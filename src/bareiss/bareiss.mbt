///|
#derive(Eq, Debug)
pub(all) enum BareissError {
  NotSquare
  ZeroDivisor
  InexactDivision
  InternalShape
}

///|
pub extend BareissError with Eq::{equal, not_equal}

///|
pub extend BareissError with Debug::{to_repr}

///|
fn zero() -> @exact.Integer {
  @exact.positive(@binary.zero())
}

///|
fn one() -> @exact.Integer {
  @exact.positive(@binary.one())
}

///|
fn quotient(
  numerator : @binary.Binary,
  denominator : @binary.Binary,
) -> Result[@binary.Binary, BareissError] {
  match @binary.divmod(numerator, denominator) {
    None => Err(ZeroDivisor)
    Some((value, remainder)) =>
      if @binary.is_zero(remainder) {
        Ok(value)
      } else {
        Err(InexactDivision)
      }
  }
}

///|
/// Signed integer division, returning an error unless the remainder is zero.
pub fn exact_divide(
  numerator : @exact.Integer,
  denominator : @exact.Integer,
) -> Result[@exact.Integer, BareissError] {
  match quotient(@exact.magnitude(numerator), @exact.magnitude(denominator)) {
    Err(error) => Err(error)
    Ok(magnitude) => {
      let value = @exact.positive(magnitude)
      if (@exact.negative(numerator) && !@exact.negative(denominator)) ||
        (!@exact.negative(numerator) && @exact.negative(denominator)) {
        Ok(@exact.negate(value))
      } else {
        Ok(value)
      }
    }
  }
}

///|
fn pivot(
  rows : @core.Chain[@core.Chain[@exact.Integer]],
) -> Result[
  (@core.Chain[@exact.Integer], @core.Chain[@core.Chain[@exact.Integer]], Bool)?,
  BareissError,
] {
  match rows {
    Nil => Ok(None)
    Cons(Cons(value, _) as row, rest) =>
      if !@binary.is_zero(@exact.magnitude(value)) {
        Ok(Some((row, rest, false)))
      } else {
        match pivot(rest) {
          Err(error) => Err(error)
          Ok(None) => Ok(None)
          Ok(Some((chosen, others, odd))) =>
            Ok(Some((chosen, Cons(row, others), !odd)))
        }
      }
    _ => Err(InternalShape)
  }
}

///|
fn eliminate_row(
  row : @core.Chain[@exact.Integer],
  pivot_row : @core.Chain[@exact.Integer],
  corner : @exact.Integer,
  left : @exact.Integer,
  previous : @exact.Integer,
) -> Result[@core.Chain[@exact.Integer], BareissError] {
  match (row, pivot_row) {
    (Nil, Nil) => Ok(Nil)
    (Cons(value, rest), Cons(top, tail)) =>
      match
        (
          exact_divide(
            @exact.subtract(
              @exact.multiply(corner, value),
              @exact.multiply(left, top),
            ),
            previous,
          ),
          eliminate_row(rest, tail, corner, left, previous),
        ) {
        (Ok(value), Ok(rest)) => Ok(Cons(value, rest))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(InternalShape)
  }
}

///|
fn eliminate_rows(
  rows : @core.Chain[@core.Chain[@exact.Integer]],
  pivot_row : @core.Chain[@exact.Integer],
  corner : @exact.Integer,
  previous : @exact.Integer,
) -> Result[@core.Chain[@core.Chain[@exact.Integer]], BareissError] {
  match rows {
    Nil => Ok(Nil)
    Cons(Cons(left, rest), tail) =>
      match
        (
          eliminate_row(rest, pivot_row, corner, left, previous),
          eliminate_rows(tail, pivot_row, corner, previous),
        ) {
        (Ok(row), Ok(rows)) => Ok(Cons(row, rows))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(InternalShape)
  }
}

///|
fn determinant_rows(
  rows : @core.Chain[@core.Chain[@exact.Integer]],
  previous : @exact.Integer,
  negative : Bool,
) -> Result[@exact.Integer, BareissError] {
  match rows {
    Nil => Ok(if negative { @exact.negate(one()) } else { one() })
    Cons(Cons(value, Nil), Nil) =>
      Ok(if negative { @exact.negate(value) } else { value })
    _ =>
      match pivot(rows) {
        Err(error) => Err(error)
        Ok(None) => Ok(zero())
        Ok(Some((Cons(corner, tail), others, odd))) =>
          match eliminate_rows(others, tail, corner, previous) {
            Err(error) => Err(error)
            Ok(next) =>
              determinant_rows(
                next,
                corner,
                if odd {
                  !negative
                } else {
                  negative
                },
              )
          }
        _ => Err(InternalShape)
      }
  }
}

///|
/// Fraction-free one-step Bareiss with row pivoting and checked exact quotients.
/// Empty determinant is one; a missing pivot gives exact singular value zero.
pub fn integer_determinant(
  matrix : @matrix.Matrix[@exact.Integer],
) -> Result[@exact.Integer, BareissError] {
  match @core.compare(@matrix.width(matrix), @matrix.height(matrix)) {
    Equal => determinant_rows(@matrix.rows(matrix), one(), false)
    _ => Err(NotSquare)
  }
}
