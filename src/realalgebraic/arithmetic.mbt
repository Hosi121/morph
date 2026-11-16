///|
fn width(value : @sturm.Interval) -> @exact.Rational {
  @exact.rational_subtract(value.upper, value.lower)
}

///|
fn padded(
  lower : @exact.Rational,
  upper : @exact.Rational,
  padding : @exact.Rational,
) -> @sturm.Interval {
  {
    lower: @exact.rational_subtract(lower, padding),
    upper: @exact.rational_add(upper, padding),
  }
}

///|
/// Use a closed relaxation of both input intervals, then strictly pad both ends.
/// Padding by the sum of widths tends to zero under paired bisection. This is
/// essential when a product's extremum equals the excluded lower endpoint.
fn binary_interval(
  a : @sturm.Interval,
  b : @sturm.Interval,
  operation : BinaryOperation,
) -> @sturm.Interval {
  let padding = @exact.rational_add(width(a), width(b))
  match operation {
    Sum =>
      padded(
        @exact.rational_add(a.lower, b.lower),
        @exact.rational_add(a.upper, b.upper),
        padding,
      )
    Product => {
      let ll = @exact.rational_multiply(a.lower, b.lower)
      let lu = @exact.rational_multiply(a.lower, b.upper)
      let ul = @exact.rational_multiply(a.upper, b.lower)
      let uu = @exact.rational_multiply(a.upper, b.upper)
      padded(
        qmin(qmin(ll, lu), qmin(ul, uu)),
        qmax(qmax(ll, lu), qmax(ul, uu)),
        padding,
      )
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct ArithmeticCertificate {
  left : RootCertificate
  right : RootCertificate
  left_refined : @sturm.Interval
  right_refined : @sturm.Interval
  resultant : ResultantCertificate
  result : RootCertificate
}

///|
pub extend ArithmeticCertificate with Eq::{equal, not_equal}

///|
pub extend ArithmeticCertificate with Debug::{to_repr}

///|
/// Validate the resultant identity and root-selection enclosure separately.
/// No interpolation or refinement search is replayed by this checker.
pub fn check_arithmetic(proof : ArithmeticCertificate) -> Bool {
  if !check_resultant(proof.resultant) {
    false
  } else {
    match
      (
        number(proof.left),
        number(proof.right),
        @sturm.system(proof.resultant.polynomial),
      ) {
      (Ok(a), Ok(b), Ok(system)) =>
        match
          (
            same_root_refinement(a, proof.left_refined),
            same_root_refinement(b, proof.right_refined),
          ) {
          (Some(ar), Some(br)) =>
            proof.resultant.left.equal(definition(a)) &&
            proof.resultant.right.equal(definition(b)) &&
            proof.result.polynomial.equal(@sturm.squarefree(system)) &&
            proof.result.interval.equal(
              binary_interval(
                ar.interval,
                br.interval,
                proof.resultant.operation,
              ),
            ) &&
            check_root(proof.result)
          _ => false
        }
      _ => false
    }
  }
}

///|
#derive(Debug)
enum ArithmeticPhase {
  Computing(Resultant)
  Selecting(ResultantCertificate, @sturm.System)
}

///|
pub extend ArithmeticPhase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Arithmetic {
  original_left : RootCertificate
  original_right : RootCertificate
  left : Number
  right : Number
  operation : BinaryOperation
  phase : ArithmeticPhase
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
  operation : BinaryOperation,
) -> Result[Arithmetic, AlgebraError] {
  match resultant_start(definition(left), definition(right), operation) {
    Err(error) => Err(error)
    Ok(state) =>
      Ok({
        original_left: root_certificate(left),
        original_right: root_certificate(right),
        left,
        right,
        operation,
        phase: Computing(state),
      })
  }
}

///|
/// Fuel counts resultant sample points, followed by paired root bisections.
/// A ready result always has a checked single-root enclosure of the operation.
pub fn arithmetic_advance(
  state : Arithmetic,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, AlgebraError] {
  match state.phase {
    Computing(job) =>
      match resultant_advance(job, Zero) {
        Err(error) => Err(error)
        Ok(ResultantReady(proof)) =>
          match @sturm.system(proof.polynomial) {
            Ok(system) =>
              arithmetic_advance(
                { ..state, phase: Selecting(proof, system), },
                fuel,
              )
            Err(_) => Err(InternalInvariant)
          }
        Ok(ResultantPaused(_)) =>
          match fuel {
            Zero => Ok(ArithmeticPaused(state))
            Succ(rest) =>
              match resultant_advance(job, Succ(Zero)) {
                Err(error) => Err(error)
                Ok(ResultantPaused(next)) =>
                  arithmetic_advance({ ..state, phase: Computing(next), }, rest)
                Ok(ResultantReady(proof)) =>
                  match @sturm.system(proof.polynomial) {
                    Ok(system) =>
                      arithmetic_advance(
                        { ..state, phase: Selecting(proof, system), },
                        rest,
                      )
                    Err(_) => Err(InternalInvariant)
                  }
              }
          }
      }
    Selecting(proof, system) => {
      let enclosure = binary_interval(
        state.left.interval,
        state.right.interval,
        state.operation,
      )
      match @sturm.count_between(system, enclosure.lower, enclosure.upper) {
        Some(Succ(Zero)) => {
          let value : Number = { system, interval: enclosure, }
          Ok(
            ArithmeticReady(value, {
              left: state.original_left,
              right: state.original_right,
              left_refined: state.left.interval,
              right_refined: state.right.interval,
              resultant: proof,
              result: root_certificate(value),
            }),
          )
        }
        Some(Succ(Succ(_))) =>
          match fuel {
            Zero => Ok(ArithmeticPaused(state))
            Succ(rest) =>
              match
                (
                  refine(state.left, Succ(Zero)),
                  refine(state.right, Succ(Zero)),
                ) {
                (Ok(left), Ok(right)) =>
                  arithmetic_advance({ ..state, left, right, }, rest)
                _ => Err(InternalInvariant)
              }
          }
        _ => Err(InternalInvariant)
      }
    }
  }
}

///|
pub fn add(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, AlgebraError] {
  match arithmetic_start(left, right, Sum) {
    Ok(state) => arithmetic_advance(state, fuel)
    Err(error) => Err(error)
  }
}

///|
pub fn multiply(
  left : Number,
  right : Number,
  fuel : @core.Nat,
) -> Result[ArithmeticProgress, AlgebraError] {
  match arithmetic_start(left, right, Product) {
    Ok(state) => arithmetic_advance(state, fuel)
    Err(error) => Err(error)
  }
}
