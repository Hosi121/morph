///|
// Independent review: native signed-literal truth tables and fixed-point RUP.
// The oracle never calls the solver, normalization, propagation or SAT checker.
fn review_nat(value : Int32) -> @core.Nat {
  for left = value, result = @core.Zero; left > 0; {
    continue left - 1, @core.Succ(result)
  } nobreak {
    result
  }
}

///|
fn review_nat_int(value : @core.Nat) -> Int32 {
  for rest = value, result = 0 {
    match rest {
      Zero => break result
      Succ(tail) => continue tail, result + 1
    }
  }
}

///|
fn review_literal(token : Int32, ids : Array[Int32]) -> @sat.Literal {
  let index = if token > 0 { token - 1 } else { -token - 1 }
  { variable: review_nat(ids[index]), positive: token > 0, }
}

///|
fn review_cnf(data : Array[Array[Int32]], ids : Array[Int32]) -> @sat.Cnf {
  @oracle.chain(
    data.map(fn(row) {
      @oracle.chain(row.map(fn(token) { review_literal(token, ids) }))
    }),
  )
}

///|
fn review_truth(data : Array[Array[Int32]], variables : Int32) -> Bool {
  for mask in 0..<(1 << variables) {
    if data.all(fn(row) {
        row.any(fn(token) {
          let index = if token > 0 { token - 1 } else { -token - 1 }
          ((mask & (1 << index)) != 0) == (token > 0)
        })
      }) {
      return true
    }
  }
  false
}

///|
fn review_token(literal : @sat.Literal, ids : Array[Int32]) -> Int32 {
  let variable = review_nat_int(literal.variable)
  for index in 0..<ids.length() {
    if variable == ids[index] {
      return if literal.positive { index + 1 } else { -index - 1 }
    }
  }
  abort("review model/proof contains an unknown variable")
}

///|
fn review_model(
  data : Array[Array[Int32]],
  ids : Array[Int32],
  model : @sat.Model,
) -> Bool {
  let tokens = @oracle.array(model).map(fn(literal) {
    review_token(literal, ids)
  })
  tokens.all(fn(token) { !tokens.contains(-token) }) &&
  data.all(fn(row) { row.any(fn(token) { tokens.contains(token) }) })
}

///|
fn review_rup_add(db : Array[Array[Int32]], clause : Array[Int32]) -> Bool {
  let mut maximum = 0
  for row in db {
    for token in row {
      let index = if token > 0 { token } else { -token }
      maximum = maximum.max(index)
    }
  }
  for token in clause {
    maximum = maximum.max(if token > 0 { token } else { -token })
  }
  // Zero means unknown; positive/negative one means true/false.
  let assigned = Array::make(maximum + 1, 0)
  for token in clause {
    let index = if token > 0 { token } else { -token }
    let denied = if token > 0 { -1 } else { 1 }
    if assigned[index] == -denied {
      return true
    }
    assigned[index] = denied
  }
  for ;; {
    let mut changed = false
    for row in db {
      let pending : Array[Int32] = []
      let mut satisfied = false
      for token in row {
        let index = if token > 0 { token } else { -token }
        let sign = if token > 0 { 1 } else { -1 }
        if assigned[index] == sign {
          satisfied = true
        } else if assigned[index] == 0 && !pending.contains(token) {
          pending.push(token)
        }
      }
      if !satisfied {
        if pending.is_empty() {
          return true
        }
        if pending.length() == 1 {
          let token = pending[0]
          let index = if token > 0 { token } else { -token }
          assigned[index] = if token > 0 { 1 } else { -1 }
          changed = true
          break
        }
      }
    }
    if !changed {
      break false
    }
  }
}

///|
fn review_rup(data : Array[Array[Int32]], steps : Array[Array[Int32]]) -> Bool {
  if steps.is_empty() || !steps[steps.length() - 1].is_empty() {
    return false
  }
  let db = data.copy()
  for clause in steps {
    if !review_rup_add(db, clause) {
      return false
    }
    db.push(clause)
  }
  true
}

