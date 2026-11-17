///|
#derive(Eq, Debug)
pub(all) enum Solvability {
  Solvable
  NonSolvable
}

///|
pub extend Solvability with Eq::{equal, not_equal}

///|
pub extend Solvability with Debug::{to_repr}

///|
/// An untrusted exact finite-group computation record. Every list is canonical.
/// The series starts with elements and ends at the trivial subgroup or at a
/// nontrivial perfect subgroup; a stable last subgroup is recorded once.
#derive(Eq, Debug)
pub(all) struct Certificate {
  degree : @core.Nat
  generators : @core.Chain[Permutation]
  elements : @core.Chain[Permutation]
  derived_series : @core.Chain[@core.Chain[Permutation]]
  conclusion : Solvability
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// Read the claimed conclusion; call verify_certificate or check_result before
/// treating an externally supplied certificate as evidence.
pub fn is_solvable(proof : Certificate) -> Bool {
  proof.conclusion.equal(Solvable)
}

///|
pub fn series_orders(proof : Certificate) -> @core.Chain[@core.Nat] {
  @core.map(proof.derived_series, @core.length)
}

///|
fn trivial(group : FiniteGroup) -> Bool {
  match group_elements(group) {
    Cons(_, Nil) => true
    _ => false
  }
}

///|
/// The descending derived series of a finite group either becomes trivial
/// or stabilizes at a nontrivial perfect subgroup. No abstract group name or
/// isomorphism classification is asserted by either conclusion.
pub fn analyze(group : FiniteGroup) -> Certificate {
  fn series(
    current : FiniteGroup,
  ) -> (@core.Chain[@core.Chain[Permutation]], Solvability) {
    let elements = group_elements(current)
    if trivial(current) {
      (Cons(elements, Nil), Solvable)
    } else {
      let derived = derived_subgroup(current)
      if same_group(current, derived) {
        (Cons(elements, Nil), NonSolvable)
      } else {
        let (tail, conclusion) = series(derived)
        (Cons(elements, tail), conclusion)
      }
    }
  }
  let (derived_series, conclusion) = series(group)
  {
    degree: group.degree,
    generators: group.generators,
    elements: group_elements(group),
    derived_series,
    conclusion,
  }
}

///|
/// Recompute closure with the claimed element count as a hard closure bound,
/// then recompute every derived subgroup. This is a replay checker, rather
/// than an independent proof assistant or a faster word-witness verifier.
/// Generator order and duplicates in the requested context are immaterial.
pub fn verify_certificate(
  degree : @core.Nat,
  generators : @core.Chain[Permutation],
  proof : Certificate,
) -> Bool {
  if !degree.equal(proof.degree) {
    return false
  }
  match generate(degree, generators, @core.length(proof.elements)) {
    Complete(group) => analyze(group).equal(proof)
    _ => false
  }
}

///|
/// Bind a verified computation record to the actual returned group payload,
/// including its concrete elements, degree and canonical generator context.
pub fn check_result(group : FiniteGroup, proof : Certificate) -> Bool {
  group.degree.equal(proof.degree) &&
  group.generators.equal(proof.generators) &&
  group_elements(group).equal(proof.elements) &&
  verify_certificate(group.degree, group.generators, proof)
}
