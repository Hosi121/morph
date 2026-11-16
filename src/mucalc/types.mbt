///|
/// Negation-normal form: Bound variables have no negation constructor, so every
/// recursive occurrence is positive. Proposition(id,false) is a negative atom.
#derive(Eq, Debug)
pub(all) enum Formula {
  Truth(Bool)
  Proposition(@core.Nat, Bool)
  And(Formula, Formula)
  Or(Formula, Formula)
  Diamond(Formula)
  Box(Formula)
  Mu(Formula)
  Nu(Formula)
  Bound(@core.Nat)
}

///|
pub extend Formula with Eq::{equal, not_equal}

///|
pub extend Formula with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct State {
  id : @core.Nat
  propositions : @core.Chain[@core.Nat]
  successors : @core.Chain[@core.Nat]
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
/// Finite, possibly empty and possibly nonserial Kripke structures. State and
/// label IDs are arbitrary symbolic naturals, not array indices.
#derive(Eq, Debug)
pub struct Model {
  states : @core.Chain[State]
}

///|
pub extend Model with Eq::{equal, not_equal}

///|
pub extend Model with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CompileError {
  DuplicateState
  UnknownSuccessor
  DuplicateLabel
  UnboundVariable(@core.Nat)
  InternalInvariant
}

///|
pub extend CompileError with Eq::{equal, not_equal}

///|
pub extend CompileError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum NodeKind {
  Constant(Bool)
  Literal(@core.Nat, Bool)
  Conjunction(@core.Nat, @core.Nat)
  Disjunction(@core.Nat, @core.Nat)
  SomeNext(@core.Nat)
  EveryNext(@core.Nat)
  Unfold(@core.Nat)
  Jump(@core.Nat)
}

///|
pub extend NodeKind with Eq::{equal, not_equal}

///|
pub extend NodeKind with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Node {
  id : @core.Nat
  priority : @core.Nat
  kind : NodeKind
}

///|
pub extend Node with Eq::{equal, not_equal}

///|
pub extend Node with Debug::{to_repr}

///|
/// Immutable formula-occurrence arena and its concrete total parity game.
#derive(Eq, Debug)
pub struct Compilation {
  model : Model
  formula : Formula
  nodes : @core.Chain[Node]
  node_count : @core.Nat
  positions : @core.Chain[@parity.Position]
  game : @parity.Game
}

///|
#derive(Eq, Debug)
pub struct Machine {
  compilation : Compilation
  solver : @parity.Machine
}

///|
#derive(Eq, Debug)
pub struct Solution {
  compilation : Compilation
  parity : @parity.Solution
}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Solution)
  Paused(Machine)
  Fault
}

///|
pub extend Compilation with Eq::{equal, not_equal}

///|
pub extend Compilation with Debug::{to_repr}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}
