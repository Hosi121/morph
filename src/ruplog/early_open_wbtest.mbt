// Complete clause evaluator and builder frozen from fbcefc1.

///|
/// Builder-only clause scan. The checking kernel has its own evaluator.
fn full_builder_clause(clause : Lits, values : Trie[Bool]) -> Status {
  match clause {
    Nil => Conflict
    Cons(value, tail) =>
      match get(values, @binary.bits(value.key)) {
        Some(assigned) =>
          match (assigned, value.source.positive) {
            (true, true) | (false, false) => Satisfied
            _ => full_builder_clause(tail, values)
          }
        None =>
          match full_builder_clause(tail, values) {
            Satisfied => Satisfied
            Conflict => Unit(value)
            Unit(_) | Open => Open
          }
      }
  }
}

///|
/// Only clauses containing a newly falsified literal enter the work queue.
/// Lists are enqueued as shared chunks rather than copied per occurrence.
fn full_occurrence_hints(
  database : Database,
  clause : Lits,
  occurrences : IdOccurrences,
) -> @core.Chain[@binary.Binary]? {
  fn propagate(work : IdWork) -> @core.Chain[@binary.Binary]? {
    match work.active {
      Nil =>
        match @core.dequeue(work.chunks) {
          None => None
          Some((active, chunks)) => propagate({ ..work, active, chunks, })
        }
      Cons(id, rest) => {
        let work = { ..work, active: rest, }
        match get(database.indexed, @binary.bits(id)) {
          None => None
          Some(Tautology) => propagate(work)
          Some(Terms(clause)) =>
            match full_builder_clause(clause, work.values) {
              Satisfied | Open => propagate(work)
              Conflict => Some(@core.reverse(Cons(id, work.hints_rev)))
              Unit(value) => {
                let work = id_assign(
                  work,
                  occurrences,
                  value.key,
                  value.source.positive,
                )
                propagate({ ..work, hints_rev: Cons(id, work.hints_rev), })
              }
            }
        }
      }
    }
  }
  match occurrences.empty {
    Some(id) => Some(Cons(id, Nil))
    None => {
      let initial = IdWork::{
        values: Empty,
        chunks: @core.queue(),
        active: Nil,
        hints_rev: Nil,
      }
      let work = @core.fold_left(clause, initial, fn(work, value) {
        id_assign(work, occurrences, value.key, !value.source.positive)
      })
      match id_seed(occurrences.units, work, occurrences) {
        Immediate(hints) => Some(hints)
        Ready(work) => propagate(work)
      }
    }
  }
}

///|
/// Enrich an existing RUP list without invoking SAT search. Source tautological
/// lemmas are omitted. Other clauses are sorted and deduplicated. An empty
/// clause is required exactly at the end.
fn full_build_using(
  input : Input,
  proof : @cdcl.Proof,
  occurrences : IdOccurrences?,
) -> Certificate? {
  fn visit(
    rest : @core.Chain[@sat.Clause],
    database : Database,
    reversed : @core.Chain[Step],
    occurrences : IdOccurrences?,
  ) -> Certificate? {
    match rest {
      Nil => None
      Cons(source, tail) =>
        match normalize(source) {
          Tautology => visit(tail, database, reversed, occurrences)
          Terms(clause) => {
            let last_step = match (clause, tail) {
              (Nil, Nil) => Some(true)
              (Nil, Cons(_, _)) | (Cons(_, _), Nil) => None
              _ => Some(false)
            }
            match last_step {
              None => None
              Some(last_step) =>
                match
                  (match occurrences {
                    None => builder_hints(database, clause)
                    Some(indexed) =>
                      full_occurrence_hints(database, clause, indexed)
                  }) {
                  None => None
                  Some(hints) => {
                    let step = Step::{
                      id: database.next,
                      clause: @core.map(clause, fn(value) { value.source }),
                      hints,
                    }
                    match last_step {
                      true =>
                        Some({ steps: @core.reverse(Cons(step, reversed)), })
                      false => {
                        let occurrences = match occurrences {
                          None => None
                          Some(indexed) =>
                            Some(
                              id_occurrence_add(indexed, step.id, Terms(clause)),
                            )
                        }
                        visit(
                          tail,
                          add(database, step.id, Terms(clause)),
                          Cons(step, reversed),
                          occurrences,
                        )
                      }
                    }
                  }
                }
            }
          }
        }
    }
  }
  match proof {
    Rup(steps) => visit(steps, input.database, Nil, occurrences)
  }
}

