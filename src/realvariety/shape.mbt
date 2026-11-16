///|
/// Provenance uses actual supplied basis rows. The selected eliminant and each
/// linear coordinate row are normalized and checked, then every basis row is
/// substituted and reduced modulo the eliminant. This proves both directions.
#derive(Eq, Debug)
pub(all) struct ShapeCertificate {
  variables : @core.Nat
  basis : @core.Chain[@poly.Polynomial]
  eliminant_source : @poly.Polynomial
  coordinate_sources : @core.Chain[@poly.Polynomial]
  eliminant : @poly.Polynomial
  coordinates : @core.Chain[@poly.Polynomial]
}

///|
pub extend ShapeCertificate with Eq::{equal, not_equal}

///|
pub extend ShapeCertificate with Debug::{to_repr}

///|
fn contains_polynomial(
  value : @poly.Polynomial,
  values : @core.Chain[@poly.Polynomial],
) -> Bool {
  @core.any(values, fn(p) { p.equal(value) })
}

///|
pub fn check_shape(proof : ShapeCertificate) -> Bool {
  fn coordinates(
    sources : @core.Chain[@poly.Polynomial],
    values : @core.Chain[@poly.Polynomial],
    index : @core.Nat,
    parameter_index : @core.Nat,
  ) -> Bool {
    if index.equal(parameter_index) {
      match (sources, values, parameter_polynomial()) {
        (Nil, Cons(last, Nil), Some(t)) => last.equal(t)
        _ => false
      }
    } else {
      match (sources, values) {
        (Cons(source, rest), Cons(value, tail)) =>
          if !contains_polynomial(source, proof.basis) {
            false
          } else {
            match coordinate_expression(source, proof.variables, index) {
              None => false
              Some(h) =>
                match @poly.normal_form(h, Cons(proof.eliminant, Nil)) {
                  Ok(reduced) =>
                    reduced.equal(value) &&
                    coordinates(rest, tail, Succ(index), parameter_index)
                  Err(_) => false
                }
            }
          }
        _ => false
      }
    }
  }
  match proof.variables {
    Zero => false
    Succ(parameter_index) =>
      if !@core.all(proof.basis, fn(p) {
          @poly.variables(p).equal(proof.variables)
        }) ||
        !contains_polynomial(proof.eliminant_source, proof.basis) ||
        !positive_degree(proof.eliminant) {
        false
      } else {
        match as_parameter(proof.eliminant_source, proof.variables) {
          None => false
          Some(g) =>
            @poly.monic(g).equal(proof.eliminant) &&
            coordinates(
              proof.coordinate_sources,
              proof.coordinates,
              Zero,
              parameter_index,
            ) &&
            @core.all(proof.basis, fn(p) {
              match substitute_mod(p, proof.coordinates, proof.eliminant) {
                Ok(remainder) => @poly.is_zero(remainder)
                Err(_) => false
              }
            })
        }
      }
  }
}

///|
#derive(Eq, Debug)
pub struct Shape {
  certificate : ShapeCertificate
  system : @sturm.System
}

///|
pub extend Shape with Eq::{equal, not_equal}

///|
pub extend Shape with Debug::{to_repr}

///|
pub fn shape_certificate(value : Shape) -> ShapeCertificate {
  value.certificate
}

