///|
/// Dense immutable components, with indices in the written left-to-right order.
pub type Tensor2 = @core.Chain[@core.Chain[@exact.Rational]]

///|
pub type Tensor3 = @core.Chain[Tensor2]

///|
pub type Tensor4 = @core.Chain[Tensor3]

///|
#derive(Eq, Debug)
pub(all) enum JetError {
  MetricShape
  FirstDerivativeShape
  SecondDerivativeShape
  MetricSymmetry
  FirstDerivativeSymmetry
  SecondDerivativeSymmetry
  MixedDerivativeSymmetry
  SingularMetric
}

///|
pub extend JetError with Eq::{equal, not_equal}

///|
pub extend JetError with Debug::{to_repr}

///|
/// A pointwise coordinate two-jet of a symmetric, nondegenerate metric.
/// Positive definiteness is NOT part of this invariant: indefinite metrics pass.
/// first[k][i,j] = partial_k g_ij; second[k][l][i,j] = partial_k partial_l g_ij.
/// No manifold, chart domain, analytic expression, or global geometry is supplied.
#derive(Eq, Debug)
pub struct MetricJet {
  value : @matrix.Matrix[@exact.Rational]
  inverse_value : @matrix.Matrix[@exact.Rational]
  first : @core.Chain[@matrix.Matrix[@exact.Rational]]
  second : @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]]
}

///|
pub extend MetricJet with Eq::{equal, not_equal}

///|
pub extend MetricJet with Debug::{to_repr}

///|
fn square(matrix : @matrix.Matrix[@exact.Rational], n : @core.Nat) -> Bool {
  @matrix.height(matrix).equal(n) && @matrix.width(matrix).equal(n)
}

///|
fn symmetric(matrix : @matrix.Matrix[@exact.Rational]) -> Bool {
  matrix.equal(@matrix.transpose(matrix))
}

///|
/// Validate shapes before symmetries, then invertibility. Zero dimension is valid.
pub fn metric_jet(
  value : @matrix.Matrix[@exact.Rational],
  first : @core.Chain[@matrix.Matrix[@exact.Rational]],
  second : @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]],
) -> Result[MetricJet, JetError] {
  let n = @matrix.width(value)
  if !square(value, n) {
    return Err(MetricShape)
  }
  if !@core.length(first).equal(n) ||
    !@core.all(first, fn(matrix) { square(matrix, n) }) {
    return Err(FirstDerivativeShape)
  }
  if !@core.length(second).equal(n) ||
    !@core.all(second, fn(row) {
      @core.length(row).equal(n) &&
      @core.all(row, fn(matrix) { square(matrix, n) })
    }) {
    return Err(SecondDerivativeShape)
  }
  if !symmetric(value) {
    return Err(MetricSymmetry)
  }
  if !@core.all(first, symmetric) {
    return Err(FirstDerivativeSymmetry)
  }
  if !@core.all(second, fn(row) { @core.all(row, symmetric) }) {
    return Err(SecondDerivativeSymmetry)
  }
  let indices = @core.indices(n)
  if !@core.all(indices, fn(k) {
      @core.all(indices, fn(l) {
        match (@core.nth(second, k), @core.nth(second, l)) {
          (Some(a), Some(b)) => @core.nth(a, l).equal(@core.nth(b, k))
          _ => false
        }
      })
    }) {
    return Err(MixedDerivativeSymmetry)
  }
  match @linear.inverse(value) {
    None => Err(SingularMetric)
    Some(inverse_value) => Ok({ value, inverse_value, first, second, })
  }
}

///|
pub fn dimension(jet : MetricJet) -> @core.Nat {
  @matrix.width(jet.value)
}

///|
pub fn metric(jet : MetricJet) -> @matrix.Matrix[@exact.Rational] {
  jet.value
}

///|
pub fn inverse_metric(jet : MetricJet) -> @matrix.Matrix[@exact.Rational] {
  jet.inverse_value
}

///|
pub fn first_derivatives(
  jet : MetricJet,
) -> @core.Chain[@matrix.Matrix[@exact.Rational]] {
  jet.first
}

