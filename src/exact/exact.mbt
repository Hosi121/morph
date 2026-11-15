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
  match (a.negative, b.negative) {
    (false, false) => positive(@binary.add(a.magnitude, b.magnitude))
    (true, true) => negate(positive(@binary.add(a.magnitude, b.magnitude)))
    (true, false) => add(b, a)
    (false, true) =>
      match @binary.subtract(a.magnitude, b.magnitude) {
        Some(difference) => positive(difference)
        None =>
          match @binary.subtract(b.magnitude, a.magnitude) {
            Some(difference) => negate(positive(difference))
            None => positive(@binary.zero())
          }
      }
  }
}

///|
pub fn subtract(a : Integer, b : Integer) -> Integer {
  add(a, negate(b))
}

///|
pub fn multiply(a : Integer, b : Integer) -> Integer {
  let product = positive(@binary.multiply(a.magnitude, b.magnitude))
  match (a.negative, b.negative) {
    (true, false) | (false, true) => negate(product)
    _ => product
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
  let common = @binary.gcd(numerator.magnitude, denominator)
  match
    (
      @binary.divmod(numerator.magnitude, common),
      @binary.divmod(denominator, common),
    ) {
    (Some((n, _)), Some((d, _))) => {
      let num = positive(n)
      {
        numerator: match numerator.negative {
          true => negate(num)
          false => num
        },
        denominator: d,
      }
    }
    // Unreachable for our nonzero denominators; retaining the fraction is sound.
    _ => { numerator, denominator, }
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
  { numerator: negate(r.numerator), denominator: r.denominator, }
}

///|
pub fn rational_add(a : Rational, b : Rational) -> Rational {
  normalize(
    add(
      multiply(a.numerator, positive(b.denominator)),
      multiply(b.numerator, positive(a.denominator)),
    ),
    @binary.multiply(a.denominator, b.denominator),
  )
}

///|
pub fn rational_subtract(a : Rational, b : Rational) -> Rational {
  rational_add(a, rational_negate(b))
}

///|
pub fn rational_multiply(a : Rational, b : Rational) -> Rational {
  normalize(
    multiply(a.numerator, b.numerator),
    @binary.multiply(a.denominator, b.denominator),
  )
}

///|
/// Halve using the nonzero denominator invariant, without a partial division API.
pub fn rational_half(value : Rational) -> Rational {
  normalize(value.numerator, @binary.double(value.denominator))
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
