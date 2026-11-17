///|
/// Canonical QQ is +1 exactly when its nonnegative numerator magnitude and
/// denominator each have the single one bit. Getters share the existing ADTs.
fn monic_positive_one(coefficient : @exact.Rational) -> Bool {
  let numerator = @exact.numerator(coefficient)
  match @exact.negative(numerator) {
    true => false
    false =>
      match
        (
          @binary.bits(@exact.magnitude(numerator)),
          @binary.bits(@exact.denominator(coefficient)),
        ) {
        (Cons(true, Nil), Cons(true, Nil)) => true
        _ => false
      }
  }
}
