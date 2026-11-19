///|
/// Exact QQ coordinates in [1,alpha,...,i,i*alpha,...].
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  @core.append(@nf.coordinates(value.real), @nf.coordinates(value.imaginary))
}

///|
/// Reconstruct in the same fixed basis; dimensions are checked before splitting.
pub fn from_coordinates(
  field : Field,
  values : @core.Chain[@exact.Rational],
) -> Result[Element, FieldError] {
  if !@core.length(values).equal(degree(field)) {
    return Err(DimensionMismatch)
  }
  fn polynomial(values : @core.Chain[@exact.Rational]) -> @poly.Polynomial? {
    match @core.zip(@core.indices(@core.length(values)), values) {
      Some(entries) =>
        match
          @poly.polynomial(
            Succ(Zero),
            @core.map(entries, fn(entry) {
              let (index, coefficient) = entry
              @poly.Term::{ coefficient, exponents: Cons(index, Nil), }
            }),
          ) {
          Ok(result) => Some(result)
          Err(_) => None
        }
      None => None
    }
  }
  let n = @nf.degree(real_field(field))
  match (polynomial(@core.take(n, values)), polynomial(@core.drop(n, values))) {
    (Some(real), Some(imaginary)) =>
      match
        (
          @nf.element(real_field(field), real),
          @nf.element(real_field(field), imaginary),
        ) {
        (Ok(a), Ok(b)) => element(field, a, b)
        _ => Err(InternalInvariant)
      }
    _ => Err(InternalInvariant)
  }
}
