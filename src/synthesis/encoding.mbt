///|
pub struct Choice {
  literal : @sat.Literal
  gate : Nand
}

///|
priv struct Row {
  inputs : @core.Chain[Bool]
  values : @core.Chain[@sat.Literal]
}

///|
priv struct Builder {
  next : @core.Nat
  clauses_rev : @sat.Cnf
}

///|
priv enum Signal {
  Fixed(Bool)
  Atom(@sat.Literal)
}

///|
fn fresh(builder : Builder) -> (@sat.Literal, Builder) {
  (
    @sat.Literal::{ variable: builder.next, positive: true, },
    { ..builder, next: Succ(builder.next), },
  )
}

///|
fn invert(signal : Signal) -> Signal {
  match signal {
    Fixed(value) => Fixed(!value)
    Atom(value) => Atom(@sat.negate(value))
  }
}

///|
fn emit(signals : @core.Chain[Signal], builder : Builder) -> Builder {
  fn simplify(
    rest : @core.Chain[Signal],
    literals : @sat.Clause,
  ) -> @sat.Clause? {
    match rest {
      Nil => Some(@core.reverse(literals))
      Cons(Fixed(true), _) => None
      Cons(Fixed(false), rest) => simplify(rest, literals)
      Cons(Atom(literal), rest) => simplify(rest, Cons(literal, literals))
    }
  }
  match simplify(signals, Nil) {
    None => builder
    Some(clause) =>
      { ..builder, clauses_rev: Cons(clause, builder.clauses_rev), }
  }
}

///|
fn one_hot(literals : @core.Chain[@sat.Literal], builder : Builder) -> Builder {
  let builder = emit(@core.map(literals, fn(x) { Atom(x) }), builder)
  fn pairs(rest : @core.Chain[@sat.Literal], builder : Builder) -> Builder {
    match rest {
      Nil => builder
      Cons(first, tail) => {
        let builder = @core.fold_left(tail, builder, fn(builder, other) {
          emit(
            Cons(Atom(@sat.negate(first)), Cons(Atom(@sat.negate(other)), Nil)),
            builder,
          )
        })
        pairs(tail, builder)
      }
    }
  }
  pairs(literals, builder)
}

///|
fn wires(inputs : @core.Nat, previous : @core.Nat) -> @core.Chain[Wire] {
  @core.append(
    @core.map(@core.indices(inputs), fn(index) { Input(index) }),
    @core.map(@core.indices(previous), fn(index) { Gate(index) }),
  )
}

///|
fn options(available : @core.Chain[Wire]) -> @core.Chain[Nand] {
  match available {
    Nil => Nil
    Cons(first, rest) =>
      @core.append(
        @core.map(available, fn(other) { Nand::{ left: first, right: other, } }),
        options(rest),
      )
  }
}

///|
fn allocate_choices(
  gates : @core.Chain[Nand],
  builder : Builder,
) -> (@core.Chain[Choice], Builder) {
  let (reversed, builder) = @core.fold_left(gates, (@core.Nil, builder), fn(
    state,
    gate,
  ) {
    let (reversed, builder) = state
    let (literal, builder) = fresh(builder)
    (Cons(Choice::{ literal, gate, }, reversed), builder)
  })
  (@core.reverse(reversed), builder)
}

///|
fn signal(wire : Wire, row : Row) -> Signal? {
  match wire {
    Input(index) =>
      match @core.nth(row.inputs, index) {
        None => None
        Some(value) => Some(Fixed(value))
      }
    Gate(index) =>
      match @core.nth(row.values, index) {
        None => None
        Some(value) => Some(Atom(value))
      }
  }
}

///|
fn gate_constraints(
  choices : @core.Chain[Choice],
  row : Row,
  result : @sat.Literal,
  builder : Builder,
) -> Builder {
  @core.fold_left(choices, builder, fn(builder, choice) {
    match (signal(choice.gate.left, row), signal(choice.gate.right, row)) {
      (Some(a), Some(b)) => {
        let disable = Atom(@sat.negate(choice.literal))
        let y = Atom(result)
        let builder = emit(Cons(disable, Cons(a, Cons(y, Nil))), builder)
        let builder = emit(Cons(disable, Cons(b, Cons(y, Nil))), builder)
        emit(
          Cons(disable, Cons(invert(a), Cons(invert(b), Cons(invert(y), Nil)))),
          builder,
        )
      }
      _ => emit(Nil, builder)
    }
  })
}

///|
fn allocate_stage(
  inputs : @core.Nat,
  previous : @core.Nat,
  rows : @core.Chain[Row],
  builder : Builder,
) -> (@core.Chain[Choice], @core.Chain[Row], Builder) {
  let (choices, builder) = allocate_choices(
    options(wires(inputs, previous)),
    builder,
  )
  let builder = one_hot(
    @core.map(choices, fn(choice) { choice.literal }),
    builder,
  )
  let (reversed, builder) = @core.fold_left(rows, (@core.Nil, builder), fn(
    state,
    row,
  ) {
    let (reversed, builder) = state
    let (value, builder) = fresh(builder)
    let builder = gate_constraints(choices, row, value, builder)
    let next = Row::{
      inputs: row.inputs,
      values: @core.append(row.values, Cons(value, Nil)),
    }
    (Cons(next, reversed), builder)
  })
  (choices, @core.reverse(reversed), builder)
}

///|
/// Acyclic NAND networks with at most bound gates, no free constants.
pub struct Problem {
  spec : Table
  bound : @core.Nat
  stages : @core.Chain[@core.Chain[Choice]]
  outputs : @core.Chain[(@sat.Literal, Wire)]
  cnf : @sat.Cnf
}

