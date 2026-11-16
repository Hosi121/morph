///|
fn test_polynomial(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  let source = terms.map(fn(term) {
    let (coefficient, exponents) = term
    @poly.Term::{
      coefficient: @oracle.rational(coefficient, 1),
      exponents: @oracle.chain(exponents.map(@oracle.nat)),
    }
  })
  match @poly.polynomial(@oracle.nat(variables), @oracle.chain(source)) {
    Ok(polynomial) => polynomial
    Err(error) => abort(error.to_repr().to_string())
  }
}

///|
fn test_plan(
  arity : Int32,
  formula : @qf.Formula,
  families : Array[Array[@poly.Polynomial]],
) -> Plan {
  match
    prepare(
      @oracle.nat(arity),
      formula,
      @oracle.chain(families.map(@oracle.chain)),
    ) {
    Ok(plan) => plan
    Err(error) => abort(error.to_repr().to_string())
  }
}

///|
fn numeric_sign(value : Int32) -> @core.Ordering {
  if value < 0 {
    Less
  } else if value > 0 {
    Greater
  } else {
    Equal
  }
}

///|
fn numeric_relation(index : Int32, value : Int32) -> Bool {
  match index {
    0 => value < 0
    1 => value <= 0
    2 => value == 0
    3 => value != 0
    4 => value >= 0
    _ => value > 0
  }
}

///|
fn test_relations() -> Array[@qf.Relation] {
  [LessZero, AtMostZero, EqualZero, NotZero, AtLeastZero, GreaterZero]
}

///|
test "nullification proves xy-1 false for every y when x vanishes" {
  let x = test_polynomial(1, [(1, [1])])
  let p = test_polynomial(2, [(1, [1, 1]), (-1, [0, 0])])
  let plan = test_plan(2, Atom(p, EqualZero), [[], [x], [p]])
  assert_eq(evaluate(plan, @oracle.nat(1), Cons(Equal, Nil)), Ok(Known(false)))
  assert_eq(
    evaluate(plan, @oracle.nat(1), Cons(Greater, Nil)),
    Ok(Undetermined),
  )
  assert_eq(evaluate(plan, @oracle.nat(1), Cons(Less, Nil)), Ok(Undetermined))
  // At (1,0) the sample is false, while the same prefix has the root y=1.
  assert_true(
    @poly.evaluate(
      p,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
    )
    is Some(q) &&
    q.equal(@oracle.rational(-1, 1)),
  )
  assert_true(
    @poly.evaluate(
      p,
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
    )
    is Some(q) &&
    q.equal(@oracle.rational(0, 1)),
  )
  for y in -4..<=4 {
    assert_true(
      @poly.evaluate(
        p,
        @oracle.chain([@oracle.rational(0, 1), @oracle.rational(y, 1)]),
      )
      is Some(q) &&
      q.equal(@oracle.rational(-1, 1)),
    )
  }
}

///|
test "missing exact coefficient binding stays unknown even when a sample vanishes" {
  let two_x = test_polynomial(1, [(2, [1])])
  let p = test_polynomial(2, [(1, [1, 1]), (-1, [0, 0])])
  let absent = test_plan(2, Atom(p, EqualZero), [[], [], [p]])
  let scaled = test_plan(2, Atom(p, EqualZero), [[], [two_x], [p]])
  assert_eq(evaluate(absent, @oracle.nat(1), Nil), Ok(Undetermined))
  assert_eq(
    evaluate(scaled, @oracle.nat(1), Cons(Equal, Nil)),
    Ok(Undetermined),
  )
  assert_eq(evaluate(absent, @oracle.nat(2), Cons(Equal, Nil)), Ok(Known(true)))
  // Positive quadratic tails also remain conservative: no positivity oracle.
  let positive = test_polynomial(2, [(1, [0, 2]), (1, [0, 0])])
  let plan = test_plan(2, Atom(positive, GreaterZero), [[], [], [positive]])
  assert_eq(evaluate(plan, @oracle.nat(1), Nil), Ok(Undetermined))
}