///|
fn full_build_prepared(input : Input, proof : @cdcl.Proof) -> Certificate? {
  full_build_using(input, proof, Some(id_occurrence_prepare(input.database)))
}

///|
fn builder_action(status : Status) -> @sat.Clause? {
  match status {
    Open | Satisfied => None
    Conflict => Some(Nil)
    Unit(value) => Some(Cons(value.source, Nil))
  }
}

///|
test "second unassigned builder cutoff preserves all unit and conflict actions" {
  for encoded in 0..<27 {
    let clause = match normalize(ternary(encoded)) {
      Terms(values) => values
      Tautology => fail("ternary clause cannot be tautological")
    }
    for assignment in 0..<27 {
      let mut values = Empty
      let mut digits = assignment
      for variable in 0..<3 {
        let digit = digits % 3
        digits /= 3
        if digit != 0 {
          values = put(
            values,
            @binary.bits(@oracle.binary(variable)),
            digit == 1,
          )
        }
      }
      assert_eq(
        builder_action(full_builder_clause(clause, values)),
        builder_action(builder_clause(clause, values)),
      )
    }
  }
  for a in 0..<27 {
    for b in 0..<27 {
      let cnf = @oracle.chain([ternary(a), ternary(b)])
      let input = prepare(cnf)
      for candidate in 0..<27 {
        let proof = @cdcl.Rup(@oracle.chain([ternary(candidate), @core.Nil]))
        let old = full_build_prepared(input, proof)
        assert_eq(old, id_build_prepared(input, proof))
        assert_eq(old, build_prepared(input, proof))
        match old {
          None => ()
          Some(logged) => assert_true(check_prepared(input, logged))
        }
      }
    }
  }
}

