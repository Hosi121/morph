///|
/// Push a probability jet through a parameter-independent stochastic channel.
/// Outcome spaces may differ. Parameters, derivatives and chart stay the same.
/// Zero-mass output outcomes are outside the open-simplex model invariant.
pub fn through(
  source : Model,
  channel : @probability.Channel,
) -> Result[Model, ModelError] {
  let pairs = match
    @core.zip(source.samples, @probability.channel_rows(channel)) {
    None => return Err(DimensionMismatch)
    Some(pairs) => pairs
  }
  fn output(
    y : @core.Nat,
    value : (Sample) -> @exact.Rational,
  ) -> @exact.Rational {
    sum(
      @core.map(pairs, fn(pair) {
        let (sample, row) = pair
        // y is always inside the checked channel output dimension.
        let weight = component(@probability.masses(row), y)
        @exact.rational_multiply(weight, value(sample))
      }),
    )
  }
  let jets = traverse(@core.indices(@probability.output_size(channel)), fn(y) {
    match
      table(source.dimension, fn(i, j) {
        output(y, fn(sample) { entry(sample.jet.hessian, i, j) })
      }) {
      None => None
      Some(hessian) =>
        Some(SampleJet::{
          probability: output(y, fn(sample) { sample.jet.probability }),
          gradient: @core.map(@core.indices(source.dimension), fn(i) {
            output(y, fn(sample) { component(sample.jet.gradient, i) })
          }),
          hessian,
        })
    }
  })
  match jets {
    None => Err(InternalShape)
    Some(jets) => model(source.dimension, jets)
  }
}

///|
/// Reuse a fixed channel at every point of a normalized polynomial family.
pub fn through_family(
  source : Family,
  channel : @probability.Channel,
) -> Result[Family, FamilyError] {
  let pairs = match
    @core.zip(outcome_polynomials(source), @probability.channel_rows(channel)) {
    None => return Err(PolynomialDimension)
    Some(pairs) => pairs
  }
  let outcomes = traverse(@core.indices(@probability.output_size(channel)), fn(
    y,
  ) {
    @core.fold_left(pairs, Some(@polynomial.zero(source.dimension)), fn(
      total,
      pair,
    ) {
      let (p, row) = pair
      let weight = component(@probability.masses(row), y)
      match total {
        None => None
        Some(total) =>
          match
            @polynomial.multiply(
              p,
              @polynomial.constant(source.dimension, weight),
            ) {
            Err(_) => None
            Ok(p) =>
              match @polynomial.add(total, p) {
                Err(_) => None
                Ok(total) => Some(total)
              }
          }
      }
    })
  })
  match outcomes {
    None => Err(InternalDerivative)
    Some(outcomes) => family(source.dimension, outcomes)
  }
}
