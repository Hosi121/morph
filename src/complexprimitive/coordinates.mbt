///|
fn coefficient(
  polynomial : @poly.Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(@poly.terms(polynomial), @exact.rational_zero(), fn(
    sum,
    term,
  ) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      @exact.rational_add(sum, term.coefficient)
    } else {
      sum
    }
  })
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
fn coordinates(value : @cf.Element) -> @core.Chain[@exact.Rational] {
  fn part(value : @nf.Element) -> @core.Chain[@exact.Rational] {
    @core.map(@core.indices(@nf.degree(@nf.parent(value))), fn(i) {
      coefficient(@nf.representative(value), i)
    })
  }
  @core.append(part(@cf.real_part(value)), part(@cf.imaginary_part(value)))
}

///|
fn power_basis(
  field : @cf.Field,
  theta : @cf.Element,
) -> @matrix.Matrix[@exact.Rational]? {
  fn columns(
    n : @core.Nat,
    power : @cf.Element,
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match n {
      Zero => Some(Nil)
      Succ(rest) =>
        match @cf.multiply(power, theta) {
          Ok(next) =>
            match columns(rest, next) {
              Some(tail) => Some(Cons(coordinates(power), tail))
              None => None
            }
          Err(_) => None
        }
    }
  }
  match columns(@cf.degree(field), @cf.one(field)) {
    Some(values) =>
      match @matrix.matrix(@cf.degree(field), values) {
        Some(matrix) => Some(@matrix.transpose(matrix))
        None => None
      }
    None => None
  }
}

///|
/// Only coefficient extraction and the shared matrix kernel are used here.
fn coordinates_polynomial(
  inverse_basis : @matrix.Matrix[@exact.Rational],
  value : @cf.Element,
) -> @poly.Polynomial? {
  let d = @cf.degree(@cf.parent(value))
  let vector = match @matrix.matrix(d, Cons(coordinates(value), Nil)) {
    Some(row) => @matrix.transpose(row)
    None => return None
  }
  match @matrix.multiply(inverse_basis, vector, @algebra.rationals()) {
    Some(product) =>
      match @matrix.column(product, Zero) {
        Some(values) =>
          match @core.zip(@core.indices(d), values) {
            Some(entries) =>
              match
                @poly.polynomial(
                  Succ(Zero),
                  @core.map(entries, fn(entry) {
                    let (i, c) = entry
                    @poly.Term::{ coefficient: c, exponents: Cons(i, Nil), }
                  }),
                ) {
                Ok(polynomial) => Some(polynomial)
                Err(_) => None
              }
            None => None
          }
        None => None
      }
    None => None
  }
}

///|
/// Horner evaluation is in the supplied checked CF context.
fn evaluate(theta : @cf.Element, polynomial : @poly.Polynomial) -> @cf.Element? {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  let count : @core.Nat = match polynomial_degree(polynomial) {
    Some(d) => Succ(d)
    None => Zero
  }
  fn go(
    todo : @core.Chain[@core.Nat],
    accumulated : @cf.Element,
  ) -> @cf.Element? {
    match todo {
      Nil => Some(accumulated)
      Cons(i, rest) =>
        match @cf.multiply(accumulated, theta) {
          Ok(product) =>
            match
              @cf.add(
                product,
                @cf.rational(@cf.parent(theta), coefficient(polynomial, i)),
              ) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
          Err(_) => None
        }
    }
  }
  go(@core.reverse(@core.indices(count)), @cf.zero(@cf.parent(theta)))
}

///|
/// Public untrusted conversion proof, bound to the full primitive presentation.
#derive(Debug)
pub(all) struct ConversionCertificate {
  representation : Certificate
  input : @cf.Element
  polynomial : @poly.Polynomial
}

///|
pub extend ConversionCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub(all) struct Conversion {
  polynomial : @poly.Polynomial
  certificate : ConversionCertificate
}

///|
pub extend Conversion with Debug::{to_repr}

///|
/// Check the separately supplied actual source and returned canonical result.
/// Evaluation, rather than producer coordinate metadata, establishes equality.
pub fn check_conversion_for(
  representation : Representation,
  input : @cf.Element,
  polynomial : @poly.Polynomial,
  proof : ConversionCertificate,
) -> Bool {
  if !@cf.same_field(source(representation), @cf.parent(input)) ||
    !@cf.equal(input, proof.input) ||
    !polynomial.equal(proof.polynomial) ||
    !same_certificate(representation.proof, proof.representation) ||
    !canonical(degree(representation), polynomial) ||
    !check(source(representation), proof.representation) {
    return false
  }
  match evaluate(generator(representation), polynomial) {
    Some(value) => @cf.equal(input, value)
    None => false
  }
}

///|
pub fn to_polynomial(
  representation : Representation,
  input : @cf.Element,
) -> Result[Conversion, PrimitiveError] {
  if !@cf.same_field(source(representation), @cf.parent(input)) {
    return Err(DifferentField)
  }
  match coordinates_polynomial(inverse_basis_matrix(representation), input) {
    Some(polynomial) => {
      let proof : ConversionCertificate = {
        representation: certificate(representation),
        input,
        polynomial,
      }
      Ok({ polynomial, certificate: proof, })
    }
    None => Err(InternalInvariant)
  }
}

///|
/// Accept any univariate polynomial, reduce modulo the absolute minimum, and
/// evaluate its unique remainder in the original CF context.
pub fn from_polynomial(
  representation : Representation,
  polynomial : @poly.Polynomial,
) -> Result[@cf.Element, PrimitiveError] {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return Err(NotUnivariate)
  }
  match @poly.normal_form(polynomial, Cons(modulus(representation), Nil)) {
    Ok(reduced) =>
      match evaluate(generator(representation), reduced) {
        Some(value) => Ok(value)
        None => Err(InternalInvariant)
      }
    Err(_) => Err(InternalInvariant)
  }
}
