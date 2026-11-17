///|
fn nat_list(values : Array[Int32]) -> @core.Chain[@core.Nat] {
  @oracle.chain(values.map(@oracle.nat))
}

///|
fn rational(value : Int32) -> @exact.Rational {
  @oracle.rational(value, 1)
}

///|
fn integers(values : Array[Int32]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(rational))
}

///|
fn[A] host_shape(value : Tensor[A]) -> Array[Int32] {
  @oracle.array(shape(value)).map(@oracle.int_of_nat)
}

///|
fn host_entries(value : Tensor[@exact.Rational]) -> Array[Int32] {
  @oracle.array(entries(value)).map(fn(value) {
    if !@exact.denominator(value).equal(@oracle.binary(1)) {
      abort("host integer oracle received a non-integral value")
    }
    @oracle.int_of_integer(@exact.numerator(value))
  })
}

///|
fn host_cardinality(dimensions : Array[Int32]) -> Int32 {
  let mut size = 1
  for dimension in dimensions {
    size *= dimension
  }
  size
}

///|
fn host_coordinates(dimensions : Array[Int32]) -> Array[Array[Int32]] {
  let mut result = [[]]
  for dimension in dimensions {
    let next = []
    for prefix in result {
      for i in 0..<dimension {
        next.push(prefix + [i])
      }
    }
    result = next
  }
  result
}

///|
fn host_offset(dimensions : Array[Int32], coordinates : Array[Int32]) -> Int32 {
  let mut offset = 0
  for i in 0..<dimensions.length() {
    offset = offset * dimensions[i] + coordinates[i]
  }
  offset
}

///|
fn small_shapes(max_rank : Int32) -> Array[Array[Int32]] {
  let result = [[]]
  let mut current = [[]]
  for _ in 0..<max_rank {
    let next = []
    for prefix in current {
      for size in 0..<3 {
        next.push(prefix + [size])
      }
    }
    for value in next {
      result.push(value)
    }
    current = next
  }
  result
}

///|
fn permutations(n : Int32) -> Array[Array[Int32]] {
  let mut result = [[]]
  for axis in 0..<n {
    let next = []
    for prefix in result {
      for at in 0..<=prefix.length() {
        let value = []
        for i in 0..<at {
          value.push(prefix[i])
        }
        value.push(axis)
        for i in at..<prefix.length() {
          value.push(prefix[i])
        }
        next.push(value)
      }
    }
    result = next
  }
  result
}

///|
fn numbered(dimensions : Array[Int32]) -> Tensor[@exact.Rational] {
  from_flat(
    nat_list(dimensions),
    integers(Array::makei(host_cardinality(dimensions), fn(i) { i + 1 })),
  ).unwrap()
}

///|
fn host_permute(
  dimensions : Array[Int32],
  values : Array[Int32],
  order : Array[Int32],
) -> (Array[Int32], Array[Int32]) {
  let output_shape = order.map(fn(i) { dimensions[i] })
  let output = host_coordinates(output_shape).map(fn(coordinates) {
    let original = Array::make(order.length(), 0)
    for i in 0..<order.length() {
      original[order[i]] = coordinates[i]
    }
    values[host_offset(dimensions, original)]
  })
  (output_shape, output)
}

///|
fn host_contract(
  dimensions : Array[Int32],
  values : Array[Int32],
  a : Int32,
  b : Int32,
) -> (Array[Int32], Array[Int32]) {
  let output_shape = []
  for i in 0..<dimensions.length() {
    if i != a && i != b {
      output_shape.push(dimensions[i])
    }
  }
  let output = host_coordinates(output_shape).map(fn(coordinates) {
    let original = Array::make(dimensions.length(), 0)
    let mut index = 0
    for i in 0..<dimensions.length() {
      if i != a && i != b {
        original[i] = coordinates[index]
        index += 1
      }
    }
    let mut sum = 0
    for i in 0..<dimensions[a] {
      original[a] = i
      original[b] = i
      sum += values[host_offset(dimensions, original)]
    }
    sum
  })
  (output_shape, output)
}

