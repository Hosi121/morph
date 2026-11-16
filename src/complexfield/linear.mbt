///|
/// Multiplication in the Q basis is the block matrix [[M_a,-M_b],[M_b,M_a]].
pub fn multiplication_matrix(
  value : Element,
) -> Result[@matrix.Matrix[@exact.Rational], FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  match
    (
      @nf.multiplication_matrix(value.real),
      @nf.multiplication_matrix(value.imaginary),
    ) {
    (Ok(a), Ok(b)) =>
      match @core.zip(@matrix.rows(a), @matrix.rows(b)) {
        Some(rows) => {
          let top = @core.map(rows, fn(pair) {
            let (arow, brow) = pair
            @core.append(arow, @core.map(brow, @exact.rational_negate))
          })
          let bottom = @core.map(rows, fn(pair) {
            let (arow, brow) = pair
            @core.append(brow, arow)
          })
          match @matrix.matrix(degree(value.field), @core.append(top, bottom)) {
            Some(result) => Ok(result)
            None => Err(InternalInvariant)
          }
        }
        None => Err(InternalInvariant)
      }
    _ => Err(InternalInvariant)
  }
}

///|
/// Ambient field trace Tr_(K(i)/Q), not trace from the element's minimum.
pub fn trace(value : Element) -> Result[@exact.Rational, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  match lift(@nf.trace(value.real)) {
    Ok(result) => Ok(@exact.rational_add(result, result))
    Err(error) => Err(error)
  }
}

///|
/// Ambient field norm N_(K(i)/Q)=N_(K/Q)(a^2+b^2).
pub fn norm(value : Element) -> Result[@exact.Rational, FieldError] {
  match relative_norm(value) {
    Ok(denominator) => lift(@nf.norm(denominator))
    Err(error) => Err(error)
  }
}

///|
/// Independent block-matrix diagonal check, with source supplied explicitly.
pub fn check_trace(input : Element, result : @exact.Rational) -> Bool {
  fn diagonal(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    index : @core.Nat,
  ) -> @exact.Rational? {
    match rows {
      Nil => Some(@exact.rational_zero())
      Cons(row, rest) =>
        match (@core.nth(row, index), diagonal(rest, Succ(index))) {
          (Some(a), Some(b)) => Some(@exact.rational_add(a, b))
          _ => None
        }
    }
  }
  match multiplication_matrix(input) {
    Ok(matrix) =>
      match diagonal(@matrix.rows(matrix), Zero) {
        Some(expected) => expected.equal(result)
        None => false
      }
    Err(_) => false
  }
}

///|
/// Independent determinant of the block multiplication matrix.
pub fn check_norm(input : Element, result : @exact.Rational) -> Bool {
  match multiplication_matrix(input) {
    Ok(matrix) =>
      match @linear.determinant(matrix) {
        Some(expected) => expected.equal(result)
        None => false
      }
    Err(_) => false
  }
}