///|
test "81 independently evaluated quadratic families agree at prefixes and full points for all six relations" {
  let relations = test_relations()
  let mut comparisons = 0
  let mut uniformly_known = 0
  for a in -1..<=1 {
    for b in -1..<=1 {
      for c in -1..<=1 {
        for d in -1..<=1 {
          // (a*x+b)*y^2 + (c*x+d)*y + x-1.
          let leading = test_polynomial(1, [(a, [1]), (b, [0])])
          let middle = test_polynomial(1, [(c, [1]), (d, [0])])
          let constant = test_polynomial(1, [(1, [1]), (-1, [0])])
          let p = test_polynomial(2, [
            (a, [1, 2]),
            (b, [0, 2]),
            (c, [1, 1]),
            (d, [0, 1]),
            (1, [1, 0]),
            (-1, [0, 0]),
          ])
          for r in 0..<relations.length() {
            let plan = test_plan(2, Atom(p, relations[r]), [
              [],
              [leading, middle, constant],
              [p],
            ])
            assert_eq(evaluate(plan, @oracle.nat(0), Nil), Ok(Undetermined))
            for x in -1..<=1 {
              let signs = @oracle.chain([
                numeric_sign(a * x + b),
                numeric_sign(c * x + d),
                numeric_sign(x - 1),
              ])
              let observed = evaluate(plan, @oracle.nat(1), signs)
              if a * x + b == 0 && c * x + d == 0 {
                assert_eq(observed, Ok(Known(numeric_relation(r, x - 1))))
                uniformly_known += 1
              } else {
                assert_eq(observed, Ok(Undetermined))
              }
              for y in -2..<=2 {
                let value = (a * x + b) * y * y + (c * x + d) * y + x - 1
                let expected = numeric_relation(r, value)
                let exact_point = @oracle.chain([
                  @oracle.rational(x, 1),
                  @oracle.rational(y, 1),
                ])
                assert_true(
                  @poly.evaluate(p, exact_point) is Some(q) &&
                  q.equal(@oracle.rational(value, 1)),
                )
                assert_eq(
                  evaluate(plan, @oracle.nat(2), Cons(numeric_sign(value), Nil)),
                  Ok(Known(expected)),
                )
                if observed is Ok(Known(holds)) {
                  assert_eq(holds, expected)
                }
                comparisons += 1
              }
            }
          }
        }
      }
    }
  }
  assert_eq(comparisons, 7290)
  assert_eq(uniformly_known, 162)
}

///|
test "three dimensions group future monomials and prefix coefficients independently" {
  // p=(x^2-1)*y*z+(x-1)*z+x+1.
  let p = test_polynomial(3, [
    (1, [2, 1, 1]),
    (-1, [0, 1, 1]),
    (1, [1, 0, 1]),
    (-1, [0, 0, 1]),
    (1, [1, 0, 0]),
    (1, [0, 0, 0]),
  ])
  let square_minus_one = test_polynomial(1, [(1, [2]), (-1, [0])])
  let minus_one = test_polynomial(1, [(1, [1]), (-1, [0])])
  let plus_one = test_polynomial(1, [(1, [1]), (1, [0])])
  let z_coefficient = test_polynomial(2, [
    (1, [2, 1]),
    (-1, [0, 1]),
    (1, [1, 0]),
    (-1, [0, 0]),
  ])
  let constant = test_polynomial(2, [(1, [1, 0]), (1, [0, 0])])
  let families = [
    [],
    [square_minus_one, minus_one, plus_one],
    [z_coefficient, constant],
    [p],
  ]
  for r in 0..<6 {
    let plan = test_plan(3, Atom(p, test_relations()[r]), families)
    for x in -1..<=1 {
      let prefix_signs = @oracle.chain([
        numeric_sign(x * x - 1),
        numeric_sign(x - 1),
        numeric_sign(x + 1),
      ])
      let at_x = evaluate(plan, @oracle.nat(1), prefix_signs)
      if x == 1 {
        assert_eq(at_x, Ok(Known(numeric_relation(r, 2))))
      } else {
        assert_eq(at_x, Ok(Undetermined))
      }
      for y in -2..<=2 {
        let coefficient = (x * x - 1) * y + x - 1
        let at_xy = evaluate(
          plan,
          @oracle.nat(2),
          @oracle.chain([numeric_sign(coefficient), numeric_sign(x + 1)]),
        )
        if coefficient == 0 {
          assert_eq(at_xy, Ok(Known(numeric_relation(r, x + 1))))
        } else {
          assert_eq(at_xy, Ok(Undetermined))
        }
        for z in -2..<=2 {
          let value = (x * x - 1) * y * z + (x - 1) * z + x + 1
          let coordinates = @oracle.chain([
            @oracle.rational(x, 1),
            @oracle.rational(y, 1),
            @oracle.rational(z, 1),
          ])
          assert_true(
            @poly.evaluate(p, coordinates) is Some(q) &&
            q.equal(@oracle.rational(value, 1)),
          )
          if at_x is Ok(Known(holds)) {
            assert_eq(holds, numeric_relation(r, value))
          }
          if at_xy is Ok(Known(holds)) {
            assert_eq(holds, numeric_relation(r, value))
          }
          assert_eq(
            evaluate(plan, @oracle.nat(3), Cons(numeric_sign(value), Nil)),
            Ok(Known(numeric_relation(r, value))),
          )
        }
      }
    }
  }
}

