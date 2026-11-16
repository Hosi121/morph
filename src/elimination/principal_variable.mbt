///|
/// Descending coefficient polynomials in the unselected variables. Zero cells
/// and nominal leading padding are retained and every cell has source arity-1.
pub fn coefficient_polynomials(
  p : Input,
) -> Result[@core.Chain[@poly.Polynomial], EliminationError] {
  fn convert(
    values : @core.Chain[Coefficient],
    remaining : @core.Nat,
  ) -> Result[@core.Chain[@poly.Polynomial], EliminationError] {
    match values {
      Nil => Ok(Nil)
      Cons(value, rest) =>
        match
          (coefficient_polynomial(value, remaining), convert(rest, remaining)) {
          (Ok(value), Ok(tail)) => Ok(Cons(value, tail))
          _ => Err(InternalDimension)
        }
    }
  }
  match (@poly.variables(p.polynomial), as_coefficients(p)) {
    (Succ(remaining), Some(fixed)) => convert(fixed.coefficients, remaining)
    _ => Err(InternalDimension)
  }
}

///|
pub fn principal_variable(
  f : Input,
  g : Input,
  k : @core.Nat,
) -> Result[@poly.Polynomial, EliminationError] {
  if !compatible(f, g) {
    Err(DimensionMismatch)
  } else {
    match
      (@poly.variables(f.polynomial), as_coefficients(f), as_coefficients(g)) {
      (Succ(remaining), Some(left), Some(right)) =>
        match
          principal_subresultant(left, right, k, coefficient_ring(remaining)) {
          None => Err(DegreeTooSmall)
          Some(value) => coefficient_polynomial(value, remaining)
        }
      _ => Err(InternalDimension)
    }
  }
}

///|
pub fn principal_coefficients_variable(
  f : Input,
  g : Input,
) -> Result[@core.Chain[@poly.Polynomial], EliminationError] {
  fn go(
    indices : @core.Chain[@core.Nat],
  ) -> Result[@core.Chain[@poly.Polynomial], EliminationError] {
    match indices {
      Nil => Ok(Nil)
      Cons(index, rest) =>
        match (principal_variable(f, g, index), go(rest)) {
          (Ok(value), Ok(tail)) => Ok(Cons(value, tail))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  if !compatible(f, g) {
    Err(DimensionMismatch)
  } else {
    go(@core.indices(Succ(@core.minimum(f.degree, g.degree))))
  }
}

///|
#derive(Eq, Debug)
pub(all) struct PrincipalVariableCertificate {
  left : Input
  right : Input
  index : @core.Nat
  value : @poly.Polynomial
}

///|
pub extend PrincipalVariableCertificate with Eq::{equal, not_equal}

///|
pub extend PrincipalVariableCertificate with Debug::{to_repr}

///|
pub fn principal_variable_certificate(
  f : Input,
  g : Input,
  k : @core.Nat,
) -> Result[PrincipalVariableCertificate, EliminationError] {
  match principal_variable(f, g, k) {
    Err(error) => Err(error)
    Ok(value) => Ok({ left: f, right: g, index: k, value, })
  }
}

///|
pub fn check_principal_variable(
  f : Input,
  g : Input,
  k : @core.Nat,
  value : @poly.Polynomial,
  proof : PrincipalVariableCertificate,
) -> Bool {
  f.equal(proof.left) &&
  g.equal(proof.right) &&
  @core.compare(k, proof.index) is Equal &&
  value.equal(proof.value) &&
  (match principal_variable(f, g, k) {
    Ok(expected) => value.equal(expected)
    Err(_) => false
  })
}
