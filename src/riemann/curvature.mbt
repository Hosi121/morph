///|
/// Exact pointwise curvature, retaining its checked metric and connection.
#derive(Eq, Debug)
pub struct Curvature {
  source : Connection
  lower : Tensor4
  upper : Tensor4
  contraction : Tensor2
  scalar : @exact.Rational
}

///|
pub extend Curvature with Eq::{equal, not_equal}

///|
pub extend Curvature with Debug::{to_repr}

///|
/// R^i_jkl = partial_k Gamma^i_lj - partial_l Gamma^i_kj
///            + Gamma^i_km Gamma^m_lj - Gamma^i_lm Gamma^m_kj.
/// R_ijkl lowers i; Ric_jl = sum_i R^i_jil; scalar = sum_jl g^jl Ric_jl.
/// The unit round two-sphere has scalar curvature positive two in this convention.
pub fn curvature(value : Connection) -> Curvature {
  let jet = connection_jet(value)
  let indices = @core.indices(dimension(jet))
  let lower = table4(indices, fn(i, j, k, l) {
    let second = @exact.rational_half(
      @exact.rational_subtract(
        @exact.rational_add(
          second_value(jet, j, k, i, l),
          second_value(jet, i, l, j, k),
        ),
        @exact.rational_add(
          second_value(jet, j, l, i, k),
          second_value(jet, i, k, j, l),
        ),
      ),
    )
    let quadratic = sum(indices, fn(a) {
      @exact.rational_subtract(
        @exact.rational_multiply(
          value3(value.lower, a, i, l),
          value3(value.upper, a, j, k),
        ),
        @exact.rational_multiply(
          value3(value.lower, a, i, k),
          value3(value.upper, a, j, l),
        ),
      )
    })
    @exact.rational_add(second, quadratic)
  })
  let inverse = @matrix.rows(inverse_metric(jet))
  let upper = table4(indices, fn(i, j, k, l) {
    sum(indices, fn(a) {
      @exact.rational_multiply(value2(inverse, i, a), value4(lower, a, j, k, l))
    })
  })
  let contraction = table2(indices, fn(j, l) {
    sum(indices, fn(i) { value4(upper, i, j, i, l) })
  })
  let scalar = sum(indices, fn(j) {
    sum(indices, fn(l) {
      @exact.rational_multiply(value2(inverse, j, l), value2(contraction, j, l))
    })
  })
  { source: value, lower, upper, contraction, scalar, }
}

///|
pub fn curvature_connection(value : Curvature) -> Connection {
  value.source
}

///|
pub fn lowered_riemann(value : Curvature) -> Tensor4 {
  value.lower
}

///|
pub fn riemann(value : Curvature) -> Tensor4 {
  value.upper
}

///|
pub fn ricci(value : Curvature) -> Tensor2 {
  value.contraction
}

///|
pub fn scalar_curvature(value : Curvature) -> @exact.Rational {
  value.scalar
}
