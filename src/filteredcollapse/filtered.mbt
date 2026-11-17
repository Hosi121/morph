///|
/// An integer chain contraction whose removed simplices have equal birth
/// grades. All remaining entries keep their actual grades and original order.
#derive(Eq, Debug)
pub(all) struct Step {
  source : @persistence.Filtration
  target : @persistence.Filtration
  contraction : @collapse.Certificate
}

///|
pub extend Step with Eq::{equal, not_equal}

///|
pub extend Step with Debug::{to_repr}

///|
fn complex(source : @persistence.Filtration) -> @homology.Complex? {
  @homology.validate(
    @core.map(@persistence.entries(source), fn(entry) { entry.simplex }),
  )
}

///|
fn birth(
  entries : @core.Chain[@persistence.Entry],
  simplex : @core.Chain[@core.Nat],
) -> @exact.Rational? {
  match entries {
    Nil => None
    Cons(entry, rest) =>
      match entry.simplex.equal(simplex) {
        true => Some(entry.grade)
        false => birth(rest, simplex)
      }
  }
}

///|
fn same_grade(source : @persistence.Filtration, pair : @collapse.Pair) -> Bool {
  let entries = @persistence.entries(source)
  match (birth(entries, pair.lower), birth(entries, pair.upper)) {
    (Some(a), Some(b)) => a.equal(b)
    _ => false
  }
}

///|
fn remove(
  source : @persistence.Filtration,
  pair : @collapse.Pair,
) -> @persistence.Filtration? {
  @persistence.validate(
    @core.filter(@persistence.entries(source), fn(entry) {
      !entry.simplex.equal(pair.lower) && !entry.simplex.equal(pair.upper)
    }),
  )
}

///|
fn grades(
  source : @persistence.Filtration,
  basis : @core.Chain[@core.Chain[@core.Nat]],
) -> @core.Chain[@exact.Rational]? {
  match basis {
    Nil => Some(Nil)
    Cons(simplex, rest) =>
      match
        (birth(@persistence.entries(source), simplex), grades(source, rest)) {
        (Some(value), Some(tail)) => Some(Cons(value, tail))
        _ => None
      }
  }
}

///|
fn preserves(
  matrix : @matrix.Matrix[@exact.Integer],
  domain : @core.Chain[@exact.Rational],
  codomain : @core.Chain[@exact.Rational],
) -> Bool {
  @matrix.width(matrix).equal(@core.length(domain)) &&
  (match @core.zip(@matrix.rows(matrix), codomain) {
    None => false
    Some(rows) =>
      @core.all(rows, fn(pair) {
        let (row, output_grade) = pair
        match @core.zip(row, domain) {
          None => false
          Some(values) =>
            @core.all(values, fn(pair) {
              let (value, input_grade) = pair
              value.equal(@exact.numerator(@exact.rational_zero())) ||
              !(@exact.rational_compare(output_grade, input_grade) is Greater)
            })
        }
      })
  })
}

///|
fn filtered_maps(
  source : @persistence.Filtration,
  target : @persistence.Filtration,
  source_complex : @homology.Complex,
  target_complex : @homology.Complex,
  degree : @core.Nat,
  maps : @core.Chain[@collapse.DegreeMaps],
) -> Bool {
  match maps {
    Nil => true
    Cons(current, rest) =>
      match
        (
          grades(source, @homology.simplices(source_complex, degree)),
          grades(source, @homology.simplices(source_complex, Succ(degree))),
          grades(target, @homology.simplices(target_complex, degree)),
        ) {
        (Some(s), Some(next), Some(t)) =>
          preserves(current.inclusion, t, s) &&
          preserves(current.projection, s, t) &&
          preserves(current.homotopy, s, next) &&
          filtered_maps(
            source,
            target,
            source_complex,
            target_complex,
            Succ(degree),
            rest,
          )
        _ => false
      }
  }
}

///|
/// Search-free source/result-bound verification. Equal-grade matching is
/// essential: an ordinary unfiltered contraction need not preserve intervals.
/// The exact I/P/H identities are checked by collapse.check over the integers.
/// Every nonzero I/P/H matrix entry is additionally checked to preserve birth
/// grades; arbitrary valid but unfiltered homotopies are not trusted.
/// Reducing coefficients also gives GF(2) filtered chain equivalences.
pub fn check_step(
  source : @persistence.Filtration,
  actual : @persistence.Filtration,
  witness : Step,
) -> Bool {
  witness.source.equal(source) &&
  witness.target.equal(actual) &&
  same_grade(source, witness.contraction.pair) &&
  remove(source, witness.contraction.pair).equal(Some(actual)) &&
  (match (complex(source), complex(actual)) {
    (Some(a), Some(b)) =>
      @collapse.check(a, b, witness.contraction) &&
      filtered_maps(source, actual, a, b, Zero, witness.contraction.maps)
    _ => false
  })
}

