///|
fn bindings(model : @sat.Model, values : Trie[Bool]) -> Trie[Bool]? {
  match model {
    Nil => Some(values)
    Cons(literal, rest) => {
      let key = @binary.bits(@binary.from_nat(literal.variable))
      match lookup(values, key) {
        None => bindings(rest, insert(values, key, literal.positive))
        Some(old) =>
          match (old, literal.positive) {
            (true, true) | (false, false) => bindings(rest, values)
            _ => None
          }
      }
    }
  }
}

///|
/// A consistent partial model is sufficient when every tested BDD variable is
/// assigned. Missing tested variables and contradictory bindings return None.
pub fn evaluate(diagram : Diagram, model : @sat.Model) -> Bool? {
  fn walk(edge : Edge, values : Trie[Bool]) -> Bool? {
    match edge {
      Terminal(value) => Some(value)
      Decision(id) =>
        match lookup(diagram.manager.nodes, @binary.bits(id)) {
          None => None
          Some(node) =>
            match lookup(values, @binary.bits(node.variable.key)) {
              None => None
              Some(false) => walk(node.low, values)
              Some(true) => walk(node.high, values)
            }
        }
    }
  }
  match bindings(model, Empty) {
    None => None
    Some(values) => walk(diagram.root, values)
  }
}

///|
fn restrict_root(
  edge : Edge,
  target : Variable,
  value : Bool,
  manager : Manager,
  memo : Trie[Edge],
) -> (Edge, Manager, Trie[Edge])? {
  match edge {
    Terminal(_) => Some((edge, manager, memo))
    Decision(id) =>
      match lookup(memo, @binary.bits(id)) {
        Some(result) => Some((result, manager, memo))
        None =>
          match lookup(manager.nodes, @binary.bits(id)) {
            None => None
            Some(node) =>
              match @core.compare(node.variable.rank, target.rank) {
                Greater =>
                  Some((edge, manager, insert(memo, @binary.bits(id), edge)))
                Equal => {
                  let result = match value {
                    false => node.low
                    true => node.high
                  }
                  Some(
                    (result, manager, insert(memo, @binary.bits(id), result)),
                  )
                }
                Less =>
                  match restrict_root(node.low, target, value, manager, memo) {
                    None => None
                    Some((low, manager, memo)) =>
                      match
                        restrict_root(node.high, target, value, manager, memo) {
                        None => None
                        Some((high, manager, memo)) => {
                          let (result, manager) = make_node(
                            manager,
                            node.variable,
                            low,
                            high,
                          )
                          Some(
                            (
                              result,
                              manager,
                              insert(memo, @binary.bits(id), result),
                            ),
                          )
                        }
                      }
                  }
              }
          }
      }
  }
}

///|
/// Substitute one declared variable. The declared order/domain is retained,
/// even when substitution removes every decision on that variable.
pub fn restrict(diagram : Diagram, literal : @sat.Literal) -> Diagram? {
  let key = @binary.bits(@binary.from_nat(literal.variable))
  match lookup(diagram.manager.variables, key) {
    None => None
    Some(target) =>
      match
        restrict_root(
          diagram.root,
          target,
          literal.positive,
          diagram.manager,
          Empty,
        ) {
        None => None
        Some((root, manager, _)) => Some({ root, manager, })
      }
  }
}

///|
/// Return a total assignment over the declared variable order, choosing false
/// on skipped variables. False diagrams have no model.
pub fn pick_model(diagram : Diagram) -> @sat.Model? {
  fn walk(edge : Edge, values : Trie[Bool]) -> Trie[Bool]? {
    match edge {
      Terminal(false) => None
      Terminal(true) => Some(values)
      Decision(id) =>
        match lookup(diagram.manager.nodes, @binary.bits(id)) {
          None => None
          Some(node) =>
            match same_edge(node.low, Terminal(false)) {
              true =>
                walk(
                  node.high,
                  insert(values, @binary.bits(node.variable.key), true),
                )
              false =>
                walk(
                  node.low,
                  insert(values, @binary.bits(node.variable.key), false),
                )
            }
        }
    }
  }
  match walk(diagram.root, Empty) {
    None => None
    Some(values) =>
      Some(
        @core.map(diagram.manager.order, fn(variable) {
          let positive = match lookup(values, @binary.bits(variable.key)) {
            None => false
            Some(value) => value
          }
          @sat.Literal::{ variable: variable.source, positive, }
        }),
      )
  }
}

