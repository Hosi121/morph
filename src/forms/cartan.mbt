///|
/// A polynomial vector field with exactly n components in the same n variables.
#derive(Eq, Debug)
pub struct VectorField {
  variables : @core.Nat
  components : @core.Chain[@poly.Polynomial]
}

///|
pub extend VectorField with Eq::{equal, not_equal}

///|
pub extend VectorField with Debug::{to_repr}

///|
pub fn vector_field(
  variables : @core.Nat,
  components : @core.Chain[@poly.Polynomial],
) -> Result[VectorField, FormError] {
  if !@core.length(components).equal(variables) {
    Err(DimensionMismatch)
  } else if !@core.all(components, fn(coefficient) {
      @poly.variables(coefficient).equal(variables)
    }) {
    Err(CoefficientDimension)
  } else {
    Ok({ variables, components, })
  }
}

///|
pub fn vector_variables(value : VectorField) -> @core.Nat {
  value.variables
}

///|
pub fn vector_components(value : VectorField) -> @core.Chain[@poly.Polynomial] {
  value.components
}

///|
/// None is the zero in exterior degree -1, outside Form's Nat grading. It is
/// returned only at degree zero, after compatibility has been checked.
pub fn contract(vector : VectorField, value : Form) -> Result[Form?, FormError] {
  fn component(
    term : Term,
    remaining : @core.Chain[@core.Nat],
    prefix_reversed : @core.Chain[@core.Nat],
    negative : Bool,
  ) -> Result[@core.Chain[Term], FormError] {
    match remaining {
      Nil => Ok(Nil)
      Cons(index, rest) =>
        match @core.nth(vector.components, index) {
          None => Err(InternalInvariant)
          Some(coordinate) =>
            match
              (
                @poly.multiply(coordinate, term.coefficient),
                component(term, rest, Cons(index, prefix_reversed), !negative),
              ) {
              (Ok(product), Ok(tail)) => {
                let coefficient = if negative {
                  @poly.negate(product)
                } else {
                  product
                }
                let indices = @core.reverse_onto(prefix_reversed, rest)
                Ok(Cons({ coefficient, indices, }, tail))
              }
              _ => Err(InternalInvariant)
            }
        }
    }
  }
  fn walk(input : @core.Chain[Term]) -> Result[@core.Chain[Term], FormError] {
    match input {
      Nil => Ok(Nil)
      Cons(term, rest) =>
        match (component(term, term.indices, Nil, false), walk(rest)) {
          (Ok(current), Ok(tail)) => Ok(@core.append(current, tail))
          _ => Err(InternalInvariant)
        }
    }
  }
  if !vector.variables.equal(value.variables) {
    Err(DimensionMismatch)
  } else {
    match value.degree {
      Zero => Ok(None)
      Succ(previous) =>
        match walk(value.terms) {
          Err(error) => Err(error)
          Ok(input) =>
            match form(value.variables, previous, input) {
              Err(error) => Err(error)
              Ok(result) => Ok(Some(result))
            }
        }
    }
  }
}

///|
/// Cartan's formula L_X = d i_X + i_X d, with the absent degree -1 term handled
/// explicitly. The resulting exterior degree is always that of the input.
pub fn lie_derivative(
  vector : VectorField,
  value : Form,
) -> Result[Form, FormError] {
  match contract(vector, value) {
    Err(error) => Err(error)
    Ok(interior) =>
      match exterior_derivative(value) {
        Err(error) => Err(error)
        Ok(differential) =>
          match contract(vector, differential) {
            Err(error) => Err(error)
            Ok(None) => Err(InternalInvariant)
            Ok(Some(second)) =>
              match interior {
                None => Ok(second)
                Some(first) =>
                  match exterior_derivative(first) {
                    Err(error) => Err(error)
                    Ok(different) => add(different, second)
                  }
              }
          }
      }
  }
}
