///|
priv enum Trie[A] {
  Empty
  Branch(A?, Trie[A], Trie[A])
}

///|
fn[A] lookup(trie : Trie[A], key : @core.Chain[Bool]) -> A? {
  match (trie, key) {
    (Empty, _) => None
    (Branch(value, _, _), Nil) => value
    (Branch(_, left, _), Cons(false, rest)) => lookup(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => lookup(right, rest)
  }
}

///|
fn[A] insert(trie : Trie[A], key : @core.Chain[Bool], value : A) -> Trie[A] {
  match (trie, key) {
    (Empty, Nil) => Branch(Some(value), Empty, Empty)
    (Empty, Cons(false, rest)) =>
      Branch(None, insert(Empty, rest, value), Empty)
    (Empty, Cons(true, rest)) => Branch(None, Empty, insert(Empty, rest, value))
    (Branch(_, left, right), Nil) => Branch(Some(value), left, right)
    (Branch(found, left, right), Cons(false, rest)) =>
      Branch(found, insert(left, rest, value), right)
    (Branch(found, left, right), Cons(true, rest)) =>
      Branch(found, left, insert(right, rest, value))
  }
}

///|
/// IDs have meaning only within their owning Manager. No Eq instance or
/// public constructor exposes ID equality as Diagram equivalence.
enum Edge {
  Terminal(Bool)
  Decision(@binary.Binary)
}

///|
fn same_edge(left : Edge, right : Edge) -> Bool {
  match (left, right) {
    (Terminal(true), Terminal(true)) | (Terminal(false), Terminal(false)) =>
      true
    (Decision(a), Decision(b)) => @binary.compare(a, b) is Equal
    _ => false
  }
}

///|
fn edge_key(edge : Edge) -> @core.Chain[Bool] {
  match edge {
    Terminal(value) => Cons(false, Cons(value, Nil))
    Decision(id) => Cons(true, @binary.bits(id))
  }
}

///|
type Triple = Trie[Trie[Trie[Edge]]]

///|
fn triple_get(
  table : Triple,
  first : @core.Chain[Bool],
  second : @core.Chain[Bool],
  third : @core.Chain[Bool],
) -> Edge? {
  match lookup(table, first) {
    None => None
    Some(middle) =>
      match lookup(middle, second) {
        None => None
        Some(last) => lookup(last, third)
      }
  }
}

///|
fn triple_put(
  table : Triple,
  first : @core.Chain[Bool],
  second : @core.Chain[Bool],
  third : @core.Chain[Bool],
  value : Edge,
) -> Triple {
  let middle = match lookup(table, first) {
    None => Empty
    Some(found) => found
  }
  let last = match lookup(middle, second) {
    None => Empty
    Some(found) => found
  }
  insert(table, first, insert(middle, second, insert(last, third, value)))
}

///|
priv struct Variable {
  source : @core.Nat
  key : @binary.Binary
  rank : @core.Nat
  rank_key : @binary.Binary
}

///|
priv struct Node {
  variable : Variable
  low : Edge
  high : Edge
}

///|
struct Manager {
  order : @core.Chain[Variable]
  variables : Trie[Variable]
  nodes : Trie[Node]
  unique : Triple
  memo : Triple
  next : @binary.Binary
}

///|
/// A self-contained persistent ROBDD. Node identities are scoped to this
/// Diagram's manager; callers compare functions through equivalent.
pub struct Diagram {
  manager : Manager
  root : Edge
}

///|
#derive(Eq, Debug)
pub(all) enum Operation {
  Conjunction
  Disjunction
  Exclusive
}

///|
pub extend Operation with Eq::{equal, not_equal}

///|
pub extend Operation with Debug::{to_repr}

///|
fn operation_key(operation : Operation) -> @core.Chain[Bool] {
  match operation {
    Conjunction => Nil
    Disjunction => Cons(false, Nil)
    Exclusive => Cons(true, Nil)
  }
}

///|
fn fresh_manager(
  order : @core.Chain[Variable],
  variables : Trie[Variable],
) -> Manager {
  {
    order,
    variables,
    nodes: Empty,
    unique: Empty,
    memo: Empty,
    next: @binary.zero(),
  }
}

///|
fn prepare(labels : @core.Chain[@core.Nat]) -> Manager? {
  fn visit(
    labels : @core.Chain[@core.Nat],
    rank : @core.Nat,
    rank_key : @binary.Binary,
    reversed : @core.Chain[Variable],
    variables : Trie[Variable],
  ) -> Manager? {
    match labels {
      Nil => Some(fresh_manager(@core.reverse(reversed), variables))
      Cons(source, rest) => {
        let key = @binary.from_nat(source)
        match lookup(variables, @binary.bits(key)) {
          Some(_) => None
          None => {
            let variable = { source, key, rank, rank_key, }
            visit(
              rest,
              Succ(rank),
              @binary.successor(rank_key),
              Cons(variable, reversed),
              insert(variables, @binary.bits(key), variable),
            )
          }
        }
      }
    }
  }
  visit(labels, Zero, @binary.zero(), Nil, Empty)
}

///|
fn make_node(
  manager : Manager,
  variable : Variable,
  low : Edge,
  high : Edge,
) -> (Edge, Manager) {
  match same_edge(low, high) {
    true => (low, manager)
    false => {
      let rank = @binary.bits(variable.rank_key)
      let low_key = edge_key(low)
      let high_key = edge_key(high)
      match triple_get(manager.unique, rank, low_key, high_key) {
        Some(edge) => (edge, manager)
        None => {
          let edge = Decision(manager.next)
          let node = { variable, low, high, }
          (
            edge,
            {
              ..manager,
              nodes: insert(manager.nodes, @binary.bits(manager.next), node),
              unique: triple_put(manager.unique, rank, low_key, high_key, edge),
              next: @binary.successor(manager.next),
            },
          )
        }
      }
    }
  }
}

///|
fn same_order(
  left : @core.Chain[Variable],
  right : @core.Chain[Variable],
) -> Bool {
  match (left, right) {
    (Nil, Nil) => true
    (Cons(a, at), Cons(b, bt)) =>
      @binary.compare(a.key, b.key) is Equal && same_order(at, bt)
    _ => false
  }
}

///|
pub fn order(diagram : Diagram) -> @core.Chain[@core.Nat] {
  @core.map(diagram.manager.order, fn(variable) { variable.source })
}
