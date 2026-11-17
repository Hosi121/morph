///|
/// Values and ordinary first/second partials of one outcome probability.
/// All indices refer to the same coordinate chart, not to outcome indices.
#derive(Eq, Debug)
pub(all) struct SampleJet {
  probability : @exact.Rational
  gradient : @core.Chain[@exact.Rational]
  hessian : @matrix.Matrix[@exact.Rational]
}

///|
pub extend SampleJet with Eq::{equal, not_equal}

///|
pub extend SampleJet with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum ModelError {
  EmptySampleSpace
  DimensionMismatch
  NotInterior
  NotNormalized
  DerivativeNotNormalized
  HessianNotSymmetric
  SingularInformation
  ThirdDerivativeShape
  ThirdDerivativeSymmetry
  ThirdDerivativeNotNormalized
  InternalShape
}

///|
pub extend ModelError with Eq::{equal, not_equal}

///|
pub extend ModelError with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Sample {
  jet : SampleJet
  inverse : @exact.Rational
}

///|
pub extend Sample with Eq::{equal, not_equal}

///|
pub extend Sample with Debug::{to_repr}

///|
/// A normalized positive finite probability 2-jet at a point.
/// It need not be an immersion: the Fisher matrix may be singular.
#derive(Eq, Debug)
pub struct Model {
  dimension : @core.Nat
  samples : @core.Chain[Sample]
  distribution : @probability.Distribution
  metric : @matrix.Matrix[@exact.Rational]
}

///|
pub extend Model with Eq::{equal, not_equal}

///|
pub extend Model with Debug::{to_repr}

///|
fn sum(values : @core.Chain[@exact.Rational]) -> @exact.Rational {
  @core.fold_left(values, @exact.rational_zero(), @exact.rational_add)
}

///|
fn is_zero(value : @exact.Rational) -> Bool {
  value.equal(@exact.rational_zero())
}

///|
// These lookups are internal and only used after all dimensions are checked.
fn component(
  values : @core.Chain[@exact.Rational],
  index : @core.Nat,
) -> @exact.Rational {
  match @core.nth(values, index) {
    Some(value) => value
    None => @exact.rational_zero()
  }
}

///|
fn entry(
  matrix : @matrix.Matrix[@exact.Rational],
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  match @core.nth(@matrix.rows(matrix), i) {
    Some(row) => component(row, j)
    None => @exact.rational_zero()
  }
}

///|
fn table(
  dimension : @core.Nat,
  f : (@core.Nat, @core.Nat) -> @exact.Rational,
) -> @matrix.Matrix[@exact.Rational]? {
  let indices = @core.indices(dimension)
  @matrix.matrix(
    dimension,
    @core.map(indices, fn(i) { @core.map(indices, fn(j) { f(i, j) }) }),
  )
}

///|
fn prepare(
  dimension : @core.Nat,
  jets : @core.Chain[SampleJet],
) -> Result[@core.Chain[Sample], ModelError] {
  match jets {
    Nil => Ok(Nil)
    Cons(jet, rest) => {
      match
        @core.length(jet.gradient).equal(dimension) &&
        @matrix.height(jet.hessian).equal(dimension) &&
        @matrix.width(jet.hessian).equal(dimension) {
        false => return Err(DimensionMismatch)
        true => ()
      }
      match jet.hessian.equal(@matrix.transpose(jet.hessian)) {
        false => return Err(HessianNotSymmetric)
        true => ()
      }
      match @exact.rational_compare(jet.probability, @exact.rational_zero()) {
        Greater => ()
        _ => return Err(NotInterior)
      }
      match (@exact.nonzero(jet.probability), prepare(dimension, rest)) {
        (Some(nonzero), Ok(rest)) =>
          Ok(Cons({ jet, inverse: @exact.reciprocal(nonzero), }, rest))
        (_, Err(error)) => Err(error)
        _ => Err(NotInterior)
      }
    }
  }
}

///|
fn fisher_entry(
  samples : @core.Chain[Sample],
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  sum(
    @core.map(samples, fn(sample) {
      @exact.rational_multiply(
        @exact.rational_multiply(
          component(sample.jet.gradient, i),
          component(sample.jet.gradient, j),
        ),
        sample.inverse,
      )
    }),
  )
}

///|
pub fn model(
  dimension : @core.Nat,
  jets : @core.Chain[SampleJet],
) -> Result[Model, ModelError] {
  match jets {
    Nil => return Err(EmptySampleSpace)
    Cons(_, _) => ()
  }
  match prepare(dimension, jets) {
    Err(error) => Err(error)
    Ok(samples) => {
      let probabilities = @core.map(jets, fn(jet) { jet.probability })
      let distribution = match @probability.distribution(probabilities) {
        None => return Err(NotNormalized)
        Some(value) => value
      }
      let indices = @core.indices(dimension)
      match
        @core.all(indices, fn(i) {
          is_zero(sum(@core.map(jets, fn(jet) { component(jet.gradient, i) }))) &&
          @core.all(indices, fn(j) {
            is_zero(sum(@core.map(jets, fn(jet) { entry(jet.hessian, i, j) })))
          })
        }) {
        false => return Err(DerivativeNotNormalized)
        true => ()
      }
      match table(dimension, fn(i, j) { fisher_entry(samples, i, j) }) {
        None => Err(InternalShape)
        Some(metric) => Ok({ dimension, samples, distribution, metric, })
      }
    }
  }
}