///|
fn host_mode_product(
  dimensions : Array[Int32],
  values : Array[Int32],
  axis : Int32,
  linear : Array[Array[Int32]],
) -> (Array[Int32], Array[Int32]) {
  let output_shape = dimensions.copy()
  output_shape[axis] = linear.length()
  let output = host_coordinates(output_shape).map(fn(coordinates) {
    let original = coordinates.copy()
    let mut sum = 0
    for i in 0..<dimensions[axis] {
      original[axis] = i
      sum += linear[coordinates[axis]][i] *
        values[host_offset(dimensions, original)]
    }
    sum
  })
  (output_shape, output)
}

///|
fn rational_matrix(
  values : Array[Array[Int32]],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(@oracle.nat(width), @oracle.chain(values.map(integers))).unwrap()
}

///|
test "rank zero and every small shape preserve row-major entries and coordinate errors" {
  assert_eq(small_shapes(3).length(), 40)
  for dimensions in small_shapes(3) {
    let value = numbered(dimensions)
    let expected = Array::makei(host_cardinality(dimensions), fn(i) { i + 1 })
    assert_eq(host_shape(value), dimensions)
    assert_eq(rank(value), @oracle.nat(dimensions.length()))
    assert_eq(host_entries(value), expected)
    for indices in host_coordinates(dimensions) {
      assert_eq(
        at(value, nat_list(indices)),
        Ok(rational(expected[host_offset(dimensions, indices)])),
      )
    }
    assert_eq(
      at(value, nat_list(Array::make(dimensions.length() + 1, 0))),
      Err(CoordinateRankMismatch),
    )
    if dimensions.length() > 0 {
      assert_eq(
        at(value, nat_list(Array::make(dimensions.length() - 1, 0))),
        Err(CoordinateRankMismatch),
      )
      for axis in 0..<dimensions.length() {
        let indices = Array::make(dimensions.length(), 0)
        indices[axis] = dimensions[axis]
        assert_eq(at(value, nat_list(indices)), Err(CoordinateOutOfBounds))
      }
    }
    assert_eq(
      from_flat(nat_list(dimensions), integers(expected + [99])),
      Err(EntryCountMismatch),
    )
    if expected.length() > 0 {
      assert_eq(
        from_flat(
          nat_list(dimensions),
          integers(Array::makei(expected.length() - 1, fn(i) { expected[i] })),
        ),
        Err(EntryCountMismatch),
      )
    }
    let calls = []
    let generated = tabulate(nat_list(dimensions), fn(indices) {
      let coordinates = @oracle.array(indices).map(@oracle.int_of_nat)
      calls.push(coordinates)
      rational(host_offset(dimensions, coordinates) + 1)
    })
    assert_eq(generated, value)
    assert_eq(calls, host_coordinates(dimensions))
    assert_eq(
      host_entries(map(value, @exact.rational_negate)),
      expected.map(fn(x) { -x }),
    )
    assert_eq(
      host_entries(zip(value, value, @exact.rational_add).unwrap()),
      expected.map(fn(x) { x + x }),
    )
  }
  assert_eq(
    zip(numbered([1, 2]), numbered([2, 1]), @exact.rational_add),
    Err(ShapeMismatch),
  )
  assert_eq(
    zip(numbered([0, 2]), numbered([2, 0]), @exact.rational_add),
    Err(ShapeMismatch),
  )
}

///|
test "all small axis permutations match independent array-index oracle" {
  let mut checked = 0
  for dimensions in small_shapes(3) {
    let value = numbered(dimensions)
    for order in permutations(dimensions.length()) {
      let (wanted_shape, wanted_entries) = host_permute(
        dimensions,
        host_entries(value),
        order,
      )
      let actual = permute(value, nat_list(order)).unwrap()
      assert_eq(host_shape(actual), wanted_shape)
      assert_eq(host_entries(actual), wanted_entries)
      let inverse = Array::make(order.length(), 0)
      for i in 0..<order.length() {
        inverse[order[i]] = i
      }
      assert_eq(permute(actual, nat_list(inverse)), Ok(value))
      checked += 1
    }
  }
  assert_eq(checked, 184)
  assert_eq(permute(numbered([]), nat_list([0])), Err(PermutationRankMismatch))
  assert_eq(
    permute(numbered([2, 2]), nat_list([0])),
    Err(PermutationRankMismatch),
  )
  assert_eq(
    permute(numbered([2, 2]), nat_list([0, 2])),
    Err(PermutationOutOfBounds),
  )
  assert_eq(
    permute(numbered([2, 2]), nat_list([0, 0])),
    Err(PermutationNotBijective),
  )
}

