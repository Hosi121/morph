///|
/// Canonical QQ coordinates in the fixed power basis of this checked field.
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  // Residue terms are unique and descending, with exponents below degree.
  // Walk them once from the highest basis position, prepending each coefficient
  // (including gaps) so the returned vector is in ascending power order.
  fn scan(
    remaining : @core.Nat,
    terms : @core.Chain[@poly.Term],
    found : @core.Chain[@exact.Rational],
  ) -> @core.Chain[@exact.Rational] {
    match remaining {
      Zero => found
      Succ(exponent) =>
        match terms {
          Cons({ coefficient, exponents: Cons(actual, Nil), }, rest) =>
            match @core.compare(actual, exponent) {
              Equal => scan(exponent, rest, Cons(coefficient, found))
              Less => scan(exponent, terms, Cons(@exact.rational_zero(), found))
              Greater => scan(remaining, rest, found)
            }
          _ => scan(exponent, Nil, Cons(@exact.rational_zero(), found))
        }
    }
  }
  scan(degree(value.field), @poly.terms(value.residue), Nil)
}
