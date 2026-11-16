///|
fn variables(cnf : @sat.Cnf) -> Lits {
  @core.fold_left(cnf, Nil, fn(known, clause) {
    @core.fold_left(clause, known, fn(known, literal) {
      let value = atom(literal)
      match @core.any(known, fn(other) { same_key(other, value) }) {
        true => known
        false => Cons(value, known)
      }
    })
  })
}

///|
fn start_preparation_mode(
  cnf : @sat.Cnf,
  indexed : Bool,
  watched : Bool,
) -> Search {
  let search = if indexed {
    start_prepared(cnf)
  } else {
    Search::{
      database: database(cnf),
      variables: variables(cnf),
      watch: None,
      trail: Nil,
      level: Zero,
      proof_rev: Nil,
      statistics: empty_statistics(),
    }
  }
  if watched {
    { ..search, watch: Some(watch_start(search.database)), }
  } else {
    search
  }
}

///|
fn preparation_query(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  indexed : Bool,
) -> Bool {
  match run(start_preparation_mode(cnf, indexed, true), budget) {
    Satisfiable(model) => @sat.check_model(cnf, model)
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      match @ruplog.build_prepared(input, proof) {
        None => false
        Some(logged) => @ruplog.check_prepared(input, logged)
      }
    }
    _ => false
  }
}

///|
test "indexed preparation preserves every small initial search and first occurrence polarity" {
  for encoded in 0..<19683 {
    let formula : @sat.Cnf = @oracle.chain([
      ternary_clause(encoded % 27, 3),
      ternary_clause(encoded / 27 % 27, 3),
      ternary_clause(encoded / 729, 3),
    ])
    for watched in [false, true] {
      assert_eq(
        start_preparation_mode(formula, false, watched),
        start_preparation_mode(formula, true, watched),
      )
    }
  }
  let examples = [
    cnf([]),
    cnf([[]]),
    cnf([
      [lit(2, false), lit(2, true), lit(5, false)],
      [lit(0, true), lit(0, true)],
    ]),
    cnf([
      [lit(5, false), lit(5, true), lit(2, false)],
      [lit(5, true), lit(2, true)],
      [],
    ]),
    cnf([
      [lit(1, false), lit(0, true), lit(1, false)],
      [lit(0, false), lit(2, true), lit(2, true)],
    ]),
  ]
  for formula in examples {
    for watched in [false, true] {
      let old = start_preparation_mode(formula, false, watched)
      let indexed = start_preparation_mode(formula, true, watched)
      assert_eq(old, indexed)
      assert_eq(
        run_measured(old, fuel(1000)),
        run_measured(indexed, fuel(1000)),
      )
    }
  }
}

///|
test "indexed preparation retains late tautology variables sparse IDs and twenty-thousand-clause stack safety" {
  let formulas = [
    cnf([[lit(65535, true)]]),
    cnf([[lit(0, false), lit(0, true), lit(65535, false)]]),
    cnf([ for _ in 0..<20000 => [lit(0, true)] ]),
    cnf([ for _ in 0..<20000 => [lit(0, true), lit(1, true)] ]),
  ]
  for formula in formulas {
    for watched in [false, true] {
      let old = start_preparation_mode(formula, false, watched)
      let indexed = start_preparation_mode(formula, true, watched)
      let old_variables = @oracle.array(old.variables).map(fn(value) {
        (
          @oracle.int_of_nat(value.source),
          value.positive,
          @oracle.int_of_binary(value.key),
        )
      })
      let new_variables = @oracle.array(indexed.variables).map(fn(value) {
        (
          @oracle.int_of_nat(value.source),
          value.positive,
          @oracle.int_of_binary(value.key),
        )
      })
      assert_eq(old_variables, new_variables)
      let (old_result, old_stats) = run_measured(old, fuel(10))
      let (new_result, new_stats) = run_measured(indexed, fuel(10))
      assert_eq(old_stats, new_stats)
      for outcome in [old_result, new_result] {
        match outcome {
          Satisfiable(model) => assert_true(@sat.check_model(formula, model))
          _ => fail("prepared sparse and repeated formulas must be satisfiable")
        }
      }
    }
  }
}

