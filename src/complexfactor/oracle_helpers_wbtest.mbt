///|
fn oracle_univariate(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(
            coefficients[index].0,
            coefficients[index].1,
          ),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn oracle_bivariate(
  terms : Array[((Int32, Int32), Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      terms.map(fn(term) {
        {
          coefficient: @oracle.rational(term.0.0, term.0.1),
          exponents: @oracle.chain(term.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn oracle_family(source : @poly.Polynomial) -> RootFamily {
  let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
  let problem = match
    prepare(
      source,
      primes,
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Prepared(problem) => problem
    _ => abort("small independent factorization must be verified")
  }
  fn finish(state : Search, calls : Int32) -> RootFamily {
    if calls == 0 {
      abort("small independent factored roots must finish")
    }
    match run(state, @oracle.nat(12), @oracle.nat(3000)).unwrap() {
      Complete(value) => value
      Paused(next, _) => finish(next, calls - 1)
    }
  }
  finish(start(problem), 96)
}

///|
fn oracle_in_box(
  value : Root,
  box : ((Int32, Int32), (Int32, Int32), (Int32, Int32), (Int32, Int32), Int32),
) -> Bool {
  let isolated = root(value)
  let coordinates = @oracle.array(
    @complexroots.coordinate_expressions(isolated),
  )
  let alpha = @complexroots.parameter(isolated)
  let bounds = [(box.0, box.1), (box.2, box.3)]
  for index in 0..<2 {
    let lower = @poly.subtract(
      coordinates[index],
      @poly.constant(
        Succ(Zero),
        @oracle.rational(bounds[index].0.0, bounds[index].0.1),
      ),
    ).unwrap()
    let upper = @poly.subtract(
      coordinates[index],
      @poly.constant(
        Succ(Zero),
        @oracle.rational(bounds[index].1.0, bounds[index].1.1),
      ),
    ).unwrap()
    if @tarski.sign_at(alpha, lower).unwrap().sign == @core.Less ||
      @tarski.sign_at(alpha, upper).unwrap().sign == @core.Greater {
      return false
    }
  }
  true
}

///|
/// All twelve independent cases include full source factorization, every root,
/// exact box membership and original-source multiplicities. No special-case
/// input avoids the mixed-factor regression at this higher-level entry point.
fn assert_factored_complex_fixture(
  coefficients : Array[(Int32, Int32)],
  expected_real : Array[((Int32, Int32), Array[Int32])],
  expected_imaginary : Array[((Int32, Int32), Array[Int32])],
  boxes : Array[
    ((Int32, Int32), (Int32, Int32), (Int32, Int32), (Int32, Int32), Int32),
  ],
) -> Unit raise {
  let input = oracle_univariate(coefficients)
  let expanded = @complexroots.cartesian(input).unwrap()
  assert_eq(expanded.real, oracle_bivariate(expected_real))
  assert_eq(expanded.imaginary, oracle_bivariate(expected_imaginary))
  let family = oracle_family(input)
  assert_eq(source(family), input)
  assert_eq(
    check_result(input, family, certificate(family), @oracle.nat(500)),
    @zassenhaus.Proven,
  )
  let found = @oracle.array(roots(family))
  assert_eq(found.length(), boxes.length())
  let membership = found.map(fn(value) {
    boxes.map(fn(box) { oracle_in_box(value, box) })
  })
  for i in 0..<found.length() {
    let mut matches = 0
    for j in 0..<boxes.length() {
      if membership[i][j] {
        matches += 1
        assert_eq(@oracle.int_of_nat(multiplicity(found[i])), boxes[j].4)
      }
    }
    assert_eq(matches, 1)
  }
  for j in 0..<boxes.length() {
    let mut matches = 0
    for i in 0..<found.length() {
      if membership[i][j] {
        matches += 1
      }
    }
    assert_eq(matches, 1)
  }
}
