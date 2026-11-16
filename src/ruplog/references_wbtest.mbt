// Clause-ID baseline from fbcefc1; it uses the current unit evaluator.

///|
/// A static signed-literal occurrence index. No watch positions or assignment
/// state survive between lemmas; only this immutable index is extended.
priv struct IdOccurrences {
  indexed : Trie[@core.Chain[@binary.Binary]]
  units : @core.Chain[(@binary.Binary, Literal)]
  empty : @binary.Binary?
}

///|
fn id_signed_key(key : @binary.Binary, positive : Bool) -> @core.Chain[Bool] {
  Cons(positive, @binary.bits(key))
}

///|
fn id_affected(
  occurrences : IdOccurrences,
  key : @binary.Binary,
  positive : Bool,
) -> @core.Chain[@binary.Binary] {
  match get(occurrences.indexed, id_signed_key(key, !positive)) {
    None => Nil
    Some(ids) => ids
  }
}

///|
fn id_occurrence_add(
  occurrences : IdOccurrences,
  id : @binary.Binary,
  clause : Clause,
) -> IdOccurrences {
  match clause {
    Tautology => occurrences
    Terms(clause) => {
      let occurrences = match clause {
        Nil =>
          match occurrences.empty {
            None => { ..occurrences, empty: Some(id), }
            Some(_) => occurrences
          }
        Cons(value, Nil) =>
          { ..occurrences, units: Cons((id, value), occurrences.units), }
        _ => occurrences
      }
      @core.fold_left(clause, occurrences, fn(occurrences, value) {
        let key = id_signed_key(value.key, value.source.positive)
        let previous : @core.Chain[@binary.Binary] = match
          get(occurrences.indexed, key) {
          None => Nil
          Some(ids) => ids
        }
        {
          ..occurrences,
          indexed: put(occurrences.indexed, key, Cons(id, previous)),
        }
      })
    }
  }
}

///|
fn id_occurrence_prepare(database : Database) -> IdOccurrences {
  let initial = IdOccurrences::{ indexed: Empty, units: Nil, empty: None, }
  let result = @core.fold_left(database.entries, initial, fn(
    occurrences,
    entry,
  ) {
    id_occurrence_add(occurrences, entry.id, entry.clause)
  })
  { ..result, units: @core.reverse(result.units), }
}

///|
priv struct IdWork {
  values : Trie[Bool]
  chunks : @core.Queue[@core.Chain[@binary.Binary]]
  active : @core.Chain[@binary.Binary]
  hints_rev : @core.Chain[@binary.Binary]
}

///|
fn id_assign(
  work : IdWork,
  occurrences : IdOccurrences,
  key : @binary.Binary,
  positive : Bool,
) -> IdWork {
  {
    ..work,
    values: put(work.values, @binary.bits(key), positive),
    chunks: @core.enqueue(work.chunks, id_affected(occurrences, key, positive)),
  }
}

///|
priv enum IdSeeded {
  Ready(IdWork)
  Immediate(@core.Chain[@binary.Binary])
}

///|
fn id_seed(
  units : @core.Chain[(@binary.Binary, Literal)],
  work : IdWork,
  occurrences : IdOccurrences,
) -> IdSeeded {
  match units {
    Nil => Ready(work)
    Cons((id, value), rest) =>
      match get(work.values, @binary.bits(value.key)) {
        Some(assigned) =>
          match (assigned, value.source.positive) {
            (true, true) | (false, false) => id_seed(rest, work, occurrences)
            _ => Immediate(@core.reverse(Cons(id, work.hints_rev)))
          }
        None => {
          let work = id_assign(
            work,
            occurrences,
            value.key,
            value.source.positive,
          )
          id_seed(
            rest,
            { ..work, hints_rev: Cons(id, work.hints_rev), },
            occurrences,
          )
        }
      }
  }
}

