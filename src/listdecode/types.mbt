///|
/// Prime-field RS evaluation list decoder. Every field element is a canonical
/// symbolic Binary residue; message coefficients are in ascending order.
#derive(Eq, Debug)
pub struct Plan {
  field : @primefield.Field
  alphabet : @core.Chain[@binary.Binary]
  points : @core.Chain[@binary.Binary]
  dimension : @core.Nat
  agreements : @core.Nat
  multiplicity : @core.Nat
  degree_bound : @core.Nat
  monomials : @core.Chain[Monomial]
  derivatives : @core.Chain[Monomial]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Monomial {
  x : @core.Nat
  y : @core.Nat
}

///|
pub extend Monomial with Eq::{equal, not_equal}

///|
pub extend Monomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Term {
  coefficient : @binary.Binary
  monomial : Monomial
}

///|
pub extend Term with Eq::{equal, not_equal}

///|
pub extend Term with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Interpolation {
  terms : @core.Chain[Term]
}

///|
pub extend Interpolation with Eq::{equal, not_equal}

///|
pub extend Interpolation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum DecodeError {
  InvalidPlan
  InvalidAlphabet
  NoncanonicalSymbol
  DuplicatePoint
  LengthMismatch
  InterpolationFailure
  InternalInvariant
  Polynomial(@fppoly.PolyError)
}

///|
pub extend DecodeError with Eq::{equal, not_equal}

///|
pub extend DecodeError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Candidate {
  message : @core.Chain[@binary.Binary]
  codeword : @core.Chain[@binary.Binary]
  agreements : @core.Nat
}

///|
pub extend Candidate with Eq::{equal, not_equal}

///|
pub extend Candidate with Debug::{to_repr}

///|
pub struct Node {
  polynomial : Interpolation
  reversed_prefix : @core.Chain[@binary.Binary]
  remaining : @core.Nat
}

///|
/// An opaque continuation, tied to its exact plan, word and interpolation.
/// One fuel unit processes a pending RR node, including its alphabet root scan.
pub struct Search {
  plan : Plan
  received : @core.Chain[@binary.Binary]
  interpolation : Interpolation
  pending : @core.Chain[Node]
  found : @core.Chain[Candidate]
  visited : @core.Nat
}

///|
/// Complete is returned only when the pending RR tree has been exhausted.
#derive(Eq, Debug)
pub(all) struct Decoded {
  interpolation : Interpolation
  candidates : @core.Chain[Candidate]
  nodes : @core.Nat
}

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with Debug::{to_repr}

///|
pub(all) enum Run {
  Suspended(Search)
  Complete(Decoded)
}