///|
pub fn shape_from_certificate(
  proof : ShapeCertificate,
) -> Result[Shape, VarietyError] {
  if !check_shape(proof) {
    Err(InvalidCertificate)
  } else {
    match @sturm.system(proof.eliminant) {
      Ok(system) => Ok({ certificate: proof, system, })
      Err(_) => Err(InternalInvariant)
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct UnitCertificate {
  variables : @core.Nat
  basis : @core.Chain[@poly.Polynomial]
  witness : @poly.Polynomial
}

///|
pub extend UnitCertificate with Eq::{equal, not_equal}

///|
pub extend UnitCertificate with Debug::{to_repr}

///|
pub fn check_unit(proof : UnitCertificate) -> Bool {
  @core.all(proof.basis, fn(p) { @poly.variables(p).equal(proof.variables) }) &&
  contains_polynomial(proof.witness, proof.basis) &&
  nonzero_constant(proof.witness)
}

///|
#derive(Eq, Debug)
pub(all) enum UnsupportedReason {
  NoParameter
  NoEliminant
  NotShapePosition
}

///|
pub extend UnsupportedReason with Eq::{equal, not_equal}

///|
pub extend UnsupportedReason with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Extraction {
  ShapeReady(Shape)
  UnitIdeal(UnitCertificate)
  Unsupported(UnsupportedReason)
}

///|
pub extend Extraction with Eq::{equal, not_equal}

///|
pub extend Extraction with Debug::{to_repr}

///|
/// A checked shape-form presentation of the supplied equations. This raw entry
/// does not claim that the equations came from an original ideal: use from_basis
/// or check_basis_shape to link the F4 bidirectional ideal certificate.
pub fn extract(
  variables : @core.Nat,
  basis : @core.Chain[@poly.Polynomial],
) -> Result[Extraction, VarietyError] {
  fn unit(values : @core.Chain[@poly.Polynomial]) -> @poly.Polynomial? {
    match values {
      Nil => None
      Cons(head, rest) =>
        if nonzero_constant(head) {
          Some(head)
        } else {
          unit(rest)
        }
    }
  }
  fn find_coordinate(
    index : @core.Nat,
    values : @core.Chain[@poly.Polynomial],
  ) -> (@poly.Polynomial, @poly.Polynomial)? {
    match values {
      Nil => None
      Cons(head, rest) =>
        match coordinate_expression(head, variables, index) {
          Some(h) => Some((head, h))
          None => find_coordinate(index, rest)
        }
    }
  }
  fn find_shape(
    values : @core.Chain[@poly.Polynomial],
    parameter_index : @core.Nat,
  ) -> Shape? {
    fn coordinate_rows(
      index : @core.Nat,
      eliminant : @poly.Polynomial,
    ) -> (@core.Chain[@poly.Polynomial], @core.Chain[@poly.Polynomial])? {
      if index.equal(parameter_index) {
        match parameter_polynomial() {
          Some(t) => Some((Nil, Cons(t, Nil)))
          None => None
        }
      } else {
        match
          (
            find_coordinate(index, basis),
            coordinate_rows(Succ(index), eliminant),
          ) {
          (Some((source, h)), Some((sources, coordinates))) =>
            match @poly.normal_form(h, Cons(eliminant, Nil)) {
              Ok(h) => Some((Cons(source, sources), Cons(h, coordinates)))
              Err(_) => None
            }
          _ => None
        }
      }
    }
    match values {
      Nil => None
      Cons(source, rest) =>
        match as_parameter(source, variables) {
          Some(g) =>
            if positive_degree(g) {
              let eliminant = @poly.monic(g)
              match coordinate_rows(Zero, eliminant) {
                Some((coordinate_sources, coordinates)) => {
                  let proof : ShapeCertificate = {
                    variables,
                    basis,
                    eliminant_source: source,
                    coordinate_sources,
                    eliminant,
                    coordinates,
                  }
                  match shape_from_certificate(proof) {
                    Ok(shape) => Some(shape)
                    Err(_) => find_shape(rest, parameter_index)
                  }
                }
                None => find_shape(rest, parameter_index)
              }
            } else {
              find_shape(rest, parameter_index)
            }
          None => find_shape(rest, parameter_index)
        }
    }
  }
  if !@core.all(basis, fn(p) { @poly.variables(p).equal(variables) }) {
    Err(DimensionMismatch)
  } else {
    match unit(basis) {
      Some(witness) => Ok(UnitIdeal({ variables, basis, witness, }))
      None =>
        match variables {
          Zero => Ok(Unsupported(NoParameter))
          Succ(parameter_index) =>
            match find_shape(basis, parameter_index) {
              Some(shape) => Ok(ShapeReady(shape))
              None => {
                let has_eliminant = @core.any(basis, fn(p) {
                  match as_parameter(p, variables) {
                    Some(g) => positive_degree(g)
                    None => false
                  }
                })
                Ok(
                  Unsupported(
                    if has_eliminant {
                      NotShapePosition
                    } else {
                      NoEliminant
                    },
                  ),
                )
              }
            }
        }
    }
  }
}

///|
pub fn from_basis(basis : @f4.Basis) -> Result[Extraction, VarietyError] {
  match @f4.verify(basis) {
    Err(error) => Err(F4Failure(error))
    Ok(false) => Err(InvalidBasis)
    Ok(true) => extract(@f4.variables(basis), @f4.polynomials(basis))
  }
}

///|
pub fn check_basis_shape(basis : @f4.Basis, proof : ShapeCertificate) -> Bool {
  match @f4.verify(basis) {
    Ok(true) =>
      @f4.variables(basis).equal(proof.variables) &&
      @f4.polynomials(basis).equal(proof.basis) &&
      check_shape(proof)
    _ => false
  }
}
