///|
#derive(Debug)
pub(all) enum SplittingError {
  NotUnivariate
  ZeroPolynomial
  InvalidRoots
  InvalidCertificate
  FactorFailure(@factor.RootError)
  RootFailure(@roots.RootError)
  CompositumFailure(@cohort.CompositumError)
  SubfieldFailure(@sub.SubfieldError)
  CubicFailure(@cube.CubicError)
  InternalInvariant
}

///|
pub extend SplittingError with Debug::{to_repr}

///|
/// Each budget is per stage/call. One exact arithmetic or certificate operation
/// has no fixed wall-clock bound. Primitive trials retain their own candidate.
#derive(Eq, Debug)
pub(all) struct Budget {
  algebra : @comp.Budget
  primitive : @core.Nat
}

///|
pub extend Budget with Eq::{equal, not_equal}

///|
pub extend Budget with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PauseReason {
  FactorizationBudget(@zass.StopReason)
  FactorizationVerification
  RootSearch(@roots.PauseReason)
  RootVerification
  RootMaterialization
  CompositumBudget(@cohort.StopReason)
  CompositumVerification
  PrimitiveTrials
  CubicBudget(@cube.StopReason)
  CubicVerification
}

///|
pub extend PauseReason with Eq::{equal, not_equal}

///|
pub extend PauseReason with Debug::{to_repr}

///|
#derive(Debug)
struct NumberRoot {
  number : @cx.Number
  multiplicity : @core.Nat
}

///|
pub extend NumberRoot with Debug::{to_repr}

