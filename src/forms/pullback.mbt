///|
/// A polynomial map from source variables to target coordinates. Each coordinate
/// is a canonical polynomial in source variables; target is their count.
#derive(Eq, Debug)
pub struct PolynomialMap {
  source : @core.Nat
  target : @core.Nat
  coordinates : @core.Chain[@poly.Polynomial]
}

///|
pub extend PolynomialMap with Eq::{equal, not_equal}

///|
pub extend PolynomialMap with Debug::{to_repr}

///|
pub fn polynomial_map(
  source : @core.Nat,
  coordinates : @core.Chain[@poly.Polynomial],
) -> Result[PolynomialMap, FormError] {
  if !@core.all(coordinates, fn(coordinate) {
      @poly.variables(coordinate).equal(source)
    }) {
    Err(CoefficientDimension)
  } else {
    Ok({ source, target: @core.length(coordinates), coordinates, })
  }
}

///|
pub fn map_source(value : PolynomialMap) -> @core.Nat {
  value.source
}

///|
pub fn map_target(value : PolynomialMap) -> @core.Nat {
  value.target
}

///|
pub fn map_coordinates(value : PolynomialMap) -> @core.Chain[@poly.Polynomial] {
  value.coordinates
}

///|
fn polynomial_power(
  value : @poly.Polynomial,
  exponent : @core.Nat,
) -> Result[@poly.Polynomial, FormError] {
  match exponent {
    Zero => Ok(@poly.constant(@poly.variables(value), @exact.rational_one()))
    Succ(_) => {
      let (half, odd) = @core.halve_nat(exponent)
      match polynomial_power(value, half) {
        Err(error) => Err(error)
        Ok(lower) =>
          match @poly.multiply(lower, lower) {
            Err(_) => Err(InternalInvariant)
            Ok(square) =>
              if odd {
                match @poly.multiply(value, square) {
                  Err(_) => Err(InternalInvariant)
                  Ok(result) => Ok(result)
                }
              } else {
                Ok(square)
              }
          }
      }
    }
  }
}

///|
fn substitute(
  mapping : PolynomialMap,
  coefficient : @poly.Polynomial,
) -> Result[@poly.Polynomial, FormError] {
  fn monomial(
    term : @poly.Term,
    exponents : @core.Chain[@core.Nat],
    coordinates : @core.Chain[@poly.Polynomial],
  ) -> Result[@poly.Polynomial, FormError] {
    match (exponents, coordinates) {
      (Nil, Nil) => Ok(@poly.constant(mapping.source, term.coefficient))
      (Cons(exponent, rest), Cons(coordinate, tail)) =>
        match
          (polynomial_power(coordinate, exponent), monomial(term, rest, tail)) {
          (Ok(factor), Ok(previous)) =>
            match @poly.multiply(factor, previous) {
              Err(_) => Err(InternalInvariant)
              Ok(result) => Ok(result)
            }
          _ => Err(InternalInvariant)
        }
      _ => Err(InternalInvariant)
    }
  }
  fn walk(
    terms : @core.Chain[@poly.Term],
  ) -> Result[@poly.Polynomial, FormError] {
    match terms {
      Nil => Ok(@poly.zero(mapping.source))
      Cons(term, rest) =>
        match
          (monomial(term, term.exponents, mapping.coordinates), walk(rest)) {
          (Ok(current), Ok(previous)) =>
            match @poly.add(current, previous) {
              Err(_) => Err(InternalInvariant)
              Ok(result) => Ok(result)
            }
          _ => Err(InternalInvariant)
        }
    }
  }
  if !@poly.variables(coefficient).equal(mapping.target) {
    Err(DimensionMismatch)
  } else {
    walk(@poly.terms(coefficient))
  }
}

///|
/// For F: QQ^source -> QQ^target, pull back a target form to the source. This is
/// substitution in coefficients and wedge multiplication of coordinate dF_i.
pub fn pullback(
  mapping : PolynomialMap,
  value : Form,
) -> Result[Form, FormError] {
  fn basis(
    indices : @core.Chain[@core.Nat],
    current : Form,
  ) -> Result[Form, FormError] {
    match indices {
      Nil => Ok(current)
      Cons(index, rest) =>
        match @core.nth(mapping.coordinates, index) {
          None => Err(InternalInvariant)
          Some(coordinate) =>
            match exterior_derivative(scalar(coordinate)) {
              Err(error) => Err(error)
              Ok(differential) =>
                match wedge(current, differential) {
                  Err(error) => Err(error)
                  Ok(updated) => basis(rest, updated)
                }
            }
        }
    }
  }
  fn walk(input : @core.Chain[Term]) -> Result[Form, FormError] {
    match input {
      Nil => Ok(zero(mapping.source, value.degree))
      Cons(term, rest) =>
        match substitute(mapping, term.coefficient) {
          Err(error) => Err(error)
          Ok(coefficient) =>
            match (basis(term.indices, scalar(coefficient)), walk(rest)) {
              (Ok(current), Ok(previous)) => add(current, previous)
              _ => Err(InternalInvariant)
            }
        }
    }
  }
  if !value.variables.equal(mapping.target) {
    Err(DimensionMismatch)
  } else {
    walk(value.terms)
  }
}
