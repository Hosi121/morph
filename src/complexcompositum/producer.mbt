///|
pub fn start(inputs : @core.Chain[@cx.Number]) -> Build {
  {
    inputs,
    remaining: flatten(inputs),
    initial: None,
    state: None,
    steps_rev: Nil,
  }
}

///|
pub fn compose(
  inputs : @core.Chain[@cx.Number],
  budget : @comp.Budget,
) -> Result[Progress, CompositumError] {
  advance(start(inputs), budget)
}

///|
/// Construct a common ambient K(i), where K contains every selected real and
/// imaginary coordinate. K(i) need not be the minimal field of the cohort.
/// A pause keeps all completed coordinate maps; only the unfinished operation
/// is retried with the next supplied budget.
pub fn advance(
  build : Build,
  budget : @comp.Budget,
) -> Result[Progress, CompositumError] {
  let (initial, state) = match (build.initial, build.state) {
    (Some(initial), Some(state)) => (initial, state)
    (None, None) => {
      let zero = match @real.rational(@exact.rational_zero()) {
        Ok(value) => value
        Err(error) => return Err(AlgebraFailure(error))
      }
      let proof = match
        @minimal.normalize(
          zero,
          budget.primes,
          budget.lift,
          budget.subset,
          budget.verification,
        ) {
        Err(error) => return Err(MinimalFailure(error))
        Ok(@minimal.Unresolved(reason)) =>
          return Ok(Paused(build, InitializationBudget(reason)))
        Ok(@minimal.Normalized(_, proof)) => proof
      }
      let field = match @nf.field(proof, budget.verification) {
        Ok(field) => field
        Err(@nf.VerificationBudget) =>
          return Ok(Paused(build, VerificationBudget))
        Err(error) => return Err(FieldFailure(error))
      }
      (proof, State::{ field, coordinates: Nil, seen: Nil, })
    }
    _ => return Err(InternalInvariant)
  }
  let checkpoint = Build::{
    ..build,
    initial: Some(initial),
    state: Some(state),
  }
  match build.remaining {
    Nil => {
      let field = @cf.field(state.field)
      let values = match complex_elements(field, state.coordinates) {
        Ok(values) => values
        Err(error) => return Err(error)
      }
      let proof = Certificate::{
        sources: @core.map(build.inputs, @cx.certificate),
        initial,
        steps: @core.reverse(build.steps_rev),
        field: state.field,
        coordinates: @core.map(state.coordinates, @nf.representative),
      }
      Ok(Ready({ field, values, proof, }, proof))
    }
    Cons(input, remaining) => {
      let (next, step) = match
        duplicate(@real.root_certificate(input), state.seen, Zero) {
        Some(index) => {
          let value = match @core.nth(state.coordinates, index) {
            Some(value) => value
            None => return Err(InternalInvariant)
          }
          (with_coordinate(state, input, value), Reuse(index))
        }
        None =>
          match rational_coordinate(input) {
            Some(rational) =>
              (
                with_coordinate(
                  state,
                  input,
                  @nf.rational(state.field, rational),
                ),
                Rational(rational),
              )
            None =>
              if @nf.degree(state.field).equal(Succ(Zero)) {
                let proof = match
                  @minimal.normalize(
                    input,
                    budget.primes,
                    budget.lift,
                    budget.subset,
                    budget.verification,
                  ) {
                  Err(error) => return Err(MinimalFailure(error))
                  Ok(@minimal.Unresolved(reason)) =>
                    return Ok(Paused(checkpoint, NormalizationBudget(reason)))
                  Ok(@minimal.Normalized(_, proof)) => proof
                }
                let field = match @nf.field(proof, budget.verification) {
                  Ok(field) => field
                  Err(@nf.VerificationBudget) =>
                    return Ok(Paused(checkpoint, VerificationBudget))
                  Err(error) => return Err(FieldFailure(error))
                }
                let coordinates = match
                  transport(state.coordinates, @nf.zero(field)) {
                  Some(values) => values
                  None => return Err(InternalInvariant)
                }
                let generator = match @nf.generator(field) {
                  Ok(value) => value
                  Err(error) => return Err(FieldFailure(error))
                }
                (
                  with_coordinate(
                    { ..state, field, coordinates, },
                    input,
                    generator,
                  ),
                  Normalize(proof),
                )
              } else {
                let alpha = match @real.number(@nf.embedding(state.field)) {
                  Ok(value) => value
                  Err(error) => return Err(AlgebraFailure(error))
                }
                let (common, proof) = match
                  @comp.compose(alpha, input, budget) {
                  Err(error) => return Err(MergeFailure(error))
                  Ok(@comp.Unresolved(reason)) =>
                    return Ok(Paused(checkpoint, MergeBudget(reason)))
                  Ok(@comp.Composed(common, proof)) => (common, proof)
                }
                let coordinates = match
                  transport(state.coordinates, @comp.left_element(common)) {
                  Some(values) => values
                  None => return Err(InternalInvariant)
                }
                let field = @comp.common_field(common)
                (
                  with_coordinate(
                    { ..state, field, coordinates, },
                    input,
                    @comp.right_element(common),
                  ),
                  Merge(common, proof),
                )
              }
          }
      }
      advance(
        {
          ..checkpoint,
          remaining,
          state: Some(next),
          steps_rev: Cons(step, build.steps_rev),
        },
        budget,
      )
    }
  }
}
