///|
fn moment(
  pairs : @core.Chain[(@exact.Rational, @core.Chain[@exact.Rational])],
  indices : @core.Chain[@core.Nat],
) -> @exact.Rational {
  sum(
    @core.map(pairs, fn(pair) {
      let (probability, values) = pair
      @core.fold_left(indices, probability, fn(value, index) {
        @exact.rational_multiply(value, component(values, index))
      })
    }),
  )
}

///|
/// A finite exponential-family germ at natural parameter zero, preserving the
/// positive carrier and sufficient statistics that imply the Hessian structure.
/// This is not a generic probability jet re-labelled as exponential.
#derive(Eq, Debug)
pub struct ExponentialFamily {
  base : @probability.Distribution
  statistics : @matrix.Matrix[@exact.Rational]
  pairs : @core.Chain[(@exact.Rational, @core.Chain[@exact.Rational])]
  covariance : @matrix.Matrix[@exact.Rational]
  skewness : Tensor
}

///|
pub extend ExponentialFamily with Eq::{equal, not_equal}

///|
pub extend ExponentialFamily with Debug::{to_repr}

///|
/// Checks the positive carrier and statistic dimensions, and computes cumulants
/// two/three only. Redundant statistics remain allowed until a metric is needed.
pub fn exponential_family(
  base : @probability.Distribution,
  statistics : @matrix.Matrix[@exact.Rational],
) -> Result[ExponentialFamily, ModelError] {
  match @matrix.height(statistics).equal(@probability.size(base)) {
    false => return Err(DimensionMismatch)
    true => ()
  }
  match @probability.is_interior(base) {
    false => return Err(NotInterior)
    true => ()
  }
  let d = @matrix.width(statistics)
  let indices = @core.indices(d)
  let probabilities = @probability.masses(base)
  let raw = match @core.zip(probabilities, @matrix.rows(statistics)) {
    None => return Err(DimensionMismatch)
    Some(raw) => raw
  }
  let means = @core.map(indices, fn(i) { moment(raw, Cons(i, Nil)) })
  let centered = @core.map(@matrix.rows(statistics), fn(row) {
    @core.map(indices, fn(i) {
      @exact.rational_subtract(component(row, i), component(means, i))
    })
  })
  let pairs = match @core.zip(probabilities, centered) {
    None => return Err(InternalShape)
    Some(pairs) => pairs
  }
  let covariance = match
    table(d, fn(i, j) { moment(pairs, Cons(i, Cons(j, Nil))) }) {
    None => return Err(InternalShape)
    Some(covariance) => covariance
  }
  let skewness = match
    tensor(d, fn(i, j, k) { moment(pairs, Cons(i, Cons(j, Cons(k, Nil)))) }) {
    None => return Err(InternalShape)
    Some(skewness) => skewness
  }
  Ok({ base, statistics, pairs, covariance, skewness, })
}

///|
pub fn ExponentialFamily::base(
  self : ExponentialFamily,
) -> @probability.Distribution {
  self.base
}

///|
pub fn ExponentialFamily::statistics(
  self : ExponentialFamily,
) -> @matrix.Matrix[@exact.Rational] {
  self.statistics
}

///|
pub fn ExponentialFamily::dimension(self : ExponentialFamily) -> @core.Nat {
  @matrix.width(self.statistics)
}

///|
pub fn ExponentialFamily::fisher(
  self : ExponentialFamily,
) -> @matrix.Matrix[@exact.Rational] {
  self.covariance
}

///|
pub fn ExponentialFamily::amari_chentsov(self : ExponentialFamily) -> Tensor {
  self.skewness
}

///|
/// Explicitly expand the per-outcome probability jet for the general algorithms.
pub fn ExponentialFamily::point(
  self : ExponentialFamily,
) -> Result[ModelPoint, ModelError] {
  let d = self.dimension()
  let pairs = self.pairs
  let covariance = self.covariance
  let skewness = self.skewness
  let jets = traverse(pairs, fn(pair) {
    let (probability, score) = pair
    let hessian = table(d, fn(i, j) {
      @exact.rational_multiply(
        probability,
        @exact.rational_subtract(
          @exact.rational_multiply(component(score, i), component(score, j)),
          entry(covariance, i, j),
        ),
      )
    })
    let third = tensor(d, fn(i, j, k) {
      let a = component(score, i)
      let b = component(score, j)
      let c = component(score, k)
      let correction = @exact.rational_add(
        @exact.rational_add(
          @exact.rational_multiply(entry(covariance, i, j), c),
          @exact.rational_multiply(entry(covariance, i, k), b),
        ),
        @exact.rational_add(
          @exact.rational_multiply(entry(covariance, j, k), a),
          tensor_component(skewness, i, j, k),
        ),
      )
      @exact.rational_multiply(
        probability,
        @exact.rational_subtract(
          @exact.rational_multiply(@exact.rational_multiply(a, b), c),
          correction,
        ),
      )
    })
    match (hessian, third) {
      (Some(hessian), Some(third)) =>
        Some(
          (
            SampleJet::{
              probability,
              gradient: @core.map(score, fn(value) {
                @exact.rational_multiply(probability, value)
              }),
              hessian,
            },
            third,
          ),
        )
      _ => None
    }
  })
  match jets {
    None => Err(InternalShape)
    Some(jets) => {
      let values = @core.map(jets, fn(pair) {
        let (jet, _) = pair
        jet
      })
      match model(d, values) {
        Err(error) => Err(error)
        Ok(source) =>
          model_point(
            source,
            @core.map(jets, fn(pair) {
              let (_, third) = pair
              third
            }),
          )
      }
    }
  }
}

///|
/// Compatibility entry point: explicitly expand an exponential family's three-jet.
pub fn exponential_point(
  base : @probability.Distribution,
  statistics : @matrix.Matrix[@exact.Rational],
) -> Result[ModelPoint, ModelError] {
  match exponential_family(base, statistics) {
    Err(error) => Err(error)
    Ok(family) => family.point()
  }
}
