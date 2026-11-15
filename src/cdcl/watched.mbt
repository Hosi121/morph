///|
/// Persistent bitwise trie; keys are structural Bool words.
#derive(Eq, Debug)
enum Index[A] {
  Empty
  Branch(A?, Index[A], Index[A])
}

///|
pub extend Index with Eq::{equal, not_equal}

///|
pub extend Index with Debug::{to_repr}

///|
fn[A] index_get(index : Index[A], key : @core.Chain[Bool]) -> A? {
  match (index, key) {
    (Empty, _) => None
    (Branch(value, _, _), Nil) => value
    (Branch(_, left, _), Cons(false, rest)) => index_get(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => index_get(right, rest)
  }
}

///|
fn[A] index_put(
  index : Index[A],
  key : @core.Chain[Bool],
  value : A,
) -> Index[A] {
  match (index, key) {
    (Empty, Nil) => Branch(Some(value), Empty, Empty)
    (Empty, Cons(false, rest)) =>
      Branch(None, index_put(Empty, rest, value), Empty)
    (Empty, Cons(true, rest)) =>
      Branch(None, Empty, index_put(Empty, rest, value))
    (Branch(_, left, right), Nil) => Branch(Some(value), left, right)
    (Branch(found, left, right), Cons(false, rest)) =>
      Branch(found, index_put(left, rest, value), right)
    (Branch(found, left, right), Cons(true, rest)) =>
      Branch(found, left, index_put(right, rest, value))
  }
}

///|
fn[A] index_branch(value : A?, left : Index[A], right : Index[A]) -> Index[A] {
  match (value, left, right) {
    (None, Empty, Empty) => Empty
    _ => Branch(value, left, right)
  }
}

///|
/// Remove one value and prune empty paths, preserving the canonical trie shape.
fn[A] index_remove(index : Index[A], key : @core.Chain[Bool]) -> Index[A] {
  match (index, key) {
    (Empty, _) => Empty
    (Branch(_, left, right), Nil) => index_branch(None, left, right)
    (Branch(value, left, right), Cons(false, rest)) =>
      index_branch(value, index_remove(left, rest), right)
    (Branch(value, left, right), Cons(true, rest)) =>
      index_branch(value, left, index_remove(right, rest))
  }
}

///|
#derive(Eq, Debug)
struct WatchedClause {
  id : @binary.Binary
  literals : Lits
  first : Atom
  second : Atom?
}

///|
pub extend WatchedClause with Eq::{equal, not_equal}

///|
pub extend WatchedClause with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct WatchState {
  clauses : Index[WatchedClause]
  buckets : Index[@core.Chain[@binary.Binary]]
  values : Index[Assignment]
  pending : @core.Queue[Atom]
  active : (Atom, @core.Chain[@binary.Binary])?
  units : @core.Chain[(Atom, Lits)]
  empty : Bool
  next_id : @binary.Binary
}

///|
pub extend WatchState with Eq::{equal, not_equal}

///|
pub extend WatchState with Debug::{to_repr}

///|
fn watch_key(literal : Atom) -> @core.Chain[Bool] {
  Cons(literal.positive, @binary.bits(literal.key))
}

///|
fn bucket(state : WatchState, literal : Atom) -> @core.Chain[@binary.Binary] {
  match index_get(state.buckets, watch_key(literal)) {
    None => Nil
    Some(ids) => ids
  }
}

///|
fn bucket_add(
  state : WatchState,
  literal : Atom,
  id : @binary.Binary,
) -> WatchState {
  {
    ..state,
    buckets: index_put(
      state.buckets,
      watch_key(literal),
      Cons(id, bucket(state, literal)),
    ),
  }
}

///|
fn bucket_remove(
  state : WatchState,
  literal : Atom,
  id : @binary.Binary,
) -> WatchState {
  {
    ..state,
    buckets: index_put(
      state.buckets,
      watch_key(literal),
      @core.filter(bucket(state, literal), fn(other) {
        match @binary.compare(id, other) {
          Equal => false
          _ => true
        }
      }),
    ),
  }
}

///|
fn watch_insert(
  state : WatchState,
  literals : Lits,
  first : Atom,
  second : Atom?,
) -> WatchState {
  let entry = { id: state.next_id, literals, first, second, }
  let state = {
    ..state,
    clauses: index_put(state.clauses, @binary.bits(entry.id), entry),
    next_id: @binary.successor(state.next_id),
  }
  let state = bucket_add(state, first, entry.id)
  match second {
    None => state
    Some(other) => bucket_add(state, other, entry.id)
  }
}

///|
fn watch_start(db : Database) -> WatchState {
  let initial = {
    clauses: Empty,
    buckets: Empty,
    values: Empty,
    pending: @core.queue(),
    active: None,
    units: Nil,
    empty: false,
    next_id: @binary.zero(),
  }
  let state = @core.fold_left(db, initial, fn(state, clause) {
    match clause {
      Nil => { ..state, empty: true, }
      Cons(first, Nil) => {
        let state = watch_insert(state, clause, first, None)
        { ..state, units: Cons((first, clause), state.units), }
      }
      Cons(first, Cons(second, _)) =>
        watch_insert(state, clause, first, Some(second))
    }
  })
  { ..state, units: @core.reverse(state.units), }
}

///|
fn index_value(literal : Atom, values : Index[Assignment]) -> Value {
  match index_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match same(entry.literal, literal) {
        true => True
        false => False
      }
  }
}

