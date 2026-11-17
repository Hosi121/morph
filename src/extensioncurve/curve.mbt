///|
fn field_result(
  value : Result[@gf.Element, @gf.FieldError],
) -> Result[@gf.Element, CurveError] {
  match value {
    Ok(value) => Ok(value)
    Err(error) => Err(FieldFailure(error))
  }
}

///|
fn plus(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, CurveError] {
  field_result(@gf.add(a, b))
}

///|
fn minus(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, CurveError] {
  field_result(@gf.subtract(a, b))
}

///|
fn times(a : @gf.Element, b : @gf.Element) -> Result[@gf.Element, CurveError] {
  field_result(@gf.multiply(a, b))
}

///|
fn square(value : @gf.Element) -> Result[@gf.Element, CurveError] {
  times(value, value)
}

///|
fn twice(value : @gf.Element) -> Result[@gf.Element, CurveError] {
  plus(value, value)
}

///|
fn thrice(value : @gf.Element) -> Result[@gf.Element, CurveError] {
  let two = match twice(value) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  plus(two, value)
}

///|
fn fourfold(value : @gf.Element) -> Result[@gf.Element, CurveError] {
  let two = match twice(value) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  twice(two)
}

///|
fn eightfold(value : @gf.Element) -> Result[@gf.Element, CurveError] {
  let four = match fourfold(value) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  twice(four)
}

///|
/// Field mismatch precedes characteristic and discriminant checks.
pub fn curve(
  field : @gf.Field,
  a : @gf.Element,
  b : @gf.Element,
) -> Result[Curve, CurveError] {
  if !field.equal(@gf.field_of(a)) || !field.equal(@gf.field_of(b)) {
    return Err(FieldMismatch)
  }
  let three = @binary.successor(@binary.double(@binary.one()))
  if !@binary.compare(@gf.characteristic(field), three).equal(Greater) {
    return Err(UnsupportedCharacteristic)
  }
  let a_square = match square(a) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let a_cube = match times(a_square, a) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let four_a_cube = match fourfold(a_cube) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let b_square = match square(b) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let three_b_square = match thrice(b_square) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let nine_b_square = match thrice(three_b_square) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let twenty_seven_b_square = match thrice(nine_b_square) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let discriminant = match plus(four_a_cube, twenty_seven_b_square) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if @gf.is_zero(discriminant) {
    Err(SingularCurve)
  } else {
    Ok({ field, a, b, })
  }
}

///|
fn rhs(curve : Curve, x : @gf.Element) -> Result[@gf.Element, CurveError] {
  let xx = match square(x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let xxx = match times(xx, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ax = match times(curve.a, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let partial = match plus(xxx, ax) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  plus(partial, curve.b)
}

///|
pub fn infinity(curve : Curve) -> Point {
  {
    curve,
    x: @gf.one(curve.field),
    y: @gf.one(curve.field),
    z: @gf.zero(curve.field),
  }
}

///|
pub fn is_infinity(point : Point) -> Bool {
  @gf.is_zero(point.z)
}

///|
/// Coordinates must belong to exactly this field presentation and lie on the curve.
pub fn point(
  curve : Curve,
  x : @gf.Element,
  y : @gf.Element,
) -> Result[Point, CurveError] {
  if !curve.field.equal(@gf.field_of(x)) || !curve.field.equal(@gf.field_of(y)) {
    return Err(FieldMismatch)
  }
  let yy = match square(y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match rhs(curve, x) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if yy.equal(right) {
    Ok({ curve, x, y, z: @gf.one(curve.field), })
  } else {
    Err(InvalidPoint)
  }
}
