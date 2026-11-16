///|
fn test_budget() -> Budget {
  {
    primes: @oracle.chain(
      [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31].map(@oracle.binary),
    ),
    lifting: @oracle.nat(40),
    subsets: @oracle.nat(1024),
    verification: @oracle.nat(4096),
  }
}

///|
fn p(terms : Array[(Int32, Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      terms.map(fn(term) {
        let (coefficient, x, y) = term
        @poly.Term::{
          coefficient: @oracle.rational(coefficient, 1),
          exponents: @oracle.chain([@oracle.nat(x), @oracle.nat(y)]),
        }
      }),
    ),
  ).unwrap()
}

///|
fn solved(formula : @base.Formula) -> Decomposition {
  let problem = prepare(formula).unwrap()
  match run(start(problem, test_budget()), @oracle.nat(8192)).unwrap() {
    Complete(value) => value
    _ => abort("CAD2 fixture budget exhausted")
  }
}

///|
fn fibre_root_counts(value : Decomposition) -> Array[Int32] {
  @oracle.array(stacks(value)).map(fn(stack) {
    @oracle.int_of_nat(@core.length(stack.fibre.isolation.roots))
  })
}

///|
test "circle at irrational critical points and all four quantifiers" {
  let circle = p([(1, 2, 0), (1, 0, 2), (-2, 0, 0)])
  let value = solved(@base.Atom(circle, EqualZero))
  assert_eq(@oracle.array(eliminate_y(value, Exists)), [
    false, true, true, true, false,
  ])
  assert_eq(fibre_root_counts(value), [0, 1, 2, 1, 0])
  assert_true(sentence(value, Exists, Exists))
  assert_false(sentence(value, Forall, Exists))
  assert_false(sentence(value, Exists, Forall))
  assert_false(sentence(value, Forall, Forall))
  assert_true(
    check(problem_of(value), certificate(value), @oracle.nat(4096)) is Some(_),
  )
  let outside = solved(@base.Atom(circle, GreaterZero))
  assert_true(sentence(outside, Forall, Exists))
  assert_true(sentence(outside, Exists, Forall))
  assert_false(sentence(outside, Forall, Forall))
}

///|
test "quantifier alternation is per fibre and a diagonal is not a plane" {
  let diagonal = p([(-1, 1, 0), (1, 0, 1)])
  let value = solved(@base.Atom(diagonal, EqualZero))
  assert_true(sentence(value, Forall, Exists))
  assert_false(sentence(value, Exists, Forall))
  assert_false(sentence(value, Forall, Forall))
  assert_true(sentence(value, Exists, Exists))
  assert_true(@core.all(eliminate_y(value, Exists), fn(x) { x }))
  assert_true(@core.all(eliminate_y(value, Forall), fn(x) { !x }))
}

///|
test "nullified atom leaves a whole positive fibre at x zero" {
  let xy = p([(1, 1, 1)])
  let y = p([(1, 0, 1)])
  let formula = @base.Conjunction(
    @base.Atom(xy, EqualZero),
    @base.Atom(y, GreaterZero),
  )
  let value = solved(formula)
  assert_eq(@oracle.array(eliminate_y(value, Exists)), [false, true, false])
  assert_eq(fibre_root_counts(value), [1, 1, 1])
  assert_true(sentence(value, Exists, Exists))
  assert_false(sentence(value, Forall, Exists))
}

///|
test "degree drop and strict discriminant endpoint" {
  let quadratic = p([(1, 1, 2), (1, 0, 1), (1, 0, 0)])
  let equality = solved(@base.Atom(quadratic, EqualZero))
  assert_eq(@oracle.array(eliminate_y(equality, Exists)), [
    true, true, true, true, false,
  ])
  assert_eq(fibre_root_counts(equality), [2, 1, 2, 1, 0])
  let negative = solved(@base.Atom(quadratic, LessZero))
  assert_eq(@oracle.array(eliminate_y(negative, Exists)), [
    true, true, true, false, false,
  ])
}

///|
test "shared repeated factors remain valid at their collision" {
  let square = p([(1, 0, 2), (-2, 1, 1), (1, 2, 0)])
  let pair = p([(1, 0, 2), (1, 0, 1), (-1, 1, 1), (-1, 1, 0)])
  let value = solved(
    @base.Conjunction(
      @base.Atom(square, EqualZero),
      @base.Atom(pair, EqualZero),
    ),
  )
  assert_true(sentence(value, Forall, Exists))
  assert_false(sentence(value, Exists, Forall))
  assert_true(
    check(problem_of(value), certificate(value), @oracle.nat(4096)) is Some(_),
  )
}

///|
test "fuel zero reconfiguration constants and invalid unreachable input" {
  let empty = prepare(@base.Truth(true)).unwrap()
  assert_true(
    run(start(empty, test_budget()), @core.Zero).unwrap() is Paused(_),
  )
  assert_true(sentence(solved(@base.Truth(true)), Forall, Forall))
  assert_false(sentence(solved(@base.Truth(false)), Exists, Exists))
  let circle = p([(1, 2, 0), (1, 0, 2), (-2, 0, 0)])
  let problem = prepare(@base.Atom(circle, EqualZero)).unwrap()
  let limited : Budget = { ..test_budget(), primes: @core.Nil, }
  match run(start(problem, limited), @oracle.nat(8192)).unwrap() {
    NeedsBudget(state, _) =>
      match run(rebudget(state, test_budget()), @oracle.nat(8192)).unwrap() {
        Complete(value) => assert_true(sentence(value, Exists, Exists))
        _ => abort("increased factorization budget did not finish")
      }
    _ => abort("empty prime list should not certify quadratic irreducibility")
  }
  let invalid = @poly.zero(@oracle.nat(3))
  assert_true(
    prepare(
      @base.Conjunction(@base.Truth(false), @base.Atom(invalid, EqualZero)),
    )
    is Err(NotBivariate),
  )
}

///|
test "source projection base field root and fibre payload substitutions fail" {
  let circle = p([(1, 2, 0), (1, 0, 2), (-2, 0, 0)])
  let problem = prepare(@base.Atom(circle, EqualZero)).unwrap()
  let proof = certificate(solved(@base.Atom(circle, EqualZero)))
  assert_true(
    check(problem, { ..proof, formula: @base.Truth(true), }, @oracle.nat(4096))
    is None,
  )
  assert_true(
    check(problem, { ..proof, stacks: @core.Nil, }, @oracle.nat(4096)) is None,
  )
  assert_true(
    check(
      problem,
      { ..proof, projection: { ..proof.projection, principal: @core.Nil, }, },
      @oracle.nat(4096),
    )
    is None,
  )
  let all = @oracle.array(proof.stacks)
  let reversed = @core.reverse(proof.stacks)
  assert_true(
    check(problem, { ..proof, stacks: reversed, }, @oracle.nat(4096)) is None,
  )
  let missing : StackCertificate = {
    ..all[2],
    fibre: { ..all[2].fibre, cells: @core.Nil, },
  }
  let changed = @oracle.chain([all[0], all[1], missing, all[3], all[4]])
  assert_true(
    check(problem, { ..proof, stacks: changed, }, @oracle.nat(4096)) is None,
  )
  let wrong_field : StackCertificate = { ..all[1], minimal: all[3].minimal, }
  assert_true(
    check(
      problem,
      {
        ..proof,
        stacks: @oracle.chain([all[0], wrong_field, all[2], all[3], all[4]]),
      },
      @oracle.nat(4096),
    )
    is None,
  )
}
