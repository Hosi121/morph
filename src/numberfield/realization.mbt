///|
#derive(Eq, Debug)
pub(all) struct RealCertificate {
  context : @real.RootCertificate
  input : @poly.Polynomial
  refined : @real.RootCertificate
  result : @real.RootCertificate
}

///|
pub extend RealCertificate with Eq::{equal, not_equal}

///|
pub extend RealCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Realization {
  input : Element
  polynomial : @poly.Polynomial
  root : @real.Number
  padding : @exact.Rational
}

///|
pub extend Realization with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum RealProgress {
  RealReady(@real.Number, RealCertificate)
  RealPaused(Realization)
}

///|
pub extend RealProgress with Debug::{to_repr}

///|
fn rational_less(a : @exact.Rational, b : @exact.Rational) -> Bool {
  @exact.rational_compare(a, b).equal(Less)
}

///|
fn rational_leq(a : @exact.Rational, b : @exact.Rational) -> Bool {
  !@exact.rational_compare(a, b).equal(Greater)
}

///|
/// Closed interval product, including all four endpoint combinations.
fn interval_product(
  a : @sturm.Interval,
  b : @sturm.Interval,
) -> @sturm.Interval {
  let first = @exact.rational_multiply(a.lower, b.lower)
  @core.fold_left(
    Cons(
      @exact.rational_multiply(a.lower, b.upper),
      Cons(
        @exact.rational_multiply(a.upper, b.lower),
        Cons(@exact.rational_multiply(a.upper, b.upper), Nil),
      ),
    ),
    @sturm.Interval::{ lower: first, upper: first, },
    fn(bounds, c) {
      @sturm.Interval::{
        lower: if rational_less(c, bounds.lower) {
          c
        } else {
          bounds.lower
        },
        upper: if rational_less(bounds.upper, c) {
          c
        } else {
          bounds.upper
        },
      }
    },
  )
}

///|
fn interval_image(
  polynomial : @poly.Polynomial,
  input : @sturm.Interval,
) -> @sturm.Interval {
  let count : @core.Nat = match polynomial_degree(polynomial) {
    None => Zero
    Some(d) => Succ(d)
  }
  @core.fold_left(
    @core.reverse(@core.indices(count)),
    @sturm.Interval::{
      lower: @exact.rational_zero(),
      upper: @exact.rational_zero(),
    },
    fn(accumulated, i) {
      let product = interval_product(accumulated, input)
      let c = coefficient(polynomial, i)
      @sturm.Interval::{
        lower: @exact.rational_add(product.lower, c),
        upper: @exact.rational_add(product.upper, c),
      }
    },
  )
}

///|
/// Computes the finite-dimensional dependence once. Fuel in advance bounds
/// root-isolation attempts only, not this exact linear algebra preprocessing.
pub fn realize_start(value : Element) -> Result[Realization, FieldError] {
  let polynomial = match minimal_polynomial(value) {
    Ok(polynomial) => polynomial
    Err(error) => return Err(error)
  }
  match @real.number(embedding(value.field)) {
    Err(_) => Err(InternalInvariant)
    Ok(root) =>
      Ok({ input: value, polynomial, root, padding: @exact.rational_one(), })
  }
}

///|
/// Each fuel unit checks one padded image interval and, if necessary, refines
/// alpha once and halves the padding. Paused never claims a selected result.
pub fn realize_advance(
  state : Realization,
  fuel : @core.Nat,
) -> Result[RealProgress, FieldError] {
  match fuel {
    Zero => Ok(RealPaused(state))
    Succ(rest) => {
      let bounds = interval_image(
        state.input.residue,
        @real.interval(state.root),
      )
      let interval : @sturm.Interval = {
        lower: @exact.rational_subtract(bounds.lower, state.padding),
        upper: @exact.rational_add(bounds.upper, state.padding),
      }
      match @real.number({ polynomial: state.polynomial, interval, }) {
        Ok(value) =>
          Ok(
            RealReady(value, {
              context: embedding(state.input.field),
              input: state.input.residue,
              refined: @real.root_certificate(state.root),
              result: @real.root_certificate(value),
            }),
          )
        Err(@real.InvalidInterval) =>
          match @real.refine(state.root, Succ(Zero)) {
            Err(_) => Err(InternalInvariant)
            Ok(root) =>
              realize_advance(
                { ..state, root, padding: @exact.rational_half(state.padding), },
                rest,
              )
          }
        Err(_) => Err(InternalInvariant)
      }
    }
  }
}

///|
pub fn realize(
  value : Element,
  fuel : @core.Nat,
) -> Result[RealProgress, FieldError] {
  match realize_start(value) {
    Err(error) => Err(error)
    Ok(state) => realize_advance(state, fuel)
  }
}

///|
/// Independent proof check: minimality by quotient rank, same selected alpha
/// by nested isolating intervals, and the exact closed image strictly
/// above the result's lower endpoint and at or below its upper endpoint.
pub fn check_realization(input : Element, proof : RealCertificate) -> Bool {
  let context = embedding(input.field)
  if !proof.context.equal(context) ||
    !proof.input.equal(input.residue) ||
    !proof.refined.polynomial.equal(context.polynomial) ||
    !rational_leq(context.interval.lower, proof.refined.interval.lower) ||
    !rational_leq(proof.refined.interval.upper, context.interval.upper) ||
    !@real.check_root(proof.refined) ||
    !@real.check_root(proof.result) ||
    !check_minimal_polynomial(input, proof.result.polynomial) {
    return false
  }
  let bounds = interval_image(input.residue, proof.refined.interval)
  rational_less(proof.result.interval.lower, bounds.lower) &&
  rational_leq(bounds.upper, proof.result.interval.upper)
}

///|
/// Bind the separately supplied Number payload to the checked result proof.
pub fn check_realization_result(
  input : Element,
  value : @real.Number,
  proof : RealCertificate,
) -> Bool {
  @real.root_certificate(value).equal(proof.result) &&
  check_realization(input, proof)
}
