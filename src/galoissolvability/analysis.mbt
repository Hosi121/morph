///|
/// A full exact Galois action and its finite derived-series evidence.
/// Over QQ, solvability of this group is equivalent to solvability by radicals.
/// This certificate does not construct radical expressions.
#derive(Debug)
pub(all) struct Certificate {
  galois : @gal.Certificate
  group : @pg.Certificate
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Analysis {
  priv source : @gal.Group
  priv group : @pg.FiniteGroup
  priv proof : Certificate
}

///|
pub extend Analysis with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  priv source : @gal.Group
  priv generation : @pg.Generation
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Ready(Analysis, Certificate)
  Paused(Search)
}

///|
pub extend Progress with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SolvabilityError {
  InvalidSource
  InvalidCertificate
  InternalInvariant
}

///|
pub extend SolvabilityError with Eq::{equal, not_equal}

///|
pub extend SolvabilityError with Debug::{to_repr}

///|
fn root_degree(group : @gal.Group) -> @core.Nat {
  @core.length(@split.roots(@gal.source(group)))
}

///|
fn generators(group : @gal.Group) -> @core.Chain[@pg.Permutation]? {
  fn go(
    todo : @core.Chain[@gal.Automorphism],
    degree : @core.Nat,
  ) -> @core.Chain[@pg.Permutation]? {
    match todo {
      Nil => Some(Nil)
      Cons(value, rest) =>
        match
          (
            @pg.checked_permutation(degree, @gal.permutation(value)),
            go(rest, degree),
          ) {
          (Some(permutation), Some(tail)) => Some(Cons(permutation, tail))
          _ => None
        }
    }
  }
  go(@gal.automorphisms(group), root_degree(group))
}

///|
/// The field action is checked before treating its root permutations as a group.
pub fn start(source : @gal.Group) -> Result[Search, SolvabilityError] {
  if !@gal.check_result(@gal.source(source), source, @gal.certificate(source)) {
    return Err(InvalidSource)
  }
  match generators(source) {
    None => Err(InvalidSource)
    Some(values) =>
      match @pg.generate(root_degree(source), values, Zero) {
        @pg.InvalidGenerators => Err(InvalidSource)
        generation => Ok({ source, generation, })
      }
  }
}

///|
fn finish(
  source : @gal.Group,
  group : @pg.FiniteGroup,
) -> Result[Progress, SolvabilityError] {
  if !@pg.order(group).equal(@gal.order(source)) {
    return Err(InternalInvariant)
  }
  let derived = @pg.analyze(group)
  if !@pg.check_result(group, derived) {
    return Err(InternalInvariant)
  }
  let proof = Certificate::{ galois: @gal.certificate(source), group: derived, }
  Ok(Ready({ source, group, proof, }, proof))
}

///|
/// Fuel bounds permutation closure transitions. Derived analysis and its checker
/// finish a whole finite group at once; fuel is not a wall-clock bound.
pub fn advance(
  search : Search,
  fuel : @core.Nat,
) -> Result[Progress, SolvabilityError] {
  let generation = match search.generation {
    @pg.Pending(state) => @pg.resume_generation(state, fuel)
    other => other
  }
  match generation {
    @pg.InvalidGenerators => Err(InternalInvariant)
    @pg.Pending(_) => Ok(Paused({ source: search.source, generation, }))
    @pg.Complete(group) => finish(search.source, group)
  }
}

///|
pub fn source(value : Analysis) -> @gal.Group {
  value.source
}

///|
pub fn permutation_group(value : Analysis) -> @pg.FiniteGroup {
  value.group
}

///|
pub fn certificate(value : Analysis) -> Certificate {
  value.proof
}

///|
pub fn is_solvable_by_radicals(value : Analysis) -> Bool {
  @pg.is_solvable(value.proof.group)
}

///|
pub fn derived_orders(value : Analysis) -> @core.Chain[@core.Nat] {
  @pg.series_orders(value.proof.group)
}

///|
/// The exact root action, actual source and generated group are all bound.
pub fn check(source : @gal.Group, proof : Certificate) -> Bool {
  if !@gal.check_result(@gal.source(source), source, proof.galois) {
    return false
  }
  match generators(source) {
    None => false
    Some(values) =>
      @core.length(proof.group.elements).equal(@gal.order(source)) &&
      @pg.verify_certificate(root_degree(source), values, proof.group)
  }
}

///|
pub fn check_result(
  source : @gal.Group,
  value : Analysis,
  proof : Certificate,
) -> Bool {
  check(source, proof) &&
  @gal.check_result(@gal.source(source), source, @gal.certificate(value.source)) &&
  @gal.check_result(@gal.source(source), source, value.proof.galois) &&
  value.proof.group.equal(proof.group) &&
  @pg.check_result(value.group, proof.group)
}
