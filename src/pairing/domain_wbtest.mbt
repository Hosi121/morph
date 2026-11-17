///|
test "Tate parameters use full extension cardinality and reject bad orders" {
  let field = pa_field(5, [2, 0, 1])
  let c = pa_curve(field)
  for n in [0, 1] {
    assert_true(parameters(c, @oracle.binary(n)) is Err(InvalidOrder))
  }
  assert_true(parameters(c, @oracle.binary(5)) is Err(CharacteristicDivisor))
  assert_true(parameters(c, @oracle.binary(7)) is Err(OrderNotDivisor))
  assert_true(parameters(c, @oracle.binary(32)) is Err(OrderNotDivisor))
  for (n, expected) in [(2, 12), (3, 8), (6, 4)] {
    let checked = parameters(c, @oracle.binary(n)).unwrap()
    assert_true(@ec.same_curve(parent(checked), c))
    assert_eq(@oracle.int_of_binary(order(checked)), n)
    assert_eq(@oracle.int_of_binary(field_size(checked)), 25)
    assert_eq(@oracle.int_of_binary(final_exponent(checked)), expected)
  }
}

///|
test "pairing context and torsion checks precede identity shortcuts" {
  let field = pa_field(5, [2, 0, 1])
  let other_field = pa_field(5, [3, 0, 1])
  let c = pa_curve(field)
  let other = pa_curve(other_field)
  let checked = parameters(c, @oracle.binary(3)).unwrap()
  let unit = @ec.infinity(c)
  let foreign = @ec.infinity(other)
  let p = @ec.point(c, @gf.zero(field), @gf.one(field)).unwrap()
  let two_torsion = @ec.point(
    c,
    @gf.constant(field, @oracle.binary(4)),
    @gf.zero(field),
  ).unwrap()
  assert_true(line_quotient(unit, unit, foreign) is Err(DifferentCurve))
  assert_true(line_quotient(unit, foreign, unit) is Err(DifferentCurve))
  assert_true(miller(unit, @oracle.binary(0), foreign) is Err(DifferentCurve))
  assert_true(reduced_tate(checked, foreign, unit, unit) is Err(DifferentCurve))
  assert_true(reduced_tate(checked, unit, foreign, unit) is Err(DifferentCurve))
  assert_true(reduced_tate(checked, unit, unit, foreign) is Err(DifferentCurve))
  assert_true(reduced_tate(checked, two_torsion, unit, unit) is Err(NotTorsion))
  assert_true(
    reduced_tate(checked, unit, p, unit).unwrap().equal(@gf.one(field)),
  )
  assert_true(
    reduced_tate(checked, p, unit, unit).unwrap().equal(@gf.one(field)),
  )
  let different = @ec.curve(field, @gf.one(field), @gf.one(field)).unwrap()
  assert_true(
    miller(p, @oracle.binary(1), @ec.infinity(different)) is Err(DifferentCurve),
  )
}

///|
test "Miller has explicit support exclusions including removable factor poles" {
  let field = pa_field(5, [0, 1])
  let c = pa_curve(field)
  let p = @ec.point(c, @gf.zero(field), @gf.one(field)).unwrap()
  let negative = @ec.negate(p)
  let infinity = @ec.infinity(c)
  let two_torsion = @ec.point(
    c,
    @gf.constant(field, @oracle.binary(4)),
    @gf.zero(field),
  ).unwrap()
  assert_true(line_quotient(p, p, infinity) is Err(EvaluationAtInfinity))
  assert_true(line_quotient(p, p, p) is Err(IndeterminateEvaluation))
  assert_true(
    line_quotient(two_torsion, two_torsion, two_torsion) is Err(ZeroEvaluation),
  )
  assert_true(line_quotient(p, p, negative) is Err(PoleEvaluation))
  // The vertical factor would cancel this pole in the final f_three.
  // The declared partial Miller path intentionally does not perform that cancellation.
  assert_true(miller(p, @oracle.binary(3), negative) is Err(PoleEvaluation))
  let at_unit = line_quotient(infinity, p, infinity).unwrap()
  assert_true(value(at_unit).equal(@gf.one(field)))
  assert_true(@ec.equal(multiple(at_unit), p).unwrap())
  for scalar in [0, 1] {
    assert_true(
      value(miller(p, @oracle.binary(scalar), infinity).unwrap()).equal(
        @gf.one(field),
      ),
    )
  }
}
