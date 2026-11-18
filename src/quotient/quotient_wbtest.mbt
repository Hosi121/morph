///|
fn rational_arithmetic() -> @rowreduce.Field[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    add: @exact.rational_add,
    subtract: @exact.rational_subtract,
    negate: @exact.rational_negate,
    multiply: @exact.rational_multiply,
    inverse: fn(value) { @exact.rational_divide(@exact.rational_one(), value) },
  }
}

///|
fn rational_is_zero(value : @exact.Rational) -> Bool {
  @exact.rational_compare(value, @exact.rational_zero()) is @core.Equal
}

///|
fn rational_coefficients(values : Array[Int32]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(value) { @oracle.rational(value, 1) }))
}

///|
fn rational_context(modulus : Array[Int32]) -> Context[@exact.Rational, Bool] {
  context(
    rational_arithmetic(),
    false,
    rational_is_zero,
    fn(_) { true },
    rational_coefficients(modulus),
  ).unwrap()
}

///|
// Independent, bounded machine-integer long division; no quotient-core helper.
fn integer_remainder(
  input : Array[Int32],
  modulus : Array[Int32],
) -> Array[Int32] {
  let work : Array[Int32] = [ for value in input => value ]
  let degree = modulus.length() - 1
  for exponent = work.length() - 1; exponent >= degree; {
    let leading = work[exponent]
    for offset in 0..<=degree {
      work[exponent - degree + offset] -= leading * modulus[offset]
    }
    continue exponent - 1
  }
  let mut count = work.length()
  while count > 0 && work[count - 1] == 0 {
    count -= 1
  }
  [
    for index in 0..<count => work[index]
  ]
}

///|
fn integer_product(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i, x in a {
    for j, y in b {
      result[i + j] += x * y
    }
  }
  result
}

///|
test "QQ quotient normalization and products match bounded integer long division" {
  let inputs = [
    [],
    [0],
    [1],
    [-2, 3],
    [1, -1, 2],
    [0, 2, 0, -1],
    [2, 0, -1, 1, 2],
  ]
  for modulus in [[-2, 0, 1], [-1, 0, 1], [0, 0, 1], [-2, 1]] {
    let ring = rational_context(modulus)
    assert_eq(@oracle.int_of_nat(degree(ring)), modulus.length() - 1)
    for aa in inputs {
      let a = normalize(ring, rational_coefficients(aa)).unwrap()
      assert_eq(
        coefficients(a),
        rational_coefficients(integer_remainder(aa, modulus)),
      )
      assert_true(same_context(parent(a), ring))
      assert_true(equivalent(normalize(ring, coefficients(a)).unwrap(), a))
      for bb in inputs {
        let b = normalize(ring, rational_coefficients(bb)).unwrap()
        let product = multiply(a, b).unwrap()
        assert_eq(
          coefficients(product),
          rational_coefficients(
            integer_remainder(integer_product(aa, bb), modulus),
          ),
        )
        assert_true(equivalent(subtract(add(a, b).unwrap(), b).unwrap(), a))
        assert_true(is_zero(add(a, negate(a).unwrap()).unwrap()))
      }
    }
  }
  let ring = rational_context([-2, 0, 1])
  let fraction = normalize(
    ring,
    @oracle.chain([@oracle.rational(1, 2), @oracle.rational(1, 3)]),
  ).unwrap()
  // (one/2 + x/3)^2 = 17/36 + x/3 for x^2=2.
  assert_eq(
    coefficients(multiply(fraction, fraction).unwrap()),
    @oracle.chain([@oracle.rational(17, 36), @oracle.rational(1, 3)]),
  )
}

