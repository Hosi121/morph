///|
/// Finite sign tree only. A geometric CAD checker must separately establish
/// coverage, sign invariance and derivative closure of the supplied families.
/// Leaf(value) is constant over every remaining real coordinate, including
/// when it appears before the final level. It carries no geometric proof.
#derive(Eq, Debug)
pub(all) enum Tree {
  Leaf(Bool)
  Branch(@core.Chain[Child])
}

///|
pub extend Tree with Eq::{equal, not_equal}

///|
pub extend Tree with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Child {
  signs : @core.Chain[@core.Ordering]
  subtree : Tree
}

///|
pub extend Child with Eq::{equal, not_equal}

///|
pub extend Child with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum EncodingError {
  DimensionMismatch
  InvalidTree
  AmbiguousSigns
  ArithmeticFailure
}

///|
pub extend EncodingError with Eq::{equal, not_equal}

///|
pub extend EncodingError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  free_variables : @core.Nat
  quantifiers : @core.Chain[@logic.Quantifier]
  levels : @core.Chain[@core.Chain[@poly.Polynomial]]
  tree : Tree
  formula : @qf.Formula
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Encoding {
  proof : Certificate
}

///|
pub extend Encoding with Eq::{equal, not_equal}

///|
pub extend Encoding with Debug::{to_repr}

///|
pub fn formula(value : Encoding) -> @qf.Formula {
  value.proof.formula
}

///|
pub fn certificate(value : Encoding) -> Certificate {
  value.proof
}
