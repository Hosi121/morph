///|
/// Raw Gram-Schmidt evidence, with triangular coefficient rows (row i has i
/// entries). Public fields are untrusted until the independent relations pass.
#derive(Eq, Debug)
pub(all) struct GramSchmidt {
  orthogonal : @core.Chain[@core.Chain[@exact.Rational]]
  coefficients : @core.Chain[@core.Chain[@exact.Rational]]
  norms : @core.Chain[@exact.Rational]
}

///|
pub extend GramSchmidt with Eq::{equal, not_equal}

///|
pub extend GramSchmidt with Debug::{to_repr}

///|
pub fn gram_schmidt(input : @matrix.Matrix[@exact.Integer]) -> GramSchmidt? {
  fn orthogonalize(
    original : @core.Chain[@exact.Rational],
    current : @core.Chain[@exact.Rational],
    previous : @core.Chain[@core.Chain[@exact.Rational]],
    norms : @core.Chain[@exact.Rational],
  ) -> (@core.Chain[@exact.Rational], @core.Chain[@exact.Rational])? {
    match (previous, norms) {
      (Nil, Nil) => Some((current, Nil))
      (Cons(star, rest), Cons(norm, tail)) =>
        match dot(original, star) {
          None => None
          Some(product) =>
            match @exact.rational_divide(product, norm) {
              None => None
              Some(coefficient) =>
                match subtract_projection(current, star, coefficient) {
                  None => None
                  Some(current) =>
                    match orthogonalize(original, current, rest, tail) {
                      Some((result, coefficients)) =>
                        Some((result, Cons(coefficient, coefficients)))
                      None => None
                    }
                }
            }
        }
      _ => None
    }
  }
  fn build(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    result : GramSchmidt,
  ) -> GramSchmidt? {
    match rows {
      Nil => Some(result)
      Cons(row, rest) => {
        let original = @core.map(row, @exact.whole)
        match
          orthogonalize(original, original, result.orthogonal, result.norms) {
          None => None
          Some((star, coefficients)) =>
            match dot(star, star) {
              None => None
              Some(norm) =>
                match @exact.rational_compare(norm, @exact.rational_zero()) {
                  Greater =>
                    build(rest, {
                      orthogonal: @core.append(
                        result.orthogonal,
                        Cons(star, Nil),
                      ),
                      coefficients: @core.append(
                        result.coefficients,
                        Cons(coefficients, Nil),
                      ),
                      norms: @core.append(result.norms, Cons(norm, Nil)),
                    })
                  _ => None
                }
            }
        }
      }
    }
  }
  build(@matrix.rows(input), { orthogonal: Nil, coefficients: Nil, norms: Nil, })
}

///|
/// Validate the raw witness by dimensions, pairwise orthogonality, positive
/// squared norms and independent reconstruction of each original basis row.
pub fn check_gram(
  input : @matrix.Matrix[@exact.Integer],
  gram : GramSchmidt,
) -> Bool {
  let height = @matrix.height(input)
  let width = @matrix.width(input)
  let dimensions = @core.compare(@core.length(gram.orthogonal), height) is Equal &&
    @core.compare(@core.length(gram.coefficients), height) is Equal &&
    @core.compare(@core.length(gram.norms), height) is Equal &&
    @core.all(gram.orthogonal, fn(row) {
      @core.compare(@core.length(row), width) is Equal
    })
  fn coefficients_ok(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    index : @core.Nat,
  ) -> Bool {
    match rows {
      Nil => true
      Cons(row, rest) =>
        @core.compare(@core.length(row), index) is Equal &&
        coefficients_ok(rest, Succ(index))
    }
  }
  fn orthogonal_rows(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    norms : @core.Chain[@exact.Rational],
  ) -> Bool {
    match (rows, norms) {
      (Nil, Nil) => true
      (Cons(row, rest), Cons(norm, tail)) => {
        let diagonal = match dot(row, row) {
          Some(value) =>
            value.equal(norm) &&
            @exact.rational_compare(norm, @exact.rational_zero()) is Greater
          None => false
        }
        diagonal &&
        @core.all(rest, fn(other) {
          match dot(row, other) {
            Some(value) => value.equal(@exact.rational_zero())
            None => false
          }
        }) &&
        orthogonal_rows(rest, tail)
      }
      _ => false
    }
  }
  fn reconstruct(
    current : @core.Chain[@exact.Rational],
    coefficients : @core.Chain[@exact.Rational],
    stars : @core.Chain[@core.Chain[@exact.Rational]],
  ) -> @core.Chain[@exact.Rational]? {
    match coefficients {
      Nil => Some(current)
      Cons(coefficient, rest) =>
        match stars {
          Nil => None
          Cons(star, tail) =>
            match add_projection(current, star, coefficient) {
              Some(current) => reconstruct(current, rest, tail)
              None => None
            }
        }
    }
  }
  fn originals(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    stars : @core.Chain[@core.Chain[@exact.Rational]],
    coefficients : @core.Chain[@core.Chain[@exact.Rational]],
  ) -> Bool {
    match (rows, stars, coefficients) {
      (Nil, Nil, Nil) => true
      (Cons(row, rest), Cons(star, tail), Cons(mu, mus)) =>
        match reconstruct(star, mu, gram.orthogonal) {
          Some(value) =>
            value.equal(@core.map(row, @exact.whole)) &&
            originals(rest, tail, mus)
          None => false
        }
      _ => false
    }
  }
  dimensions &&
  coefficients_ok(gram.coefficients, Zero) &&
  orthogonal_rows(gram.orthogonal, gram.norms) &&
  originals(@matrix.rows(input), gram.orthogonal, gram.coefficients)
}

///|
fn coefficient(
  gram : GramSchmidt,
  row : @core.Nat,
  column : @core.Nat,
) -> @exact.Rational? {
  match @core.nth(gram.coefficients, row) {
    Some(row) => @core.nth(row, column)
    None => None
  }
}

///|
fn lovasz(
  gram : GramSchmidt,
  current : @core.Nat,
  previous : @core.Nat,
) -> Bool {
  match
    (
      @core.nth(gram.norms, current),
      @core.nth(gram.norms, previous),
      coefficient(gram, current, previous),
    ) {
    (Some(norm), Some(before), Some(mu)) => {
      let bound = @exact.rational_multiply(
        @exact.rational_subtract(delta(), @exact.rational_multiply(mu, mu)),
        before,
      )
      match @exact.rational_compare(norm, bound) {
        Less => false
        _ => true
      }
    }
    _ => false
  }
}