///|
#derive(Debug)
enum Phase {
  Factoring
  Cubic(@cube.Search)
  VerifyingCubic(@cube.Common, @cube.Certificate)
  Enumerating(@factor.Search)
  VerifyingRoots(@factor.RootFamily)
  Materializing(
    @core.Chain[@factor.Root],
    @core.Chain[NumberRoot],
    @roots.Materialization?
  )
  Cohorting(@core.Chain[NumberRoot], @cohort.Build)
  VerifyingCohort(@core.Chain[NumberRoot], @cohort.Common, @cohort.Certificate)
  Primitive(@cf.Field, @core.Chain[Root], @sub.Field, @sub.PrimitiveSearch)
}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  priv source : @poly.Polynomial
  priv phase : Phase
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Ready(Splitting, Certificate)
  Paused(Search, PauseReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
fn source_error(source : @poly.Polynomial) -> SplittingError? {
  if !@poly.variables(source).equal(Succ(Zero)) {
    Some(NotUnivariate)
  } else if @poly.is_zero(source) {
    Some(ZeroPolynomial)
  } else {
    None
  }
}

///|
/// Fully automatic route: QQ factors -> complete complex roots -> exact shared
/// ambient K(i) -> smallest generated subfield -> primitive quotient and roots.
pub fn start(source : @poly.Polynomial) -> Result[Search, SplittingError] {
  match source_error(source) {
    Some(error) => Err(error)
    None =>
      if @cube.eligible(source) {
        match @cube.start(source) {
          Ok(state) => Ok({ source, phase: Cubic(state), })
          Err(error) => Err(CubicFailure(error))
        }
      } else {
        Ok({ source, phase: Factoring, })
      }
  }
}

///|
/// Explicit general Cartesian route retained for reproducible comparison.
pub fn start_cartesian(
  source : @poly.Polynomial,
) -> Result[Search, SplittingError] {
  match source_error(source) {
    Some(error) => Err(error)
    None => Ok({ source, phase: Factoring, })
  }
}

///|
/// Reuse a supplied exact full splitting without repeating root enumeration.
pub fn start_from_roots(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  values : @core.Chain[Root],
) -> Result[Search, SplittingError] {
  match source_error(source) {
    Some(error) => return Err(error)
    None => ()
  }
  if !valid_roots(source, ambient, values) {
    return Err(InvalidRoots)
  }
  match @sub.generate(ambient, root_values(values)) {
    Ok(field) =>
      Ok({
        source,
        phase: Primitive(ambient, values, field, @sub.primitive_start(field)),
      })
    Err(error) => Err(SubfieldFailure(error))
  }
}

///|
fn numbers(values : @core.Chain[NumberRoot]) -> @core.Chain[@cx.Number] {
  @core.map(values, fn(root) { root.number })
}

///|
fn bind_roots(
  numbers : @core.Chain[NumberRoot],
  values : @core.Chain[@cf.Element],
) -> @core.Chain[Root]? {
  match (numbers, values) {
    (Nil, Nil) => Some(Nil)
    (Cons(root, rest), Cons(value, tail)) =>
      match bind_roots(rest, tail) {
        Some(bound) =>
          Some(Cons({ value, multiplicity: root.multiplicity, }, bound))
        None => None
      }
    _ => None
  }
}

///|
pub fn advance(
  search : Search,
  budget : Budget,
) -> Result[Progress, SplittingError] {
  let source = search.source
  let work = budget.algebra
  fn next(phase : Phase) -> Result[Progress, SplittingError] {
    advance({ source, phase, }, budget)
  }
  fn pause(
    phase : Phase,
    reason : PauseReason,
  ) -> Result[Progress, SplittingError] {
    Ok(Paused({ source, phase, }, reason))
  }
  match search.phase {
    Cubic(state) =>
      match @cube.advance(state, work) {
        Err(error) => Err(CubicFailure(error))
        Ok(@cube.Paused(state, reason)) =>
          pause(Cubic(state), CubicBudget(reason))
        Ok(@cube.Ready(common, proof)) => next(VerifyingCubic(common, proof))
      }
    VerifyingCubic(common, proof) =>
      match @cube.check_result(source, common, proof, work.verification) {
        @zass.Undecided =>
          pause(VerifyingCubic(common, proof), CubicVerification)
        @zass.Refuted => Err(InternalInvariant)
        @zass.Proven => {
          let values = @core.map(@cube.roots(common), fn(value) {
            Root::{ value, multiplicity: Succ(Zero), }
          })
          match start_from_roots(source, @cube.common_field(common), values) {
            Ok(state) => advance(state, budget)
            Err(error) => Err(error)
          }
        }
      }
    Factoring =>
      match
        @factor.prepare(
          source,
          work.primes,
          work.lift,
          work.subset,
          work.verification,
        ) {
        Err(error) => Err(FactorFailure(error))
        Ok(@factor.FactorizationIncomplete(reason)) =>
          pause(Factoring, FactorizationBudget(reason))
        Ok(@factor.VerificationUndecided(_)) =>
          pause(Factoring, FactorizationVerification)
        Ok(@factor.Prepared(problem)) =>
          next(Enumerating(@factor.start(problem)))
      }
    Enumerating(state) =>
      match @factor.run(state, work.attempts, work.work) {
        Err(error) => Err(FactorFailure(error))
        Ok(@factor.Paused(state, reason)) =>
          pause(Enumerating(state), RootSearch(reason))
        Ok(@factor.Complete(family)) => next(VerifyingRoots(family))
      }
    VerifyingRoots(family) =>
      match
        @factor.check_result(
          source,
          family,
          @factor.certificate(family),
          work.verification,
        ) {
        @zass.Undecided => pause(VerifyingRoots(family), RootVerification)
        @zass.Refuted => Err(InternalInvariant)
        @zass.Proven => next(Materializing(@factor.roots(family), Nil, None))
      }
    Materializing(remaining, reversed, pending) =>
      match remaining {
        Nil => {
          let ordered = @core.reverse(reversed)
          next(Cohorting(ordered, @cohort.start(numbers(ordered))))
        }
        Cons(root, rest) => {
          let state = match pending {
            Some(value) => value
            None => @roots.materialize_start(@factor.root(root))
          }
          match @roots.materialize_advance(state, work.coordinate) {
            Err(error) => Err(RootFailure(error))
            Ok(@roots.MaterializationPaused(state)) =>
              pause(
                Materializing(remaining, reversed, Some(state)),
                RootMaterialization,
              )
            Ok(@roots.Materialized(number, proof)) =>
              if @roots.check_materialization(@factor.root(root), number, proof) {
                next(
                  Materializing(
                    rest,
                    Cons(
                      { number, multiplicity: @factor.multiplicity(root), },
                      reversed,
                    ),
                    None,
                  ),
                )
              } else {
                Err(InternalInvariant)
              }
          }
        }
      }
    Cohorting(ordered, state) =>
      match @cohort.advance(state, work) {
        Err(error) => Err(CompositumFailure(error))
        Ok(@cohort.Paused(state, reason)) =>
          pause(Cohorting(ordered, state), CompositumBudget(reason))
        Ok(@cohort.Ready(common, proof)) =>
          next(VerifyingCohort(ordered, common, proof))
      }
    VerifyingCohort(ordered, common, proof) =>
      match
        @cohort.check_result(numbers(ordered), common, proof, work.verification) {
        @zass.Undecided =>
          pause(VerifyingCohort(ordered, common, proof), CompositumVerification)
        @zass.Refuted => Err(InternalInvariant)
        @zass.Proven =>
          match bind_roots(ordered, @cohort.elements(common)) {
            Some(values) =>
              match
                start_from_roots(source, @cohort.common_field(common), values) {
                Ok(state) => advance(state, budget)
                Err(error) => Err(error)
              }
            None => Err(InternalInvariant)
          }
      }
    Primitive(ambient, values, field, state) =>
      match @sub.primitive_advance(state, budget.primitive) {
        Err(error) => Err(SubfieldFailure(error))
        Ok(@sub.PrimitivePaused(state)) =>
          pause(Primitive(ambient, values, field, state), PrimitiveTrials)
        Ok(@sub.PrimitiveReady(representation, proof)) =>
          match finish(source, ambient, values, field, representation, proof) {
            Ok(value) => Ok(Ready(value, certificate(value)))
            Err(error) => Err(error)
          }
      }
  }
}

///|
pub fn solve(
  source : @poly.Polynomial,
  budget : Budget,
) -> Result[Progress, SplittingError] {
  match start(source) {
    Ok(state) => advance(state, budget)
    Err(error) => Err(error)
  }
}

///|
pub fn solve_from_roots(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  values : @core.Chain[Root],
  budget : Budget,
) -> Result[Progress, SplittingError] {
  match start_from_roots(source, ambient, values) {
    Ok(state) => advance(state, budget)
    Err(error) => Err(error)
  }
}
