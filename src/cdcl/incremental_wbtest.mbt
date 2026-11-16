///|
fn incremental_finish(search : Search) -> IncrementalStatus raise {
  match run_incremental(search, @oracle.nat(2000)) {
    Paused(_) => fail("incremental test exhausted fuel")
    InvariantViolation => fail("incremental invariant violation")
    outcome => outcome
  }
}

///|
fn incremental_answer(
  search : Search,
  formula : @sat.Cnf,
  variables : Int32,
) -> Search? raise {
  let expected = brute(formula, variables)
  match incremental_finish(search) {
    Satisfiable(model, cursor) => {
      assert_true(expected)
      assert_true(@sat.check_model(formula, model))
      assert_eq(model, cdcl_model_from_cursor(cursor))
      for entry in @oracle.array(cursor.trail) {
        match cursor.watch {
          None => ()
          Some(watch) =>
            assert_eq(
              index_get(watch.values, @binary.bits(entry.literal.key)),
              Some(entry),
            )
        }
      }
      Some(cursor)
    }
    Unsatisfiable(proof) => {
      assert_false(expected)
      assert_true(check_refutation(formula, proof))
      assert_true(check_refutation_scanning(formula, proof))
      None
    }
    _ => fail("finish must decide")
  }
}

///|
fn cdcl_model_from_cursor(cursor : Search) -> @sat.Model {
  model(cursor.trail, cursor.variables)
}

///|
test "incremental completion preserves ordinary transition results statistics and persistence" {
  let formulas = [
    cnf([]),
    cnf([[]]),
    cnf([[lit(0, true), lit(1, true)]]),
    pigeonhole(4, 3),
    cnf([
      [lit(0, true), lit(3, true)],
      [lit(1, true), lit(4, true)],
      [lit(2, true), lit(5, true)],
      [lit(0, false), lit(2, false), lit(6, true)],
      [lit(0, false), lit(2, false), lit(6, false)],
    ]),
  ]
  for formula in formulas {
    for initial in [start(formula), start_scanning(formula)] {
      assert_eq(
        run_incremental(initial, @core.Zero),
        IncrementalStatus::Paused(initial),
      )
      for cursor = initial, count = 0 {
        assert_true(count < 2000)
        let (ordinary, statistics) = run_measured(cursor, @oracle.nat(1))
        match (ordinary, run_incremental(cursor, @oracle.nat(1))) {
          (Paused(expected), Paused(actual)) => {
            assert_eq(actual, expected)
            continue actual, count + 1
          }
          (Satisfiable(expected), Satisfiable(actual, state)) => {
            assert_eq(actual, expected)
            assert_eq(state.statistics, statistics)
            assert_true(@sat.check_model(formula, actual))
            assert_eq(
              run_incremental(initial, @oracle.nat(2000)),
              incremental_finish(initial),
            )
            break
          }
          (Unsatisfiable(expected), Unsatisfiable(actual)) => {
            assert_eq(actual, expected)
            assert_true(check_refutation(formula, actual))
            break
          }
          _ => fail("incremental and ordinary engines diverged")
        }
      }
    }
  }
}

///|
test "incremental monotone additions agree with host truth tables for all three variable clause pairs" {
  for a in 0..<27 {
    for b in 0..<27 {
      let first = ternary_clause(a, 3)
      let second = ternary_clause(b, 3)
      for watched in [false, true] {
        let original = @core.Cons(first, @core.Nil)
        let initial = if watched {
          start(original)
        } else {
          start_scanning(original)
        }
        match incremental_answer(initial, original, 3) {
          None => ()
          Some(cursor) => {
            let augmented = @core.append(
              original,
              @core.Cons(second, @core.Nil),
            )
            let inserted = add_clause(cursor, second)
            assert_eq(inserted.trail, cursor.trail)
            assert_eq(inserted.level, cursor.level)
            assert_eq(inserted.statistics, cursor.statistics)
            assert_eq(inserted.proof_rev, cursor.proof_rev)
            ignore(incremental_answer(inserted, augmented, 3))
          }
        }
      }
    }
  }
}

