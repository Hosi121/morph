///|
#derive(Eq, Debug)
pub(all) enum SubfieldError {
  InvalidCertificate
  DifferentField
  NotInSubfield
  DimensionMismatch
  NotUnivariate
  InternalInvariant
}

///|
pub extend SubfieldError with Eq::{equal, not_equal}

///|
pub extend SubfieldError with Debug::{to_repr}

///|
/// Public, untrusted proof of precisely Q(generators). Each basis value has a
/// generator-monomial witness. Independence and multiplication closure are
/// recomputed by the checker, establishing both inclusions of vector spaces.
#derive(Debug)
pub(all) struct Certificate {
  source : @cf.Field
  generators : @core.Chain[@cf.Element]
  degree : @core.Nat
  basis : @core.Chain[@cf.Element]
  monomials : @core.Chain[@core.Chain[@core.Nat]]
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Field {
  priv proof : Certificate
}

///|
pub extend Field with Debug::{to_repr}

///|
pub fn ambient(field : Field) -> @cf.Field {
  field.proof.source
}

///|
pub fn generators(field : Field) -> @core.Chain[@cf.Element] {
  field.proof.generators
}

///|
pub fn degree(field : Field) -> @core.Nat {
  field.proof.degree
}

///|
pub fn basis(field : Field) -> @core.Chain[@cf.Element] {
  field.proof.basis
}

///|
pub fn certificate(field : Field) -> Certificate {
  field.proof
}

///|
fn same_elements(
  a : @core.Chain[@cf.Element],
  b : @core.Chain[@cf.Element],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) => @cf.equal(x, y) && same_elements(xs, ys)
    _ => false
  }
}

///|
fn same_certificate(a : Certificate, b : Certificate) -> Bool {
  @cf.same_field(a.source, b.source) &&
  same_elements(a.generators, b.generators) &&
  a.degree.equal(b.degree) &&
  same_elements(a.basis, b.basis) &&
  a.monomials.equal(b.monomials)
}

///|
fn basis_matrix(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
) -> @matrix.Matrix[@exact.Rational]? {
  match @matrix.matrix(@cf.degree(source), @core.map(values, @cf.coordinates)) {
    Some(rows) => Some(@matrix.transpose(rows))
    None => None
  }
}

///|
fn span_coordinates(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  input : @cf.Element,
) -> @core.Chain[@exact.Rational]? {
  match basis_matrix(source, values) {
    Some(matrix) =>
      match @linear.solve(matrix, @cf.coordinates(input)) {
        Some(@linear.Unique(coefficients)) => Some(coefficients)
        _ => None
      }
    None => None
  }
}

///|
fn power(value : @cf.Element, exponent : @core.Nat) -> @cf.Element? {
  match exponent {
    Zero => Some(@cf.one(@cf.parent(value)))
    Succ(rest) =>
      match power(value, rest) {
        Some(previous) =>
          match @cf.multiply(previous, value) {
            Ok(result) => Some(result)
            Err(_) => None
          }
        None => None
      }
  }
}

///|
fn monomial(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  exponents : @core.Chain[@core.Nat],
) -> @cf.Element? {
  match (values, exponents) {
    (Nil, Nil) => Some(@cf.one(source))
    (Cons(value, rest), Cons(exponent, tail)) =>
      match (power(value, exponent), monomial(source, rest, tail)) {
        (Some(a), Some(b)) =>
          match @cf.multiply(a, b) {
            Ok(result) => Some(result)
            Err(_) => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// A closed independent span containing one proves completeness; monomial
/// provenance proves minimality, rejecting larger ambient subfields.
pub fn check(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  proof : Certificate,
) -> Bool {
  if !@cf.same_field(source, proof.source) ||
    !same_elements(values, proof.generators) ||
    !@core.all(@core.append(values, proof.basis), fn(value) {
      @cf.same_field(source, @cf.parent(value))
    }) ||
    @core.is_zero(proof.degree) ||
    !@core.length(proof.basis).equal(proof.degree) ||
    @core.compare(proof.degree, @cf.degree(source)).equal(Greater) ||
    !@core.any(proof.basis, fn(value) { @cf.equal(@cf.one(source), value) }) {
    return false
  }
  match @core.zip(proof.basis, proof.monomials) {
    Some(witnesses) =>
      if !@core.all(witnesses, fn(witness) {
          let (claimed, exponents) = witness
          match monomial(source, values, exponents) {
            Some(value) => @cf.equal(value, claimed)
            None => false
          }
        }) {
        return false
      }
    None => return false
  }
  let matrix = match basis_matrix(source, proof.basis) {
    Some(value) => value
    None => return false
  }
  match @linear.rref(matrix) {
    Some(reduced) =>
      if !@core.length(reduced.pivots).equal(proof.degree) {
        return false
      }
    None => return false
  }
  @core.all(proof.basis, fn(value) {
    @core.all(values, fn(generator) {
      match @cf.multiply(value, generator) {
        Ok(product) =>
          match @linear.solve(matrix, @cf.coordinates(product)) {
            Some(@linear.Unique(_)) => true
            _ => false
          }
        Err(_) => false
      }
    })
  })
}

///|
pub fn from_certificate(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  proof : Certificate,
) -> Result[Field, SubfieldError] {
  if check(source, values, proof) {
    Ok({ proof, })
  } else {
    Err(InvalidCertificate)
  }
}

///|
/// Bind the caller's source and generators, plus the entire actual result.
pub fn check_result(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  result : Field,
  proof : Certificate,
) -> Bool {
  same_certificate(result.proof, proof) && check(source, values, proof)
}

///|
pub fn contains(field : Field, input : @cf.Element) -> Bool {
  @cf.same_field(ambient(field), @cf.parent(input)) &&
  span_coordinates(ambient(field), basis(field), input) is Some(_)
}

///|
pub fn coordinates(
  field : Field,
  input : @cf.Element,
) -> Result[@core.Chain[@exact.Rational], SubfieldError] {
  if !@cf.same_field(ambient(field), @cf.parent(input)) {
    return Err(DifferentField)
  }
  match span_coordinates(ambient(field), basis(field), input) {
    Some(values) => Ok(values)
    None => Err(NotInSubfield)
  }
}

///|
fn linear_combination(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
  coefficients : @core.Chain[@exact.Rational],
) -> @cf.Element? {
  match (values, coefficients) {
    (Nil, Nil) => Some(@cf.zero(source))
    (Cons(value, rest), Cons(coefficient, tail)) =>
      match
        (
          @cf.multiply(value, @cf.rational(source, coefficient)),
          linear_combination(source, rest, tail),
        ) {
        (Ok(a), Some(b)) =>
          match @cf.add(a, b) {
            Ok(sum) => Some(sum)
            Err(_) => None
          }
        _ => None
      }
    _ => None
  }
}

///|
pub fn from_coordinates(
  field : Field,
  values : @core.Chain[@exact.Rational],
) -> Result[@cf.Element, SubfieldError] {
  if !@core.length(values).equal(degree(field)) {
    return Err(DimensionMismatch)
  }
  match linear_combination(ambient(field), basis(field), values) {
    Some(result) => Ok(result)
    None => Err(InternalInvariant)
  }
}
