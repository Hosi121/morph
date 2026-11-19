///|
/// Horner evaluation in the existing checked field and embedding context.
pub fn evaluate_polynomial(
  value : Element,
  polynomial : @poly.Polynomial,
) -> Element? {
  @poly.evaluate_in(
    value,
    polynomial,
    zero(value.field),
    fn(c) { rational(value.field, c) },
    add,
    multiply,
  )
}

///|
/// Monicity and annihilation plus an independent RREF of preceding powers.
pub fn check_minimal_polynomial(
  value : Element,
  polynomial : @poly.Polynomial,
) -> Bool {
  valid(value) &&
  @linear.check_power_minimal_polynomial(
    value,
    one(value.field),
    degree(value.field),
    coordinates,
    multiply,
    evaluate_polynomial,
    is_zero,
    polynomial,
  )
}

///|
/// First power dependence, checked independently before returning.
pub fn minimal_polynomial(
  value : Element,
) -> Result[@poly.Polynomial, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  match
    @linear.power_minimal_polynomial(
      value,
      one(value.field),
      degree(value.field),
      coordinates,
      multiply,
    ) {
    Some(polynomial) =>
      if check_minimal_polynomial(value, polynomial) {
        Ok(polynomial)
      } else {
        Err(InternalInvariant)
      }
    None => Err(InternalInvariant)
  }
}