///|
test "incremental deterministic four variable prefixes agree with exhaustive Boolean assignments" {
  let mut seed = 41957
  for _ in 0..<400 {
    let mut formula : @sat.Cnf = @core.Nil
    let mut watched = start(formula)
    let mut scanning = start_scanning(formula)
    for _ in 0..<10 {
      let clause = []
      for variable in 0..<4 {
        seed = (seed * 61 + 17) % 65521
        let digit = seed % 3
        if digit != 0 {
          clause.push(lit(variable, digit == 1))
        }
      }
      let clause = @oracle.chain(clause)
      formula = @core.append(formula, @core.Cons(clause, @core.Nil))
      watched = add_clause(watched, clause)
      scanning = add_clause(scanning, clause)
      match
        (
          incremental_answer(watched, formula, 4),
          incremental_answer(scanning, formula, 4),
        ) {
        (Some(next), Some(other)) => {
          watched = next
          scanning = other
        }
        (None, None) => break
        _ => fail("scan and watches disagree with truth table")
      }
    }
  }
}

///|
test "incremental tautological additions register every new sparse identifier without changing learned state" {
  for watched in [false, true] {
    let initial = if watched {
      start(cnf([[lit(0, true)]]))
    } else {
      start_scanning(cnf([[lit(0, true)]]))
    }
    let cursor = match incremental_finish(initial) {
      Satisfiable(_, cursor) => cursor
      _ => fail("initial unit is satisfiable")
    }
    let clause = @oracle.chain([
      lit(200, true),
      lit(200, false),
      lit(65535, true),
      lit(65535, true),
    ])
    let inserted = add_clause(cursor, clause)
    assert_eq(inserted.database, cursor.database)
    assert_eq(inserted.watch, cursor.watch)
    assert_eq(inserted.trail, cursor.trail)
    assert_eq(inserted.statistics, cursor.statistics)
    assert_eq(inserted.proof_rev, cursor.proof_rev)
    match incremental_finish(inserted) {
      Satisfiable(result, next) => {
        assert_eq(@core.length(result), @oracle.nat(3))
        assert_true(
          @core.any(result, fn(literal) {
            literal.variable.equal(@oracle.nat(65535))
          }),
        )
        assert_true(
          @core.any(result, fn(literal) {
            literal.variable.equal(@oracle.nat(200))
          }),
        )
        let negative = @oracle.chain([lit(65535, false), lit(65535, false)])
        let completed = add_clause(next, negative)
        match incremental_finish(completed) {
          Satisfiable(result, _) =>
            assert_true(
              @sat.check_model(
                cnf([
                  [lit(0, true)],
                  @oracle.array(clause),
                  @oracle.array(negative),
                ]),
                result,
              ),
            )
          _ => fail("negative new variable remains satisfiable")
        }
      }
      _ => fail("tautology preserves satisfiability")
    }
  }
}

///|
test "incremental added units survive later backjumps instead of losing their propagation event" {
  let original = cnf([[lit(0, true), lit(1, true)]])
  for watched in [false, true] {
    let initial = if watched {
      start(original)
    } else {
      start_scanning(original)
    }
    let first = incremental_answer(initial, original, 2).unwrap()
    assert_eq(first.level, @oracle.nat(1))
    // b is not yet assigned: an added unit first propagates at decision level1.
    assert_true(assignment(first.trail, atom(lit(1, true))) is None)
    let unit_b = @oracle.chain([lit(1, true)])
    let with_b = @core.append(original, @core.Cons(unit_b, @core.Nil))
    let second = incremental_answer(add_clause(first, unit_b), with_b, 2).unwrap()
    assert_eq(
      assignment(second.trail, atom(lit(1, true))).unwrap().level,
      @oracle.nat(1),
    )
    // A conflicting input forces root backjump, dropping b's level1 assignment.
    let not_a = @oracle.chain([lit(0, false)])
    let final_formula = @core.append(with_b, @core.Cons(not_a, @core.Nil))
    let completed = incremental_answer(
      add_clause(second, not_a),
      final_formula,
      2,
    ).unwrap()
    let b = assignment(completed.trail, atom(lit(1, true))).unwrap()
    assert_true(b.literal.positive)
    assert_eq(b.level, @core.Zero)
    assert_true(@oracle.int_of_nat(completed.statistics.backjumps) > 0)
  }
}

