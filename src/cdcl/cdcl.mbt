///|
/// Ordered reverse-unit-propagation additions, ending with the empty clause.
#derive(Eq, Debug)
pub(all) enum Proof {
  Rup(@core.Chain[@sat.Clause])
}

///|
pub extend Proof with Eq::{equal, not_equal}

///|
pub extend Proof with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Statistics {
  transitions : @core.Nat
  decisions : @core.Nat
  propagations : @core.Nat
  conflicts : @core.Nat
  learned : @core.Nat
  backjumps : @core.Nat
  nonchronological : @core.Nat
}

///|
pub extend Statistics with Eq::{equal, not_equal}

///|
pub extend Statistics with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Atom {
  key : @binary.Binary
  source : @core.Nat
  positive : Bool
}

///|
pub extend Atom with Eq::{equal, not_equal}

///|
pub extend Atom with Debug::{to_repr}

///|
type Lits = @core.Chain[Atom]

///|
type Database = @core.Chain[Lits]

///|
#derive(Eq, Debug)
struct Assignment {
  literal : Atom
  level : @core.Nat
  reason : Lits?
}

///|
pub extend Assignment with Eq::{equal, not_equal}

///|
pub extend Assignment with Debug::{to_repr}

///|
type Trail = @core.Chain[Assignment]

