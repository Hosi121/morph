///|
/// Untrusted Smith witness and claimed invariants of these literal relators.
#derive(Eq, Debug)
pub(all) struct Certificate {
  generators : @core.Nat
  relators : @core.Chain[@core.Chain[Letter]]
  relations : @matrix.Matrix[@exact.Integer]
  left : @matrix.Matrix[@exact.Integer]
  diagonal : @matrix.Matrix[@exact.Integer]
  right : @matrix.Matrix[@exact.Integer]
  free : @core.Nat
  torsion : @core.Chain[@binary.Binary]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// The checked finitely generated abelian quotient of a finite presentation.
/// It carries no decision about the original group's order or solvability.
#derive(Eq, Debug)
pub struct Abelianization {
  priv source : Presentation
  priv proof : Certificate
  priv form : @smith.Decomposition
  priv group : @smith.Cokernel
}

///|
pub extend Abelianization with Eq::{equal, not_equal}

///|
pub extend Abelianization with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct State {
  priv source : Presentation
  priv machine : @smith.Machine
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Done(Abelianization, Certificate)
  Paused(State)
  Fault(State)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
fn checked_form(
  source : Presentation,
  proof : Certificate,
) -> @smith.Decomposition? {
  if !source.generators.equal(proof.generators) ||
    !source.relators.equal(proof.relators) {
    return None
  }
  // Reconstruct even the source's private cached matrix from its literal words.
  let rebuilt = match checked_presentation(source.generators, source.relators) {
    Some(rebuilt) => rebuilt
    None => return None
  }
  if !rebuilt.relations.equal(source.relations) ||
    !rebuilt.relations.equal(proof.relations) {
    return None
  }
  match
    @smith.check(rebuilt.relations, proof.left, proof.diagonal, proof.right) {
    Some(form) => {
      let group = @smith.cokernel(form)
      if @smith.free_rank(group).equal(proof.free) &&
        @smith.torsion_factors(group).equal(proof.torsion) {
        Some(form)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// Search-free source-bound verification delegates matrix correctness to
/// smith.check: dimensions, unimodularity, U A V = D and Smith divisibility.
pub fn check(source : Presentation, proof : Certificate) -> Bool {
  checked_form(source, proof) is Some(_)
}

///|
pub fn from_certificate(
  source : Presentation,
  proof : Certificate,
) -> Abelianization? {
  match checked_form(source, proof) {
    Some(form) => Some({ source, proof, form, group: @smith.cokernel(form), })
    None => None
  }
}

///|
pub fn source(result : Abelianization) -> Presentation {
  result.source
}

///|
pub fn certificate(result : Abelianization) -> Certificate {
  result.proof
}

///|
pub fn decomposition(result : Abelianization) -> @smith.Decomposition {
  result.form
}

///|
pub fn cokernel(result : Abelianization) -> @smith.Cokernel {
  result.group
}

///|
pub fn free_rank(result : Abelianization) -> @core.Nat {
  @smith.free_rank(result.group)
}

///|
pub fn torsion_factors(result : Abelianization) -> @core.Chain[@binary.Binary] {
  @smith.torsion_factors(result.group)
}

///|
pub fn finite_order(result : Abelianization) -> @binary.Binary? {
  @smith.finite_order(result.group)
}

///|
/// Check the actual source, stored witness, decomposition and cached cokernel.
pub fn check_result(
  source : Presentation,
  result : Abelianization,
  proof : Certificate,
) -> Bool {
  if !source.equal(result.source) || !proof.equal(result.proof) {
    return false
  }
  match checked_form(source, proof) {
    Some(form) =>
      form.equal(result.form) && @smith.cokernel(form).equal(result.group)
    None => false
  }
}

///|
pub fn start(source : Presentation) -> State {
  { source, machine: @smith.start(relation_matrix(source)), }
}

///|
/// Fuel has exactly smith.run's step semantics; exhaustion retains all work.
/// No matrix reduction algorithm is implemented in this package.
pub fn run(state : State, fuel : @core.Nat) -> Status {
  match @smith.run(state.machine, fuel) {
    Paused(machine) => Paused({ ..state, machine, })
    Fault(machine) => Fault({ ..state, machine, })
    Done(form) => {
      let group = @smith.cokernel(form)
      let proof : Certificate = {
        generators: state.source.generators,
        relators: state.source.relators,
        relations: @smith.original(form),
        left: @smith.left(form),
        diagonal: @smith.diagonal(form),
        right: @smith.right(form),
        free: @smith.free_rank(group),
        torsion: @smith.torsion_factors(group),
      }
      match from_certificate(state.source, proof) {
        Some(result) => Done(result, proof)
        None => Fault(state)
      }
    }
  }
}
