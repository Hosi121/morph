///|
/// Pointwise Levi-Civita symbols in the coordinate frame of the metric jet.
#derive(Eq, Debug)
pub struct Connection {
  source : MetricJet
  lower : Tensor3
  upper : Tensor3
}

///|
pub extend Connection with Eq::{equal, not_equal}

///|
pub extend Connection with Debug::{to_repr}

///|
/// lower[i][j][k] = Gamma_ijk = (partial_j g_ik + partial_k g_ij - partial_i g_jk)/two.
/// upper[i][j][k] = Gamma^i_jk. Both are symmetric in j,k.
pub fn connection(jet : MetricJet) -> Connection {
  let indices = @core.indices(dimension(jet))
  let lower = table3(indices, fn(i, j, k) {
    @exact.rational_half(
      @exact.rational_subtract(
        @exact.rational_add(
          first_value(jet, j, i, k),
          first_value(jet, k, i, j),
        ),
        first_value(jet, i, j, k),
      ),
    )
  })
  let inverse = @matrix.rows(inverse_metric(jet))
  let upper = table3(indices, fn(i, j, k) {
    sum(indices, fn(l) {
      @exact.rational_multiply(value2(inverse, i, l), value3(lower, l, j, k))
    })
  })
  { source: jet, lower, upper, }
}

///|
pub fn connection_jet(value : Connection) -> MetricJet {
  value.source
}

///|
pub fn christoffel_first(value : Connection) -> Tensor3 {
  value.lower
}

///|
pub fn christoffel_second(value : Connection) -> Tensor3 {
  value.upper
}
