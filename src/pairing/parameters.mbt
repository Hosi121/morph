///|
/// Order must exceed one, be coprime to the characteristic and divide size minus one.
pub fn parameters(
  curve : @ec.Curve,
  order : @binary.Binary,
) -> Result[Parameters, PairingError] {
  if !@binary.compare(order, @binary.one()).equal(Greater) {
    return Err(InvalidOrder)
  }
  let field = @ec.field(curve)
  if !@binary.gcd(order, @gf.characteristic(field)).equal(@binary.one()) {
    return Err(CharacteristicDivisor)
  }
  let size = @gf.cardinality(field)
  match @binary.subtract(size, @binary.one()) {
    None => Err(InternalInvariant)
    Some(group_order) =>
      match @binary.divmod(group_order, order) {
        None => Err(InternalInvariant)
        Some((exponent, remainder)) =>
          if @binary.is_zero(remainder) {
            Ok({ curve, order, size, exponent, })
          } else {
            Err(OrderNotDivisor)
          }
      }
  }
}
