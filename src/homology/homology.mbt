///|
/// H_k = Z^free_rank plus the cyclic groups of the torsion invariant factors.
/// Unit factors are omitted; torsion factors are positive and divide successors.
#derive(Eq, Debug)
pub(all) struct ResultGroup {
  free_rank : @core.Nat
  torsion : @core.Chain[@binary.Binary]
}

///|
pub extend ResultGroup with Eq::{equal, not_equal}

///|
pub extend ResultGroup with Debug::{to_repr}

///|
/// Search-free witness for one actual complex, degree, and result. The first
/// Smith form U*d_k*V=D determines a full integer cycle basis. Coordinates
/// V^-1*d_(k+1) have zero leading rank(d_k) rows. The second Smith form is of
/// the remaining rows, presenting boundaries inside the cycle lattice.
/// Fields are public so independently produced witnesses can be checked.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : Complex
  degree : @core.Nat
  result : ResultGroup
  boundary_form : @smith.Decomposition
  right_inverse : @matrix.Matrix[@exact.Integer]
  coordinates : @matrix.Matrix[@exact.Integer]
  image_form : @smith.Decomposition
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Computation {
  Computed(Certificate)
  BudgetExhausted
  InvalidWitness
}

///|
pub extend Computation with Eq::{equal, not_equal}

///|
pub extend Computation with Debug::{to_repr}

///|
fn engine(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
  witness : Certificate,
) -> @chainhomology.Certificate {
  {
    boundary: a,
    next_boundary: b,
    result: {
      free_rank: witness.result.free_rank,
      torsion: witness.result.torsion,
    },
    boundary_form: witness.boundary_form,
    right_inverse: witness.right_inverse,
    coordinates: witness.coordinates,
    image_form: witness.image_form,
  }
}

///|
/// Checks the actual source, degree and result, then the common matrix-pair witness.
/// Runs no Smith search or inversion.
pub fn check_result(
  complex : Complex,
  degree : @core.Nat,
  actual : ResultGroup,
  witness : Certificate,
) -> Bool {
  let bound = witness.source.equal(complex) &&
    witness.degree.equal(degree) &&
    witness.result.equal(actual) &&
    validate(complex.faces).equal(Some(complex))
  match bound {
    false => false
    true =>
      match (boundary(complex, degree), boundary(complex, Succ(degree))) {
        (Some(a), Some(b)) =>
          @chainhomology.check_result(
            a,
            b,
            { free_rank: actual.free_rank, torsion: actual.torsion, },
            engine(a, b, witness),
          )
        _ => false
      }
  }
}

///|
pub fn result(witness : Certificate) -> ResultGroup {
  witness.result
}

///|
/// Full integer cycle basis in lexicographic simplex coordinates.
pub fn cycle_basis(
  witness : Certificate,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  @core.drop(
    @smith.rank(witness.boundary_form),
    @matrix.rows(@matrix.transpose(@smith.right(witness.boundary_form))),
  )
}

///|
/// Delegates the two Smith searches to the shared matrix-pair engine.
pub fn compute(
  complex : Complex,
  degree : @core.Nat,
  fuel : @core.Nat,
) -> Computation {
  match (boundary(complex, degree), boundary(complex, Succ(degree))) {
    (Some(a), Some(b)) =>
      match @chainhomology.compute(a, b, fuel) {
        BudgetExhausted => BudgetExhausted
        InvalidWitness => InvalidWitness
        Computed(c) => {
          let witness = Certificate::{
            source: complex,
            degree,
            result: {
              free_rank: c.result.free_rank,
              torsion: c.result.torsion,
            },
            boundary_form: c.boundary_form,
            right_inverse: c.right_inverse,
            coordinates: c.coordinates,
            image_form: c.image_form,
          }
          match check_result(complex, degree, witness.result, witness) {
            true => Computed(witness)
            false => InvalidWitness
          }
        }
      }
    _ => InvalidWitness
  }
}
