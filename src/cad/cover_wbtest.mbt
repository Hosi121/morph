///|
fn cover_checked_refutation(
  value : Decomposition,
  target : @qf.Formula,
) -> Decomposition raise {
  let result = match refute_on_cover(value, target) {
    Ok(Some(result)) => result
    Ok(None) => fail("cover did not certify the requested refutation")
    Err(error) => fail("cover refutation failed: \{error.to_repr()}")
  }
  let proof = certificate(result)
  assert_eq(proof.formula, target)
  assert_eq(proof.projection, projection(problem_of(value)))
  assert_true(check_cover(arity(problem_of(value)), target, proof) is Some(_))
  assert_true(check_result(problem_of(result), result, proof))
  assert_eq(
    sentence(
      result,
      @core.replicate_onto(
        arity(problem_of(result)),
        @logic.Quantifier::Exists,
        Nil,
      ),
    ),
    Ok(false),
  )
  result
}

///|
test "cover refutation rebinds constant subsets and keeps ordinary exact projection binding" {
  for variables in 0..<=3 {
    let one = @poly.constant(@oracle.nat(variables), @oracle.rational(1, 1))
    let two = @poly.constant(@oracle.nat(variables), @oracle.rational(2, 1))
    let target = @qf.Atom(one, @qf.LessZero)
    let source = @qf.Conjunction(target, @qf.Atom(two, @qf.GreaterZero))
    let problem = make_problem(variables, source)
    let original = match finish_search(problem, 200) {
      Unsatisfiable(value) => value
      _ => fail("positive constant is never negative")
    }
    let reduced = cover_checked_refutation(original, target)
    let proof = certificate(reduced)
    assert_eq(proof.tree, Leaf(false))
    let canonical_target = make_problem(variables, target)
    assert_false(projection(canonical_target).equal(proof.projection))
    assert_true(check(canonical_target, proof) is None)
    assert_true(check_cover(@oracle.nat(variables), source, proof) is None)
    assert_true(refute_on_cover(original, @qf.Truth(true)) is Ok(None))
    ignore(cover_checked_refutation(original, @qf.Truth(false)))
  }
}

///|
test "cover refutation agrees with the independent range of all shifted squares and six relations" {
  let relations : Array[@qf.Relation] = [
    @qf.LessZero,
    @qf.AtMostZero,
    @qf.EqualZero,
    @qf.NotZero,
    @qf.AtLeastZero,
    @qf.GreaterZero,
  ]
  for offset in -2..<=2 {
    let p = polynomial_fixture(1, [(1, [2]), (offset, [0])])
    for relation in relations {
      let target = @qf.Atom(p, relation)
      let source = @qf.Conjunction(
        target,
        @qf.Atom(p, @logic.complement(relation)),
      )
      let original = finish(make_problem(1, source), 2000)
      assert_true(
        check_result(problem_of(original), original, certificate(original)),
      )
      // Over R, x^2+offset has exact range [offset,+infinity).
      // This analytic oracle is independent of CAD samples and prefix signs.
      let impossible = match relation {
        LessZero => offset >= 0
        AtMostZero | EqualZero => offset > 0
        NotZero | AtLeastZero | GreaterZero => false
      }
      match refute_on_cover(original, target).unwrap() {
        Some(result) => {
          assert_true(impossible)
          assert_true(
            check_cover(@oracle.nat(1), target, certificate(result)) is Some(_),
          )
        }
        None => assert_false(impossible)
      }
    }
  }
}

