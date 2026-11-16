///|
fn middle(lower : @exact.Rational, upper : @exact.Rational) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(lower, upper))
}

///|
fn at_rational(
  p : @polynomial.Polynomial,
  x : @exact.Rational,
) -> @core.Ordering? {
  match @polynomial.evaluate(p, Cons(x, Nil)) {
    None => None
    Some(value) => Some(@exact.rational_compare(value, @exact.rational_zero()))
  }
}

///|
/// In a single-root interval of the product, a nonzero atom has either that
/// same root or no root. In the latter case its sign is constant throughout
/// the interval's interior, so rational midpoint evaluation is exact.
fn atom_sign(info : AtomInfo, sample : Sample) -> @core.Ordering? {
  match sample {
    RationalPoint(x) => at_rational(info.polynomial, x)
    AlgebraicPoint(interval) =>
      match info.system {
        None => Some(Equal)
        Some(system) =>
          match @sturm.count_between(system, interval.lower, interval.upper) {
            Some(Succ(Zero)) => Some(Equal)
            Some(Zero) =>
              at_rational(
                info.polynomial,
                middle(interval.lower, interval.upper),
              )
            _ => None
          }
      }
  }
}

///|
fn all_signs(
  atoms : @core.Chain[AtomInfo],
  sample : Sample,
) -> @core.Chain[@core.Ordering]? {
  match atoms {
    Nil => Some(Nil)
    Cons(info, rest) =>
      match (atom_sign(info, sample), all_signs(rest, sample)) {
        (Some(sign), Some(signs)) => Some(Cons(sign, signs))
        _ => None
      }
  }
}

///|
fn relation_holds(relation : Relation, sign : @core.Ordering) -> Bool {
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
fn find_sign(
  p : @polynomial.Polynomial,
  atoms : @core.Chain[AtomInfo],
  signs : @core.Chain[@core.Ordering],
) -> @core.Ordering? {
  match (atoms, signs) {
    (Cons(info, rest), Cons(sign, tail)) =>
      match p.equal(info.polynomial) {
        true => Some(sign)
        false => find_sign(p, rest, tail)
      }
    _ => None
  }
}

///|
fn evaluate_signs(
  formula : Formula,
  atoms : @core.Chain[AtomInfo],
  signs : @core.Chain[@core.Ordering],
) -> Bool? {
  match formula {
    Truth(value) => Some(value)
    Atom(p, relation) =>
      match find_sign(p, atoms, signs) {
        None => None
        Some(sign) => Some(relation_holds(relation, sign))
      }
    Negation(body) =>
      match evaluate_signs(body, atoms, signs) {
        None => None
        Some(value) => Some(!value)
      }
    Conjunction(left, right) =>
      match
        (
          evaluate_signs(left, atoms, signs),
          evaluate_signs(right, atoms, signs),
        ) {
        (Some(a), Some(b)) => Some(a && b)
        _ => None
      }
    Disjunction(left, right) =>
      match
        (
          evaluate_signs(left, atoms, signs),
          evaluate_signs(right, atoms, signs),
        ) {
        (Some(a), Some(b)) => Some(a || b)
        _ => None
      }
  }
}

///|
fn classify(problem : Problem, sample : Sample) -> Cell? {
  match all_signs(problem.atoms, sample) {
    None => None
    Some(signs) =>
      match evaluate_signs(problem.formula, problem.atoms, signs) {
        None => None
        Some(holds) => Some({ sample, signs, holds, })
      }
  }
}

///|
/// Rational points are evaluated directly. Algebraic points must isolate one
/// root of root_polynomial(problem). Returns None for a malformed sample.
pub fn evaluate_sample(problem : Problem, sample : Sample) -> Bool? {
  let valid = match sample {
    RationalPoint(_) => true
    AlgebraicPoint(interval) =>
      match
        @sturm.count_between(problem.system, interval.lower, interval.upper) {
        Some(Succ(Zero)) => true
        _ => false
      }
  }
  match valid {
    false => None
    true =>
      match classify(problem, sample) {
        None => None
        Some(cell) => Some(cell.holds)
      }
  }
}

///|
pub fn check_witness(problem : Problem, sample : Sample) -> Bool {
  match evaluate_sample(problem, sample) {
    Some(true) => true
    _ => false
  }
}
