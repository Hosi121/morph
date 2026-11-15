///|
/// Canonical sign-and-magnitude integer, with a unique zero.
#derive(Eq, Debug)
pub struct Integer {
  negative : Bool
  magnitude : @binary.Binary
}

///|
pub extend Integer with Eq::{equal, not_equal}

///|
pub extend Integer with Debug::{to_repr}

///|
pub fn positive(magnitude : @binary.Binary) -> Integer {
  { negative: false, magnitude, }
}

///|
pub fn magnitude(n : Integer) -> @binary.Binary {
  n.magnitude
}

///|
pub fn negative(n : Integer) -> Bool {
  n.negative
}

///|
pub fn negate(n : Integer) -> Integer {
  match (@binary.is_zero(n.magnitude), n.negative) {
    (true, _) => n
    (false, true) => positive(n.magnitude)
    (false, false) => { negative: true, magnitude: n.magnitude, }
  }
}

///|
pub fn add(a : Integer, b : Integer) -> Integer {
  match (@binary.is_zero(a.magnitude), @binary.is_zero(b.magnitude)) {
    (true, _) => return b
    (_, true) => return a
    _ => ()
  }
  match (a.negative, b.negative) {
    (false, false) => positive(@binary.add(a.magnitude, b.magnitude))
    (true, true) =>
      { negative: true, magnitude: @binary.add(a.magnitude, b.magnitude), }
    _ => signed_difference(a.magnitude, b.magnitude, a.negative)
  }
}

///|
fn signed_difference(
  a : @binary.Binary,
  b : @binary.Binary,
  negative : Bool,
) -> Integer {
  match @binary.subtract(a, b) {
    Some(difference) =>
      {
        negative: negative && !@binary.is_zero(difference),
        magnitude: difference,
      }
    None =>
      match @binary.subtract(b, a) {
        Some(difference) => { negative: !negative, magnitude: difference, }
        None => positive(@binary.zero())
      }
  }
}

///|
pub fn subtract(a : Integer, b : Integer) -> Integer {
  match (@binary.is_zero(a.magnitude), @binary.is_zero(b.magnitude)) {
    (_, true) => return a
    (true, _) => return negate(b)
    _ => ()
  }
  match (a.negative, b.negative) {
    (true, false) | (false, true) =>
      {
        negative: a.negative,
        magnitude: @binary.add(a.magnitude, b.magnitude),
      }
    _ => signed_difference(a.magnitude, b.magnitude, a.negative)
  }
}

///|
pub fn multiply(a : Integer, b : Integer) -> Integer {
  match (@binary.is_zero(a.magnitude), @binary.is_zero(b.magnitude)) {
    (true, _) => return a
    (_, true) => return b
    _ => ()
  }
  match is_one(a.magnitude) {
    true =>
      return match a.negative {
        true => negate(b)
        false => b
      }
    false => ()
  }
  match is_one(b.magnitude) {
    true =>
      return match b.negative {
        true => negate(a)
        false => a
      }
    false => ()
  }
  {
    negative: match (a.negative, b.negative) {
      (true, false) | (false, true) => true
      _ => false
    },
    magnitude: @binary.multiply(a.magnitude, b.magnitude),
  }
}

///|
pub fn compare(a : Integer, b : Integer) -> @core.Ordering {
  match (a.negative, b.negative) {
    (true, false) => Less
    (false, true) => Greater
    (false, false) => @binary.compare(a.magnitude, b.magnitude)
    (true, true) => @binary.compare(b.magnitude, a.magnitude)
  }
}

///|
/// Reduced fraction; denominator is strictly positive.
#derive(Eq, Debug)
pub struct Rational {
  numerator : Integer
  denominator : @binary.Binary
}

///|
pub extend Rational with Eq::{equal, not_equal}

///|
pub extend Rational with Debug::{to_repr}

///|
fn normalize(numerator : Integer, denominator : @binary.Binary) -> Rational {
  match @binary.is_zero(numerator.magnitude) {
    true => return rational_zero()
    false => ()
  }
  match is_one(denominator) || is_one(numerator.magnitude) {
    true => return { numerator, denominator, }
    false => ()
  }
  let common = common_factor(numerator.magnitude, denominator)
  match is_one(common) {
    true => { numerator, denominator, }
    false =>
      {
        numerator: integer_quotient(numerator, common),
        denominator: exact_quotient(denominator, common),
      }
  }
}

