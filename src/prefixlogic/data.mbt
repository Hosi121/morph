///|
/// A conditional truth over every suffix of a fixed sign-invariant parent cell.
#derive(Eq, Debug)
pub(all) enum Truth {
  Known(Bool)
  Undetermined
}

///|
pub extend Truth with Eq::{equal, not_equal}

///|
pub extend Truth with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PrefixError {
  DimensionMismatch
  InvalidObservation
}

///|
pub extend PrefixError with Eq::{equal, not_equal}

///|
pub extend PrefixError with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Binding {
  Fixed(@core.Ordering)
  Observed(@core.Nat)
  Unavailable
}

///|
#derive(Eq, Debug)
enum Conditional {
  Constant(Bool)
  Atom(Binding, @core.Chain[Binding], @qf.Relation)
  Not(Conditional)
  And(Conditional, Conditional)
  Or(Conditional, Conditional)
}

///|
#derive(Eq, Debug)
struct Stage {
  observation_count : @core.Nat
  conditional : Conditional
}

///|
/// Geometry is deliberately external: the caller must establish that each
/// observed family has these signs throughout its parent cell. check_plan
/// reconstructs the algebraic compilation from the supplied source and families.
#derive(Eq, Debug)
pub struct Plan {
  stages : @core.Chain[Stage]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
#derive(Debug)
struct Group {
  future : @core.Chain[@core.Nat]
  terms : @core.Chain[@poly.Term]
}

///|
pub extend Binding with Eq::{equal, not_equal}

///|
pub extend Binding with Debug::{to_repr}

///|
pub extend Conditional with Eq::{equal, not_equal}

///|
pub extend Conditional with Debug::{to_repr}

///|
pub extend Stage with Eq::{equal, not_equal}

///|
pub extend Stage with Debug::{to_repr}

///|
pub extend Group with Debug::{to_repr}
