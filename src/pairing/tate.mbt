///|
/// Evaluate on the degree-zero divisor (Q+S)-(S), then apply the final exponent.
/// Q represents E(F) modulo order times E(F); it need not be a torsion point.
/// S is explicit and must avoid all intermediate supports of this Miller path.
pub fn reduced_tate(
  parameters : Parameters,
  p : @ec.Point,
  q : @ec.Point,
  shift : @ec.Point,
) -> Result[@gf.Element, PairingError] {
  let curve = parameters.curve
  if !@ec.same_curve(curve, @ec.parent(p)) ||
    !@ec.same_curve(curve, @ec.parent(q)) ||
    !@ec.same_curve(curve, @ec.parent(shift)) {
    return Err(DifferentCurve)
  }
  let annihilated = match curve_result(@ec.scale(p, parameters.order)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !@ec.is_infinity(annihilated) {
    return Err(NotTorsion)
  }
  let field = @ec.field(curve)
  // Either divisor is zero in these identity cases, so no support evaluation is needed.
  if @ec.is_infinity(p) || @ec.is_infinity(q) {
    return Ok(@gf.one(field))
  }
  let translated = match curve_result(@ec.add(q, shift)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let numerator = match miller(p, parameters.order, translated) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let denominator = match miller(p, parameters.order, shift) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !@ec.is_infinity(numerator.multiple) ||
    !@ec.is_infinity(denominator.multiple) {
    return Err(InternalInvariant)
  }
  let quotient = match nonzero_ratio(numerator.value, denominator.value) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let result = match field_result(@gf.power(quotient, parameters.exponent)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let root_check = match field_result(@gf.power(result, parameters.order)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if root_check.equal(@gf.one(field)) {
    Ok(result)
  } else {
    Err(InternalInvariant)
  }
}
