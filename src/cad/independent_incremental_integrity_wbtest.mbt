///|
fn incremental_review_polynomial(
  count : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial raise {
  let converted = terms.map(fn(term) {
    let (numerator, denominator, powers) = term
    @poly.Term::{
      coefficient: @oracle.rational(numerator, denominator),
      exponents: @oracle.chain(powers.map(@oracle.nat)),
    }
  })
  match @poly.polynomial(@oracle.nat(count), @oracle.chain(converted)) {
    Ok(polynomial) => polynomial
    Err(_) => fail("invalid independent review polynomial")
  }
}

///|
fn incremental_review_expect(
  count : Int32,
  source : @qf.Formula,
  expected : Bool,
  compare_full : Bool,
) -> Unit raise {
  let problem = prepare(@oracle.nat(count), source).unwrap()
  let quantifiers = @core.replicate_onto(
    @oracle.nat(count),
    @logic.Quantifier::Exists,
    @core.Nil,
  )
  if compare_full {
    let full = match run(start(problem), @oracle.nat(20000)) {
      Ok(Complete(value)) => value
      Ok(Paused(_)) => fail("independent full CAD reference exhausted fuel")
      Err(error) => fail("independent full CAD error: \{error.to_repr()}")
    }
    assert_true(check_result(problem, full, certificate(full)))
    assert_eq(sentence(full, quantifiers), Ok(expected))
  }
  match search_run(start_search(problem), @oracle.nat(20000)) {
    Ok(Satisfiable(point)) => {
      assert_true(expected)
      assert_true(check_witness(problem, point))
    }
    Ok(Unsatisfiable(value)) => {
      assert_false(expected)
      assert_true(check_result(problem, value, certificate(value)))
      assert_eq(sentence(value, quantifiers), Ok(false))
    }
    Ok(Paused(_)) => fail("independent pruned search exhausted fuel")
    Err(error) => fail("independent pruned search error: \{error.to_repr()}")
  }
}

///|
test "independent incremental point evaluation cannot certify an entire suffix" {
  let xy_minus_one = polynomial_fixture(2, [(1, [1, 1]), (-1, [0, 0])])
  let problem = make_problem(2, @qf.Atom(xy_minus_one, @qf.EqualZero))
  // Every prefix sample with suffix y=0 is false, while x=y=1 is a model.
  assert_eq(
    evaluate_formula(
      rational_point(
        @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)]),
      ),
      formula(problem),
    ),
    Ok(false),
  )
  assert_true(
    check_witness(
      problem,
      rational_point(
        @oracle.chain([@oracle.rational(1, 1), @oracle.rational(1, 1)]),
      ),
    ),
  )
  let full = finish(problem, 4000)
  let proof = certificate(full)
  match proof.tree {
    Stack(isolation, cells) => {
      let wrongly_false = @core.map(cells, fn(cell) {
        { ..cell, subtree: Leaf(false), }
      })
      let wrongly_true = @core.map(cells, fn(cell) {
        { ..cell, subtree: Leaf(true), }
      })
      assert_true(
        check(problem, { ..proof, tree: Stack(isolation, wrongly_false), })
        is None,
      )
      assert_true(
        check(problem, { ..proof, tree: Stack(isolation, wrongly_true), })
        is None,
      )
    }
    _ => fail("expected x prefix stacks")
  }
}

///|
test "independent incremental positive dimensional sectors admit only uniform shortened leaves" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let problem = make_problem(2, @qf.Atom(x, @qf.GreaterZero))
  let proof = certificate(finish(problem, 2000))
  match proof.tree {
    Stack(isolation, cells) => {
      let compact = @core.map(cells, fn(cell) {
        let positive = @core.any(cell.signs, fn(sign) { sign is Greater })
        { ..cell, subtree: Leaf(positive), }
      })
      let compact_proof = { ..proof, tree: Stack(isolation, compact), }
      let checked = check(problem, compact_proof).unwrap()
      assert_true(check_witness(problem, witness(checked).unwrap().unwrap()))
      // Shift each asserted parent sign and leaf together: internally coherent
      // truth labels still cannot replace recomputed signs of the actual cell.
      let forged_cells = @core.map(compact, fn(cell) {
        let signs = @core.map(cell.signs, fn(sign) {
          match sign {
            Greater => @core.Less
            _ => @core.Greater
          }
        })
        let positive = @core.any(signs, fn(sign) { sign is Greater })
        { ..cell, signs, subtree: Leaf(positive), }
      })
      assert_true(
        check(problem, { ..proof, tree: Stack(isolation, forged_cells), })
        is None,
      )
      assert_true(
        check(problem, {
          ..proof,
          tree: Stack(isolation, @core.reverse(compact)),
        })
        is None,
      )
      let shifted = make_problem(
        2,
        @qf.Atom(
          polynomial_fixture(2, [(1, [1, 0]), (-1, [0, 0])]),
          @qf.GreaterZero,
        ),
      )
      assert_true(
        check(shifted, {
          ..compact_proof,
          formula: formula(shifted),
          projection: projection(shifted),
        })
        is None,
      )
    }
    _ => fail("expected x-sector decomposition")
  }
}

///|
test "independent incremental shortened irrational sections bind coefficients and endpoint relations" {
  let d = polynomial_fixture(2, [(1, [2, 0]), (-2, [0, 0])])
  let product = polynomial_fixture(2, [(1, [2, 1]), (-2, [0, 1])])
  let source = @qf.Conjunction(
    @qf.Atom(d, @qf.EqualZero),
    @qf.Atom(product, @qf.GreaterZero),
  )
  let problem = make_problem(2, source)
  let value = match finish_search(problem, 4000) {
    Unsatisfiable(value) => value
    _ => fail("strictly positive zero product is impossible")
  }
  let proof = certificate(value)
  assert_true(check_result(problem, value, proof))
  let nonstrict = make_problem(
    2,
    @qf.Conjunction(
      @qf.Atom(d, @qf.EqualZero),
      @qf.Atom(product, @qf.AtLeastZero),
    ),
  )
  assert_true(
    check(nonstrict, {
      ..proof,
      formula: formula(nonstrict),
      projection: projection(nonstrict),
    })
    is None,
  )
  let forged = { ..problem, prefix: nonstrict.prefix, }
  assert_true(check(forged, proof) is None)
  // Different false formulas can share a compact all-false shape. The original
  // source and projection remain part of the certificate independently.
  let other = make_problem(2, @qf.Truth(false))
  assert_true(check(problem, certificate(finish(other, 1000))) is None)
}

///|
test "independent incremental coherently rebuilt prefix plan cannot bless reordered projection family" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let shifted = polynomial_fixture(2, [(1, [1, 0]), (-1, [0, 0])])
  let problem = make_problem(
    2,
    @qf.Conjunction(
      @qf.Atom(x, @qf.GreaterZero),
      @qf.Atom(shifted, @qf.AtMostZero),
    ),
  )
  let proof = certificate(finish(problem, 2000))
  let projection = {
    ..problem.projection,
    levels: @core.map(problem.projection.levels, fn(level) {
      { ..level, family: @core.reverse(level.family), }
    }),
  }
  assert_false(projection.equal(problem.projection))
  let prefix = @prefix.prepare(
    problem.arity,
    problem.formula,
    @core.map(projection.levels, @projection.family),
  ).unwrap()
  let forged = { ..problem, projection, prefix, }
  assert_true(check(forged, { ..proof, projection, }) is None)
}
