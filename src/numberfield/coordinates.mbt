///|
/// Canonical QQ coordinates in the fixed power basis of this checked field.
pub fn coordinates(value : Element) -> @core.Chain[@exact.Rational] {
  @core.map(@core.indices(degree(value.field)), fn(i) {
    coefficient(value.residue, i)
  })
}

