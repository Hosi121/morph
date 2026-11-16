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
fn projection_fixture(
  mode : Method,
  original : @core.Chain[@poly.Polynomial],
  selected : Int32,
  expected_coefficients : @core.Chain[@poly.Polynomial],
  expected_principal : @core.Chain[@poly.Polynomial],
  expected_product : @poly.Polynomial?,
  specializations : Array[
    (@exact.Rational, @core.Chain[@exact.Rational], @core.Nat?),
  ],
) -> Unit raise {
  let plan = match mode {
    CollinsProjection => full_collins(original, @oracle.nat(selected)).unwrap()
    ProductProjection =>
      product_projection(original, @oracle.nat(selected)).unwrap()
  }
  assert_eq(atoms(plan), original)
  assert_eq(variable(plan), @oracle.nat(selected))
  assert_eq(coefficients(plan), expected_coefficients)
  assert_eq(principal_coefficients(plan), expected_principal)
  assert_eq(product(plan), expected_product)
  assert_eq(
    polynomials(plan),
    @core.append(expected_coefficients, expected_principal),
  )
  assert_true(
    @core.all(polynomials(plan), fn(p) { @poly.variables(p) == @oracle.nat(1) }),
  )
  assert_true(
    check_result(mode, original, @oracle.nat(selected), plan, certificate(plan)),
  )
  for (point, expected, gcd_degree) in specializations {
    let actual = @core.map(principal_coefficients(plan), fn(p) {
      @poly.evaluate(p, @core.Cons(point, @core.Nil)).unwrap()
    })
    assert_eq(actual, expected)
    match gcd_degree {
      Some(degree) =>
        assert_eq(
          @eliminate.first_nonzero(actual, @exact.rational_zero(), fn(a, b) {
            a == b
          }),
          Some(degree),
        )
      None => ()
    }
  }
}
