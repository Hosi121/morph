///|
#derive(Eq, Debug)
pub(all) enum EliminationError {
  InvalidVariable
  DegreeTooSmall
  DimensionMismatch
  InternalDimension
  ConstantPairIdentity
}

///|
pub extend EliminationError with Eq::{equal, not_equal}

///|
pub extend EliminationError with Debug::{to_repr}

///|
/// A checked source polynomial, selected variable, and retained nominal degree.
#derive(Eq, Debug)
pub struct Input {
  polynomial : @poly.Polynomial
  variable : @core.Nat
  degree : @core.Nat
}

///|
pub extend Input with Eq::{equal, not_equal}

///|
pub extend Input with Debug::{to_repr}

///|
fn split_exponent(
  exponents : @core.Chain[@core.Nat],
  variable : @core.Nat,
) -> (@core.Nat, @core.Chain[@core.Nat])? {
  match (exponents, variable) {
    (Cons(power, rest), Zero) => Some((power, rest))
    (Cons(power, rest), Succ(previous)) =>
      match split_exponent(rest, previous) {
        None => None
        Some((selected, others)) => Some((selected, Cons(power, others)))
      }
    _ => None
  }
}

///|
fn variable_degree(p : @poly.Polynomial, variable : @core.Nat) -> @core.Nat? {
  fn go(terms : @core.Chain[@poly.Term], degree : @core.Nat) -> @core.Nat? {
    match terms {
      Nil => Some(degree)
      Cons(term, rest) =>
        match split_exponent(term.exponents, variable) {
          None => None
          Some((power, _)) =>
            go(
              rest,
              match @core.compare(power, degree) {
                Greater => power
                _ => degree
              },
            )
        }
    }
  }
  match @core.compare(variable, @poly.variables(p)) {
    Less => go(@poly.terms(p), Zero)
    _ => None
  }
}

///|
pub fn fixed_input(
  p : @poly.Polynomial,
  variable : @core.Nat,
  degree : @core.Nat,
) -> Result[Input, EliminationError] {
  match variable_degree(p, variable) {
    None => Err(InvalidVariable)
    Some(actual) =>
      match @core.compare(actual, degree) {
        Greater => Err(DegreeTooSmall)
        _ => Ok({ polynomial: p, variable, degree, })
      }
  }
}

///|
/// The zero polynomial has selected-variable degree zero by this convention.
pub fn input(
  p : @poly.Polynomial,
  variable : @core.Nat,
) -> Result[Input, EliminationError] {
  match variable_degree(p, variable) {
    None => Err(InvalidVariable)
    Some(degree) => Ok({ polynomial: p, variable, degree, })
  }
}

///|
pub fn source(p : Input) -> @poly.Polynomial {
  p.polynomial
}

///|
pub fn variable(p : Input) -> @core.Nat {
  p.variable
}

///|
pub fn input_degree(p : Input) -> @core.Nat {
  p.degree
}

///|
fn split_terms(
  terms : @core.Chain[@poly.Term],
  variable : @core.Nat,
) -> @core.Chain[(@core.Nat, @poly.Term)]? {
  match terms {
    Nil => Some(Nil)
    Cons(term, rest) =>
      match
        (split_exponent(term.exponents, variable), split_terms(rest, variable)) {
        (Some((power, others)), Some(rest)) =>
          Some(Cons((power, { ..term, exponents: others, }), rest))
        _ => None
      }
  }
}

///|
fn as_coefficients(p : Input) -> Fixed[Coefficient]? {
  if !@core.all(@poly.terms(p.polynomial), fn(term) {
      @core.compare(@core.length(term.exponents), @poly.variables(p.polynomial))
      is Equal
    }) {
    return None
  }
  match split_terms(@poly.terms(p.polynomial), p.variable) {
    None => None
    Some(terms) => {
      let ascending = @core.map(@core.indices(Succ(p.degree)), fn(power) {
        {
          terms: @core.fold_left(terms, @core.Nil, fn(found, pair) {
            let (selected_power, term) = pair
            match @core.compare(selected_power, power) {
              Equal => coefficient_insert(term, found)
              _ => found
            }
          }),
        }
      })
      fixed(p.degree, @core.reverse(ascending))
    }
  }
}

///|
fn compatible(f : Input, g : Input) -> Bool {
  @core.compare(f.variable, g.variable) is Equal &&
  @core.compare(@poly.variables(f.polynomial), @poly.variables(g.polynomial))
  is Equal
}

///|
/// Delete the selected variable; preserve the order of every other variable.
/// Degree-zero pairs use the fixed Sylvester empty determinant convention one.
pub fn eliminate(
  f : Input,
  g : Input,
) -> Result[@poly.Polynomial, EliminationError] {
  if !compatible(f, g) {
    Err(DimensionMismatch)
  } else {
    match @poly.variables(f.polynomial) {
      Zero => Err(InvalidVariable)
      Succ(remaining) =>
        match (as_coefficients(f), as_coefficients(g)) {
          (Some(left), Some(right)) =>
            match resultant(left, right, coefficient_ring(remaining)) {
              None => Err(InternalDimension)
              Some(value) => coefficient_polynomial(value, remaining)
            }
          _ => Err(InternalDimension)
        }
    }
  }
}

///|
pub fn resultant_variable(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@poly.Polynomial, EliminationError] {
  match (input(f, selected), input(g, selected)) {
    (Ok(left), Ok(right)) => eliminate(left, right)
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
pub fn discriminate(f : Input) -> Result[@poly.Polynomial, EliminationError] {
  match @poly.variables(f.polynomial) {
    Zero => Err(InvalidVariable)
    Succ(remaining) =>
      match as_coefficients(f) {
        None => Err(InternalDimension)
        Some(coefficients) =>
          match discriminant(coefficients, coefficient_ring(remaining)) {
            None => Err(InternalDimension)
            Some(value) => coefficient_polynomial(value, remaining)
          }
      }
  }
}

///|
pub fn discriminant_variable(
  f : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@poly.Polynomial, EliminationError] {
  match input(f, selected) {
    Err(error) => Err(error)
    Ok(value) => discriminate(value)
  }
}
