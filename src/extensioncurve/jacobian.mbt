///|
/// EFD dbl-1998-cmo-2; the exceptional branches are handled explicitly.
pub fn double(p : Point) -> Result[Point, CurveError] {
  if is_infinity(p) || @gf.is_zero(p.y) {
    return Ok(infinity(p.curve))
  }
  let xx = match square(p.x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let yy = match square(p.y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let zz = match square(p.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let xyy = match times(p.x, yy) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s = match fourfold(xyy) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let zzzz = match square(zz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let azzzz = match times(p.curve.a, zzzz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let three_xx = match thrice(xx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let m = match plus(three_xx, azzzz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mm = match square(m) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let two_s = match twice(s) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let x = match minus(mm, two_s) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s_minus_x = match minus(s, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let m_term = match times(m, s_minus_x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let yyyy = match square(yy) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let eight_yyyy = match eightfold(yyyy) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y = match minus(m_term, eight_yyyy) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let yz = match times(p.y, p.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z = match twice(yz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ curve: p.curve, x, y, z, })
}

///|
/// EFD add-1998-cmo-2 with context, identity, equal-point and inverse branches.
pub fn add(p : Point, q : Point) -> Result[Point, CurveError] {
  if !same_curve(p.curve, q.curve) {
    return Err(DifferentCurve)
  }
  if is_infinity(p) {
    return Ok(q)
  }
  if is_infinity(q) {
    return Ok(p)
  }
  let z1z1 = match square(p.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z2z2 = match square(q.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let u1 = match times(p.x, z2z2) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let u2 = match times(q.x, z1z1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z2_cubed = match times(q.z, z2z2) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z1_cubed = match times(p.z, z1z1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s1 = match times(p.y, z2_cubed) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s2 = match times(q.y, z1_cubed) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let h = match minus(u2, u1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let r = match minus(s2, s1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if @gf.is_zero(h) {
    return if @gf.is_zero(r) { double(p) } else { Ok(infinity(p.curve)) }
  }
  let hh = match square(h) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let hhh = match times(h, hh) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let v = match times(u1, hh) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rr = match square(r) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rr_minus_hhh = match minus(rr, hhh) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let two_v = match twice(v) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let x = match minus(rr_minus_hhh, two_v) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let v_minus_x = match minus(v, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let first_y = match times(r, v_minus_x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let second_y = match times(s1, hhh) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y = match minus(first_y, second_y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z1z2 = match times(p.z, q.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z = match times(z1z2, h) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ curve: p.curve, x, y, z, })
}

///|
pub fn negate(p : Point) -> Point {
  if is_infinity(p) {
    p
  } else {
    { ..p, y: @gf.negate(p.y), }
  }
}

///|
/// Binary double-and-add; projective operations do not invert field elements.
pub fn scale(p : Point, scalar : @binary.Binary) -> Result[Point, CurveError] {
  fn walk(bits : @core.Chain[Bool], base : Point) -> Result[Point, CurveError] {
    match bits {
      Nil => Ok(infinity(base.curve))
      Cons(bit, rest) => {
        let half = match walk(rest, base) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let doubled = match double(half) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        if bit {
          add(doubled, base)
        } else {
          Ok(doubled)
        }
      }
    }
  }
  walk(@binary.bits(scalar), p)
}

///|
/// Projective equality is independent of the chosen nonzero scale factor.
pub fn equal(p : Point, q : Point) -> Result[Bool, CurveError] {
  if !same_curve(p.curve, q.curve) {
    return Err(DifferentCurve)
  }
  if is_infinity(p) {
    return Ok(is_infinity(q))
  }
  if is_infinity(q) {
    return Ok(false)
  }
  let z1z1 = match square(p.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z2z2 = match square(q.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let u1 = match times(p.x, z2z2) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let u2 = match times(q.x, z1z1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !u1.equal(u2) {
    return Ok(false)
  }
  let z2_cubed = match times(q.z, z2z2) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z1_cubed = match times(p.z, z1z1) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s1 = match times(p.y, z2_cubed) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let s2 = match times(q.y, z1_cubed) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(s1.equal(s2))
}

///|
/// The sole affine conversion boundary; infinity never attempts to invert zero.
pub fn coordinates(p : Point) -> Result[Coordinates, CurveError] {
  if is_infinity(p) {
    return Ok(AtInfinity)
  }
  let inverse = match field_result(@gf.inverse(p.z)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let inverse_square = match square(inverse) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let inverse_cube = match times(inverse_square, inverse) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let x = match times(p.x, inverse_square) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y = match times(p.y, inverse_cube) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(Affine(x, y))
}

///|
pub fn normalize(p : Point) -> Result[Point, CurveError] {
  match coordinates(p) {
    Err(error) => Err(error)
    Ok(AtInfinity) => Ok(infinity(p.curve))
    Ok(Affine(x, y)) => point(p.curve, x, y)
  }
}

///|
fn check_projective(p : Point) -> Result[Bool, CurveError] {
  if !p.curve.field.equal(@gf.field_of(p.x)) ||
    !p.curve.field.equal(@gf.field_of(p.y)) ||
    !p.curve.field.equal(@gf.field_of(p.z)) {
    return Ok(false)
  }
  match curve(p.curve.field, p.curve.a, p.curve.b) {
    Err(_) => return Ok(false)
    Ok(_) => ()
  }
  if is_infinity(p) {
    let unit = @gf.one(p.curve.field)
    return Ok(p.x.equal(unit) && p.y.equal(unit))
  }
  let yy = match square(p.y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let xx = match square(p.x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let xxx = match times(xx, p.x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let zz = match square(p.z) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z4 = match square(zz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let z6 = match times(z4, zz) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ax = match times(p.curve.a, p.x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let axz4 = match times(ax, z4) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bz6 = match times(p.curve.b, z6) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let partial = match plus(xxx, axz4) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match plus(partial, bz6) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(yy.equal(right))
}

///|
/// Recheck field binding, curve nonsingularity and the Jacobian equation.
pub fn check_point(p : Point) -> Bool {
  match check_projective(p) {
    Ok(valid) => valid
    Err(_) => false
  }
}
