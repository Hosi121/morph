///|
#derive(Debug)
pub(all) struct PrimitiveCertificate {
  field : Certificate
  candidate : @core.Nat
  theta : @cf.Element
  modulus : @poly.Polynomial
  power_basis : @matrix.Matrix[@exact.Rational]
}

///|
pub extend PrimitiveCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Representation {
  priv field : Field
  priv proof : PrimitiveCertificate
}

///|
pub extend Representation with Debug::{to_repr}

///|
#derive(Debug)
pub struct PrimitiveSearch {
  priv field : Field
  priv next : @core.Nat
}

///|
pub extend PrimitiveSearch with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum PrimitiveProgress {
  PrimitiveReady(Representation, PrimitiveCertificate)
  PrimitivePaused(PrimitiveSearch)
}

///|
pub extend PrimitiveProgress with Debug::{to_repr}

///|
pub fn representation_field(value : Representation) -> Field {
  value.field
}

///|
pub fn primitive_element(value : Representation) -> @cf.Element {
  value.proof.theta
}

///|
pub fn modulus(value : Representation) -> @poly.Polynomial {
  value.proof.modulus
}

///|
pub fn primitive_certificate(value : Representation) -> PrimitiveCertificate {
  value.proof
}

///|
pub fn primitive_next_candidate(search : PrimitiveSearch) -> @core.Nat {
  search.next
}

///|
fn polynomial_degree(polynomial : @poly.Polynomial) -> @core.Nat? {
  match @poly.terms(polynomial) {
    Cons({ exponents: Cons(d, Nil), .. }, _) => Some(d)
    _ => None
  }
}

///|
fn canonical(d : @core.Nat, polynomial : @poly.Polynomial) -> Bool {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return false
  }
  match polynomial_degree(polynomial) {
    None => @poly.is_zero(polynomial)
    Some(k) => @core.compare(k, d).equal(Less)
  }
}

///|
fn rational_nat(value : @core.Nat) -> @exact.Rational {
  match value {
    Zero => @exact.rational_zero()
    Succ(rest) => @exact.rational_add(@exact.rational_one(), rational_nat(rest))
  }
}

///|
/// The complete basis separates distinct embeddings, so only finitely many
/// nonnegative integer candidates fail to be primitive in characteristic zero.
fn candidate_element(field : Field, candidate : @core.Nat) -> @cf.Element? {
  let c = rational_nat(candidate)
  fn coefficients(
    remaining : @core.Nat,
    coefficient : @exact.Rational,
  ) -> @core.Chain[@exact.Rational] {
    match remaining {
      Zero => Nil
      Succ(rest) =>
        Cons(
          coefficient,
          coefficients(rest, @exact.rational_multiply(c, coefficient)),
        )
    }
  }
  linear_combination(
    ambient(field),
    basis(field),
    coefficients(degree(field), @exact.rational_one()),
  )
}

///|
/// An ambient-N by subfield-r matrix: no assumption that r equals N.
fn power_matrix(
  field : Field,
  theta : @cf.Element,
) -> @matrix.Matrix[@exact.Rational]? {
  fn columns(n : @core.Nat, value : @cf.Element) -> @core.Chain[@cf.Element]? {
    match n {
      Zero => Some(Nil)
      Succ(rest) =>
        match @cf.multiply(value, theta) {
          Ok(next) =>
            match columns(rest, next) {
              Some(tail) => Some(Cons(value, tail))
              None => None
            }
          Err(_) => None
        }
    }
  }
  match columns(degree(field), @cf.one(ambient(field))) {
    Some(values) => basis_matrix(ambient(field), values)
    None => None
  }
}

///|
fn same_primitive_certificate(
  a : PrimitiveCertificate,
  b : PrimitiveCertificate,
) -> Bool {
  same_certificate(a.field, b.field) &&
  a.candidate.equal(b.candidate) &&
  @cf.equal(a.theta, b.theta) &&
  a.modulus.equal(b.modulus) &&
  a.power_basis.equal(b.power_basis)
}

///|
/// Recheck the generated field, the exact candidate, its true minimum and every
/// rectangular power-basis column. Rank r proves theta generates this subfield.
pub fn check_primitive(field : Field, proof : PrimitiveCertificate) -> Bool {
  if !check_result(ambient(field), generators(field), field, proof.field) ||
    !@cf.same_field(ambient(field), @cf.parent(proof.theta)) ||
    !polynomial_degree(proof.modulus).equal(Some(degree(field))) {
    return false
  }
  match candidate_element(field, proof.candidate) {
    Some(theta) => if !@cf.equal(theta, proof.theta) { return false }
    None => return false
  }
  if !@cf.check_minimal_polynomial(proof.theta, proof.modulus) {
    return false
  }
  match power_matrix(field, proof.theta) {
    Some(expected) => if !expected.equal(proof.power_basis) { return false }
    None => return false
  }
  match @linear.rref(proof.power_basis) {
    Some(reduced) => @core.length(reduced.pivots).equal(degree(field))
    None => false
  }
}

///|
pub fn from_primitive_certificate(
  field : Field,
  proof : PrimitiveCertificate,
) -> Result[Representation, SubfieldError] {
  if check_primitive(field, proof) {
    Ok({ field, proof, })
  } else {
    Err(InvalidCertificate)
  }
}

///|
pub fn check_primitive_result(
  field : Field,
  result : Representation,
  proof : PrimitiveCertificate,
) -> Bool {
  same_certificate(certificate(field), certificate(result.field)) &&
  same_primitive_certificate(result.proof, proof) &&
  check_primitive(field, proof)
}

///|
pub fn primitive_start(field : Field) -> PrimitiveSearch {
  { field, next: Zero, }
}

///|
/// Budget counts whole integer candidates. Each trial's exact CF minimum and
/// linear algebra run to completion; this is not an inner-operation fuel bound.
/// Pausing retains the next untried integer, without restarting earlier trials.
pub fn primitive_advance(
  search : PrimitiveSearch,
  budget : @core.Nat,
) -> Result[PrimitiveProgress, SubfieldError] {
  match budget {
    Zero => Ok(PrimitivePaused(search))
    Succ(rest) => {
      let field = search.field
      let theta = match candidate_element(field, search.next) {
        Some(value) => value
        None => return Err(InternalInvariant)
      }
      let minimum = match @cf.minimal_polynomial(theta) {
        Ok(value) => value
        Err(_) => return Err(InternalInvariant)
      }
      if !polynomial_degree(minimum).equal(Some(degree(field))) {
        return primitive_advance({ field, next: Succ(search.next), }, rest)
      }
      let power_basis = match power_matrix(field, theta) {
        Some(value) => value
        None => return Err(InternalInvariant)
      }
      let proof : PrimitiveCertificate = {
        field: certificate(field),
        candidate: search.next,
        theta,
        modulus: minimum,
        power_basis,
      }
      if check_primitive(field, proof) {
        Ok(PrimitiveReady({ field, proof, }, proof))
      } else {
        Err(InternalInvariant)
      }
    }
  }
}
