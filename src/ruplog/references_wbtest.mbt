// Direct-reference candidate; production retains clause-ID lookup after inconclusive complete-query comparison.

///|
/// A static signed-literal occurrence index. No watch positions or assignment
/// state survive between lemmas; only this immutable index is extended.
priv struct ReferenceOccurrences {
  indexed : Trie[@core.Chain[Entry]]
  units : @core.Chain[(@binary.Binary, Literal)]
  empty : @binary.Binary?
}

///|
fn ref_signed_key(key : @binary.Binary, positive : Bool) -> @core.Chain[Bool] {
  Cons(positive, @binary.bits(key))
}

///|
fn ref_affected(
  occurrences : ReferenceOccurrences,
  key : @binary.Binary,
  positive : Bool,
) -> @core.Chain[Entry] {
  match get(occurrences.indexed, ref_signed_key(key, !positive)) {
    None => Nil
    Some(ids) => ids
  }
}

///|
fn ref_occurrence_add(
  occurrences : ReferenceOccurrences,
  id : @binary.Binary,
  clause : Clause,
) -> ReferenceOccurrences {
  match clause {
    Tautology => occurrences
    Terms(clause) => {
      let entry = Entry::{ id, clause: Terms(clause), }
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
        let key = ref_signed_key(value.key, value.source.positive)
        let previous : @core.Chain[Entry] = match
          get(occurrences.indexed, key) {
          None => Nil
          Some(ids) => ids
        }
        {
          ..occurrences,
          indexed: put(occurrences.indexed, key, Cons(entry, previous)),
        }
      })
    }
  }
}

///|
fn ref_occurrence_prepare(database : Database) -> ReferenceOccurrences {
  let initial = ReferenceOccurrences::{
    indexed: Empty,
    units: Nil,
    empty: None,
  }
  let result = @core.fold_left(database.entries, initial, fn(
    occurrences,
    entry,
  ) {
    ref_occurrence_add(occurrences, entry.id, entry.clause)
  })
  { ..result, units: @core.reverse(result.units), }
}

///|
priv struct ReferenceWork {
  values : Trie[Bool]
  chunks : @core.Queue[@core.Chain[Entry]]
  active : @core.Chain[Entry]
  hints_rev : @core.Chain[@binary.Binary]
}

///|
fn ref_assign(
  work : ReferenceWork,
  occurrences : ReferenceOccurrences,
  key : @binary.Binary,
  positive : Bool,
) -> ReferenceWork {
  {
    ..work,
    values: put(work.values, @binary.bits(key), positive),
    chunks: @core.enqueue(work.chunks, ref_affected(occurrences, key, positive)),
  }
}

///|
priv enum ReferenceSeeded {
  Ready(ReferenceWork)
  Immediate(@core.Chain[@binary.Binary])
}

