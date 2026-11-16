///|
#derive(Eq, Debug)
pub(all) struct Budget {
  primes : @core.Chain[@binary.Binary]
  lifting : @core.Nat
  subsets : @core.Nat
  verification : @core.Nat
}

///|
pub extend Budget with Eq::{equal, not_equal}

///|
pub extend Budget with Debug::{to_repr}

///|
#derive(Debug)
pub struct Problem {
  formula : @base.Formula
  atoms : @core.Chain[@poly.Polynomial]
  projection : @projection.Certificate
  base : @base.Problem
}

///|
pub extend Problem with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CadError {
  NotBivariate
  ProjectionFailure(@projection.ProjectionError)
  BaseFailure
  AlgebraicFailure
  FieldFailure(@nf.FieldError)
  RelativeFailure(@relative.CadError)
  OrderedFailure(@ordered.OrderedError)
  InternalInvariant
}

///|
pub extend CadError with Eq::{equal, not_equal}

///|
pub extend CadError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StackCertificate {
  sample : @base.Sample
  minimal : @minimal.Certificate
  fibre : @relative.Certificate
}

///|
pub extend StackCertificate with Eq::{equal, not_equal}

///|
pub extend StackCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  formula : @base.Formula
  projection : @projection.Certificate
  base : @base.Certificate
  stacks : @core.Chain[StackCertificate]
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
  Base(@base.Machine)
  Next(
    @base.Certificate,
    @core.Chain[@base.Cell],
    @core.Chain[StackCertificate]
  )
  Lifting(
    @base.Certificate,
    @core.Chain[@base.Cell],
    @core.Chain[StackCertificate],
    @base.Sample,
    @minimal.Certificate,
    @relative.Machine
  )
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Machine {
  problem : Problem
  budget : Budget
  phase : Phase
}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(Decomposition)
  Paused(Machine)
  NeedsBudget(Machine, @minimal.StopReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Quantifier {
  Exists
  Forall
}

///|
pub extend Quantifier with Eq::{equal, not_equal}

///|
pub extend Quantifier with Debug::{to_repr}
