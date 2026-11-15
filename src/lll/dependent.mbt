///|
/// A Smith-backed independent row basis of exactly the same integer row lattice.
#derive(Eq, Debug)
pub struct IndependentBasis {
  smith : @smith.Decomposition
  basis : @matrix.Matrix[@exact.Integer]
}

///|
pub extend IndependentBasis with Eq::{equal, not_equal}

///|
pub extend IndependentBasis with Debug::{to_repr}

///|
pub fn independent_basis(
  prepared : IndependentBasis,
) -> @matrix.Matrix[@exact.Integer] {
  prepared.basis
}

///|
pub fn smith_certificate(prepared : IndependentBasis) -> @smith.Decomposition {
  prepared.smith
}

///|
fn zero_rows(rows : @core.Chain[@core.Chain[@exact.Integer]]) -> Bool {
  @core.all(rows, fn(row) {
    @core.all(row, fn(value) { @binary.is_zero(@exact.magnitude(value)) })
  })
}

///|
/// U*B has independent leading rows and zero trailing rows because U*B*V=D.
/// Removing these zero rows preserves the integer lattice, including content.
pub fn from_smith(form : @smith.Decomposition) -> IndependentBasis? {
  let input = @smith.original(form)
  let rank = @smith.rank(form)
  match @matrix.multiply(@smith.left(form), input, integers()) {
    None => None
    Some(transformed) =>
      match zero_rows(@core.drop(rank, @matrix.rows(transformed))) {
        false => None
        true =>
          match
            @matrix.matrix(
              @matrix.width(input),
              @core.take(rank, @matrix.rows(transformed)),
            ) {
            None => None
            Some(basis) =>
              match gram_schmidt(basis) {
                Some(gram) =>
                  match check_gram(basis, gram) {
                    true => Some({ smith: form, basis, })
                    false => None
                  }
                None => None
              }
          }
      }
  }
}

///|
/// A reduction of a possibly dependent generating set. The square unimodular
/// transform sends the original rows to reduced basis rows followed by zeros.
#derive(Eq, Debug)
pub struct LatticeReduction {
  input : @matrix.Matrix[@exact.Integer]
  transform : @matrix.Matrix[@exact.Integer]
  basis : @matrix.Matrix[@exact.Integer]
  gram : GramSchmidt
}

///|
pub extend LatticeReduction with Eq::{equal, not_equal}

///|
pub extend LatticeReduction with Debug::{to_repr}

///|
pub fn lattice_original(
  result : LatticeReduction,
) -> @matrix.Matrix[@exact.Integer] {
  result.input
}

///|
pub fn lattice_transform(
  result : LatticeReduction,
) -> @matrix.Matrix[@exact.Integer] {
  result.transform
}

///|
pub fn lattice_basis(
  result : LatticeReduction,
) -> @matrix.Matrix[@exact.Integer] {
  result.basis
}

///|
pub fn lattice_gram(result : LatticeReduction) -> GramSchmidt {
  result.gram
}

///|
/// Search-free checker for dependent presentations too: U*B consists of the
/// supplied reduced independent rows and zero rows, with det(U)=plus/minus one.
pub fn check_lattice(
  input : @matrix.Matrix[@exact.Integer],
  transform : @matrix.Matrix[@exact.Integer],
  reduced : @matrix.Matrix[@exact.Integer],
) -> LatticeReduction? {
  let height = @matrix.height(input)
  let rank = @matrix.height(reduced)
  let dimensions = @core.compare(@matrix.height(transform), height) is Equal &&
    @core.compare(@matrix.width(transform), height) is Equal &&
    @core.compare(@matrix.width(reduced), @matrix.width(input)) is Equal &&
    !(@core.compare(rank, height) is Greater)
  match dimensions && unimodular(transform) {
    false => None
    true =>
      match
        (gram_schmidt(reduced), @matrix.multiply(transform, input, integers())) {
        (Some(gram), Some(transformed)) => {
          let rows = @matrix.rows(transformed)
          let equal_basis = @core.take(rank, rows).equal(@matrix.rows(reduced))
          match
            equal_basis &&
            zero_rows(@core.drop(rank, rows)) &&
            check_gram(reduced, gram) &&
            reduced_conditions(gram) {
            true => Some({ input, transform, basis: reduced, gram, })
            false => None
          }
        }
        _ => None
      }
  }
}

///|
/// Embed the reduced rank-by-rank transform into a full unimodular block matrix
/// before composing it with Smith's U. The final checker rechecks the result.
pub fn combine(
  prepared : IndependentBasis,
  reduction : Reduction,
) -> LatticeReduction? {
  match original(reduction).equal(prepared.basis) {
    false => None
    true => {
      let input = @smith.original(prepared.smith)
      let height = @matrix.height(input)
      let rank = @matrix.height(prepared.basis)
      let missing = @core.subtract(height, rank)
      let zero_tail = @core.replicate(missing, @exact.positive(@binary.zero()))
      let upper = @core.map(@matrix.rows(transform(reduction)), fn(row) {
        @core.append(row, zero_tail)
      })
      let lower = @core.drop(
        rank,
        @matrix.rows(@matrix.identity(height, integers())),
      )
      match @matrix.matrix(height, @core.append(upper, lower)) {
        None => None
        Some(block) =>
          match
            @matrix.multiply(block, @smith.left(prepared.smith), integers()) {
            Some(transform) => check_lattice(input, transform, basis(reduction))
            None => None
          }
      }
    }
  }
}
