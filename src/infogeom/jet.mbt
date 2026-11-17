///|
/// A normalized positive probability 3-jet at a point.
pub struct ModelPoint {
  model : Model
  third : @core.Chain[Tensor]
}

///|
/// Third partials are indexed by outcome, then i,j,k.
pub fn model_point(
  source : Model,
  third : @core.Chain[Tensor],
) -> Result[ModelPoint, ModelError] {
  let d = source.dimension
  match
    @core.length(third).equal(@core.length(source.samples)) &&
    @core.all(third, fn(tensor) {
      @core.length(tensor).equal(d) &&
      @core.all(tensor, fn(matrix) {
        @matrix.height(matrix).equal(d) && @matrix.width(matrix).equal(d)
      })
    }) {
    false => return Err(ThirdDerivativeShape)
    true => ()
  }
  let indices = @core.indices(d)
  match
    @core.all(indices, fn(i) {
      @core.all(indices, fn(j) {
        @core.all(indices, fn(k) {
          @core.all(third, fn(tensor) {
            let value = tensor_component(tensor, i, j, k)
            value.equal(tensor_component(tensor, j, i, k)) &&
            value.equal(tensor_component(tensor, i, k, j))
          })
        })
      })
    }) {
    false => return Err(ThirdDerivativeSymmetry)
    true => ()
  }
  match
    @core.all(indices, fn(i) {
      @core.all(indices, fn(j) {
        @core.all(indices, fn(k) {
          is_zero(
            sum(
              @core.map(third, fn(tensor) { tensor_component(tensor, i, j, k) }),
            ),
          )
        })
      })
    }) {
    false => Err(ThirdDerivativeNotNormalized)
    true => Ok({ model: source, third, })
  }
}

///|
pub fn third_derivatives(point : ModelPoint) -> @core.Chain[Tensor] {
  point.third
}

///|
pub fn local_model(point : ModelPoint) -> Model {
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
pub fn metric_second(point : ModelPoint) -> @core.Chain[Tensor]? {
  traverse(@core.indices(point.model.dimension), fn(k) {
    tensor(point.model.dimension, fn(l, i, j) {
      second_metric_entry(point.model.samples, point.third, i, j, k, l)
    })
  })
}