///|
fn preparation_chain(size : Int32) -> @sat.Cnf {
  let rows = [[lit(0, true)]]
  for variable in 0..<size {
    rows.push([lit(variable, false), lit(variable + 1, true)])
  }
  rows.push([lit(size, false)])
  cnf(rows)
}

///|
fn preparation_work(formula : @sat.Cnf) -> (Int32, Int32, Int32) {
  let mut known : Lits = Nil
  let mut seen : Index[Bool] = Empty
  let mut literal_count = 0
  let mut comparisons = 0
  let mut branches = 0
  fn scan(values : Lits, value : Atom) -> (Bool, Int32) {
    match values {
      Nil => (false, 0)
      Cons(other, rest) =>
        if same_key(other, value) {
          (true, 1)
        } else {
          let (found, count) = scan(rest, value)
          (found, count + 1)
        }
    }
  }
  fn query(index : Index[Bool], key : @core.Chain[Bool]) -> (Bool?, Int32) {
    match (index, key) {
      (Empty, _) => (None, 0)
      (Branch(value, _, _), Nil) => (value, 1)
      (Branch(_, left, _), Cons(false, rest)) => {
        let (found, count) = query(left, rest)
        (found, count + 1)
      }
      (Branch(_, _, right), Cons(true, rest)) => {
        let (found, count) = query(right, rest)
        (found, count + 1)
      }
    }
  }
  for clause in @oracle.array(formula) {
    for source in @oracle.array(clause) {
      let value = atom(source)
      let (found, count) = scan(known, value)
      let (cached, visits) = query(seen, @binary.bits(value.key))
      literal_count += 1
      comparisons += count
      branches += visits
      if !found {
        known = Cons(value, known)
        seen = index_put(seen, @binary.bits(value.key), true)
      }
      ignore(cached)
    }
  }
  (literal_count, comparisons, branches)
}

///|
test "same executable startup and sparse complete-query preparation comparison" (
  b : @bench.T,
) {
  let miter = @circuit.cnf(miter_formula(64))
  let chain = preparation_chain(256)
  let sparse = cnf([[lit(65535, true)]])
  let repeated = cnf([ for _ in 0..<20000 => [lit(0, true), lit(1, true)] ])
  let budget = fuel(200000)
  assert_eq(
    start_preparation_mode(miter, false, true),
    start_preparation_mode(miter, true, true),
  )
  assert_eq(
    start_preparation_mode(chain, false, true),
    start_preparation_mode(chain, true, true),
  )
  for formula in [miter, chain, sparse, repeated] {
    assert_true(preparation_query(formula, budget, false))
    assert_true(preparation_query(formula, budget, true))
  }
  let (literals, comparisons, branches) = preparation_work(miter)
  println(
    "preparation-work width=64 literals=\{literals} old-variable-key-comparisons=\{comparisons} indexed-trie-branches=\{branches}",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(miter, false, true)) },
    name="sixty-four-bit startup separate passes",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(miter, true, true)) },
    name="sixty-four-bit startup indexed single conversion",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(miter, true, true)) },
    name="sixty-four-bit startup indexed repeated control",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(miter, false, true)) },
    name="sixty-four-bit startup separate repeated control",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(chain, false, true)) },
    name="chain256 startup separate passes",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(chain, true, true)) },
    name="chain256 startup indexed single conversion",
  )
  b.bench(
    fn() { b.keep(preparation_query(sparse, budget, false)) },
    name="sparse65535 complete query separate passes",
  )
  b.bench(
    fn() { b.keep(preparation_query(sparse, budget, true)) },
    name="sparse65535 complete query indexed single conversion",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(repeated, false, true)) },
    name="repeated20000 startup separate passes",
  )
  b.bench(
    fn() { b.keep(start_preparation_mode(repeated, true, true)) },
    name="repeated20000 startup indexed single conversion",
  )
}

