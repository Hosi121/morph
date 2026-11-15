///|
/// Nonsingular short Weierstrass y^two = x^three + a*x + b, prime characteristic > three.
#derive(Eq, Debug)
pub struct Curve {
  field : @finitefield.Field
  a : @binary.Binary
  b : @binary.Binary
}

///|
pub extend Curve with Eq::{equal, not_equal}

///|
pub extend Curve with Debug::{to_repr}

///|
pub fn curve(
  field : @finitefield.Field,
  a : @binary.Binary,
  b : @binary.Binary,
) -> Curve? {
  let modulus = @finitefield.modulus(field)
  let one = @binary.one()
  let two = @binary.double(one)
  let three = @binary.successor(two)
  let four = @binary.double(two)
  let twenty_seven = @binary.multiply(three, @binary.multiply(three, three))
  let a = @modular.reduce(modulus, a)
  let b = @modular.reduce(modulus, b)
  let cube = @modular.multiply(modulus, a, @modular.multiply(modulus, a, a))
  let discriminant = @modular.add(
    modulus,
    @modular.multiply(modulus, four, cube),
    @modular.multiply(modulus, twenty_seven, @modular.multiply(modulus, b, b)),
  )
  match
    (
      @binary.compare(@modular.value(modulus), three),
      @binary.is_zero(discriminant),
    ) {
    (Greater, false) => Some({ field, a, b, })
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Coordinates {
  Infinity
  Affine(@binary.Binary, @binary.Binary)
}

///|
pub extend Coordinates with Eq::{equal, not_equal}

///|
pub extend Coordinates with Debug::{to_repr}

///|
/// An element carries its curve; coordinates cannot be forged through this type.
#derive(Eq, Debug)
pub struct Point {
  curve : Curve
  coordinates : Coordinates
}

///|
pub extend Point with Eq::{equal, not_equal}

///|
pub extend Point with Debug::{to_repr}

///|
pub fn coordinates(point : Point) -> Coordinates {
  point.coordinates
}

///|
pub fn infinity(curve : Curve) -> Point {
  { curve, coordinates: Infinity, }
}

///|
fn rhs(curve : Curve, x : @binary.Binary) -> @binary.Binary {
  let modulus = @finitefield.modulus(curve.field)
  @modular.add(
    modulus,
    @modular.add(
      modulus,
      @modular.multiply(modulus, x, @modular.multiply(modulus, x, x)),
      @modular.multiply(modulus, curve.a, x),
    ),
    curve.b,
  )
}

///|
/// Strict canonical input coordinates; out-of-range representatives are rejected.
pub fn point(curve : Curve, x : @binary.Binary, y : @binary.Binary) -> Point? {
  let modulus = @finitefield.modulus(curve.field)
  let prime = @modular.value(modulus)
  match
    (
      @binary.compare(x, prime),
      @binary.compare(y, prime),
      @binary.compare(@modular.multiply(modulus, y, y), rhs(curve, x)),
    ) {
    (Less, Less, Equal) => Some({ curve, coordinates: Affine(x, y), })
    _ => None
  }
}

///|
pub fn negate(p : Point) -> Point {
  match p.coordinates {
    Infinity => p
    Affine(x, y) =>
      {
        ..p,
        coordinates: Affine(
          x,
          @modular.subtract(
            @finitefield.modulus(p.curve.field),
            @binary.zero(),
            y,
          ),
        ),
      }
  }
}

///|
/// Affine group addition; None rejects different curves or an internal inverse failure.
pub fn add(p : Point, q : Point) -> Point? {
  fn same_curve(a : Curve, b : Curve) -> Bool {
    match
      (
        @binary.compare(
          @modular.value(@finitefield.modulus(a.field)),
          @modular.value(@finitefield.modulus(b.field)),
        ),
        @binary.compare(a.a, b.a),
        @binary.compare(a.b, b.b),
      ) {
      (Equal, Equal, Equal) => true
      _ => false
    }
  }
  match same_curve(p.curve, q.curve) {
    false => None
    true =>
      match (p.coordinates, q.coordinates) {
        (Infinity, _) => Some(q)
        (_, Infinity) => Some(p)
        (Affine(x, y), Affine(u, v)) => {
          let modulus = @finitefield.modulus(p.curve.field)
          let same_x = match @binary.compare(x, u) {
            Equal => true
            _ => false
          }
          match same_x && @binary.is_zero(@modular.add(modulus, y, v)) {
            true => Some(infinity(p.curve))
            false => {
              let (numerator, denominator) = match same_x {
                false =>
                  (
                    @modular.subtract(modulus, v, y),
                    @modular.subtract(modulus, u, x),
                  )
                true => {
                  let two = @binary.double(@binary.one())
                  let three = @binary.successor(two)
                  (
                    @modular.add(
                      modulus,
                      @modular.multiply(
                        modulus,
                        three,
                        @modular.multiply(modulus, x, x),
                      ),
                      p.curve.a,
                    ),
                    @modular.multiply(modulus, two, y),
                  )
                }
              }
              match @modular.inverse(modulus, denominator) {
                None => None
                Some(inverse) => {
                  let slope = @modular.multiply(modulus, numerator, inverse)
                  let next_x = @modular.subtract(
                    modulus,
                    @modular.subtract(
                      modulus,
                      @modular.multiply(modulus, slope, slope),
                      x,
                    ),
                    u,
                  )
                  let next_y = @modular.subtract(
                    modulus,
                    @modular.multiply(
                      modulus,
                      slope,
                      @modular.subtract(modulus, x, next_x),
                    ),
                    y,
                  )
                  point(p.curve, next_x, next_y)
                }
              }
            }
          }
        }
      }
  }
}

///|
/// Double-and-add consuming the arbitrary-precision scalar's Bool digits.
pub fn scale(p : Point, scalar : @binary.Binary) -> Point? {
  fn multiply(bits : @core.Chain[Bool]) -> Point? {
    match bits {
      Nil => Some(infinity(p.curve))
      Cons(bit, rest) =>
        match multiply(rest) {
          None => None
          Some(half) =>
            match add(half, half) {
              None => None
              Some(doubled) =>
                match bit {
                  true => add(doubled, p)
                  false => Some(doubled)
                }
            }
        }
    }
  }
  multiply(@binary.bits(scalar))
}

///|
#derive(Eq, Debug)
pub(all) enum Compressed {
  AtInfinity
  XParity(@binary.Binary, Bool)
}

///|
pub extend Compressed with Eq::{equal, not_equal}

///|
pub extend Compressed with Debug::{to_repr}

///|
pub fn compress(p : Point) -> Compressed {
  match p.coordinates {
    Infinity => AtInfinity
    Affine(x, y) => XParity(x, @binary.odd(y))
  }
}

///|
/// Reconstruct y through Tonelli-Shanks and select the requested parity.
/// This is a symbolic point encoding, not SEC octet serialization.
pub fn decompress(curve : Curve, encoded : Compressed) -> Point? {
  match encoded {
    AtInfinity => Some(infinity(curve))
    XParity(x, odd) =>
      match
        @binary.compare(x, @modular.value(@finitefield.modulus(curve.field))) {
        Less =>
          match @finitefield.sqrt(curve.field, rhs(curve, x)) {
            None => None
            Some(y) => {
              let y = match (@binary.odd(y), odd) {
                (true, true) | (false, false) => y
                _ =>
                  @modular.subtract(
                    @finitefield.modulus(curve.field),
                    @binary.zero(),
                    y,
                  )
              }
              match (@binary.odd(y), odd) {
                (true, true) | (false, false) => point(curve, x, y)
                _ => None
              }
            }
          }
        _ => None
      }
  }
}