///|
pub fn problem(spec : Table, bound : @core.Nat) -> Problem {
  fn stages(
    rest : @core.Nat,
    previous : @core.Nat,
    rows : @core.Chain[Row],
    reversed : @core.Chain[@core.Chain[Choice]],
    builder : Builder,
  ) -> (@core.Chain[@core.Chain[Choice]], @core.Chain[Row], Builder) {
    match rest {
      Zero => (@core.reverse(reversed), rows, builder)
      Succ(rest) => {
        let (choices, rows, builder) = allocate_stage(
          spec.inputs,
          previous,
          rows,
          builder,
        )
        stages(rest, Succ(previous), rows, Cons(choices, reversed), builder)
      }
    }
  }
  let initial = Builder::{ next: Zero, clauses_rev: Nil, }
  let rows = @core.map(assignments(spec.inputs), fn(inputs) {
    Row::{ inputs, values: Nil, }
  })
  let (choices, rows, builder) = stages(bound, Zero, rows, Nil, initial)
  let (outputs_rev, builder) = @core.fold_left(
    wires(spec.inputs, bound),
    (@core.Nil, builder),
    fn(state, wire) {
      let (reversed, builder) = state
      let (literal, builder) = fresh(builder)
      (Cons((literal, wire), reversed), builder)
    },
  )
  let outputs = @core.reverse(outputs_rev)
  let builder = one_hot(
    @core.map(outputs, fn(pair) {
      let (literal, _) = pair
      literal
    }),
    builder,
  )
  let builder = match @core.zip(rows, spec.outputs) {
    None => emit(Nil, builder)
    Some(pairs) =>
      @core.fold_left(pairs, builder, fn(builder, pair) {
        let (row, expected) = pair
        @core.fold_left(outputs, builder, fn(builder, pair) {
          let (select, wire) = pair
          match signal(wire, row) {
            None => emit(Nil, builder)
            Some(value) => {
              let value = match expected {
                true => value
                false => invert(value)
              }
              emit(Cons(Atom(@sat.negate(select)), Cons(value, Nil)), builder)
            }
          }
        })
      })
  }
  {
    spec,
    bound,
    stages: choices,
    outputs,
    cnf: @core.reverse(builder.clauses_rev),
  }
}

///|
pub fn cnf(problem : Problem) -> @sat.Cnf {
  problem.cnf
}

///|
pub fn bound(problem : Problem) -> @core.Nat {
  problem.bound
}

///|
fn selected(model : @sat.Model, variable : @core.Nat) -> Bool {
  @core.any(model, fn(literal) {
    match @core.compare(literal.variable, variable) {
      Equal => literal.positive
      _ => false
    }
  })
}

///|
fn[A] exactly_one(values : @core.Chain[(Bool, A)]) -> A? {
  fn walk(rest : @core.Chain[(Bool, A)], found : A?) -> A? {
    match rest {
      Nil => found
      Cons((false, _), rest) => walk(rest, found)
      Cons((true, value), rest) =>
        match found {
          Some(_) => None
          None => walk(rest, Some(value))
        }
    }
  }
  walk(values, None)
}

///|
/// Check the SAT model, decode all selectors, then evaluate the whole truth table.
pub fn decode(problem : Problem, model : @sat.Model) -> Network? {
  fn decode_gates(
    stages : @core.Chain[@core.Chain[Choice]],
    reversed : @core.Chain[Nand],
  ) -> @core.Chain[Nand]? {
    match stages {
      Nil => Some(@core.reverse(reversed))
      Cons(choices, rest) =>
        match
          exactly_one(
            @core.map(choices, fn(choice) {
              (selected(model, choice.literal.variable), choice.gate)
            }),
          ) {
          None => None
          Some(gate) => decode_gates(rest, Cons(gate, reversed))
        }
    }
  }
  match @sat.check_model(problem.cnf, model) {
    false => None
    true =>
      match
        (
          decode_gates(problem.stages, Nil),
          exactly_one(
            @core.map(problem.outputs, fn(pair) {
              let (literal, wire) = pair
              (selected(model, literal.variable), wire)
            }),
          ),
        ) {
        (Some(gates), Some(output)) =>
          match network(problem.spec.inputs, gates, output) {
            None => None
            Some(net) =>
              match check_network(problem.spec, net) {
                true => Some(net)
                false => None
              }
          }
        _ => None
      }
  }
}

///|
pub fn check_impossibility(problem : Problem, proof : @cdcl.Proof) -> Bool {
  @cdcl.check_refutation(problem.cnf, proof)
}

///|
pub struct Search {
  problem : Problem
  solver : @cdcl.Search
}

///|
pub(all) enum Outcome {
  Found(Network)
  Impossible(@cdcl.Proof)
  Paused(Search)
  InvariantViolation
}

///|
pub fn start(problem : Problem) -> Search {
  { problem, solver: @cdcl.start(problem.cnf), }
}

///|
pub fn run(search : Search, fuel : @core.Nat) -> Outcome {
  match @cdcl.run(search.solver, fuel) {
    Satisfiable(model) =>
      match decode(search.problem, model) {
        Some(net) => Found(net)
        None => InvariantViolation
      }
    Unsatisfiable(proof) =>
      match check_impossibility(search.problem, proof) {
        true => Impossible(proof)
        false => InvariantViolation
      }
    Paused(solver) => Paused({ ..search, solver, })
    InvariantViolation => InvariantViolation
  }
}
