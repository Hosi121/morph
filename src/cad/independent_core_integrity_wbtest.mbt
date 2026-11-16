///|
fn core_review_polynomial(
  count : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(count),
    @oracle.chain(
      terms.map(fn(term) {
        let (numerator, denominator, powers) = term
        @poly.Term::{
          coefficient: @oracle.rational(numerator, denominator),
          exponents: @oracle.chain(powers.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn core_review_pair(
  count : Int32,
  whole : @qf.Formula,
  subset : @qf.Formula,
  subset_sat : Bool,
  pruned : Bool,
  reusable : Bool,
) -> Unit raise {
  let original = make_problem(count, whole)
  let cover = if pruned {
    match finish_search(original, 10000) {
      Unsatisfiable(value) => value
      _ => fail("independent whole formula must be UNSAT")
    }
  } else {
    finish(original, 10000)
  }
  assert_true(check_result(original, cover, certificate(cover)))
  assert_eq(
    sentence(
      cover,
      @core.replicate_onto(@oracle.nat(count), @logic.Quantifier::Exists, Nil),
    ),
    Ok(false),
  )
  let target = make_problem(count, subset)
  let target_reference = finish(target, 10000)
  assert_true(
    check_result(target, target_reference, certificate(target_reference)),
  )
  assert_eq(
    sentence(
      target_reference,
      @core.replicate_onto(@oracle.nat(count), @logic.Quantifier::Exists, Nil),
    ),
    Ok(subset_sat),
  )
  if subset_sat {
    assert_true(
      check_witness(target, witness(target_reference).unwrap().unwrap()),
    )
  }
  match refute_on_cover(cover, subset).unwrap() {
    None => assert_false(reusable)
    Some(reduced) => {
      assert_true(reusable)
      assert_false(subset_sat)
      let proof = certificate(reduced)
      assert_eq(proof.formula, subset)
      assert_eq(proof.arity, @oracle.nat(count))
      assert_eq(proof.projection, projection(original))
      assert_true(check_cover(@oracle.nat(count), subset, proof) is Some(_))
      assert_true(check_result(problem_of(reduced), reduced, proof))
      assert_eq(
        sentence(
          reduced,
          @core.replicate_onto(
            @oracle.nat(count),
            @logic.Quantifier::Exists,
            Nil,
          ),
        ),
        Ok(false),
      )
      assert_true(
        check_cover(@core.Succ(@oracle.nat(count)), subset, proof) is None,
      )
      assert_true(
        check_cover(@oracle.nat(count), @qf.Truth(true), proof) is None,
      )
    }
  }
}

///|
test "independent core cover missing target cannot be repaired by relabeling source metadata" {
  let positive = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let original = make_problem(1, @qf.Atom(positive, @qf.LessZero))
  let proof = certificate(finish(original, 1000))
  let x = polynomial_fixture(1, [(1, [1])])
  let satisfiable = @qf.Atom(x, @qf.EqualZero)
  assert_true(
    check_cover(@oracle.nat(1), satisfiable, { ..proof, formula: satisfiable, })
    is None,
  )
  assert_true(
    refute_on_cover(finish(original, 1000), satisfiable)
    is Err(InvalidCertificate),
  )
  let wrong_arity = @qf.Atom(
    polynomial_fixture(2, [(1, [1, 0])]),
    @qf.EqualZero,
  )
  assert_true(
    check_cover(@oracle.nat(1), wrong_arity, { ..proof, formula: wrong_arity, })
    is None,
  )
  assert_true(
    refute_on_cover(finish(original, 1000), wrong_arity) is Err(WrongArity),
  )
}

///|
test "independent core cover projection source family and hidden payload stay bound" {
  let positive = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let helper = polynomial_fixture(1, [(1, [1]), (-2, [0])])
  let source = @qf.Conjunction(
    @qf.Atom(positive, @qf.LessZero),
    @qf.Atom(helper, @qf.EqualZero),
  )
  let original = make_problem(1, source)
  let reduced = refute_on_cover(
      finish(original, 2000),
      @qf.Atom(positive, @qf.LessZero),
    )
    .unwrap()
    .unwrap()
  let proof = certificate(reduced)
  let target = proof.formula
  assert_true(check_cover(@oracle.nat(1), target, proof) is Some(_))
  let canonical = make_problem(1, target)
  assert_false(proof.projection.equal(projection(canonical)))
  assert_true(check(canonical, proof) is None)
  let reversed = {
    ..proof.projection,
    levels: @core.map(proof.projection.levels, fn(level) {
      { ..level, family: @core.reverse(level.family), }
    }),
  }
  assert_false(reversed.equal(proof.projection))
  assert_true(
    check_cover(@oracle.nat(1), target, { ..proof, projection: reversed, })
    is None,
  )
  assert_true(
    check_cover(@oracle.nat(1), target, {
      ..proof,
      projection: { ..proof.projection, atoms: @core.Nil, },
    })
    is None,
  )
  assert_true(
    check_cover(@oracle.nat(1), target, {
      ..proof,
      projection: { ..proof.projection, arity: @core.Zero, },
    })
    is None,
  )
  let problem = problem_of(reduced)
  let foreign = make_problem(1, @qf.Truth(false))
  let forged = { ..problem, prefix: foreign.prefix, }
  assert_true(check(forged, proof) is None)
  let forged_atoms = { ..problem, atoms: @core.Nil, }
  assert_true(check(forged_atoms, proof) is None)
}

///|
test "independent core cover SAT weakening cannot inherit old all false leaf labels" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let product = polynomial_fixture(2, [(1, [1, 1]), (-1, [0, 0])])
  let source = @qf.Conjunction(
    @qf.Atom(x, @qf.EqualZero),
    @qf.Atom(product, @qf.EqualZero),
  )
  let original = make_problem(2, source)
  let cover = finish(original, 4000)
  let proof = certificate(cover)
  let target = @qf.Atom(product, @qf.EqualZero)
  let target_problem = make_problem(2, target)
  assert_true(
    check_witness(
      target_problem,
      rational_point(
        @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
      ),
    ),
  )
  assert_true(refute_on_cover(cover, target).unwrap() is None)
  assert_true(
    check_cover(@oracle.nat(2), target, { ..proof, formula: target, }) is None,
  )
  // Even a geometrically valid x partition with every y sample set to zero
  // cannot justify a false cylinder for xy=1 when x is nonzero.
  let shallow = match proof.tree {
    Stack(isolation, cells) =>
      Stack(
        isolation,
        @core.map(cells, fn(cell) { { ..cell, subtree: Leaf(false), } }),
      )
    _ => fail("expected a nontrivial x cover")
  }
  assert_true(
    check_cover(@oracle.nat(2), target, {
      ..proof,
      formula: target,
      tree: shallow,
    })
    is None,
  )
}

///|
test "independent core cover checks sibling root samples and observed signs" {
  let positive = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let helper = polynomial_fixture(1, [(1, [1]), (-2, [0])])
  let original = make_problem(
    1,
    @qf.Conjunction(
      @qf.Atom(positive, @qf.LessZero),
      @qf.Atom(helper, @qf.EqualZero),
    ),
  )
  let reduced = refute_on_cover(
      finish(original, 2000),
      @qf.Atom(positive, @qf.LessZero),
    )
    .unwrap()
    .unwrap()
  let proof = certificate(reduced)
  match proof.tree {
    Stack(isolation, Cons(first, tail)) => {
      assert_true(
        check_cover(@oracle.nat(1), proof.formula, {
          ..proof,
          tree: Stack(isolation, tail),
        })
        is None,
      )
      let roots = { ..isolation, roots: @core.Nil, }
      assert_false(isolation.equal(roots))
      assert_true(
        check_cover(@oracle.nat(1), proof.formula, {
          ..proof,
          tree: Stack(roots, Cons(first, tail)),
        })
        is None,
      )
      let signs = @core.map(first.signs, fn(sign) {
        match sign {
          Equal => @core.Greater
          _ => @core.Equal
        }
      })
      assert_true(
        check_cover(@oracle.nat(1), proof.formula, {
          ..proof,
          tree: Stack(isolation, Cons({ ..first, signs, }, tail)),
        })
        is None,
      )
      let sample = Sample::RationalPoint(@oracle.rational(100, 1))
      assert_true(
        check_cover(@oracle.nat(1), proof.formula, {
          ..proof,
          tree: Stack(isolation, Cons({ ..first, sample, }, tail)),
        })
        is None,
      )
    }
    _ => fail("expected geometric stack before false leaves")
  }
}

///|
test "independent core cover missing polynomial would miss irrational roots" {
  let positive = polynomial_fixture(1, [(1, [2]), (1, [0])])
  let original = make_problem(1, @qf.Atom(positive, @qf.LessZero))
  let cover = finish(original, 1000)
  let proof = certificate(cover)
  let missed = polynomial_fixture(1, [(1, [2]), (-2, [0])])
  let target = @qf.Atom(missed, @qf.EqualZero)
  let level = @core.nth(proof.projection.levels, @oracle.nat(1)).unwrap()
  let origin = rational_point(@core.Nil)
  let fibre = prepare_fibre(origin, level.family).unwrap()
  match proof.tree {
    Stack(_, cells) =>
      for cell in @oracle.array(cells) {
        let sample = extend_point(origin, fibre, cell.sample).unwrap()
        // All samples of the unrelated x^2+1 partition miss +-sqrt(2).
        // Rechecking truth at just these points would still say false.
        assert_eq(evaluate_formula(sample, target), Ok(false))
      }
    _ => fail("expected the source derivative partition")
  }
  let target_problem = make_problem(1, target)
  let target_value = finish(target_problem, 1000)
  assert_true(
    check_witness(target_problem, witness(target_value).unwrap().unwrap()),
  )
  assert_true(
    check_cover(@oracle.nat(1), target, { ..proof, formula: target, }) is None,
  )
  assert_true(refute_on_cover(cover, target) is Err(InvalidCertificate))
}
