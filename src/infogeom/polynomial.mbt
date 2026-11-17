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
pub struct PolynomialPoint {
  model : Model
  third : @core.Chain[Tensor]
}

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
          Ok({
            model,
            third: @core.map(evaluated, fn(pair) {
              let (_, third) = pair
              third
            }),
          })
      }
    }
  }
}

///|
pub fn local_model(point : PolynomialPoint) -> Model {
  point.model
}

///|
fn tensor_component(
  tensor : Tensor,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
) -> @exact.Rational {
  match @core.nth(tensor, i) {
    None => @exact.rational_zero()
    Some(matrix) => entry(matrix, j, k)
  }
}

///|
fn second_metric_entry(
  samples : @core.Chain[Sample],
  thirds : @core.Chain[Tensor],
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
  l : @core.Nat,
) -> @exact.Rational {
  match (samples, thirds) {
    (Cons(sample, rest), Cons(third, thirds)) => {
      let a = component(sample.jet.gradient, i)
      let b = component(sample.jet.gradient, j)
      let c = component(sample.jet.gradient, k)
      let d = component(sample.jet.gradient, l)
      let ik = entry(sample.jet.hessian, i, k)
      let il = entry(sample.jet.hessian, i, l)
      let jk = entry(sample.jet.hessian, j, k)
      let jl = entry(sample.jet.hessian, j, l)
      let kl = entry(sample.jet.hessian, k, l)
      let inverse_squared = @exact.rational_multiply(
        sample.inverse,
        sample.inverse,
      )
      let numerator_second = @exact.rational_add(
        @exact.rational_add(
          @exact.rational_multiply(tensor_component(third, i, k, l), b),
          @exact.rational_multiply(a, tensor_component(third, j, k, l)),
        ),
        @exact.rational_add(
          @exact.rational_multiply(ik, jl),
          @exact.rational_multiply(il, jk),
        ),
      )
      let denominator_first = @exact.rational_add(
        @exact.rational_add(
          @exact.rational_multiply(
            @exact.rational_add(
              @exact.rational_multiply(ik, b),
              @exact.rational_multiply(a, jk),
            ),
            d,
          ),
          @exact.rational_multiply(
            @exact.rational_add(
              @exact.rational_multiply(il, b),
              @exact.rational_multiply(a, jl),
            ),
            c,
          ),
        ),
        @exact.rational_multiply(@exact.rational_multiply(a, b), kl),
      )
      let product = @exact.rational_multiply(
        @exact.rational_multiply(a, b),
        @exact.rational_multiply(c, d),
      )
      let twice = @exact.rational_add(product, product)
      let value = @exact.rational_add(
        @exact.rational_subtract(
          @exact.rational_multiply(numerator_second, sample.inverse),
          @exact.rational_multiply(denominator_first, inverse_squared),
        ),
        @exact.rational_multiply(
          twice,
          @exact.rational_multiply(inverse_squared, sample.inverse),
        ),
      )
      @exact.rational_add(value, second_metric_entry(rest, thirds, i, j, k, l))
    }
    _ => @exact.rational_zero()
  }
}

///|
/// Outer indices k,l, matrix indices i,j: partial_k partial_l g_ij.
/// Third probability partials were generated symbolically, not finite differences.
pub fn metric_second(point : PolynomialPoint) -> @core.Chain[Tensor]? {
  traverse(@core.indices(point.model.dimension), fn(k) {
    tensor(point.model.dimension, fn(l, i, j) {
      second_metric_entry(point.model.samples, point.third, i, j, k, l)
    })
  })
}
