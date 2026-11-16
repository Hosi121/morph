///|
pub fn relation_holds(relation : @realcad.Relation, sign : @core.Ordering) -> Bool {
  match (relation, sign) {
    (LessZero, Less)
    | (AtMostZero, Less)
    | (AtMostZero, Equal)
    | (EqualZero, Equal)
    | (NotZero, Less)
    | (NotZero, Greater)
    | (AtLeastZero, Equal)
    | (AtLeastZero, Greater)
    | (GreaterZero, Greater) => true
    _ => false
  }
}

///|
fn collect_atoms(
  formula : @realcad.Formula,
  reversed : @core.Chain[@polynomial.Polynomial],
) -> @core.Chain[@polynomial.Polynomial] {
  match formula {
    Truth(_) => reversed
    Atom(polynomial, _) =>
      if @core.any(reversed, fn(other) { polynomial.equal(other) }) {
        reversed
      } else {
        Cons(polynomial, reversed)
      }
    Negation(body) => collect_atoms(body, reversed)
    Conjunction(left, right) | Disjunction(left, right) =>
      collect_atoms(right, collect_atoms(left, reversed))
  }
}

///|
/// Distinct polynomials in stable left-to-right first-occurrence order.
pub fn qf_atoms(formula : @realcad.Formula) -> @core.Chain[@polynomial.Polynomial] {
  @core.reverse(collect_atoms(formula, Nil))
}

///|
fn find_sign(
  polynomial : @polynomial.Polynomial,
  atoms : @core.Chain[@polynomial.Polynomial],
  signs : @core.Chain[@core.Ordering],
) -> @core.Ordering? {
  match (atoms, signs) {
    (Cons(atom, rest), Cons(sign, tail)) =>
      if polynomial.equal(atom) { Some(sign) } else { find_sign(polynomial, rest, tail) }
    _ => None
  }
}

///|
fn evaluate_tree(
  formula : @realcad.Formula,
  atoms : @core.Chain[@polynomial.Polynomial],
  signs : @core.Chain[@core.Ordering],
) -> Bool? {
  match formula {
    Truth(value) => Some(value)
    Atom(polynomial, relation) =>
      match find_sign(polynomial, atoms, signs) {
        None => None
        Some(sign) => Some(relation_holds(relation, sign))
      }
    Negation(body) =>
      match evaluate_tree(body, atoms, signs) {
        None => None
        Some(value) => Some(!value)
      }
    Conjunction(left, right) =>
      match (evaluate_tree(left, atoms, signs), evaluate_tree(right, atoms, signs)) {
        (Some(a), Some(b)) => Some(a && b)
        _ => None
      }
    Disjunction(left, right) =>
      match (evaluate_tree(left, atoms, signs), evaluate_tree(right, atoms, signs)) {
        (Some(a), Some(b)) => Some(a || b)
        _ => None
      }
  }
}

///|
/// Rejects different atom/sign lengths, duplicate atoms, and missing formula
/// atoms. Extra distinct supplied atoms are allowed and keep their given order.
/// Both Boolean branches are checked even if one determines the truth value.
pub fn evaluate_signs(
  formula : @realcad.Formula,
  atoms : @core.Chain[@polynomial.Polynomial],
  signs : @core.Chain[@core.Ordering],
) -> Bool? {
  if @core.length(atoms).equal(@core.length(signs)) && distinct_atoms(atoms) {
    evaluate_tree(formula, atoms, signs)
  } else {
    None
  }
}

///|
fn distinct_atoms(atoms : @core.Chain[@polynomial.Polynomial]) -> Bool {
  match atoms {
    Nil => true
    Cons(atom, rest) =>
      !@core.any(rest, fn(other) { atom.equal(other) }) && distinct_atoms(rest)
  }
}