///|
fn review_proof(
  data : Array[Array[Int32]],
  ids : Array[Int32],
  steps : Array[Array[Int32]],
) -> Unit raise {
  let expected = review_rup(data, steps)
  assert_eq(
    check_refutation(review_cnf(data, ids), Rup(review_cnf(steps, ids))),
    expected,
  )
  if expected {
    assert_false(review_truth(data, ids.length()))
  }
}

///|
fn review_validate(
  data : Array[Array[Int32]],
  ids : Array[Int32],
) -> Unit raise {
  let expected = review_truth(data, ids.length())
  let input = review_cnf(data, ids)
  match run(start(input), review_nat(500)) {
    Satisfiable(model) => {
      assert_true(expected)
      assert_true(review_model(data, ids, model))
    }
    Unsatisfiable(Rup(steps) as proof) => {
      assert_false(expected)
      assert_true(check_refutation(input, proof))
      let raw = @oracle.array(steps).map(fn(row) {
        @oracle.array(row).map(fn(literal) { review_token(literal, ids) })
      })
      assert_true(review_rup(data, raw))
    }
    Paused(_) =>
      fail("independent review exhausted the bounded transition budget")
    InvariantViolation =>
      fail("independent review found a CDCL invariant violation")
  }
}

///|
test "review: all triples of ordered two-literal clauses include duplicates and tautologies" {
  let clauses : Array[Array[Int32]] = [[], [1], [-1], [2], [-2]]
  for left in [1, -1, 2, -2] {
    for right in [1, -1, 2, -2] {
      clauses.push([left, right])
    }
  }
  for a in clauses {
    for b in clauses {
      for c in clauses {
        review_validate([a, b, c], [0, 1])
      }
    }
  }
}

///|
test "review: deterministic five-variable formulas preserve repeated literal and clause semantics" {
  let mut state = 17371
  for family in 0..<600 {
    let clauses : Array[Array[Int32]] = []
    for index in 0..<(5 + family % 14) {
      let row = []
      for _ in 0..<(1 + (index + family) % 7) {
        state = (state * 109 + 89) % 65521
        let variable = 1 + state % 5
        state = (state * 109 + 89) % 65521
        row.push(if state % 2 == 0 { variable } else { -variable })
      }
      clauses.push(row)
      if index % 4 == 0 {
        clauses.push(row.copy())
      }
    }
    review_validate(clauses, [0, 1, 2, 3, 4])
  }
}

///|
test "review: exhaustive short RUP traces agree with an independent fixed-point checker" {
  let additions : Array[Array[Int32]] = [
    [],
    [1],
    [-1],
    [2],
    [-2],
    [1, 1],
    [1, -1],
    [1, 2],
    [-1, 2],
    [3],
    [-3],
  ]
  let cube : Array[Array[Int32]] = [[1, 2], [1, -2], [-1, 2], [-1, -2]]
  for subset in 0..<16 {
    let input = [
      for index in 0..<4 if (subset & (1 << index)) != 0 => cube[index]
    ]
    for a in additions {
      for b in additions {
        review_proof(input, [0, 1, 17], [a, b, []])
      }
    }
  }
  for
    input in [
      [],
      [[]],
      [[1, 1], [-1, -1]],
      [[1, -1]],
      [[1], [-1, 2], [-2]],
      [[1, 1, 2], [-1, 2], [-2]],
    ] {
    for a in additions {
      for b in additions {
        review_proof(input, [0, 1, 17], [a, b, []])
      }
    }
  }
}

///|
fn review_cube(variables : Int32) -> Array[Array[Int32]] {
  [
    for mask in 0..<(1 << variables) => {
      [
        for variable in 0..<variables => {
          if (mask & (1 << variable)) == 0 {
            variable + 1
          } else {
            -variable - 1
          }
        }
      ]
    }
  ]
}