///|
pub fn elementary(
  source : @persistence.Filtration,
  pair : @collapse.Pair,
) -> Step? {
  match same_grade(source, pair) {
    false => None
    true =>
      match (complex(source), remove(source, pair)) {
        (Some(a), Some(target)) =>
          match @collapse.elementary(a, pair) {
            None => None
            Some(contraction) => {
              let witness = Step::{ source, target, contraction, }
              match check_step(source, target, witness) {
                true => Some(witness)
                false => None
              }
            }
          }
        _ => None
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @persistence.Filtration
  target : @persistence.Filtration
  steps : @core.Chain[Step]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// Verifies a sequence of filtered chain equivalences, without rerunning the
/// reduction search or persistence. Does not assert optimal simplification.
pub fn check_result(
  source : @persistence.Filtration,
  actual : @persistence.Filtration,
  witness : Certificate,
) -> Bool {
  fn walk(
    current : @persistence.Filtration,
    steps : @core.Chain[Step],
  ) -> Bool {
    match steps {
      Nil => current.equal(actual)
      Cons(step, rest) =>
        check_step(current, step.target, step) && walk(step.target, rest)
    }
  }
  witness.source.equal(source) &&
  witness.target.equal(actual) &&
  walk(source, witness.steps)
}

///|
fn candidates(source : @persistence.Filtration) -> @core.Chain[@collapse.Pair] {
  @core.fold_left(@persistence.entries(source), Nil, fn(onto, entry) {
    @core.fold_left(@homology.faces(entry.simplex), onto, fn(onto, lower) {
      match lower {
        Nil => onto
        _ => {
          let pair : @collapse.Pair = { lower, upper: entry.simplex, }
          match same_grade(source, pair) {
            true => Cons(pair, onto)
            false => onto
          }
        }
      }
    })
  })
}

///|
#derive(Eq, Debug)
pub struct State {
  source : @persistence.Filtration
  current : @persistence.Filtration
  remaining : @core.Chain[@collapse.Pair]
  reversed_steps : @core.Chain[Step]
  attempts : @core.Nat
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Paused(State)
  Stalled(Certificate)
  InvalidWitness
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(source : @persistence.Filtration) -> State {
  {
    source,
    current: source,
    remaining: candidates(source),
    reversed_steps: Nil,
    attempts: Zero,
  }
}

///|
pub fn attempts(state : State) -> @core.Nat {
  state.attempts
}

///|
/// One fuel unit attempts one same-grade codimension-one pair. Candidate
/// construction, list walks and all certificate matrix checks are unmetered.
/// Stalled means no equal-grade elementary pair remains in the current
/// complex; it is neither a minimal-size result nor a general Morse matching.
pub fn run(state : State, fuel : @core.Nat) -> Progress {
  match state.remaining {
    Nil => {
      let witness = Certificate::{
        source: state.source,
        target: state.current,
        steps: @core.reverse(state.reversed_steps),
      }
      match check_result(state.source, state.current, witness) {
        true => Stalled(witness)
        false => InvalidWitness
      }
    }
    Cons(pair, rest) =>
      match fuel {
        Zero => Paused(state)
        Succ(left) =>
          match elementary(state.current, pair) {
            None =>
              run(
                { ..state, remaining: rest, attempts: Succ(state.attempts), },
                left,
              )
            Some(step) =>
              run(
                {
                  ..state,
                  current: step.target,
                  remaining: candidates(step.target),
                  reversed_steps: Cons(step, state.reversed_steps),
                  attempts: Succ(state.attempts),
                },
                left,
              )
          }
      }
  }
}

///|
/// Additional structural verification of the Stalled claim. This scans the
/// finite supplied complex for eligible free pairs, without matrix search.
pub fn check_stalled(
  source : @persistence.Filtration,
  actual : @persistence.Filtration,
  witness : Certificate,
) -> Bool {
  check_result(source, actual, witness) &&
  (match complex(actual) {
    None => false
    Some(reduced_complex) =>
      @core.all(candidates(actual), fn(pair) {
        !@collapse.is_free(reduced_complex, pair)
      })
  })
}
