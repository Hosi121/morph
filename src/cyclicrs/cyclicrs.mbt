///|
/// Narrow-sense cyclic RS, or its zero-shortened version when length<order.
/// Words are ascending polynomial coefficients; low coefficients are parity.
#derive(Eq, Debug)
pub struct Plan {
  field : @galois.Field
  root : @galois.Element
  order : @core.Nat
  length : @core.Nat
  errors : @core.Nat
  parity : @core.Nat
  message_size : @core.Nat
  generator : @core.Chain[@galois.Element]
  roots : @core.Chain[@galois.Element]
  inverse_points : @core.Chain[@galois.Element]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CodeError {
  InvalidPlan
  LengthMismatch
  FieldMismatch
  Uncorrectable
  Arithmetic(@galois.FieldError)
  Recurrence(@recurrence.CheckedError[@galois.FieldError])
}

///|
pub extend CodeError with Eq::{equal, not_equal}

///|
pub extend CodeError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Decoded {
  message : @core.Chain[@galois.Element]
  corrected : @core.Chain[@galois.Element]
  error_positions : @core.Chain[@core.Nat]
  error_values : @core.Chain[@galois.Element]
}

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with Debug::{to_repr}

///|
fn[A] arithmetic(
  result : Result[A, @galois.FieldError],
) -> Result[A, CodeError] {
  match result {
    Ok(value) => Ok(value)
    Err(error) => Err(Arithmetic(error))
  }
}

///|
fn trim(values : @core.Chain[@galois.Element]) -> @core.Chain[@galois.Element] {
  match values {
    Nil => Nil
    Cons(value, rest) => {
      let rest = trim(rest)
      match (rest, @galois.is_zero(value)) {
        (Nil, true) => Nil
        _ => Cons(value, rest)
      }
    }
  }
}

///|
fn polynomial_add(
  a : @core.Chain[@galois.Element],
  b : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match (a, b) {
    (Nil, _) => Ok(b)
    (_, Nil) => Ok(a)
    (Cons(x, xs), Cons(y, ys)) =>
      match (@galois.add(x, y), polynomial_add(xs, ys)) {
        (Ok(head), Ok(tail)) => Ok(trim(Cons(head, tail)))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn polynomial_subtract(
  a : @core.Chain[@galois.Element],
  b : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  polynomial_add(a, @core.map(b, @galois.negate))
}

///|
fn polynomial_scale(
  values : @core.Chain[@galois.Element],
  scalar : @galois.Element,
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match (@galois.multiply(value, scalar), polynomial_scale(rest, scalar)) {
        (Ok(head), Ok(tail)) => Ok(trim(Cons(head, tail)))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn polynomial_multiply(
  field : @galois.Field,
  a : @core.Chain[@galois.Element],
  b : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match a {
    Nil => Ok(Nil)
    Cons(head, tail) =>
      match (polynomial_scale(b, head), polynomial_multiply(field, tail, b)) {
        (Ok(head), Ok(tail)) =>
          polynomial_add(head, trim(Cons(@galois.zero(field), tail)))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn polynomial_evaluate(
  field : @galois.Field,
  values : @core.Chain[@galois.Element],
  point : @galois.Element,
) -> Result[@galois.Element, @galois.FieldError] {
  match values {
    Nil => Ok(@galois.zero(field))
    Cons(value, rest) =>
      match polynomial_evaluate(field, rest, point) {
        Err(error) => Err(error)
        Ok(tail) =>
          match @galois.multiply(point, tail) {
            Err(error) => Err(error)
            Ok(product) => @galois.add(value, product)
          }
      }
  }
}

///|
fn remainder_loop(
  field : @galois.Field,
  value : @core.Chain[@galois.Element],
  divisor : @core.Chain[@galois.Element],
  inverse_leading : @galois.Element,
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match
    (
      @core.compare(@core.length(value), @core.length(divisor)),
      @core.last(value),
    ) {
    (Less, _) | (_, None) => Ok(value)
    (_, Some(leading)) =>
      match @galois.multiply(leading, inverse_leading) {
        Err(error) => Err(error)
        Ok(scalar) =>
          match polynomial_scale(divisor, scalar) {
            Err(error) => Err(error)
            Ok(scaled) => {
              let shifted = @core.append(
                @core.replicate(
                  @core.subtract(@core.length(value), @core.length(divisor)),
                  @galois.zero(field),
                ),
                scaled,
              )
              match polynomial_subtract(value, shifted) {
                Err(error) => Err(error)
                Ok(next) =>
                  remainder_loop(field, next, divisor, inverse_leading)
              }
            }
          }
      }
  }
}

///|
fn polynomial_remainder(
  field : @galois.Field,
  value : @core.Chain[@galois.Element],
  divisor : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match @core.last(divisor) {
    None => Err(@galois.ZeroDivisor)
    Some(leading) =>
      match @galois.inverse(leading) {
        Err(error) => Err(error)
        Ok(inverse_leading) =>
          remainder_loop(field, trim(value), divisor, inverse_leading)
      }
  }
}

///|
fn powers(
  root : @galois.Element,
  current : @galois.Element,
  remaining : @core.Nat,
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match remaining {
    Zero => Ok(Nil)
    Succ(rest) =>
      match @galois.multiply(current, root) {
        Err(error) => Err(error)
        Ok(next) =>
          match powers(root, next, rest) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons(current, tail))
          }
      }
  }
}

///|
fn exact_order(
  root : @galois.Element,
  current : @galois.Element,
  remaining : @core.Nat,
) -> Result[Bool, @galois.FieldError] {
  match remaining {
    Zero => Ok(false)
    Succ(rest) =>
      match @galois.multiply(current, root) {
        Err(error) => Err(error)
        Ok(next) =>
          match next.equal(@galois.one(@galois.field_of(root))) {
            true => Ok(@core.is_zero(rest))
            false => exact_order(root, next, rest)
          }
      }
  }
}

///|
fn invert_all(
  values : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match (@galois.inverse(value), invert_all(rest)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn generator_product(
  field : @galois.Field,
  roots : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match roots {
    Nil => Ok(Cons(@galois.one(field), Nil))
    Cons(root, rest) =>
      match generator_product(field, rest) {
        Err(error) => Err(error)
        Ok(tail) =>
          polynomial_multiply(
            field,
            Cons(@galois.negate(root), Cons(@galois.one(field), Nil)),
            tail,
          )
      }
  }
}

///|
/// Verify the claimed exact order by visiting all smaller positive powers.
/// Require 2*t<length<=order<=q-1. Equality length=order is the cyclic case;
/// shorter lengths are zero-shortened mother codes with the same generator.
pub fn plan(
  field : @galois.Field,
  root : @galois.Element,
  order : @core.Nat,
  length : @core.Nat,
  errors : @core.Nat,
) -> Result[Plan, CodeError] {
  let parity = @core.add(errors, errors)
  match @galois.field_of(root).equal(field) {
    false => return Err(FieldMismatch)
    true => ()
  }
  let valid = !@galois.is_zero(root) &&
    !@core.is_zero(order) &&
    @core.compare(parity, length) is Less &&
    !(@core.compare(length, order) is Greater)
  match (valid, @binary.subtract(@galois.cardinality(field), @binary.one())) {
    (true, Some(maximum)) =>
      match @binary.compare(@binary.from_nat(order), maximum) {
        Greater => Err(InvalidPlan)
        _ =>
          match arithmetic(exact_order(root, @galois.one(field), order)) {
            Err(error) => Err(error)
            Ok(false) => Err(InvalidPlan)
            Ok(true) =>
              match
                (
                  arithmetic(powers(root, root, parity)),
                  arithmetic(powers(root, @galois.one(field), length)),
                ) {
                (Ok(roots), Ok(points)) =>
                  match
                    (
                      arithmetic(generator_product(field, roots)),
                      arithmetic(invert_all(points)),
                    ) {
                    (Ok(generator), Ok(inverse_points)) =>
                      Ok({
                        field,
                        root,
                        order,
                        length,
                        errors,
                        parity,
                        message_size: @core.subtract(length, parity),
                        generator,
                        roots,
                        inverse_points,
                      })
                    (Err(error), _) | (_, Err(error)) => Err(error)
                  }
                (Err(error), _) | (_, Err(error)) => Err(error)
              }
          }
      }
    _ => Err(InvalidPlan)
  }
}

///|
pub fn length(plan : Plan) -> @core.Nat {
  plan.length
}

///|
pub fn message_size(plan : Plan) -> @core.Nat {
  plan.message_size
}

///|
pub fn radius(plan : Plan) -> @core.Nat {
  plan.errors
}

///|
pub fn root(plan : Plan) -> @galois.Element {
  plan.root
}

///|
pub fn root_order(plan : Plan) -> @core.Nat {
  plan.order
}

///|
pub fn field_of(plan : Plan) -> @galois.Field {
  plan.field
}

///|
pub fn generator_polynomial(plan : Plan) -> @core.Chain[@galois.Element] {
  plan.generator
}

///|
fn check_word(
  plan : Plan,
  word : @core.Chain[@galois.Element],
  size : @core.Nat,
) -> CodeError? {
  match @core.compare(@core.length(word), size) {
    Equal =>
      match
        @core.all(word, fn(value) { @galois.field_of(value).equal(plan.field) }) {
        true => None
        false => Some(FieldMismatch)
      }
    _ => Some(LengthMismatch)
  }
}

///|
pub fn encode(
  plan : Plan,
  message : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match check_word(plan, message, plan.message_size) {
    Some(error) => Err(error)
    None => {
      let shifted = @core.append(
        @core.replicate(plan.parity, @galois.zero(plan.field)),
        message,
      )
      match
        arithmetic(polynomial_remainder(plan.field, shifted, plan.generator)) {
        Err(error) => Err(error)
        Ok(remainder) =>
          match arithmetic(polynomial_subtract(shifted, remainder)) {
            Err(error) => Err(error)
            Ok(word) =>
              Ok(
                @core.take(
                  plan.length,
                  @core.append(
                    word,
                    @core.replicate(plan.length, @galois.zero(plan.field)),
                  ),
                ),
              )
          }
      }
    }
  }
}

///|
pub fn syndrome(
  plan : Plan,
  received : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  fn bins(
    roots : @core.Chain[@galois.Element],
  ) -> Result[@core.Chain[@galois.Element], CodeError] {
    match roots {
      Nil => Ok(Nil)
      Cons(root, rest) =>
        match
          (
            arithmetic(polynomial_evaluate(plan.field, received, root)),
            bins(rest),
          ) {
          (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  match check_word(plan, received, plan.length) {
    Some(error) => Err(error)
    None => bins(plan.roots)
  }
}

///|
fn bm_field(
  field : @galois.Field,
) -> @recurrence.CheckedField[@galois.Element, @galois.FieldError] {
  {
    zero: @galois.zero(field),
    one: @galois.one(field),
    add: @galois.add,
    subtract: @galois.subtract,
    multiply: @galois.multiply,
    negate: fn(value) { Ok(@galois.negate(value)) },
    inverse: fn(value) {
      match @galois.inverse(value) {
        Ok(inverse) => Ok(Some(inverse))
        Err(@galois.ZeroDivisor) => Ok(None)
        Err(error) => Err(error)
      }
    },
  }
}

///|
priv struct Location {
  position : @core.Nat
  inverse_point : @galois.Element
}

///|
fn chien(
  plan : Plan,
  locator : @core.Chain[@galois.Element],
  points : @core.Chain[@galois.Element],
  index : @core.Nat,
) -> Result[@core.Chain[Location], CodeError] {
  match points {
    Nil => Ok(Nil)
    Cons(point, rest) =>
      match
        (
          arithmetic(polynomial_evaluate(plan.field, locator, point)),
          chien(plan, locator, rest, Succ(index)),
        ) {
        (Ok(value), Ok(tail)) =>
          match @galois.is_zero(value) {
            true => Ok(Cons({ position: index, inverse_point: point, }, tail))
            false => Ok(tail)
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn derivative(
  plan : Plan,
  polynomial : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  fn visit(
    values : @core.Chain[@galois.Element],
    exponent : @binary.Binary,
  ) -> Result[@core.Chain[@galois.Element], CodeError] {
    match values {
      Nil => Ok(Nil)
      Cons(value, rest) =>
        match
          (
            arithmetic(
              @galois.multiply(value, @galois.constant(plan.field, exponent)),
            ),
            visit(rest, @binary.successor(exponent)),
          ) {
          (Ok(head), Ok(tail)) => Ok(trim(Cons(head, tail)))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  match polynomial {
    Nil => Ok(Nil)
    Cons(_, rest) => visit(rest, @binary.one())
  }
}

///|
fn forney(
  plan : Plan,
  evaluator : @core.Chain[@galois.Element],
  derivative : @core.Chain[@galois.Element],
  locations : @core.Chain[Location],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match locations {
    Nil => Ok(Nil)
    Cons(location, rest) =>
      match
        (
          arithmetic(
            polynomial_evaluate(plan.field, evaluator, location.inverse_point),
          ),
          arithmetic(
            polynomial_evaluate(plan.field, derivative, location.inverse_point),
          ),
        ) {
        (Ok(numerator), Ok(denominator)) =>
          match @galois.divide(@galois.negate(numerator), denominator) {
            Err(@galois.ZeroDivisor) => Err(Uncorrectable)
            Err(error) => Err(Arithmetic(error))
            Ok(value) =>
              match @galois.is_zero(value) {
                true => Err(Uncorrectable)
                false =>
                  match forney(plan, evaluator, derivative, rest) {
                    Err(error) => Err(error)
                    Ok(tail) => Ok(Cons(value, tail))
                  }
              }
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn apply_correction(
  received : @core.Chain[@galois.Element],
  locations : @core.Chain[Location],
  magnitudes : @core.Chain[@galois.Element],
  index : @core.Nat,
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match (received, locations, magnitudes) {
    (Nil, Nil, Nil) => Ok(Nil)
    (Cons(value, rest), Cons(location, tail), Cons(error, errors)) =>
      match @core.compare(index, location.position) {
        Equal =>
          match
            (
              arithmetic(@galois.subtract(value, error)),
              apply_correction(rest, tail, errors, Succ(index)),
            ) {
            (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
            (Err(error), _) | (_, Err(error)) => Err(error)
          }
        Less =>
          match apply_correction(rest, locations, magnitudes, Succ(index)) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons(value, tail))
          }
        Greater => Err(Uncorrectable)
      }
    (Cons(value, rest), Nil, Nil) =>
      match apply_correction(rest, Nil, Nil, Succ(index)) {
        Err(error) => Err(error)
        Ok(tail) => Ok(Cons(value, tail))
      }
    _ => Err(Uncorrectable)
  }
}

///|
/// BM -> Chien -> Forney, followed by a complete syndrome recheck.
/// Corrects up to the configured radius. Beyond it, failure or a different
/// nearby codeword is possible; success is not an original-message guarantee.
pub fn decode(
  plan : Plan,
  received : @core.Chain[@galois.Element],
) -> Result[Decoded, CodeError] {
  match syndrome(plan, received) {
    Err(error) => Err(error)
    Ok(syndromes) =>
      match
        @recurrence.checked_berlekamp_massey(bm_field(plan.field), syndromes) {
        Err(error) => Err(Recurrence(error))
        Ok(recurrence) =>
          match @core.compare(recurrence.length, plan.errors) {
            Greater => Err(Uncorrectable)
            _ =>
              match
                @recurrence.checked_check(
                  bm_field(plan.field),
                  syndromes,
                  recurrence,
                ) {
                Err(error) => Err(Recurrence(error))
                Ok(false) => Err(Uncorrectable)
                Ok(true) =>
                  match @core.last(recurrence.connection) {
                    None => Err(Uncorrectable)
                    Some(last) =>
                      match @galois.is_zero(last) {
                        true => Err(Uncorrectable)
                        false =>
                          match
                            chien(
                              plan,
                              recurrence.connection,
                              plan.inverse_points,
                              Zero,
                            ) {
                            Err(error) => Err(error)
                            Ok(locations) =>
                              match
                                @core.compare(
                                  @core.length(locations),
                                  recurrence.length,
                                ) {
                                Less | Greater => Err(Uncorrectable)
                                Equal =>
                                  match
                                    (
                                      arithmetic(
                                        polynomial_multiply(
                                          plan.field,
                                          syndromes,
                                          recurrence.connection,
                                        ),
                                      ),
                                      derivative(plan, recurrence.connection),
                                    ) {
                                    (Ok(product), Ok(derivative)) =>
                                      match
                                        forney(
                                          plan,
                                          @core.take(plan.parity, product),
                                          derivative,
                                          locations,
                                        ) {
                                        Err(error) => Err(error)
                                        Ok(magnitudes) =>
                                          match
                                            apply_correction(
                                              received,
                                              locations,
                                              magnitudes,
                                              Zero,
                                            ) {
                                            Err(error) => Err(error)
                                            Ok(corrected) =>
                                              match syndrome(plan, corrected) {
                                                Err(error) => Err(error)
                                                Ok(checked) =>
                                                  match
                                                    @core.all(
                                                      checked, @galois.is_zero,
                                                    ) {
                                                    false => Err(Uncorrectable)
                                                    true =>
                                                      Ok({
                                                        message: @core.drop(
                                                          plan.parity,
                                                          corrected,
                                                        ),
                                                        corrected,
                                                        error_positions: @core.map(
                                                          locations,
                                                          fn(location) {
                                                            location.position
                                                          },
                                                        ),
                                                        error_values: magnitudes,
                                                      })
                                                  }
                                              }
                                          }
                                      }
                                    (Err(error), _) | (_, Err(error)) =>
                                      Err(error)
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
fn differences(
  received : @core.Chain[@galois.Element],
  corrected : @core.Chain[@galois.Element],
  index : @core.Nat,
) -> Result[(@core.Chain[@core.Nat], @core.Chain[@galois.Element]), CodeError] {
  match (received, corrected) {
    (Nil, Nil) => Ok((Nil, Nil))
    (Cons(a, xs), Cons(b, ys)) =>
      match
        (arithmetic(@galois.subtract(a, b)), differences(xs, ys, Succ(index))) {
        (Ok(value), Ok((positions, values))) =>
          match @galois.is_zero(value) {
            true => Ok((positions, values))
            false => Ok((Cons(index, positions), Cons(value, values)))
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(LengthMismatch)
  }
}

///|
/// Independent result check: reencode the systematic message, inspect actual
/// differences and check their count/metadata. No BM, Chien or Forney is run.
pub fn check(
  plan : Plan,
  received : @core.Chain[@galois.Element],
  decoded : Decoded,
) -> Bool {
  match
    (
      check_word(plan, received, plan.length),
      check_word(plan, decoded.corrected, plan.length),
    ) {
    (None, None) =>
      match
        (
          encode(plan, decoded.message),
          differences(received, decoded.corrected, Zero),
        ) {
        (Ok(encoded), Ok((positions, values))) =>
          encoded.equal(decoded.corrected) &&
          positions.equal(decoded.error_positions) &&
          values.equal(decoded.error_values) &&
          !(@core.compare(@core.length(positions), plan.errors) is Greater)
        _ => false
      }
    _ => false
  }
}
