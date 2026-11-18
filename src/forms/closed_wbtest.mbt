///|
test "closed and exact constructors preserve grading and reject nonclosed input" {
  let constant = scalar(fixture_polynomial(2, [(3, 2, [0, 0])]))
  let known = closed_form(constant).unwrap()
  assert_eq(known.primitive(), Err(ZeroDegree))
  assert_eq(known.exterior_derivative(), zero(@oracle.nat(2), Succ(Zero)))
  let function = scalar(fixture_polynomial(2, [(1, 1, [1, 0])]))
  assert_eq(closed_form(function), Err(NotClosed))
  let nonclosed = fixture_form(2, 1, [([(1, 1, [1, 0])], [1])])
  assert_eq(closed_form(nonclosed), Err(NotClosed))
  for n in 0..<4 {
    for k in 0..<6 {
      let value = zero(@oracle.nat(n), @oracle.nat(k))
      let closed = closed_form(value).unwrap()
      assert_eq(
        closed.exterior_derivative(),
        zero(@oracle.nat(n), @oracle.nat(k + 1)),
      )
      if k == 0 {
        assert_eq(closed.primitive(), Err(ZeroDegree))
      } else {
        let exact = closed.primitive().unwrap()
        assert_eq(exact.value(), value)
        assert_eq(exact.primitive(), zero(@oracle.nat(n), @oracle.nat(k - 1)))
        assert_true(exact.check())
      }
      let exact = exact_differential(value).unwrap()
      assert_eq(exact.value(), zero(@oracle.nat(n), @oracle.nat(k + 1)))
      assert_true(exact.check())
    }
  }
  let top = fixture_form(2, 2, [([(2, 3, [2, 1])], [0, 1])])
  let exact = closed_form(top).unwrap().primitive().unwrap()
  assert_true(exact.check())
  assert_eq(exact.value(), top)
}

///|
test "exact equality ignores primitive choice and addition retains witnesses" {
  let function = scalar(fixture_polynomial(2, [(1, 1, [2, 1])]))
  let shifted = scalar(fixture_polynomial(2, [(1, 1, [2, 1]), (7, 3, [0, 0])]))
  let a = exact_differential(function).unwrap()
  let b = exact_differential(shifted).unwrap()
  assert_eq(a, b)
  assert_true(a.primitive() != b.primitive())
  assert_true(a.check())
  assert_true(b.check())
  let sum = a.add(b).unwrap()
  assert_eq(sum.value(), add(a.value(), b.value()).unwrap())
  assert_eq(sum.primitive(), add(function, shifted).unwrap())
  assert_true(sum.check())
  assert_true(a.negate().check())
  assert_eq(a.negate().value(), negate(a.value()))
  let cancelled = a.add(a.negate()).unwrap()
  assert_true(is_zero(cancelled.value()))
  assert_true(cancelled.check())
  assert_eq(a.as_closed().add(b.as_closed()).unwrap().value(), sum.value())
  assert_eq(a.as_closed().negate().value(), a.negate().value())
}

///|
test "graded exact products transport primitives on either side with the correct sign" {
  for p in 0..<4 {
    let n = p + 1
    let exponents = Array::make(n, 0)
    let basis = Array::makei(p, fn(i) { i + 1 })
    let closed = closed_form(fixture_form(n, p, [([(1, 1, exponents)], basis)])).unwrap()
    let x_exponents = Array::makei(n, fn(i) { if i == 0 { 1 } else { 0 } })
    let dx = exact_differential(
      scalar(fixture_polynomial(n, [(1, 1, x_exponents)])),
    ).unwrap()
    let right = closed.wedge_exact(dx).unwrap()
    let left = dx.wedge_closed(closed).unwrap()
    let sign = if p % 2 == 0 { 1 } else { -1 }
    let all_indices = Array::makei(n, fn(i) { i })
    assert_eq(
      terms(right.value()),
      fixture_terms(n, [([(sign, 1, exponents)], all_indices)]),
    )
    assert_eq(
      terms(left.value()),
      fixture_terms(n, [([(1, 1, exponents)], all_indices)]),
    )
    assert_true(right.check())
    assert_true(left.check())
    assert_eq(closed.wedge(dx.as_closed()).unwrap().value(), right.value())
    assert_eq(exterior_derivative(right.primitive()), Ok(right.value()))
    assert_eq(exterior_derivative(left.primitive()), Ok(left.value()))
  }
  let a = exact_differential(scalar(fixture_polynomial(2, [(1, 1, [2, 0])]))).unwrap()
  let b = exact_differential(scalar(fixture_polynomial(2, [(3, 2, [0, 2])]))).unwrap()
  let product = a.wedge(b).unwrap()
  assert_eq(
    terms(product.value()),
    fixture_terms(2, [([(6, 1, [1, 1])], [0, 1])]),
  )
  assert_true(product.check())
}

