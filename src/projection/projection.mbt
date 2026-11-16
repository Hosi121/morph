///|
#derive(Eq, Debug)
pub(all) enum Method {
  CollinsProjection
  ProductProjection
}

///|
pub extend Method with Eq::{equal, not_equal}

///|
pub extend Method with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum ProjectionError {
  InvalidVariable
  WrongArity
  ArithmeticFailure
}

///|
pub extend ProjectionError with Eq::{equal, not_equal}

///|
pub extend ProjectionError with Debug::{to_repr}

///|
/// Every original atom and its order are retained, including zeros/constants.
/// Coefficients and PSCs retain zeros and duplicates. Product is Some only for
/// the separately named product projection, not for full Collins projection.
#derive(Eq, Debug)
pub(all) struct Certificate {
  mode : Method
  atoms : @core.Chain[@poly.Polynomial]
  variable : @core.Nat
  product : @poly.Polynomial?
  coefficients : @core.Chain[@poly.Polynomial]
  principal : @core.Chain[@poly.Polynomial]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
pub struct Plan {
  proof : Certificate
}

///|
pub fn certificate(plan : Plan) -> Certificate {
  plan.proof
}

///|
pub fn atoms(plan : Plan) -> @core.Chain[@poly.Polynomial] {
  plan.proof.atoms
}

///|
pub fn variable(plan : Plan) -> @core.Nat {
  plan.proof.variable
}

///|
pub fn mode(plan : Plan) -> Method {
  plan.proof.mode
}

///|
pub fn product(plan : Plan) -> @poly.Polynomial? {
  plan.proof.product
}

///|
pub fn coefficients(plan : Plan) -> @core.Chain[@poly.Polynomial] {
  plan.proof.coefficients
}

///|
pub fn principal_coefficients(plan : Plan) -> @core.Chain[@poly.Polynomial] {
  plan.proof.principal
}

///|
pub fn polynomials(plan : Plan) -> @core.Chain[@poly.Polynomial] {
  @core.append(plan.proof.coefficients, plan.proof.principal)
}

///|
fn validate(
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[Unit, ProjectionError] {
  let two = @core.Succ(@core.Succ(@core.Zero))
  if !(@core.compare(selected, two) is Less) {
    Err(InvalidVariable)
  } else if @core.all(atoms, fn(p) {
      @core.compare(@poly.variables(p), two) is Equal
    }) {
    Ok(())
  } else {
    Err(WrongArity)
  }
}

///|
fn input(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@eliminate.Input, ProjectionError] {
  match @eliminate.input(p, selected) {
    Ok(p) => Ok(p)
    Err(_) => Err(ArithmeticFailure)
  }
}

///|
fn coefficient_rows(
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match atoms {
    Nil => Ok(Nil)
    Cons(p, rest) =>
      match input(p, selected) {
        Err(error) => Err(error)
        Ok(p) =>
          match
            (
              @eliminate.coefficient_polynomials(p),
              coefficient_rows(rest, selected),
            ) {
            (Ok(coefficients), Ok(tail)) => Ok(@core.append(coefficients, tail))
            _ => Err(ArithmeticFailure)
          }
      }
  }
}

///|
fn principal_pair(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match (input(f, selected), input(g, selected)) {
    (Ok(f), Ok(g)) =>
      match @eliminate.principal_coefficients_variable(f, g) {
        Ok(values) => Ok(values)
        Err(_) => Err(ArithmeticFailure)
      }
    _ => Err(ArithmeticFailure)
  }
}

///|
fn derivative_principal(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match @poly.derivative(p, selected) {
    None => Err(ArithmeticFailure)
    Some(derivative) => principal_pair(p, derivative, selected)
  }
}

///|
fn multiply_atoms(
  atoms : @core.Chain[@poly.Polynomial],
  accumulated : @poly.Polynomial,
) -> Result[@poly.Polynomial, ProjectionError] {
  match atoms {
    Nil => Ok(accumulated)
    Cons(p, rest) =>
      if @poly.is_zero(p) {
        multiply_atoms(rest, accumulated)
      } else {
        match @poly.multiply(accumulated, p) {
          Ok(next) => multiply_atoms(rest, next)
          Err(_) => Err(ArithmeticFailure)
        }
      }
  }
}

///|
/// All nonzero atoms multiply with content, shared factors and multiplicities
/// intact. Empty/nonzero-empty products are one. Nullification is a lift issue;
/// this function never returns a NoSolutions conclusion.
pub fn product_projection(
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[Plan, ProjectionError] {
  match validate(atoms, selected) {
    Err(error) => Err(error)
    Ok(_) =>
      match
        multiply_atoms(
          atoms,
          @poly.constant(
            @core.Succ(@core.Succ(@core.Zero)),
            @exact.rational_one(),
          ),
        ) {
        Err(error) => Err(error)
        Ok(product) =>
          match
            (
              coefficient_rows(Cons(product, Nil), selected),
              derivative_principal(product, selected),
            ) {
            (Ok(coefficients), Ok(principal)) =>
              Ok({
                proof: {
                  mode: ProductProjection,
                  atoms,
                  variable: selected,
                  product: Some(product),
                  coefficients,
                  principal,
                },
              })
            _ => Err(ArithmeticFailure)
          }
      }
  }
}
