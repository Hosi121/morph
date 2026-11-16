///|
/// A static signed-literal occurrence index. No watch positions or assignment
/// state survive between lemmas; only this immutable index is extended.
priv struct Occurrences {
  indexed : Trie[@core.Chain[Entry]]
  units : @core.Chain[(@binary.Binary, Literal)]
  empty : @binary.Binary?
}

///|
fn signed_key(key : @binary.Binary, positive : Bool) -> @core.Chain[Bool] {
  Cons(positive, @binary.bits(key))
}

///|
fn affected(
  occurrences : Occurrences,
  key : @binary.Binary,
  positive : Bool,
) -> @core.Chain[Entry] {
  match get(occurrences.indexed, signed_key(key, !positive)) {
    None => Nil
    Some(entries) => entries
  }
}

///|
fn occurrence_add(
  occurrences : Occurrences,
  id : @binary.Binary,
  clause : Clause,
) -> Occurrences {
  match clause {
    Tautology => occurrences
    Terms(literals) => {
      let entry = Entry::{ id, clause, }
      let occurrences = match literals {
        Nil =>
          match occurrences.empty {
            None => { ..occurrences, empty: Some(id), }
            Some(_) => occurrences
          }
        Cons(value, Nil) =>
          { ..occurrences, units: Cons((id, value), occurrences.units), }
        _ => occurrences
      }
      @core.fold_left(literals, occurrences, fn(occurrences, value) {
        let key = signed_key(value.key, value.source.positive)
        let previous : @core.Chain[Entry] = match
          get(occurrences.indexed, key) {
          None => Nil
          Some(entries) => entries
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
fn occurrence_prepare(database : Database) -> Occurrences {
  let initial = Occurrences::{ indexed: Empty, units: Nil, empty: None, }
  let result = @core.fold_left(database.entries, initial, fn(
    occurrences,
    entry,
  ) {
    occurrence_add(occurrences, entry.id, entry.clause)
  })
  { ..result, units: @core.reverse(result.units), }
}

///|
priv struct Work {
  values : Trie[Bool]
  chunks : @core.Queue[@core.Chain[Entry]]
  active : @core.Chain[Entry]
  hints_rev : @core.Chain[@binary.Binary]
}

///|
fn assign(
  work : Work,
  occurrences : Occurrences,
  key : @binary.Binary,
  positive : Bool,
) -> Work {
  {
    ..work,
    values: put(work.values, @binary.bits(key), positive),
    chunks: @core.enqueue(work.chunks, affected(occurrences, key, positive)),
  }
}

///|
priv enum Seeded {
  Ready(Work)
  Immediate(@core.Chain[@binary.Binary])
}

///|
fn seed(
  units : @core.Chain[(@binary.Binary, Literal)],
  work : Work,
  occurrences : Occurrences,
) -> Seeded {
  match units {
    Nil => Ready(work)
    Cons((id, value), rest) =>
      match get(work.values, @binary.bits(value.key)) {
        Some(assigned) =>
          match (assigned, value.source.positive) {
            (true, true) | (false, false) => seed(rest, work, occurrences)
            _ => Immediate(@core.reverse(Cons(id, work.hints_rev)))
          }
        None => {
          let work = assign(work, occurrences, value.key, value.source.positive)
          seed(
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
/// Shared chunks retain immutable clause references, avoiding repeated ID lookup.
fn occurrence_hints(
  clause : Lits,
  occurrences : Occurrences,
) -> @core.Chain[@binary.Binary]? {
  fn propagate(work : Work) -> @core.Chain[@binary.Binary]? {
    match work.active {
      Nil =>
        match @core.dequeue(work.chunks) {
          None => None
          Some((active, chunks)) => propagate({ ..work, active, chunks, })
        }
      Cons(entry, rest) => {
        let work = { ..work, active: rest, }
        match entry.clause {
          Tautology => propagate(work)
          Terms(clause) =>
            match builder_clause(clause, work.values) {
              Satisfied | Open => propagate(work)
              Conflict => Some(@core.reverse(Cons(entry.id, work.hints_rev)))
              Unit(value) => {
                let work = assign(
                  work,
                  occurrences,
                  value.key,
                  value.source.positive,
                )
                propagate({ ..work, hints_rev: Cons(entry.id, work.hints_rev), })
              }
            }
        }
      }
    }
  }
  match occurrences.empty {
    Some(id) => Some(Cons(id, Nil))
    None => {
      let initial = Work::{
        values: Empty,
        chunks: @core.queue(),
        active: Nil,
        hints_rev: Nil,
      }
      let work = @core.fold_left(clause, initial, fn(work, value) {
        assign(work, occurrences, value.key, !value.source.positive)
      })
      match seed(occurrences.units, work, occurrences) {
        Immediate(hints) => Some(hints)
        Ready(work) => propagate(work)
      }
    }
  }
}