///|
test "rational coefficients nullify exactly at a nonintegral prefix" {
  let source : @core.Chain[@poly.Term] = @oracle.chain([
    {
      coefficient: @oracle.rational(1, 2),
      exponents: @oracle.chain([@oracle.nat(1), @oracle.nat(1)]),
    },
    {
      coefficient: @oracle.rational(-1, 3),
      exponents: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
    },
    {
      coefficient: @oracle.rational(2, 7),
      exponents: @oracle.chain([@oracle.nat(0), @oracle.nat(0)]),
    },
  ])
  let p = match @poly.polynomial(@oracle.nat(2), source) {
    Ok(p) => p
    Err(_) => abort("source")
  }
  let coefficient = match
    @poly.polynomial(
      @oracle.nat(1),
      @oracle.chain([
        @poly.Term::{
          coefficient: @oracle.rational(1, 2),
          exponents: Cons(@oracle.nat(1), Nil),
        },
        @poly.Term::{
          coefficient: @oracle.rational(-1, 3),
          exponents: Cons(@oracle.nat(0), Nil),
        },
      ]),
    ) {
    Ok(p) => p
    Err(_) => abort("coefficient")
  }
  let plan = test_plan(2, Atom(p, GreaterZero), [[], [coefficient], [p]])
  assert_eq(evaluate(plan, @oracle.nat(1), Cons(Equal, Nil)), Ok(Known(true)))
  assert_eq(evaluate(plan, @oracle.nat(1), Cons(Less, Nil)), Ok(Undetermined))
  assert_true(
    @poly.evaluate(coefficient, Cons(@oracle.rational(2, 3), Nil)) is Some(q) &&
    q.equal(@oracle.rational(0, 1)),
  )
  for y in -3..<=3 {
    assert_true(
      @poly.evaluate(
        p,
        @oracle.chain([@oracle.rational(2, 3), @oracle.rational(y, 2)]),
      )
      is Some(q) &&
      q.equal(@oracle.rational(2, 7)),
    )
  }
}

///|
test "strong Kleene Boolean combinations agree with every completion of an unavailable atom" {
  let unknown_poly = test_polynomial(2, [(1, [1, 1])])
  let unknown : @qf.Formula = Atom(unknown_poly, GreaterZero)
  let formulas : Array[@qf.Formula] = [Truth(false), Truth(true), unknown]
  let expected_and : Array[Array[Truth]] = [
    [Known(false), Known(false), Known(false)],
    [Known(false), Known(true), Undetermined],
    [Known(false), Undetermined, Undetermined],
  ]
  let expected_or : Array[Array[Truth]] = [
    [Known(false), Known(true), Undetermined],
    [Known(true), Known(true), Known(true)],
    [Undetermined, Known(true), Undetermined],
  ]
  for i in 0..<3 {
    for j in 0..<3 {
      let conjunction = test_plan(2, Conjunction(formulas[i], formulas[j]), [
        [],
        [],
        [unknown_poly],
      ])
      let disjunction = test_plan(2, Disjunction(formulas[i], formulas[j]), [
        [],
        [],
        [unknown_poly],
      ])
      assert_eq(
        evaluate(conjunction, @oracle.nat(1), Nil),
        Ok(expected_and[i][j]),
      )
      assert_eq(
        evaluate(disjunction, @oracle.nat(1), Nil),
        Ok(expected_or[i][j]),
      )
      for x in [-1, 1] {
        for y in [-1, 1] {
          let completion = [false, true, x * y > 0]
          if expected_and[i][j] is Known(holds) {
            assert_eq(holds, completion[i] && completion[j])
          }
          if expected_or[i][j] is Known(holds) {
            assert_eq(holds, completion[i] || completion[j])
          }
        }
      }
    }
    let negation = test_plan(2, Negation(formulas[i]), [[], [], [unknown_poly]])
    let expected : Truth = match i {
      0 => Known(true)
      1 => Known(false)
      _ => Undetermined
    }
    assert_eq(evaluate(negation, @oracle.nat(1), Nil), Ok(expected))
  }
}

///|
test "constant and zero polynomials are resolved before any lifting" {
  for arity in 0..<=3 {
    for value in -1..<=1 {
      let p = @poly.constant(@oracle.nat(arity), @oracle.rational(value, 2))
      let families = @core.replicate(@oracle.nat(arity + 1), @core.Nil)
      for r in 0..<6 {
        let plan = match
          prepare(@oracle.nat(arity), Atom(p, test_relations()[r]), families) {
          Ok(p) => p
          Err(_) => abort("constant")
        }
        for depth in 0..<=arity {
          assert_eq(
            evaluate(plan, @oracle.nat(depth), Nil),
            Ok(Known(numeric_relation(r, value))),
          )
        }
      }
    }
  }
}

