///|
fn dual_product(
  a : (@exact.Rational, @exact.Rational),
  b : (@exact.Rational, @exact.Rational),
) -> Result[(@exact.Rational, @exact.Rational), Unit] {
  Ok(
    (
      @exact.rational_multiply(a.0, b.0),
      @exact.rational_add(
        @exact.rational_multiply(a.0, b.1),
        @exact.rational_multiply(a.1, b.0),
      ),
    ),
  )
}

///|
fn dual_sum(
  a : (@exact.Rational, @exact.Rational),
  b : (@exact.Rational, @exact.Rational),
) -> Result[(@exact.Rational, @exact.Rational), Unit] {
  Ok((@exact.rational_add(a.0, b.0), @exact.rational_add(a.1, b.1)))
}

///|
fn dual_coordinates(
  a : (@exact.Rational, @exact.Rational),
) -> @core.Chain[@exact.Rational] {
  Cons(a.0, Cons(a.1, Nil))
}

///|
fn dual_evaluate(
  a : (@exact.Rational, @exact.Rational),
  p : @poly.Polynomial,
) -> (@exact.Rational, @exact.Rational)? {
  let zero = @exact.rational_zero()
  @poly.evaluate_in(
    a,
    p,
    (zero, zero),
    fn(c) { (c, zero) },
    dual_sum,
    dual_product,
  )
}

///|
fn dual_is_zero(a : (@exact.Rational, @exact.Rational)) -> Bool {
  a.0.equal(@exact.rational_zero()) && a.1.equal(@exact.rational_zero())
}

///|
fn power_fixture(cs : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      cs.mapi(fn(i, c) {
        @poly.Term::{
          coefficient: @oracle.rational(c, 1),
          exponents: Cons(@oracle.nat(i), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
test "power minimality also applies to nilpotents in a finite algebra which is not a field" {
  let z = @exact.rational_zero()
  let o = @exact.rational_one()
  let unit = (o, z)
  let epsilon = (z, o)
  let square = power_fixture([0, 0, 1])
  let minimum = power_minimal_polynomial(
    epsilon,
    unit,
    @oracle.nat(2),
    dual_coordinates,
    dual_product,
  ).unwrap()
  assert_eq(minimum, square)
  assert_true(
    check_power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(2),
      dual_coordinates,
      dual_product,
      dual_evaluate,
      dual_is_zero,
      square,
    ),
  )
  // A faithful embedding in a larger ambient coordinate space must still reject
  // a higher-degree annihilator by rank, rather than only the dimension bound.
  let padded = fn(a) {
    @core.append(dual_coordinates(a), Cons(z, Cons(z, Nil)))
  }
  assert_eq(
    power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(4),
      padded,
      dual_product,
    ).unwrap(),
    square,
  )
  let cube = power_fixture([0, 0, 0, 1])
  assert_true(dual_is_zero(dual_evaluate(epsilon, cube).unwrap()))
  assert_false(
    check_power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(4),
      padded,
      dual_product,
      dual_evaluate,
      dual_is_zero,
      cube,
    ),
  )
  assert_eq(
    power_minimal_polynomial(
      (z, z),
      unit,
      @oracle.nat(2),
      dual_coordinates,
      dual_product,
    ).unwrap(),
    power_fixture([0, 1]),
  )
}

///|
test "power algorithms keep callback and coordinate failures explicit" {
  let z = @exact.rational_zero()
  let o = @exact.rational_one()
  let epsilon = (z, o)
  let unit = (o, z)
  let fail_product : (
    (@exact.Rational, @exact.Rational),
    (@exact.Rational, @exact.Rational),
  ) -> Result[(@exact.Rational, @exact.Rational), Unit] = fn(_, _) { Err(()) }
  assert_true(
    power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(2),
      dual_coordinates,
      fail_product,
    )
    is None,
  )
  assert_false(
    check_power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(2),
      dual_coordinates,
      fail_product,
      dual_evaluate,
      dual_is_zero,
      power_fixture([0, 0, 1]),
    ),
  )
  let wrong_shape = fn(_) { @core.Cons(z, @core.Nil) }
  assert_true(
    power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(2),
      wrong_shape,
      dual_product,
    )
    is None,
  )
  assert_false(
    check_power_minimal_polynomial(
      epsilon,
      unit,
      @oracle.nat(2),
      wrong_shape,
      dual_product,
      dual_evaluate,
      dual_is_zero,
      power_fixture([0, 0, 1]),
    ),
  )
}
