///|
type Fraction = (Int32, Int32)

///|
fn normalized(numerator : Int32, denominator : Int32) -> Fraction {
  let mut a = if numerator < 0 { -numerator } else { numerator }
  let mut b = denominator
  while b != 0 {
    let r = a % b
    a = b
    b = r
  }
  (numerator / a, denominator / a)
}

///|
fn plus(left : Fraction, right : Fraction) -> Fraction {
  let (a, b) = left
  let (c, d) = right
  normalized(a * d + c * b, b * d)
}

///|
fn times(left : Fraction, right : Fraction) -> Fraction {
  let (a, b) = left
  let (c, d) = right
  normalized(a * c, b * d)
}

///|
fn rational(value : Fraction) -> @exact.Rational {
  let (n, d) = value
  @oracle.rational(n, d)
}

///|
fn tensor(
  dimensions : Array[Int32],
  values : Array[Fraction],
) -> @tensor.Tensor[@exact.Rational] {
  @tensor.from_flat(
    @oracle.chain(dimensions.map(@oracle.nat)),
    @oracle.chain(values.map(rational)),
  ).unwrap()
}

///|
fn encoded(value : @tensor.Tensor[@exact.Rational]) -> String {
  let shape = @oracle.array(@tensor.shape(value))
    .map(fn(n) { @oracle.int_of_nat(n).to_string() })
    .join(",")
  let entries = @oracle.array(@tensor.entries(value))
    .map(fn(q) {
      let numerator = @oracle.int_of_integer(@exact.numerator(q))
      let denominator = @oracle.int_of_binary(@exact.denominator(q))
      "[\{numerator},\{denominator}]"
    })
    .join(",")
  "{\"shape\":[\{shape}],\"entries\":[\{entries}]}"
}

///|
fn permutation_coordinates(dimensions : Array[Int32]) -> Array[Array[Int32]] {
  let mut coordinates = [[]]
  for size in dimensions {
    let next = []
    for prefix in coordinates {
      for index in 0..<size {
        next.push(prefix + [index])
      }
    }
    coordinates = next
  }
  coordinates
}