///|
pub fn ratio(numerator : Integer, denominator : @binary.Binary) -> Rational? {
  match @binary.is_zero(denominator) {
    true => None
    false => Some(normalize(numerator, denominator))
  }
}

///|
pub fn whole(numerator : Integer) -> Rational {
  { numerator, denominator: @binary.one(), }
}

///|
pub fn numerator(r : Rational) -> Integer {
  r.numerator
}

///|
pub fn denominator(r : Rational) -> @binary.Binary {
  r.denominator
}

///|
pub fn rational_zero() -> Rational {
  whole(positive(@binary.zero()))
}

///|
pub fn rational_one() -> Rational {
  whole(positive(@binary.one()))
}

///|
pub fn rational_negate(r : Rational) -> Rational {
  match @binary.is_zero(r.numerator.magnitude) {
    true => r
    false => { numerator: negate(r.numerator), denominator: r.denominator, }
  }
}

///|
pub fn rational_add(a : Rational, b : Rational) -> Rational {
  match
    (
      @binary.is_zero(a.numerator.magnitude),
      @binary.is_zero(b.numerator.magnitude),
    ) {
    (true, _) => return b
    (_, true) => return a
    _ => ()
  }
  match a.denominator.equal(b.denominator) {
    true => return normalize(add(a.numerator, b.numerator), a.denominator)
    false => ()
  }
  let common = common_factor(a.denominator, b.denominator)
  let left = exact_quotient(a.denominator, common)
  let right = exact_quotient(b.denominator, common)
  let numerator = add(
    multiply(a.numerator, positive(right)),
    multiply(b.numerator, positive(left)),
  )
  // Reduced inputs imply any remaining common factor divides common.
  let remaining = common_factor(numerator.magnitude, common)
  {
    numerator: integer_quotient(numerator, remaining),
    denominator: @binary.multiply(
      left,
      exact_quotient(b.denominator, remaining),
    ),
  }
}

///|
pub fn rational_subtract(a : Rational, b : Rational) -> Rational {
  rational_add(a, rational_negate(b))
}

///|
pub fn rational_multiply(a : Rational, b : Rational) -> Rational {
  match
    @binary.is_zero(a.numerator.magnitude) ||
    @binary.is_zero(b.numerator.magnitude) {
    true => return rational_zero()
    false => ()
  }
  match is_one(a.numerator.magnitude) && is_one(a.denominator) {
    true =>
      return match a.numerator.negative {
        true => rational_negate(b)
        false => b
      }
    false => ()
  }
  match is_one(b.numerator.magnitude) && is_one(b.denominator) {
    true =>
      return match b.numerator.negative {
        true => rational_negate(a)
        false => a
      }
    false => ()
  }
  let left = common_factor(a.numerator.magnitude, b.denominator)
  let right = common_factor(b.numerator.magnitude, a.denominator)
  {
    numerator: multiply(
      integer_quotient(a.numerator, left),
      integer_quotient(b.numerator, right),
    ),
    denominator: @binary.multiply(
      exact_quotient(a.denominator, right),
      exact_quotient(b.denominator, left),
    ),
  }
}

///|
fn close_widths(a : @core.Chain[Bool], b : @core.Chain[Bool]) -> Bool {
  match (a, b) {
    (_, Nil) =>
      match a {
        Nil
        | Cons(_, Nil)
        | Cons(_, Cons(_, Nil))
        | Cons(_, Cons(_, Cons(_, Nil))) => true
        _ => false
      }
    (Cons(_, a), Cons(_, b)) => close_widths(a, b)
    _ => false
  }
}

///|
/// Exact division with a short quotient. Strip the divisor's powers of two;
/// for odd d, q's low bit is a's low bit and the remaining quotient is halved.
fn short_exact_quotient(
  a : @binary.Binary,
  d : @binary.Binary,
) -> @binary.Binary {
  match @binary.is_zero(a) || is_one(d) {
    true => return a
    false => ()
  }
  match a.equal(d) {
    true => return @binary.one()
    false => ()
  }
  match @binary.odd(d) {
    false => short_exact_quotient(@binary.half(a), @binary.half(d))
    true =>
      match @binary.odd(a) {
        false => @binary.double(short_exact_quotient(@binary.half(a), d))
        true =>
          match @binary.subtract(a, d) {
            Some(rest) =>
              @binary.successor(
                @binary.double(short_exact_quotient(@binary.half(rest), d)),
              )
            None => @binary.zero()
          }
      }
  }
}