///|
test "review: learned proof reorder deletion sign reversal and terminator attacks obey RUP rules" {
  let input = review_cube(4)
  let ids = [0, 1, 2, 3, 29]
  let proof = match run(start(review_cnf(input, ids)), review_nat(500)) {
    Unsatisfiable(Rup(steps)) =>
      @oracle.array(steps).map(fn(row) {
        @oracle.array(row).map(fn(literal) { review_token(literal, ids) })
      })
    _ => abort("review cube must have a learned refutation")
  }
  assert_true(proof.length() > 2)
  review_proof(input, ids, proof)
  review_proof(input, ids, [])
  review_proof(input, ids, [[]])
  review_proof(input, ids, proof[:proof.length() - 1].to_owned())
  let reversed = proof.rev()
  review_proof(input, ids, reversed)
  let reversed_literals = proof.map(fn(row) { row.rev() })
  assert_true(review_rup(input, reversed_literals))
  review_proof(input, ids, reversed_literals)
  let duplicate_literals = proof.map(fn(row) {
    row.map(fn(token) { [token, token] }).flatten()
  })
  assert_true(review_rup(input, duplicate_literals))
  review_proof(input, ids, duplicate_literals)
  for dropped in 0..<proof.length() {
    review_proof(
      input,
      ids,
      [
        for index in 0..<proof.length() if index != dropped => proof[index]
      ],
    )
  }
  for index in 0..<(proof.length() - 1) {
    let reordered = proof.copy()
    let other = (index + 1) % (proof.length() - 1)
    reordered[index] = proof[other]
    reordered[other] = proof[index]
    review_proof(input, ids, reordered)
    for literal in 0..<proof[index].length() {
      let mutated = proof.copy()
      let clause = proof[index].copy()
      clause[literal] = -clause[literal]
      mutated[index] = clause
      review_proof(input, ids, mutated)
    }
  }
  let trailing_nonempty = proof.copy()
  trailing_nonempty.push([5, -5])
  assert_false(review_rup(input, trailing_nonempty))
  review_proof(input, ids, trailing_nonempty)
  let repeated_empty = proof.copy()
  repeated_empty.push([])
  assert_true(review_rup(input, repeated_empty))
  review_proof(input, ids, repeated_empty)
}

///|
test "review: every resumption boundary preserves terminal results statistics and snapshots" {
  let cases : Array[Array[Array[Int32]]] = [
    [],
    [[]],
    [[1], [-1]],
    [[1, 2], [-1, 2], [1, -2]],
    review_cube(3),
    review_cube(4),
    [[1, 4], [2, 5], [3, 6], [-1, -3, 7], [-1, -3, -7]],
  ]
  for input in cases {
    let ids = [0, 1, 2, 3, 4, 5, 6]
    let initial = start(review_cnf(input, ids))
    let (full, final_stats) = run_measured(initial, review_nat(500))
    assert_false(full is Paused(_) || full is InvariantViolation)
    let transitions = review_nat_int(final_stats.transitions)
    assert_true(transitions > 0)
    for boundary in 0..<=transitions {
      let (prefix, prefix_stats) = run_measured(initial, review_nat(boundary))
      match prefix {
        Paused(state) => {
          assert_eq(prefix_stats, statistics(state))
          assert_eq(
            run_measured(state, @core.Zero),
            (Paused(state), prefix_stats),
          )
          assert_eq(
            run_measured(state, review_nat(transitions - boundary)),
            (full, final_stats),
          )
          assert_eq(
            run_measured(initial, review_nat(boundary)),
            (prefix, prefix_stats),
          )
        }
        terminal => assert_eq((terminal, prefix_stats), (full, final_stats))
      }
    }
    assert_eq(run_measured(initial, review_nat(500)), (full, final_stats))
  }
}

///|
test "review: sparse identifiers are labels and never truth-table bit positions" {
  let ids = [0, 1024, 4096, 8191]
  review_validate([[1, 2], [-1, 3], [-3, 4], [2, 2], [-2, 2]], ids)
  review_validate(review_cube(3), ids)
  review_validate([[1], [-1, 4], [-4]], ids)
  review_proof([[1], [-1, 4], [-4]], ids, [[]])
}

///|
test "review: a single unit with label 65535 starts without recursive conversion overflow" {
  review_validate([[1]], [65535])
}
