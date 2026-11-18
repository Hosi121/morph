///|
fn[A] pad_coefficients(
  coefficients : @core.Chain[A],
  count : @core.Nat,
  zero : A,
) -> @core.Chain[A] {
  match (count, coefficients) {
    (Zero, _) => Nil
    (Succ(rest), Nil) => Cons(zero, pad_coefficients(Nil, rest, zero))
    (Succ(rest), Cons(head, tail)) =>
      Cons(head, pad_coefficients(tail, rest, zero))
  }
}

///|
/// In the d-dimensional K-algebra, multiplication by a is invertible exactly
/// when a is a unit. Solve its action on the power basis against one. This
/// intentionally uses the existing independent field solver rather than Euclid.
/// Reducible moduli are allowed; a nonzero nonunit returns None.
pub fn[A, K : Eq] unit_inverse(
  value : Residue[A, K],
) -> Result[Residue[A, K]?, QuotientError] {
  if is_zero(value) {
    return Ok(None)
  }
  let context = value.context
  let x = match generator(context) {
    Ok(x) => x
    Err(error) => return Err(error)
  }
  fn columns(
    count : @core.Nat,
    basis : Residue[A, K],
  ) -> Result[@core.Chain[@core.Chain[A]], QuotientError] {
    match count {
      Zero => Ok(Nil)
      Succ(rest) => {
        let product = match multiply(value, basis) {
          Ok(product) => product
          Err(error) => return Err(error)
        }
        let tail : @core.Chain[@core.Chain[A]] = match rest {
          Zero => Nil
          Succ(_) => {
            let next = match multiply(basis, x) {
              Ok(next) => next
              Err(error) => return Err(error)
            }
            match columns(rest, next) {
              Ok(tail) => tail
              Err(error) => return Err(error)
            }
          }
        }
        Ok(
          Cons(
            pad_coefficients(
              product.coefficients,
              context.degree,
              context.arithmetic.zero,
            ),
            tail,
          ),
        )
      }
    }
  }
  let columns = match columns(context.degree, one(context)) {
    Ok(columns) => columns
    Err(error) => return Err(error)
  }
  let matrix = match @matrix.matrix(context.degree, columns) {
    Some(matrix) => @matrix.transpose(matrix)
    None => return Err(InternalInvariant)
  }
  let right = pad_coefficients(
    one(context).coefficients,
    context.degree,
    context.arithmetic.zero,
  )
  match
    @rowreduce.solve_with_zero(
      context.arithmetic,
      context.coefficient_is_zero,
      matrix,
      right,
    ) {
    Some(@rowreduce.Inconsistent) => Ok(None)
    Some(@rowreduce.Unique(coefficients)) => {
      let candidate = match normalize(context, coefficients) {
        Ok(candidate) => candidate
        Err(_) => return Err(InternalInvariant)
      }
      match multiply(value, candidate) {
        Ok(product) =>
          if equivalent(product, one(context)) {
            Ok(Some(candidate))
          } else {
            Err(InternalInvariant)
          }
        Err(error) => Err(error)
      }
    }
    // A solution to a*b=one makes multiplication by a surjective. A square
    // finite-dimensional operator over a field cannot then have free variables.
    Some(@rowreduce.Affine(_, _)) | None => Err(InternalInvariant)
  }
}
