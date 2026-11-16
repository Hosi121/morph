///|
fn review_poly(
  variables : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(t) {
        @poly.Term::{
          coefficient: @oracle.rational(t.0, t.1),
          exponents: @oracle.chain(t.2.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn review_fo_fixture(
  free : Int32,
  source : @logic.Formula,
  points : Array[(Array[(Int32, Int32)], Bool)],
) -> Unit raise {
  let result = solve(free, source)
  assert_true(
    check_result(@oracle.nat(free), source, result, certificate(result)),
  )
  assert_true(
    @core.all(@logic.qf_atoms(quantifier_free(result)), fn(p) {
      @poly.variables(p) == @oracle.nat(free)
    }),
  )
  for (coordinates, expected) in points {
    let sample = @cad.rational_point(
      @oracle.chain(coordinates.map(fn(p) { @oracle.rational(p.0, p.1) })),
    )
    assert_eq(
      @cad.evaluate_formula(sample, quantifier_free(result)),
      Ok(expected),
    )
    if free == 0 {
      assert_eq(truth(result), Some(expected))
    } else {
      assert_eq(truth(result), None)
    }
  }
}