///|
pub fn second_derivatives(
  jet : MetricJet,
) -> @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]] {
  jet.second
}

///|
pub fn component2(
  values : Tensor2,
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational? {
  match @core.nth(values, i) {
    None => None
    Some(row) => @core.nth(row, j)
  }
}

///|
pub fn component3(
  values : Tensor3,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
) -> @exact.Rational? {
  match @core.nth(values, i) {
    None => None
    Some(matrix) => component2(matrix, j, k)
  }
}

///|
pub fn component4(
  values : Tensor4,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
  l : @core.Nat,
) -> @exact.Rational? {
  match @core.nth(values, i) {
    None => None
    Some(tensor) => component3(tensor, j, k, l)
  }
}

///|
/// Zero extension is private. Computations use only the validated index range.
fn value2(values : Tensor2, i : @core.Nat, j : @core.Nat) -> @exact.Rational {
  match component2(values, i, j) {
    None => @exact.rational_zero()
    Some(value) => value
  }
}

///|
fn value3(
  values : Tensor3,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
) -> @exact.Rational {
  match component3(values, i, j, k) {
    None => @exact.rational_zero()
    Some(value) => value
  }
}

///|
fn value4(
  values : Tensor4,
  i : @core.Nat,
  j : @core.Nat,
  k : @core.Nat,
  l : @core.Nat,
) -> @exact.Rational {
  match component4(values, i, j, k, l) {
    None => @exact.rational_zero()
    Some(value) => value
  }
}

///|
fn sum(
  indices : @core.Chain[@core.Nat],
  term : (@core.Nat) -> @exact.Rational,
) -> @exact.Rational {
  @core.fold_left(indices, @exact.rational_zero(), fn(total, i) {
    @exact.rational_add(total, term(i))
  })
}

///|
fn table2(
  indices : @core.Chain[@core.Nat],
  term : (@core.Nat, @core.Nat) -> @exact.Rational,
) -> Tensor2 {
  @core.map(indices, fn(i) { @core.map(indices, fn(j) { term(i, j) }) })
}

///|
fn table3(
  indices : @core.Chain[@core.Nat],
  term : (@core.Nat, @core.Nat, @core.Nat) -> @exact.Rational,
) -> Tensor3 {
  @core.map(indices, fn(i) { table2(indices, fn(j, k) { term(i, j, k) }) })
}

///|
fn table4(
  indices : @core.Chain[@core.Nat],
  term : (@core.Nat, @core.Nat, @core.Nat, @core.Nat) -> @exact.Rational,
) -> Tensor4 {
  @core.map(indices, fn(i) { table3(indices, fn(j, k, l) { term(i, j, k, l) }) })
}

///|
fn first_value(
  jet : MetricJet,
  k : @core.Nat,
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  match @core.nth(jet.first, k) {
    None => @exact.rational_zero()
    Some(matrix) => value2(@matrix.rows(matrix), i, j)
  }
}

///|
fn second_value(
  jet : MetricJet,
  k : @core.Nat,
  l : @core.Nat,
  i : @core.Nat,
  j : @core.Nat,
) -> @exact.Rational {
  match @core.nth(jet.second, k) {
    None => @exact.rational_zero()
    Some(row) =>
      match @core.nth(row, l) {
        None => @exact.rational_zero()
        Some(matrix) => value2(@matrix.rows(matrix), i, j)
      }
  }
}

///|
/// Retain the positive-definiteness witness and reusable factorization.
/// This concerns the metric value; it does not assert flatness of the metric field.
pub fn positive_metric(
  jet : MetricJet,
) -> Result[@positiveform.PositiveDefinite, @positiveform.FormError] {
  @positiveform.positive_definite(metric(jet))
}

///|
/// Separate classification: metric_jet still accepts indefinite metrics.
pub fn is_positive_definite(jet : MetricJet) -> Bool {
  match positive_metric(jet) {
    Ok(_) => true
    Err(_) => false
  }
}