///|
test "cover helpers can partition positive dimensional cylinders without becoming assumptions" {
  let p = polynomial_fixture(2, [(1, [2, 0]), (1, [0, 0])])
  let y = polynomial_fixture(2, [(1, [0, 1])])
  let target = @qf.Atom(p, @qf.LessZero)
  let source = @qf.Conjunction(target, @qf.Atom(y, @qf.EqualZero))
  let original = match finish_search(make_problem(2, source), 2000) {
    Unsatisfiable(value) => value
    _ => fail("positive square cannot be negative")
  }
  let reduced = cover_checked_refutation(original, target)
  match certificate(reduced).tree {
    Stack(_, children) =>
      assert_true(
        @core.all(children, fn(child) { child.subtree.equal(Leaf(false)) }),
      )
    _ => fail("x partition is needed to certify the square signs")
  }
  let opposite = @qf.Atom(p, @qf.AtLeastZero)
  assert_true(refute_on_cover(original, opposite) is Ok(None))
  assert_eq(
    evaluate_formula(
      rational_point(
        @oracle.chain([@oracle.rational(0, 1), @oracle.rational(7, 1)]),
      ),
      opposite,
    ),
    Ok(true),
  )
}

///|
test "cover refutation never weakens x equals zero and xy equals one into a false SAT atom" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let xy_one = polynomial_fixture(2, [(1, [1, 1]), (-1, [0, 0])])
  let x_zero = @qf.Atom(x, @qf.EqualZero)
  let product_one = @qf.Atom(xy_one, @qf.EqualZero)
  let source = @qf.Conjunction(x_zero, product_one)
  let original = match finish_search(make_problem(2, source), 2000) {
    Unsatisfiable(value) => value
    _ => fail("nullification contradicts the product equation")
  }
  for target in [x_zero, product_one] {
    assert_true(refute_on_cover(original, target) is Ok(None))
    assert_true(
      check_cover(@oracle.nat(2), target, {
        ..certificate(original),
        formula: target,
      })
      is None,
    )
  }
  assert_eq(
    evaluate_formula(
      rational_point(
        @oracle.chain([@oracle.rational(0, 1), @oracle.rational(17, 1)]),
      ),
      x_zero,
    ),
    Ok(true),
  )
  assert_eq(
    evaluate_formula(
      rational_point(
        @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
      ),
      product_one,
    ),
    Ok(true),
  )
}

///|
test "cover refutation remains conservative when an old shortened leaf hides an UNSAT subset" {
  let positive = polynomial_fixture(2, [(1, [0, 2]), (1, [0, 0])])
  let target = @qf.Atom(positive, @qf.LessZero)
  let source = @qf.Conjunction(@qf.Truth(false), target)
  let original = match finish_search(make_problem(2, source), 200) {
    Unsatisfiable(value) => value
    _ => fail("source is false")
  }
  assert_eq(certificate(original).tree, Leaf(false))
  assert_true(refute_on_cover(original, target) is Ok(None))
  // The target itself is UNSAT, but the old root leaf has no y sign observations.
  assert_false(search_answer(make_problem(2, target), 2000))
}

///|
test "cover checker binds irrational nullification and strict endpoint relations" {
  let d = polynomial_fixture(2, [(1, [2, 0]), (-2, [0, 0])])
  let product = polynomial_fixture(2, [(1, [2, 1]), (-2, [0, 1])])
  let source = @qf.Conjunction(
    @qf.Atom(d, @qf.EqualZero),
    @qf.Atom(product, @qf.GreaterZero),
  )
  let original = match finish_search(make_problem(2, source), 2000) {
    Unsatisfiable(value) => value
    _ => fail("zero coefficient cannot make a positive product")
  }
  ignore(cover_checked_refutation(original, source))
  let nonstrict = @qf.Conjunction(
    @qf.Atom(d, @qf.EqualZero),
    @qf.Atom(product, @qf.AtLeastZero),
  )
  assert_true(refute_on_cover(original, nonstrict) is Ok(None))
  assert_true(
    check_cover(@oracle.nat(2), nonstrict, {
      ..certificate(original),
      formula: nonstrict,
    })
    is None,
  )
  let target = @qf.Atom(d, @qf.EqualZero)
  assert_true(refute_on_cover(original, target) is Ok(None))
  assert_true(search_answer(make_problem(2, target), 2000))
}

