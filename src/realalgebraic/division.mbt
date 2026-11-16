///|
#derive(Eq, Debug)
pub(all) struct QuotientCertificate {
  reciprocal : UnaryCertificate
  product : ArithmeticCertificate
}

///|
pub extend QuotientCertificate with Eq::{equal, not_equal}

///|
pub extend QuotientCertificate with Debug::{to_repr}

///|
pub fn check_quotient(proof : QuotientCertificate) -> Bool {
  proof.reciprocal.operation.equal(Reciprocal) &&
  proof.product.resultant.operation.equal(Product) &&
  proof.product.right.equal(proof.reciprocal.result) &&
  check_unary(proof.reciprocal) &&
  check_arithmetic(proof.product)
}

///|
#derive(Debug)
enum DivisionPhase {
  Inverting(Unary)
  Multiplying(UnaryCertificate, Arithmetic)
}

///|
pub extend DivisionPhase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Division {
  left : Number
  phase : DivisionPhase
}

///|
pub extend Division with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum DivisionProgress {
  DivisionReady(Number, QuotientCertificate)
  DivisionPaused(Division)
}

///|
pub extend DivisionProgress with Debug::{to_repr}

///|
pub fn division_start(
  left : Number,
  right : Number,
) -> Result[Division, AlgebraError] {
  match unary_start(right, Reciprocal) {
    Err(error) => Err(error)
    Ok(state) => Ok({ left, phase: Inverting(state), })
  }
}

///|
/// A shared budget covers reciprocal refinements, product determinant samples,
/// and product root refinements. Paused phases retain all completed work.
pub fn division_advance(
  state : Division,
  fuel : @core.Nat,
) -> Result[DivisionProgress, AlgebraError] {
  fn continue_product(
    value : Number,
    proof : UnaryCertificate,
    fuel : @core.Nat,
  ) -> Result[DivisionProgress, AlgebraError] {
    match arithmetic_start(state.left, value, Product) {
      Err(error) => Err(error)
      Ok(job) =>
        division_advance({ ..state, phase: Multiplying(proof, job), }, fuel)
    }
  }
  match state.phase {
    Inverting(job) =>
      match unary_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(UnaryReady(value, proof)) => continue_product(value, proof, fuel)
        Ok(UnaryPaused(_)) =>
          match fuel {
            Zero => Ok(DivisionPaused(state))
            Succ(rest) =>
              match unary_advance(job, Succ(Zero)) {
                Err(error) => Err(error)
                Ok(UnaryReady(value, proof)) =>
                  continue_product(value, proof, rest)
                Ok(UnaryPaused(next)) =>
                  division_advance({ ..state, phase: Inverting(next), }, rest)
              }
          }
      }
    Multiplying(reciprocal, job) =>
      match arithmetic_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(ArithmeticReady(value, product)) =>
          Ok(DivisionReady(value, { reciprocal, product, }))
        Ok(ArithmeticPaused(_)) =>
          match fuel {
            Zero => Ok(DivisionPaused(state))
            Succ(rest) =>
              match arithmetic_advance(job, Succ(Zero)) {
                Err(error) => Err(error)
                Ok(ArithmeticReady(value, product)) =>
                  Ok(DivisionReady(value, { reciprocal, product, }))
                Ok(ArithmeticPaused(next)) =>
                  division_advance(
                    { ..state, phase: Multiplying(reciprocal, next), },
                    rest,
                  )
              }
          }
      }
  }
}

///|
pub fn divide(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[DivisionProgress, AlgebraError] {
  match division_start(left, right) {
    Ok(state) => division_advance(state, fuel)
    Err(error) => Err(error)
  }
}
