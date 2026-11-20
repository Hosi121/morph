///|
fn conjunction_fixture(values : Array[@qf.Formula]) -> @qf.Formula {
  values.fold(init=@qf.Truth(true), fn(a, b) { @qf.Conjunction(a, b) })
}

///|
test "affine conjunct conflicts agree with an independent integer grid and input orders" {
  for a in -1..<=1 {
    for b in -1..<=1 {
      for c in -1..<=1 {
        let x = test_polynomial(3, [(1, [1, 0, 0]), (-a, [0, 0, 0])])
        let y = test_polynomial(3, [(1, [0, 1, 0]), (-b, [0, 0, 0])])
        let p = test_polynomial(3, [
          (1, [1, 0, 2]),
          (-a, [0, 0, 2]),
          (1, [0, 1, 1]),
          (-b, [0, 0, 1]),
          (c, [0, 0, 0]),
        ])
        let atoms : Array[@qf.Formula] = [
          Atom(x, EqualZero),
          Atom(y, EqualZero),
          Atom(p, EqualZero),
        ]
        for order in [[0, 1, 2], [2, 0, 1], [1, 2, 0]] {
          let source = conjunction_fixture(order.map(i => atoms[i]))
          assert_eq(conjunct_conflict(source), c != 0)
          let plan = test_plan(3, source, [[], [], [], []])
          assert_eq(
            evaluate(plan, @oracle.nat(0), Nil),
            Ok(if c == 0 { Undetermined } else { Known(false) }),
          )
          for u in -2..<=2 {
            for v in -2..<=2 {
              for w in -2..<=2 {
                let expected = u == a &&
                  v == b &&
                  (u - a) * w * w + (v - b) * w + c == 0
                if c != 0 {
                  assert_false(expected)
                }
              }
            }
          }
          if c == 0 {
            let witness = @oracle.chain([
              @oracle.rational(a, 1),
              @oracle.rational(b, 1),
              @oracle.rational(0, 1),
            ])
            assert_eq(@poly.evaluate(p, witness), Some(@oracle.rational(0, 1)))
          }
        }
      }
    }
  }
}

///|
test "conditional equalities and nonzero relations are not unconditional assumptions" {
  let x = test_polynomial(3, [(1, [1, 0, 0])])
  let y = test_polynomial(3, [(1, [0, 1, 0]), (-1, [0, 0, 0])])
  let p = test_polynomial(3, [
    (1, [1, 0, 2]),
    (1, [0, 1, 1]),
    (-1, [0, 0, 1]),
    (-1, [0, 0, 0]),
  ])
  let bad = conjunction_fixture([
    Atom(x, EqualZero),
    Atom(y, EqualZero),
    Atom(p, EqualZero),
  ])
  assert_true(conjunct_conflict(bad))
  let incompatible = test_polynomial(3, [(1, [1, 0, 0]), (1, [0, 1, 0])])
  assert_true(
    conjunct_conflict(
      conjunction_fixture([
        Atom(x, EqualZero),
        Atom(y, EqualZero),
        Atom(incompatible, EqualZero),
      ]),
    ),
  )
  for
    source in [
      @qf.Disjunction(bad, Truth(true)),
      @qf.Negation(bad),
      conjunction_fixture([
        Atom(x, NotZero),
        Atom(y, EqualZero),
        Atom(p, EqualZero),
      ]),
      conjunction_fixture([
        Atom(x, EqualZero),
        @qf.Disjunction(Atom(y, EqualZero), Atom(p, EqualZero)),
      ]),
    ] {
    assert_false(conjunct_conflict(source))
    assert_true(
      evaluate(test_plan(3, source, [[], [], [], []]), @oracle.nat(0), Nil) !=
      Ok(Known(false)),
    )
  }
  // Two-term aliases do not expand monomials and now derive the contradiction.
  let coupled = test_polynomial(3, [(1, [1, 0, 0]), (1, [0, 1, 0])])
  let coupled_target = test_polynomial(3, [
    (1, [1, 0, 1]),
    (1, [0, 1, 1]),
    (-1, [0, 0, 0]),
  ])
  assert_true(
    conjunct_conflict(
      conjunction_fixture([
        Atom(coupled, EqualZero),
        Atom(coupled_target, EqualZero),
      ]),
    ),
  )
  // A nonlinear assumption alone need not decide an unrelated target.
  let nonlinear = test_polynomial(3, [(1, [2, 0, 0])])
  assert_false(
    conjunct_conflict(
      conjunction_fixture([Atom(nonlinear, EqualZero), Atom(p, EqualZero)]),
    ),
  )
  assert_true(
    conjunct_conflict(
      conjunction_fixture([Atom(@poly.zero(@oracle.nat(3)), EqualZero), bad]),
    ),
  )
}

///|
test "rational rescaling retains conflict and observation and source validation" {
  let x = test_polynomial(3, [(1, [1, 0, 0])])
  let y = test_polynomial(3, [(1, [0, 1, 0]), (-1, [0, 0, 0])])
  let p = test_polynomial(3, [
    (1, [1, 0, 2]),
    (1, [0, 1, 1]),
    (-1, [0, 0, 1]),
    (-1, [0, 0, 0]),
  ])
  let source = conjunction_fixture([
    Atom(
      @poly.multiply(x, @poly.constant(@oracle.nat(3), @oracle.rational(-2, 3))).unwrap(),
      EqualZero,
    ),
    Atom(
      @poly.multiply(y, @poly.constant(@oracle.nat(3), @oracle.rational(5, 7))).unwrap(),
      EqualZero,
    ),
    Atom(
      @poly.multiply(
        p,
        @poly.constant(@oracle.nat(3), @oracle.rational(-11, 13)),
      ).unwrap(),
      EqualZero,
    ),
  ])
  let plan = test_plan(3, source, [[], [], [], []])
  assert_eq(evaluate(plan, @oracle.nat(0), Nil), Ok(Known(false)))
  assert_eq(
    evaluate(plan, @oracle.nat(0), Cons(Equal, Nil)),
    Err(InvalidObservation),
  )
  assert_true(
    check_plan(
      @oracle.nat(3),
      source,
      @oracle.chain([@core.Nil, Nil, Nil, Nil]),
      plan,
    ),
  )
  let forged : Plan = {
    stages: @core.map(plan.stages, fn(stage) {
      { ..stage, conditional: Constant(true), }
    }),
  }
  assert_false(
    check_plan(
      @oracle.nat(3),
      source,
      @oracle.chain([@core.Nil, Nil, Nil, Nil]),
      forged,
    ),
  )
  assert_eq(
    prepare(
      @oracle.nat(3),
      source,
      @oracle.chain([@oracle.chain([x]), Nil, Nil, Nil]),
    ),
    Err(DimensionMismatch),
  )
}