///|
fn indexed_clause(clause : Lits, values : Index[Assignment]) -> ClauseState {
  match clause {
    Nil => Conflict
    Cons(literal, rest) =>
      match index_value(literal, values) {
        True => Satisfied
        False => indexed_clause(rest, values)
        Unassigned =>
          match indexed_clause(rest, values) {
            Satisfied => Satisfied
            Conflict => Unit(literal)
            Unit(_) | Open(_) => Open(literal)
          }
      }
  }
}

///|
fn watch_decision_checked(
  db : Database,
  values : Index[Assignment],
) -> Inspection {
  fn visit(db : Database, candidate : Atom?) -> Inspection {
    match db {
      Nil =>
        match candidate {
          None => Complete
          Some(literal) => Decide(literal)
        }
      Cons(clause, rest) =>
        match indexed_clause(clause, values) {
          Satisfied => visit(rest, candidate)
          Open(literal) =>
            match candidate {
              None => visit(rest, Some(literal))
              Some(_) => visit(rest, candidate)
            }
          Unit(_) | Conflict => Broken
        }
    }
  }
  visit(db, None)
}

///|
/// At quiescence the watch invariant excludes pending units and conflicts.
/// Keep the full database diagnostic in watch_decision_checked for tests.
fn watch_decision(db : Database, values : Index[Assignment]) -> Inspection {
  match db {
    Nil => Complete
    Cons(clause, rest) =>
      match indexed_clause(clause, values) {
        Satisfied => watch_decision(rest, values)
        Open(literal) => Decide(literal)
        Unit(_) | Conflict => Broken
      }
  }
}

///|
fn replacement(
  clause : Lits,
  false_watch : Atom,
  other : Atom,
  values : Index[Assignment],
) -> Atom? {
  match clause {
    Nil => None
    Cons(literal, rest) =>
      match same_key(literal, false_watch) || same_key(literal, other) {
        true => replacement(rest, false_watch, other, values)
        false =>
          match index_value(literal, values) {
            False => replacement(rest, false_watch, other, values)
            _ => Some(literal)
          }
      }
  }
}

///|
fn watch_move(
  state : WatchState,
  clause : WatchedClause,
  previous : Atom,
  next : Atom,
  other : Atom,
) -> WatchState {
  let state = bucket_remove(state, previous, clause.id)
  let state = bucket_add(state, next, clause.id)
  {
    ..state,
    clauses: index_put(state.clauses, @binary.bits(clause.id), {
      ..clause,
      first: next,
      second: Some(other),
    }),
  }
}

