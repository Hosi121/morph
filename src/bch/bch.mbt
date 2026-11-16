///|
/// Full-length primitive narrow-sense binary BCH. Every word is an ascending
/// Boolean coefficient chain; the low coefficients are systematic parity.
#derive(Eq, Debug)
pub struct Plan {
  field : @galois.Field
  root : @galois.Element
  length : @core.Nat
  errors : @core.Nat
  parity : @core.Nat
  message_size : @core.Nat
  generator : @core.Chain[Bool]
  factors : @core.Chain[MinimalPolynomial]
  roots : @core.Chain[@galois.Element]
  inverse_points : @core.Chain[@galois.Element]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
/// A complete Frobenius orbit and its reconstructed polynomial over F₂.
#derive(Eq, Debug)
pub(all) struct MinimalPolynomial {
  conjugates : @core.Chain[@galois.Element]
  coefficients : @core.Chain[Bool]
}

///|
pub extend MinimalPolynomial with Eq::{equal, not_equal}

///|
pub extend MinimalPolynomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CodeError {
  InvalidPlan
  FieldMismatch
  LengthMismatch
  Uncorrectable
  NonbinaryCoefficient
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
  message : @core.Chain[Bool]
  corrected : @core.Chain[Bool]
  error_positions : @core.Chain[@core.Nat]
}

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with Debug::{to_repr}

///|
fn bit_trim(values : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match values {
    Nil => Nil
    Cons(value, rest) => {
      let rest = bit_trim(rest)
      match (rest, value) {
        (Nil, false) => Nil
        _ => Cons(value, rest)
      }
    }
  }
}

///|
fn bit_add(a : @core.Chain[Bool], b : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      bit_trim(Cons(!(x && y) && (x || y), bit_add(xs, ys)))
  }
}

///|
fn bit_multiply(
  a : @core.Chain[Bool],
  b : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match a {
    Nil => Nil
    Cons(head, tail) =>
      bit_add(
        if head {
          b
        } else {
          Nil
        },
        bit_trim(Cons(false, bit_multiply(tail, b))),
      )
  }
}

///|
fn bit_remainder(
  value : @core.Chain[Bool],
  divisor : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  let value = bit_trim(value)
  match @core.compare(@core.length(value), @core.length(divisor)) {
    Less => value
    _ =>
      bit_remainder(
        bit_add(
          value,
          @core.append(
            @core.replicate(
              @core.subtract(@core.length(value), @core.length(divisor)),
              false,
            ),
            divisor,
          ),
        ),
        divisor,
      )
  }
}

///|
fn lift(
  field : @galois.Field,
  values : @core.Chain[Bool],
) -> @core.Chain[@galois.Element] {
  @core.map(values, fn(bit) {
    if bit {
      @galois.one(field)
    } else {
      @galois.zero(field)
    }
  })
}

///|
fn lower(
  field : @galois.Field,
  values : @core.Chain[@galois.Element],
) -> Result[@core.Chain[Bool], CodeError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) => {
      let bit = if value.equal(@galois.zero(field)) {
        false
      } else if value.equal(@galois.one(field)) {
        true
      } else {
        return Err(NonbinaryCoefficient)
      }
      match lower(field, rest) {
        Ok(tail) => Ok(Cons(bit, tail))
        Err(error) => Err(error)
      }
    }
  }
}