///|
test "every ordered contraction in small ranks matches independent array-loop oracle" {
  let mut checked = 0
  for dimensions in small_shapes(3) {
    let value = numbered(dimensions)
    for a in 0..<dimensions.length() {
      for b in 0..<dimensions.length() {
        let actual = contract(
          @algebra.rationals(),
          value,
          @oracle.nat(a),
          @oracle.nat(b),
        )
        if a == b {
          assert_eq(actual, Err(RepeatedAxis))
        } else if dimensions[a] != dimensions[b] {
          assert_eq(actual, Err(AxisSizeMismatch))
        } else {
          let (wanted_shape, wanted_entries) = host_contract(
            dimensions,
            host_entries(value),
            a,
            b,
          )
          let result = actual.unwrap()
          assert_eq(host_shape(result), wanted_shape)
          assert_eq(host_entries(result), wanted_entries)
          checked += 1
        }
      }
    }
    assert_eq(
      contract(
        @algebra.rationals(),
        value,
        @oracle.nat(dimensions.length()),
        @oracle.nat(0),
      ),
      Err(AxisOutOfBounds),
    )
  }
  assert_eq(checked, 60)
  assert_eq(
    host_shape(
      contract(
        @algebra.rationals(),
        numbered([0, 0]),
        @oracle.nat(0),
        @oracle.nat(1),
      ).unwrap(),
    ),
    [],
  )
  assert_eq(
    host_entries(
      contract(
        @algebra.rationals(),
        numbered([0, 0]),
        @oracle.nat(0),
        @oracle.nat(1),
      ).unwrap(),
    ),
    [0],
  )
}

///|
test "all small mode products preserve rectangular and zero-dimensional semantics" {
  let mut checked = 0
  for dimensions in small_shapes(3) {
    let value = numbered(dimensions)
    for axis in 0..<dimensions.length() {
      for height in 0..<3 {
        let linear = Array::makei(height, fn(i) {
          Array::makei(dimensions[axis], fn(j) { i - j + 2 })
        })
        let actual = mode_product(
          value,
          @oracle.nat(axis),
          rational_matrix(linear, dimensions[axis]),
          @algebra.rationals(),
        ).unwrap()
        let (wanted_shape, wanted_entries) = host_mode_product(
          dimensions,
          host_entries(value),
          axis,
          linear,
        )
        assert_eq(host_shape(actual), wanted_shape)
        assert_eq(host_entries(actual), wanted_entries)
        checked += 1
      }
      let wrong_width = dimensions[axis] + 1
      assert_eq(
        mode_product(
          value,
          @oracle.nat(axis),
          rational_matrix([Array::make(wrong_width, 0)], wrong_width),
          @algebra.rationals(),
        ),
        Err(ModeWidthMismatch),
      )
    }
    assert_eq(
      mode_product(
        value,
        @oracle.nat(dimensions.length()),
        rational_matrix([], 0),
        @algebra.rationals(),
      ),
      Err(AxisOutOfBounds),
    )
  }
  assert_eq(checked, 306)
}

///|
test "tensor product on every small shape pair matches nested array product" {
  let mut checked = 0
  for left_shape in small_shapes(3) {
    for right_shape in small_shapes(3) {
      let left = numbered(left_shape)
      let right = numbered(right_shape)
      let expected = []
      for a in host_entries(left) {
        for b in host_entries(right) {
          expected.push(a * b)
        }
      }
      let actual = product(@algebra.rationals(), left, right)
      assert_eq(host_shape(actual), left_shape + right_shape)
      assert_eq(host_entries(actual), expected)
      checked += 1
    }
  }
  assert_eq(checked, 1600)
}

