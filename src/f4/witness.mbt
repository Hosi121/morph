///|
#derive(Eq, Debug)
pub(all) enum F4Error {
  DimensionMismatch
  InternalInvariant
}

///|
pub extend F4Error with Eq::{equal, not_equal}

///|
pub extend F4Error with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Annotated {
  value : @poly.Polynomial
  combination : @core.Chain[@poly.Polynomial]
}

///|
pub extend Annotated with Eq::{equal, not_equal}

///|
pub extend Annotated with Debug::{to_repr}

///|
fn[A] polynomial_result(
  value : Result[A, @poly.PolyError],
) -> Result[A, F4Error] {
  match value {
    Ok(value) => Ok(value)
    Err(_) => Err(InternalInvariant)
  }
}

///|
fn[A, B] traverse(
  values : @core.Chain[A],
  f : (A) -> Result[B, F4Error],
) -> Result[@core.Chain[B], F4Error] {
  match values {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      match (f(head), traverse(rest, f)) {
        (Ok(value), Ok(tail)) => Ok(Cons(value, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn scalar_term(
  variables : @core.Nat,
  coefficient : @exact.Rational,
) -> @poly.Term {
  { coefficient, exponents: @core.replicate(variables, Zero), }
}

///|
fn annotated_scale(
  value : Annotated,
  term : @poly.Term,
) -> Result[Annotated, F4Error] {
  match
    (
      polynomial_result(@poly.scale(value.value, term)),
      traverse(value.combination, fn(p) {
        polynomial_result(@poly.scale(p, term))
      }),
    ) {
    (Ok(value), Ok(combination)) => Ok({ value, combination, })
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
fn annotated_add(a : Annotated, b : Annotated) -> Result[Annotated, F4Error] {
  match @core.zip(a.combination, b.combination) {
    None => Err(InternalInvariant)
    Some(pairs) =>
      match
        (
          polynomial_result(@poly.add(a.value, b.value)),
          traverse(pairs, fn(pair) {
            let (x, y) = pair
            polynomial_result(@poly.add(x, y))
          }),
        ) {
        (Ok(value), Ok(combination)) => Ok({ value, combination, })
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn annotated_multiply(
  value : Annotated,
  weight : @poly.Polynomial,
) -> Result[Annotated, F4Error] {
  match
    (
      polynomial_result(@poly.multiply(value.value, weight)),
      traverse(value.combination, fn(p) {
        polynomial_result(@poly.multiply(p, weight))
      }),
    ) {
    (Ok(value), Ok(combination)) => Ok({ value, combination, })
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
fn annotated_monic(value : Annotated) -> Result[Annotated, F4Error] {
  match @poly.terms(value.value) {
    Nil => Ok(value)
    Cons(head, _) =>
      match @exact.nonzero(head.coefficient) {
        None => Err(InternalInvariant)
        Some(nonzero) =>
          annotated_scale(
            value,
            scalar_term(
              @poly.variables(value.value),
              @exact.reciprocal(nonzero),
            ),
          )
      }
  }
}

///|
fn zero_annotated(variables : @core.Nat, input_count : @core.Nat) -> Annotated {
  {
    value: @poly.zero(variables),
    combination: @core.replicate(input_count, @poly.zero(variables)),
  }
}

///|
fn combine_rows(
  variables : @core.Nat,
  input_count : @core.Nat,
  rows : @core.Chain[Annotated],
  weights : @core.Chain[@exact.Rational],
) -> Result[Annotated, F4Error] {
  match (rows, weights) {
    (Nil, Nil) => Ok(zero_annotated(variables, input_count))
    (Cons(row, rest), Cons(weight, tail)) =>
      match
        (
          annotated_scale(row, scalar_term(variables, weight)),
          combine_rows(variables, input_count, rest, tail),
        ) {
        (Ok(a), Ok(b)) => annotated_add(a, b)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(InternalInvariant)
  }
}

///|
/// Untrusted exact ideal-membership witnesses: each combination has one
/// coefficient polynomial per original input, in the supplied input order.
#derive(Eq, Debug)
pub(all) struct Certificate {
  polynomials : @core.Chain[@poly.Polynomial]
  combinations : @core.Chain[@core.Chain[@poly.Polynomial]]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
fn reconstruct(
  variables : @core.Nat,
  inputs : @core.Chain[@poly.Polynomial],
  weights : @core.Chain[@poly.Polynomial],
) -> Result[@poly.Polynomial, F4Error] {
  match (inputs, weights) {
    (Nil, Nil) => Ok(@poly.zero(variables))
    (Cons(input, rest), Cons(weight, tail)) =>
      match
        (
          polynomial_result(@poly.multiply(input, weight)),
          reconstruct(variables, rest, tail),
        ) {
        (Ok(a), Ok(b)) => polynomial_result(@poly.add(a, b))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
    _ => Err(DimensionMismatch)
  }
}

///|
/// Check ideal equality in both directions and Buchberger's criterion. This
/// never calls F4 symbolic preprocessing, matrix reduction, or basis search.
pub fn check(
  variables : @core.Nat,
  inputs : @core.Chain[@poly.Polynomial],
  certificate : Certificate,
) -> Result[Bool, F4Error] {
  let basis = certificate.polynomials
  let dimensions = @core.all(@core.append(inputs, basis), fn(p) {
      @core.compare(@poly.variables(p), variables).equal(Equal)
    }) &&
    @core.all(certificate.combinations, fn(row) {
      @core.compare(@core.length(row), @core.length(inputs)).equal(Equal) &&
      @core.all(row, fn(p) {
        @core.compare(@poly.variables(p), variables).equal(Equal)
      })
    })
  if !dimensions {
    return Err(DimensionMismatch)
  }
  if @core.any(basis, @poly.is_zero) {
    return Ok(false)
  }
  fn memberships(
    values : @core.Chain[@poly.Polynomial],
    combinations : @core.Chain[@core.Chain[@poly.Polynomial]],
  ) -> Result[Bool, F4Error] {
    match (values, combinations) {
      (Nil, Nil) => Ok(true)
      (Cons(value, rest), Cons(weights, tail)) =>
        match reconstruct(variables, inputs, weights) {
          Err(error) => Err(error)
          Ok(reconstructed) =>
            if !value.equal(reconstructed) || @poly.is_zero(value) {
              Ok(false)
            } else {
              memberships(rest, tail)
            }
        }
      _ => Ok(false)
    }
  }
  fn vanish(values : @core.Chain[@poly.Polynomial]) -> Result[Bool, F4Error] {
    match values {
      Nil => Ok(true)
      Cons(value, rest) =>
        match @poly.normal_form(value, basis) {
          Err(_) => Err(InternalInvariant)
          Ok(remainder) =>
            if @poly.is_zero(remainder) {
              vanish(rest)
            } else {
              Ok(false)
            }
        }
    }
  }
  fn pair_rows(
    a : @poly.Polynomial,
    values : @core.Chain[@poly.Polynomial],
  ) -> Result[Bool, F4Error] {
    match values {
      Nil => Ok(true)
      Cons(b, rest) =>
        match @groebner.s_polynomial(a, b) {
          Err(_) => Err(InternalInvariant)
          Ok(s) =>
            match @poly.normal_form(s, basis) {
              Err(_) => Err(InternalInvariant)
              Ok(remainder) =>
                if @poly.is_zero(remainder) {
                  pair_rows(a, rest)
                } else {
                  Ok(false)
                }
            }
        }
    }
  }
  fn all_pairs(
    values : @core.Chain[@poly.Polynomial],
  ) -> Result[Bool, F4Error] {
    match values {
      Nil => Ok(true)
      Cons(a, rest) =>
        match pair_rows(a, rest) {
          Ok(true) => all_pairs(rest)
          other => other
        }
    }
  }
  match (memberships(basis, certificate.combinations), vanish(inputs)) {
    (Ok(true), Ok(true)) => all_pairs(basis)
    (Err(error), _) | (_, Err(error)) => Err(error)
    _ => Ok(false)
  }
}
