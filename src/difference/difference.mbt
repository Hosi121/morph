///|
/// left - right <= bound over mathematical integers. Variable Zero is fixed zero.
#derive(Eq, Debug)
pub(all) struct Constraint {
  left : @core.Nat
  right : @core.Nat
  bound : @exact.Integer
}

///|
pub extend Constraint with Eq::{equal, not_equal}

///|
pub extend Constraint with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Vertex {
  source : @core.Nat
  key : @binary.Binary
}

///|
pub extend Vertex with Eq::{equal, not_equal}

///|
pub extend Vertex with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Edge {
  index : @core.Nat
  from : Vertex
  to : Vertex
  bound : @exact.Integer
}

///|
pub extend Edge with Eq::{equal, not_equal}

///|
pub extend Edge with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Problem {
  constraints : @core.Chain[Constraint]
  vertices : @core.Chain[Vertex]
  edges : @core.Chain[Edge]
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn integer_zero() -> @exact.Integer {
  @exact.positive(@binary.zero())
}

///|
fn same_variable(a : @core.Nat, b : @core.Nat) -> Bool {
  match @core.compare(a, b) {
    Equal => true
    _ => false
  }
}

///|
pub fn negate(constraint : Constraint) -> Constraint {
  {
    left: constraint.right,
    right: constraint.left,
    bound: @exact.subtract(
      @exact.negate(constraint.bound),
      @exact.positive(@binary.one()),
    ),
  }
}

///|
pub fn problem(constraints : @core.Chain[Constraint]) -> Problem {
  let zero = Vertex::{ source: Zero, key: @binary.zero(), }
  let initial = @avl.put(@avl.empty(), zero.key, zero, @binary.compare)
  let (vertices, reversed, _) = @core.fold_left(
    constraints,
    (initial, @core.Nil, @core.Zero),
    fn(state, constraint) {
      let (vertices, reversed, index) = state
      let from = Vertex::{
        source: constraint.right,
        key: @binary.from_nat(constraint.right),
      }
      let to = Vertex::{
        source: constraint.left,
        key: @binary.from_nat(constraint.left),
      }
      let vertices = @avl.put(vertices, from.key, from, @binary.compare)
      let vertices = @avl.put(vertices, to.key, to, @binary.compare)
      let edge = Edge::{ index, from, to, bound: constraint.bound, }
      (vertices, Cons(edge, reversed), Succ(index))
    },
  )
  {
    constraints,
    vertices: @core.map(@avl.entries(vertices), fn(pair) {
      let (_, vertex) = pair
      vertex
    }),
    edges: @core.reverse(reversed),
  }
}

///|
pub fn constraints(problem : Problem) -> @core.Chain[Constraint] {
  problem.constraints
}

///|
#derive(Eq, Debug)
pub struct Solution {
  values : @core.Chain[(@core.Nat, @exact.Integer)]
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
fn lookup(
  values : @core.Chain[(@core.Nat, @exact.Integer)],
  variable : @core.Nat,
) -> @exact.Integer? {
  match values {
    Nil => None
    Cons((key, value), rest) =>
      match same_variable(key, variable) {
        true => Some(value)
        false => lookup(rest, variable)
      }
  }
}

///|
pub fn values(solution : Solution) -> @core.Chain[(@core.Nat, @exact.Integer)] {
  solution.values
}

///|
pub fn value(solution : Solution, variable : @core.Nat) -> @exact.Integer? {
  lookup(solution.values, variable)
}

///|
pub fn holds(
  constraint : Constraint,
  values : @core.Chain[(@core.Nat, @exact.Integer)],
) -> Bool {
  match (lookup(values, constraint.left), lookup(values, constraint.right)) {
    (Some(left), Some(right)) =>
      match @exact.compare(@exact.subtract(left, right), constraint.bound) {
        Greater => false
        _ => true
      }
    _ => false
  }
}

///|
/// Validate all vertices, origin, uniqueness and each original inequality.
pub fn check_values(
  problem : Problem,
  raw : @core.Chain[(@core.Nat, @exact.Integer)],
) -> Solution? {
  fn unique(rest : @core.Chain[(@core.Nat, @exact.Integer)]) -> Bool {
    match rest {
      Nil => true
      Cons((variable, _), tail) =>
        @core.any(problem.vertices, fn(vertex) {
          same_variable(vertex.source, variable)
        }) &&
        !@core.any(tail, fn(pair) {
          let (other, _) = pair
          same_variable(variable, other)
        }) &&
        unique(tail)
    }
  }
  let complete = @core.all(problem.vertices, fn(vertex) {
    match lookup(raw, vertex.source) {
      None => false
      Some(_) => true
    }
  })
  let anchored = match lookup(raw, Zero) {
    None => false
    Some(origin) =>
      match @exact.compare(origin, integer_zero()) {
        Equal => true
        _ => false
      }
  }
  match
    unique(raw) &&
    complete &&
    anchored &&
    @core.all(problem.constraints, fn(c) { holds(c, raw) }) {
    true => Some({ values: raw, })
    false => None
  }
}

///|
pub fn check_solution(problem : Problem, solution : Solution) -> Bool {
  match check_values(problem, solution.values) {
    Some(_) => true
    None => false
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Cycle {
  indices : @core.Chain[@core.Nat]
}

///|
pub extend Cycle with Eq::{equal, not_equal}

///|
pub extend Cycle with Debug::{to_repr}

///|
/// Check a closed directed walk with strictly negative total weight.
/// No Bellman-Ford state, predecessor map or distance values are trusted.
pub fn check_cycle(problem : Problem, cycle : Cycle) -> Bool {
  fn walk(
    rest : @core.Chain[@core.Nat],
    current : @core.Nat,
    start : @core.Nat,
    weight : @exact.Integer,
  ) -> Bool {
    match rest {
      Nil =>
        match @exact.compare(weight, integer_zero()) {
          Less => same_variable(current, start)
          _ => false
        }
      Cons(index, tail) =>
        match @core.nth(problem.constraints, index) {
          None => false
          Some(constraint) =>
            same_variable(current, constraint.right) &&
            walk(
              tail,
              constraint.left,
              start,
              @exact.add(weight, constraint.bound),
            )
        }
    }
  }
  match cycle.indices {
    Nil => false
    Cons(index, _) =>
      match @core.nth(problem.constraints, index) {
        None => false
        Some(first) =>
          walk(cycle.indices, first.right, first.right, integer_zero())
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Outcome {
  Feasible(Solution)
  Infeasible(Cycle)
  InvariantViolation
}

///|
pub extend Outcome with Eq::{equal, not_equal}

///|
pub extend Outcome with Debug::{to_repr}

///|
priv struct State {
  distances : @avl.OrderedMap[@binary.Binary, @exact.Integer]
  predecessors : @avl.OrderedMap[@binary.Binary, Edge]
  changed : Vertex?
}

///|
fn distance(state : State, key : @binary.Binary) -> @exact.Integer {
  match @avl.lookup(state.distances, key, @binary.compare) {
    None => integer_zero()
    Some(value) => value
  }
}

///|
fn relax(state : State, edge : Edge) -> State {
  let candidate = @exact.add(distance(state, edge.from.key), edge.bound)
  match @exact.compare(candidate, distance(state, edge.to.key)) {
    Less =>
      {
        distances: @avl.put(
          state.distances,
          edge.to.key,
          candidate,
          @binary.compare,
        ),
        predecessors: @avl.put(
          state.predecessors,
          edge.to.key,
          edge,
          @binary.compare,
        ),
        changed: Some(edge.to),
      }
    _ => state
  }
}

///|
fn negative_cycle(problem : Problem, state : State, vertex : Vertex) -> Cycle? {
  fn rewind(remaining : @core.Nat, vertex : Vertex) -> Vertex? {
    match remaining {
      Zero => Some(vertex)
      Succ(rest) =>
        match @avl.lookup(state.predecessors, vertex.key, @binary.compare) {
          None => None
          Some(edge) => rewind(rest, edge.from)
        }
    }
  }
  match rewind(@core.length(problem.vertices), vertex) {
    None => None
    Some(start) => {
      fn collect(
        remaining : @core.Nat,
        current : Vertex,
        indices : @core.Chain[@core.Nat],
      ) -> Cycle? {
        match (indices, @binary.compare(current.key, start.key)) {
          (Cons(_, _), Equal) => Some({ indices, })
          _ =>
            match remaining {
              Zero => None
              Succ(rest) =>
                match
                  @avl.lookup(state.predecessors, current.key, @binary.compare) {
                  None => None
                  Some(edge) =>
                    collect(rest, edge.from, Cons(edge.index, indices))
                }
            }
        }
      }
      collect(Succ(@core.length(problem.vertices)), start, Nil)
    }
  }
}

///|
/// Bellman-Ford with an implicit zero-cost root to every vertex.
pub fn solve(problem : Problem) -> Outcome {
  fn feasible(state : State) -> Outcome {
    let origin = distance(state, @binary.zero())
    let raw = @core.map(problem.vertices, fn(vertex) {
      (vertex.source, @exact.subtract(distance(state, vertex.key), origin))
    })
    match check_values(problem, raw) {
      None => InvariantViolation
      Some(solution) => Feasible(solution)
    }
  }
  fn iterate(remaining : @core.Nat, state : State) -> Outcome {
    match remaining {
      Zero =>
        match state.changed {
          None => feasible(state)
          Some(vertex) =>
            match negative_cycle(problem, state, vertex) {
              None => InvariantViolation
              Some(cycle) =>
                match check_cycle(problem, cycle) {
                  true => Infeasible(cycle)
                  false => InvariantViolation
                }
            }
        }
      Succ(rest) => {
        let initial = State::{ ..state, changed: None, }
        let next = @core.fold_left(problem.edges, initial, relax)
        match next.changed {
          None => feasible(next)
          Some(_) => iterate(rest, next)
        }
      }
    }
  }
  iterate(@core.length(problem.vertices), {
    distances: @avl.empty(),
    predecessors: @avl.empty(),
    changed: None,
  })
}