///|
fn ref_seed(
  units : @core.Chain[(@binary.Binary, Literal)],
  work : ReferenceWork,
  occurrences : ReferenceOccurrences,
) -> ReferenceSeeded {
  match units {
    Nil => Ready(work)
    Cons((id, value), rest) =>
      match get(work.values, @binary.bits(value.key)) {
        Some(assigned) =>
          match (assigned, value.source.positive) {
            (true, true) | (false, false) => ref_seed(rest, work, occurrences)
            _ => Immediate(@core.reverse(Cons(id, work.hints_rev)))
          }
        None => {
          let work = ref_assign(
            work,
            occurrences,
            value.key,
            value.source.positive,
          )
          ref_seed(
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
fn ref_occurrence_hints(
  clause : Lits,
  occurrences : ReferenceOccurrences,
) -> @core.Chain[@binary.Binary]? {
  fn ref_propagate(work : ReferenceWork) -> @core.Chain[@binary.Binary]? {
    match work.active {
      Nil =>
        match @core.dequeue(work.chunks) {
          None => None
          Some((active, chunks)) => ref_propagate({ ..work, active, chunks, })
        }
      Cons(entry, rest) => {
        let work = { ..work, active: rest, }
        match entry.clause {
          Tautology => ref_propagate(work)
          Terms(clause) =>
            match builder_clause(clause, work.values) {
              Satisfied | Open => ref_propagate(work)
              Conflict => Some(@core.reverse(Cons(entry.id, work.hints_rev)))
              Unit(value) => {
                let work = ref_assign(
                  work,
                  occurrences,
                  value.key,
                  value.source.positive,
                )
                ref_propagate({
                  ..work,
                  hints_rev: Cons(entry.id, work.hints_rev),
                })
              }
            }
        }
      }
    }
  }
  match occurrences.empty {
    Some(id) => Some(Cons(id, Nil))
    None => {
      let initial = ReferenceWork::{
        values: Empty,
        chunks: @core.queue(),
        active: Nil,
        hints_rev: Nil,
      }
      let work = @core.fold_left(clause, initial, fn(work, value) {
        ref_assign(work, occurrences, value.key, !value.source.positive)
      })
      match ref_seed(occurrences.units, work, occurrences) {
        Immediate(hints) => Some(hints)
        Ready(work) => ref_propagate(work)
      }
    }
  }
}

///|
/// Enrich an existing RUP list without invoking SAT search. Source tautological
/// lemmas are omitted. Other clauses are sorted and deduplicated. An empty
/// clause is required exactly at the end.
fn ref_build_using(
  input : Input,
  proof : @cdcl.Proof,
  occurrences : ReferenceOccurrences?,
) -> Certificate? {
  fn ref_visit(
    rest : @core.Chain[@sat.Clause],
    database : Database,
    reversed : @core.Chain[Step],
    occurrences : ReferenceOccurrences?,
  ) -> Certificate? {
    match rest {
      Nil => None
      Cons(source, tail) =>
        match normalize(source) {
          Tautology => ref_visit(tail, database, reversed, occurrences)
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
                    Some(indexed) => ref_occurrence_hints(clause, indexed)
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
                              ref_occurrence_add(
                                indexed,
                                step.id,
                                Terms(clause),
                              ),
                            )
                        }
                        ref_visit(
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
    Rup(steps) => ref_visit(steps, input.database, Nil, occurrences)
  }
}

///|
fn ref_build_prepared(input : Input, proof : @cdcl.Proof) -> Certificate? {
  ref_build_using(input, proof, Some(ref_occurrence_prepare(input.database)))
}

///|
test "direct clause references preserve every hint on small complete and rejected proofs" {
  for a in 0..<27 {
    for b in 0..<27 {
      let cnf = @oracle.chain([ternary(a), ternary(b)])
      let input = prepare(cnf)
      for candidate in 0..<27 {
        let proof = @cdcl.Rup(@oracle.chain([ternary(candidate), @core.Nil]))
        let baseline = build_prepared(input, proof)
        assert_eq(baseline, ref_build_prepared(input, proof))
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
    let old = build_prepared(input, proof).unwrap()
    assert_eq(old, ref_build_prepared(input, proof).unwrap())
    assert_true(check_prepared(input, old))
  }
}

///|
test "same executable clause reference builder ABBA comparison" (b : @bench.T) {
  let (cnf, proof) = miter(64)
  let input = prepare(cnf)
  let old = build_prepared(input, proof).unwrap()
  assert_eq(old, ref_build_prepared(input, proof).unwrap())
  assert_true(check_prepared(input, old))
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
    name="clause IDs builder first control",
  )
  b.bench(
    fn() { b.keep(ref_build_prepared(input, proof)) },
    name="clause references builder",
  )
  b.bench(
    fn() { b.keep(ref_build_prepared(input, proof)) },
    name="clause references builder repeated control",
  )
  b.bench(
    fn() { b.keep(build_prepared(input, proof)) },
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
        ref_build_prepared(input, proof)
      } else {
        build_prepared(input, proof)
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
  let old = build_prepared(input, proof).unwrap()
  assert_eq(old, ref_build_prepared(input, proof).unwrap())
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
        let old = build_prepared(input, proof).unwrap()
        assert_eq(old, ref_build_prepared(input, proof).unwrap())
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
    fn() { b.keep(ref_build_prepared(input, proof)) },
    name="whole prepared direct-reference builder control",
  )
}
