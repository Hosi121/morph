///|
/// Positive, sequential addition IDs and positive unit-propagation references.
/// Original CNF clause occurrences retain IDs starting at Binary one.
#derive(Eq, Debug)
pub(all) struct Step {
  id : @binary.Binary
  clause : @sat.Clause
  hints : @core.Chain[@binary.Binary]
}

///|
pub extend Step with Eq::{equal, not_equal}

///|
pub extend Step with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  steps : @core.Chain[Step]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
priv enum Trie[A] {
  Empty
  Branch(A?, Trie[A], Trie[A])
}

///|
fn[A] get(trie : Trie[A], key : @core.Chain[Bool]) -> A? {
  match (trie, key) {
    (Empty, _) => None
    (Branch(value, _, _), Nil) => value
    (Branch(_, left, _), Cons(false, rest)) => get(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => get(right, rest)
  }
}

///|
fn[A] put(trie : Trie[A], key : @core.Chain[Bool], value : A) -> Trie[A] {
  match (trie, key) {
    (Empty, Nil) => Branch(Some(value), Empty, Empty)
    (Empty, Cons(false, rest)) => Branch(None, put(Empty, rest, value), Empty)
    (Empty, Cons(true, rest)) => Branch(None, Empty, put(Empty, rest, value))
    (Branch(_, left, right), Nil) => Branch(Some(value), left, right)
    (Branch(found, left, right), Cons(false, rest)) =>
      Branch(found, put(left, rest, value), right)
    (Branch(found, left, right), Cons(true, rest)) =>
      Branch(found, left, put(right, rest, value))
  }
}

///|
priv struct Literal {
  key : @binary.Binary
  source : @sat.Literal
}

///|
type Lits = @core.Chain[Literal]

///|
priv enum Clause {
  Terms(Lits)
  Tautology
}

///|
priv struct Entry {
  id : @binary.Binary
  clause : Clause
}

///|
struct Database {
  entries : @core.Chain[Entry]
  indexed : Trie[Clause]
  next : @binary.Binary
}

///|
/// Prepared input normalizes literal repetitions without changing clause IDs.
/// Tautological original occurrences retain their positions and IDs.
pub struct Input {
  database : Database
}

///|
fn literal(value : @sat.Literal) -> Literal {
  { key: @binary.from_nat(value.variable), source: value, }
}

///|
fn same_polarity(left : Literal, right : Literal) -> Bool {
  match (left.source.positive, right.source.positive) {
    (true, true) | (false, false) => true
    _ => false
  }
}

///|
fn insert_literal(value : Literal, rest : Lits) -> Clause {
  match rest {
    Nil => Terms(Cons(value, Nil))
    Cons(first, tail) =>
      match @binary.compare(value.key, first.key) {
        Less => Terms(Cons(value, rest))
        Equal =>
          match same_polarity(value, first) {
            true => Terms(rest)
            false => Tautology
          }
        Greater =>
          match insert_literal(value, tail) {
            Tautology => Tautology
            Terms(rest) => Terms(Cons(first, rest))
          }
      }
  }
}

///|
fn normalize(source : @sat.Clause) -> Clause {
  fn visit(rest : @sat.Clause, result : Lits) -> Clause {
    match rest {
      Nil => Terms(result)
      Cons(value, tail) =>
        match insert_literal(literal(value), result) {
          Tautology => Tautology
          Terms(result) => visit(tail, result)
        }
    }
  }
  visit(source, Nil)
}

///|
fn add(database : Database, id : @binary.Binary, clause : Clause) -> Database {
  {
    entries: Cons({ id, clause, }, database.entries),
    indexed: put(database.indexed, @binary.bits(id), clause),
    next: @binary.successor(id),
  }
}

///|
pub fn prepare(cnf : @sat.Cnf) -> Input {
  let initial = Database::{ entries: Nil, indexed: Empty, next: @binary.one(), }
  let database = @core.fold_left(cnf, initial, fn(database, clause) {
    add(database, database.next, normalize(clause))
  })
  { database: { ..database, entries: @core.reverse(database.entries), }, }
}

///|
pub fn first_derived_id(input : Input) -> @binary.Binary {
  input.database.next
}

///|
pub fn hint_count(certificate : Certificate) -> @core.Nat {
  @core.fold_left(certificate.steps, Zero, fn(count, step) {
    @core.fold_left(step.hints, count, fn(count, _) { Succ(count) })
  })
}

///|
pub fn erase(certificate : Certificate) -> @cdcl.Proof {
  @cdcl.Rup(@core.map(certificate.steps, fn(step) { step.clause }))
}
