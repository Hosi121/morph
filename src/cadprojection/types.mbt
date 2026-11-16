///|
#derive(Eq, Debug)
pub(all) enum ProjectionError {
  WrongArity
  InvalidVariable
  ArithmeticFailure
}

///|
pub extend ProjectionError with Eq::{equal, not_equal}

///|
pub extend ProjectionError with Debug::{to_repr}

///|
/// Constants are mapped to their exact sign; all other bindings are zero-based
/// indices in the level's family. No rescaling changes an original atom's sign.
#derive(Eq, Debug)
pub(all) enum Binding {
  Constant(@core.Ordering)
  Member(@core.Nat)
}

///|
pub extend Binding with Eq::{equal, not_equal}

///|
pub extend Binding with Debug::{to_repr}

///|
/// A complete PSC sequence, including zeros and the Collins terminal one.
#derive(Eq, Debug)
pub(all) struct PrincipalRow {
  left : @poly.Polynomial
  right : @poly.Polynomial
  values : @core.Chain[@poly.Polynomial]
}

///|
pub extend PrincipalRow with Eq::{equal, not_equal}

///|
pub extend PrincipalRow with Debug::{to_repr}

///|
/// Full Collins data for the last variable of an explicitly given arity.
/// Rows are deterministic: each block's self rows, then its cross rows against
/// all later blocks, then the next block. All sparse reducta are retained.
#derive(Eq, Debug)
pub(all) struct ProjectionCertificate {
  arity : @core.Nat
  atoms : @core.Chain[@poly.Polynomial]
  coefficients : @core.Chain[@poly.Polynomial]
  reducta : @core.Chain[@core.Chain[@poly.Polynomial]]
  principal : @core.Chain[PrincipalRow]
}

///|
pub extend ProjectionCertificate with Eq::{equal, not_equal}

///|
pub extend ProjectionCertificate with Debug::{to_repr}

///|
/// Family contains distinct nonconstant polynomials, closed under differentiation
/// in variable arity-1 modulo omitted constants. Bindings retain source order;
/// derivatives is aligned with family. At arity zero family is empty and every
/// binding is Constant. Projection is None exactly at arity zero.
#derive(Eq, Debug)
pub(all) struct Level {
  arity : @core.Nat
  source : @core.Chain[@poly.Polynomial]
  family : @core.Chain[@poly.Polynomial]
  bindings : @core.Chain[Binding]
  derivatives : @core.Chain[Binding]
  projection : ProjectionCertificate?
}

///|
pub extend Level with Eq::{equal, not_equal}

///|
pub extend Level with Debug::{to_repr}

///|
/// Levels are in ascending dimension, including both dimension zero and the
/// original arity, even for an empty atom list. The top source is exactly atoms.
#derive(Eq, Debug)
pub(all) struct Certificate {
  arity : @core.Nat
  atoms : @core.Chain[@poly.Polynomial]
  levels : @core.Chain[Level]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
pub struct Plan {
  proof : Certificate
}

///|
pub fn certificate(plan : Plan) -> Certificate {
  plan.proof
}

///|
pub fn levels(plan : Plan) -> @core.Chain[Level] {
  plan.proof.levels
}

///|
pub fn arity(plan : Plan) -> @core.Nat {
  plan.proof.arity
}

///|
pub fn atoms(plan : Plan) -> @core.Chain[@poly.Polynomial] {
  plan.proof.atoms
}

///|
pub fn level(plan : Plan, dimension : @core.Nat) -> Level? {
  @core.nth(plan.proof.levels, dimension)
}

///|
pub fn family(level : Level) -> @core.Chain[@poly.Polynomial] {
  level.family
}

///|
pub fn polynomials(level : Level) -> @core.Chain[@poly.Polynomial] {
  level.family
}

///|
pub fn projection_polynomials(
  proof : ProjectionCertificate,
) -> @core.Chain[@poly.Polynomial] {
  @core.append(
    proof.coefficients,
    @core.fold_left(proof.principal, @core.Nil, fn(acc, row) {
      @core.append(acc, row.values)
    }),
  )
}

///|
/// Recover the signs of the source in its original order (including duplicates,
/// zeros and constants). Reject a sign vector of the wrong family length.
pub fn source_signs(
  level : Level,
  signs : @core.Chain[@core.Ordering],
) -> @core.Chain[@core.Ordering]? {
  fn go(
    bindings : @core.Chain[Binding],
    signs : @core.Chain[@core.Ordering],
  ) -> @core.Chain[@core.Ordering]? {
    match bindings {
      Nil => Some(Nil)
      Cons(binding, rest) => {
        let sign = match binding {
          Constant(sign) => Some(sign)
          Member(index) => @core.nth(signs, index)
        }
        match (sign, go(rest, signs)) {
          (Some(sign), Some(tail)) => Some(Cons(sign, tail))
          _ => None
        }
      }
    }
  }
  if @core.compare(@core.length(signs), @core.length(level.family)) is Equal {
    go(level.bindings, signs)
  } else {
    None
  }
}
