///|
#derive(Eq, Debug)
pub(all) struct MaterializationCertificate {
  source : @poly.Polynomial
  point : @variety.ProjectedPointCertificate
  real : @variety.CoordinateCertificate
  imaginary : @variety.CoordinateCertificate
}

///|
pub extend MaterializationCertificate with Eq::{equal, not_equal}

///|
pub extend MaterializationCertificate with Debug::{to_repr}

///|
pub fn check_materialization(
  root : Root,
  value : @complex.Number,
  proof : MaterializationCertificate,
) -> Bool {
  if !proof.source.equal(root.source) ||
    !proof.point.equal(@variety.projected_point_certificate(root.point)) ||
    !proof.real.index.equal(Zero) ||
    !proof.imaginary.index.equal(Succ(Zero)) ||
    !proof.real.point.shape.equal(proof.point.separation.solutions.shape) ||
    !proof.imaginary.point.shape.equal(proof.point.separation.solutions.shape) {
    false
  } else {
    match prepare(root.source) {
      Err(_) => false
      Ok(problem) =>
        @variety.check_projected_coordinate_result(
          problem.variety,
          root.point,
          @complex.real_part(value),
          proof.real,
        ) &&
        @variety.check_projected_coordinate_result(
          problem.variety,
          root.point,
          @complex.imaginary_part(value),
          proof.imaginary,
        )
    }
  }
}

///|
#derive(Debug)
enum MaterializationPhase {
  PendingReal
  ComputingReal(@variety.CoordinateEvaluation)
  PendingImaginary(@real.Number, @variety.CoordinateCertificate)
  ComputingImaginary(
    @real.Number,
    @variety.CoordinateCertificate,
    @variety.CoordinateEvaluation
  )
}

///|
pub extend MaterializationPhase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Materialization {
  root : Root
  phase : MaterializationPhase
}

///|
pub extend Materialization with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum MaterializationProgress {
  Materialized(@complex.Number, MaterializationCertificate)
  MaterializationPaused(Materialization)
}

///|
pub extend MaterializationProgress with Debug::{to_repr}

///|
pub fn materialize_start(root : Root) -> Materialization {
  { root, phase: PendingReal, }
}

///|
/// Each fuel unit advances one coordinate interpolation/refinement step.
/// Matrix setup and certificate checking are exact but not time-bounded.
pub fn materialize_advance(
  state : Materialization,
  fuel : @core.Nat,
) -> Result[MaterializationProgress, RootError] {
  fn real_ready(
    value : @real.Number,
    proof : @variety.CoordinateCertificate,
    fuel : @core.Nat,
  ) -> Result[MaterializationProgress, RootError] {
    materialize_advance(
      { ..state, phase: PendingImaginary(value, proof), },
      fuel,
    )
  }
  fn imaginary_ready(
    real : @real.Number,
    real_proof : @variety.CoordinateCertificate,
    imaginary : @real.Number,
    imaginary_proof : @variety.CoordinateCertificate,
  ) -> Result[MaterializationProgress, RootError] {
    let value = @complex.number(real, imaginary)
    let proof : MaterializationCertificate = {
      source: state.root.source,
      point: @variety.projected_point_certificate(state.root.point),
      real: real_proof,
      imaginary: imaginary_proof,
    }
    if check_materialization(state.root, value, proof) {
      Ok(Materialized(value, proof))
    } else {
      Err(InternalInvariant)
    }
  }
  match state.phase {
    PendingReal =>
      match
        @variety.evaluate_projected_coordinate(state.root.point, Zero, Zero) {
        Err(error) => Err(VarietyFailure(error))
        Ok(CoordinateReady(value, proof)) => real_ready(value, proof, fuel)
        Ok(CoordinatePaused(job)) =>
          materialize_advance({ ..state, phase: ComputingReal(job), }, fuel)
      }
    ComputingReal(job) =>
      match fuel {
        Zero => Ok(MaterializationPaused(state))
        Succ(rest) =>
          match @variety.coordinate_advance(job, Succ(Zero)) {
            Err(error) => Err(VarietyFailure(error))
            Ok(CoordinateReady(value, proof)) => real_ready(value, proof, rest)
            Ok(CoordinatePaused(next)) =>
              materialize_advance(
                { ..state, phase: ComputingReal(next), },
                rest,
              )
          }
      }
    PendingImaginary(real, real_proof) =>
      match
        @variety.evaluate_projected_coordinate(
          state.root.point,
          Succ(Zero),
          Zero,
        ) {
        Err(error) => Err(VarietyFailure(error))
        Ok(CoordinateReady(value, proof)) =>
          imaginary_ready(real, real_proof, value, proof)
        Ok(CoordinatePaused(job)) =>
          materialize_advance(
            { ..state, phase: ComputingImaginary(real, real_proof, job), },
            fuel,
          )
      }
    ComputingImaginary(real, real_proof, job) =>
      match fuel {
        Zero => Ok(MaterializationPaused(state))
        Succ(rest) =>
          match @variety.coordinate_advance(job, Succ(Zero)) {
            Err(error) => Err(VarietyFailure(error))
            Ok(CoordinateReady(value, proof)) =>
              imaginary_ready(real, real_proof, value, proof)
            Ok(CoordinatePaused(next)) =>
              materialize_advance(
                { ..state, phase: ComputingImaginary(real, real_proof, next), },
                rest,
              )
          }
      }
  }
}

///|
pub fn materialize(
  root : Root,
  fuel : @core.Nat,
) -> Result[MaterializationProgress, RootError] {
  materialize_advance(materialize_start(root), fuel)
}
