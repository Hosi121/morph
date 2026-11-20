///|
fn finish_search(problem : Problem, fuel : Int32) -> SearchProgress raise {
  match search_run(start_search(problem), @oracle.nat(fuel)) {
    Ok(Paused(_)) => fail("search exhausted transition budget")
    Ok(result) => result
    Err(error) => fail("search error: \{error.to_repr()}")
  }
}

///|
fn search_answer(problem : Problem, fuel : Int32) -> Bool raise {
  match finish_search(problem, fuel) {
    Satisfiable(point) => {
      assert_true(check_witness(problem, point))
      true
    }
    Unsatisfiable(result) => {
      assert_true(check_result(problem, result, certificate(result)))
      assert_eq(
        sentence(
          result,
          @core.replicate_onto(arity(problem), @logic.Quantifier::Exists, Nil),
        ),
        Ok(false),
      )
      false
    }
    Paused(_) => fail("unfinished search")
  }
}

///|
test "search constant cylinders terminate without lifting remaining coordinates" {
  for dimensions in 0..<=4 {
    let yes = make_problem(dimensions, @qf.Truth(true))
    match search_step(start_search(yes)).unwrap() {
      Satisfiable(point) => {
        assert_true(check_witness(yes, point))
        assert_eq(@core.length(coordinates(point)), @oracle.nat(dimensions))
      }
      _ => fail("constant true should immediately produce a complete point")
    }
    let no = make_problem(dimensions, @qf.Truth(false))
    match search_step(start_search(no)).unwrap() {
      Unsatisfiable(value) => {
        assert_eq(certificate(value).tree, Leaf(false))
        assert_true(check_result(no, value, certificate(value)))
        assert_eq(
          sentence(
            value,
            @core.replicate_onto(
              @oracle.nat(dimensions),
              @logic.Quantifier::Forall,
              Nil,
            ),
          ),
          Ok(false),
        )
      }
      _ => fail("constant false should close the whole cylinder")
    }
    assert_true(search_run(start_search(no), @core.Zero) is Ok(Paused(_)))
  }
}

///|
test "search rejects xy equals one over the entire x equals zero parent cell" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let xy_minus_one = polynomial_fixture(2, [(1, [1, 1]), (-1, [0, 0])])
  let problem = make_problem(
    2,
    @qf.Conjunction(
      @qf.Atom(x, @qf.EqualZero),
      @qf.Atom(xy_minus_one, @qf.EqualZero),
    ),
  )
  let compact = match finish_search(problem, 1000) {
    Unsatisfiable(result) => result
    _ => fail("x=0 and xy=1 is inconsistent")
  }
  let proof = certificate(compact)
  assert_true(check_result(problem, compact, proof))
  // The checked identity xy-1 = y*x-1 now refutes the whole cylinder.
  assert_eq(proof.tree, Leaf(false))
  let reference = finish(problem, 2000)
  assert_true(check_result(problem, reference, certificate(reference)))
  // Keep the complete geometric reference, including the three x cells.
  match certificate(reference).tree {
    Stack(_, cells) => assert_eq(@core.length(cells), @oracle.nat(3))
    _ => fail("complete CAD must retain its geometric root cover")
  }
  assert_eq(
    sentence(
      reference,
      @oracle.chain([@logic.Quantifier::Exists, @logic.Quantifier::Exists]),
    ),
    Ok(false),
  )
}

///|
test "search agrees with complete CAD on algebraic and mixed Boolean fibres" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let y_squared_minus_two = polynomial_fixture(2, [(1, [0, 2]), (-2, [0, 0])])
  let y_squared_plus_one = polynomial_fixture(2, [(1, [0, 2]), (1, [0, 0])])
  let xy_minus_one = polynomial_fixture(2, [(1, [1, 1]), (-1, [0, 0])])
  let formulas : Array[@qf.Formula] = [
    @qf.Conjunction(
      @qf.Atom(x, @qf.GreaterZero),
      @qf.Atom(y_squared_minus_two, @qf.EqualZero),
    ),
    @qf.Disjunction(
      @qf.Atom(x, @qf.EqualZero),
      @qf.Atom(y_squared_plus_one, @qf.EqualZero),
    ),
    @qf.Conjunction(
      @qf.Atom(x, @qf.EqualZero),
      @qf.Atom(xy_minus_one, @qf.EqualZero),
    ),
    @qf.Negation(
      @qf.Disjunction(
        @qf.Atom(x, @qf.NotZero),
        @qf.Atom(xy_minus_one, @qf.NotZero),
      ),
    ),
    @qf.Atom(y_squared_plus_one, @qf.LessZero),
  ]
  for formula in formulas {
    let problem = make_problem(2, formula)
    let reference = finish(problem, 10000)
    assert_true(check_result(problem, reference, certificate(reference)))
    let expected = sentence(
      reference,
      @oracle.chain([@logic.Quantifier::Exists, @logic.Quantifier::Exists]),
    ).unwrap()
    assert_eq(search_answer(problem, 10000), expected)
  }
}

