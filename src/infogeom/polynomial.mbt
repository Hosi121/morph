///|
#derive(Eq, Debug)
pub(all) enum FamilyError {
  EmptyFamily
  PolynomialDimension
  NotNormalizedPolynomial
  PointDimension
  InvalidJet(ModelError)
  InternalDerivative
}

///|
pub extend FamilyError with Eq::{equal, not_equal}

///|
pub extend FamilyError with Debug::{to_repr}

///|
struct PolynomialDerivatives {
  value : @polynomial.Polynomial
  first : @core.Chain[@polynomial.Polynomial]
  second : @core.Chain[@core.Chain[@polynomial.Polynomial]]
  third : @core.Chain[@core.Chain[@core.Chain[@polynomial.Polynomial]]]
}

///|
/// Polynomial outcome functions whose sum is identically one.
/// Positivity is checked at evaluation points, not asserted on all of Q^d.
pub struct Family {
  dimension : @core.Nat
  derivatives : @core.Chain[PolynomialDerivatives]
}

///|
pub type PolynomialPoint = ModelPoint

///|
fn[A, B] traverse(values : @core.Chain[A], f : (A) -> B?) -> @core.Chain[B]? {
  match values {
    Nil => Some(Nil)
    Cons(value, rest) =>
      match (f(value), traverse(rest, f)) {
        (Some(value), Some(rest)) => Some(Cons(value, rest))
        _ => None
      }
  }
}

///|
fn derivatives(
  value : @polynomial.Polynomial,
  indices : @core.Chain[@core.Nat],
) -> PolynomialDerivatives? {
  let first = match
    traverse(indices, fn(i) { @polynomial.derivative(value, i) }) {
    None => return None
    Some(first) => first
  }
  let second = match
    traverse(first, fn(p) {
      traverse(indices, fn(i) { @polynomial.derivative(p, i) })
    }) {
    None => return None
    Some(second) => second
  }
  let third = match
    traverse(second, fn(row) {
      traverse(row, fn(p) {
        traverse(indices, fn(i) { @polynomial.derivative(p, i) })
      })
    }) {
    None => return None
    Some(third) => third
  }
  Some({ value, first, second, third, })
}

///|
pub fn family(
  dimension : @core.Nat,
  outcomes : @core.Chain[@polynomial.Polynomial],
) -> Result[Family, FamilyError] {
  match outcomes {
    Nil => return Err(EmptyFamily)
    Cons(_, _) => ()
  }
  match
    @core.all(outcomes, fn(p) { @polynomial.variables(p).equal(dimension) }) {
    false => return Err(PolynomialDimension)
    true => ()
  }
  let total = @core.fold_left(outcomes, Ok(@polynomial.zero(dimension)), fn(
    sum,
    p,
  ) {
    match sum {
      Err(error) => Err(error)
      Ok(sum) => @polynomial.add(sum, p)
    }
  })
  match total {
    Ok(total) =>
      match
        total.equal(@polynomial.constant(dimension, @exact.rational_one())) {
        false => return Err(NotNormalizedPolynomial)
        true => ()
      }
    Err(_) => return Err(PolynomialDimension)
  }
  let indices = @core.indices(dimension)
  match traverse(outcomes, fn(p) { derivatives(p, indices) }) {
    None => Err(InternalDerivative)
    Some(derivatives) => Ok({ dimension, derivatives, })
  }
}

///|
pub fn family_dimension(family : Family) -> @core.Nat {
  family.dimension
}

///|
pub fn outcome_polynomials(
  family : Family,
) -> @core.Chain[@polynomial.Polynomial] {
  @core.map(family.derivatives, fn(p) { p.value })
}

///|
fn evaluate_row(
  polynomials : @core.Chain[@polynomial.Polynomial],
  parameters : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  traverse(polynomials, fn(p) { @polynomial.evaluate(p, parameters) })
}

///|
fn evaluate_matrix(
  dimension : @core.Nat,
  rows : @core.Chain[@core.Chain[@polynomial.Polynomial]],
  parameters : @core.Chain[@exact.Rational],
) -> @matrix.Matrix[@exact.Rational]? {
  match traverse(rows, fn(row) { evaluate_row(row, parameters) }) {
    None => None
    Some(rows) => @matrix.matrix(dimension, rows)
  }
}

///|
pub fn at(
  family : Family,
  parameters : @core.Chain[@exact.Rational],
) -> Result[PolynomialPoint, FamilyError] {
  match @core.length(parameters).equal(family.dimension) {
    false => return Err(PointDimension)
    true => ()
  }
  let evaluated = traverse(family.derivatives, fn(p) {
    match
      (
        @polynomial.evaluate(p.value, parameters),
        evaluate_row(p.first, parameters),
        evaluate_matrix(family.dimension, p.second, parameters),
        traverse(p.third, fn(rows) {
          evaluate_matrix(family.dimension, rows, parameters)
        }),
      ) {
      (Some(probability), Some(gradient), Some(hessian), Some(third)) =>
        Some((SampleJet::{ probability, gradient, hessian, }, third))
      _ => None
    }
  })
  match evaluated {
    None => Err(InternalDerivative)
    Some(evaluated) => {
      let jets = @core.map(evaluated, fn(pair) {
        let (jet, _) = pair
        jet
      })
      match model(family.dimension, jets) {
        Err(error) => Err(InvalidJet(error))
        Ok(model) =>
          match
            model_point(
              model,
              @core.map(evaluated, fn(pair) {
                let (_, third) = pair
                third
              }),
            ) {
            Ok(point) => Ok(point)
            Err(error) => Err(InvalidJet(error))
          }
      }
    }
  }
}
