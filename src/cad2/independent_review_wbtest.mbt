///|
fn review_plane_polynomial(
  terms : Array[(Int32, Int32, Int32, Int32)],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      terms.map(fn(term) {
        @poly.Term::{
          coefficient: @oracle.rational(term.0, term.1),
          exponents: @oracle.chain([@oracle.nat(term.2), @oracle.nat(term.3)]),
        }
      }),
    ),
  ).unwrap()
}

///|
fn review_cad_budget() -> Budget {
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
fn review_plane_solved(problem : Problem) -> Decomposition {
  let paused = match run(start(problem, review_cad_budget()), Zero).unwrap() {
    Paused(state) => state
    _ => abort("zero CAD2 review fuel must pause")
  }
  match run(paused, @oracle.nat(8192)).unwrap() {
    Complete(value) => value
    _ => abort("frozen finite CAD2 family did not complete")
  }
}

///|
fn review_plane_fixture(
  atoms : Array[Array[(Int32, Int32, Int32, Int32)]],
  build : (Array[@poly.Polynomial]) -> @base.Formula,
  expected : Array[Bool],
) -> Unit raise {
  let source = build(atoms.map(review_plane_polynomial))
  let problem = prepare(source).unwrap()
  let value = review_plane_solved(problem)
  let proof = certificate(value)
  assert_true(check(problem, proof, @oracle.nat(4096)) is Some(_))
  assert_eq(proof.formula, source)
  assert_eq(proof.projection.mode, @projection.CollinsProjection)
  assert_eq(@core.length(proof.stacks), @core.length(proof.base.cells))
  assert_true(
    @core.all(proof.stacks, fn(stack) { !stack.fibre.cells.equal(Nil) }),
  )
  assert_eq(sentence(value, Exists, Exists), expected[0])
  assert_eq(sentence(value, Exists, Forall), expected[1])
  assert_eq(sentence(value, Forall, Exists), expected[2])
  assert_eq(sentence(value, Forall, Forall), expected[3])
}

///|
test "independent CAD2 coverage source projection and field substitutions are rejected" {
  let circle = review_plane_polynomial([
    (1, 1, 2, 0),
    (1, 1, 0, 2),
    (-2, 1, 0, 0),
  ])
  let problem = prepare(@base.Atom(circle, EqualZero)).unwrap()
  let proof = certificate(review_plane_solved(problem))
  let all = @oracle.array(proof.stacks)
  assert_eq(all.length(), 5)
  assert_true(
    check(problem, { ..proof, stacks: Nil, }, @oracle.nat(4096)) is None,
  )
  assert_true(
    check(
      problem,
      { ..proof, stacks: @core.reverse(proof.stacks), },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      { ..proof, stacks: @core.drop(Succ(Zero), proof.stacks), },
      @oracle.nat(4096),
    )
    is None,
  )
  let both_missing = Certificate::{
    ..proof,
    base: { ..proof.base, cells: @core.drop(Succ(Zero), proof.base.cells), },
    stacks: @core.drop(Succ(Zero), proof.stacks),
  }
  assert_true(check(problem, both_missing, @oracle.nat(4096)) is None)
  assert_true(
    check(
      problem,
      { ..proof, base: { ..proof.base, roots: Nil, }, },
      @oracle.nat(4096),
    )
    is None,
  )
  let bad = all.copy()
  bad[1] = { ..all[1], fibre: all[3].fibre, }
  assert_true(
    check(problem, { ..proof, stacks: @oracle.chain(bad), }, @oracle.nat(4096))
    is None,
  )
  bad[1] = { ..all[1], minimal: all[3].minimal, }
  assert_true(
    check(problem, { ..proof, stacks: @oracle.chain(bad), }, @oracle.nat(4096))
    is None,
  )
  bad[1] = { ..all[1], sample: all[3].sample, }
  assert_true(
    check(problem, { ..proof, stacks: @oracle.chain(bad), }, @oracle.nat(4096))
    is None,
  )
  bad[1] = { ..all[1], fibre: { ..all[1].fibre, cells: Nil, }, }
  assert_true(
    check(problem, { ..proof, stacks: @oracle.chain(bad), }, @oracle.nat(4096))
    is None,
  )
  let wrong_formula = prepare(@base.Atom(circle, AtMostZero)).unwrap()
  assert_true(check(wrong_formula, proof, @oracle.nat(4096)) is None)
  assert_true(
    check(problem, { ..proof, formula: @base.Truth(true), }, @oracle.nat(4096))
    is None,
  )
  let weaker = @projection.product_projection(atoms(problem), Succ(Zero)).unwrap()
  assert_true(
    check(
      problem,
      { ..proof, projection: @projection.certificate(weaker), },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      { ..proof, projection: { ..proof.projection, principal: Nil, }, },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(check(problem, proof, Zero) is None)
}

///|
test "independent irrational nullification preserves both full vertical lines" {
  let p = review_plane_polynomial([(1, 1, 2, 1), (-2, 1, 0, 1)])
  let equation = review_plane_solved(prepare(@base.Atom(p, EqualZero)).unwrap())
  let all = @oracle.array(stacks(equation))
  assert_eq(all.length(), 5)
  assert_eq(
    all.map(fn(stack) {
      @oracle.int_of_nat(@core.length(stack.fibre.isolation.roots))
    }),
    [1, 0, 1, 0, 1],
  )
  assert_eq(
    all.map(fn(stack) { @oracle.int_of_nat(@core.length(stack.fibre.cells)) }),
    [3, 1, 3, 1, 3],
  )
  assert_eq(@oracle.array(eliminate_y(equation, Exists)), [
    true, true, true, true, true,
  ])
  assert_eq(@oracle.array(eliminate_y(equation, Forall)), [
    false, true, false, true, false,
  ])
  let strict = review_plane_solved(prepare(@base.Atom(p, GreaterZero)).unwrap())
  assert_eq(@oracle.array(eliminate_y(strict, Exists)), [
    true, false, true, false, true,
  ])
  assert_eq(@oracle.array(eliminate_y(strict, Forall)), [
    false, false, false, false, false,
  ])
  assert_true(sentence(equation, Exists, Forall))
  assert_false(sentence(strict, Forall, Exists))
}

///|
test "independent CAD2 factorization insufficiency pauses and reuses prior cells" {
  let p = review_plane_polynomial([(1, 1, 2, 1), (-2, 1, 0, 1)])
  let problem = prepare(@base.Atom(p, EqualZero)).unwrap()
  let limited = Budget::{ ..review_cad_budget(), primes: Nil, }
  match run(start(problem, limited), @oracle.nat(8192)).unwrap() {
    NeedsBudget(state, _) =>
      match
        run(rebudget(state, review_cad_budget()), @oracle.nat(8192)).unwrap() {
        Complete(value) => {
          assert_true(
            check(problem, certificate(value), @oracle.nat(4096)) is Some(_),
          )
          assert_true(sentence(value, Exists, Forall))
          assert_eq(
            certificate(value),
            certificate(review_plane_solved(problem)),
          )
        }
        _ => fail("rebudget did not resume finite review system")
      }
    _ => fail("missing prime budget accepted an irrational base field")
  }
}

///|
fn review_cad_scalar_field() -> @nf.Field {
  let m = @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain([
      @poly.Term::{
        coefficient: @oracle.rational(-2, 1),
        exponents: Cons(Zero, Nil),
      },
      @poly.Term::{
        coefficient: @oracle.rational(1, 1),
        exponents: Cons(@oracle.nat(2), Nil),
      },
    ]),
  ).unwrap()
  let alpha = @real.number({
    polynomial: m,
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }).unwrap()
  match
    @minimal.normalize(
      alpha,
      review_cad_budget().primes,
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("review scalar field")
  }
}

///|
test "independent specialization reduces null coefficients and every y coefficient" {
  let field = review_cad_scalar_field()
  let x = @nf.generator(field).unwrap()
  let p = review_plane_polynomial([
    (1, 1, 3, 0),
    (1, 1, 2, 1),
    (3, 1, 0, 1),
    (1, 1, 1, 2),
    (1, 1, 0, 2),
  ])
  let expected = @ordered.polynomial(
    field,
    @oracle.chain([
      @nf.add(x, x).unwrap(),
      @nf.rational(field, @oracle.rational(5, 1)),
      @nf.add(x, @nf.one(field)).unwrap(),
    ]),
  ).unwrap()
  assert_true(@ordered.equal(specialize(field, p).unwrap(), expected))
  let drop = review_plane_polynomial([
    (1, 1, 2, 2),
    (-2, 1, 0, 2),
    (1, 1, 0, 1),
    (-1, 1, 0, 0),
  ])
  let linear = @ordered.polynomial(
    field,
    @oracle.chain([@nf.rational(field, @oracle.rational(-1, 1)), @nf.one(field)]),
  ).unwrap()
  assert_true(@ordered.equal(specialize(field, drop).unwrap(), linear))
  let nullified = review_plane_polynomial([
    (1, 1, 2, 1),
    (-2, 1, 0, 1),
    (1, 1, 2, 0),
    (-2, 1, 0, 0),
  ])
  assert_true(@ordered.is_zero(specialize(field, nullified).unwrap()))
  assert_true(
    specialize(field, @poly.zero(@oracle.nat(1))) is Err(NotBivariate),
  )
}

///|
test "independent shared factor needs a higher PSC when all reducta resultants vanish" {
  // f-g=(x+2)y, and every nonzero reductum of f,g shares y.
  // All cross-resultants vanish identically, while PSC_1 detects x=-2.
  let f = review_plane_polynomial([(1, 1, 0, 2), (-1, 1, 1, 1), (-1, 1, 0, 1)])
  let g = review_plane_polynomial([(1, 1, 0, 2), (-2, 1, 1, 1), (-3, 1, 0, 1)])
  let h = review_plane_polynomial([(1, 1, 0, 1)])
  let problem = prepare(
    @base.Conjunction(
      @base.Atom(f, EqualZero),
      @base.Conjunction(@base.Atom(g, EqualZero), @base.Atom(h, NotZero)),
    ),
  ).unwrap()
  let value = review_plane_solved(problem)
  assert_true(sentence(value, Exists, Exists))
  assert_false(sentence(value, Exists, Forall))
  assert_false(sentence(value, Forall, Exists))
  assert_false(sentence(value, Forall, Forall))
  let truth = @oracle.array(eliminate_y(value, Exists))
  let all = @oracle.array(stacks(value))
  let target = @real.definition(
    @real.rational(@oracle.rational(-2, 1)).unwrap(),
  )
  let mut selected = 0
  for i in 0..<truth.length() {
    if truth[i] {
      selected += 1
      assert_eq(all[i].minimal.result.polynomial, target)
      assert_true(all[i].sample is @base.AlgebraicPoint(_))
    }
  }
  assert_eq(selected, 1)
}
