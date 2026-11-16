///|
fn lcm(
  a : @binary.Binary,
  b : @binary.Binary,
) -> Result[@binary.Binary, BareissError] {
  match quotient(a, @binary.gcd(a, b)) {
    Err(error) => Err(error)
    Ok(q) => Ok(@binary.multiply(q, b))
  }
}

///|
fn denominator_lcm(
  row : @core.Chain[@exact.Rational],
  found : @binary.Binary,
) -> Result[@binary.Binary, BareissError] {
  match row {
    Nil => Ok(found)
    Cons(value, rest) =>
      match lcm(found, @exact.denominator(value)) {
        Err(error) => Err(error)
        Ok(next) => denominator_lcm(rest, next)
      }
  }
}

///|
fn scale_row(
  row : @core.Chain[@exact.Rational],
  denominator : @binary.Binary,
) -> Result[@core.Chain[@exact.Integer], BareissError] {
  match row {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match
        (
          quotient(denominator, @exact.denominator(value)),
          scale_row(rest, denominator),
        ) {
        (Ok(scale), Ok(tail)) =>
          Ok(
            Cons(
              @exact.multiply(@exact.numerator(value), @exact.positive(scale)),
              tail,
            ),
          )
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn clear_denominators(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
) -> Result[
  (@core.Chain[@core.Chain[@exact.Integer]], @binary.Binary),
  BareissError,
] {
  match rows {
    Nil => Ok((Nil, @binary.one()))
    Cons(row, rest) =>
      match (denominator_lcm(row, @binary.one()), clear_denominators(rest)) {
        (Ok(scale), Ok((tail, factor))) =>
          match scale_row(row, scale) {
            Err(error) => Err(error)
            Ok(row) => Ok((Cons(row, tail), @binary.multiply(scale, factor)))
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
/// QQ determinant: row denominator LCMs produce an integer matrix; divide its
/// Bareiss determinant by the product of positive row scales afterward.
pub fn determinant(
  matrix : @matrix.Matrix[@exact.Rational],
) -> Result[@exact.Rational, BareissError] {
  match @core.compare(@matrix.width(matrix), @matrix.height(matrix)) {
    Equal =>
      match clear_denominators(@matrix.rows(matrix)) {
        Err(error) => Err(error)
        Ok((rows, scale)) =>
          match determinant_rows(rows, one(), false) {
            Err(error) => Err(error)
            Ok(numerator) =>
              match @exact.ratio(numerator, scale) {
                None => Err(ZeroDivisor)
                Some(value) => Ok(value)
              }
          }
      }
    _ => Err(NotSquare)
  }
}