///|
test "builder cutoff cost with and without direct clause references" (
  b : @bench.T,
) {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let old = full_build_prepared(input, proof).unwrap()
  assert_eq(old, id_build_prepared(input, proof).unwrap())
  assert_eq(old, build_prepared(input, proof).unwrap())
  assert_true(check_prepared(input, old))
  b.bench(
    fn() { b.keep(full_build_prepared(input, proof)) },
    name="full evaluator clause IDs first control",
  )
  b.bench(
    fn() { b.keep(id_build_prepared(input, proof)) },
    name="second unassigned cutoff clause IDs",
  )
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
    name="second unassigned cutoff direct references",
  )
  b.bench(
    fn() { b.keep(id_build_prepared(input, proof)) },
    name="second unassigned cutoff clause IDs repeated control",
  )
  b.bench(
    fn() { b.keep(full_build_prepared(input, proof)) },
    name="full evaluator clause IDs repeated control",
  )
  b.bench(
    fn() { b.keep(check_prepared(input, old)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
priv enum BuilderTrial {
  CompleteIds
  CutoffIds
  CutoffReferences
}

///|
fn builder_trial(
  input : Input,
  proof : @cdcl.Proof,
  trial : BuilderTrial,
) -> Certificate? {
  match trial {
    CompleteIds => full_build_prepared(input, proof)
    CutoffIds => id_build_prepared(input, proof)
    CutoffReferences => build_prepared(input, proof)
  }
}

///|
fn cutoff_query(
  cnf : @sat.Cnf,
  budget : @core.Nat,
  trial : BuilderTrial,
) -> Bool {
  match @cdcl.run(@cdcl.start(cnf), budget) {
    Unsatisfiable(proof) => {
      let input = prepare(cnf)
      match builder_trial(input, proof, trial) {
        None => false
        Some(logged) => check_prepared(input, logged)
      }
    }
    Satisfiable(model) => @sat.check_model(cnf, model)
    _ => false
  }
}

///|
fn cutoff_pairs(
  trial : BuilderTrial,
  direct : Bool,
  b : @bench.T,
) -> Unit raise {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let old = full_build_prepared(input, proof).unwrap()
  assert_eq(old, builder_trial(input, proof, trial).unwrap())
  assert_true(check_prepared(input, old))
  let budget = @oracle.nat(200000)
  for pair in 0..<20 {
    let complete_first = pair % 2 == 0
    let first_trial = if complete_first { CompleteIds } else { trial }
    let second_trial = if complete_first { trial } else { CompleteIds }
    let started = @bench.monotonic_clock_start()
    let first = cutoff_query(cnf, budget, first_trial)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = cutoff_query(cnf, budget, second_trial)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (complete, cutoff) = if complete_first {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "cutoff-pair index=\{pair} complete_first=\{complete_first} direct=\{direct} complete_ms=\{complete/1000.0} cutoff_ms=\{cutoff/1000.0} ratio=\{complete/cutoff}",
    )
  }
  b.bench(
    fn() { b.keep(check_prepared(input, old)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
test "paired complete queries with second unassigned cutoff" (b : @bench.T) {
  cutoff_pairs(CutoffIds, false, b)
}

///|
test "paired complete queries combine cutoff and direct references" (
  b : @bench.T,
) {
  cutoff_pairs(CutoffReferences, true, b)
}

///|
test "cutoff and references preserve deterministic cohort certificates" {
  let budget = @oracle.nat(200000)
  let mut id_seed = 31415
  for _ in 0..<1000 {
    let clauses = []
    for _ in 0..<24 {
      let values = []
      for _ in 0..<3 {
        id_seed = (id_seed * 61 + 17) % 65521
        let variable = id_seed % 6
        id_seed = (id_seed * 61 + 17) % 65521
        values.push(lit(variable, id_seed % 2 == 1))
      }
      clauses.push(values)
    }
    let cnf = formula(clauses)
    match @cdcl.run(@cdcl.start(cnf), budget) {
      Unsatisfiable(proof) => {
        let input = prepare(cnf)
        let old = full_build_prepared(input, proof).unwrap()
        for trial in [CutoffIds, CutoffReferences] {
          assert_eq(old, builder_trial(input, proof, trial).unwrap())
        }
        assert_true(check_prepared(input, old))
      }
      Satisfiable(model) => assert_true(@sat.check_model(cnf, model))
      _ => fail("cutoff cohort must finish")
    }
  }
}

///|
fn cutoff_batch(
  formulas : Array[@sat.Cnf],
  budget : @core.Nat,
  trial : BuilderTrial,
) -> Bool {
  for cnf in formulas {
    if !cutoff_query(cnf, budget, trial) {
      return false
    }
  }
  true
}

///|
test "small complete query controls for selected builder" (b : @bench.T) {
  let pigeon = pigeonhole(6, 5)
  let budget = @oracle.nat(200000)
  let cohort = []
  let mut seed = 31415
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
    cohort.push(formula(clauses))
  }
  for trial in [CompleteIds, CutoffReferences] {
    assert_true(cutoff_query(pigeon, budget, trial))
    assert_true(cutoff_batch(cohort, budget, trial))
  }
  b.bench(
    fn() { b.keep(cutoff_query(pigeon, budget, CompleteIds)) },
    name="pigeonhole full evaluator and clause IDs",
  )
  b.bench(
    fn() { b.keep(cutoff_query(pigeon, budget, CutoffReferences)) },
    name="pigeonhole cutoff and clause references",
  )
  b.bench(
    fn() { b.keep(cutoff_batch(cohort, budget, CompleteIds)) },
    name="thousand queries full evaluator and clause IDs",
  )
  b.bench(
    fn() { b.keep(cutoff_batch(cohort, budget, CutoffReferences)) },
    name="thousand queries cutoff and clause references",
  )
}
