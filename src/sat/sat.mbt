///|
#derive(Eq, Debug)
pub(all) struct Literal {
  variable : @core.Nat
  positive : Bool
}

///|
pub extend Literal with Eq::{equal, not_equal}

///|
pub extend Literal with Debug::{to_repr}

///|
pub type Clause = @core.Chain[Literal]

///|
pub type Cnf = @core.Chain[Clause]

///|
pub type Model = @core.Chain[Literal]

///|
pub fn negate(literal : Literal) -> Literal {
  {
    variable: literal.variable,
    positive: match literal.positive {
      true => false
      false => true
    },
  }
}

///|
fn same(a : Literal, b : Literal) -> Bool {
  match (@core.compare(a.variable, b.variable), a.positive, b.positive) {
    (Equal, true, true) | (Equal, false, false) => true
    _ => false
  }
}

///|
/// Satisfied clauses disappear; the false literal disappears from others.
pub fn restrict(cnf : Cnf, literal : Literal) -> Cnf {
  match cnf {
    Nil => Nil
    Cons(clause, rest) =>
      match @core.any(clause, fn(candidate) { same(candidate, literal) }) {
        true => restrict(rest, literal)
        false =>
          Cons(
            @core.filter(clause, fn(candidate) {
              match same(candidate, negate(literal)) {
                true => false
                false => true
              }
            }),
            restrict(rest, literal),
          )
      }
  }
}

///|
fn has_empty(cnf : Cnf) -> Bool {
  @core.any(cnf, fn(clause) {
    match clause {
      Nil => true
      _ => false
    }
  })
}

///|
fn unit(cnf : Cnf) -> Literal? {
  match cnf {
    Nil => None
    Cons(Cons(literal, Nil), _) => Some(literal)
    Cons(_, rest) => unit(rest)
  }
}

///|
fn pure(cnf : Cnf) -> Literal? {
  fn search(literals : Clause) -> Literal? {
    match literals {
      Nil => None
      Cons(literal, rest) => {
        let opposite = @core.any(cnf, fn(clause) {
          @core.any(clause, fn(candidate) { same(candidate, negate(literal)) })
        })
        match opposite {
          false => Some(literal)
          true => search(rest)
        }
      }
    }
  }
  fn clauses(remaining : Cnf) -> Literal? {
    match remaining {
      Nil => None
      Cons(clause, rest) =>
        match search(clause) {
          Some(literal) => Some(literal)
          None => clauses(rest)
        }
    }
  }
  clauses(cnf)
}

///|
/// A finite, independently checkable DPLL refutation.
#derive(Eq, Debug)
pub(all) enum Refutation {
  Conflict
  UnitStep(Literal, Refutation)
  PureStep(Literal, Refutation)
  Split(Literal, Refutation, Refutation)
}

///|
pub extend Refutation with Eq::{equal, not_equal}

///|
pub extend Refutation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Outcome {
  Satisfiable(Model)
  Unsatisfiable(Refutation)
}

///|
pub extend Outcome with Eq::{equal, not_equal}

///|
pub extend Outcome with Debug::{to_repr}

///|
/// DPLL with unit propagation, pure literal elimination and binary branching.
pub fn solve(cnf : Cnf) -> Outcome {
  fn search(cnf : Cnf, model : Model) -> Outcome {
    match cnf {
      Nil => Satisfiable(@core.reverse(model))
      _ =>
        match has_empty(cnf) {
          true => Unsatisfiable(Conflict)
          false =>
            match unit(cnf) {
              Some(literal) =>
                match search(restrict(cnf, literal), Cons(literal, model)) {
                  Satisfiable(model) => Satisfiable(model)
                  Unsatisfiable(proof) =>
                    Unsatisfiable(UnitStep(literal, proof))
                }
              None =>
                match pure(cnf) {
                  Some(literal) =>
                    match search(restrict(cnf, literal), Cons(literal, model)) {
                      Satisfiable(model) => Satisfiable(model)
                      Unsatisfiable(proof) =>
                        Unsatisfiable(PureStep(literal, proof))
                    }
                  None =>
                    match cnf {
                      Cons(Cons(literal, _), _) =>
                        match
                          search(restrict(cnf, literal), Cons(literal, model)) {
                          Satisfiable(model) => Satisfiable(model)
                          Unsatisfiable(left) =>
                            match
                              search(
                                restrict(cnf, negate(literal)),
                                Cons(negate(literal), model),
                              ) {
                              Satisfiable(model) => Satisfiable(model)
                              Unsatisfiable(right) =>
                                Unsatisfiable(Split(literal, left, right))
                            }
                        }
                      _ => Unsatisfiable(Conflict)
                    }
                }
            }
        }
    }
  }
  search(cnf, Nil)
}

///|
/// Check a partial model, rejecting contradictory assignments.
pub fn check_model(cnf : Cnf, model : Model) -> Bool {
  let consistent = @core.all(model, fn(literal) {
    match @core.any(model, fn(other) { same(other, negate(literal)) }) {
      true => false
      false => true
    }
  })
  match consistent {
    false => false
    true =>
      @core.all(cnf, fn(clause) {
        @core.any(clause, fn(literal) {
          @core.any(model, fn(value) { same(value, literal) })
        })
      })
  }
}

///|
/// This checker does no search and does not call solve.
pub fn check_refutation(cnf : Cnf, proof : Refutation) -> Bool {
  match proof {
    Conflict => has_empty(cnf)
    UnitStep(literal, next) => {
      let justified = @core.any(cnf, fn(clause) {
        match clause {
          Cons(only, Nil) => same(only, literal)
          _ => false
        }
      })
      match justified {
        true => check_refutation(restrict(cnf, literal), next)
        false => false
      }
    }
    PureStep(literal, next) => {
      let occurs = @core.any(cnf, fn(clause) {
        @core.any(clause, fn(value) { same(value, literal) })
      })
      let opposite = @core.any(cnf, fn(clause) {
        @core.any(clause, fn(value) { same(value, negate(literal)) })
      })
      match (occurs, opposite) {
        (true, false) => check_refutation(restrict(cnf, literal), next)
        _ => false
      }
    }
    Split(literal, left, right) =>
      match check_refutation(restrict(cnf, literal), left) {
        false => false
        true => check_refutation(restrict(cnf, negate(literal)), right)
      }
  }
}
