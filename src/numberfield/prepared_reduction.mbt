///|
/// Remainder-only univariate division by a fixed checked modulus. `reduction`
/// is its negative monic normalization, prepared only after field verification.
/// Multiplication supplies a canonical univariate product; each cancellation
/// strictly lowers its leading exponent. The generic polynomial division and
/// all certificate checkers remain independent of this producer path.
fn prepared_remainder(
  value : @poly.Polynomial,
  reduction : @poly.Polynomial,
  degree : @core.Nat,
) -> Result[@poly.Polynomial, FieldError] {
  match @poly.terms(value) {
    Nil => Ok(value)
    Cons({ coefficient, exponents: Cons(exponent, Nil), }, _) =>
      match @core.compare(exponent, degree) {
        Less => Ok(value)
        _ =>
          match
            @poly.scale(reduction, {
              coefficient,
              exponents: Cons(@core.subtract(exponent, degree), Nil),
            }) {
            Err(_) => Err(InternalInvariant)
            Ok(cancellation) =>
              match @poly.add(value, cancellation) {
                Err(_) => Err(InternalInvariant)
                Ok(next) => prepared_remainder(next, reduction, degree)
              }
          }
      }
    _ => Err(InternalInvariant)
  }
}
