///|
#derive(Eq, Debug)
pub(all) enum TowerError {
  DifferentField
  ZeroDivisor
  ZeroPolynomial
  InvalidInterval
  InvalidCertificate
  InternalInvariant
  PendingImplementation
}

///|
pub extend TowerError with Eq::{equal, not_equal}

///|
pub extend TowerError with Debug::{to_repr}

///|
/// Raw values carry no repeated context. Constructors are package-private.
#derive(Eq, Debug)
pub enum Representation {
  Base(@exact.Rational)
  Fraction(@core.Chain[Representation], @core.Chain[Representation])
}

///|
pub extend Representation with Eq::{equal, not_equal}

///|
pub extend Representation with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Context {
  Rationals
  Extension(Field, @core.Chain[Representation], @sturm.Interval)
}

///|
#derive(Eq, Debug)
pub struct Field {
  context : Context
}

///|
pub extend Field with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Scalar {
  field : Field
  value : Representation
}

///|
pub extend Scalar with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Polynomial {
  field : Field
  values : @core.Chain[Representation]
}

///|
pub extend Polynomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ScalarCertificate {
  field : Field
  value : Representation
  sign : @core.Ordering
}

///|
pub extend ScalarCertificate with Eq::{equal, not_equal}

///|
pub extend ScalarCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ScalarSign {
  sign : @core.Ordering
  certificate : ScalarCertificate
}

///|
pub extend ScalarSign with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Division {
  quotient : Polynomial
  remainder : Polynomial
}

///|
pub extend Division with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct SystemCertificate {
  field : Field
  polynomial : @core.Chain[Representation]
  squarefree : @core.Chain[Representation]
}

///|
pub extend SystemCertificate with Eq::{equal, not_equal}

///|
pub extend SystemCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct System {
  polynomial : Polynomial
  squarefree : Polynomial
  sequence : @core.Chain[@core.Chain[Representation]]
  certificate : SystemCertificate
}

///|
pub extend System with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct CountCertificate {
  system : SystemCertificate
  interval : @sturm.Interval
  count : @core.Nat
}

///|
pub extend CountCertificate with Eq::{equal, not_equal}

///|
pub extend CountCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct RootCertificate {
  system : SystemCertificate
  count : CountCertificate
}

///|
pub extend RootCertificate with Eq::{equal, not_equal}

///|
pub extend RootCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Root {
  system : System
  certificate : RootCertificate
}

///|
pub extend Root with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct BoundCertificate {
  system : SystemCertificate
  bound : @exact.Rational
}

///|
pub extend BoundCertificate with Eq::{equal, not_equal}

///|
pub extend BoundCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct SolutionCertificate {
  system : SystemCertificate
  bound : BoundCertificate
  whole : CountCertificate
  roots : @core.Chain[RootCertificate]
}

///|
pub extend SolutionCertificate with Eq::{equal, not_equal}

///|
pub extend SolutionCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct SolutionSet {
  system : System
  roots : @core.Chain[Root]
  certificate : SolutionCertificate
}

///|
pub extend SolutionSet with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Phase {
  FindingBound
  Splitting(BoundCertificate, CountCertificate, @core.Chain[CountCertificate], @core.Chain[RootCertificate])
}

///|
#derive(Eq, Debug)
pub struct State {
  system : System
  threshold : Scalar
  candidate : @binary.Binary
  phase : Phase
}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Isolated(SolutionSet)
  Paused(State)
}

///|
pub extend Progress with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Extension {
  field : Field
  generator : Scalar
}

///|
pub extend Extension with Debug::{to_repr}