///|
/// Only clauses containing a newly falsified literal enter the work queue.
/// Lists are enqueued as shared chunks rather than copied per occurrence.
fn id_occurrence_hints(
  database : Database,
  clause : Lits,
  occurrences : IdOccurrences,
) -> @core.Chain[@binary.Binary]? {
  fn id_propagate(work : IdWork) -> @core.Chain[@binary.Binary]? {
    match work.active {
      Nil =>
        match @core.dequeue(work.chunks) {
          None => None
          Some((active, chunks)) => id_propagate({ ..work, active, chunks, })
        }
      Cons(id, rest) => {
        let work = { ..work, active: rest, }
        match get(database.indexed, @binary.bits(id)) {
          None => None
          Some(Tautology) => id_propagate(work)
          Some(Terms(clause)) =>
            match builder_clause(clause, work.values) {
              Satisfied | Open => id_propagate(work)
              Conflict => Some(@core.reverse(Cons(id, work.hints_rev)))
              Unit(value) => {
                let work = id_assign(
                  work,
                  occurrences,
                  value.key,
                  value.source.positive,
                )
                id_propagate({ ..work, hints_rev: Cons(id, work.hints_rev), })
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
        Ready(work) => id_propagate(work)
      }
    }
  }
}

///|
/// Enrich an existing RUP list without invoking SAT search. Source tautological
/// lemmas are omitted. Other clauses are sorted and deduplicated. An empty
/// clause is required exactly at the end.
fn id_build_using(
  input : Input,
  proof : @cdcl.Proof,
  occurrences : IdOccurrences?,
) -> Certificate? {
  fn id_visit(
    rest : @core.Chain[@sat.Clause],
    database : Database,
    reversed : @core.Chain[Step],
    occurrences : IdOccurrences?,
  ) -> Certificate? {
    match rest {
      Nil => None
      Cons(source, tail) =>
        match normalize(source) {
          Tautology => id_visit(tail, database, reversed, occurrences)
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
                      id_occurrence_hints(database, clause, indexed)
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
                        id_visit(
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
    Rup(steps) => id_visit(steps, input.database, Nil, occurrences)
  }
}

///|
fn id_build_prepared(input : Input, proof : @cdcl.Proof) -> Certificate? {
  id_build_using(input, proof, Some(id_occurrence_prepare(input.database)))
}

///|
test "direct clause references preserve every hint on small complete and rejected proofs" {
  for a in 0..<27 {
    for b in 0..<27 {
      let cnf = @oracle.chain([ternary(a), ternary(b)])
      let input = prepare(cnf)
      for candidate in 0..<27 {
        let proof = @cdcl.Rup(@oracle.chain([ternary(candidate), @core.Nil]))
        let baseline = id_build_prepared(input, proof)
        assert_eq(baseline, build_prepared(input, proof))
        match baseline {
          None => ()
          Some(logged) => assert_true(check_prepared(input, logged))
        }
      }
    }
  }
  let examples = [
    formula([[]]),
    formula([[lit(0, true)], [lit(0, false)]]),
    formula([
      [lit(0, true), lit(0, true)],
      [lit(0, false), lit(0, true)],
      [lit(0, false)],
    ]),
    formula([[lit(65535, true)], [lit(65535, false)]]),
  ]
  for cnf in examples {
    let input = prepare(cnf)
    let proof = match @cdcl.run(@cdcl.start(cnf), @oracle.nat(10000)) {
      Unsatisfiable(proof) => proof
      _ => fail("reference examples must be refuted")
    }
    let old = id_build_prepared(input, proof).unwrap()
    assert_eq(old, build_prepared(input, proof).unwrap())
    assert_true(check_prepared(input, old))
  }
}

///|
test "same executable clause reference builder ABBA comparison" (b : @bench.T) {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let old = id_build_prepared(input, proof).unwrap()
  assert_eq(old, build_prepared(input, proof).unwrap())
  assert_true(check_prepared(input, old))
  b.bench(
    fn() { b.keep(id_build_prepared(input, proof)) },
    name="clause IDs builder first control",
  )
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
    name="clause references builder",
  )
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
    name="clause references builder repeated control",
  )
  b.bench(
    fn() { b.keep(id_build_prepared(input, proof)) },
    name="clause IDs builder repeated control",
  )
  b.bench(
    fn() { b.keep(check_prepared(input, old)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn reference_query(cnf : @sat.Cnf, budget : @core.Nat, direct : Bool) -> Bool {
  match @cdcl.run(@cdcl.start(cnf), budget) {
    Unsatisfiable(proof) => {
      let input = prepare(cnf)
      let certificate = if direct {
        build_prepared(input, proof)
      } else {
        id_build_prepared(input, proof)
      }
      match certificate {
        None => false
        Some(logged) => check_prepared(input, logged)
      }
    }
    Satisfiable(model) => @sat.check_model(cnf, model)
    _ => false
  }
}

///|
test "paired complete queries compare clause references with clause IDs" (
  b : @bench.T,
) {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let old = id_build_prepared(input, proof).unwrap()
  assert_eq(old, build_prepared(input, proof).unwrap())
  let budget = @oracle.nat(200000)
  for pair in 0..<20 {
    let ids_first = pair % 2 == 0
    let started = @bench.monotonic_clock_start()
    let first = reference_query(cnf, budget, !ids_first)
    let first_elapsed = @bench.monotonic_clock_end(started)
    let started = @bench.monotonic_clock_start()
    let second = reference_query(cnf, budget, ids_first)
    let second_elapsed = @bench.monotonic_clock_end(started)
    b.keep(first)
    b.keep(second)
    assert_true(first)
    assert_true(second)
    let (ids, direct) = if ids_first {
      (first_elapsed, second_elapsed)
    } else {
      (second_elapsed, first_elapsed)
    }
    println(
      "reference-pair index=\{pair} ids_first=\{ids_first} ids_ms=\{ids/1000.0} direct_ms=\{direct/1000.0} ratio=\{ids/direct}",
    )
  }
  b.bench(
    fn() { b.keep(check_prepared(input, old)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn reference_batch(
  formulas : Array[@sat.Cnf],
  budget : @core.Nat,
  direct : Bool,
) -> Bool {
  for cnf in formulas {
    if !reference_query(cnf, budget, direct) {
      return false
    }
  }
  true
}

///|
test "direct references retain certificates for deterministic six-variable queries" (
  b : @bench.T,
) {
  let budget = @oracle.nat(200000)
  let cohort = []
  let mut seed = 31415
  let mut unsat = 0
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
    let cnf = formula(clauses)
    cohort.push(cnf)
    match @cdcl.run(@cdcl.start(cnf), budget) {
      Unsatisfiable(proof) => {
        let input = prepare(cnf)
        let old = id_build_prepared(input, proof).unwrap()
        assert_eq(old, build_prepared(input, proof).unwrap())
        assert_true(check_prepared(input, old))
        unsat += 1
      }
      Satisfiable(model) => assert_true(@sat.check_model(cnf, model))
      _ => fail("reference cohort must finish")
    }
  }
  println("reference-cohort formulas=1000 unsat=\{unsat}")
  assert_true(reference_batch(cohort, budget, false))
  assert_true(reference_batch(cohort, budget, true))
  b.bench(
    fn() { b.keep(reference_batch(cohort, budget, false)) },
    name="thousand six-variable queries clause IDs",
  )
  b.bench(
    fn() { b.keep(reference_batch(cohort, budget, true)) },
    name="thousand six-variable queries clause references",
  )
}

///|
test "proof normalization cost before changing canonicalization" (b : @bench.T) {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let @cdcl.Rup(steps) = proof
  b.bench(
    fn() { b.keep(@core.map(steps, normalize)) },
    name="normalize all learned proof clauses",
  )
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
    name="whole prepared direct-reference builder control",
  )
}