///|
fn run_permutation(mode : String) -> Unit {
  let (dimensions, order, iterations) = match mode {
    "permute-scalar" => ([], [], 10000)
    "permute-zero" => ([3, 0, 5], [2, 0, 1], 10000)
    "permute-tiny" => ([2, 3], [1, 0], 10000)
    "permute-rect" => ([3, 4, 5], [2, 0, 1], 3000)
    "permute-rank5" => ([3, 3, 3, 3, 3], [4, 2, 0, 3, 1], 500)
    "permute-identity" => ([3, 4, 5], [0, 1, 2], 3000)
    _ => abort("unknown permutation case")
  }
  let input_coordinates = permutation_coordinates(dimensions)
  let values = Array::makei(input_coordinates.length(), fn(i) { i - 7 })
  let input = @tensor.from_flat(
    @oracle.chain(dimensions.map(@oracle.nat)),
    @oracle.chain(values),
  ).unwrap()
  let axes = @oracle.chain(order.map(@oracle.nat))
  let output_shape = order.map(fn(axis) { dimensions[axis] })
  let expected = permutation_coordinates(output_shape).map(fn(coordinates) {
    let original = Array::make(dimensions.length(), 0)
    for axis in 0..<order.length() {
      original[order[axis]] = coordinates[axis]
    }
    let mut offset = 0
    for axis in 0..<dimensions.length() {
      offset = offset * dimensions[axis] + original[axis]
    }
    values[offset]
  })
  let expected_tensor = @tensor.from_flat(
    @oracle.chain(output_shape.map(@oracle.nat)),
    @oracle.chain(expected),
  ).unwrap()
  let mut actual = expected_tensor
  for _ in 0..<iterations {
    actual = @tensor.permute(input, axes).unwrap()
    if actual != expected_tensor {
      abort("full permutation differs from independent coordinate loops")
    }
  }
  let shape = @oracle.array(@tensor.shape(actual))
    .map(fn(n) { @oracle.int_of_nat(n).to_string() })
    .join(",")
  let entries = @oracle.array(@tensor.entries(actual))
    .map(fn(n) { n.to_string() })
    .join(",")
  println(
    "{\"case\":\"\{mode}\",\"iterations\":\{iterations},\"shape\":[\{shape}],\"entries\":[\{entries}],\"checked\":true}",
  )
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  if mode.has_prefix("permute-") {
    run_permutation(mode)
    return
  }
  let (n, base_iterations) = match mode {
    "tiny" => (1, 10000)
    "zero" => (0, 10000)
    "raise3" => (3, 2000)
    "raise5" => (5, 500)
    "scalar3" => (3, 1000)
    "scalar5" => (5, 500)
    _ => abort("expected frozen tensor benchmark case")
  }
  // The diagnostic profile multiplier is frozen here; ABBA always uses defaults.
  let iterations = base_iterations *
    (if args.contains("--profile") { 32 } else { 1 })
  let outcomes = n + 1
  let inverse = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) {
      normalized(if i == j { outcomes - 1 } else { -1 }, outcomes * outcomes)
    })
  })
  let inverse_values = []
  for row in inverse {
    for value in row {
      inverse_values.push(value)
    }
  }
  let metric_inverse = tensor([n, n], inverse_values)
  let inverse_matrix = @matrix.matrix(
    @oracle.nat(n),
    @oracle.chain(inverse.map(fn(row) { @oracle.chain(row.map(rational)) })),
  ).unwrap()
  let lower_values = []
  for i in 0..<n {
    for j in 0..<n {
      for k in 0..<n {
        lower_values.push(
          if i == j && j == k {
            (0, 1)
          } else {
            normalized(outcomes * outcomes, 2)
          },
        )
      }
    }
  }
  let lower = tensor([n, n, n], lower_values)
  let expected_raise_values = []
  for i in 0..<n {
    for j in 0..<n {
      for k in 0..<n {
        let mut value = (0, 1)
        for a in 0..<n {
          value = plus(
            value,
            times(inverse[k][a], lower_values[(i * n + j) * n + a]),
          )
        }
        expected_raise_values.push(value)
      }
    }
  }
  let expected_raise = tensor([n, n, n], expected_raise_values)
  let ricci_values = []
  for i in 0..<n {
    for j in 0..<n {
      ricci_values.push(
        normalized((n - 1) * outcomes * (if i == j { 2 } else { 1 }), 4),
      )
    }
  }
  let ricci = tensor([n, n], ricci_values)
  let expected_product_values = []
  for a in inverse_values {
    for b in ricci_values {
      expected_product_values.push(times(a, b))
    }
  }
  let expected_product = tensor([n, n, n, n], expected_product_values)
  let expected_first_values = []
  for b in 0..<n {
    for d in 0..<n {
      let mut value = (0, 1)
      for a in 0..<n {
        value = plus(value, times(inverse[a][b], ricci_values[a * n + d]))
      }
      expected_first_values.push(value)
    }
  }
  let expected_first = tensor([n, n], expected_first_values)
  let expected_scalar = tensor([], [normalized(n * (n - 1), 4)])
  let run_raise = mode == "tiny" ||
    mode == "zero" ||
    mode == "raise3" ||
    mode == "raise5"
  let scalar = mode == "tiny" ||
    mode == "zero" ||
    mode == "scalar3" ||
    mode == "scalar5"
  for _ in 0..<iterations {
    if run_raise {
      let actual = @tensor.mode_product(
        lower,
        @oracle.nat(2),
        inverse_matrix,
        @algebra.rationals(),
      ).unwrap()
      if actual != expected_raise {
        abort("full raised connection differs from independent fraction loops")
      }
    }
    if scalar {
      let product = @tensor.product(@algebra.rationals(), metric_inverse, ricci)
      let first = @tensor.contract(
        @algebra.rationals(),
        product,
        @oracle.nat(0),
        @oracle.nat(2),
      ).unwrap()
      let result = @tensor.contract(
        @algebra.rationals(),
        first,
        @oracle.nat(0),
        @oracle.nat(1),
      ).unwrap()
      if product != expected_product ||
        first != expected_first ||
        result != expected_scalar {
        abort(
          "full product/first trace/scalar differs from independent fraction loops",
        )
      }
    }
  }
  println(
    "{\"case\":\"\{mode}\",\"dimension\":\{n},\"iterations\":\{iterations},\"inverse\":\{encoded(metric_inverse)},\"lower\":\{encoded(lower)},\"ricci\":\{encoded(ricci)},\"raised\":\{encoded(expected_raise)},\"product\":\{encoded(expected_product)},\"first_trace\":\{encoded(expected_first)},\"scalar\":\{encoded(expected_scalar)},\"checked\":true}",
  )
}
