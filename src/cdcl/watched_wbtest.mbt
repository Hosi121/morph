///|
fn[A] index_entries(index : Index[A]) -> @core.Chain[A] {
  match index {
    Empty => Nil
    Branch(None, left, right) =>
      @core.append(index_entries(left), index_entries(right))
    Branch(Some(value), left, right) =>
      Cons(value, @core.append(index_entries(left), index_entries(right)))
  }
}

///|
fn assert_trail(trail : Trail) -> Unit raise {
  match trail {
    Nil => ()
    Cons(entry, rest) => {
      assert_true(assignment(rest, entry.literal) is None)
      match entry.reason {
        None => assert_false(@core.is_zero(entry.level))
        Some(reason) =>
          match inspect_clause(reason, rest) {
            Unit(literal) => assert_true(same(literal, entry.literal))
            _ =>
              fail(
                "stored propagation reason was not unit before its assignment",
              )
          }
      }
      assert_trail(rest)
    }
  }
}

///|
fn assert_watch(search : Search) -> Unit raise {
  assert_trail(search.trail)
  match search.watch {
    None => fail("watch invariant test requires the watched engine")
    Some(state) => {
      let clauses = @oracle.array(index_entries(state.clauses))
      let mut watch_count = 0
      for clause in clauses {
        assert_true(contains(clause.literals, clause.first))
        assert_eq(
          @oracle.array(bucket(state, clause.first))
          .filter(fn(id) { id == clause.id })
          .length(),
          1,
        )
        watch_count += 1
        match clause.second {
          None => assert_eq(@oracle.array(clause.literals).length(), 1)
          Some(other) => {
            assert_false(same_key(clause.first, other))
            assert_true(contains(clause.literals, other))
            assert_eq(
              @oracle.array(bucket(state, other))
              .filter(fn(id) { id == clause.id })
              .length(),
              1,
            )
            watch_count += 1
          }
        }
      }
      let buckets = @oracle.array(index_entries(state.buckets))
      assert_eq(
        buckets.fold(init=0, fn(total, ids) {
          total + @oracle.array(ids).length()
        }),
        watch_count,
      )
      let entries = @oracle.array(index_entries(state.values))
      assert_eq(entries.length(), @oracle.array(search.trail).length())
      for entry in @oracle.array(search.trail) {
        assert_eq(
          index_get(state.values, @binary.bits(entry.literal.key)),
          Some(entry),
        )
      }
      assert_eq(
        clauses.length(),
        @oracle.array(search.database).length() -
        @oracle.array(search.database)
        .filter(fn(clause) { clause is Nil })
        .length(),
      )
    }
  }
}

///|
fn run_checked(formula : @sat.Cnf) -> Status raise {
  for state = start(formula), count = 0 {
    assert_true(count < 20000)
    assert_watch(state)
    match run(state, fuel(1)) {
      Paused(next) => continue next, count + 1
      InvariantViolation => fail("watched propagation invariant violated")
      outcome => break outcome
    }
  }
}

///|
test "persistent trie distinguishes prefixes zero and both polarities" {
  let zero = @binary.bits(@oracle.binary(0))
  let one = @binary.bits(@oracle.binary(1))
  let two = @binary.bits(@oracle.binary(2))
  let base : Index[Int32] = Empty
  let first = index_put(base, zero, 10)
  let second = index_put(first, one, 20)
  let third = index_put(second, two, 30)
  assert_eq(index_get(base, zero), None)
  assert_eq(index_get(first, zero), Some(10))
  assert_eq(index_get(first, one), None)
  assert_eq(index_get(third, zero), Some(10))
  assert_eq(index_get(third, one), Some(20))
  assert_eq(index_get(third, two), Some(30))
  let changed = index_put(third, one, 40)
  assert_eq(index_get(third, one), Some(20))
  assert_eq(index_get(changed, one), Some(40))
  let positive = atom(lit(0, true))
  let negative = atom(lit(0, false))
  let signed = index_put(
    index_put(base, watch_key(positive), 1),
    watch_key(negative),
    2,
  )
  assert_eq(index_get(signed, watch_key(positive)), Some(1))
  assert_eq(index_get(signed, watch_key(negative)), Some(2))
}

///|
test "watch membership assignment index and unit reasons survive learning and backjump" {
  for holes in 1..<=5 {
    let formula = pigeonhole(holes + 1, holes)
    match run_checked(formula) {
      Unsatisfiable(proof) => assert_true(check_refutation(formula, proof))
      _ => fail("checked pigeonhole run must be unsatisfiable")
    }
  }
}

///|
test "a thousand six-variable three-SAT instances preserve watches and agree with truth tables" {
  let mut state = 31415
  for _ in 0..<1000 {
    let clauses = []
    for _ in 0..<24 {
      let values = []
      for _ in 0..<3 {
        state = (state * 61 + 17) % 65521
        let variable = state % 6
        state = (state * 61 + 17) % 65521
        values.push(lit(variable, state % 2 == 1))
      }
      clauses.push(values)
    }
    let formula = cnf(clauses)
    validate(formula, 6)
    match run_checked(formula) {
      Satisfiable(model) => {
        assert_true(brute(formula, 6))
        assert_true(@sat.check_model(formula, model))
      }
      Unsatisfiable(proof) => {
        assert_false(brute(formula, 6))
        assert_true(check_refutation(formula, proof))
      }
      _ => fail("checked random run must terminate")
    }
  }
}
