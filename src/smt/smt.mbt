///|
#derive(Eq, Debug)
pub(all) enum Atom {
  Difference(@difference.Constraint)
  Free
}

///|
pub extend Atom with Eq::{equal, not_equal}

///|
pub extend Atom with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Problem {
  atoms : @core.Chain[Atom]
  formula : @sat.Cnf
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn valid_variable(variable : @core.Nat, count : @core.Nat) -> Bool {
  match @core.compare(variable, count) {
    Less => true
    _ => false
  }
}

///|
pub fn problem(atoms : @core.Chain[Atom], formula : @sat.Cnf) -> Problem? {
  let count = @core.length(atoms)
  match
    @core.all(formula, fn(clause) {
      @core.all(clause, fn(literal) { valid_variable(literal.variable, count) })
    }) {
    true => Some({ atoms, formula, })
    false => None
  }
}

///|
pub fn differences(
  atoms : @core.Chain[@difference.Constraint],
  formula : @sat.Cnf,
) -> Problem? {
  problem(@core.map(atoms, fn(atom) { Difference(atom) }), formula)
}

///|
pub fn atoms(problem : Problem) -> @core.Chain[Atom] {
  problem.atoms
}

///|
pub fn cnf(problem : Problem) -> @sat.Cnf {
  problem.formula
}

///|
fn assigned(model : @sat.Model, variable : @core.Nat) -> Bool? {
  match model {
    Nil => None
    Cons(literal, rest) =>
      match @core.compare(literal.variable, variable) {
        Equal => Some(literal.positive)
        _ => assigned(rest, variable)
      }
  }
}

///|
fn complete(problem : Problem, model : @sat.Model) -> @sat.Model? {
  let count = @core.length(problem.atoms)
  match
    @sat.check_model(problem.formula, model) &&
    @core.all(model, fn(literal) { valid_variable(literal.variable, count) }) {
    false => None
    true =>
      Some(
        @core.map(@core.indices(count), fn(variable) {
          let positive = match assigned(model, variable) {
            None => false
            Some(value) => value
          }
          @sat.Literal::{ variable, positive, }
        }),
      )
  }
}

///|
priv struct Bundle {
  constraints : @core.Chain[@difference.Constraint]
  labels : @sat.Model
}

///|
fn selected(problem : Problem, model : @sat.Model) -> Bundle? {
  fn walk(
    rest : @core.Chain[Atom],
    index : @core.Nat,
    constraints_rev : @core.Chain[@difference.Constraint],
    labels_rev : @sat.Model,
  ) -> Bundle? {
    match rest {
      Nil =>
        Some({
          constraints: @core.reverse(constraints_rev),
          labels: @core.reverse(labels_rev),
        })
      Cons(atom, tail) =>
        match assigned(model, index) {
          None => None
          Some(positive) =>
            match atom {
              Free => walk(tail, Succ(index), constraints_rev, labels_rev)
              Difference(constraint) => {
                let constraint = match positive {
                  true => constraint
                  false => @difference.negate(constraint)
                }
                walk(
                  tail,
                  Succ(index),
                  Cons(constraint, constraints_rev),
                  Cons(@sat.Literal::{ variable: index, positive, }, labels_rev),
                )
              }
            }
        }
    }
  }
  walk(problem.atoms, Zero, Nil, Nil)
}

///|
#derive(Eq, Debug)
pub struct Model {
  booleans : @sat.Model
  integers : @difference.Solution
}

///|
pub extend Model with Eq::{equal, not_equal}

///|
pub extend Model with Debug::{to_repr}

///|
pub fn booleans(model : Model) -> @sat.Model {
  model.booleans
}

///|
pub fn integers(model : Model) -> @difference.Solution {
  model.integers
}

///|
pub fn check_model(problem : Problem, model : Model) -> Bool {
  match complete(problem, model.booleans) {
    None => false
    Some(full) =>
      match selected(problem, full) {
        None => false
        Some(bundle) =>
          @difference.check_solution(
            @difference.problem(bundle.constraints),
            model.integers,
          )
      }
  }
}

///|
/// Signed atom labels in directed cycle order. Their conjunction is impossible.
#derive(Eq, Debug)
pub(all) struct Lemma {
  cycle : @sat.Model
}

///|
pub extend Lemma with Eq::{equal, not_equal}

///|
pub extend Lemma with Debug::{to_repr}

///|
pub fn lemma_clause(problem : Problem, lemma : Lemma) -> @sat.Clause? {
  fn interpret(
    rest : @sat.Model,
    reversed : @core.Chain[@difference.Constraint],
  ) -> @core.Chain[@difference.Constraint]? {
    match rest {
      Nil => Some(@core.reverse(reversed))
      Cons(literal, tail) =>
        match @core.nth(problem.atoms, literal.variable) {
          Some(Difference(constraint)) => {
            let constraint = match literal.positive {
              true => constraint
              false => @difference.negate(constraint)
            }
            interpret(tail, Cons(constraint, reversed))
          }
          _ => None
        }
    }
  }
  match interpret(lemma.cycle, Nil) {
    None => None
    Some(constraints) => {
      let cycle = @difference.Cycle::{
        indices: @core.indices(@core.length(constraints)),
      }
      match @difference.check_cycle(@difference.problem(constraints), cycle) {
        false => None
        true => Some(@core.map(lemma.cycle, @sat.negate))
      }
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Refutation {
  lemmas : @core.Chain[Lemma]
  propositional : @cdcl.Proof
}

///|
pub extend Refutation with Eq::{equal, not_equal}

///|
pub extend Refutation with Debug::{to_repr}

///|
/// Validate every integer-theory lemma before checking the final RUP refutation.
pub fn check_refutation(problem : Problem, proof : Refutation) -> Bool {
  fn augment(rest : @core.Chain[Lemma], formula : @sat.Cnf) -> @sat.Cnf? {
    match rest {
      Nil => Some(formula)
      Cons(lemma, tail) =>
        match lemma_clause(problem, lemma) {
          None => None
          Some(clause) =>
            augment(tail, @core.append(formula, Cons(clause, Nil)))
        }
    }
  }
  match augment(proof.lemmas, problem.formula) {
    None => false
    Some(formula) => @cdcl.check_refutation(formula, proof.propositional)
  }
}

///|
pub enum Phase {
  Boolean(@cdcl.Search)
  Theory(@sat.Model)
}

///|
pub struct Search {
  problem : Problem
  formula : @sat.Cnf
  lemmas_rev : @core.Chain[Lemma]
  phase : Phase
  transitions : @core.Nat
}

///|
pub(all) enum Outcome {
  Satisfiable(Model)
  Unsatisfiable(Refutation)
  Paused(Search)
  InvariantViolation
}

///|
pub fn start(problem : Problem) -> Search {
  {
    problem,
    formula: problem.formula,
    lemmas_rev: Nil,
    phase: Boolean(@cdcl.start(problem.formula)),
    transitions: Zero,
  }
}

///|
pub fn transitions(search : Search) -> @core.Nat {
  search.transitions
}

///|
pub fn theory_conflicts(search : Search) -> @core.Nat {
  @core.length(search.lemmas_rev)
}

///|
fn extract_lemma(bundle : Bundle, cycle : @difference.Cycle) -> Lemma? {
  fn collect(
    indices : @core.Chain[@core.Nat],
    reversed : @sat.Model,
  ) -> Lemma? {
    match indices {
      Nil => Some({ cycle: @core.reverse(reversed), })
      Cons(index, tail) =>
        match @core.nth(bundle.labels, index) {
          None => None
          Some(literal) => collect(tail, Cons(literal, reversed))
        }
    }
  }
  collect(cycle.indices, Nil)
}

///|
pub fn step(search : Search) -> Outcome {
  let search = { ..search, transitions: Succ(search.transitions), }
  match search.phase {
    Boolean(solver) =>
      match @cdcl.run(solver, @core.Succ(Zero)) {
        Paused(solver) => Paused({ ..search, phase: Boolean(solver), })
        InvariantViolation => InvariantViolation
        Satisfiable(model) =>
          match @sat.check_model(search.formula, model) {
            false => InvariantViolation
            true =>
              match complete(search.problem, model) {
                None => InvariantViolation
                Some(model) => Paused({ ..search, phase: Theory(model), })
              }
          }
        Unsatisfiable(propositional) => {
          let proof = Refutation::{
            lemmas: @core.reverse(search.lemmas_rev),
            propositional,
          }
          match check_refutation(search.problem, proof) {
            true => Unsatisfiable(proof)
            false => InvariantViolation
          }
        }
      }
    Theory(model) =>
      match selected(search.problem, model) {
        None => InvariantViolation
        Some(bundle) =>
          match @difference.solve(@difference.problem(bundle.constraints)) {
            InvariantViolation => InvariantViolation
            Feasible(integers) => {
              let model = Model::{ booleans: model, integers, }
              match check_model(search.problem, model) {
                true => Satisfiable(model)
                false => InvariantViolation
              }
            }
            Infeasible(cycle) =>
              match extract_lemma(bundle, cycle) {
                None => InvariantViolation
                Some(lemma) =>
                  match lemma_clause(search.problem, lemma) {
                    None => InvariantViolation
                    Some(clause) =>
                      match @sat.check_model(Cons(clause, Nil), model) {
                        true => InvariantViolation
                        false => {
                          let formula = @core.append(
                            search.formula,
                            Cons(clause, Nil),
                          )
                          Paused({
                            ..search,
                            formula,
                            lemmas_rev: Cons(lemma, search.lemmas_rev),
                            phase: Boolean(@cdcl.start(formula)),
                          })
                        }
                      }
                  }
              }
          }
      }
  }
}

///|
/// Fuel is phase transitions: a Boolean solver step or a whole theory check.
pub fn run(search : Search, fuel : @core.Nat) -> Outcome {
  match fuel {
    Zero => Paused(search)
    Succ(rest) =>
      match step(search) {
        Paused(next) => run(next, rest)
        result => result
      }
  }
}
