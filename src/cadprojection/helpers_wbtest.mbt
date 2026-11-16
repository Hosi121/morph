///|
fn elimination_rat(
  negative : Bool,
  numerator : String,
  denominator : String,
) -> @exact.Rational {
  let n = @exact.positive(@oracle.binary_from_hex(numerator))
  @exact.ratio(
    if negative {
      @exact.negate(n)
    } else {
      n
    },
    @oracle.binary_from_hex(denominator),
  ).unwrap()
}

///|
fn elimination_poly(
  variables : Int32,
  terms : Array[(@exact.Rational, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(term) {
        @poly.Term::{
          coefficient: term.0,
          exponents: @oracle.chain(term.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn one_step_fixture(
  arity : @core.Nat,
  original : @core.Chain[@poly.Polynomial],
  expected : ProjectionCertificate,
) -> Unit raise {
  let actual = full_collins(arity, original).unwrap()
  assert_eq(actual, expected)
  let remaining = match arity {
    Succ(n) => n
    Zero => abort("one_step_fixture needs positive arity")
  }
  assert_true(
    @core.all(projection_polynomials(actual), fn(p) {
      @poly.variables(p) == remaining
    }),
  )
  assert_true(check_projection(arity, original, actual))
  if arity == @oracle.nat(2) {
    let old = @old.full_collins(original, @oracle.nat(1)).unwrap()
    assert_eq(projection_polynomials(actual), @old.polynomials(old))
  }
}

///|
fn hierarchy_fixture(
  arity : @core.Nat,
  original : @core.Chain[@poly.Polynomial],
  expected : @core.Chain[Level],
) -> Unit raise {
  let plan = prepare(arity, original).unwrap()
  assert_eq(levels(plan), expected)
  assert_eq(@core.length(levels(plan)), @core.Succ(arity))
  assert_eq(atoms(plan), original)
  assert_eq(level(plan, arity).unwrap().source, original)
  assert_true(check_result(arity, original, plan, certificate(plan)))
  for dimension in 0..<=5 {
    match level(plan, @oracle.nat(dimension)) {
      None => assert_true(dimension > nat_int(arity))
      Some(entry) => {
        assert_eq(entry.arity, @oracle.nat(dimension))
        assert_true(
          @core.all(entry.family, fn(p) { @poly.variables(p) == entry.arity }),
        )
        assert_eq(@core.length(entry.derivatives), @core.length(entry.family))
      }
    }
  }
}

///|
fn nat_int(n : @core.Nat) -> Int32 {
  match n {
    Zero => 0
    Succ(n) => nat_int(n) + 1
  }
}
