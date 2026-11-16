///|
pub fn start(source : @poly.Polynomial) -> Result[Search, CubicError] {
  if !eligible(source) {
    return Err(Ineligible)
  }
  match @sturm.system(@poly.monic(source)) {
    Ok(system) => Ok({ source, phase: Isolation(@sturm.isolate(system)), })
    Err(error) => Err(SturmFailure(error))
  }
}

///|
pub fn compose(
  source : @poly.Polynomial,
  budget : @comp.Budget,
) -> Result[Progress, CubicError] {
  match start(source) {
    Ok(search) => advance(search, budget)
    Err(error) => Err(error)
  }
}

///|
/// Isolate the unique real cube root, then use one exact real compositum with
/// positive square root of three. Isolation progress is resumable; the single
/// unfinished compositum is retried using the next operation-local budget.
pub fn advance(
  search : Search,
  budget : @comp.Budget,
) -> Result[Progress, CubicError] {
  let (scale, radicand) = match source_data(search.source) {
    Some(data) => data
    None => return Err(Ineligible)
  }
  let alpha = match search.phase {
    Merging(alpha) => alpha
    Isolation(isolation) =>
      match @sturm.advance(isolation, budget.coordinate) {
        @sturm.Paused(pending) =>
          return Ok(
            Paused({ ..search, phase: Isolation(pending), }, IsolationBudget),
          )
        @sturm.Isolated(Cons(interval, Nil)) =>
          match
            @real.number({ polynomial: @poly.monic(search.source), interval, }) {
            Ok(alpha) => alpha
            Err(error) => return Err(AlgebraFailure(error))
          }
        @sturm.Isolated(_) => return Err(InternalInvariant)
      }
  }
  let pending = Search::{ ..search, phase: Merging(alpha), }
  let beta = match sqrt_three() {
    Ok(beta) => beta
    Err(error) => return Err(error)
  }
  let (common, composition) = match @comp.compose(alpha, beta, budget) {
    Ok(@comp.Composed(common, proof)) => (common, proof)
    Ok(@comp.Unresolved(reason)) =>
      return Ok(Paused(pending, MergeBudget(reason)))
    Err(error) => return Err(MergeFailure(error))
  }
  let (field, values) = match formula_roots(common) {
    Ok(result) => result
    Err(error) => return Err(error)
  }
  if !actual_roots(search.source, values) {
    return Err(InternalInvariant)
  }
  let proof = Certificate::{
    source: search.source,
    scale,
    radicand,
    cube_root: @real.root_certificate(alpha),
    common,
    composition,
    field,
    roots: values,
  }
  Ok(Ready({ field, values, proof, }, proof))
}
