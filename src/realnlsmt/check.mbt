///|
fn assigned(model : @sat.Model, variable : @core.Nat) -> Bool? {
  match model {
    Nil => None
    Cons(literal, rest) =>
      if literal.variable.equal(variable) {
        Some(literal.positive)
      } else {
        assigned(rest, variable)
      }
  }
}

///|
fn unique_assignments(model : @sat.Model) -> Bool {
  match model {
    Nil => true
    Cons(literal, rest) =>
      !@core.any(rest, fn(other) { literal.variable.equal(other.variable) }) &&
      unique_assignments(rest)
  }
}

///|
fn boolean_variables(formula : @sat.Cnf) -> @core.Chain[@core.Nat] {
  @core.reverse(
    @core.fold_left(formula, Nil, fn(seen, clause) {
      @core.fold_left(clause, seen, fn(seen, literal) {
        if @core.any(seen, fn(variable) { variable.equal(literal.variable) }) {
          seen
        } else {
          Cons(literal.variable, seen)
        }
      })
    }),
  )
}

///|
/// A partial CNF model already has a true literal in each clause. Canonical
/// completion preserves those literals, rejects invalid/duplicate variables,
/// and rechecks the completed CNF before it can constrain arithmetic atoms.
fn complete_boolean(formula : @sat.Cnf, model : @sat.Model) -> @sat.Model? {
  let variables = boolean_variables(formula)
  if !unique_assignments(model) ||
    !@sat.check_model(formula, model) ||
    !@core.all(model, fn(literal) {
      @core.any(variables, fn(variable) { variable.equal(literal.variable) })
    }) {
    None
  } else {
    let full = @core.map(variables, fn(variable) {
      @sat.Literal::{
        variable,
        positive: match assigned(model, variable) {
          Some(value) => value
          None => false
        },
      }
    })
    if @sat.check_model(formula, full) {
      Some(full)
    } else {
      None
    }
  }
}

///|
fn source_assignment(problem : Problem, model : @sat.Model) -> @sat.Model? {
  match @circuit.source_model(problem.encoding, model) {
    None => None
    Some(source) => {
      fn walk(indices : @core.Chain[@core.Nat]) -> @sat.Model? {
        match indices {
          Nil => Some(Nil)
          Cons(variable, rest) =>
            match (assigned(source, variable), walk(rest)) {
              (Some(positive), Some(tail)) =>
                Some(Cons(@sat.Literal::{ variable, positive, }, tail))
              _ => None
            }
        }
      }
      walk(@core.indices(@core.length(problem.atoms)))
    }
  }
}

///|
fn signed_formula(problem : Problem, assignment : @sat.Model) -> @qf.Formula? {
  if !unique_assignments(assignment) {
    None
  } else {
    fn walk(rest : @sat.Model) -> @qf.Formula? {
      match rest {
        Nil => Some(Truth(true))
        Cons(literal, tail) =>
          match (@core.nth(problem.atoms, literal.variable), walk(tail)) {
            (Some(atom), Some(rest)) =>
              Some(
                Conjunction(
                  Atom(
                    atom.polynomial,
                    if literal.positive {
                      atom.relation
                    } else {
                      @logic.complement(atom.relation)
                    },
                  ),
                  rest,
                ),
              )
            _ => None
          }
      }
    }
    walk(assignment)
  }
}

///|
pub fn booleans(model : Model) -> @sat.Model {
  model.booleans
}

///|
pub fn point(model : Model) -> @cad.Point {
  model.point
}

///|
pub fn check_model(problem : Problem, model : Model) -> Bool {
  if !model.context.equal(problem.context) ||
    !@core.length(@cad.coordinates(model.point)).equal(arity(problem)) {
    false
  } else {
    match complete_boolean(cnf(problem), model.booleans) {
      None => false
      Some(full) =>
        match source_assignment(problem, full) {
          None => false
          Some(assignment) =>
            match signed_formula(problem, assignment) {
              None => false
              Some(signed) =>
                @circuit.check_source_model(problem.encoding, full) &&
                @cad.evaluate_formula(model.point, signed) is Ok(true) &&
                @cad.evaluate_formula(model.point, formula(problem)) is Ok(true)
            }
        }
    }
  }
}

///|
/// Reconstruct signed atoms from this exact source context and source IDs,
/// validate complete CAD coverage, then require its existential sentence false.
/// This does not accept a detached valid decomposition of another conjunction.
pub fn lemma_clause(problem : Problem, lemma : Lemma) -> @sat.Clause? {
  if !lemma.context.equal(problem.context) {
    None
  } else {
    match signed_formula(problem, lemma.assignment) {
      None => None
      Some(signed) =>
        match @cad.prepare(arity(problem), signed) {
          Err(_) => None
          Ok(theory) =>
            match @cad.check(theory, lemma.decomposition) {
              None => None
              Some(decomposition) =>
                match
                  @cad.sentence(
                    decomposition,
                    @core.replicate(arity(problem), @logic.Quantifier::Exists),
                  ) {
                  Ok(false) => Some(@core.map(lemma.assignment, @sat.negate))
                  _ => None
                }
            }
        }
    }
  }
}

///|
pub fn check_refutation(problem : Problem, proof : Refutation) -> Bool {
  if !proof.context.equal(problem.context) {
    false
  } else {
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
    match augment(proof.lemmas, cnf(problem)) {
      None => false
      Some(augmented) => @cdcl.check_refutation(augmented, proof.propositional)
    }
  }
}
