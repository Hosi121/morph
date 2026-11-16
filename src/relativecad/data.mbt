///|
#derive(Eq, Debug)
pub(all) enum Relation {
  LessZero
  AtMostZero
  EqualZero
  NotZero
  AtLeastZero
  GreaterZero
}

///|
pub extend Relation with Eq::{equal, not_equal}

///|
pub extend Relation with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Formula {
  Truth(Bool)
  Atom(@ordered.Polynomial, Relation)
  Negation(Formula)
  Conjunction(Formula, Formula)
  Disjunction(Formula, Formula)
}

///|
pub extend Formula with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CadError {
  DifferentField
  OrderedFailure(@ordered.OrderedError)
  InternalInvariant
}

///|
pub extend CadError with Eq::{equal, not_equal}

///|
pub extend CadError with Debug::{to_repr}

///|
#derive(Debug)
struct AtomInfo {
  polynomial : @ordered.Polynomial
  system : @ordered.System?
}

///|
pub extend AtomInfo with Debug::{to_repr}

///|
#derive(Debug)
pub struct Problem {
  field : @numberfield.Field
  formula : Formula
  atoms : @core.Chain[AtomInfo]
  product : @ordered.Polynomial
  system : @ordered.System
}

///|
pub extend Problem with Debug::{to_repr}

///|
/// Algebraic intervals refer to this Problem's root polynomial and base field.
#derive(Eq, Debug)
pub(all) enum Sample {
  RationalPoint(@exact.Rational)
  AlgebraicPoint(@sturm.Interval)
}

///|
pub extend Sample with Eq::{equal, not_equal}

///|
pub extend Sample with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Cell {
  sample : Sample
  signs : @core.Chain[@core.Ordering]
  holds : Bool
}

///|
pub extend Cell with Eq::{equal, not_equal}

///|
pub extend Cell with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  isolation : @ordered.SolutionCertificate
  cells : @core.Chain[Cell]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Decomposition {
  problem : Problem
  certificate : Certificate
}

///|
pub extend Decomposition with Debug::{to_repr}

///|
#derive(Debug)
enum Phase {
  Isolating(@ordered.State)
  Separating(@ordered.SolutionCertificate, @core.Chain[@ordered.Root])
  Sampling(@ordered.SolutionCertificate, @core.Chain[Sample], @core.Chain[Cell])
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Machine {
  problem : Problem
  phase : Phase
}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(Decomposition)
  Paused(Machine)
}

///|
pub extend Progress with Debug::{to_repr}
