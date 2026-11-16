///|
/// Untrusted witnesses for individual real coordinate operations. The enclosing
/// fixed recipe determines their inputs and operation; the witness cannot do so.
#derive(Eq, Debug)
pub(all) enum StepCertificate {
  BinaryStep(@realalgebraic.ArithmeticCertificate)
  UnaryStep(@realalgebraic.UnaryCertificate)
  DivisionStep(@realalgebraic.QuotientCertificate)
  RationalStep(@realalgebraic.RootCertificate)
}

///|
pub extend StepCertificate with Eq::{equal, not_equal}

///|
pub extend StepCertificate with Debug::{to_repr}

///|
fn step_result(proof : StepCertificate) -> @realalgebraic.RootCertificate {
  match proof {
    BinaryStep(proof) => proof.result
    UnaryStep(proof) => proof.result
    DivisionStep(proof) => proof.product.result
    RationalStep(proof) => proof
  }
}

///|
/// Extract a rational only when the full defining polynomial has degree one.
/// Root validity then identifies its unique root independently of the interval.
fn as_rational(value : @realalgebraic.Number) -> @exact.Rational? {
  fn coefficients(
    terms : @core.Chain[@poly.Term],
    constant : @exact.Rational,
    linear : @exact.Rational,
  ) -> (@exact.Rational, @exact.Rational)? {
    match terms {
      Nil => Some((constant, linear))
      Cons(term, rest) =>
        match term.exponents {
          Cons(Zero, Nil) =>
            coefficients(
              rest,
              @exact.rational_add(constant, term.coefficient),
              linear,
            )
          Cons(Succ(Zero), Nil) =>
            coefficients(
              rest,
              constant,
              @exact.rational_add(linear, term.coefficient),
            )
          _ => None
        }
    }
  }
  match
    coefficients(
      @poly.terms(@realalgebraic.definition(value)),
      @exact.rational_zero(),
      @exact.rational_zero(),
    ) {
    Some((constant, linear)) =>
      @exact.rational_divide(@exact.rational_negate(constant), linear)
    None => None
  }
}

///|
fn rational_evaluate(
  instruction : Instruction,
  a : @realalgebraic.Number,
  b : @realalgebraic.Number,
) -> Result[@exact.Rational?, @realalgebraic.AlgebraError] {
  match (as_rational(a), as_rational(b)) {
    (Some(a), Some(b)) =>
      match instruction {
        Sum(_, _) => Ok(Some(@exact.rational_add(a, b)))
        Product(_, _) => Ok(Some(@exact.rational_multiply(a, b)))
        Negative(_) => Ok(Some(@exact.rational_negate(a)))
        Quotient(_, _) =>
          match @exact.rational_divide(a, b) {
            Some(value) => Ok(Some(value))
            None => Err(@realalgebraic.ZeroDivisor)
          }
      }
    _ => Ok(None)
  }
}

///|
fn check_step(
  instruction : Instruction,
  a : @realalgebraic.Number,
  b : @realalgebraic.Number,
  proof : StepCertificate,
) -> Bool {
  let ar = @realalgebraic.root_certificate(a)
  let br = @realalgebraic.root_certificate(b)
  match (instruction, proof) {
    (Sum(_, _), BinaryStep(proof)) =>
      proof.left.equal(ar) &&
      proof.right.equal(br) &&
      proof.resultant.operation.equal(@realalgebraic.Sum) &&
      @realalgebraic.check_arithmetic(proof)
    (Product(_, _), BinaryStep(proof)) =>
      proof.left.equal(ar) &&
      proof.right.equal(br) &&
      proof.resultant.operation.equal(@realalgebraic.Product) &&
      @realalgebraic.check_arithmetic(proof)
    (Negative(_), UnaryStep(proof)) =>
      proof.input.equal(ar) &&
      proof.operation.equal(@realalgebraic.Negation) &&
      @realalgebraic.check_unary(proof)
    (Quotient(_, _), DivisionStep(proof)) =>
      proof.product.left.equal(ar) &&
      proof.reciprocal.input.equal(br) &&
      @realalgebraic.check_quotient(proof)
    (_, RationalStep(proof)) =>
      match rational_evaluate(instruction, a, b) {
        Ok(Some(value)) =>
          match @realalgebraic.rational(value) {
            Ok(value) => @realalgebraic.root_certificate(value).equal(proof)
            Err(_) => false
          }
        _ => false
      }
    _ => false
  }
}

///|
#derive(Debug)
priv enum RealJob {
  BinaryJob(@realalgebraic.Arithmetic)
  UnaryJob(@realalgebraic.Unary)
  DivisionJob(@realalgebraic.Division)
  Completed(@realalgebraic.Number, StepCertificate)
}

///|
priv enum StepProgress {
  StepReady(@realalgebraic.Number, StepCertificate)
  StepPaused(RealJob)
}

///|
fn start_step(
  instruction : Instruction,
  a : @realalgebraic.Number,
  b : @realalgebraic.Number,
) -> Result[RealJob, @realalgebraic.AlgebraError] {
  match rational_evaluate(instruction, a, b) {
    Err(error) => Err(error)
    Ok(Some(value)) =>
      match @realalgebraic.rational(value) {
        Ok(value) =>
          Ok(
            Completed(
              value,
              RationalStep(@realalgebraic.root_certificate(value)),
            ),
          )
        Err(error) => Err(error)
      }
    Ok(None) =>
      match instruction {
        Sum(_, _) | Product(_, _) => {
          let operation = match instruction {
            Sum(_, _) => @realalgebraic.Sum
            _ => @realalgebraic.Product
          }
          match @realalgebraic.arithmetic_start(a, b, operation) {
            Ok(job) => Ok(BinaryJob(job))
            Err(error) => Err(error)
          }
        }
        Negative(_) =>
          match @realalgebraic.unary_start(a, @realalgebraic.Negation) {
            Ok(job) => Ok(UnaryJob(job))
            Err(error) => Err(error)
          }
        Quotient(_, _) =>
          match @realalgebraic.division_start(a, b) {
            Ok(job) => Ok(DivisionJob(job))
            Err(error) => Err(error)
          }
      }
  }
}

///|
fn advance_step(
  job : RealJob,
  fuel : @core.Nat,
) -> Result[StepProgress, @realalgebraic.AlgebraError] {
  match job {
    Completed(value, proof) => Ok(StepReady(value, proof))
    BinaryJob(job) =>
      match @realalgebraic.arithmetic_advance(job, fuel) {
        Ok(ArithmeticReady(value, proof)) =>
          Ok(StepReady(value, BinaryStep(proof)))
        Ok(ArithmeticPaused(job)) => Ok(StepPaused(BinaryJob(job)))
        Err(error) => Err(error)
      }
    UnaryJob(job) =>
      match @realalgebraic.unary_advance(job, fuel) {
        Ok(UnaryReady(value, proof)) => Ok(StepReady(value, UnaryStep(proof)))
        Ok(UnaryPaused(job)) => Ok(StepPaused(UnaryJob(job)))
        Err(error) => Err(error)
      }
    DivisionJob(job) =>
      match @realalgebraic.division_advance(job, fuel) {
        Ok(DivisionReady(value, proof)) =>
          Ok(StepReady(value, DivisionStep(proof)))
        Ok(DivisionPaused(job)) => Ok(StepPaused(DivisionJob(job)))
        Err(error) => Err(error)
      }
  }
}
