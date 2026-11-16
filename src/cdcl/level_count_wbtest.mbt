///|
fn cutoff_after_one_level(
  clause : Lits,
  lookup : (Atom) -> Assignment?,
  level : @core.Nat,
) -> Count {
  match clause {
    Nil => Once
    Cons(literal, rest) =>
      match lookup(literal) {
        None => cutoff_after_one_level(rest, lookup, level)
        Some(entry) =>
          match @core.compare(entry.level, level) {
            Equal => Several
            _ => cutoff_after_one_level(rest, lookup, level)
          }
      }
  }
}

///|
fn cutoff_at_level(
  clause : Lits,
  lookup : (Atom) -> Assignment?,
  level : @core.Nat,
) -> Count {
  match clause {
    Nil => Absent
    Cons(literal, rest) =>
      match lookup(literal) {
        None => cutoff_at_level(rest, lookup, level)
        Some(entry) =>
          match @core.compare(entry.level, level) {
            Equal => cutoff_after_one_level(rest, lookup, level)
            _ => cutoff_at_level(rest, lookup, level)
          }
      }
  }
}

// Full clause counting frozen before the two-match cutoff experiment.

///|
fn full_level_count(
  clause : Lits,
  lookup : (Atom) -> Assignment?,
  level : @core.Nat,
) -> Count {
  match clause {
    Nil => Absent
    Cons(literal, rest) =>
      match lookup(literal) {
        None => full_level_count(rest, lookup, level)
        Some(entry) =>
          match @core.compare(entry.level, level) {
            Equal =>
              match full_level_count(rest, lookup, level) {
                Absent => Once
                Once | Several => Several
              }
            _ => full_level_count(rest, lookup, level)
          }
      }
  }
}

///|
fn level_count_tag(count : Count) -> Int32 {
  match count {
    Absent => 0
    Once => 1
    Several => 2
  }
}

///|
test "two-match level cutoff agrees with full counting and numeric partial-assignment oracle" {
  for encoded in 0..<27 {
    let clause = normalize(ternary_clause(encoded, 3)).unwrap()
    for assignment in 0..<64 {
      let mut values = Empty
      let mut digits = assignment
      let levels = []
      for variable in 0..<3 {
        let digit = digits % 4
        digits /= 4
        levels.push(digit)
        if digit != 0 {
          let literal = atom(lit(variable, true))
          values = index_put(values, @binary.bits(literal.key), {
            literal,
            level: @oracle.nat(digit - 1),
            reason: None,
          })
        }
      }
      let lookup = fn(literal : Atom) {
        index_get(values, @binary.bits(literal.key))
      }
      for level in 0..<4 {
        let hits = @oracle.array(clause)
          .filter(fn(literal) {
            let digit = levels[@oracle.int_of_nat(literal.source)]
            digit != 0 && digit - 1 == level
          })
          .length()
        let expected = if hits == 0 { 0 } else if hits == 1 { 1 } else { 2 }
        assert_eq(
          level_count_tag(full_level_count(clause, lookup, @oracle.nat(level))),
          expected,
        )
        assert_eq(
          level_count_tag(cutoff_at_level(clause, lookup, @oracle.nat(level))),
          expected,
        )
      }
    }
  }
}

///|
priv struct LevelCountCase {
  clause : Lits
  lookup : (Atom) -> Assignment?
  level : @core.Nat
}

///|
fn collect_level_cases(
  clause : Lits,
  trail : Trail,
  lookup : (Atom) -> Assignment?,
  level : @core.Nat,
  cases : Array[LevelCountCase],
) -> Lits? {
  fn visit(clause : Lits, remaining : Trail) -> Lits? {
    cases.push(LevelCountCase::{ clause, lookup, level, })
    match full_level_count(clause, lookup, level) {
      Absent => None
      Once => Some(clause)
      Several =>
        match remaining {
          Nil => None
          Cons(entry, rest) =>
            match
              @core.compare(entry.level, level) is Equal &&
              contains(clause, opposite(entry.literal)) {
              false => visit(clause, rest)
              true =>
                match entry.reason {
                  None => None
                  Some(reason) =>
                    visit(resolve(clause, reason, entry.literal), rest)
                }
            }
        }
    }
  }
  visit(clause, trail)
}

///|
fn collect_level_work(
  initial : Search,
  cases : Array[LevelCountCase],
) -> (Status, Statistics) raise {
  for state = initial, remaining = 200000; remaining > 0; {
    let (inspection, watched) = watch_inspect(
      state.watch.unwrap(),
      state.database,
    )
    match inspection {
      Contradiction(conflict) => {
        let lookup = fn(literal : Atom) {
          index_get(watched.values, @binary.bits(literal.key))
        }
        let level = highest_level(conflict, lookup)
        match level {
          Zero => ()
          Succ(_) => {
            let old = collect_level_cases(
              conflict,
              state.trail,
              lookup,
              level,
              cases,
            )
            assert_eq(old, analyze(conflict, state.trail, lookup, level))
          }
        }
      }
      _ => ()
    }
    let result = transition({ ..state, watch: Some(watched), }, inspection)
    let (outcome, _) = result
    match outcome {
      Paused(next) => continue next, remaining - 1
      _ => break result
    }
  } nobreak {
    fail("level-count collector exhausted fuel")
  }
}

///|
fn level_work_checksum(cases : Array[LevelCountCase], cutoff : Bool) -> Int32 {
  let mut checksum = 0
  for item in cases {
    let count = if cutoff {
      cutoff_at_level(item.clause, item.lookup, item.level)
    } else {
      full_level_count(item.clause, item.lookup, item.level)
    }
    checksum += level_count_tag(count)
  }
  checksum
}

///|
test "actual sixty-four-bit analysis clauses compare full and two-match level counting" (
  b : @bench.T,
) {
  let cnf = @circuit.cnf(miter_formula(64))
  let initial = start(cnf)
  let budget = fuel(200000)
  let cases = []
  let collected = collect_level_work(initial, cases)
  assert_eq(collected, run_measured(initial, budget))
  let (outcome, _) = collected
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("level count miter must be refuted")
  }
  let mut original_queries = 0
  let mut cutoff_queries = 0
  for item in cases {
    let lookup = fn(literal : Atom) {
      original_queries += 1
      (item.lookup)(literal)
    }
    let original = full_level_count(item.clause, lookup, item.level)
    let lookup = fn(literal : Atom) {
      cutoff_queries += 1
      (item.lookup)(literal)
    }
    let cutoff = cutoff_at_level(item.clause, lookup, item.level)
    assert_eq(level_count_tag(original), level_count_tag(cutoff))
  }
  println(
    "level-count cases=\{cases.length()} original_queries=\{original_queries} cutoff_queries=\{cutoff_queries}",
  )
  assert_eq(level_work_checksum(cases, false), level_work_checksum(cases, true))
  b.bench(
    fn() { b.keep(level_work_checksum(cases, false)) },
    name="full level counts first control",
  )
  b.bench(
    fn() { b.keep(level_work_checksum(cases, true)) },
    name="two-match cutoff level counts",
  )
  b.bench(
    fn() { b.keep(level_work_checksum(cases, true)) },
    name="two-match cutoff level counts repeated control",
  )
  b.bench(
    fn() { b.keep(level_work_checksum(cases, false)) },
    name="full level counts repeated control",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}