///|
/// An immutable continuation. A fuel unit performs one propagation, decision,
/// or conflict-analysis transition; traversals inside a transition are finite
/// but are not separately charged.
#derive(Eq, Debug)
pub struct Search {
  database : Database
  variables : Lits
  watch : WatchState?
  trail : Trail
  level : @core.Nat
  proof_rev : @core.Chain[@sat.Clause]
  statistics : Statistics
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Satisfiable(@sat.Model)
  Unsatisfiable(Proof)
  Paused(Search)
  InvariantViolation
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
fn empty_statistics() -> Statistics {
  {
    transitions: Zero,
    decisions: Zero,
    propagations: Zero,
    conflicts: Zero,
    learned: Zero,
    backjumps: Zero,
    nonchronological: Zero,
  }
}

///|
fn atom(literal : @sat.Literal) -> Atom {
  {
    key: @binary.from_nat(literal.variable),
    source: literal.variable,
    positive: literal.positive,
  }
}

///|
fn external(literal : Atom) -> @sat.Literal {
  { variable: literal.source, positive: literal.positive, }
}

///|
fn opposite(literal : Atom) -> Atom {
  { ..literal, positive: !literal.positive, }
}

///|
fn same_key(left : Atom, right : Atom) -> Bool {
  match @binary.compare(left.key, right.key) {
    Equal => true
    _ => false
  }
}

///|
fn same(left : Atom, right : Atom) -> Bool {
  same_key(left, right) &&
  (match (left.positive, right.positive) {
    (true, true) | (false, false) => true
    _ => false
  })
}

///|
fn contains(clause : Lits, literal : Atom) -> Bool {
  @core.any(clause, fn(other) { same(literal, other) })
}

///|
/// Remove repeated literals and discard tautological clauses.
fn normalize(clause : @sat.Clause) -> Lits? {
  fn collect(rest : @sat.Clause, result : Lits) -> Lits? {
    match rest {
      Nil => Some(@core.reverse(result))
      Cons(literal, rest) => {
        let value = atom(literal)
        match contains(result, opposite(value)) {
          true => None
          false =>
            match contains(result, value) {
              true => collect(rest, result)
              false => collect(rest, Cons(value, result))
            }
        }
      }
    }
  }
  collect(clause, Nil)
}

///|
fn database(cnf : @sat.Cnf) -> Database {
  @core.reverse(
    @core.fold_left(cnf, Nil, fn(result, clause) {
      match normalize(clause) {
        None => result
        Some(clause) => Cons(clause, result)
      }
    }),
  )
}

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
pub fn start(cnf : @sat.Cnf) -> Search {
  let search = start_scanning(cnf)
  { ..search, watch: Some(watch_start(search.database)), }
}

///|
/// Retain the original scan engine for controlled comparisons.
pub fn start_scanning(cnf : @sat.Cnf) -> Search {
  {
    database: database(cnf),
    variables: variables(cnf),
    watch: None,
    trail: Nil,
    level: Zero,
    proof_rev: Nil,
    statistics: empty_statistics(),
  }
}

///|
pub fn statistics(search : Search) -> Statistics {
  search.statistics
}

///|
fn assignment(trail : Trail, literal : Atom) -> Assignment? {
  match trail {
    Nil => None
    Cons(entry, rest) =>
      match same_key(entry.literal, literal) {
        true => Some(entry)
        false => assignment(rest, literal)
      }
  }
}

///|
priv enum Value {
  True
  False
  Unassigned
}

///|
fn value(literal : Atom, trail : Trail) -> Value {
  match assignment(trail, literal) {
    None => Unassigned
    Some(entry) =>
      match same(entry.literal, literal) {
        true => True
        false => False
      }
  }
}

///|
priv enum ClauseState {
  Satisfied
  Conflict
  Unit(Atom)
  Open(Atom)
}

///|
fn inspect_clause(clause : Lits, trail : Trail) -> ClauseState {
  match clause {
    Nil => Conflict
    Cons(literal, rest) =>
      match value(literal, trail) {
        True => Satisfied
        False => inspect_clause(rest, trail)
        Unassigned =>
          match inspect_clause(rest, trail) {
            Satisfied => Satisfied
            Conflict => Unit(literal)
            Unit(_) | Open(_) => Open(literal)
          }
      }
  }
}

///|
priv enum Inspection {
  Complete
  Contradiction(Lits)
  Propagate(Atom, Lits)
  Decide(Atom)
  Broken
}

///|
fn inspect_database(db : Database, trail : Trail) -> Inspection {
  fn visit(db : Database, candidate : Atom?) -> Inspection {
    match db {
      Nil =>
        match candidate {
          None => Complete
          Some(literal) => Decide(literal)
        }
      Cons(clause, rest) =>
        match inspect_clause(clause, trail) {
          Conflict => Contradiction(clause)
          Unit(literal) => Propagate(literal, clause)
          Satisfied => visit(rest, candidate)
          Open(literal) =>
            match candidate {
              None => visit(rest, Some(literal))
              Some(_) => visit(rest, candidate)
            }
        }
    }
  }
  visit(db, None)
}

///|
priv enum Count {
  Absent
  Once
  Several
}

///|
fn at_level(clause : Lits, trail : Trail, level : @core.Nat) -> Count {
  match clause {
    Nil => Absent
    Cons(literal, rest) =>
      match assignment(trail, literal) {
        None => at_level(rest, trail, level)
        Some(entry) =>
          match @core.compare(entry.level, level) {
            Equal =>
              match at_level(rest, trail, level) {
                Absent => Once
                Once | Several => Several
              }
            _ => at_level(rest, trail, level)
          }
      }
  }
}

///|
fn maximum(left : @core.Nat, right : @core.Nat) -> @core.Nat {
  match @core.compare(left, right) {
    Less => right
    _ => left
  }
}

///|
fn highest_level(clause : Lits, trail : Trail) -> @core.Nat {
  match clause {
    Nil => Zero
    Cons(literal, rest) =>
      match assignment(trail, literal) {
        None => highest_level(rest, trail)
        Some(entry) => maximum(entry.level, highest_level(rest, trail))
      }
  }
}

///|
fn resolve(left : Lits, right : Lits, pivot : Atom) -> Lits {
  let result = @core.filter(left, fn(literal) { !same_key(literal, pivot) })
  @core.fold_left(right, result, fn(clause, literal) {
    match same_key(literal, pivot) || contains(clause, literal) {
      true => clause
      false => Cons(literal, clause)
    }
  })
}

///|
/// Resolve the most recent implied literals until a first UIP remains.
fn analyze(clause : Lits, trail : Trail, level : @core.Nat) -> Lits? {
  fn visit(clause : Lits, remaining : Trail) -> Lits? {
    match at_level(clause, trail, level) {
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
fn asserting(clause : Lits, trail : Trail, level : @core.Nat) -> Atom? {
  match clause {
    Nil => None
    Cons(literal, rest) =>
      match assignment(trail, literal) {
        Some(entry) =>
          match @core.compare(entry.level, level) {
            Equal => Some(literal)
            _ => asserting(rest, trail, level)
          }
        None => None
      }
  }
}

///|
fn backjump_level(clause : Lits, trail : Trail, asserting : Atom) -> @core.Nat {
  highest_level(
    @core.filter(clause, fn(literal) { !same_key(literal, asserting) }),
    trail,
  )
}

///|
fn backjump(trail : Trail, level : @core.Nat) -> Trail {
  @core.filter(trail, fn(entry) {
    match @core.compare(entry.level, level) {
      Greater => false
      _ => true
    }
  })
}

///|
fn model(trail : Trail, variables : Lits) -> @sat.Model {
  @core.map(variables, fn(literal) {
    match assignment(trail, literal) {
      None => external(literal)
      Some(entry) => external(entry.literal)
    }
  })
}

///|
fn transition(search : Search, inspection : Inspection) -> (Status, Statistics) {
  let stats = {
    ..search.statistics,
    transitions: Succ(search.statistics.transitions),
  }
  match inspection {
    Broken => (InvariantViolation, stats)
    Complete => (Satisfiable(model(search.trail, search.variables)), stats)
    Propagate(literal, reason) => {
      let stats = { ..stats, propagations: Succ(stats.propagations), }
      (
        Paused({
          ..search,
          trail: Cons(
            { literal, level: search.level, reason: Some(reason), },
            search.trail,
          ),
          statistics: stats,
          watch: watch_assign(search.watch, {
            literal,
            level: search.level,
            reason: Some(reason),
          }),
        }),
        stats,
      )
    }
    Decide(literal) => {
      let level : @core.Nat = Succ(search.level)
      let stats = { ..stats, decisions: Succ(stats.decisions), }
      (
        Paused({
          ..search,
          level,
          trail: Cons({ literal, level, reason: None, }, search.trail),
          watch: watch_assign(search.watch, { literal, level, reason: None, }),
          statistics: stats,
        }),
        stats,
      )
    }
    Contradiction(conflict) => {
      let stats = { ..stats, conflicts: Succ(stats.conflicts), }
      let conflict_level = highest_level(conflict, search.trail)
      match conflict_level {
        Zero =>
          (
            Unsatisfiable(Rup(@core.reverse(Cons(Nil, search.proof_rev)))),
            stats,
          )
        Succ(_) =>
          match analyze(conflict, search.trail, conflict_level) {
            None => (InvariantViolation, stats)
            Some(learned) =>
              match asserting(learned, search.trail, conflict_level) {
                None => (InvariantViolation, stats)
                Some(literal) => {
                  let level = backjump_level(learned, search.trail, literal)
                  let trail : Trail = Cons(
                    { literal, level, reason: Some(learned), },
                    backjump(search.trail, level),
                  )
                  let stats = {
                    ..stats,
                    learned: Succ(stats.learned),
                    backjumps: Succ(stats.backjumps),
                    nonchronological: match
                      @core.compare(Succ(level), search.level) {
                      Less => Succ(stats.nonchronological)
                      _ => stats.nonchronological
                    },
                  }
                  (
                    Paused({
                      database: Cons(learned, search.database),
                      variables: search.variables,
                      watch: watch_learn(search.watch, learned, literal, trail),
                      trail,
                      level,
                      proof_rev: Cons(
                        @core.map(learned, external),
                        search.proof_rev,
                      ),
                      statistics: stats,
                    }),
                    stats,
                  )
                }
              }
          }
      }
    }
  }
}

///|
fn step(search : Search) -> (Status, Statistics) {
  match search.watch {
    None => transition(search, inspect_database(search.database, search.trail))
    Some(watch) => {
      let (inspection, watch) = watch_inspect(watch, search.database)
      transition({ ..search, watch: Some(watch), }, inspection)
    }
  }
}

///|
pub fn run_measured(search : Search, fuel : @core.Nat) -> (Status, Statistics) {
  match fuel {
    Zero => (Paused(search), search.statistics)
    Succ(rest) =>
      match step(search) {
        (Paused(next), _) => run_measured(next, rest)
        result => result
      }
  }
}

///|
pub fn run(search : Search, fuel : @core.Nat) -> Status {
  let (status, _) = run_measured(search, fuel)
  status
}
