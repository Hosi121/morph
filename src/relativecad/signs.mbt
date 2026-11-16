///|
fn midpoint(interval : @sturm.Interval) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(interval.lower, interval.upper))
}

///|
fn scalar_at(
  p : @ordered.Polynomial,
  value : @exact.Rational,
) -> Result[@core.Ordering, CadError] {
  match @ordered.evaluate(p, value) {
    Err(error) => Err(OrderedFailure(error))
    Ok(element) =>
      match @ordered.scalar_sign(element) {
        Ok(sign) => Ok(sign.sign)
        Err(error) => Err(OrderedFailure(error))
      }
  }
}

///|
fn atom_sign(
  atom : AtomInfo,
  sample : Sample,
) -> Result[@core.Ordering, CadError] {
  match atom.system {
    None => Ok(Equal)
    Some(system) =>
      match sample {
        RationalPoint(value) => scalar_at(atom.polynomial, value)
        AlgebraicPoint(interval) =>
          match @ordered.count_between(system, interval) {
            Err(error) => Err(OrderedFailure(error))
            Ok(proof) =>
              match proof.count {
                Zero => scalar_at(atom.polynomial, midpoint(interval))
                Succ(Zero) => Ok(Equal)
                _ => Err(InternalInvariant)
              }
          }
      }
  }
}

///|
fn relation_holds(relation : Relation, sign : @core.Ordering) -> Bool {
  match relation {
    LessZero => sign is Less
    AtMostZero => sign is Less || sign is Equal
    EqualZero => sign is Equal
    NotZero => !(sign is Equal)
    AtLeastZero => sign is Equal || sign is Greater
    GreaterZero => sign is Greater
  }
}

///|
fn sign_of(
  polynomial : @ordered.Polynomial,
  atoms : @core.Chain[AtomInfo],
  signs : @core.Chain[@core.Ordering],
) -> @core.Ordering? {
  match (atoms, signs) {
    (Cons(atom, rest), Cons(sign, tail)) =>
      if @ordered.equal(atom.polynomial, polynomial) {
        Some(sign)
      } else {
        sign_of(polynomial, rest, tail)
      }
    _ => None
  }
}

///|
fn truth(
  formula : Formula,
  atoms : @core.Chain[AtomInfo],
  signs : @core.Chain[@core.Ordering],
) -> Bool? {
  match formula {
    Truth(value) => Some(value)
    Atom(polynomial, relation) =>
      match sign_of(polynomial, atoms, signs) {
        Some(sign) => Some(relation_holds(relation, sign))
        None => None
      }
    Negation(child) =>
      match truth(child, atoms, signs) {
        Some(value) => Some(!value)
        None => None
      }
    Conjunction(left, right) =>
      match (truth(left, atoms, signs), truth(right, atoms, signs)) {
        (Some(a), Some(b)) => Some(a && b)
        _ => None
      }
    Disjunction(left, right) =>
      match (truth(left, atoms, signs), truth(right, atoms, signs)) {
        (Some(a), Some(b)) => Some(a || b)
        _ => None
      }
  }
}

///|
fn classify(problem : Problem, sample : Sample) -> Result[Cell, CadError] {
  match map_result(problem.atoms, fn(atom) { atom_sign(atom, sample) }) {
    Err(error) => Err(error)
    Ok(signs) =>
      match truth(problem.formula, problem.atoms, signs) {
        Some(holds) => Ok({ sample, signs, holds, })
        None => Err(InternalInvariant)
      }
  }
}
