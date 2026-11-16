///|
fn collect(
  formula : Formula,
  atoms : @core.Chain[@polynomial.Polynomial],
) -> Result[@core.Chain[@polynomial.Polynomial], BuildError] {
  match formula {
    Truth(_) => Ok(atoms)
    Atom(p, _) =>
      match @core.compare(@polynomial.variables(p), Succ(Zero)) {
        Equal =>
          match @core.any(atoms, fn(q) { p.equal(q) }) {
            true => Ok(atoms)
            false => Ok(Cons(p, atoms))
          }
        _ => Err(NotUnivariate)
      }
    Negation(body) => collect(body, atoms)
    Conjunction(left, right) | Disjunction(left, right) =>
      match collect(left, atoms) {
        Err(error) => Err(error)
        Ok(atoms) => collect(right, atoms)
      }
  }
}

///|
fn prepare_atoms(
  polys : @core.Chain[@polynomial.Polynomial],
  infos : @core.Chain[AtomInfo],
  product : @polynomial.Polynomial,
) -> Result[(@core.Chain[AtomInfo], @polynomial.Polynomial), BuildError] {
  match polys {
    Nil => Ok((@core.reverse(infos), product))
    Cons(p, rest) =>
      match @polynomial.is_zero(p) {
        true =>
          prepare_atoms(
            rest,
            Cons({ polynomial: p, system: None, }, infos),
            product,
          )
        false =>
          match
            (
              @sturm.system(p),
              @polynomial.multiply(product, @polynomial.monic(p)),
            ) {
            (Ok(system), Ok(product)) =>
              prepare_atoms(
                rest,
                Cons({ polynomial: p, system: Some(system), }, infos),
                product,
              )
            _ => Err(ArithmeticFailure)
          }
      }
  }
}

///|
/// Check arity and cache distinct atom Sturm systems and their product.
/// Polynomial preparation is exact but is not a constant-time fuel step.
pub fn prepare(formula : Formula) -> Result[Problem, BuildError] {
  match collect(formula, Nil) {
    Err(error) => Err(error)
    Ok(reversed) =>
      match
        prepare_atoms(
          @core.reverse(reversed),
          Nil,
          @polynomial.constant(Succ(Zero), @exact.rational_one()),
        ) {
        Err(error) => Err(error)
        Ok((atoms, product)) =>
          match @sturm.system(product) {
            Err(_) => Err(ArithmeticFailure)
            Ok(system) => Ok({ formula, atoms, system, })
          }
      }
  }
}

///|
pub fn formula(problem : Problem) -> Formula {
  problem.formula
}

///|
pub fn polynomials(problem : Problem) -> @core.Chain[@polynomial.Polynomial] {
  @core.map(problem.atoms, fn(info) { info.polynomial })
}

///|
/// The defining polynomial for every AlgebraicPoint of this problem.
pub fn root_polynomial(problem : Problem) -> @polynomial.Polynomial {
  @sturm.squarefree(problem.system)
}
