///|
fn contains(
  atoms : @core.Chain[@poly.Polynomial],
  p : @poly.Polynomial,
) -> Bool {
  match atoms {
    Nil => false
    Cons(a, rest) => a.equal(p) || contains(rest, p)
  }
}

///|
fn gather(
  formula : @base.Formula,
  atoms : @core.Chain[@poly.Polynomial],
) -> Result[@core.Chain[@poly.Polynomial], CadError] {
  match formula {
    Truth(_) => Ok(atoms)
    Atom(p, _) =>
      match @poly.variables(p) {
        Succ(Succ(Zero)) =>
          if contains(atoms, p) {
            Ok(atoms)
          } else {
            Ok(Cons(p, atoms))
          }
        _ => Err(NotBivariate)
      }
    Negation(child) => gather(child, atoms)
    Conjunction(left, right) | Disjunction(left, right) =>
      match gather(left, atoms) {
        Ok(next) => gather(right, next)
        Err(error) => Err(error)
      }
  }
}

///|
fn tautologies(polynomials : @core.Chain[@poly.Polynomial]) -> @base.Formula {
  match polynomials {
    Nil => @base.Truth(true)
    Cons(p, rest) =>
      @base.Conjunction(
        @base.Disjunction(@base.Atom(p, EqualZero), @base.Atom(p, NotZero)),
        tautologies(rest),
      )
  }
}

///|
/// x is variable zero and y is variable one. This finite implementation uses
/// the full Collins projector, including every reductum and cross-atom PSC.
pub fn prepare(formula : @base.Formula) -> Result[Problem, CadError] {
  match gather(formula, Nil) {
    Err(error) => Err(error)
    Ok(atoms) =>
      match @projection.full_collins(atoms, Succ(Zero)) {
        Err(error) => Err(ProjectionFailure(error))
        Ok(plan) =>
          match @base.prepare(tautologies(@projection.polynomials(plan))) {
            Ok(base) =>
              Ok({
                formula,
                atoms,
                projection: @projection.certificate(plan),
                base,
              })
            Err(_) => Err(BaseFailure)
          }
      }
  }
}

///|
pub fn formula(problem : Problem) -> @base.Formula {
  problem.formula
}

///|
pub fn atoms(problem : Problem) -> @core.Chain[@poly.Polynomial] {
  problem.atoms
}

///|
pub fn projection_certificate(problem : Problem) -> @projection.Certificate {
  problem.projection
}

///|
pub fn base_problem(problem : Problem) -> @base.Problem {
  problem.base
}