///|
test "units and nonunits in quadratic fields and reducible QQ algebras" {
  let quadratic = rational_context([-2, 0, 1])
  let x = generator(quadratic).unwrap()
  let inverse = unit_inverse(x).unwrap().unwrap()
  assert_eq(
    coefficients(inverse),
    @oracle.chain([@oracle.rational(0, 1), @oracle.rational(1, 2)]),
  )
  assert_true(equivalent(multiply(x, inverse).unwrap(), one(quadratic)))
  assert_true(unit_inverse(zero(quadratic)).unwrap() is None)

  let dual = rational_context([0, 0, 1])
  let nilpotent = generator(dual).unwrap()
  assert_true(!is_zero(nilpotent))
  assert_true(is_zero(multiply(nilpotent, nilpotent).unwrap()))
  assert_true(unit_inverse(nilpotent).unwrap() is None)
  let unipotent = add(one(dual), nilpotent).unwrap()
  let reciprocal = unit_inverse(unipotent).unwrap().unwrap()
  assert_eq(coefficients(reciprocal), rational_coefficients([1, -1]))

  let split = rational_context([-1, 0, 1])
  let plus = add(one(split), generator(split).unwrap()).unwrap()
  let minus = subtract(generator(split).unwrap(), one(split)).unwrap()
  assert_true(!is_zero(plus) && !is_zero(minus))
  assert_true(is_zero(multiply(plus, minus).unwrap()))
  assert_true(unit_inverse(plus).unwrap() is None)
  assert_true(unit_inverse(minus).unwrap() is None)

  let linear = rational_context([-2, 1])
  assert_eq(
    coefficients(generator(linear).unwrap()),
    rational_coefficients([2]),
  )
  assert_eq(
    coefficients(unit_inverse(generator(linear).unwrap()).unwrap().unwrap()),
    @oracle.chain([@oracle.rational(1, 2)]),
  )
}

///|
test "input validation rejects bad moduli coefficients and mixed context keys" {
  let field = rational_arithmetic()
  let checked = fn(values) {
    context(
      field,
      false,
      rational_is_zero,
      fn(_) { true },
      rational_coefficients(values),
    )
  }
  assert_true(checked([]) is Err(ZeroModulus))
  assert_true(checked([0, 0]) is Err(ZeroModulus))
  assert_true(checked([1]) is Err(ConstantModulus))
  assert_true(checked([0, 2]) is Err(NonMonicModulus))
  let ring = checked([-2, 0, 1, 0]).unwrap()
  assert_eq(modulus(ring), rational_coefficients([-2, 0, 1]))
  assert_eq(base_key(ring), false)

  let valid = fn(value : @exact.Rational) {
    !value.equal(@oracle.rational(7, 1))
  }
  assert_true(
    context(
      field,
      false,
      rational_is_zero,
      valid,
      rational_coefficients([7, 1]),
    )
    is Err(InvalidCoefficient),
  )
  // Deliberately non-closed carrier: test boundary rejection, not a valid
  // coefficient field for total quotient arithmetic.
  let restricted = context(
    field,
    false,
    rational_is_zero,
    valid,
    rational_coefficients([-2, 0, 1]),
  ).unwrap()
  assert_true(
    normalize(restricted, rational_coefficients([7, 0]))
    is Err(InvalidCoefficient),
  )
  assert_true(
    context(
      field,
      false,
      fn(_) { false },
      fn(_) { true },
      rational_coefficients([-2, 0, 1]),
    )
    is Err(InvalidArithmetic),
  )
  let bad_one = { ..field, one: field.zero, }
  assert_true(
    context(
      bad_one,
      false,
      rational_is_zero,
      fn(_) { true },
      rational_coefficients([-2, 0, 1]),
    )
    is Err(InvalidArithmetic),
  )
  assert_true(
    context(
      field,
      false,
      rational_is_zero,
      fn(_) { false },
      rational_coefficients([-2, 0, 1]),
    )
    is Err(InvalidCoefficient),
  )

  let different_key = context(
    field,
    true,
    rational_is_zero,
    fn(_) { true },
    rational_coefficients([-2, 0, 1]),
  ).unwrap()
  let different_modulus = checked([-1, 0, 1]).unwrap()
  let a = generator(ring).unwrap()
  for other in [different_key, different_modulus] {
    let b = generator(other).unwrap()
    assert_true(!same_context(ring, other))
    assert_true(!equivalent(a, b))
    assert_true(add(a, b) is Err(DifferentContext))
    assert_true(subtract(a, b) is Err(DifferentContext))
    assert_true(multiply(zero(ring), zero(other)) is Err(DifferentContext))
  }
}