///|
test "incremental input insertion while watches have active buckets and queued units remains exact" {
  let original = cnf([
    [lit(0, true)],
    [lit(0, false), lit(1, true)],
    [lit(0, false), lit(2, true)],
    [lit(1, false), lit(3, true)],
    [lit(2, false), lit(3, true)],
  ])
  let mut saw_active = false
  for watched in [false, true] {
    let initial = if watched {
      start(original)
    } else {
      start_scanning(original)
    }
    for state = initial, step_count = 0 {
      assert_true(step_count < 10)
      match state.watch {
        Some(watch) =>
          if watch.active is Some((_, Cons(_, _))) {
            saw_active = true
          }
        None => ()
      }
      for code in 0..<27 {
        let clause = ternary_clause(code, 3)
        let formula = @core.append(original, @core.Cons(clause, @core.Nil))
        ignore(incremental_answer(add_clause(state, clause), formula, 4))
      }
      match run_incremental(state, @oracle.nat(1)) {
        Paused(next) => continue next, step_count + 1
        Satisfiable(_, _) => break
        _ => fail("positive propagation chain must stay satisfiable")
      }
    }
  }
  assert_true(saw_active)
}

///|
test "incremental retained RUP additions are checked only relative to all external input axioms" {
  let original = cnf([
    [lit(0, true), lit(3, true)],
    [lit(1, true), lit(4, true)],
    [lit(2, true), lit(5, true)],
    [lit(0, false), lit(2, false), lit(6, true)],
    [lit(0, false), lit(2, false), lit(6, false)],
  ])
  for watched in [false, true] {
    let initial = if watched {
      start(original)
    } else {
      start_scanning(original)
    }
    let cursor = incremental_answer(initial, original, 7).unwrap()
    assert_true(@oracle.int_of_nat(cursor.statistics.learned) > 0)
    assert_true(cursor.proof_rev is Cons(_, _))
    let a = @oracle.chain([lit(0, true)])
    let inserted = add_clause(cursor, a)
    assert_eq(inserted.proof_rev, cursor.proof_rev)
    assert_eq(inserted.statistics, cursor.statistics)
    assert_eq(inserted.trail, cursor.trail)
    match (cursor.watch, inserted.watch) {
      (Some(before), Some(after)) => {
        assert_eq(after.values, before.values)
        assert_eq(after.next_id, @binary.successor(before.next_id))
      }
      (None, None) => ()
      _ => fail("insertion cannot change engine mode")
    }
    let first_formula = @core.append(original, @core.Cons(a, @core.Nil))
    let second = incremental_answer(inserted, first_formula, 7).unwrap()
    let c = @oracle.chain([lit(2, true)])
    let augmented = @core.append(first_formula, @core.Cons(c, @core.Nil))
    match incremental_finish(add_clause(second, c)) {
      Unsatisfiable(proof) => {
        assert_true(check_refutation(augmented, proof))
        assert_false(check_refutation(original, proof))
        let Rup(steps) = proof
        assert_true(
          @oracle.int_of_nat(@core.length(steps)) >
          @oracle.int_of_nat(@core.length(cursor.proof_rev)),
        )
      }
      _ => fail("a and c conflict with the retained original clauses")
    }
  }
}

///|
test "incremental new conflicts below the current level backjump soundly and empty input is not a RUP step" {
  let original = cnf([
    [lit(0, true), lit(3, true)],
    [lit(1, true), lit(4, true)],
    [lit(2, true), lit(5, true)],
  ])
  for watched in [false, true] {
    let initial = if watched {
      start(original)
    } else {
      start_scanning(original)
    }
    let first = incremental_answer(initial, original, 6).unwrap()
    assert_eq(first.level, @oracle.nat(3))
    let clause = @oracle.chain([lit(0, false)])
    let augmented = @core.append(original, @core.Cons(clause, @core.Nil))
    let next = incremental_answer(add_clause(first, clause), augmented, 6).unwrap()
    assert_true(@oracle.int_of_nat(next.statistics.nonchronological) > 0)
    let old_steps = next.proof_rev
    let with_empty = add_clause(next, @core.Nil)
    assert_eq(with_empty.proof_rev, old_steps)
    match incremental_finish(with_empty) {
      Unsatisfiable(proof) => {
        assert_true(
          check_refutation(
            @core.append(augmented, @core.Cons(@core.Nil, @core.Nil)),
            proof,
          ),
        )
        assert_false(check_refutation(augmented, proof))
      }
      _ => fail("an empty added axiom makes the augmented input unsatisfiable")
    }
  }
}
