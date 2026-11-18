///|
fn hf_space(g : Array[Array[HFRat]]) -> Space {
  space(@positiveform.positive_definite(hf_matrix(g)).unwrap(), Positive).unwrap()
}

///|
test "positive volume roots collapse rational squares and realize irrational roots" {
  let rational = hf_space([[(4, 9), (0, 1)], [(0, 1), (25, 16)]])
  assert_eq(rational.rational_volume(), Some(@oracle.rational(5, 6)))
  assert_true(
    rational
    .scalar(@oracle.rational(-5, 6), @exact.rational_one())
    .is_zero()
    .unwrap(),
  )
  let s = hf_space([[(2, 1), (0, 1)], [(0, 1), (3, 1)]])
  assert_eq(s.rational_volume(), None)
  let generator = s.scalar(@exact.rational_zero(), @exact.rational_one())
  assert_true(
    generator
    .wedge(generator)
    .unwrap()
    .equivalent(s.scalar(@oracle.rational(6, 1), @exact.rational_zero()))
    .unwrap(),
  )
  let root = s.volume_root().unwrap()
  let certificate = @realalgebraic.root_certificate(root)
  assert_eq(certificate.interval.lower, @exact.rational_zero())
  assert_true(@realalgebraic.check_root(certificate))
  let (square, proof) = match
    @realalgebraic.multiply(root, root, @oracle.nat(100)) {
    Ok(ArithmeticReady(value, proof)) => (value, proof)
    _ =>
      abort(
        "volume square did not finish within the fixed exact arithmetic budget",
      )
  }
  assert_true(@realalgebraic.check_arithmetic_result(square, proof))
  match
    @realalgebraic.compare(
      square,
      @realalgebraic.rational(@oracle.rational(6, 1)).unwrap(),
      @oracle.nat(100),
    ) {
    Ok(Compared(order, certificate)) => {
      assert_eq(order, @core.Equal)
      assert_true(@realalgebraic.check_comparison_result(order, certificate))
    }
    _ => abort("exact volume-square comparison did not finish")
  }
}

///|
test "orientation changes Hodge signs and volume has unit norm" {
  let s = hf_space([[(2, 1), (1, 1)], [(1, 1), (2, 1)]])
  let reversed = s.reverse_orientation()
  assert_eq(reversed.reverse_orientation(), s)
  let dx = hf_form(2, 1, [([(1, 1, [0, 0])], [0])])
  let positive = s.lift(dx).unwrap().star().parts().unwrap()
  let negative = reversed.lift(dx).unwrap().star().parts().unwrap()
  assert_eq(negative.rational, @forms.negate(positive.rational))
  assert_eq(negative.radical, @forms.negate(positive.radical))
  let one = s.scalar(@exact.rational_one(), @exact.rational_zero())
  assert_true(s.volume().star().equivalent(one).unwrap())
  let expanded_volume = s.from_parts(s.volume().parts().unwrap()).unwrap()
  assert_true(
    expanded_volume.inner(expanded_volume).unwrap().equivalent(one).unwrap(),
  )
  let point = hf_space([])
  assert_eq(point.rational_volume(), Some(@exact.rational_one()))
  assert_true(
    point
    .volume()
    .star()
    .equivalent(point.scalar(@exact.rational_one(), @exact.rational_zero()))
    .unwrap(),
  )
}

///|
test "metric and orientation contexts are checked before zero shortcuts" {
  let s = hf_space([[(2, 1), (0, 1)], [(0, 1), (3, 1)]])
  let other = hf_space([[(3, 1), (0, 1)], [(0, 1), (2, 1)]])
  assert_eq(s.volume_squared(), other.volume_squared())
  let a = s.zero(Succ(Zero)).unwrap()
  let b = other.zero(Succ(Zero)).unwrap()
  assert_eq(a.add(b), Err(SpaceMismatch))
  assert_eq(a.wedge(b), Err(SpaceMismatch))
  assert_eq(a.inner(b), Err(SpaceMismatch))
  assert_eq(a.equivalent(b), Err(SpaceMismatch))
  assert_eq(s.prepare(Succ(Zero)).unwrap().apply(b), Err(SpaceMismatch))
  assert_eq(
    a.add(s.reverse_orientation().zero(Succ(Zero)).unwrap()),
    Err(SpaceMismatch),
  )
  assert_eq(a.add(s.zero(Zero).unwrap()), Err(DegreeMismatch))
  assert_eq(
    s.prepare(Succ(Zero)).unwrap().apply(s.zero(Zero).unwrap()),
    Err(DegreeMismatch),
  )
  assert_eq(s.prepare(@oracle.nat(3)), Err(DegreeOutOfRange))
  assert_eq(
    s.lift(@forms.zero(@oracle.nat(2), @oracle.nat(3))),
    Err(DegreeOutOfRange),
  )
  assert_eq(s.lift(@forms.zero(@oracle.nat(3), Zero)), Err(DimensionMismatch))
  assert_eq(
    s.from_parts({
      rational: @forms.zero(@oracle.nat(2), Zero),
      radical: @forms.zero(@oracle.nat(2), Succ(Zero)),
    }),
    Err(DegreeMismatch),
  )
  assert_eq(s.zero(@oracle.nat(2)).unwrap().wedge(a), Err(DegreeOutOfRange))
}

