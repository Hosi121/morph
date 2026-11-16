///|
#derive(Eq, Debug)
pub(all) enum UnaryOperation {
  Negation
  Reciprocal
}

///|
pub extend UnaryOperation with Eq::{equal, not_equal}

///|
pub extend UnaryOperation with Debug::{to_repr}

///|
fn unary_polynomial(
  value : @poly.Polynomial,
  operation : UnaryOperation,
) -> @poly.Polynomial? {
  fn negative(
    values : @core.Chain[@exact.Rational],
    sign : Bool,
  ) -> @core.Chain[@exact.Rational] {
    match values {
      Nil => Nil
      Cons(head, rest) =>
        Cons(
          if sign {
            @exact.rational_negate(head)
          } else {
            head
          },
          negative(rest, !sign),
        )
    }
  }
  match dense(value) {
    None => None
    Some(values) =>
      match operation {
        Negation => sparse(negative(values, false))
        Reciprocal => sparse(trim(@core.reverse(values)))
      }
  }
}

///|
fn selected_zero(value : Number) -> Bool {
  let zero = @exact.rational_zero()
  let evaluates_zero = match
    @poly.evaluate(definition(value), Cons(zero, Nil)) {
    Some(c) => qzero(c)
    None => false
  }
  @exact.rational_compare(value.interval.lower, zero).equal(Less) &&
  !@exact.rational_compare(value.interval.upper, zero).equal(Less) &&
  evaluates_zero
}

///|
fn unary_interval(
  interval : @sturm.Interval,
  operation : UnaryOperation,
) -> @sturm.Interval? {
  match operation {
    Negation =>
      Some(
        padded(
          @exact.rational_negate(interval.upper),
          @exact.rational_negate(interval.lower),
          width(interval),
        ),
      )
    Reciprocal => {
      let zero = @exact.rational_zero()
      if @exact.rational_compare(interval.lower, zero).equal(Greater) ||
        @exact.rational_compare(interval.upper, zero).equal(Less) {
        match
          (
            @exact.rational_divide(@exact.rational_one(), interval.upper),
            @exact.rational_divide(@exact.rational_one(), interval.lower),
          ) {
          (Some(lower), Some(upper)) =>
            Some(padded(lower, upper, @exact.rational_subtract(upper, lower)))
          _ => None
        }
      } else {
        None
      }
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct UnaryCertificate {
  input : RootCertificate
  refined : @sturm.Interval
  operation : UnaryOperation
  result : RootCertificate
}

///|
pub extend UnaryCertificate with Eq::{equal, not_equal}

///|
pub extend UnaryCertificate with Debug::{to_repr}

///|
pub fn check_unary(proof : UnaryCertificate) -> Bool {
  match number(proof.input) {
    Err(_) => false
    Ok(input) =>
      match
        (
          same_root_refinement(input, proof.refined),
          unary_polynomial(definition(input), proof.operation),
        ) {
        (Some(refined), Some(polynomial)) =>
          match
            (
              unary_interval(refined.interval, proof.operation),
              @sturm.system(polynomial),
            ) {
            (Some(enclosure), Ok(system)) =>
              enclosure.equal(proof.result.interval) &&
              @sturm.squarefree(system).equal(proof.result.polynomial) &&
              check_root(proof.result)
            _ => false
          }
        _ => false
      }
  }
}

///|
#derive(Debug)
pub struct Unary {
  original : RootCertificate
  current : Number
  operation : UnaryOperation
  output : @sturm.System
}

///|
pub extend Unary with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum UnaryProgress {
  UnaryReady(Number, UnaryCertificate)
  UnaryPaused(Unary)
}

///|
pub extend UnaryProgress with Debug::{to_repr}

///|
pub fn unary_start(
  value : Number,
  operation : UnaryOperation,
) -> Result[Unary, AlgebraError] {
  if operation.equal(Reciprocal) && selected_zero(value) {
    Err(ZeroDivisor)
  } else {
    match unary_polynomial(definition(value), operation) {
      None => Err(InternalInvariant)
      Some(polynomial) =>
        match @sturm.system(polynomial) {
          Err(_) => Err(InternalInvariant)
          Ok(output) =>
            Ok({
              original: root_certificate(value),
              current: value,
              operation,
              output,
            })
        }
    }
  }
}

///|
/// Reciprocals refine until the closed interval avoids zero. Every output
/// range is padded on both sides before applying half-open Sturm root counts.
pub fn unary_advance(
  state : Unary,
  fuel : @core.Nat,
) -> Result[UnaryProgress, AlgebraError] {
  let enclosure = unary_interval(state.current.interval, state.operation)
  let count = match enclosure {
    None => None
    Some(interval) =>
      @sturm.count_between(state.output, interval.lower, interval.upper)
  }
  match (enclosure, count) {
    (Some(interval), Some(Succ(Zero))) => {
      let value : Number = { system: state.output, interval, }
      Ok(
        UnaryReady(value, {
          input: state.original,
          refined: state.current.interval,
          operation: state.operation,
          result: root_certificate(value),
        }),
      )
    }
    (Some(_), Some(Zero)) => Err(InternalInvariant)
    _ =>
      match fuel {
        Zero => Ok(UnaryPaused(state))
        Succ(rest) =>
          match refine(state.current, Succ(Zero)) {
            Ok(current) => unary_advance({ ..state, current, }, rest)
            Err(error) => Err(error)
          }
      }
  }
}

///|
pub fn negate(
  value : Number,
  fuel : @core.Nat,
) -> Result[UnaryProgress, AlgebraError] {
  match unary_start(value, Negation) {
    Ok(state) => unary_advance(state, fuel)
    Err(error) => Err(error)
  }
}

///|
pub fn inverse(
  value : Number,
  fuel : @core.Nat,
) -> Result[UnaryProgress, AlgebraError] {
  match unary_start(value, Reciprocal) {
    Ok(state) => unary_advance(state, fuel)
    Err(error) => Err(error)
  }
}
