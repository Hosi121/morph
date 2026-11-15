///|
/// Maximize c*x subject to A*x<=b and every variable in {false,true}.
/// The relaxation also stores explicit upper bounds x<=one.
#derive(Eq, Debug)
pub struct Problem {
  a : @matrix.Matrix[@exact.Rational]
  b : @core.Chain[@exact.Rational]
  c : @core.Chain[@exact.Rational]
  relaxation : @simplex.Problem
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn indicator(
  n : @core.Nat,
  variable : @core.Nat,
  negative : Bool,
) -> @core.Chain[@exact.Rational] {
  @core.map(@core.indices(n), fn(index) {
    match @core.compare(index, variable) {
      Equal =>
        match negative {
          false => @exact.rational_one()
          true => @exact.rational_negate(@exact.rational_one())
        }
      _ => @exact.rational_zero()
    }
  })
}

///|
pub fn problem(
  a : @matrix.Matrix[@exact.Rational],
  b : @core.Chain[@exact.Rational],
  c : @core.Chain[@exact.Rational],
) -> Problem? {
  match @simplex.problem(a, b, c) {
    None => None
    Some(_) => {
      let n = @matrix.width(a)
      let bounds = @core.map(@core.indices(n), fn(i) { indicator(n, i, false) })
      let rows = @core.append(@matrix.rows(a), bounds)
      let b = @core.append(b, @core.replicate(n, @exact.rational_one()))
      match @matrix.matrix(n, rows) {
        None => None
        Some(a) =>
          match @simplex.problem(a, b, c) {
            None => None
            Some(relaxation) => Some({ a, b, c, relaxation, })
          }
      }
    }
  }
}

///|
fn branch(p : Problem, variable : @core.Nat, value : Bool) -> Problem? {
  let n = @matrix.width(p.a)
  match @core.compare(variable, n) {
    Less => {
      let row = indicator(n, variable, value)
      let bound = match value {
        false => @exact.rational_zero()
        true => @exact.rational_negate(@exact.rational_one())
      }
      let b = @core.append(p.b, Cons(bound, Nil))
      match @matrix.matrix(n, @core.append(@matrix.rows(p.a), Cons(row, Nil))) {
        None => None
        Some(a) =>
          match @simplex.problem(a, b, p.c) {
            None => None
            Some(relaxation) => Some({ a, b, c: p.c, relaxation, })
          }
      }
    }
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Proof {
  Excluded(@core.Chain[@exact.Rational])
  Bounded(@simplex.Optimum)
  Split(@core.Nat, Proof, Proof)
}

///|
pub extend Proof with Eq::{equal, not_equal}

///|
pub extend Proof with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Candidate {
  assignment : @core.Chain[Bool]
  value : @exact.Rational
}

///|
pub extend Candidate with Eq::{equal, not_equal}

///|
pub extend Candidate with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Task {
  Solve(Problem, @simplex.State)
  Combine(@core.Nat)
}

///|
pub extend Task with Eq::{equal, not_equal}

///|
pub extend Task with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Search {
  tasks : @core.Chain[Task]
  proofs : @core.Chain[Proof]
  incumbent : Candidate?
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Candidate, Proof)
  Infeasible(Proof)
  Paused(Search)
  InvariantViolation
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(p : Problem) -> Search {
  {
    tasks: Cons(Solve(p, @simplex.start(p.relaxation)), Nil),
    proofs: Nil,
    incumbent: None,
  }
}

///|
priv enum Classification {
  Integral(@core.Chain[Bool])
  Fractional(@core.Nat)
}

///|
fn classify(values : @core.Chain[@exact.Rational]) -> Classification {
  fn inspect(
    values : @core.Chain[@exact.Rational],
    index : @core.Nat,
    reversed : @core.Chain[Bool],
  ) -> Classification {
    match values {
      Nil => Integral(@core.reverse(reversed))
      Cons(x, rest) =>
        match
          (
            @exact.rational_compare(x, @exact.rational_zero()),
            @exact.rational_compare(x, @exact.rational_one()),
          ) {
          (Equal, _) => inspect(rest, Succ(index), Cons(false, reversed))
          (_, Equal) => inspect(rest, Succ(index), Cons(true, reversed))
          _ => Fractional(index)
        }
    }
  }
  inspect(values, Zero, Nil)
}

///|
/// Each fuel unit runs at most one LP pivot/cleanup step plus one decision,
/// or assembles one proof node. Matrix/rational operations within a unit vary.
pub fn run(search : Search, fuel : @core.Nat) -> Progress {
  match search.tasks {
    Nil =>
      match (search.proofs, search.incumbent) {
        (Cons(proof, Nil), Some(candidate)) => Complete(candidate, proof)
        (Cons(proof, Nil), None) => Infeasible(proof)
        _ => InvariantViolation
      }
    Cons(task, rest) =>
      match fuel {
        Zero => Paused(search)
        Succ(fuel) =>
          match task {
            Combine(variable) =>
              match search.proofs {
                Cons(right, Cons(left, proofs)) =>
                  run(
                    {
                      ..search,
                      tasks: rest,
                      proofs: Cons(Split(variable, left, right), proofs),
                    },
                    fuel,
                  )
                _ => InvariantViolation
              }
            Solve(p, state) =>
              match @simplex.run(state, Succ(Zero)) {
                Paused(state) =>
                  run({ ..search, tasks: Cons(Solve(p, state), rest), }, fuel)
                Infeasible(proof) =>
                  run(
                    {
                      ..search,
                      tasks: rest,
                      proofs: Cons(Excluded(proof), search.proofs),
                    },
                    fuel,
                  )
                Unbounded(_) | InvariantViolation => InvariantViolation
                Optimal(bound) => {
                  let pruned = match search.incumbent {
                    None => false
                    Some(best) =>
                      match @exact.rational_compare(bound.value, best.value) {
                        Greater => false
                        _ => true
                      }
                  }
                  match pruned {
                    true =>
                      run(
                        {
                          ..search,
                          tasks: rest,
                          proofs: Cons(Bounded(bound), search.proofs),
                        },
                        fuel,
                      )
                    false =>
                      match classify(bound.primal) {
                        Integral(assignment) =>
                          run(
                            {
                              tasks: rest,
                              proofs: Cons(Bounded(bound), search.proofs),
                              incumbent: Some({
                                assignment,
                                value: bound.value,
                              }),
                            },
                            fuel,
                          )
                        Fractional(variable) =>
                          match
                            (
                              branch(p, variable, false),
                              branch(p, variable, true),
                            ) {
                            (Some(left), Some(right)) => {
                              let tasks : @core.Chain[Task] = Cons(
                                Solve(left, @simplex.start(left.relaxation)),
                                Cons(
                                  Solve(right, @simplex.start(right.relaxation)),
                                  Cons(Combine(variable), rest),
                                ),
                              )
                              run({ ..search, tasks, }, fuel)
                            }
                            _ => InvariantViolation
                          }
                      }
                  }
                }
              }
          }
      }
  }
}

///|
fn verify_tree(p : Problem, proof : Proof, limit : @exact.Rational?) -> Bool {
  match proof {
    Excluded(multipliers) =>
      @simplex.check_infeasible(p.relaxation, multipliers)
    Bounded(certificate) =>
      match limit {
        None => false
        Some(value) =>
          @simplex.check_optimum(p.relaxation, certificate) &&
          (match @exact.rational_compare(certificate.value, value) {
            Greater => false
            _ => true
          })
      }
    Split(variable, left, right) =>
      match (branch(p, variable, false), branch(p, variable, true)) {
        (Some(a), Some(b)) =>
          verify_tree(a, left, limit) && verify_tree(b, right, limit)
        _ => false
      }
  }
}

///|
/// Check a feasible binary candidate and a bound certificate covering every branch.
/// No simplex iterations or integer search occur in verification.
pub fn check_optimal(p : Problem, candidate : Candidate, proof : Proof) -> Bool {
  let values = @core.map(candidate.assignment, fn(bit) {
    match bit {
      false => @exact.rational_zero()
      true => @exact.rational_one()
    }
  })
  match @core.zip(p.c, values) {
    None => false
    Some(pairs) => {
      let objective = @core.fold_left(pairs, @exact.rational_zero(), fn(
        sum,
        pair,
      ) {
        let (cost, value) = pair
        @exact.rational_add(sum, @exact.rational_multiply(cost, value))
      })
      match @exact.rational_compare(objective, candidate.value) {
        Equal =>
          @simplex.feasible(p.relaxation, values) &&
          verify_tree(p, proof, Some(candidate.value))
        _ => false
      }
    }
  }
}

///|
pub fn check_infeasible(p : Problem, proof : Proof) -> Bool {
  verify_tree(p, proof, None)
}