///|
test "all source and family dimensions and every observation are checked" {
  let one = @oracle.nat(1)
  let x = test_polynomial(1, [(1, [1])])
  let xy = test_polynomial(2, [(1, [1, 1])])
  let correct : @core.Chain[@core.Chain[@poly.Polynomial]] = @oracle.chain([
    @core.Nil,
    Cons(x, Nil),
  ])
  assert_true(
    prepare(one, Atom(xy, EqualZero), correct) is Err(DimensionMismatch),
  )
  assert_true(
    prepare(one, Conjunction(Truth(false), Atom(xy, EqualZero)), correct)
    is Err(DimensionMismatch),
  )
  assert_true(prepare(one, Truth(true), Nil) is Err(DimensionMismatch))
  assert_true(
    prepare(one, Truth(true), Cons(Nil, Nil)) is Err(DimensionMismatch),
  )
  assert_true(
    prepare(one, Truth(true), @oracle.chain([Nil, Nil, Nil]))
    is Err(DimensionMismatch),
  )
  assert_true(
    prepare(one, Truth(true), @oracle.chain([Cons(x, Nil), Nil]))
    is Err(DimensionMismatch),
  )
  assert_true(
    prepare(one, Truth(true), @oracle.chain([Nil, Cons(xy, Nil)]))
    is Err(DimensionMismatch),
  )
  let plan = test_plan(1, Truth(true), [[], [x]])
  assert_eq(
    evaluate(plan, @oracle.nat(0), Cons(Equal, Nil)),
    Err(InvalidObservation),
  )
  assert_eq(evaluate(plan, @oracle.nat(1), Nil), Err(InvalidObservation))
  assert_eq(
    evaluate(plan, @oracle.nat(1), @oracle.chain([Equal, Less])),
    Err(InvalidObservation),
  )
  assert_eq(evaluate(plan, @oracle.nat(2), Nil), Err(InvalidObservation))
  assert_eq(evaluate(plan, @oracle.nat(1), Cons(Greater, Nil)), Ok(Known(true)))
}

///|
test "plan checking rejects coherent unrelated sources family order and forged coefficient bindings" {
  let x = test_polynomial(1, [(1, [1])])
  let x_plus_one = test_polynomial(1, [(1, [1]), (1, [0])])
  let p = test_polynomial(2, [(1, [1, 1]), (1, [1, 0]), (1, [0, 0])])
  let formula : @qf.Formula = Atom(p, EqualZero)
  let families : @core.Chain[@core.Chain[@poly.Polynomial]] = @oracle.chain([
    Nil,
    @oracle.chain([x, x_plus_one]),
    Cons(p, Nil),
  ])
  let plan = match prepare(@oracle.nat(2), formula, families) {
    Ok(plan) => plan
    Err(_) => abort("plan")
  }
  assert_true(check_plan(@oracle.nat(2), formula, families, plan))
  let unrelated = test_plan(2, Truth(false), [[], [x, x_plus_one], [p]])
  assert_false(check_plan(@oracle.nat(2), formula, families, unrelated))
  assert_false(check_plan(@oracle.nat(2), Negation(formula), families, plan))
  let reordered : @core.Chain[@core.Chain[@poly.Polynomial]] = @oracle.chain([
    Nil,
    @oracle.chain([x_plus_one, x]),
    Cons(p, Nil),
  ])
  assert_false(check_plan(@oracle.nat(2), formula, reordered, plan))
  let altered_family : @core.Chain[@core.Chain[@poly.Polynomial]] = @oracle.chain([
      Nil,
      Cons(x, Nil),
      Cons(p, Nil),
    ],
  )
  assert_false(check_plan(@oracle.nat(2), formula, altered_family, plan))
  let stages = @oracle.array(plan.stages)
  let original = stages[1]
  let forged_conditionals : Array[Conditional] = [
    Constant(true),
    Atom(Fixed(Equal), Cons(Fixed(Equal), Nil), EqualZero),
    Atom(
      Observed(@oracle.nat(0)),
      Cons(Observed(@oracle.nat(1)), Nil),
      EqualZero,
    ),
    Atom(Observed(@oracle.nat(2)), Nil, EqualZero),
    Atom(Observed(@oracle.nat(1)), Nil, EqualZero),
  ]
  for conditional in forged_conditionals {
    let forged : Plan = {
      stages: @oracle.chain([stages[0], { ..original, conditional, }, stages[2]]),
    }
    assert_false(check_plan(@oracle.nat(2), formula, families, forged))
  }
  let wrong_count : Plan = {
    stages: @oracle.chain([
      stages[0],
      { ..original, observation_count: @oracle.nat(0), },
      stages[2],
    ]),
  }
  assert_false(check_plan(@oracle.nat(2), formula, families, wrong_count))
  assert_false(
    check_plan(@oracle.nat(2), formula, families, {
      stages: @core.drop(@oracle.nat(1), plan.stages),
    }),
  )
}