///|
test "Boolean semirings and prime-field dictionaries remain generic" {
  let boolean = from_flat(
    nat_list([2, 2]),
    @oracle.chain([true, false, false, true]),
  ).unwrap()
  let xor : @algebra.Semiring[Bool] = {
    zero: false,
    one: true,
    plus: fn(a, b) { a != b },
    times: fn(a, b) { a && b },
  }
  let trace_or = contract(
    @algebra.booleans(),
    boolean,
    @oracle.nat(0),
    @oracle.nat(1),
  ).unwrap()
  let trace_xor = contract(xor, boolean, @oracle.nat(0), @oracle.nat(1)).unwrap()
  assert_eq(@oracle.array(entries(trace_or)), [true])
  assert_eq(@oracle.array(entries(trace_xor)), [false])
  assert_eq(host_shape(trace_xor), [])
  let vector = from_flat(nat_list([2]), @oracle.chain([true, true])).unwrap()
  let linear = @matrix.matrix(
    @oracle.nat(2),
    @oracle.chain([@oracle.chain([true, true]), @oracle.chain([false, true])]),
  ).unwrap()
  assert_eq(
    @oracle.array(
      entries(
        mode_product(vector, @oracle.nat(0), linear, @algebra.booleans()).unwrap(),
      ),
    ),
    [true, true],
  )
  assert_eq(
    @oracle.array(
      entries(mode_product(vector, @oracle.nat(0), linear, xor).unwrap()),
    ),
    [false, true],
  )
  let field = @primefield.arithmetic(
    @primefield.field(@oracle.binary(5)).unwrap(),
  )
  let finite : @algebra.Semiring[@binary.Binary] = {
    zero: field.zero,
    one: field.one,
    plus: field.add,
    times: field.multiply,
  }
  let table = from_flat(
    nat_list([2, 2]),
    @oracle.chain([1, 2, 3, 4].map(@oracle.binary)),
  ).unwrap()
  let trace = contract(finite, table, @oracle.nat(0), @oracle.nat(1)).unwrap()
  assert_eq(@oracle.array(entries(trace)).map(@oracle.int_of_binary), [0])
  let actual = mode_product(
    table,
    @oracle.nat(1),
    @matrix.matrix(
      @oracle.nat(2),
      @oracle.chain([
        @oracle.chain([1, 2].map(@oracle.binary)),
        @oracle.chain([3, 4].map(@oracle.binary)),
      ]),
    ).unwrap(),
    finite,
  ).unwrap()
  assert_eq(host_shape(actual), [2, 2])
  assert_eq(@oracle.array(entries(actual)).map(@oracle.int_of_binary), [
    0, 1, 1, 0,
  ])
  let mixed = zip(numbered([2]), vector, fn(number, flag) {
    if flag {
      number
    } else {
      @exact.rational_negate(number)
    }
  }).unwrap()
  assert_eq(host_entries(mixed), [1, 2])
}

///|
type Fraction = (Int32, Int32)

///|
fn host_fraction(numerator : Int32, denominator : Int32) -> Fraction {
  let mut a = if numerator < 0 { -numerator } else { numerator }
  let mut b = denominator
  while b != 0 {
    let remainder = a % b
    a = b
    b = remainder
  }
  (numerator / a, denominator / a)
}

///|
fn host_add(a : Fraction, b : Fraction) -> Fraction {
  let (an, ad) = a
  let (bn, bd) = b
  host_fraction(an * bd + bn * ad, ad * bd)
}

///|
fn host_multiply(a : Fraction, b : Fraction) -> Fraction {
  let (an, ad) = a
  let (bn, bd) = b
  host_fraction(an * bn, ad * bd)
}

///|
fn fraction(value : Fraction) -> @exact.Rational {
  let (n, d) = value
  @oracle.rational(n, d)
}

///|
fn fractions(values : Array[Fraction]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fraction))
}

