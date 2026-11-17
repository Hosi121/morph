///|
/// Only a constant monomial with numerator magnitude and denominator exactly one
/// denotes a scalar unit. Getters inspect existing immutable canonical ADTs.
fn scalar_unit_sign(term : Term) -> Bool? {
  if !@core.all(term.exponents, fn(exponent) { exponent is Zero }) {
    return None
  }
  let numerator = @exact.numerator(term.coefficient)
  match
    (
      @binary.bits(@exact.denominator(term.coefficient)),
      @binary.bits(@exact.magnitude(numerator)),
    ) {
    (Cons(true, Nil), Cons(true, Nil)) => Some(@exact.negative(numerator))
    _ => None
  }
}

///|
/// Multi-term by multi-term inputs perform only this constant-size shape test.
/// Identity returns share the other opaque immutable Polynomial; minus one uses
/// the unchanged canonical negate operation and shares its exponent vectors.
fn unit_identity_product(a : Polynomial, b : Polynomial) -> Polynomial? {
  match (a.terms, b.terms) {
    (Cons(x, Nil), Cons(y, Nil)) =>
      match scalar_unit_sign(x) {
        Some(false) => Some(b)
        Some(true) => Some(negate(b))
        None =>
          match scalar_unit_sign(y) {
            Some(false) => Some(a)
            Some(true) => Some(negate(a))
            None => None
          }
      }
    (Cons(x, Nil), _) =>
      match scalar_unit_sign(x) {
        Some(false) => Some(b)
        Some(true) => Some(negate(b))
        None => None
      }
    (_, Cons(y, Nil)) =>
      match scalar_unit_sign(y) {
        Some(false) => Some(a)
        Some(true) => Some(negate(a))
        None => None
      }
    _ => None
  }
}
