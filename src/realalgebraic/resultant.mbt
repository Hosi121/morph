///|
#derive(Eq, Debug)
pub(all) enum BinaryOperation {
  Sum
  Product
}

///|
pub extend BinaryOperation with Eq::{equal, not_equal}

///|
pub extend BinaryOperation with Debug::{to_repr}

///|
fn transformed(
  right : @core.Chain[@exact.Rational],
  point : @exact.Rational,
  operation : BinaryOperation,
) -> @core.Chain[@exact.Rational] {
  match operation {
    Sum => {
      fn compose(
        values : @core.Chain[@exact.Rational],
      ) -> @core.Chain[@exact.Rational] {
        match values {
          Nil => Nil
          Cons(head, rest) =>
            dense_add(
              Cons(head, Nil),
              dense_multiply(
                Cons(
                  point,
                  Cons(@exact.rational_negate(@exact.rational_one()), Nil),
                ),
                compose(rest),
              ),
            )
        }
      }
      compose(right)
    }
    Product => {
      fn scaled(
        values : @core.Chain[@exact.Rational],
        power : @exact.Rational,
      ) -> @core.Chain[@exact.Rational] {
        match values {
          Nil => Nil
          Cons(head, rest) =>
            Cons(
              @exact.rational_multiply(head, power),
              scaled(rest, @exact.rational_multiply(power, point)),
            )
        }
      }
      @core.reverse(scaled(right, @exact.rational_one()))
    }
  }
}

///|
/// Fixed nominal degrees are retained even when a specialization drops degree.
/// The first polynomial is monic, so padding a dropped second leading term
/// introduces no extra leading-coefficient factor in the scalar resultant.
fn sylvester(
  left : @core.Chain[@exact.Rational],
  right : @core.Chain[@exact.Rational],
  m : @core.Nat,
  n : @core.Nat,
  point : @exact.Rational,
  operation : BinaryOperation,
) -> @exact.Rational? {
  let size = @core.add(m, n)
  fn rows(
    coefficients : @core.Chain[@exact.Rational],
    count : @core.Nat,
    shift : @core.Nat,
  ) -> @core.Chain[@core.Chain[@exact.Rational]] {
    match count {
      Zero => Nil
      Succ(rest) =>
        Cons(
          @core.take(
            size,
            @core.replicate_onto(
              shift,
              @exact.rational_zero(),
              @core.append(
                coefficients,
                @core.replicate(size, @exact.rational_zero()),
              ),
            ),
          ),
          rows(coefficients, rest, Succ(shift)),
        )
    }
  }
  let data = @core.append(
    rows(@core.reverse(left), n, Zero),
    rows(@core.reverse(transformed(right, point, operation)), m, Zero),
  )
  match @matrix.matrix(size, data) {
    Some(matrix) => @linear.determinant(matrix)
    None => None
  }
}

///|
/// The polynomial is the resultant of monic input definitions. Samples are
/// exact Sylvester determinants at the integer points zero through m*n.
#derive(Eq, Debug)
pub(all) struct ResultantCertificate {
  left : @poly.Polynomial
  right : @poly.Polynomial
  operation : BinaryOperation
  polynomial : @poly.Polynomial
  samples : @core.Chain[@exact.Rational]
}

///|
pub extend ResultantCertificate with Eq::{equal, not_equal}

///|
pub extend ResultantCertificate with Debug::{to_repr}

