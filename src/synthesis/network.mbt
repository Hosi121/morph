///|
#derive(Eq, Debug)
pub(all) enum Wire {
  Input(@core.Nat)
  Gate(@core.Nat)
}

///|
pub extend Wire with Eq::{equal, not_equal}

///|
pub extend Wire with Debug::{to_repr}

///|
/// Two-input NAND. Equal inputs implement negation; constants are not free.
#derive(Eq, Debug)
pub(all) struct Nand {
  left : Wire
  right : Wire
}

///|
pub extend Nand with Eq::{equal, not_equal}

///|
pub extend Nand with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Network {
  inputs : @core.Nat
  gates : @core.Chain[Nand]
  output : Wire
}

///|
pub extend Network with Eq::{equal, not_equal}

///|
pub extend Network with Debug::{to_repr}

///|
fn valid_wire(wire : Wire, inputs : @core.Nat, previous : @core.Nat) -> Bool {
  let (index, bound) = match wire {
    Input(index) => (index, inputs)
    Gate(index) => (index, previous)
  }
  match @core.compare(index, bound) {
    Less => true
    _ => false
  }
}

///|
pub fn network(
  inputs : @core.Nat,
  gates : @core.Chain[Nand],
  output : Wire,
) -> Network? {
  fn validate(rest : @core.Chain[Nand], previous : @core.Nat) -> Bool {
    match rest {
      Nil => valid_wire(output, inputs, previous)
      Cons(gate, rest) =>
        valid_wire(gate.left, inputs, previous) &&
        valid_wire(gate.right, inputs, previous) &&
        validate(rest, Succ(previous))
    }
  }
  match validate(gates, Zero) {
    true => Some({ inputs, gates, output, })
    false => None
  }
}

///|
pub fn input_count(net : Network) -> @core.Nat {
  net.inputs
}

///|
pub fn gates(net : Network) -> @core.Chain[Nand] {
  net.gates
}

///|
pub fn output(net : Network) -> Wire {
  net.output
}

///|
fn[A] read_wire(
  wire : Wire,
  inputs : @core.Chain[A],
  values : @core.Chain[A],
) -> A? {
  match wire {
    Input(index) => @core.nth(inputs, index)
    Gate(index) => @core.nth(values, index)
  }
}

///|
pub fn evaluate(net : Network, inputs : @core.Chain[Bool]) -> Bool? {
  fn walk(rest : @core.Chain[Nand], values : @core.Chain[Bool]) -> Bool? {
    match rest {
      Nil => read_wire(net.output, inputs, values)
      Cons(gate, rest) =>
        match
          (
            read_wire(gate.left, inputs, values),
            read_wire(gate.right, inputs, values),
          ) {
          (Some(a), Some(b)) =>
            walk(rest, @core.append(values, Cons(!(a && b), Nil)))
          _ => None
        }
    }
  }
  match @core.compare(@core.length(inputs), net.inputs) {
    Equal => walk(net.gates, Nil)
    _ => None
  }
}

///|
/// Lexicographic rows: the first input changes slowest.
pub fn assignments(inputs : @core.Nat) -> @core.Chain[@core.Chain[Bool]] {
  match inputs {
    Zero => Cons(Nil, Nil)
    Succ(rest) => {
      let suffixes = assignments(rest)
      @core.append(
        @core.map(suffixes, fn(row) { Cons(false, row) }),
        @core.map(suffixes, fn(row) { Cons(true, row) }),
      )
    }
  }
}

///|
#derive(Eq, Debug)
pub struct Table {
  inputs : @core.Nat
  outputs : @core.Chain[Bool]
}

///|
pub extend Table with Eq::{equal, not_equal}

///|
pub extend Table with Debug::{to_repr}

///|
pub fn table(inputs : @core.Nat, outputs : @core.Chain[Bool]) -> Table? {
  match
    @core.compare(@core.length(assignments(inputs)), @core.length(outputs)) {
    Equal => Some({ inputs, outputs, })
    _ => None
  }
}

///|
pub fn truth_table(spec : Table) -> @core.Chain[Bool] {
  spec.outputs
}

///|
pub fn check_network(spec : Table, net : Network) -> Bool {
  match @core.compare(spec.inputs, net.inputs) {
    Equal =>
      match @core.zip(assignments(spec.inputs), spec.outputs) {
        None => false
        Some(rows) =>
          @core.all(rows, fn(row) {
            let (inputs, expected) = row
            match (evaluate(net, inputs), expected) {
              (Some(true), true) | (Some(false), false) => true
              _ => false
            }
          })
      }
    _ => false
  }
}
