///|
fn alpha_derivative_entry(
  point : ModelPoint,
  factor : @exact.Rational,
  k : @core.Nat,
  i : @core.Nat,
  j : @core.Nat,
  l : @core.Nat,
) -> @exact.Rational {
  let pairs = match @core.zip(point.model.samples, point.third) {
    None => return @exact.rational_zero()
    Some(pairs) => pairs
  }
  sum(
    @core.map(pairs, fn(pair) {
      let (sample, third) = pair
      let a = component(sample.jet.gradient, i)
      let b = component(sample.jet.gradient, j)
      let c = component(sample.jet.gradient, l)
      let d = component(sample.jet.gradient, k)
      let ij = entry(sample.jet.hessian, i, j)
      let ik = entry(sample.jet.hessian, i, k)
      let jk = entry(sample.jet.hessian, j, k)
      let lk = entry(sample.jet.hessian, l, k)
      let inverse_squared = @exact.rational_multiply(
        sample.inverse,
        sample.inverse,
      )
      let mixture = @exact.rational_subtract(
        @exact.rational_multiply(
          @exact.rational_add(
            @exact.rational_multiply(tensor_component(third, i, j, k), c),
            @exact.rational_multiply(ij, lk),
          ),
          sample.inverse,
        ),
        @exact.rational_multiply(
          @exact.rational_multiply(@exact.rational_multiply(ij, c), d),
          inverse_squared,
        ),
      )
      let numerator = @exact.rational_add(
        @exact.rational_add(
          @exact.rational_multiply(@exact.rational_multiply(ik, b), c),
          @exact.rational_multiply(@exact.rational_multiply(a, jk), c),
        ),
        @exact.rational_multiply(@exact.rational_multiply(a, b), lk),
      )
      let product = @exact.rational_multiply(
        @exact.rational_multiply(a, b),
        @exact.rational_multiply(c, d),
      )
      let cubic = @exact.rational_subtract(
        @exact.rational_multiply(numerator, inverse_squared),
        @exact.rational_multiply(
          @exact.rational_add(product, product),
          @exact.rational_multiply(inverse_squared, sample.inverse),
        ),
      )
      @exact.rational_subtract(mixture, @exact.rational_multiply(factor, cubic))
    }),
  )
}

///|
/// Ordinary coordinate partials of lowered connection coefficients.
/// Outer k, then tensor [i][j][l]: partial_k Gamma^(alpha)_ij,l.
/// These are connection derivatives, not tensor components under chart changes.
pub fn alpha_lower_first(
  point : ModelPoint,
  alpha : @exact.Rational,
) -> @core.Chain[Tensor]? {
  let factor = @exact.rational_half(
    @exact.rational_add(@exact.rational_one(), alpha),
  )
  traverse(@core.indices(point.model.dimension), fn(k) {
    tensor(point.model.dimension, fn(i, j, l) {
      alpha_derivative_entry(point, factor, k, i, j, l)
    })
  })
}