///|
test "true cylinder certificates support exact witness completion and mixed QE" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let problem = make_problem(2, @qf.Atom(x, @qf.EqualZero))
  let reference = finish(problem, 2000)
  let compact_tree = match certificate(reference).tree {
    Stack(isolation, cells) =>
      Stack(
        isolation,
        @core.map(cells, fn(cell) {
          let holds = @core.any(cell.signs, fn(sign) { sign is Equal })
          { ..cell, subtree: Leaf(holds), }
        }),
      )
    _ => fail("expected x decomposition")
  }
  let proof = { ..certificate(reference), tree: compact_tree, }
  let checked = match check(problem, proof) {
    Some(value) => value
    None => fail("constant y cylinders should validate")
  }
  let point = witness(checked).unwrap().unwrap()
  assert_true(check_witness(problem, point))
  assert_eq(@core.length(coordinates(point)), @oracle.nat(2))
  assert_eq(
    sentence(
      checked,
      @oracle.chain([@logic.Quantifier::Exists, @logic.Quantifier::Forall]),
    ),
    Ok(true),
  )
  assert_eq(
    sentence(
      checked,
      @oracle.chain([@logic.Quantifier::Forall, @logic.Quantifier::Exists]),
    ),
    Ok(false),
  )
  assert_true(
    check_elimination(
      problem,
      @oracle.nat(1),
      @oracle.chain([@logic.Quantifier::Forall]),
      elimination_certificate(
        eliminate(
          checked,
          @oracle.nat(1),
          @oracle.chain([@logic.Quantifier::Forall]),
        ).unwrap(),
      ),
    )
    is Some(_),
  )
}

///|
test "shortened proof leaves cannot replace unknown cells or forge source plans" {
  let x = polynomial_fixture(2, [(1, [1, 0])])
  let problem = make_problem(2, @qf.Atom(x, @qf.EqualZero))
  let reference = finish(problem, 2000)
  let proof = certificate(reference)
  assert_true(check(problem, { ..proof, tree: Leaf(false), }) is None)
  assert_true(check(problem, { ..proof, tree: Leaf(true), }) is None)
  let bad = make_problem(2, @qf.Truth(false))
  let forged = { ..problem, prefix: bad.prefix, }
  assert_true(check(forged, proof) is None)
  match proof.tree {
    Stack(isolation, Cons(first, tail)) => {
      assert_true(
        check(problem, { ..proof, tree: Stack(isolation, tail), }) is None,
      )
      assert_true(
        check(problem, {
          ..proof,
          tree: Stack(isolation, Cons({ ..first, subtree: Leaf(true), }, tail)),
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
        check(problem, {
          ..proof,
          tree: Stack(
            isolation,
            Cons({ ..first, signs, subtree: Leaf(true), }, tail),
          ),
        })
        is None,
      )
    }
    _ => fail("expected nontrivial x cover")
  }
}

///|
test "quadratic nullification conflict has a checked root leaf bound to its original source" {
  let source = @qf.Conjunction(
    @qf.Atom(
      incremental_review_polynomial(3, [(1, 1, [1, 0, 0])]),
      @qf.EqualZero,
    ),
    @qf.Conjunction(
      @qf.Atom(
        incremental_review_polynomial(3, [(1, 1, [0, 1, 0]), (-1, 1, [0, 0, 0])]),
        @qf.EqualZero,
      ),
      @qf.Atom(
        incremental_review_polynomial(3, [
          (1, 1, [1, 0, 2]),
          (1, 1, [0, 1, 1]),
          (-1, 1, [0, 0, 1]),
          (-1, 1, [0, 0, 0]),
        ]),
        @qf.EqualZero,
      ),
    ),
  )
  let problem = prepare(@oracle.nat(3), source).unwrap()
  let value = match search_step(start_search(problem)).unwrap() {
    Unsatisfiable(value) => value
    _ => fail("global polynomial identity must avoid lifting")
  }
  assert_eq(certificate(value).tree, Leaf(false))
  assert_true(check_result(problem, value, certificate(value)))
  // A coherent source/projection relabel to SAT must still reject the false leaf.
  let other = @qf.Conjunction(
    @qf.Atom(polynomial_fixture(3, [(1, [1, 0, 0])]), @qf.EqualZero),
    @qf.Conjunction(
      @qf.Atom(
        polynomial_fixture(3, [(1, [0, 1, 0]), (-1, [0, 0, 0])]),
        @qf.EqualZero,
      ),
      @qf.Atom(
        polynomial_fixture(3, [(1, [1, 0, 2]), (1, [0, 1, 1]), (-1, [0, 0, 1])]),
        @qf.EqualZero,
      ),
    ),
  )
  let sat = prepare(@oracle.nat(3), other).unwrap()
  let forged : Certificate = {
    ..certificate(value),
    formula: other,
    projection: projection(sat),
  }
  assert_true(check(sat, forged) is None)
  match search_run(start_search(sat), @oracle.nat(20000)).unwrap() {
    Satisfiable(point) => assert_true(check_witness(sat, point))
    _ => fail("zero residual was incorrectly refuted")
  }
}