///|
fn field_scale(
  values : @core.Chain[@galois.Element],
  scalar : @galois.Element,
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match
        (arithmetic(@galois.multiply(value, scalar)), field_scale(rest, scalar)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn field_add(
  a : @core.Chain[@galois.Element],
  b : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match (a, b) {
    (Nil, _) => Ok(b)
    (_, Nil) => Ok(a)
    (Cons(x, xs), Cons(y, ys)) =>
      match (arithmetic(@galois.add(x, y)), field_add(xs, ys)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn orbit_product(
  field : @galois.Field,
  roots : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  match roots {
    Nil => Ok(Cons(@galois.one(field), Nil))
    Cons(root, rest) =>
      match orbit_product(field, rest) {
        Err(error) => Err(error)
        Ok(tail) =>
          match field_scale(tail, root) {
            Err(error) => Err(error)
            Ok(scaled) => field_add(scaled, Cons(@galois.zero(field), tail))
          }
      }
  }
}

///|
fn contains(
  values : @core.Chain[@galois.Element],
  value : @galois.Element,
) -> Bool {
  @core.any(values, fn(other) { other.equal(value) })
}

///|
fn conjugates(
  field : @galois.Field,
  start : @galois.Element,
) -> Result[@core.Chain[@galois.Element], CodeError] {
  fn visit(
    current : @galois.Element,
    remaining : @core.Nat,
    seen : @core.Chain[@galois.Element],
  ) -> Result[@core.Chain[@galois.Element], CodeError] {
    if contains(seen, current) {
      if current.equal(start) {
        Ok(@core.reverse(seen))
      } else {
        Err(InvalidPlan)
      }
    } else {
      match remaining {
        Zero => Err(InvalidPlan)
        Succ(rest) =>
          match arithmetic(@galois.frobenius(current)) {
            Err(error) => Err(error)
            Ok(next) => visit(next, rest, Cons(current, seen))
          }
      }
    }
  }
  visit(start, @galois.degree(field), Nil)
}

///|
fn minimal_factors(
  field : @galois.Field,
  roots : @core.Chain[@galois.Element],
  seen : @core.Chain[@galois.Element],
) -> Result[@core.Chain[MinimalPolynomial], CodeError] {
  match roots {
    Nil => Ok(Nil)
    Cons(root, rest) =>
      if contains(seen, root) {
        minimal_factors(field, rest, seen)
      } else {
        match conjugates(field, root) {
          Err(error) => Err(error)
          Ok(orbit) =>
            match orbit_product(field, orbit) {
              Err(error) => Err(error)
              Ok(product) =>
                match
                  (
                    lower(field, product),
                    minimal_factors(field, rest, @core.append(orbit, seen)),
                  ) {
                  (Ok(coefficients), Ok(tail)) =>
                    Ok(Cons({ conjugates: orbit, coefficients, }, tail))
                  (Err(error), _) | (_, Err(error)) => Err(error)
                }
            }
        }
      }
  }
}

///|
fn factor_product(
  factors : @core.Chain[MinimalPolynomial],
) -> @core.Chain[Bool] {
  match factors {
    Nil => Cons(true, Nil)
    Cons(factor, rest) =>
      bit_multiply(factor.coefficients, factor_product(rest))
  }
}

///|
/// Require characteristic two, n=2^m−1, a root of exact order n, and 2t<n.
/// A zero radius produces the full binary space with generator one.
/// Construction enumerates all positive powers below n to verify exact order.
pub fn plan(
  field : @galois.Field,
  root : @galois.Element,
  length : @core.Nat,
  errors : @core.Nat,
) -> Result[Plan, CodeError] {
  if !@galois.field_of(root).equal(field) {
    return Err(FieldMismatch)
  }
  let two = @binary.double(@binary.one())
  let checks = @core.add(errors, errors)
  if !@galois.characteristic(field).equal(two) ||
    @core.is_zero(length) ||
    @galois.is_zero(root) ||
    !@binary.successor(@binary.from_nat(length)).equal(
      @galois.cardinality(field),
    ) ||
    !(@core.compare(checks, length) is Less) {
    return Err(InvalidPlan)
  }
  match arithmetic(exact_order(root, @galois.one(field), length)) {
    Err(error) => return Err(error)
    Ok(false) => return Err(InvalidPlan)
    Ok(true) => ()
  }
  let roots = match arithmetic(powers(root, root, checks)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let factors = match minimal_factors(field, roots, Nil) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let generator = factor_product(factors)
  let parity = match @core.length(generator) {
    Zero => return Err(InvalidPlan)
    Succ(degree) => degree
  }
  if !(@core.compare(parity, length) is Less) {
    return Err(InvalidPlan)
  }
  match arithmetic(powers(root, @galois.one(field), length)) {
    Err(error) => Err(error)
    Ok(points) =>
      match arithmetic(invert_all(points)) {
        Err(error) => Err(error)
        Ok(inverse_points) =>
          Ok({
            field,
            root,
            length,
            errors,
            parity,
            message_size: @core.subtract(length, parity),
            generator,
            factors,
            roots,
            inverse_points,
          })
      }
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
pub fn field_of(plan : Plan) -> @galois.Field {
  plan.field
}

///|
pub fn generator_polynomial(plan : Plan) -> @core.Chain[Bool] {
  plan.generator
}

///|
pub fn minimal_polynomials(plan : Plan) -> @core.Chain[MinimalPolynomial] {
  plan.factors
}

///|
pub fn encode(
  plan : Plan,
  message : @core.Chain[Bool],
) -> Result[@core.Chain[Bool], CodeError] {
  if !@core.length(message).equal(plan.message_size) {
    return Err(LengthMismatch)
  }
  let shifted = @core.append(@core.replicate(plan.parity, false), message)
  let word = bit_add(shifted, bit_remainder(shifted, plan.generator))
  Ok(
    @core.take(
      plan.length,
      @core.append(word, @core.replicate(plan.length, false)),
    ),
  )
}

///|
/// S_j=r(α^j), j=1,…,2t. The coefficient at chain index i multiplies x^i.
pub fn syndrome(
  plan : Plan,
  received : @core.Chain[Bool],
) -> Result[@core.Chain[@galois.Element], CodeError] {
  fn bins(
    roots : @core.Chain[@galois.Element],
    values : @core.Chain[@galois.Element],
  ) -> Result[@core.Chain[@galois.Element], CodeError] {
    match roots {
      Nil => Ok(Nil)
      Cons(root, rest) =>
        match
          (
            arithmetic(polynomial_evaluate(plan.field, values, root)),
            bins(rest, values),
          ) {
          (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  if !@core.length(received).equal(plan.length) {
    return Err(LengthMismatch)
  }
  bins(plan.roots, lift(plan.field, received))
}

///|
/// Independent codeword test by Boolean polynomial divisibility.
pub fn check_codeword(plan : Plan, word : @core.Chain[Bool]) -> Bool {
  if !@core.length(word).equal(plan.length) {
    return false
  }
  match bit_remainder(word, plan.generator) {
    Nil => true
    _ => false
  }
}

///|
fn chien(
  plan : Plan,
  locator : @core.Chain[@galois.Element],
  points : @core.Chain[@galois.Element],
  index : @core.Nat,
) -> Result[@core.Chain[@core.Nat], CodeError] {
  match points {
    Nil => Ok(Nil)
    Cons(point, rest) =>
      match
        (
          arithmetic(polynomial_evaluate(plan.field, locator, point)),
          chien(plan, locator, rest, Succ(index)),
        ) {
        (Ok(value), Ok(tail)) =>
          Ok(if @galois.is_zero(value) { Cons(index, tail) } else { tail })
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn flip(
  received : @core.Chain[Bool],
  positions : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> Result[@core.Chain[Bool], CodeError] {
  match (received, positions) {
    (Nil, Nil) => Ok(Nil)
    (Cons(bit, rest), Nil) => Ok(Cons(bit, rest))
    (Cons(bit, rest), Cons(position, tail)) =>
      match @core.compare(index, position) {
        Greater => Err(Uncorrectable)
        Equal =>
          match flip(rest, tail, Succ(index)) {
            Err(error) => Err(error)
            Ok(rest) => Ok(Cons(!bit, rest))
          }
        Less =>
          match flip(rest, positions, Succ(index)) {
            Err(error) => Err(error)
            Ok(rest) => Ok(Cons(bit, rest))
          }
      }
    _ => Err(Uncorrectable)
  }
}

///|
/// Checked Berlekamp–Massey followed by Chien evaluation at α^(−i).
/// Binary errors have magnitude one, so their positions are simply flipped.
/// Every success is checked for generator divisibility and distance at most t.
/// Beyond t errors, failure or a different nearby codeword is possible.
pub fn decode(
  plan : Plan,
  received : @core.Chain[Bool],
) -> Result[Decoded, CodeError] {
  let syndromes = match syndrome(plan, received) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let recurrence = match
    @recurrence.checked_berlekamp_massey(bm_field(plan.field), syndromes) {
    Err(error) => return Err(Recurrence(error))
    Ok(value) => value
  }
  if @core.compare(recurrence.length, plan.errors) is Greater {
    return Err(Uncorrectable)
  }
  match @recurrence.checked_check(bm_field(plan.field), syndromes, recurrence) {
    Err(error) => return Err(Recurrence(error))
    Ok(false) => return Err(Uncorrectable)
    Ok(true) => ()
  }
  match @core.last(recurrence.connection) {
    None => return Err(Uncorrectable)
    Some(value) => if @galois.is_zero(value) { return Err(Uncorrectable) }
  }
  let positions = match
    chien(plan, recurrence.connection, plan.inverse_points, Zero) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if !@core.length(positions).equal(recurrence.length) {
    return Err(Uncorrectable)
  }
  let corrected = match flip(received, positions, Zero) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let decoded = {
    message: @core.drop(plan.parity, corrected),
    corrected,
    error_positions: positions,
  }
  if check(plan, received, decoded) {
    Ok(decoded)
  } else {
    Err(Uncorrectable)
  }
}

///|
fn differences(
  received : @core.Chain[Bool],
  corrected : @core.Chain[Bool],
  index : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match (received, corrected) {
    (Cons(a, xs), Cons(b, ys)) => {
      let rest = differences(xs, ys, Succ(index))
      if !(a && b) && (a || b) {
        Cons(index, rest)
      } else {
        rest
      }
    }
    _ => Nil
  }
}

///|
/// Reencoding, Boolean divisibility and actual Hamming differences verify the
/// returned witness without running BM or Chien.
pub fn check(
  plan : Plan,
  received : @core.Chain[Bool],
  decoded : Decoded,
) -> Bool {
  if !@core.length(received).equal(plan.length) ||
    !check_codeword(plan, decoded.corrected) {
    return false
  }
  let positions = differences(received, decoded.corrected, Zero)
  if !positions.equal(decoded.error_positions) ||
    @core.compare(@core.length(positions), plan.errors) is Greater {
    return false
  }
  match encode(plan, decoded.message) {
    Ok(encoded) => encoded.equal(decoded.corrected)
    Err(_) => false
  }
}