///|
test "nonintegral QQ rank-five index raising matches independent fraction loops" {
  let inverses : Array[Array[Array[Fraction]]] = [
    [],
    [[(2, 3)]],
    [[(3, 5), (-1, 5)], [(-1, 5), (2, 5)]],
    [
      [(7, 19), (-2, 19), (1, 19)],
      [(-2, 19), (6, 19), (-3, 19)],
      [(1, 19), (-3, 19), (11, 19)],
    ],
  ]
  for n in 0..<4 {
    let coefficients = inverses[n]
    let g_values = []
    for row in coefficients {
      for value in row {
        g_values.push(value)
      }
    }
    let g = from_flat(nat_list([n, n]), fractions(g_values)).unwrap()
    let cube_values = host_coordinates([n, n, n]).map(fn(index) {
      let sum = index[0] + index[1] + index[2]
      host_fraction(sum + 1, sum + 2)
    })
    let cube = from_flat(nat_list([n, n, n]), fractions(cube_values)).unwrap()
    let combined = product(@algebra.rationals(), g, cube)
    let raised = contract(
      @algebra.rationals(),
      combined,
      @oracle.nat(1),
      @oracle.nat(2),
    ).unwrap()
    let expected = host_coordinates([n, n, n]).map(fn(index) {
      let mut value = (0, 1)
      for a in 0..<n {
        value = host_add(
          value,
          host_multiply(
            coefficients[index[0]][a],
            cube_values[host_offset([n, n, n], [a, index[1], index[2]])],
          ),
        )
      }
      fraction(value)
    })
    assert_eq(host_shape(raised), [n, n, n])
    assert_eq(@oracle.array(entries(raised)), expected)
    let linear = @matrix.matrix(
      @oracle.nat(n),
      @oracle.chain(coefficients.map(fractions)),
    ).unwrap()
    assert_eq(
      mode_product(cube, @oracle.nat(0), linear, @algebra.rationals()),
      Ok(raised),
    )
    let rearranged = permute(combined, nat_list([2, 0, 3, 1, 4])).unwrap()
    assert_eq(
      contract(@algebra.rationals(), rearranged, @oracle.nat(0), @oracle.nat(3)),
      Ok(raised),
    )
  }
  let scalar = from_flat(nat_list([]), fractions([(2, 3)])).unwrap()
  let other = from_flat(nat_list([]), fractions([(-5, 7)])).unwrap()
  assert_eq(
    entries(product(@algebra.rationals(), scalar, other)),
    fractions([(-10, 21)]),
  )
  assert_eq(at(scalar, nat_list([])), Ok(fraction((2, 3))))
}

///|
test "cubic pullback evaluates a QQ trilinear form and zero-dimensional form" {
  for n in [0, 2] {
    let values = host_coordinates([n, n, n]).map(fn(index) {
      host_fraction(
        index[0] + 2 * index[1] + 3 * index[2] + 1,
        index[0] + index[1] + index[2] + 2,
      )
    })
    let cube = from_flat(nat_list([n, n, n]), fractions(values)).unwrap()
    let direction = Array::makei(n, fn(i) {
      if i == 0 {
        (1, 2)
      } else {
        (-2, 3)
      }
    })
    let linear = @matrix.matrix(
      @oracle.nat(n),
      @oracle.chain([fractions(direction)]),
    ).unwrap()
    let first = mode_product(cube, @oracle.nat(0), linear, @algebra.rationals()).unwrap()
    let second = mode_product(
      first,
      @oracle.nat(1),
      linear,
      @algebra.rationals(),
    ).unwrap()
    let third = mode_product(
      second,
      @oracle.nat(2),
      linear,
      @algebra.rationals(),
    ).unwrap()
    let mut expected = (0, 1)
    for index in host_coordinates([n, n, n]) {
      let weight = host_multiply(
        direction[index[0]],
        host_multiply(direction[index[1]], direction[index[2]]),
      )
      expected = host_add(
        expected,
        host_multiply(weight, values[host_offset([n, n, n], index)]),
      )
    }
    assert_eq(host_shape(third), [1, 1, 1])
    assert_eq(entries(third), fractions([expected]))
  }
}

///|
test "generic construction and permutation do not require Eq on entries" {
  let function = fn() { true }
  let value = from_flat(nat_list([1]), @oracle.chain([function])).unwrap()
  let actual = permute(value, nat_list([0])).unwrap()
  assert_true(at(actual, nat_list([0])).unwrap()())
  let mapped = map(actual, fn(f) { f() })
  assert_eq(@oracle.array(entries(mapped)), [true])
}
