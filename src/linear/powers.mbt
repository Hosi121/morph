///|
/// Rational coordinate columns in the fixed ambient dimension.
fn vector_matrix(
  d : @core.Nat,
  columns : @core.Chain[@core.Chain[@exact.Rational]],
) -> @matrix.Matrix[@exact.Rational]? {
  match @matrix.matrix(d, columns) {
    Some(matrix) => Some(@matrix.transpose(matrix))
    None => None
  }
}

///|
/// Check monicity, annihilation, and independence of all preceding powers.
/// Rank k of [1,a,...,a^(k-1)] rules out every lower-degree annihilator.
/// All callbacks must use one finite-dimensional unital Q-algebra and a faithful
/// coordinate map of length dimension. This full-RREF checker does not reuse
/// the producer's incremental-span state or dependence search.
pub fn[A, E] check_power_minimal_polynomial(
  value : A,
  unit : A,
  dimension : @core.Nat,
  coordinates : (A) -> @core.Chain[@exact.Rational],
  multiply_element : (A, A) -> Result[A, E],
  evaluate : (A, @poly.Polynomial) -> A?,
  is_zero : (A) -> Bool,
  polynomial : @poly.Polynomial,
) -> Bool {
  if !@poly.variables(polynomial).equal(Succ(Zero)) ||
    !@poly.monic(polynomial).equal(polynomial) {
    return false
  }
  let k = match @poly.univariate_degree(polynomial) {
    Some(Succ(_) as d) => d
    _ => return false
  }
  if @core.compare(k, dimension).equal(Greater) {
    return false
  }
  match evaluate(value, polynomial) {
    Some(result) => if !is_zero(result) { return false }
    None => return false
  }
  fn powers(
    n : @core.Nat,
    power : A,
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match n {
      Zero => Some(Nil)
      Succ(rest) =>
        match multiply_element(power, value) {
          Err(_) => None
          Ok(next) =>
            match powers(rest, next) {
              Some(tail) => Some(Cons(coordinates(power), tail))
              None => None
            }
        }
    }
  }
  match powers(k, unit) {
    Some(columns) =>
      match vector_matrix(dimension, columns) {
        Some(matrix) =>
          match rref(matrix) {
            Some(reduction) => @core.length(reduction.pivots).equal(k)
            None => false
          }
        None => false
      }
    None => false
  }
}

///|
/// Find the first dependence among powers in the finite Q-vector space.
/// Coordinates must be faithful and dimension-bounded in one unital Q-algebra;
/// unit is its nonzero identity and multiplication must preserve that context.
/// Callback/shape failures return None. Call check_power_minimal_polynomial
/// independently before trusting a candidate from untrusted operations.
pub fn[A, E] power_minimal_polynomial(
  value : A,
  unit : A,
  dimension : @core.Nat,
  coordinates : (A) -> @core.Chain[@exact.Rational],
  multiply_element : (A, A) -> Result[A, E],
) -> @poly.Polynomial? {
  fn dependence(
    remaining : @core.Nat,
    k : @core.Nat,
    span : @linearspan.State,
    power : A,
  ) -> @poly.Polynomial? {
    match remaining {
      Zero => None
      Succ(rest) =>
        match @linearspan.insert(span, coordinates(power)) {
          Ok(@linearspan.Dependent(coefficients)) =>
            match @core.zip(@core.indices(k), coefficients) {
              None => None
              Some(entries) =>
                match
                  @poly.polynomial(
                    Succ(Zero),
                    Cons(
                      {
                        coefficient: @exact.rational_one(),
                        exponents: Cons(k, Nil),
                      },
                      @core.map(entries, fn(entry) {
                        let (i, c) = entry
                        @poly.Term::{
                          coefficient: @exact.rational_negate(c),
                          exponents: Cons(i, Nil),
                        }
                      }),
                    ),
                  ) {
                  Ok(polynomial) => Some(polynomial)
                  Err(_) => None
                }
            }
          Ok(@linearspan.Independent(next_span)) =>
            match multiply_element(power, value) {
              Ok(next) => dependence(rest, Succ(k), next_span, next)
              Err(_) => None
            }
          _ => None
        }
    }
  }
  let initial = match
    @linearspan.insert(@linearspan.empty(dimension), coordinates(unit)) {
    Ok(@linearspan.Independent(span)) => span
    _ => return None
  }
  dependence(dimension, Succ(Zero), initial, value)
}
