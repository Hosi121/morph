///|
/// Sources, fixed formula, every intermediate witness, and the bound result.
/// For unary operations only left is used; right remains source-bound metadata.
#derive(Eq, Debug)
pub(all) struct ArithmeticCertificate {
  left : NumberCertificate
  right : NumberCertificate
  operation : Operation
  steps : @core.Chain[StepCertificate]
  result : NumberCertificate
}

///|
pub extend ArithmeticCertificate with Eq::{equal, not_equal}

///|
pub extend ArithmeticCertificate with Debug::{to_repr}

///|
/// Verify the fixed formula and each exact real relation without replaying any
/// search. This still performs exact polynomial and certificate computations;
/// it is not a constant-time or fuel-limited checker.
pub fn check_arithmetic(proof : ArithmeticCertificate) -> Bool {
  fn walk(
    instructions : @core.Chain[Instruction],
    proofs : @core.Chain[StepCertificate],
    left : Number,
    right : Number,
    values : @core.Chain[@realalgebraic.Number],
  ) -> @core.Chain[@realalgebraic.Number]? {
    match (instructions, proofs) {
      (Nil, Nil) => Some(values)
      (Cons(instruction, rest), Cons(proof, proofs)) =>
        match instruction_inputs(instruction, left, right, values) {
          Some((a, b)) =>
            if check_step(instruction, a, b, proof) {
              match @realalgebraic.number(step_result(proof)) {
                Ok(value) =>
                  walk(
                    rest,
                    proofs,
                    left,
                    right,
                    @core.append(values, Cons(value, Nil)),
                  )
                Err(_) => None
              }
            } else {
              None
            }
          None => None
        }
      _ => None
    }
  }
  match (read_certificate(proof.left), read_certificate(proof.right)) {
    (Ok(left), Ok(right)) =>
      match
        walk(
          recipe(proof.operation).instructions,
          proof.steps,
          left,
          right,
          Nil,
        ) {
        Some(values) =>
          match recipe_result(proof.operation, left, right, values) {
            Some(value) => certificate(value).equal(proof.result)
            None => false
          }
        None => false
      }
    _ => false
  }
}

///|
pub fn check_arithmetic_result(
  value : Number,
  proof : ArithmeticCertificate,
) -> Bool {
  certificate(value).equal(proof.result) && check_arithmetic(proof)
}

///|
/// Bind externally supplied sources, operation, and result by representation.
pub fn check_arithmetic_for(
  left : Number,
  right : Number,
  operation : Operation,
  result : Number,
  proof : ArithmeticCertificate,
) -> Bool {
  certificate(left).equal(proof.left) &&
  certificate(right).equal(proof.right) &&
  operation.equal(proof.operation) &&
  check_arithmetic_result(result, proof)
}

///|
#derive(Debug)
pub struct Arithmetic {
  priv left : Number
  priv right : Number
  priv operation : Operation
  priv remaining : @core.Chain[Instruction]
  priv values : @core.Chain[@realalgebraic.Number]
  priv proofs : @core.Chain[StepCertificate]
  priv active : RealJob?
}

///|
pub extend Arithmetic with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum ArithmeticProgress {
  ArithmeticReady(Number, ArithmeticCertificate)
  ArithmeticPaused(Arithmetic)
}

///|
pub extend ArithmeticProgress with Debug::{to_repr}

///|
pub fn arithmetic_start(
  left : Number,
  right : Number,
  operation : Operation,
) -> Result[Arithmetic, @realalgebraic.AlgebraError] {
  if operation.equal(Division) && is_zero(right) {
    Err(@realalgebraic.ZeroDivisor)
  } else {
    Ok({
      left,
      right,
      operation,
      remaining: recipe(operation).instructions,
      values: Nil,
      proofs: Nil,
      active: None,
    })
  }
}

///|
fn complete_step(
  state : Arithmetic,
  remaining : @core.Chain[Instruction],
  value : @realalgebraic.Number,
  proof : StepCertificate,
) -> Arithmetic {
  {
    ..state,
    remaining,
    values: @core.append(state.values, Cons(value, Nil)),
    proofs: Cons(proof, state.proofs),
    active: None,
  }
}

///|
/// A shared budget counts instruction startups and delegated real-algebraic
/// sample/refinement units. Setup and certificate checks are exact but not
/// bounded in wall time by fuel. Every pause retains all completed instructions
/// and the active real continuation; no pause denotes a numeric result.
pub fn arithmetic_advance(
  state : Arithmetic,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  match state.remaining {
    Nil =>
      match
        recipe_result(state.operation, state.left, state.right, state.values) {
        Some(value) =>
          Ok(
            ArithmeticReady(value, {
              left: certificate(state.left),
              right: certificate(state.right),
              operation: state.operation,
              steps: @core.reverse(state.proofs),
              result: certificate(value),
            }),
          )
        None => Err(@realalgebraic.InternalInvariant)
      }
    Cons(instruction, remaining) =>
      match state.active {
        None =>
          match fuel {
            Zero => Ok(ArithmeticPaused(state))
            Succ(rest) =>
              match
                instruction_inputs(
                  instruction,
                  state.left,
                  state.right,
                  state.values,
                ) {
                Some((a, b)) =>
                  match start_step(instruction, a, b) {
                    Ok(job) =>
                      arithmetic_advance({ ..state, active: Some(job), }, rest)
                    Err(error) => Err(error)
                  }
                None => Err(@realalgebraic.InternalInvariant)
              }
          }
        Some(job) =>
          match advance_step(job, Zero) {
            Err(error) => Err(error)
            Ok(StepReady(value, proof)) =>
              arithmetic_advance(
                complete_step(state, remaining, value, proof),
                fuel,
              )
            Ok(StepPaused(current)) =>
              match fuel {
                Zero =>
                  Ok(ArithmeticPaused({ ..state, active: Some(current), }))
                Succ(rest) =>
                  match advance_step(current, Succ(Zero)) {
                    Err(error) => Err(error)
                    Ok(StepReady(value, proof)) =>
                      arithmetic_advance(
                        complete_step(state, remaining, value, proof),
                        rest,
                      )
                    Ok(StepPaused(next)) =>
                      arithmetic_advance({ ..state, active: Some(next), }, rest)
                  }
              }
          }
      }
  }
}

///|
fn run(
  left : Number,
  right : Number,
  operation : Operation,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  match arithmetic_start(left, right, operation) {
    Ok(state) => arithmetic_advance(state, fuel)
    Err(error) => Err(error)
  }
}

///|
pub fn add(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(left, right, Addition, fuel)
}

///|
pub fn subtract(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(left, right, Subtraction, fuel)
}

///|
pub fn multiply(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(left, right, Multiplication, fuel)
}

///|
pub fn divide(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(left, right, Division, fuel)
}

///|
pub fn negate(
  value : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(value, value, Negation, fuel)
}

///|
pub fn conjugate(
  value : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, @realalgebraic.AlgebraError] {
  run(value, value, Conjugation, fuel)
}
