///|
// Keep the reduced-fraction addition formula, subtracting signed numerators
// directly so a temporary negated Rational and Integer are unnecessary.
fn subtract_rationals(a : Rational, b : Rational) -> Rational {
  match
    (
      @binary.is_zero(a.numerator.magnitude),
      @binary.is_zero(b.numerator.magnitude),
    ) {
    (_, true) => return a
    (true, _) => return rational_negate(b)
    _ => ()
  }
  match a.denominator.equal(b.denominator) {
    true => return normalize(subtract(a.numerator, b.numerator), a.denominator)
    false => ()
  }
  let common = common_factor(a.denominator, b.denominator)
  let left = exact_quotient(a.denominator, common)
  let right = exact_quotient(b.denominator, common)
  let numerator = subtract(
    multiply(a.numerator, positive(right)),
    multiply(b.numerator, positive(left)),
  )
  let remaining = common_factor(numerator.magnitude, common)
  {
    numerator: integer_quotient(numerator, remaining),
    denominator: @binary.multiply(
      left,
      exact_quotient(b.denominator, remaining),
    ),
  }
}