///|
test "equal metric values share a context despite different positive-form decompositions" {
  let a = @positiveform.positive_definite(hf_matrix([[(2, 1)]])).unwrap()
  let b = @positiveform.positive_definite(hf_matrix([[(3, 1)]])).unwrap()
  let blocks = space(a.direct_sum(b), Positive).unwrap()
  let dense = hf_space([[(2, 1), (0, 1)], [(0, 1), (3, 1)]])
  assert_eq(blocks, dense)
  assert_eq(
    blocks
    .zero(Zero)
    .unwrap()
    .add(dense.zero(Zero).unwrap())
    .unwrap()
    .is_zero()
    .unwrap(),
    true,
  )
  let x = dense.lift(hf_form(2, 1, [([(1, 1, [0, 0])], [0])])).unwrap()
  assert_true(
    blocks
    .prepare(Succ(Zero))
    .unwrap()
    .apply(x)
    .unwrap()
    .equivalent(x.star())
    .unwrap(),
  )
}

///|
test "polynomial quadratic coefficients obey Hodge linearity and graded exterior products" {
  let s = hf_space([[(2, 1), (1, 1)], [(1, 1), (2, 1)]])
  let a = s
    .from_parts({
      rational: hf_form(2, 1, [([(1, 1, [1, 0])], [0])]),
      radical: hf_form(2, 1, [([(1, 2, [0, 1])], [1])]),
    })
    .unwrap()
  let b = s
    .lift(hf_form(2, 1, [([(2, 3, [0, 1])], [0]), ([(1, 1, [1, 0])], [1])]))
    .unwrap()
  assert_true(
    a
    .add(b)
    .unwrap()
    .star()
    .equivalent(a.star().add(b.star()).unwrap())
    .unwrap(),
  )
  assert_true(
    a
    .scale(@oracle.rational(-2, 3))
    .unwrap()
    .star()
    .equivalent(a.star().scale(@oracle.rational(-2, 3)).unwrap())
    .unwrap(),
  )
  assert_true(a.wedge(a).unwrap().is_zero().unwrap())
  assert_true(
    a.wedge(b).unwrap().equivalent(b.wedge(a).unwrap().negate()).unwrap(),
  )
  assert_true(a.add(a.negate()).unwrap().is_zero().unwrap())
  assert_eq(a.negate().negate(), a)
  assert_eq(a.star().star(), a.negate())
  assert_true(a.star().star().star().star().equivalent(a).unwrap())
  assert_eq(s.zero(Succ(Zero)).unwrap().star().is_zero().unwrap(), true)
}

///|
test "Gaussian Hessian Fisher form supplies an oriented metric without repeated SPD validation" {
  let source = @gaussian.gaussian(
    Cons(@exact.rational_zero(), Nil),
    hf_matrix([[(1, 1)]]),
  ).unwrap()
  let point = @statgeometry.gaussian_hessian(
    @gaussian.information(source).unwrap(),
  ).unwrap()
  let s = space(point.metric_form(), Positive).unwrap()
  assert_eq(s.dimension(), @oracle.nat(2))
  assert_eq(s.volume_squared().value(), @oracle.rational(2, 1))
  assert_eq(s.rational_volume(), None)
  let dx = s.lift(hf_form(2, 1, [([(1, 1, [0, 0])], [0])])).unwrap()
  let dy = s.lift(hf_form(2, 1, [([(1, 1, [0, 0])], [1])])).unwrap()
  hf_assert_parts(dx.star().parts().unwrap(), 2, 1, [], [
    ([(1, 1, [0, 0])], [1]),
  ])
  hf_assert_parts(dy.star().parts().unwrap(), 2, 1, [], [
    ([(-1, 2, [0, 0])], [0]),
  ])
}
