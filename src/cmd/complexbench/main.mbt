///|
/// Fixed source and host output only; both routes use the same exact kernel.
fn source() -> @poly.Polynomial {
  let coefficients = [-1, 1, -2, 2, -1, 1]
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(coefficients[index], 1),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn main {
  let arguments = @env.args()
  let mode = arguments[arguments.length() - 1]
  let input = source()
  let (count, mass, checked) = if mode == "factored" {
    let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
    let problem = match
      @factor.prepare(
        input,
        primes,
        @oracle.nat(100),
        @oracle.nat(500),
        @oracle.nat(500),
      ).unwrap() {
      Prepared(problem) => problem
      _ => abort("benchmark factorization did not complete")
    }
    match
      @factor.run(@factor.start(problem), @oracle.nat(12), @oracle.nat(3000)).unwrap() {
      Complete(value) => {
        let roots = @factor.roots(value)
        let total = @core.fold_left(roots, @core.Zero, fn(sum, root) {
          @core.add(sum, @factor.multiplicity(root))
        })
        let checked = @factor.check_result(
            input,
            value,
            @factor.certificate(value),
            @oracle.nat(500),
          ) ==
          @zassenhaus.Proven
        (
          @oracle.int_of_nat(@core.length(roots)),
          @oracle.int_of_nat(total),
          checked,
        )
      }
      Paused(_, _) => abort("benchmark root search needs more fuel")
    }
  } else {
    let seed = match mode {
      "unfactored-zero" => @binary.zero()
      "unfactored-two" => @oracle.binary(2)
      _ => abort("mode must be factored, unfactored-zero or unfactored-two")
    }
    let problem = @bare.prepare(input).unwrap()
    match
      @bare.run(
        @bare.start_from(problem, seed),
        @oracle.nat(12),
        @oracle.nat(3000),
      ).unwrap() {
      Complete(value) => {
        let roots = @bare.roots(value)
        let total = @core.fold_left(roots, @core.Zero, fn(sum, root) {
          @core.add(sum, @bare.multiplicity(root))
        })
        let checked = @bare.check_result(input, value, @bare.certificate(value))
        (
          @oracle.int_of_nat(@core.length(roots)),
          @oracle.int_of_nat(total),
          checked,
        )
      }
      Paused(_, _) => abort("benchmark root search needs more fuel")
    }
  }
  if count != 3 || mass != 5 || !checked {
    abort("benchmark result failed exact degree/cover validation")
  }
  println(
    "{\"source\":\"(z^2+1)^2(z-1)\",\"roots\":\{count},\"multiplicity_sum\":\{mass},\"checked\":\{checked}}",
  )
}