///|
/// Count only reachable nonterminal decisions, excluding terminals and cached
/// intermediate nodes no longer reachable from this Diagram's root.
pub fn node_count(diagram : Diagram) -> @core.Nat? {
  fn walk(
    edge : Edge,
    seen : Trie[Unit],
    count : @core.Nat,
  ) -> (Trie[Unit], @core.Nat)? {
    match edge {
      Terminal(_) => Some((seen, count))
      Decision(id) => {
        let key = @binary.bits(id)
        match lookup(seen, key) {
          Some(_) => Some((seen, count))
          None =>
            match lookup(diagram.manager.nodes, key) {
              None => None
              Some(node) =>
                match walk(node.low, insert(seen, key, ()), Succ(count)) {
                  None => None
                  Some((seen, count)) => walk(node.high, seen, count)
                }
            }
        }
      }
    }
  }
  match walk(diagram.root, Empty, Zero) {
    None => None
    Some((_, count)) => Some(count)
  }
}

///|
/// Includes unique decisions created for intermediate operations and cached
/// roots. This is not the size of the final reachable ROBDD.
pub fn allocated_count(diagram : Diagram) -> @binary.Binary {
  diagram.manager.next
}

///|
fn same_variable(left : Variable, right : Variable) -> Bool {
  @core.compare(left.source, right.source) is Equal &&
  @core.compare(left.rank, right.rank) is Equal &&
  @binary.compare(left.key, right.key) is Equal &&
  @binary.compare(left.rank_key, right.rank_key) is Equal
}

///|
/// Structural checker for declared order, reduction, unique-table membership,
/// and acyclic increasing-rank edges. This does not prove expression semantics.
pub fn valid(diagram : Diagram) -> Bool {
  let manager = diagram.manager
  fn order_valid(
    order : @core.Chain[Variable],
    rank : @core.Nat,
    rank_key : @binary.Binary,
    seen : Trie[Unit],
  ) -> Bool {
    match order {
      Nil => true
      Cons(variable, rest) => {
        let key = @binary.bits(variable.key)
        let coherent = @core.compare(variable.rank, rank) is Equal &&
          @binary.compare(variable.rank_key, rank_key) is Equal &&
          @binary.compare(variable.key, @binary.from_nat(variable.source))
          is Equal
        match (lookup(seen, key), lookup(manager.variables, key), coherent) {
          (None, Some(expected), true) =>
            same_variable(variable, expected) &&
            order_valid(
              rest,
              Succ(rank),
              @binary.successor(rank_key),
              insert(seen, key, ()),
            )
          _ => false
        }
      }
    }
  }
  fn child_valid(
    parent : @binary.Binary,
    rank : @core.Nat,
    child : Edge,
  ) -> Bool {
    match child {
      Terminal(_) => true
      Decision(id) =>
        match lookup(manager.nodes, @binary.bits(id)) {
          None => false
          Some(node) =>
            @binary.compare(id, parent) is Less &&
            @core.compare(node.variable.rank, rank) is Greater
        }
    }
  }
  fn walk(edge : Edge, seen : Trie[Unit]) -> Trie[Unit]? {
    match edge {
      Terminal(_) => Some(seen)
      Decision(id) => {
        let key = @binary.bits(id)
        match lookup(seen, key) {
          Some(_) => Some(seen)
          None =>
            match lookup(manager.nodes, key) {
              None => None
              Some(node) => {
                let info = node.variable
                let ordered = match @core.nth(manager.order, info.rank) {
                  None => false
                  Some(expected) => same_variable(info, expected)
                }
                let unique = match
                  triple_get(
                    manager.unique,
                    @binary.bits(info.rank_key),
                    edge_key(node.low),
                    edge_key(node.high),
                  ) {
                  None => false
                  Some(found) => same_edge(found, edge)
                }
                let coherent = ordered &&
                  unique &&
                  !same_edge(node.low, node.high) &&
                  @binary.compare(id, manager.next) is Less &&
                  child_valid(id, info.rank, node.low) &&
                  child_valid(id, info.rank, node.high)
                match coherent {
                  false => None
                  true =>
                    match walk(node.low, insert(seen, key, ())) {
                      None => None
                      Some(seen) => walk(node.high, seen)
                    }
                }
              }
            }
        }
      }
    }
  }
  order_valid(manager.order, Zero, @binary.zero(), Empty) &&
  walk(diagram.root, Empty) is Some(_)
}
