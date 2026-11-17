///|
#derive(Eq, Debug)
pub(all) struct BoundaryFace {
  omitted : @core.Nat
  negative : Bool
  simplex : Simplex
}

///|
pub extend BoundaryFace with Eq::{equal, not_equal}

///|
pub extend BoundaryFace with Debug::{to_repr}

///|
pub fn boundary(value : Simplex) -> @core.Chain[BoundaryFace] {
  match value.dimension {
    Zero => Nil
    Succ(previous) => {
      fn walk(
        remaining : @core.Chain[@core.Chain[@exact.Rational]],
        prefix_reversed : @core.Chain[@core.Chain[@exact.Rational]],
        index : @core.Nat,
        negative : Bool,
      ) -> @core.Chain[BoundaryFace] {
        match remaining {
          Nil => Nil
          Cons(head, rest) => {
            let simplex = Simplex::{
              ambient: value.ambient,
              dimension: previous,
              vertices: @core.reverse_onto(prefix_reversed, rest),
            }
            Cons(
              { omitted: index, negative, simplex, },
              walk(rest, Cons(head, prefix_reversed), Succ(index), !negative),
            )
          }
        }
      }
      walk(value.vertices, Nil, Zero, false)
    }
  }
}

///|
fn omits_exactly(
  original : @core.Chain[@core.Chain[@exact.Rational]],
  candidate : @core.Chain[@core.Chain[@exact.Rational]],
  omitted : @core.Nat,
) -> Bool {
  match (original, omitted) {
    (Cons(_, rest), Zero) => rest.equal(candidate)
    (Cons(head, rest), Succ(previous)) =>
      match candidate {
        Nil => false
        Cons(actual, tail) =>
          head.equal(actual) && omits_exactly(rest, tail, previous)
      }
    _ => false
  }
}

///|
fn valid_boundary_face(
  value : Simplex,
  index : @core.Nat,
  actual : BoundaryFace,
) -> Bool {
  let (_, negative) = @core.halve_nat(index)
  actual.omitted.equal(index) &&
  (if actual.negative { negative } else { !negative }) &&
  actual.simplex.ambient.equal(value.ambient) &&
  @core.Succ(actual.simplex.dimension).equal(value.dimension) &&
  omits_exactly(value.vertices, actual.simplex.vertices, index)
}

///|
/// Checks omission and parity directly; does not invoke boundary's construction.
pub fn check_boundary(
  value : Simplex,
  actual : @core.Chain[BoundaryFace],
) -> Bool {
  fn walk(
    remaining : @core.Chain[@core.Chain[@exact.Rational]],
    faces : @core.Chain[BoundaryFace],
    index : @core.Nat,
  ) -> Bool {
    match (remaining, faces) {
      (Nil, Nil) => true
      (Cons(_, rest), Cons(head, tail)) =>
        valid_boundary_face(value, index, head) && walk(rest, tail, Succ(index))
      _ => false
    }
  }
  match value.dimension {
    Zero => actual is Nil
    Succ(_) => walk(value.vertices, actual, Zero)
  }
}

///|
#derive(Eq, Debug)
pub(all) struct FaceIntegral {
  oriented : BoundaryFace
  integral : @exact.Rational
}

///|
pub extend FaceIntegral with Eq::{equal, not_equal}

///|
pub extend FaceIntegral with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StokesCertificate {
  simplex : Simplex
  integrand : @forms.Form
  differential : @forms.Form
  interior : @exact.Rational
  faces : @core.Chain[FaceIntegral]
  boundary : @exact.Rational
}

///|
pub extend StokesCertificate with Eq::{equal, not_equal}

///|
pub extend StokesCertificate with Debug::{to_repr}

///|
fn integrated_faces(
  faces : @core.Chain[BoundaryFace],
  integrand : @forms.Form,
) -> Result[@core.Chain[FaceIntegral], IntegrationError] {
  match faces {
    Nil => Ok(Nil)
    Cons(oriented, rest) =>
      match
        (
          integrate(oriented.simplex, integrand),
          integrated_faces(rest, integrand),
        ) {
        (Ok(integral), Ok(tail)) => Ok(Cons({ oriented, integral, }, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn signed_sum(faces : @core.Chain[FaceIntegral]) -> @exact.Rational {
  @core.fold_left(faces, @exact.rational_zero(), fn(total, face) {
    @exact.rational_add(
      total,
      if face.oriented.negative {
        @exact.rational_negate(face.integral)
      } else {
        face.integral
      },
    )
  })
}

///|
pub fn boundary_integral(
  value : Simplex,
  integrand : @forms.Form,
) -> Result[@exact.Rational, IntegrationError] {
  if !@forms.variables(integrand).equal(value.ambient) {
    Err(DimensionMismatch)
  } else if !@core.Succ(@forms.degree(integrand)).equal(value.dimension) {
    Err(DegreeMismatch)
  } else {
    match integrated_faces(boundary(value), integrand) {
      Err(error) => Err(error)
      Ok(faces) => Ok(signed_sum(faces))
    }
  }
}

///|
/// Checks the exact source differential, complete canonical oriented boundary,
/// every integral with the independent moment recurrence, and the Stokes equation.
/// It does not call stokes, boundary, integrate or factorial. Forms pullback/d and
/// exact arithmetic are shared dependencies.
pub fn check_stokes(certificate : StokesCertificate) -> Bool {
  let value = certificate.simplex
  if !@forms.variables(certificate.integrand).equal(value.ambient) ||
    !@core.Succ(@forms.degree(certificate.integrand)).equal(value.dimension) {
    return false
  }
  fn faces(
    vertices : @core.Chain[@core.Chain[@exact.Rational]],
    entries : @core.Chain[FaceIntegral],
    index : @core.Nat,
  ) -> Bool {
    match (vertices, entries) {
      (Nil, Nil) => true
      (Cons(_, rest), Cons(entry, tail)) =>
        valid_boundary_face(value, index, entry.oriented) &&
        check_integral(
          entry.oriented.simplex,
          certificate.integrand,
          entry.integral,
        ) &&
        faces(rest, tail, Succ(index))
      _ => false
    }
  }
  match @forms.exterior_derivative(certificate.integrand) {
    Err(_) => false
    Ok(differential) =>
      differential.equal(certificate.differential) &&
      check_integral(value, certificate.differential, certificate.interior) &&
      faces(value.vertices, certificate.faces, Zero) &&
      signed_sum(certificate.faces).equal(certificate.boundary) &&
      certificate.interior.equal(certificate.boundary)
  }
}

///|
pub fn stokes(
  value : Simplex,
  integrand : @forms.Form,
) -> Result[StokesCertificate, IntegrationError] {
  if !@forms.variables(integrand).equal(value.ambient) {
    Err(DimensionMismatch)
  } else if !@core.Succ(@forms.degree(integrand)).equal(value.dimension) {
    Err(DegreeMismatch)
  } else {
    match @forms.exterior_derivative(integrand) {
      Err(error) => Err(FormFailure(error))
      Ok(differential) =>
        match
          (
            integrate(value, differential),
            integrated_faces(boundary(value), integrand),
          ) {
          (Ok(interior), Ok(faces)) => {
            let boundary = signed_sum(faces)
            let certificate = StokesCertificate::{
              simplex: value,
              integrand,
              differential,
              interior,
              faces,
              boundary,
            }
            if check_stokes(certificate) {
              Ok(certificate)
            } else {
              Err(InternalInvariant)
            }
          }
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
}
