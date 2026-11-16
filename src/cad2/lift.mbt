///|
fn sample_number(
  problem : Problem,
  sample : @base.Sample,
) -> Result[@real.Number, CadError] {
  match sample {
    RationalPoint(value) =>
      match @real.rational(value) {
        Ok(number) => Ok(number)
        Err(_) => Err(AlgebraicFailure)
      }
    AlgebraicPoint(interval) =>
      match
        @real.number({
          polynomial: @base.root_polynomial(problem.base),
          interval,
        }) {
        Ok(number) => Ok(number)
        Err(_) => Err(AlgebraicFailure)
      }
  }
}

///|
fn max_y(terms : @core.Chain[@poly.Term], found : @core.Nat) -> @core.Nat {
  match terms {
    Nil => found
    Cons(term, rest) =>
      match term.exponents {
        Cons(_, Cons(y, Nil)) =>
          max_y(
            rest,
            match @core.compare(y, found) {
              Greater => y
              _ => found
            },
          )
        _ => max_y(rest, found)
      }
  }
}

///|
fn coefficient_terms(
  terms : @core.Chain[@poly.Term],
  y_degree : @core.Nat,
) -> @core.Chain[@poly.Term] {
  match terms {
    Nil => Nil
    Cons(term, rest) => {
      let tail = coefficient_terms(rest, y_degree)
      match term.exponents {
        Cons(x, Cons(y, Nil)) =>
          if y.equal(y_degree) {
            Cons(
              { coefficient: term.coefficient, exponents: Cons(x, Nil), },
              tail,
            )
          } else {
            tail
          }
        _ => tail
      }
    }
  }
}

///|
/// Substitute the selected real x into QQ[x,y], retaining a polynomial in y
/// over the same checked coefficient Field. Coefficients are reduced modulo
/// its minimal polynomial, so point nullification and degree drops are exact.
pub fn specialize(
  field : @nf.Field,
  p : @poly.Polynomial,
) -> Result[@ordered.Polynomial, CadError] {
  fn build(
    index : @core.Nat,
    remaining : @core.Nat,
  ) -> Result[@core.Chain[@nf.Element], CadError] {
    match
      @poly.polynomial(Succ(Zero), coefficient_terms(@poly.terms(p), index)) {
      Err(_) => Err(InternalInvariant)
      Ok(coefficient) =>
        match @nf.element(field, coefficient) {
          Err(error) => Err(FieldFailure(error))
          Ok(value) =>
            match remaining {
              Zero => Ok(Cons(value, Nil))
              Succ(rest) =>
                match build(Succ(index), rest) {
                  Ok(tail) => Ok(Cons(value, tail))
                  Err(error) => Err(error)
                }
            }
        }
    }
  }
  match @poly.variables(p) {
    Succ(Succ(Zero)) =>
      match build(Zero, max_y(@poly.terms(p), Zero)) {
        Ok(coefficients) =>
          match @ordered.polynomial(field, coefficients) {
            Ok(result) => Ok(result)
            Err(error) => Err(OrderedFailure(error))
          }
        Err(error) => Err(error)
      }
    _ => Err(NotBivariate)
  }
}

///|
fn relation(relation : @base.Relation) -> @relative.Relation {
  match relation {
    LessZero => @relative.LessZero
    AtMostZero => @relative.AtMostZero
    EqualZero => @relative.EqualZero
    NotZero => @relative.NotZero
    AtLeastZero => @relative.AtLeastZero
    GreaterZero => @relative.GreaterZero
  }
}

///|
fn lift_formula(
  field : @nf.Field,
  formula : @base.Formula,
) -> Result[@relative.Formula, CadError] {
  match formula {
    Truth(value) => Ok(@relative.Truth(value))
    Atom(p, op) =>
      match specialize(field, p) {
        Ok(value) => Ok(@relative.Atom(value, relation(op)))
        Err(error) => Err(error)
      }
    Negation(child) =>
      match lift_formula(field, child) {
        Ok(value) => Ok(@relative.Negation(value))
        Err(error) => Err(error)
      }
    Conjunction(left, right) | Disjunction(left, right) =>
      match (lift_formula(field, left), lift_formula(field, right)) {
        (Ok(a), Ok(b)) =>
          match formula {
            Conjunction(_, _) => Ok(@relative.Conjunction(a, b))
            _ => Ok(@relative.Disjunction(a, b))
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
pub fn fibre_problem(
  problem : Problem,
  field : @nf.Field,
) -> Result[@relative.Problem, CadError] {
  match lift_formula(field, problem.formula) {
    Err(error) => Err(error)
    Ok(formula) =>
      match @relative.prepare(field, formula) {
        Ok(result) => Ok(result)
        Err(error) => Err(RelativeFailure(error))
      }
  }
}

///|
#derive(Debug)
enum FieldProgress {
  Ready(@nf.Field, @minimal.Certificate)
  Insufficient(@minimal.StopReason)
}

///|
pub extend FieldProgress with Debug::{to_repr}

///|
fn make_field(
  problem : Problem,
  sample : @base.Sample,
  budget : Budget,
) -> Result[FieldProgress, CadError] {
  match sample_number(problem, sample) {
    Err(error) => Err(error)
    Ok(number) =>
      match
        @minimal.normalize(
          number,
          budget.primes,
          budget.lifting,
          budget.subsets,
          budget.verification,
        ) {
        Err(_) => Err(AlgebraicFailure)
        Ok(Unresolved(reason)) => Ok(Insufficient(reason))
        Ok(Normalized(value, proof)) =>
          match @nf.field_result(value, proof, budget.verification) {
            Ok(field) => Ok(Ready(field, proof))
            Err(error) => Err(FieldFailure(error))
          }
      }
  }
}

///|
fn checked_field(
  problem : Problem,
  sample : @base.Sample,
  proof : @minimal.Certificate,
  verification : @core.Nat,
) -> @nf.Field? {
  match (sample_number(problem, sample), @real.number(proof.result)) {
    (Ok(input), Ok(value)) =>
      match @minimal.check_normalization(input, value, proof, verification) {
        Proven =>
          match @nf.field_result(value, proof, verification) {
            Ok(field) => Some(field)
            Err(_) => None
          }
        _ => None
      }
    _ => None
  }
}
