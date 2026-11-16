///|
test "independent coherent private Problem atoms and projection mismatch rejected" {
  let original = @qf.Atom(
    polynomial_fixture(1, [(1, [2]), (-2, [0])]),
    @qf.EqualZero,
  )
  let unrelated = @qf.Atom(
    polynomial_fixture(1, [(1, [2]), (1, [0])]),
    @qf.EqualZero,
  )
  let good = make_problem(1, original)
  let bad = make_problem(1, unrelated)
  let forged = Problem::{
    ..good,
    atoms: bad.atoms,
    projection: bad.projection,
  }
  let generated = finish(forged, 500)
  let proof = certificate(generated)
  // The unrelated root family misses both roots of x^2-2. Every generated leaf
  // therefore says false, even though the original existential is true.
  assert_eq(
    sentence(generated, @oracle.chain([@logic.Quantifier::Exists])),
    Ok(false),
  )
  assert_true(check(good, proof) is None)
  assert_true(check(forged, proof) is None)
  assert_false(check_result(forged, generated, proof))
  let qe = eliminate(
    generated,
    @core.Zero,
    @oracle.chain([@logic.Quantifier::Exists]),
  ).unwrap()
  assert_true(
    check_elimination(
      forged,
      @core.Zero,
      @oracle.chain([@logic.Quantifier::Exists]),
      elimination_certificate(qe),
    )
    is None,
  )
}
