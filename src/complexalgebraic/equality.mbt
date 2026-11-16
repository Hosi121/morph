///|
/// Numeric equality uses common real roots, not equality of representations.
#derive(Eq, Debug)
pub(all) struct EqualityCertificate {
  left : NumberCertificate
  right : NumberCertificate
  real : @realalgebraic.ComparisonCertificate
  imaginary : @realalgebraic.ComparisonCertificate
  equal : Bool
}

///|
pub extend EqualityCertificate with Eq::{equal, not_equal}

///|
pub extend EqualityCertificate with Debug::{to_repr}

///|
pub fn check_equality(proof : EqualityCertificate) -> Bool {
  let equal = proof.real.order.equal(Equal) &&
    proof.imaginary.order.equal(Equal)
  let result_matches = if proof.equal { equal } else { !equal }
  check_number(proof.left) &&
  check_number(proof.right) &&
  proof.real.left.equal(proof.left.real) &&
  proof.real.right.equal(proof.right.real) &&
  proof.imaginary.left.equal(proof.left.imaginary) &&
  proof.imaginary.right.equal(proof.right.imaginary) &&
  @realalgebraic.check_comparison(proof.real) &&
  @realalgebraic.check_comparison(proof.imaginary) &&
  result_matches
}

///|
pub fn check_equality_result(value : Bool, proof : EqualityCertificate) -> Bool {
  let result_matches = if value { proof.equal } else { !proof.equal }
  result_matches && check_equality(proof)
}

///|
pub fn check_equality_for(
  left : Number,
  right : Number,
  value : Bool,
  proof : EqualityCertificate,
) -> Bool {
  certificate(left).equal(proof.left) &&
  certificate(right).equal(proof.right) &&
  check_equality_result(value, proof)
}

///|
#derive(Debug)
priv enum EqualityPhase {
  RealCoordinate(@realalgebraic.Comparison)
  ImaginaryCoordinate(
    @realalgebraic.ComparisonCertificate,
    @realalgebraic.Comparison
  )
}

///|
#derive(Debug)
pub struct Equality {
  priv left : Number
  priv right : Number
  priv phase : EqualityPhase
}

///|
pub extend Equality with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum EqualityProgress {
  EqualityReady(Bool, EqualityCertificate)
  EqualityPaused(Equality)
}

///|
pub extend EqualityProgress with Debug::{to_repr}

///|
pub fn equality_start(
  left : Number,
  right : Number,
) -> Result[Equality, @realalgebraic.AlgebraError] {
  match @realalgebraic.comparison(left.real, right.real) {
    Ok(job) => Ok({ left, right, phase: RealCoordinate(job), })
    Err(error) => Err(error)
  }
}

///|
fn equality_finish(
  state : Equality,
  real : @realalgebraic.ComparisonCertificate,
  imaginary : @realalgebraic.ComparisonCertificate,
) -> EqualityProgress {
  let equal = real.order.equal(Equal) && imaginary.order.equal(Equal)
  EqualityReady(equal, {
    left: certificate(state.left),
    right: certificate(state.right),
    real,
    imaginary,
    equal,
  })
}

///|
/// A shared budget counts paired real-coordinate refinements. Completed real
/// comparison proofs survive an imaginary-coordinate pause. Initial gcd setup
/// and proof checking have the same unmetered exact work as realalgebraic.
pub fn equality_advance(
  state : Equality,
  fuel : @core.Nat,
) -> Result[EqualityProgress, @realalgebraic.AlgebraError] {
  fn continue_imaginary(
    real : @realalgebraic.ComparisonCertificate,
    fuel : @core.Nat,
  ) -> Result[EqualityProgress, @realalgebraic.AlgebraError] {
    match
      @realalgebraic.comparison(state.left.imaginary, state.right.imaginary) {
      Ok(job) =>
        equality_advance(
          { ..state, phase: ImaginaryCoordinate(real, job), },
          fuel,
        )
      Err(error) => Err(error)
    }
  }
  match state.phase {
    RealCoordinate(job) =>
      match @realalgebraic.compare_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(Compared(_, proof)) => continue_imaginary(proof, fuel)
        Ok(ComparisonPaused(_)) =>
          match fuel {
            Zero => Ok(EqualityPaused(state))
            Succ(rest) =>
              match @realalgebraic.compare_advance(job, Succ(Zero)) {
                Err(error) => Err(error)
                Ok(Compared(_, proof)) => continue_imaginary(proof, rest)
                Ok(ComparisonPaused(next)) =>
                  equality_advance(
                    { ..state, phase: RealCoordinate(next), },
                    rest,
                  )
              }
          }
      }
    ImaginaryCoordinate(real, job) =>
      match @realalgebraic.compare_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(Compared(_, imaginary)) =>
          Ok(equality_finish(state, real, imaginary))
        Ok(ComparisonPaused(_)) =>
          match fuel {
            Zero => Ok(EqualityPaused(state))
            Succ(rest) =>
              match @realalgebraic.compare_advance(job, Succ(Zero)) {
                Err(error) => Err(error)
                Ok(Compared(_, imaginary)) =>
                  Ok(equality_finish(state, real, imaginary))
                Ok(ComparisonPaused(next)) =>
                  equality_advance(
                    { ..state, phase: ImaginaryCoordinate(real, next), },
                    rest,
                  )
              }
          }
      }
  }
}

///|
pub fn equal(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[EqualityProgress, @realalgebraic.AlgebraError] {
  match equality_start(left, right) {
    Ok(state) => equality_advance(state, fuel)
    Err(error) => Err(error)
  }
}
