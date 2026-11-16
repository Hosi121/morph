///|
#derive(Eq, Debug)
pub(all) struct ProblemDescription {
  variables : @core.Nat
  inputs : @core.Chain[@poly.Polynomial]
}

///|
pub extend ProblemDescription with Eq::{equal, not_equal}

///|
pub extend ProblemDescription with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Problem {
  description : ProblemDescription
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
pub fn problem(
  variables : @core.Nat,
  inputs : @core.Chain[@poly.Polynomial],
) -> Result[Problem, VarietyError] {
  if variables.equal(Zero) ||
    !@core.all(inputs, fn(p) { @poly.variables(p).equal(variables) }) {
    Err(DimensionMismatch)
  } else {
    Ok({ description: { variables, inputs, }, })
  }
}

///|
pub fn problem_description(value : Problem) -> ProblemDescription {
  value.description
}

///|
/// Untrusted graph augmentation: append t, lift original exponents by a zero,
/// and append t-(x_0+s*x_1+...+s^(n-1)*x_(n-1)).
#derive(Eq, Debug)
pub(all) struct Augmentation {
  source : ProblemDescription
  seed : @binary.Binary
  variables : @core.Nat
  inputs : @core.Chain[@poly.Polynomial]
  relation : @poly.Polynomial
}

///|
pub extend Augmentation with Eq::{equal, not_equal}

///|
pub extend Augmentation with Debug::{to_repr}

///|
pub fn augment(
  source : Problem,
  seed : @binary.Binary,
) -> Result[Augmentation, VarietyError] {
  let original = source.description
  let variables : @core.Nat = Succ(original.variables)
  fn lift_inputs(
    values : @core.Chain[@poly.Polynomial],
  ) -> @core.Chain[@poly.Polynomial]? {
    match values {
      Nil => Some(Nil)
      Cons(head, rest) =>
        match
          (
            @poly.polynomial(
              variables,
              @core.map(@poly.terms(head), fn(term) {
                {
                  coefficient: term.coefficient,
                  exponents: @core.append(term.exponents, Cons(Zero, Nil)),
                }
              }),
            ),
            lift_inputs(rest),
          ) {
          (Ok(p), Some(tail)) => Some(Cons(p, tail))
          _ => None
        }
    }
  }
  fn linear_terms(
    count : @core.Nat,
    index : @core.Nat,
    power : @binary.Binary,
  ) -> @core.Chain[@poly.Term] {
    match count {
      Zero => Nil
      Succ(rest) => {
        let exponents : @core.Chain[@core.Nat] = @core.map(
          @core.indices(variables),
          fn(j) { if j.equal(index) { Succ(Zero) } else { Zero } },
        )
        Cons(
          {
            coefficient: @exact.whole(@exact.negate(@exact.positive(power))),
            exponents,
          },
          linear_terms(rest, Succ(index), @binary.multiply(power, seed)),
        )
      }
    }
  }
  let parameter_term : @poly.Term = {
    coefficient: @exact.rational_one(),
    exponents: @core.append(
      @core.replicate(original.variables, Zero),
      Cons(Succ(Zero), Nil),
    ),
  }
  match
    (
      lift_inputs(original.inputs),
      @poly.polynomial(
        variables,
        Cons(
          parameter_term,
          linear_terms(original.variables, Zero, @binary.one()),
        ),
      ),
    ) {
    (Some(inputs), Ok(relation)) =>
      Ok({
        source: original,
        seed,
        variables,
        inputs: @core.append(inputs, Cons(relation, Nil)),
        relation,
      })
    _ => Err(InternalInvariant)
  }
}

///|
/// Bind source, seed, exponent embedding, the exact graph relation and its
/// ordered augmented input list to the separately supplied Problem.
pub fn check_augmentation(source : Problem, proof : Augmentation) -> Bool {
  match augment(source, proof.seed) {
    Ok(expected) => expected.equal(proof)
    Err(_) => false
  }
}

///|
#derive(Eq, Debug)
pub(all) struct SeparationCertificate {
  augmentation : Augmentation
  groebner : @f4.Certificate
  solutions : SolutionCertificate
  projection : @core.Nat
}

///|
pub extend SeparationCertificate with Eq::{equal, not_equal}

///|
pub extend SeparationCertificate with Debug::{to_repr}

///|
/// Verifies the original Problem, graph augmentation, F4 witness against those
/// exact augmented inputs, full shape/root coverage, and projection dimension.
pub fn check_separation(
  source : Problem,
  proof : SeparationCertificate,
) -> Bool {
  if !check_augmentation(source, proof.augmentation) ||
    !proof.projection.equal(source.description.variables) ||
    !proof.solutions.shape.variables.equal(proof.augmentation.variables) ||
    !proof.solutions.shape.basis.equal(proof.groebner.polynomials) {
    false
  } else {
    match
      @f4.check(
        proof.augmentation.variables,
        proof.augmentation.inputs,
        proof.groebner,
      ) {
      Ok(true) =>
        check_solutions(proof.solutions) &&
        @core.all(proof.augmentation.inputs, fn(p) {
          match
            substitute_mod(
              p,
              proof.solutions.shape.coordinates,
              proof.solutions.shape.eliminant,
            ) {
            Ok(remainder) => @poly.is_zero(remainder)
            Err(_) => false
          }
        })
      _ => false
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct SeparationUnitCertificate {
  augmentation : Augmentation
  groebner : @f4.Certificate
  unit : UnitCertificate
  projection : @core.Nat
}

///|
pub extend SeparationUnitCertificate with Eq::{equal, not_equal}

///|
pub extend SeparationUnitCertificate with Debug::{to_repr}

///|
pub fn check_separation_unit(
  source : Problem,
  proof : SeparationUnitCertificate,
) -> Bool {
  if !check_augmentation(source, proof.augmentation) ||
    !proof.projection.equal(source.description.variables) ||
    !proof.unit.variables.equal(proof.augmentation.variables) ||
    !proof.unit.basis.equal(proof.groebner.polynomials) {
    false
  } else {
    match
      @f4.check(
        proof.augmentation.variables,
        proof.augmentation.inputs,
        proof.groebner,
      ) {
      Ok(true) => check_unit(proof.unit)
      _ => false
    }
  }
}

///|
#derive(Eq, Debug)
pub struct SeparatedSet {
  source : Problem
  augmentation : Augmentation
  groebner : @f4.Certificate
  full : SolutionSet
}

///|
pub extend SeparatedSet with Eq::{equal, not_equal}

///|
pub extend SeparatedSet with Debug::{to_repr}

///|
pub fn separation_certificate(value : SeparatedSet) -> SeparationCertificate {
  {
    augmentation: value.augmentation,
    groebner: value.groebner,
    solutions: solution_certificate(value.full),
    projection: value.source.description.variables,
  }
}

///|
pub fn separation_from_certificate(
  source : Problem,
  proof : SeparationCertificate,
) -> Result[SeparatedSet, VarietyError] {
  if !check_separation(source, proof) {
    Err(InvalidCertificate)
  } else {
    match solutions_from_certificate(proof.solutions) {
      Ok(full) =>
        Ok({
          source,
          augmentation: proof.augmentation,
          groebner: proof.groebner,
          full,
        })
      Err(_) => Err(InternalInvariant)
    }
  }
}

///|
/// Representation binding includes the separately requested source Problem.
pub fn check_separation_result(
  source : Problem,
  value : SeparatedSet,
  proof : SeparationCertificate,
) -> Bool {
  value.source.equal(source) &&
  separation_certificate(value).equal(proof) &&
  check_separation(source, proof)
}

///|
#derive(Eq, Debug)
pub(all) struct AttemptFailure {
  seed : @binary.Binary
  reason : UnsupportedReason
}

///|
pub extend AttemptFailure with Eq::{equal, not_equal}

///|
pub extend AttemptFailure with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum SearchPhase {
  Choosing
  Computing(Augmentation, @f4.State)
  IsolatingCandidate(Augmentation, @f4.Certificate, Isolation)
}

///|
pub extend SearchPhase with Eq::{equal, not_equal}

///|
pub extend SearchPhase with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct SeparationSearch {
  source : Problem
  next : @binary.Binary
  attempts : @core.Nat
  failures : @core.Chain[AttemptFailure]
  phase : SearchPhase
}

///|
pub extend SeparationSearch with Eq::{equal, not_equal}

///|
pub extend SeparationSearch with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SearchPauseReason {
  AttemptLimit
  ComputationFuel
}

///|
pub extend SearchPauseReason with Eq::{equal, not_equal}

///|
pub extend SearchPauseReason with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SeparationProgress {
  Separated(SeparatedSet)
  SeparationPaused(SeparationSearch, SearchPauseReason)
  SeparationNoSolutions(SeparationUnitCertificate)
}

///|
pub extend SeparationProgress with Eq::{equal, not_equal}

///|
pub extend SeparationProgress with Debug::{to_repr}

///|
pub fn separation_start(source : Problem) -> SeparationSearch {
  separation_start_at(source, @binary.zero())
}

///|
/// Choose the first nonnegative integer separating form explicitly. Subsequent
/// attempts still advance by one. This is a search preference, not a promise
/// that the requested form separates the points; all certificates are checked.
pub fn separation_start_at(
  source : Problem,
  seed : @binary.Binary,
) -> SeparationSearch {
  { source, next: seed, attempts: Zero, failures: Nil, phase: Choosing, }
}

///|
pub fn attempted(value : SeparationSearch) -> @core.Nat {
  value.attempts
}

///|
pub fn next_seed(value : SeparationSearch) -> @binary.Binary {
  value.next
}

///|
/// Diagnostic history, not a certificate of global unsupportedness.
pub fn failed_attempts(value : SeparationSearch) -> @core.Chain[AttemptFailure] {
  @core.reverse(value.failures)
}

///|
/// attempt_fuel counts newly started seeds in this call. work_fuel counts F4
/// steps (including finalization) and Sturm interval nodes across all candidates.
/// Both paused phases resume their completed work. No global success guarantee
/// is made for arbitrary nonradical or positive-dimensional input ideals.
pub fn separation_advance(
  state : SeparationSearch,
  attempt_fuel : @core.Nat,
  work_fuel : @core.Nat,
) -> Result[SeparationProgress, VarietyError] {
  match state.phase {
    Choosing =>
      match attempt_fuel {
        Zero => Ok(SeparationPaused(state, AttemptLimit))
        Succ(rest) =>
          match augment(state.source, state.next) {
            Err(error) => Err(error)
            Ok(augmentation) =>
              match @f4.start(augmentation.variables, augmentation.inputs) {
                Err(error) => Err(F4Failure(error))
                Ok(job) =>
                  separation_advance(
                    {
                      ..state,
                      next: @binary.successor(state.next),
                      attempts: Succ(state.attempts),
                      phase: Computing(augmentation, job),
                    },
                    rest,
                    work_fuel,
                  )
              }
          }
      }
    Computing(augmentation, job) =>
      match work_fuel {
        Zero => Ok(SeparationPaused(state, ComputationFuel))
        Succ(rest) =>
          match @f4.step(job) {
            Err(error) => Err(F4Failure(error))
            Ok(Paused(next)) =>
              separation_advance(
                { ..state, phase: Computing(augmentation, next), },
                attempt_fuel,
                rest,
              )
            Ok(Complete(basis)) =>
              match start_basis(basis) {
                Err(error) => Err(error)
                Ok(NoSolutions(unit)) => {
                  let proof : SeparationUnitCertificate = {
                    augmentation,
                    groebner: @f4.certificate(basis),
                    unit,
                    projection: state.source.description.variables,
                  }
                  if check_separation_unit(state.source, proof) {
                    Ok(SeparationNoSolutions(proof))
                  } else {
                    Err(InternalInvariant)
                  }
                }
                Ok(UnsupportedSystem(reason)) =>
                  separation_advance(
                    {
                      ..state,
                      failures: Cons(
                        { seed: augmentation.seed, reason, },
                        state.failures,
                      ),
                      phase: Choosing,
                    },
                    attempt_fuel,
                    rest,
                  )
                Ok(Isolating(isolation)) =>
                  separation_advance(
                    {
                      ..state,
                      phase: IsolatingCandidate(
                        augmentation,
                        @f4.certificate(basis),
                        isolation,
                      ),
                    },
                    attempt_fuel,
                    rest,
                  )
              }
          }
      }
    IsolatingCandidate(augmentation, groebner, isolation) =>
      match work_fuel {
        Zero => Ok(SeparationPaused(state, ComputationFuel))
        Succ(rest) =>
          match advance(isolation, Succ(Zero)) {
            Paused(next) =>
              separation_advance(
                {
                  ..state,
                  phase: IsolatingCandidate(augmentation, groebner, next),
                },
                attempt_fuel,
                rest,
              )
            Complete(full) => {
              let value : SeparatedSet = {
                source: state.source,
                augmentation,
                groebner,
                full,
              }
              if check_separation_result(
                  state.source,
                  value,
                  separation_certificate(value),
                ) {
                Ok(Separated(value))
              } else {
                Err(InternalInvariant)
              }
            }
          }
      }
  }
}
