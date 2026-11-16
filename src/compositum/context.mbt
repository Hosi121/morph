///|
#derive(Eq, Debug)
pub(all) struct Budget {
  attempts : @core.Nat
  work : @core.Nat
  coordinate : @core.Nat
  comparison : @core.Nat
  primes : @core.Chain[@binary.Binary]
  lift : @core.Nat
  subset : @core.Nat
  verification : @core.Nat
  realization : @core.Nat
}

///|
pub extend Budget with Eq::{equal, not_equal}

///|
pub extend Budget with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum CompositumError {
  VarietyFailure(@variety.VarietyError)
  AlgebraFailure(@real.AlgebraError)
  MinimalFailure(@minimal.MinimalError)
  FieldFailure(@nf.FieldError)
  InternalInvariant
}

///|
pub extend CompositumError with Eq::{equal, not_equal}

///|
pub extend CompositumError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StopReason {
  SeparationBudget(@variety.SearchPauseReason)
  CoordinateBudget
  ComparisonBudget
  MinimalBudget(@minimal.StopReason)
  RealizationBudget
}

///|
pub extend StopReason with Eq::{equal, not_equal}

///|
pub extend StopReason with Debug::{to_repr}

///|
#derive(Debug)
pub struct Common {
  field : @nf.Field
  left : @nf.Element
  right : @nf.Element
}

///|
pub extend Common with Debug::{to_repr}

///|
pub fn common_field(value : Common) -> @nf.Field {
  value.field
}

///|
pub fn left_element(value : Common) -> @nf.Element {
  value.left
}

///|
pub fn right_element(value : Common) -> @nf.Element {
  value.right
}

///|
#derive(Eq, Debug)
pub(all) struct SelectionRow {
  left : @variety.CoordinateCertificate
  right : @variety.CoordinateCertificate
  left_comparison : @real.ComparisonCertificate
  right_comparison : @real.ComparisonCertificate
}

///|
pub extend SelectionRow with Eq::{equal, not_equal}

///|
pub extend SelectionRow with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  left : @real.RootCertificate
  right : @real.RootCertificate
  separation : @variety.SeparationCertificate
  selection : @core.Chain[SelectionRow]
  selected : @core.Nat
  minimal : @minimal.Certificate
  left_embedding : @nf.RealCertificate
  right_embedding : @nf.RealCertificate
  left_equality : @real.ComparisonCertificate
  right_equality : @real.ComparisonCertificate
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Composed(Common, Certificate)
  Unresolved(StopReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
fn lift(polynomial : @poly.Polynomial, right : Bool) -> @poly.Polynomial? {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  fn terms(todo : @core.Chain[@poly.Term]) -> @core.Chain[@poly.Term]? {
    match todo {
      Nil => Some(Nil)
      Cons(term, rest) =>
        match (term.exponents, terms(rest)) {
          (Cons(exponent, Nil), Some(tail)) =>
            Some(
              Cons(
                {
                  coefficient: term.coefficient,
                  exponents: if right {
                    Cons(Zero, Cons(exponent, Nil))
                  } else {
                    Cons(exponent, Cons(Zero, Nil))
                  },
                },
                tail,
              ),
            )
          _ => None
        }
    }
  }
  match terms(@poly.terms(polynomial)) {
    Some(values) =>
      match @poly.polynomial(Succ(Succ(Zero)), values) {
        Ok(polynomial) => Some(polynomial)
        Err(_) => None
      }
    None => None
  }
}

///|
/// Exact Cartesian source, in the order m_left(x),m_right(y).
pub fn source_problem(
  left : @real.Number,
  right : @real.Number,
) -> Result[@variety.Problem, CompositumError] {
  match
    (lift(@real.definition(left), false), lift(@real.definition(right), true)) {
    (Some(a), Some(b)) =>
      match @variety.problem(Succ(Succ(Zero)), Cons(a, Cons(b, Nil))) {
        Ok(problem) => Ok(problem)
        Err(error) => Err(VarietyFailure(error))
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn matched(row : SelectionRow) -> Bool {
  row.left_comparison.order.equal(Equal) &&
  row.right_comparison.order.equal(Equal)
}

///|
fn unique_index(rows : @core.Chain[SelectionRow]) -> @core.Nat? {
  fn indices(
    todo : @core.Chain[SelectionRow],
    index : @core.Nat,
  ) -> @core.Chain[@core.Nat] {
    match todo {
      Nil => Nil
      Cons(row, rest) => {
        let tail = indices(rest, Succ(index))
        if matched(row) {
          Cons(index, tail)
        } else {
          tail
        }
      }
    }
  }
  match indices(rows, Zero) {
    Cons(index, Nil) => Some(index)
    _ => None
  }
}