///|
test "paired complete queries retain proof statistics and all paused preparation states" (
  b : @bench.T,
) {
  let formula = @circuit.cnf(miter_formula(64))
  let budget = fuel(200000)
  let baseline = run_measured(
    start_preparation_mode(formula, false, true),
    budget,
  )
  assert_eq(
    baseline,
    run_measured(start_preparation_mode(formula, true, true), budget),
  )
  let (outcome, _) = baseline
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(formula)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("preparation miter must be refuted")
  }
  for pair in 0..<20 {
    let separate_first = pair % 2 == 0
    let started = @bench.monotonic_clock_start()
    let first = preparation_query(formula, budget, !separate_first)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = preparation_query(formula, budget, separate_first)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (separate, indexed) = if separate_first {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "preparation-pair index=\{pair} separate_first=\{separate_first} separate_ms=\{separate/1000.0} indexed_ms=\{indexed/1000.0} ratio=\{separate/indexed}",
    )
  }
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "preparation alternatives preserve every paused state" {
  for formula in [pigeonhole(4, 3), @circuit.cnf(miter_formula(4))] {
    for watched in [false, true] {
      for baseline = start_preparation_mode(formula, false, watched), indexed = start_preparation_mode(
              formula, true, watched,
            ), count = 0 {
        assert_true(count < 10000)
        assert_eq(baseline, indexed)
        let old_result = run_measured(baseline, fuel(1))
        let new_result = run_measured(indexed, fuel(1))
        assert_eq(old_result, new_result)
        let (status, _) = old_result
        let (other, _) = new_result
        match (status, other) {
          (Paused(next), Paused(other)) => continue next, other, count + 1
          (Unsatisfiable(proof), _) => {
            assert_true(check_refutation(formula, proof))
            break
          }
          _ => fail("preparation pause comparison must end in UNSAT")
        }
      }
    }
  }
}

///|
fn preparation_batch(
  formulas : Array[@sat.Cnf],
  budget : @core.Nat,
  indexed : Bool,
) -> Bool {
  for formula in formulas {
    if !preparation_query(formula, budget, indexed) {
      return false
    }
  }
  true
}

///|
test "preparation complete queries include pigeonhole and deterministic six-variable cohort" (
  b : @bench.T,
) {
  let pigeon = pigeonhole(6, 5)
  let budget = fuel(200000)
  let mut seed = 31415
  let cohort = []
  for _ in 0..<1000 {
    let clauses = []
    for _ in 0..<24 {
      let values = []
      for _ in 0..<3 {
        seed = (seed * 61 + 17) % 65521
        let variable = seed % 6
        seed = (seed * 61 + 17) % 65521
        values.push(lit(variable, seed % 2 == 1))
      }
      clauses.push(values)
    }
    let formula = cnf(clauses)
    cohort.push(formula)
    assert_eq(
      run_measured(start_preparation_mode(formula, false, true), budget),
      run_measured(start_preparation_mode(formula, true, true), budget),
    )
  }
  for formula in [pigeon] {
    assert_eq(
      run_measured(start_preparation_mode(formula, false, true), budget),
      run_measured(start_preparation_mode(formula, true, true), budget),
    )
  }
  assert_true(preparation_batch(cohort, budget, false))
  assert_true(preparation_batch(cohort, budget, true))
  b.bench(
    fn() { b.keep(preparation_query(pigeon, budget, false)) },
    name="pigeonhole six into five separate query",
  )
  b.bench(
    fn() { b.keep(preparation_query(pigeon, budget, true)) },
    name="pigeonhole six into five indexed query",
  )
  b.bench(
    fn() { b.keep(preparation_batch(cohort, budget, false)) },
    name="thousand six-variable queries separate",
  )
  b.bench(
    fn() { b.keep(preparation_batch(cohort, budget, true)) },
    name="thousand six-variable queries indexed",
  )
}