///|
/// This checker does not repeat interpolation: it verifies the degree bound and
/// evaluates the claimed polynomial at every independently recomputed sample.
pub fn check_resultant(proof : ResultantCertificate) -> Bool {
  match
    (
      positive_dense(proof.left),
      positive_dense(proof.right),
      dense(proof.polynomial),
    ) {
    (Some((m, left)), Some((n, right)), Some(claimed)) => {
      let bound = @core.multiply(m, n)
      fn samples(
        values : @core.Chain[@exact.Rational],
        remaining : @core.Nat,
        point : @core.Nat,
      ) -> Bool {
        match (values, remaining) {
          (Nil, Zero) => true
          (Cons(head, tail), Succ(rest)) => {
            let x = rnat(point)
            match sylvester(left, right, m, n, x, proof.operation) {
              Some(expected) =>
                expected.equal(head) &&
                dense_evaluate(claimed, x).equal(head) &&
                samples(tail, rest, Succ(point))
              None => false
            }
          }
          _ => false
        }
      }
      match dense_degree(claimed) {
        Some(degree) =>
          !@core.compare(degree, bound).equal(Greater) &&
          samples(proof.samples, Succ(bound), Zero)
        None => false
      }
    }
    _ => false
  }
}

///|
#derive(Eq, Debug)
pub struct Resultant {
  left : @poly.Polynomial
  right : @poly.Polynomial
  left_dense : @core.Chain[@exact.Rational]
  right_dense : @core.Chain[@exact.Rational]
  m : @core.Nat
  n : @core.Nat
  operation : BinaryOperation
  remaining : @core.Nat
  point : @core.Nat
  coefficients : @core.Chain[@exact.Rational]
  basis : @core.Chain[@exact.Rational]
  samples : @core.Chain[@exact.Rational]
}

///|
pub extend Resultant with Eq::{equal, not_equal}

///|
pub extend Resultant with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum ResultantProgress {
  ResultantReady(ResultantCertificate)
  ResultantPaused(Resultant)
}

///|
pub extend ResultantProgress with Eq::{equal, not_equal}

///|
pub extend ResultantProgress with Debug::{to_repr}

///|
pub fn resultant_start(
  left : @poly.Polynomial,
  right : @poly.Polynomial,
  operation : BinaryOperation,
) -> Result[Resultant, AlgebraError] {
  match (positive_dense(left), positive_dense(right)) {
    (Some((m, left_dense)), Some((n, right_dense))) =>
      Ok({
        left: @poly.monic(left),
        right: @poly.monic(right),
        left_dense,
        right_dense,
        m,
        n,
        operation,
        remaining: Succ(@core.multiply(m, n)),
        point: Zero,
        coefficients: Nil,
        basis: Cons(@exact.rational_one(), Nil),
        samples: Nil,
      })
    _ => Err(InvalidDefinition)
  }
}

///|
/// Fuel counts exact determinant/interpolation points, not field operations.
pub fn resultant_advance(
  state : Resultant,
  fuel : @core.Nat,
) -> Result[ResultantProgress, AlgebraError] {
  match state.remaining {
    Zero =>
      match sparse(state.coefficients) {
        Some(polynomial) =>
          Ok(
            ResultantReady({
              left: state.left,
              right: state.right,
              operation: state.operation,
              polynomial,
              samples: @core.reverse(state.samples),
            }),
          )
        None => Err(InternalInvariant)
      }
    Succ(remaining) =>
      match fuel {
        Zero => Ok(ResultantPaused(state))
        Succ(rest) => {
          let point = rnat(state.point)
          match
            sylvester(
              state.left_dense,
              state.right_dense,
              state.m,
              state.n,
              point,
              state.operation,
            ) {
            None => Err(InternalInvariant)
            Some(sample) =>
              match
                @exact.rational_divide(
                  @exact.rational_subtract(
                    sample,
                    dense_evaluate(state.coefficients, point),
                  ),
                  dense_evaluate(state.basis, point),
                ) {
                None => Err(InternalInvariant)
                Some(coefficient) => {
                  let coefficients = dense_add(
                    state.coefficients,
                    dense_scale(state.basis, coefficient),
                  )
                  let basis = dense_multiply(
                    state.basis,
                    Cons(
                      @exact.rational_negate(point),
                      Cons(@exact.rational_one(), Nil),
                    ),
                  )
                  resultant_advance(
                    {
                      ..state,
                      remaining,
                      point: Succ(state.point),
                      coefficients,
                      basis,
                      samples: Cons(sample, state.samples),
                    },
                    rest,
                  )
                }
              }
          }
        }
      }
  }
}
