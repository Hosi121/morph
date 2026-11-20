///|
test "binomial residues refute nonlinear chains in several source orders" {
  let xy = test_polynomial(3, [(1, [1, 0, 0]), (-1, [0, 1, 0])])
  let yz = test_polynomial(3, [(1, [0, 1, 0]), (-1, [0, 0, 1])])
  let x2 = test_polynomial(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])])
  let z2 = test_polynomial(3, [(1, [0, 0, 2]), (-2, [0, 0, 0])])
  let atoms : Array[@qf.Formula] = [
    Atom(xy, EqualZero),
    Atom(yz, EqualZero),
    Atom(x2, EqualZero),
    Atom(z2, NotZero),
  ]
  for
    order in [
      [0, 1, 2, 3],
      [3, 2, 1, 0],
      [2, 0, 3, 1],
      [1, 3, 0, 2],
      [2, 1, 0, 3],
      [3, 0, 2, 1],
    ] {
    let source = conjunction_fixture(order.map(i => atoms[i]))
    assert_true(conjunct_conflict(source))
    assert_eq(
      evaluate(test_plan(3, source, [[], [], [], []]), @oracle.nat(0), Nil),
      Ok(Known(false)),
    )
  }
}

///|
test "zero residues distinguish all six strict and nonstrict relations" {
  let same_coordinate = test_polynomial(2, [(1, [1, 0]), (-1, [0, 1])])
  let difference = test_polynomial(2, [(1, [2, 0]), (-1, [0, 2])])
  let relations = test_relations()
  for i, relation in relations {
    let source = conjunction_fixture([
      Atom(same_coordinate, EqualZero),
      Atom(difference, relation),
    ])
    assert_eq(conjunct_conflict(source), !numeric_relation(i, 0))
    let plan = test_plan(2, source, [[], [], []])
    assert_eq(
      evaluate(plan, @oracle.nat(0), Nil),
      Ok(if numeric_relation(i, 0) { Undetermined } else { Known(false) }),
    )
    for x in -3..<=3 {
      for y in -3..<=3 {
        let actual = x == y && numeric_relation(i, x * x - y * y)
        if !numeric_relation(i, 0) {
          assert_false(actual)
        }
        if x == y {
          assert_eq(actual, numeric_relation(i, 0))
        }
      }
    }
  }
}

///|
test "binomial inference keeps zero factors and distinct real branches" {
  let xy0 = test_polynomial(2, [(1, [1, 1])])
  let xy1 = test_polynomial(2, [(1, [1, 1]), (-1, [0, 0])])
  let square = test_polynomial(2, [(1, [2, 2]), (-1, [0, 0])])
  let x = test_polynomial(2, [(1, [1, 0])])
  let difference = test_polynomial(2, [(1, [2, 0]), (-1, [0, 2])])
  let same_coordinate = test_polynomial(2, [(1, [1, 0]), (-1, [0, 1])])
  assert_true(
    conjunct_conflict(
      conjunction_fixture([Atom(xy1, EqualZero), Atom(square, NotZero)]),
    ),
  )
  assert_false(
    conjunct_conflict(
      conjunction_fixture([Atom(xy0, EqualZero), Atom(x, NotZero)]),
    ),
  )
  assert_false(
    conjunct_conflict(
      conjunction_fixture([
        Atom(difference, EqualZero),
        Atom(same_coordinate, NotZero),
      ]),
    ),
  )
  assert_eq(
    @poly.evaluate(
      xy0,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
    ),
    Some(@oracle.rational(0, 1)),
  )
  assert_eq(
    @poly.evaluate(
      x,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
    ),
    Some(@oracle.rational(1, 1)),
  )
  assert_eq(
    @poly.evaluate(
      difference,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(-1, 1)]),
    ),
    Some(@oracle.rational(0, 1)),
  )
  assert_eq(
    @poly.evaluate(
      same_coordinate,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(-1, 1)]),
    ),
    Some(@oracle.rational(2, 1)),
  )
  // Three-term substitutions can expand monomials and remain outside this path.
  let wide = test_polynomial(3, [
    (1, [1, 0, 0]),
    (1, [0, 1, 0]),
    (-1, [0, 0, 0]),
  ])
  let target = test_polynomial(3, [
    (1, [1, 0, 1]),
    (1, [0, 1, 1]),
    (-1, [0, 0, 1]),
    (-1, [0, 0, 0]),
  ])
  assert_false(
    conjunct_conflict(
      conjunction_fixture([Atom(wide, EqualZero), Atom(target, EqualZero)]),
    ),
  )
  // Lexicographic rewriting can raise degree even with only two terms.
  // Keep that case on the original CAD path instead of growing unary powers.
  let raising = test_polynomial(2, [(1, [1, 0]), (-1, [0, 2])])
  let consequence = test_polynomial(2, [(1, [2, 0]), (-1, [0, 4])])
  assert_false(
    conjunct_conflict(
      conjunction_fixture([Atom(raising, EqualZero), Atom(consequence, NotZero)]),
    ),
  )
}

///|
test "self-excluded residues find incompatible binomials and keep coordinate precedence" {
  let a = test_polynomial(2, [(1, [2, 0]), (-2, [0, 0])])
  let b = test_polynomial(2, [(1, [2, 0]), (-3, [0, 0])])
  assert_true(
    conjunct_conflict(
      conjunction_fixture([Atom(a, EqualZero), Atom(b, EqualZero)]),
    ),
  )
  assert_true(
    conjunct_conflict(
      conjunction_fixture([Atom(b, EqualZero), Atom(a, EqualZero)]),
    ),
  )
  let same = @poly.multiply(
    a,
    @poly.constant(@oracle.nat(2), @oracle.rational(-3, 7)),
  ).unwrap()
  assert_false(
    conjunct_conflict(
      conjunction_fixture([Atom(a, EqualZero), Atom(same, EqualZero)]),
    ),
  )
  let x1 = test_polynomial(3, [(1, [1, 0, 0]), (-1, [0, 0, 0])])
  let xy2 = test_polynomial(3, [(1, [1, 0, 0]), (-1, [0, 2, 0])])
  let x2z = test_polynomial(3, [(1, [2, 0, 0]), (-1, [0, 0, 1])])
  let x2 = test_polynomial(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])])
  let atoms : Array[@qf.Formula] = [
    Atom(x1, EqualZero),
    Atom(xy2, EqualZero),
    Atom(x2z, EqualZero),
    Atom(x2, EqualZero),
  ]
  for order in [[0, 1, 2, 3], [2, 1, 0, 3], [3, 2, 1, 0]] {
    assert_true(
      conjunct_conflict(conjunction_fixture(order.map(i => atoms[i]))),
    )
  }
}
