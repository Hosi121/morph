///|
/// Certificate bound to the actual pair, degree and integral relative group.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : Pair
  degree : @core.Nat
  result : @homology.ResultGroup
  chain : @chainhomology.Certificate
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
/// Checks both matrices rebuilt from the actual pair. No search or inversion.
pub fn check_result(
  source : Pair,
  degree : @core.Nat,
  actual : @homology.ResultGroup,
  witness : Certificate,
) -> Bool {
  let bound = pair(source.ambient, source.subcomplex).equal(Some(source)) &&
    witness.source.equal(source) &&
    witness.degree.equal(degree) &&
    witness.result.equal(actual)
  match bound {
    false => false
    true =>
      match (boundary(source, degree), boundary(source, Succ(degree))) {
        (Some(a), Some(b)) =>
          @chainhomology.check_result(
            a,
            b,
            { free_rank: actual.free_rank, torsion: actual.torsion, },
            witness.chain,
          )
        _ => false
      }
  }
}

///|
pub fn result(witness : Certificate) -> @homology.ResultGroup {
  witness.result
}

///|
pub fn cycle_basis(
  witness : Certificate,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  @chainhomology.cycle_basis(witness.chain)
}

///|
/// Integral relative homology using the common two-Smith matrix-pair engine.
/// Unit factors are omitted; empty pairs and A=K have zero groups.
pub fn compute(
  source : Pair,
  degree : @core.Nat,
  fuel : @core.Nat,
) -> Computation {
  match (boundary(source, degree), boundary(source, Succ(degree))) {
    (Some(a), Some(b)) =>
      match @chainhomology.compute(a, b, fuel) {
        BudgetExhausted => BudgetExhausted
        InvalidWitness => InvalidWitness
        Computed(chain) => {
          let witness = Certificate::{
            source,
            degree,
            chain,
            result: {
              free_rank: chain.result.free_rank,
              torsion: chain.result.torsion,
            },
          }
          match check_result(source, degree, witness.result, witness) {
            true => Computed(witness)
            false => InvalidWitness
          }
        }
      }
    _ => InvalidWitness
  }
}
