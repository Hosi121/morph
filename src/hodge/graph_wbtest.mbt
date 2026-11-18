///|
fn hf_basis(s : Space, indices : Array[Int32]) -> HodgeForm {
  let n = @oracle.int_of_nat(s.dimension())
  s
  .lift(hf_form(n, indices.length(), [([(1, 1, Array::make(n, 0))], indices)]))
  .unwrap()
}

///|
test "decomposable wedges remain graphs and Hodge uses contractions with volume" {
  for
    g in [
      [
        [(1, 1), (0, 1), (0, 1)],
        [(0, 1), (1, 1), (0, 1)],
        [(0, 1), (0, 1), (1, 1)],
      ],
      [
        [(2, 1), (1, 1), (0, 1)],
        [(1, 1), (3, 1), (1, 1)],
        [(0, 1), (1, 1), (2, 1)],
      ],
    ] {
    let s = hf_space(g)
    let dx = hf_basis(s, [0])
    let dy = hf_basis(s, [1])
    let dz = hf_basis(s, [2])
    let a = dx.add(dy).unwrap()
    let b = dy.add(dz).unwrap()
    let expression = a.wedge(b).unwrap()
    assert_true(
      expression.expression
      is Wedged(
        { expression: Added(_, _), .. },
        { expression: Added(_, _), .. }
      ),
    )
    let star = expression.star()
    assert_eq(star.parts_with(InteriorProduct), star.parts_with(Factorized))
    let contraction = s
      .volume()
      .contract_sharp(a)
      .unwrap()
      .contract_sharp(b)
      .unwrap()
    assert_eq(contraction.parts(), star.parts())
    let expanded = s
      .lift(
        hf_form(3, 2, [
          ([(1, 1, [0, 0, 0])], [0, 1]),
          ([(1, 1, [0, 0, 0])], [0, 2]),
          ([(1, 1, [0, 0, 0])], [1, 2]),
        ]),
      )
      .unwrap()
    assert_true(expression.equivalent(expanded).unwrap())
    assert_eq(star.parts(), expanded.star().parts())
  }
  let s = hf_space([
    [(1, 1), (0, 1), (0, 1)],
    [(0, 1), (1, 1), (0, 1)],
    [(0, 1), (0, 1), (1, 1)],
  ])
  let alpha = hf_basis(s, [0])
    .add(hf_basis(s, [1]))
    .unwrap()
    .wedge(hf_basis(s, [1]).add(hf_basis(s, [2])).unwrap())
    .unwrap()
  hf_assert_parts(
    alpha.star().parts_with(InteriorProduct).unwrap(),
    3,
    1,
    [
      ([(1, 1, [0, 0, 0])], [0]),
      ([(-1, 1, [0, 0, 0])], [1]),
      ([(1, 1, [0, 0, 0])], [2]),
    ],
    [],
  )
}

///|
test "dimension twenty-four middle-degree sparse action enumerates no exterior bases" {
  let n = 24
  let g = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { (if i == j { 1 } else { 0 }, 1) })
  })
  let s = hf_space(g)
  let prepared = s.prepare(@oracle.nat(12)).unwrap()
  assert_eq(@core.length(s.congruence_value.shears()), @core.Zero)
  assert_eq(@core.length(s.congruence_value.diagonal()), @oracle.nat(n))
  let basis = hf_basis(s, Array::makei(12, fn(i) { i }))
  let result = prepared.apply(basis).unwrap().parts().unwrap()
  hf_assert_parts(
    result,
    n,
    12,
    [([(1, 1, Array::make(n, 0))], Array::makei(12, fn(i) { i + 12 }))],
    [],
  )
  assert_eq(basis.star().star(), basis)
  let zero = basis.scale(@exact.rational_zero()).unwrap().star()
  assert_eq(zero.known_zero(), Some(true))
  assert_true(zero.is_zero().unwrap())
  assert_true(
    @forms.is_zero(zero.parts_with(InteriorProduct).unwrap().rational),
  )
}

///|
test "inverse scaled and block congruences act without another LDL" {
  let dense = @positiveform.positive_definite(
    hf_matrix([[(2, 1), (1, 1)], [(1, 1), (3, 1)]]),
  ).unwrap()
  let factor = @positiveform.positive_scalar(@oracle.rational(7, 3)).unwrap()
  let scalar = @positiveform.positive_definite(hf_matrix([[(3, 2)]])).unwrap()
  let dense_three = @positiveform.positive_definite(
    hf_matrix([
      [(4, 1), (1, 1), (2, 1)],
      [(1, 1), (3, 1), (1, 1)],
      [(2, 1), (1, 1), (5, 1)],
    ]),
  ).unwrap()
  for
    metric in [
      dense,
      dense_three.inverse(),
      dense.inverse(),
      dense.scale(factor),
      dense.direct_sum(scalar),
      dense.direct_sum(scalar).inverse().scale(factor),
    ] {
    let s = space(metric, Positive).unwrap()
    let fresh = space(
      @positiveform.positive_definite(metric.matrix().unwrap()).unwrap(),
      Positive,
    ).unwrap()
    let n = @oracle.int_of_nat(s.dimension())
    for k in 0..<(n + 1) {
      let a = hf_basis(s, Array::makei(k, fn(i) { i }))
      let b = hf_basis(fresh, Array::makei(k, fn(i) { i }))
      assert_eq(a.star().parts(), b.star().parts())
      assert_eq(a.inner(a).unwrap().parts(), b.inner(b).unwrap().parts())
    }
  }
}

///|
test "local shear graphs preserve degree and inverse action cancels" {
  let s = hf_space([
    [(2, 1), (1, 1), (0, 1)],
    [(1, 1), (3, 1), (1, 1)],
    [(0, 1), (1, 1), (2, 1)],
  ])
  let input = hf_basis(s, [1])
    .add(hf_basis(s, [2]))
    .unwrap()
    .wedge(hf_basis(s, [0]))
    .unwrap()
  let changed = input
    .shear(@oracle.nat(2), @oracle.nat(1), @oracle.rational(5, 3))
    .unwrap()
  assert_true(changed.expression is Sheared(_, _, _, _))
  assert_true(
    changed
    .shear(@oracle.nat(2), @oracle.nat(1), @oracle.rational(-5, 3))
    .unwrap()
    .equivalent(input)
    .unwrap(),
  )
  assert_eq(
    input.shear(Zero, Zero, @exact.rational_zero()),
    Err(Form(InvalidShear)),
  )
  assert_eq(
    s
    .scalar(@exact.rational_zero(), @exact.rational_zero())
    .contract_sharp(hf_basis(s, [0])),
    Err(DegreeOutOfRange),
  )
}