///|
pub fn dimension(model : Model) -> @core.Nat {
  model.dimension
}

///|
pub fn distribution(model : Model) -> @probability.Distribution {
  model.distribution
}

///|
pub fn jets(model : Model) -> @core.Chain[SampleJet] {
  @core.map(model.samples, fn(sample) { sample.jet })
}

///|
pub fn fisher(model : Model) -> @matrix.Matrix[@exact.Rational] {
  model.metric
}

///|
/// Score rows are indexed by outcomes, columns by parameters.
pub fn scores(model : Model) -> @matrix.Matrix[@exact.Rational]? {
  @matrix.matrix(
    model.dimension,
    @core.map(model.samples, fn(sample) {
      @core.map(sample.jet.gradient, fn(derivative) {
        @exact.rational_multiply(derivative, sample.inverse)
      })
    }),
  )
}

///|
/// Slice i is the matrix with row j, column k: T[i][j][k].
pub type Tensor = @core.Chain[@matrix.Matrix[@exact.Rational]]

///|
fn tensor(
  dimension : @core.Nat,
  f : (@core.Nat, @core.Nat, @core.Nat) -> @exact.Rational,
) -> Tensor? {
  fn slices(indices : @core.Chain[@core.Nat]) -> Tensor? {
    match indices {
      Nil => Some(Nil)
      Cons(i, rest) =>
        match (table(dimension, fn(j, k) { f(i, j, k) }), slices(rest)) {
          (Some(slice), Some(rest)) => Some(Cons(slice, rest))
          _ => None
        }
    }
  }
  slices(@core.indices(dimension))
}

///|
fn cubic_entry(
  model : Model,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
) -> @exact.Rational {
  sum(
    @core.map(model.samples, fn(sample) {
      @exact.rational_multiply(
        @exact.rational_multiply(
          @exact.rational_multiply(
            component(sample.jet.gradient, i),
            component(sample.jet.gradient, j),
          ),
          component(sample.jet.gradient, k),
        ),
        @exact.rational_multiply(sample.inverse, sample.inverse),
      )
    }),
  )
}

///|
/// Amari-Chentsov covariant tensor T_ijk = E[score_i score_j score_k].
/// This convention fixes T = Gamma^(-1) - Gamma^(+1), with no factor one-half.
pub fn amari_chentsov(model : Model) -> Tensor? {
  tensor(model.dimension, fn(i, j, k) { cubic_entry(model, i, j, k) })
}

///|
/// Compatibility name for amari_chentsov.
pub fn cubic(model : Model) -> Tensor? {
  amari_chentsov(model)
}

///|
/// Lowered coefficients Gamma^(alpha)_{ij,k}; +1 exponential, -1 mixture.
pub fn alpha_lower(model : Model, alpha : @exact.Rational) -> Tensor? {
  let factor = @exact.rational_half(
    @exact.rational_add(@exact.rational_one(), alpha),
  )
  tensor(model.dimension, fn(i, j, k) {
    let mixture = sum(
      @core.map(model.samples, fn(sample) {
        @exact.rational_multiply(
          @exact.rational_multiply(
            entry(sample.jet.hessian, i, j),
            component(sample.jet.gradient, k),
          ),
          sample.inverse,
        )
      }),
    )
    @exact.rational_subtract(
      mixture,
      @exact.rational_multiply(factor, cubic_entry(model, i, j, k)),
    )
  })
}

///|
/// Slice k contains the ordinary coordinate derivative partial_k g_ij.
pub fn metric_first(model : Model) -> Tensor? {
  tensor(model.dimension, fn(k, i, j) {
    sum(
      @core.map(model.samples, fn(sample) {
        let a = component(sample.jet.gradient, i)
        let b = component(sample.jet.gradient, j)
        let c = component(sample.jet.gradient, k)
        @exact.rational_subtract(
          @exact.rational_multiply(
            @exact.rational_add(
              @exact.rational_multiply(entry(sample.jet.hessian, k, i), b),
              @exact.rational_multiply(a, entry(sample.jet.hessian, k, j)),
            ),
            sample.inverse,
          ),
          @exact.rational_multiply(
            @exact.rational_multiply(@exact.rational_multiply(a, b), c),
            @exact.rational_multiply(sample.inverse, sample.inverse),
          ),
        )
      }),
    )
  })
}

///|
/// Solve g v = dL. Singular models do not receive an arbitrary pseudo-inverse.
pub fn natural_gradient(
  model : Model,
  covector : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], ModelError] {
  match @core.length(covector).equal(model.dimension) {
    false => return Err(DimensionMismatch)
    true => ()
  }
  match @linear.solve(model.metric, covector) {
    Some(Unique(value)) => Ok(value)
    Some(Affine(_, _)) | Some(Inconsistent) => Err(SingularInformation)
    None => Err(InternalShape)
  }
}
