///|
/// A checked lattice-equivalent, size-reduced and Lovasz-reduced row basis.
#derive(Eq, Debug)
pub struct Reduction {
  input : @matrix.Matrix[@exact.Integer]
  transform : @matrix.Matrix[@exact.Integer]
  basis : @matrix.Matrix[@exact.Integer]
  gram : GramSchmidt
}

///|
pub extend Reduction with Eq::{equal, not_equal}

///|
pub extend Reduction with Debug::{to_repr}

///|
pub fn original(reduction : Reduction) -> @matrix.Matrix[@exact.Integer] {
  reduction.input
}

///|
pub fn transform(reduction : Reduction) -> @matrix.Matrix[@exact.Integer] {
  reduction.transform
}

///|
pub fn basis(reduction : Reduction) -> @matrix.Matrix[@exact.Integer] {
  reduction.basis
}

///|
pub fn gram(reduction : Reduction) -> GramSchmidt {
  reduction.gram
}

///|
fn unimodular(input : @matrix.Matrix[@exact.Integer]) -> Bool {
  let rows = @core.map(@matrix.rows(input), fn(row) {
    @core.map(row, @exact.whole)
  })
  match @matrix.matrix(@matrix.width(input), rows) {
    None => false
    Some(rationals) =>
      match @linear.determinant(rationals) {
        Some(value) =>
          @binary.compare(@exact.denominator(value), @binary.one()) is Equal &&
          @binary.compare(
            @exact.magnitude(@exact.numerator(value)),
            @binary.one(),
          )
          is Equal
        None => false
      }
  }
}

///|
fn reduced_conditions(gram : GramSchmidt) -> Bool {
  fn consecutive(
    norms : @core.Chain[@exact.Rational],
    index : @core.Nat,
  ) -> Bool {
    match norms {
      Nil => true
      Cons(_, rest) =>
        lovasz(gram, Succ(index), index) && consecutive(rest, Succ(index))
    }
  }
  let ordered = match gram.norms {
    Nil => true
    Cons(_, rest) => consecutive(rest, Zero)
  }
  @core.all(gram.coefficients, fn(row) { @core.all(row, size_bounded) }) &&
  ordered
}

///|
/// Validate raw Gram-Schmidt evidence, lattice equivalence, unimodularity, all
/// size conditions and Lovasz with exact delta = three quarters.
pub fn check_with_gram(
  input : @matrix.Matrix[@exact.Integer],
  transform : @matrix.Matrix[@exact.Integer],
  reduced : @matrix.Matrix[@exact.Integer],
  gram : GramSchmidt,
) -> Reduction? {
  let height = @matrix.height(input)
  let dimensions = @core.compare(@matrix.height(transform), height) is Equal &&
    @core.compare(@matrix.width(transform), height) is Equal &&
    @core.compare(@matrix.height(reduced), height) is Equal &&
    @core.compare(@matrix.width(reduced), @matrix.width(input)) is Equal
  match
    dimensions &&
    check_gram(reduced, gram) &&
    reduced_conditions(gram) &&
    unimodular(transform) {
    false => None
    true =>
      match @matrix.multiply(transform, input, integers()) {
        Some(value) =>
          match value.equal(reduced) {
            true => Some({ input, transform, basis: reduced, gram, })
            false => None
          }
        None => None
      }
  }
}

///|
/// Recompute evidence, then validate it independently of the reduction trace.
pub fn check(
  input : @matrix.Matrix[@exact.Integer],
  transform : @matrix.Matrix[@exact.Integer],
  reduced : @matrix.Matrix[@exact.Integer],
) -> Reduction? {
  match gram_schmidt(reduced) {
    Some(gram) => check_with_gram(input, transform, reduced, gram)
    None => None
  }
}