///|
fn native_bit_degree(value : Int32) -> Int32 {
  for value = value, degree = -1; value > 0; {
    continue value >> 1, degree + 1
  } nobreak {
    degree
  }
}

///|
fn native_bit_remainder(value : Int32, modulus : Int32) -> Int32 {
  let degree = native_bit_degree(modulus)
  for rest = value; native_bit_degree(rest) >= degree; {
    continue rest ^ (modulus << (native_bit_degree(rest) - degree))
  } nobreak {
    rest
  }
}

///|
// Full unreduced convolution followed by high-bit division, independent of
// the fused shift-and-reduce loop in the Bool specialization.
fn native_bit_product(a : Int32, b : Int32, modulus : Int32) -> Int32 {
  let mut full = 0
  for bit in 0..<4 {
    if ((b >> bit) & 1) == 1 {
      full = full ^ (a << bit)
    }
  }
  native_bit_remainder(full, modulus)
}

///|
fn native_bit_inverse(value : Int32, modulus : Int32, count : Int32) -> Int32? {
  for candidate in 0..<count {
    if native_bit_product(value, candidate, modulus) == 1 {
      return Some(candidate)
    }
  }
  None
}

///|
fn bool_coefficients(value : Int32, width : Int32) -> @core.Chain[Bool] {
  @oracle.chain([ for bit in 0..<width => ((value >> bit) & 1) == 1 ])
}

///|
fn native_bits(value : Residue[Bool, Bool]) -> Int32 {
  let mut result = 0
  for index, bit in @oracle.array(coefficients(value)) {
    if bit {
      result = result | (1 << index)
    }
  }
  result
}

///|
test "all monic F2 quotients through degree four match integer bit oracles" {
  // Include every reducible modulus, not only field presentations.
  for degree in 1..<=4 {
    let count = 1 << degree
    for lower in 0..<count {
      let modulus = count | lower
      let ordinary = gf2_context(
        false,
        bool_coefficients(modulus, degree + 1),
        Generic,
      ).unwrap()
      let fused = gf2_context(
        false,
        bool_coefficients(modulus, degree + 1),
        Carryless,
      ).unwrap()
      assert_eq(policy(ordinary), Generic)
      assert_eq(policy(fused), Carryless)
      assert_true(same_context(ordinary, fused))
      for raw in 0..<(1 << (degree + degree)) {
        assert_eq(
          native_bits(
            normalize(ordinary, bool_coefficients(raw, degree + degree)).unwrap(),
          ),
          native_bit_remainder(raw, modulus),
        )
        assert_true(
          equivalent(
            normalize(ordinary, bool_coefficients(raw, degree + degree)).unwrap(),
            normalize(fused, bool_coefficients(raw, degree + degree)).unwrap(),
          ),
        )
      }
      for a in 0..<count {
        let left = normalize(ordinary, bool_coefficients(a, degree)).unwrap()
        let fast_left = normalize(fused, bool_coefficients(a, degree)).unwrap()
        for b in 0..<count {
          let right = normalize(ordinary, bool_coefficients(b, degree)).unwrap()
          let fast_right = normalize(fused, bool_coefficients(b, degree)).unwrap()
          let expected = native_bit_product(a, b, modulus)
          assert_eq(native_bits(multiply(left, right).unwrap()), expected)
          assert_eq(
            native_bits(multiply(fast_left, fast_right).unwrap()),
            expected,
          )
          assert_eq(native_bits(multiply(left, fast_right).unwrap()), expected)
          assert_eq(native_bits(add(left, fast_right).unwrap()), a ^ b)
          assert_eq(native_bits(subtract(fast_left, right).unwrap()), a ^ b)
        }
        assert_eq(native_bits(negate(fast_left).unwrap()), a)
        let expected_inverse = native_bit_inverse(a, modulus, count)
        assert_eq(
          unit_inverse(left).unwrap().map(native_bits),
          expected_inverse,
        )
        assert_eq(
          unit_inverse(fast_left).unwrap().map(native_bits),
          expected_inverse,
        )
      }
    }
  }
}
