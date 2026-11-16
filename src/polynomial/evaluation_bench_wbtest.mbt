///|
fn evaluation_polynomial(
  coefficients : Array[(Int32, Int32)],
  denominator : Int32,
) -> Polynomial {
  polynomial(
    @oracle.nat(1),
    @oracle.chain(
      coefficients.map(fn(entry) {
        let (degree, numerator) = entry
        Term::{
          coefficient: @oracle.rational(numerator, denominator),
          exponents: Cons(@oracle.nat(degree), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn evaluation_cases(
  kind : Int32,
) -> Array[(Polynomial, @core.Chain[@exact.Rational])] {
  let out : Array[(Polynomial, @core.Chain[@exact.Rational])] = []
  if kind == 0 {
    for degree in [0, 1, 2] {
      let p = evaluation_polynomial([ for i in 0..<=degree => (i, i + 1) ], 2)
      for x in [-1, 0, 1, 2] {
        out.push((p, @oracle.chain([@oracle.rational(x, 1)])))
      }
    }
  } else if kind == 1 {
    for degree in [16, 32] {
      let p = evaluation_polynomial(
        [
          for i in 0..<=degree => (i, i * 7 % 9 - 4)
        ],
        3,
      )
      for (n, d) in [(3, 2), (1, 1), (0, 1)] {
        out.push((p, @oracle.chain([@oracle.rational(n, d)])))
      }
    }
  } else if kind == 2 {
    for last in [64, 128] {
      let p = evaluation_polynomial(
        [(last, 3), (last / 2, -2), (2, 1), (0, -7)],
        5,
      )
      for (n, d) in [(2, 1), (3, 2)] {
        out.push((p, @oracle.chain([@oracle.rational(n, d)])))
      }
    }
  } else {
    let p = polynomial(
      @oracle.nat(2),
      @oracle.chain(
        [
          for i in 0..<12 => {
            Term::{
              coefficient: @oracle.rational(i % 5 - 2, 3),
              exponents: @oracle.chain([@oracle.nat(i % 4), @oracle.nat(i / 4)]),
            }
          }
        ],
      ),
    ).unwrap()
    for x in [-1, 0, 1, 2] {
      out.push(
        (p, @oracle.chain([@oracle.rational(x, 2), @oracle.rational(3, 2)])),
      )
    }
  }
  out
}

///|
fn bench_evaluation(
  b : @bench.T,
  eval : (Polynomial, @core.Chain[@exact.Rational]) -> @exact.Rational?,
  cases : Array[(Polynomial, @core.Chain[@exact.Rational])],
) -> Unit {
  // Warm both paths equally before each measured cohort. WasmGC tiering in
  // particular makes very short cold samples unsuitable for a stable ratio.
  for _ in 0..<128 {
    for (p, values) in cases {
      b.keep(evaluation_reference(p, values))
      b.keep(evaluate(p, values))
    }
  }
  b.bench(fn() {
    for (p, values) in cases {
      b.keep(eval(p, values))
    }
  })
}

///|
test "evaluation short scalar reference" (b : @bench.T) {
  bench_evaluation(b, evaluation_reference, evaluation_cases(0))
}

///|
test "evaluation short scalar Horner" (b : @bench.T) {
  bench_evaluation(b, evaluate, evaluation_cases(0))
}

///|
test "evaluation dense reference" (b : @bench.T) {
  bench_evaluation(b, evaluation_reference, evaluation_cases(1))
}

///|
test "evaluation dense Horner" (b : @bench.T) {
  bench_evaluation(b, evaluate, evaluation_cases(1))
}

///|
test "evaluation sparse reference" (b : @bench.T) {
  bench_evaluation(b, evaluation_reference, evaluation_cases(2))
}

///|
test "evaluation sparse Horner" (b : @bench.T) {
  bench_evaluation(b, evaluate, evaluation_cases(2))
}

///|
test "evaluation multivariate reference control" (b : @bench.T) {
  bench_evaluation(b, evaluation_reference, evaluation_cases(3))
}

///|
test "evaluation multivariate Horner control" (b : @bench.T) {
  bench_evaluation(b, evaluate, evaluation_cases(3))
}

///|
test "Horner all 3125 small coefficient vectors and independent integer fractions" {
  for code in 0..<3125 {
    let coeffs = [ for i in 0..<5 => code / [1, 5, 25, 125, 625][i] % 5 - 2 ]
    let p = evaluation_polynomial([ for i in 0..<5 => (i, coeffs[i]) ], 1)
    for (n, d) in [(-3, 2), (-1, 2), (0, 1), (1, 2), (1, 1), (2, 1), (3, 2)] {
      let mut numerator = 0
      for i in 0..<5 {
        let mut np = 1
        let mut dp = 1
        for _ in 0..<i {
          np = np * n
        }
        for _ in i..<4 {
          dp = dp * d
        }
        numerator = numerator + coeffs[i] * np * dp
      }
      let denominator = d * d * d * d
      let values = @oracle.chain([@oracle.rational(n, d)])
      let expected = Some(@oracle.rational(numerator, denominator))
      assert_eq(evaluation_reference(p, values), expected)
      assert_eq(evaluate(p, values), expected)
    }
  }
  for kind in 0..<4 {
    for (p, values) in evaluation_cases(kind) {
      assert_eq(evaluate(p, values), evaluation_reference(p, values))
      assert_eq(evaluate(p, Nil), evaluation_reference(p, Nil))
      assert_eq(
        evaluate(p, @core.append(values, values)),
        evaluation_reference(p, @core.append(values, values)),
      )
    }
  }
}
