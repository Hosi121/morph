///|
/// A nonsingular short Weierstrass curve over one checked finite-field presentation.
#derive(Eq, Debug)
pub struct Curve {
  field : @gf.Field
  a : @gf.Element
  b : @gf.Element
}

///|
pub extend Curve with Eq::{equal, not_equal}

///|
pub extend Curve with Debug::{to_repr}

///|
/// Affine observations are canonical finite-field elements.
#derive(Eq, Debug)
pub(all) enum Coordinates {
  AtInfinity
  Affine(@gf.Element, @gf.Element)
}

///|
pub extend Coordinates with Eq::{equal, not_equal}

///|
pub extend Coordinates with Debug::{to_repr}

///|
/// Jacobian coordinates are private. Use equal for projective equality.
#derive(Debug)
pub struct Point {
  curve : Curve
  x : @gf.Element
  y : @gf.Element
  z : @gf.Element
}

///|
pub extend Point with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CurveError {
  FieldMismatch
  DifferentCurve
  UnsupportedCharacteristic
  SingularCurve
  InvalidPoint
  FieldFailure(@gf.FieldError)
}

///|
pub extend CurveError with Eq::{equal, not_equal}

///|
pub extend CurveError with Debug::{to_repr}

///|
pub fn field(curve : Curve) -> @gf.Field {
  curve.field
}

///|
pub fn coefficients(curve : Curve) -> (@gf.Element, @gf.Element) {
  (curve.a, curve.b)
}

///|
pub fn parent(point : Point) -> Curve {
  point.curve
}

///|
/// Equal presentations and coefficients; no implicit isomorphism of fields.
pub fn same_curve(a : Curve, b : Curve) -> Bool {
  a.equal(b)
}