///|
test "nonlinear pullbacks preserve closedness and primitive equations" {
  let mapping = fixture_map(2, [[(1, 1, [2, 0])], [(1, 1, [1, 1])]])
  let primitive = fixture_form(2, 1, [([(1, 1, [1, 0])], [1])])
  let exact = exact_differential(primitive).unwrap()
  let pulled = exact.pullback(mapping).unwrap()
  assert_eq(
    terms(pulled.value()),
    fixture_terms(2, [([(2, 1, [2, 0])], [0, 1])]),
  )
  assert_true(pulled.check())
  assert_eq(pulled.primitive(), pullback(mapping, primitive).unwrap())
  let closed = exact.as_closed().pullback(mapping).unwrap()
  assert_eq(closed.value(), pulled.value())
  assert_eq(
    exterior_derivative(closed.value()),
    Ok(closed.exterior_derivative()),
  )
  let empty = polynomial_map(Zero, Nil).unwrap()
  let point = exact_differential(scalar(fixture_polynomial(0, [(7, 1, [])]))).unwrap()
  assert_true(point.pullback(empty).unwrap().check())
}

///|
test "typed operations check spaces and degrees before using zero laws" {
  let a = closed_form(zero(@oracle.nat(2), Succ(Zero))).unwrap()
  let b = closed_form(zero(@oracle.nat(3), Succ(Zero))).unwrap()
  let c = closed_form(zero(@oracle.nat(2), @oracle.nat(2))).unwrap()
  assert_eq(a.add(b), Err(DimensionMismatch))
  assert_eq(a.add(c), Err(DegreeMismatch))
  assert_eq(a.wedge(b), Err(DimensionMismatch))
  let ea = a.primitive().unwrap()
  let eb = b.primitive().unwrap()
  let ec = c.primitive().unwrap()
  assert_eq(ea.add(eb), Err(DimensionMismatch))
  assert_eq(ea.add(ec), Err(DegreeMismatch))
  assert_eq(ea.wedge(eb), Err(DimensionMismatch))
  assert_eq(ea.wedge_closed(b), Err(DimensionMismatch))
  assert_eq(a.wedge_exact(eb), Err(DimensionMismatch))
  let wrong = polynomial_map(Zero, Nil).unwrap()
  assert_eq(a.pullback(wrong), Err(DimensionMismatch))
  assert_eq(ea.pullback(wrong), Err(DimensionMismatch))
}

///|
test "all exterior basis pairs through dimension six match inversion-count signs" {
  for n in 0..<7 {
    for mask_a in 0..<(1 << n) {
      let a = []
      for i in 0..<n {
        if (mask_a & (1 << i)) != 0 {
          a.push(i)
        }
      }
      for mask_b in 0..<(1 << n) {
        let b = []
        for i in 0..<n {
          if (mask_b & (1 << i)) != 0 {
            b.push(i)
          }
        }
        let exponents = Array::make(n, 0)
        let left = fixture_form(n, a.length(), [([(1, 1, exponents)], a)])
        let right = fixture_form(n, b.length(), [([(1, 1, exponents)], b)])
        let actual = wedge(left, right).unwrap()
        assert_eq(degree(actual), @oracle.nat(a.length() + b.length()))
        if (mask_a & mask_b) != 0 {
          assert_true(is_zero(actual))
        } else {
          let union = []
          for i in 0..<n {
            if ((mask_a | mask_b) & (1 << i)) != 0 {
              union.push(i)
            }
          }
          let mut inversions = 0
          for i in a {
            for j in b {
              if i > j {
                inversions += 1
              }
            }
          }
          let sign = if inversions % 2 == 0 { 1 } else { -1 }
          assert_eq(
            terms(actual),
            fixture_terms(n, [([(sign, 1, exponents)], union)]),
          )
        }
      }
    }
  }
}