///|
test "cover checker rejects source arity membership and coherent private payload substitutions" {
  let p = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let helper = polynomial_fixture(1, [(1, [1]), (-3, [0])])
  let target = @qf.Atom(p, @qf.LessZero)
  let source = @qf.Conjunction(target, @qf.Atom(helper, @qf.GreaterZero))
  let original = finish(make_problem(1, source), 2000)
  let reduced = cover_checked_refutation(original, target)
  let proof = certificate(reduced)
  let unsupported = @qf.Atom(
    polynomial_fixture(1, [(1, [2]), (2, [0])]),
    @qf.LessZero,
  )
  assert_true(refute_on_cover(original, unsupported) is Err(InvalidCertificate))
  assert_true(
    check_cover(@oracle.nat(1), unsupported, { ..proof, formula: unsupported, })
    is None,
  )
  assert_true(check_cover(@oracle.nat(2), target, proof) is None)
  assert_true(check_cover(@oracle.nat(1), @qf.Truth(false), proof) is None)
  let other = make_problem(1, @qf.Truth(false))
  let forged_problem = { ..problem_of(reduced), prefix: other.prefix, }
  assert_true(check(forged_problem, proof) is None)
  let forged_source = {
    ..original,
    problem: { ..problem_of(original), atoms: other.atoms, },
  }
  assert_true(refute_on_cover(forged_source, target) is Err(InvalidCertificate))
  let reversed = {
    ..proof.projection,
    levels: @core.reverse(proof.projection.levels),
  }
  assert_true(
    check_cover(@oracle.nat(1), target, { ..proof, projection: reversed, })
    is None,
  )
  let reordered = {
    ..proof.projection,
    levels: @core.map(proof.projection.levels, fn(level) {
      { ..level, family: @core.reverse(level.family), }
    }),
  }
  assert_false(reordered.equal(proof.projection))
  assert_true(
    check_cover(@oracle.nat(1), target, { ..proof, projection: reordered, })
    is None,
  )
}

///|
test "cover checker rechecks root coverage siblings and signs instead of trusting relabelled truth" {
  let p = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let helper = polynomial_fixture(1, [(1, [1]), (-3, [0])])
  let target = @qf.Atom(p, @qf.LessZero)
  let source = @qf.Conjunction(target, @qf.Atom(helper, @qf.GreaterZero))
  let original = finish(make_problem(1, source), 2000)
  let proof = certificate(cover_checked_refutation(original, target))
  assert_true(
    check_cover(@oracle.nat(1), target, { ..proof, tree: Leaf(false), }) is None,
  )
  match proof.tree {
    Stack(isolation, Cons(first, tail)) => {
      assert_true(
        check_cover(@oracle.nat(1), target, {
          ..proof,
          tree: Stack(isolation, tail),
        })
        is None,
      )
      let wrong_signs = @core.map(first.signs, fn(_) { @core.Equal })
      let wrong_cells = @core.Cons({ ..first, signs: wrong_signs, }, tail)
      assert_true(
        check_cover(@oracle.nat(1), target, {
          ..proof,
          tree: Stack(isolation, wrong_cells),
        })
        is None,
      )
      let broken_roots = { ..isolation, roots: @core.Nil, }
      assert_true(
        check_cover(@oracle.nat(1), target, {
          ..proof,
          tree: Stack(broken_roots, Cons(first, tail)),
        })
        is None,
      )
      // Producers use an opaque generated cover; untrusted or reconstructed
      // payloads still need the public boundary checker, even after relabelling.
      let bad_original = {
        ..original,
        proof: { ..certificate(original), tree: Stack(isolation, wrong_cells), },
      }
      match refute_on_cover(bad_original, target).unwrap() {
        Some(candidate) =>
          assert_true(
            check_cover(@oracle.nat(1), target, certificate(candidate)) is None,
          )
        None => ()
      }
    }
    _ => fail("expected nonempty root cover")
  }
}