///|
/// All callers supply a positive divisor known to divide the magnitude exactly.
fn exact_quotient(
  value : @binary.Binary,
  divisor : @binary.Binary,
) -> @binary.Binary {
  match is_one(divisor) {
    true => return value
    false => ()
  }
  match @binary.is_zero(value) {
    true => return value
    false => ()
  }
  match value.equal(divisor) {
    true => return @binary.one()
    false => ()
  }
  match
    !@binary.is_zero(divisor) &&
    close_widths(@binary.bits(value), @binary.bits(divisor)) {
    true => return short_exact_quotient(value, divisor)
    false => ()
  }
  match @binary.divmod(value, divisor) {
    Some((quotient, _)) => quotient
    None => value
  }
}

///|
fn is_one(value : @binary.Binary) -> Bool {
  match @binary.bits(value) {
    Cons(true, Nil) => true
    _ => false
  }
}

///|
fn small_gcd_magnitude(value : @binary.Binary) -> Bool {
  match @binary.bits(value) {
    Cons(
      _,
      Cons(_, Cons(_, Cons(_, Cons(_, Cons(_, Cons(_, Cons(_, Cons(_, _))))))))
    ) => false
    _ => true
  }
}

///|
fn common_factor(a : @binary.Binary, b : @binary.Binary) -> @binary.Binary {
  match is_one(a) || is_one(b) {
    true => @binary.one()
    false =>
      match (@binary.is_zero(a), @binary.is_zero(b)) {
        (true, _) => b
        (_, true) => a
        _ =>
          match a.equal(b) {
            true => a
            false =>
              match small_gcd_magnitude(a) && small_gcd_magnitude(b) {
                true => @binary.stein_gcd(a, b)
                false => @binary.gcd(a, b)
              }
          }
      }
  }
}

///|
fn integer_quotient(value : Integer, divisor : @binary.Binary) -> Integer {
  match is_one(divisor) {
    true => return value
    false => ()
  }
  {
    negative: value.negative,
    magnitude: exact_quotient(value.magnitude, divisor),
  }
}

///|
/// Halve using the nonzero denominator invariant, without a partial division API.
pub fn rational_half(value : Rational) -> Rational {
  match @binary.is_zero(value.numerator.magnitude) {
    true => return value
    false => ()
  }
  // Coprimality is already known. Only a factor two can be introduced by half.
  match @binary.odd(value.numerator.magnitude) {
    true =>
      {
        numerator: value.numerator,
        denominator: @binary.double(value.denominator),
      }
    false =>
      {
        numerator: {
          negative: value.numerator.negative,
          magnitude: @binary.half(value.numerator.magnitude),
        },
        denominator: value.denominator,
      }
  }
}

///|
pub fn rational_divide(a : Rational, b : Rational) -> Rational? {
  match nonzero(b) {
    None => None
    Some(value) => Some(rational_multiply(a, reciprocal(value)))
  }
}

///|
pub fn rational_compare(a : Rational, b : Rational) -> @core.Ordering {
  match (a.numerator.negative, b.numerator.negative) {
    (true, false) => return Less
    (false, true) => return Greater
    _ => ()
  }
  match
    @binary.is_zero(a.numerator.magnitude) ||
    @binary.is_zero(b.numerator.magnitude) ||
    a.denominator.equal(b.denominator) {
    true => return compare(a.numerator, b.numerator)
    false => ()
  }
  compare(
    multiply(a.numerator, positive(b.denominator)),
    multiply(b.numerator, positive(a.denominator)),
  )
}

///|
/// Evidence that a rational is nonzero, for total pivot inversion.
pub struct Nonzero {
  value : Rational
}

///|
pub fn nonzero(value : Rational) -> Nonzero? {
  match @binary.is_zero(value.numerator.magnitude) {
    true => None
    false => Some({ value, })
  }
}

///|
pub fn nonzero_value(value : Nonzero) -> Rational {
  value.value
}

///|
/// Total because the only constructor is the checked nonzero function.
pub fn reciprocal(nonzero : Nonzero) -> Rational {
  let r = nonzero.value
  let n = positive(r.denominator)
  {
    numerator: match r.numerator.negative {
      true => negate(n)
      false => n
    },
    denominator: r.numerator.magnitude,
  }
}
