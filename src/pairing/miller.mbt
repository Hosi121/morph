///|
fn[A] curve_result(
  value : Result[A, @ec.CurveError],
) -> Result[A, PairingError] {
  match value {
    Ok(value) => Ok(value)
    Err(error) => Err(CurveFailure(error))
  }
}

///|
fn field_result(
  value : Result[@gf.Element, @gf.FieldError],
) -> Result[@gf.Element, PairingError] {
  match value {
    Ok(value) => Ok(value)
    Err(error) => Err(FieldFailure(error))
  }
}

///|
fn plus(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, PairingError] {
  field_result(@gf.add(a, b))
}

///|
fn minus(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, PairingError] {
  field_result(@gf.subtract(a, b))
}

///|
fn times(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, PairingError] {
  field_result(@gf.multiply(a, b))
}

///|
/// Intermediate zeroes, poles and removable zero-over-zero points are excluded.
fn nonzero_ratio(
  numerator : @gf.Element,
  denominator : @gf.Element,
) -> Result[@gf.Element, PairingError] {
  if @gf.is_zero(numerator) {
    if @gf.is_zero(denominator) {
      Err(IndeterminateEvaluation)
    } else {
      Err(ZeroEvaluation)
    }
  } else if @gf.is_zero(denominator) {
    Err(PoleEvaluation)
  } else {
    field_result(@gf.divide(numerator, denominator))
  }
}

///|
fn affine_coordinates(
  point : @ec.Point,
) -> Result[(@gf.Element, @gf.Element), PairingError] {
  match @ec.coordinates(point) {
    Err(error) => Err(CurveFailure(error))
    Ok(@ec.AtInfinity) => Err(EvaluationAtInfinity)
    Ok(@ec.Affine(x, y)) => Ok((x, y))
  }
}

///|
fn slope(
  x : @gf.Element,
  y : @gf.Element,
  u : @gf.Element,
  v : @gf.Element,
  a : @gf.Element,
) -> Result[@gf.Element, PairingError] {
  if x.equal(u) {
    if !y.equal(v) {
      return Err(InternalInvariant)
    }
    let xx = match times(x, x) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let two_xx = match plus(xx, xx) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let three_xx = match plus(two_xx, xx) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let top = match plus(three_xx, a) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let bottom = match plus(y, y) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    field_result(@gf.divide(top, bottom))
  } else {
    let top = match minus(v, y) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let bottom = match minus(u, x) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    field_result(@gf.divide(top, bottom))
  }
}

///|
/// Evaluate the secant or tangent divided by the vertical line through the sum.
/// The returned value is partial and nonzero; no cancellation across factors is attempted.
pub fn line_quotient(
  p : @ec.Point,
  q : @ec.Point,
  at : @ec.Point,
) -> Result[MillerValue, PairingError] {
  let curve = @ec.parent(p)
  if !@ec.same_curve(curve, @ec.parent(q)) ||
    !@ec.same_curve(curve, @ec.parent(at)) {
    return Err(DifferentCurve)
  }
  let field = @ec.field(curve)
  if @ec.is_infinity(p) {
    return Ok({ multiple: q, value: @gf.one(field), })
  }
  if @ec.is_infinity(q) {
    return Ok({ multiple: p, value: @gf.one(field), })
  }
  let (x, y) = match affine_coordinates(p) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (u, v) = match affine_coordinates(q) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (tx, ty) = match affine_coordinates(at) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let multiple = match curve_result(@ec.add(p, q)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let sum_y = match plus(y, v) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if x.equal(u) && @gf.is_zero(sum_y) {
    let numerator = match minus(tx, x) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let value = match nonzero_ratio(numerator, @gf.one(field)) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    return Ok({ multiple, value, })
  }
  let (a, _) = @ec.coefficients(curve)
  let slope = match slope(x, y, u, v, a) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let delta_x = match minus(tx, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let slope_term = match times(slope, delta_x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let delta_y = match minus(ty, y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let numerator = match minus(delta_y, slope_term) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (rx, _) = match affine_coordinates(multiple) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let denominator = match minus(tx, rx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let value = match nonzero_ratio(numerator, denominator) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ multiple, value, })
}

///|
/// Binary Miller recurrence. Infinity and scalar zero or one use the unit function.
pub fn miller(
  p : @ec.Point,
  scalar : @binary.Binary,
  at : @ec.Point,
) -> Result[MillerValue, PairingError] {
  if !@ec.same_curve(@ec.parent(p), @ec.parent(at)) {
    return Err(DifferentCurve)
  }
  fn walk(
    bits : @core.Chain[Bool],
    base : @ec.Point,
    at : @ec.Point,
  ) -> Result[MillerValue, PairingError] {
    match bits {
      Nil =>
        Ok({
          multiple: @ec.infinity(@ec.parent(base)),
          value: @gf.one(@ec.field(@ec.parent(base))),
        })
      Cons(bit, rest) => {
        let half = match walk(rest, base, at) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let doubled = match line_quotient(half.multiple, half.multiple, at) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let square = match times(half.value, half.value) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let value = match times(square, doubled.value) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        if bit {
          let added = match line_quotient(doubled.multiple, base, at) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let value = match times(value, added.value) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          Ok({ multiple: added.multiple, value, })
        } else {
          Ok({ multiple: doubled.multiple, value, })
        }
      }
    }
  }
  walk(@binary.bits(scalar), p, at)
}
