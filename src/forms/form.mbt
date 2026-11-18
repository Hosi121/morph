///|
/// coefficient dx(indices[0]) wedge ... wedge dx(indices[k-1]). Input indices
/// may be permuted or repeated; form validates all data before antisymmetrizing.
#derive(Eq, Debug)
pub(all) struct Term {
  coefficient : @poly.Polynomial
  indices : @core.Chain[@core.Nat]
}

///|
pub extend Term with Eq::{equal, not_equal}

///|
pub extend Term with Debug::{to_repr}

///|
/// A homogeneous exterior-degree form, with arbitrary polynomial coefficients.
/// Terms are lex-increasing, basis indices strictly increase, coefficients are
/// nonzero canonical polynomials in exactly variables coordinates.
#derive(Eq, Debug)
pub struct Form {
  variables : @core.Nat
  degree : @core.Nat
  terms : @core.Chain[Term]
}

///|
pub extend Form with Eq::{equal, not_equal}

///|
pub extend Form with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum FormError {
  CoefficientDimension
  ComponentDegree
  IndexOutOfRange
  DimensionMismatch
  DegreeMismatch
  ZeroDegree
  NotClosed
  InvalidShear
  DegreeOutOfRange
  InternalInvariant
}

///|
pub extend FormError with Eq::{equal, not_equal}

///|
pub extend FormError with Debug::{to_repr}

///|
pub fn variables(value : Form) -> @core.Nat {
  value.variables
}

///|
pub fn degree(value : Form) -> @core.Nat {
  value.degree
}

///|
pub fn terms(value : Form) -> @core.Chain[Term] {
  value.terms
}

///|
pub fn is_zero(value : Form) -> Bool {
  value.terms is Nil
}

///|
pub fn zero(variables : @core.Nat, degree : @core.Nat) -> Form {
  { variables, degree, terms: Nil, }
}

///|
pub fn scalar(coefficient : @poly.Polynomial) -> Form {
  let variables = @poly.variables(coefficient)
  if @poly.is_zero(coefficient) {
    zero(variables, Zero)
  } else {
    {
      variables,
      degree: Zero,
      terms: Cons({ coefficient, indices: Nil, }, Nil),
    }
  }
}

///|
fn validate_terms(
  variables : @core.Nat,
  degree : @core.Nat,
  input : @core.Chain[Term],
) -> Result[Unit, FormError] {
  match input {
    Nil => Ok(())
    Cons(term, rest) =>
      if !@poly.variables(term.coefficient).equal(variables) {
        Err(CoefficientDimension)
      } else if !@core.length(term.indices).equal(degree) {
        Err(ComponentDegree)
      } else if !@core.all(term.indices, fn(index) {
          @core.compare(index, variables) is Less
        }) {
        Err(IndexOutOfRange)
      } else {
        validate_terms(variables, degree, rest)
      }
  }
}

///|
fn insert_index(
  index : @core.Nat,
  sorted : @core.Chain[@core.Nat],
) -> (@core.Chain[@core.Nat], Bool)? {
  match sorted {
    Nil => Some((Cons(index, Nil), false))
    Cons(head, rest) =>
      match @core.compare(index, head) {
        Equal => None
        Less => Some((Cons(index, sorted), false))
        Greater =>
          match insert_index(index, rest) {
            None => None
            Some((tail, negative)) => Some((Cons(head, tail), !negative))
          }
      }
  }
}

///|
fn canonical_indices(
  indices : @core.Chain[@core.Nat],
) -> (@core.Chain[@core.Nat], Bool)? {
  match indices {
    Nil => Some((Nil, false))
    Cons(head, rest) =>
      match canonical_indices(rest) {
        None => None
        Some((tail, negative)) =>
          match insert_index(head, tail) {
            None => None
            Some((sorted, flipped)) =>
              Some((sorted, if negative { !flipped } else { flipped }))
          }
      }
  }
}

///|
fn compare_indices(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, Cons(_, _)) => Less
    (Cons(_, _), Nil) => Greater
    (Cons(x, xs), Cons(y, ys)) =>
      match @core.compare(x, y) {
        Equal => compare_indices(xs, ys)
        order => order
      }
  }
}

///|
fn insert_term(
  term : Term,
  accumulator : @core.Chain[Term],
) -> Result[@core.Chain[Term], FormError] {
  if @poly.is_zero(term.coefficient) {
    return Ok(accumulator)
  }
  match accumulator {
    Nil => Ok(Cons(term, Nil))
    Cons(head, rest) =>
      match compare_indices(term.indices, head.indices) {
        Less => Ok(Cons(term, accumulator))
        Equal =>
          match @poly.add(term.coefficient, head.coefficient) {
            Err(_) => Err(InternalInvariant)
            Ok(coefficient) =>
              if @poly.is_zero(coefficient) {
                Ok(rest)
              } else {
                Ok(Cons({ coefficient, indices: term.indices, }, rest))
              }
          }
        Greater =>
          match insert_term(term, rest) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons(head, tail))
          }
      }
  }
}

///|
/// All terms must already pass validation, even when they later vanish.
fn normalize(
  input : @core.Chain[Term],
  accumulator : @core.Chain[Term],
) -> Result[@core.Chain[Term], FormError] {
  match input {
    Nil => Ok(accumulator)
    Cons(term, rest) =>
      match canonical_indices(term.indices) {
        None => normalize(rest, accumulator)
        Some((indices, negative)) => {
          let coefficient = if negative {
            @poly.negate(term.coefficient)
          } else {
            term.coefficient
          }
          match insert_term({ coefficient, indices, }, accumulator) {
            Err(error) => Err(error)
            Ok(updated) => normalize(rest, updated)
          }
        }
      }
  }
}

///|
pub fn form(
  variables : @core.Nat,
  degree : @core.Nat,
  input : @core.Chain[Term],
) -> Result[Form, FormError] {
  match validate_terms(variables, degree, input) {
    Err(error) => Err(error)
    Ok(_) =>
      match normalize(input, Nil) {
        Err(error) => Err(error)
        Ok(terms) => Ok({ variables, degree, terms, })
      }
  }
}

///|
pub fn negate(value : Form) -> Form {
  {
    ..value,
    terms: @core.map(value.terms, fn(term) {
      { ..term, coefficient: @poly.negate(term.coefficient), }
    }),
  }
}

///|
pub fn add(a : Form, b : Form) -> Result[Form, FormError] {
  if !a.variables.equal(b.variables) {
    Err(DimensionMismatch)
  } else if !a.degree.equal(b.degree) {
    Err(DegreeMismatch)
  } else {
    form(a.variables, a.degree, @core.append(a.terms, b.terms))
  }
}