///|
/// Finish a bucket incrementally, retaining the remaining IDs when a new
/// implied literal is returned. Clause moves remain valid after unassignment.
fn watch_inspect_using(
  state : WatchState,
  db : Database,
  check_rest : Bool,
) -> (Inspection, WatchState) {
  match state.empty {
    true => (Contradiction(Nil), state)
    false =>
      match state.units {
        Cons((literal, reason), rest) => {
          let state = { ..state, units: rest, }
          match index_value(literal, state.values) {
            True => watch_inspect_using(state, db, check_rest)
            False => (Contradiction(reason), state)
            Unassigned => (Propagate(literal, reason), state)
          }
        }
        Nil =>
          match state.active {
            None =>
              match @core.dequeue(state.pending) {
                None => {
                  let decision = match check_rest {
                    true => watch_decision_checked(db, state.values)
                    false => watch_decision(db, state.values)
                  }
                  (decision, state)
                }
                Some((literal, pending)) => {
                  let literal = opposite(literal)
                  watch_inspect_using(
                    {
                      ..state,
                      pending,
                      active: Some((literal, bucket(state, literal))),
                    },
                    db,
                    check_rest,
                  )
                }
              }
            Some((_, Nil)) =>
              watch_inspect_using({ ..state, active: None, }, db, check_rest)
            Some((false_watch, Cons(id, rest))) => {
              let state = { ..state, active: Some((false_watch, rest)), }
              match index_get(state.clauses, @binary.bits(id)) {
                None => (Broken, state)
                Some(clause) => {
                  let other = match same(clause.first, false_watch) {
                    true => clause.second
                    false => Some(clause.first)
                  }
                  match other {
                    None => (Contradiction(clause.literals), state)
                    Some(other) =>
                      match index_value(other, state.values) {
                        True => watch_inspect_using(state, db, check_rest)
                        _ =>
                          match
                            replacement(
                              clause.literals,
                              false_watch,
                              other,
                              state.values,
                            ) {
                            Some(next) =>
                              watch_inspect_using(
                                watch_move(
                                  state, clause, false_watch, next, other,
                                ),
                                db,
                                check_rest,
                              )
                            None =>
                              match index_value(other, state.values) {
                                False => (Contradiction(clause.literals), state)
                                Unassigned =>
                                  (Propagate(other, clause.literals), state)
                                True => (Broken, state)
                              }
                          }
                      }
                  }
                }
              }
            }
          }
      }
  }
}

///|
fn watch_inspect(state : WatchState, db : Database) -> (Inspection, WatchState) {
  watch_inspect_using(state, db, false)
}

///|
fn watch_assign(watch : WatchState?, entry : Assignment) -> WatchState? {
  match watch {
    None => None
    Some(state) =>
      Some({
        ..state,
        values: index_put(state.values, @binary.bits(entry.literal.key), entry),
        pending: @core.enqueue(state.pending, entry.literal),
      })
  }
}

///|
fn second_watch(clause : Lits, first : Atom, trail : Trail) -> Atom? {
  @core.fold_left(clause, None, fn(best, literal) {
    match same_key(first, literal) {
      true => best
      false =>
        match best {
          None => Some(literal)
          Some(previous) =>
            match (assignment(trail, literal), assignment(trail, previous)) {
              (Some(found), Some(old)) =>
                match @core.compare(found.level, old.level) {
                  Greater => Some(literal)
                  _ => best
                }
              _ => best
            }
        }
    }
  })
}

///|
fn watch_learn(
  watch : WatchState?,
  clause : Lits,
  first : Atom,
  trail : Trail,
) -> WatchState? {
  match watch {
    None => None
    Some(state) => {
      let values = @core.fold_left(trail, Empty, fn(values, entry) {
        index_put(values, @binary.bits(entry.literal.key), entry)
      })
      let state = {
        ..state,
        values,
        active: None,
        pending: @core.enqueue(@core.queue(), first),
      }
      Some(
        watch_insert(state, clause, first, second_watch(clause, first, trail)),
      )
    }
  }
}

///|
fn watch_forget_above(
  values : Index[Assignment],
  trail : Trail,
  level : @core.Nat,
) -> Index[Assignment] {
  match trail {
    Nil => values
    Cons(entry, rest) =>
      match @core.compare(entry.level, level) {
        Greater =>
          watch_forget_above(
            index_remove(values, @binary.bits(entry.literal.key)),
            rest,
            level,
          )
        _ => values
      }
  }
}

///|
/// Keep surviving assignment paths and remove only the abandoned trail prefix.
fn watch_learn_shared(
  watch : WatchState?,
  clause : Lits,
  first : Atom,
  trail : Trail,
  previous : Trail,
) -> WatchState? {
  match (watch, trail) {
    (None, _) => None
    (Some(_), Nil) => watch_learn(watch, clause, first, trail)
    (Some(state), Cons(entry, _)) => {
      let values = watch_forget_above(state.values, previous, entry.level)
      let values = index_put(values, @binary.bits(entry.literal.key), entry)
      let state = {
        ..state,
        values,
        active: None,
        pending: @core.enqueue(@core.queue(), first),
      }
      Some(
        watch_insert(state, clause, first, second_watch(clause, first, trail)),
      )
    }
  }
}
