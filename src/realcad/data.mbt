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
/// Boolean combinations of rational-coefficient polynomials in one real variable.
#derive(Eq, Debug)
pub(all) enum Formula {
  Truth(Bool)
  Atom(@polynomial.Polynomial, Relation)
  Negation(Formula)
  Conjunction(Formula, Formula)
  Disjunction(Formula, Formula)
}

///|
pub extend Formula with Eq::{equal, not_equal}

///|
pub extend Formula with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum BuildError {
  NotUnivariate
  ArithmeticFailure
}

///|
pub extend BuildError with Eq::{equal, not_equal}

///|
pub extend BuildError with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct AtomInfo {
  polynomial : @polynomial.Polynomial
  system : @sturm.System?
}

///|
pub extend AtomInfo with Eq::{equal, not_equal}

///|
pub extend AtomInfo with Debug::{to_repr}

///|
/// The unique root in an algebraic sample's (lower,upper] belongs to this
/// problem's squarefree root polynomial; the interval alone is not a number
/// independently of its owning Problem.
#derive(Eq, Debug)
pub struct Problem {
  formula : Formula
  atoms : @core.Chain[AtomInfo]
  system : @sturm.System
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
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
/// Signs are in polynomials(problem) order. Cells alternate rational open-cell
/// samples and isolated roots, beginning and ending with an open-cell sample.
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
/// An untrusted finite description of a sign-invariant decomposition of R.
#derive(Eq, Debug)
pub(all) struct Certificate {
  roots : @core.Chain[@sturm.Interval]
  cells : @core.Chain[Cell]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// Constructible only by generation or successful coverage/sign verification.
#derive(Eq, Debug)
pub struct Decomposition {
  problem : Problem
  certificate : Certificate
}

///|
pub extend Decomposition with Eq::{equal, not_equal}

///|
pub extend Decomposition with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Phase {
  Isolating(@sturm.Isolation)
  Separating(@core.Chain[@sturm.Interval])
  Sampling(@core.Chain[@sturm.Interval], @core.Chain[Sample], @core.Chain[Cell])
}

///|
pub extend Phase with Eq::{equal, not_equal}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Machine {
  problem : Problem
  phase : Phase
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Decomposition)
  Paused(Machine)
  Fault
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}
