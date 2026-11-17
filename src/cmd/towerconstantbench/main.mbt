///|
fn extension(field : @tower.Field, quadratic : Bool) -> @tower.Extension {
  let values = if quadratic { [-2, 0, 1] } else { [-1, 1] }
  let polynomial = @tower.polynomial(
    field,
    @oracle.chain(
      values.map(fn(n) { @tower.rational(field, @oracle.rational(n, 1)) }),
    ),
  ).unwrap()
  let system = @tower.system(polynomial).unwrap()
  let interval : @sturm.Interval = {
    lower: @oracle.rational(if quadratic { 1 } else { 0 }, 1),
    upper: @oracle.rational(if quadratic { 2 } else { 1 }, 1),
  }
  let root = @tower.root_in_interval(system, interval).unwrap()
  if !@tower.check_system(polynomial, @tower.system_certificate(system)) ||
    !@tower.check_root_result(polynomial, root, @tower.root_certificate(root)) {
    abort("checked setup mismatch")
  }
  @tower.adjoin(root).unwrap()
}

///|
fn field_depth(depth : Int32) -> @tower.Field {
  let mut field = @tower.rational_field()
  for _ in 0..<depth {
    field = extension(field, false).field
  }
  field
}

///|
fn samples(field : @tower.Field) -> Array[@tower.Scalar] {
  let values = [(-2, 3), (0, 1), (1, 1), (7, 5)]
  let result = values.map(fn(pair) {
    @tower.rational(field, @oracle.rational(pair.0, pair.1))
  })
  result.push(@tower.scalar_one(field))
  let coefficients = @oracle.array(@tower.coefficients(@tower.one(field)))
  if coefficients.length() != 1 {
    abort("one polynomial shape mismatch")
  }
  result.push(coefficients[0])
  result
}

///|
fn reference(field : @tower.Field) -> Array[@tower.Scalar] {
  let base = @tower.rational_field()
  [(-2, 3), (0, 1), (1, 1), (7, 5), (1, 1), (1, 1)].map(fn(pair) {
    @tower.embed(field, @tower.rational(base, @oracle.rational(pair.0, pair.1))).unwrap()
  })
}

///|
fn check_values(
  actual : Array[@tower.Scalar],
  expected : Array[@tower.Scalar],
  signs : Array[@core.Ordering],
) -> Array[@tower.Scalar] {
  if actual.length() != expected.length() || actual.length() != signs.length() {
    abort("full value count mismatch")
  }
  for i in 0..<actual.length() {
    if @tower.representative(actual[i]) != @tower.representative(expected[i]) ||
      !@tower.same_field(
        @tower.scalar_field(actual[i]),
        @tower.scalar_field(expected[i]),
      ) {
      abort("full representation/context mismatch")
    }
    let proof = @tower.scalar_sign(actual[i]).unwrap()
    if proof.sign != signs[i] ||
      !@tower.check_scalar(actual[i], signs[i], proof.certificate) {
      abort("scalar sign/checker mismatch")
    }
  }
  actual
}

///|
fn result_json(values : Array[@tower.Scalar]) -> String {
  let representations : Array[Json] = values.map(fn(value) {
    Json::string("\{@tower.representative(value).to_repr()}")
  })
  Json::array(representations).stringify()
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let signs : Array[@core.Ordering] = [
    Less,
    Equal,
    Greater,
    Greater,
    Greater,
    Greater,
  ]
  let (iterations, operation) : (Int32, () -> Array[@tower.Scalar]) = match
    name {
    "embed-base" | "embed-depth1" | "embed-depth2" => {
      let depth = if name == "embed-base" {
        0
      } else if name == "embed-depth1" {
        1
      } else {
        2
      }
      let field = field_depth(depth)
      let expected = reference(field)
      let count = if depth == 0 {
        10000
      } else if depth == 1 {
        5000
      } else {
        2000
      }
      (count, fn() { check_values(samples(field), expected, signs) })
    }
    "embed-depth3-4" => {
      let third = field_depth(3)
      let fourth = field_depth(4)
      let expected3 = reference(third)
      let expected4 = reference(fourth)
      (
        300,
        fn() {
          let a = check_values(samples(third), expected3, signs)
          let b = check_values(samples(fourth), expected4, signs)
          for value in b {
            a.push(value)
          }
          a
        },
      )
    }
    "multiply-depth2" => {
      let first = extension(@tower.rational_field(), true)
      let second = extension(first.field, true)
      let field = second.field
      let a = @tower.rational(field, @oracle.rational(2, 3))
      let b = @tower.rational(field, @oracle.rational(-5, 7))
      let unit = @tower.scalar_one(field)
      let expected = [
        @tower.rational(field, @oracle.rational(-10, 21)),
        second.generator,
        second.generator,
      ]
      (
        100,
        fn() {
          check_values(
            [
              @tower.scalar_multiply(a, b).unwrap(),
              @tower.scalar_multiply(second.generator, unit).unwrap(),
              @tower.scalar_multiply(unit, second.generator).unwrap(),
            ],
            expected,
            [Less, Greater, Greater],
          )
        },
      )
    }
    "cold-setup-depth2" => {
      let expected = reference(field_depth(2))
      (20, fn() { check_values(samples(field_depth(2)), expected, signs) })
    }
    _ => abort("unknown tower constant benchmark case")
  }
  let initial = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    let _ = operation()
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  let result = result_json(initial)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{result},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
