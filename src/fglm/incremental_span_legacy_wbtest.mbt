// Legacy exact solver retained only as an independent test oracle.

///|
/// Solve A*c=v with known independent columns, then check the exact dependence
/// witness by reconstructing v. Affine solutions violate the state invariant.
fn span(
  vectors : @core.Chain[@core.Chain[@exact.Rational]],
  vector : @core.Chain[@exact.Rational],
) -> Result[Span, FglmError] {
  let dimension = @core.length(vector)
  if !@core.all(vectors, fn(v) {
      @core.compare(@core.length(v), dimension).equal(Equal)
    }) {
    return Err(InternalInvariant)
  }
  let rows = @core.map(@core.indices(dimension), fn(i) {
    @core.map(vectors, fn(v) {
      match @core.nth(v, i) {
        Some(x) => x
        None => @exact.rational_zero()
      }
    })
  })
  match @matrix.matrix(@core.length(vectors), rows) {
    None => Err(InternalInvariant)
    Some(matrix) =>
      match @linear.solve(matrix, vector) {
        Some(@linear.Inconsistent) => Ok(Independent)
        Some(@linear.Unique(coefficients)) =>
          match combine_vectors(vectors, coefficients, dimension) {
            Some(actual) =>
              if actual.equal(vector) {
                Ok(Dependent(coefficients))
              } else {
                Err(InternalInvariant)
              }
            None => Err(InternalInvariant)
          }
        _ => Err(InternalInvariant)
      }
  }
}
