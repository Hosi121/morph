///|
fn terminal_operation(operation : Operation, left : Bool, right : Bool) -> Bool {
  match operation {
    Conjunction => left && right
    Disjunction => left || right
    Exclusive =>
      match (left, right) {
        (true, false) | (false, true) => true
        _ => false
      }
  }
}

///|
fn read_node(manager : Manager, edge : Edge) -> Node? {
  match edge {
    Terminal(_) => None
    Decision(id) => lookup(manager.nodes, @binary.bits(id))
  }
}

///|
fn cofactor(node : Node?, edge : Edge, rank : @core.Nat) -> (Edge, Edge) {
  match node {
    Some(node) =>
      match @core.compare(node.variable.rank, rank) {
        Equal => (node.low, node.high)
        _ => (edge, edge)
      }
    None => (edge, edge)
  }
}

///|
fn apply_roots(
  operation : Operation,
  left : Edge,
  right : Edge,
  manager : Manager,
) -> (Edge, Manager)? {
  match (left, right) {
    (Terminal(a), Terminal(b)) =>
      Some((Terminal(terminal_operation(operation, a, b)), manager))
    _ => {
      let op_key = operation_key(operation)
      let left_key = edge_key(left)
      let right_key = edge_key(right)
      match triple_get(manager.memo, op_key, left_key, right_key) {
        Some(edge) => Some((edge, manager))
        None => {
          let left_node = read_node(manager, left)
          let right_node = read_node(manager, right)
          let variable = match (left_node, right_node) {
            (None, None) => None
            (Some(node), None) | (None, Some(node)) => Some(node.variable)
            (Some(a), Some(b)) =>
              match @core.compare(a.variable.rank, b.variable.rank) {
                Greater => Some(b.variable)
                _ => Some(a.variable)
              }
          }
          match variable {
            None => None
            Some(variable) => {
              let (a_low, a_high) = cofactor(left_node, left, variable.rank)
              let (b_low, b_high) = cofactor(right_node, right, variable.rank)
              match apply_roots(operation, a_low, b_low, manager) {
                None => None
                Some((low, manager)) =>
                  match apply_roots(operation, a_high, b_high, manager) {
                    None => None
                    Some((high, manager)) => {
                      let (root, manager) = make_node(
                        manager, variable, low, high,
                      )
                      Some(
                        (
                          root,
                          {
                            ..manager,
                            memo: triple_put(
                              manager.memo,
                              op_key,
                              left_key,
                              right_key,
                              root,
                            ),
                          },
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
  }
}

///|
fn build(expression : @circuit.Expr, manager : Manager) -> (Edge, Manager)? {
  match expression {
    Constant(value) => Some((Terminal(value), manager))
    Variable(source) =>
      match lookup(manager.variables, @binary.bits(@binary.from_nat(source))) {
        None => None
        Some(variable) =>
          Some(make_node(manager, variable, Terminal(false), Terminal(true)))
      }
    Negation(expression) =>
      match build(expression, manager) {
        None => None
        Some((root, manager)) =>
          apply_roots(Exclusive, root, Terminal(true), manager)
      }
    Conjunction(left, right)
    | Disjunction(left, right)
    | Exclusive(left, right) => {
      let operation = match expression {
        Conjunction(_, _) => Conjunction
        Disjunction(_, _) => Disjunction
        _ => Exclusive
      }
      match build(left, manager) {
        None => None
        Some((left, manager)) =>
          match build(right, manager) {
            None => None
            Some((right, manager)) =>
              apply_roots(operation, left, right, manager)
          }
      }
    }
    Select(condition, when_true, when_false) =>
      match build(condition, manager) {
        None => None
        Some((condition, manager)) =>
          match build(when_true, manager) {
            None => None
            Some((when_true, manager)) =>
              match build(when_false, manager) {
                None => None
                Some((when_false, manager)) =>
                  match
                    apply_roots(Exclusive, condition, Terminal(true), manager) {
                    None => None
                    Some((negative, manager)) =>
                      match
                        apply_roots(Conjunction, condition, when_true, manager) {
                        None => None
                        Some((left, manager)) =>
                          match
                            apply_roots(
                              Conjunction,
                              negative,
                              when_false,
                              manager,
                            ) {
                            None => None
                            Some((right, manager)) =>
                              apply_roots(Disjunction, left, right, manager)
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
/// Order must contain each source variable exactly once. Additional variables
/// are allowed. Repeated labels and expressions using absent labels fail.
pub fn compile(
  expression : @circuit.Expr,
  order : @core.Chain[@core.Nat],
) -> Diagram? {
  match prepare(order) {
    None => None
    Some(manager) =>
      match build(expression, manager) {
        None => None
        Some((root, manager)) => Some({ root, manager, })
      }
  }
}

///|
/// Import with a memo scoped to exactly one source manager. Each binary apply
/// starts a fresh import memo for its other input, even when IDs coincide.
fn import_root(
  source : Manager,
  edge : Edge,
  destination : Manager,
  memo : Trie[Edge],
) -> (Edge, Manager, Trie[Edge])? {
  match edge {
    Terminal(_) => Some((edge, destination, memo))
    Decision(id) =>
      match lookup(memo, @binary.bits(id)) {
        Some(edge) => Some((edge, destination, memo))
        None =>
          match lookup(source.nodes, @binary.bits(id)) {
            None => None
            Some(node) =>
              match import_root(source, node.low, destination, memo) {
                None => None
                Some((low, destination, memo)) =>
                  match import_root(source, node.high, destination, memo) {
                    None => None
                    Some((high, destination, memo)) => {
                      let (root, destination) = make_node(
                        destination,
                        node.variable,
                        low,
                        high,
                      )
                      Some(
                        (
                          root,
                          destination,
                          insert(memo, @binary.bits(id), root),
                        ),
                      )
                    }
                  }
              }
          }
      }
  }
}

///|
/// Different variable orders are rejected. Both operands are imported into a
/// new manager before any node identities or operation memo entries are used.
pub fn apply(
  operation : Operation,
  left : Diagram,
  right : Diagram,
) -> Diagram? {
  match same_order(left.manager.order, right.manager.order) {
    false => None
    true => {
      let manager = fresh_manager(left.manager.order, left.manager.variables)
      match import_root(left.manager, left.root, manager, Empty) {
        None => None
        Some((left_root, manager, _)) =>
          match import_root(right.manager, right.root, manager, Empty) {
            None => None
            Some((right_root, manager, _)) =>
              match apply_roots(operation, left_root, right_root, manager) {
                None => None
                Some((root, manager)) => Some({ root, manager, })
              }
          }
      }
    }
  }
}

///|
pub fn negate(diagram : Diagram) -> Diagram? {
  match apply_roots(Exclusive, diagram.root, Terminal(true), diagram.manager) {
    None => None
    Some((root, manager)) => Some({ root, manager, })
  }
}

///|
pub fn equivalent(left : Diagram, right : Diagram) -> Bool? {
  match apply(Exclusive, left, right) {
    None => None
    Some(diagram) => Some(same_edge(diagram.root, Terminal(false)))
  }
}
