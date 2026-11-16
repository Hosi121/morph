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
fn review_qe_fixture(
  variables : Int32,
  free : Int32,
  matrix : @qf.Formula,
  quantifiers : @core.Chain[@logic.Quantifier],
  points : Array[(Array[(Int32, Int32)], Bool)],
) -> Unit raise {
  let problem = make_problem(variables, matrix)
  let decomposition = finish(problem, 100000)
  assert_true(check_result(problem, decomposition, certificate(decomposition)))
  let output = eliminate(decomposition, @oracle.nat(free), quantifiers).unwrap()
  let result = quantifier_free(output)
  assert_true(
    @core.all(@logic.qf_atoms(result), fn(p) {
      @poly.variables(p) == @oracle.nat(free)
    }),
  )
  assert_true(
    check_elimination_result(
      problem,
      @oracle.nat(free),
      quantifiers,
      output,
      elimination_certificate(output),
    ),
  )
  for (coordinates, expected) in points {
    let sample = rational_point(
      @oracle.chain(coordinates.map(fn(p) { @oracle.rational(p.0, p.1) })),
    )
    assert_eq(evaluate_formula(sample, result), Ok(expected))
  }
  match witness(decomposition) {
    Ok(Some(point)) => assert_true(check_witness(problem, point))
    Ok(None) => ()
    Err(error) => fail("witness failed: \{error.to_repr()}")
  }
}
