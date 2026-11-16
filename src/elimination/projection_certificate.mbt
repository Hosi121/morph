///|
#derive(Eq, Debug)
pub(all) struct ProjectionIdentity {
  left : Input
  right : Input
  value : @poly.Polynomial
  u : @poly.Polynomial
  v : @poly.Polynomial
}

///|
pub extend ProjectionIdentity with Eq::{equal, not_equal}

///|
pub extend ProjectionIdentity with Debug::{to_repr}

///|
fn insert_exponent(
  exponents : @core.Chain[@core.Nat],
  variable : @core.Nat,
  power : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match (variable, exponents) {
    (Zero, _) => Some(Cons(power, exponents))
    (Succ(previous), Cons(head, rest)) =>
      match insert_exponent(rest, previous, power) {
        None => None
        Some(tail) => Some(Cons(head, tail))
      }
    _ => None
  }
}

///|
fn lift_coefficient(
  terms : @core.Chain[@poly.Term],
  selected : @core.Nat,
  power : @core.Nat,
) -> @core.Chain[@poly.Term]? {
  match terms {
    Nil => Some(Nil)
    Cons(term, rest) =>
      match
        (
          insert_exponent(term.exponents, selected, power),
          lift_coefficient(rest, selected, power),
        ) {
        (Some(exponents), Some(tail)) =>
          Some(Cons({ ..term, exponents, }, tail))
        _ => None
      }
  }
}

///|
fn coefficient_list_polynomial(
  values : @core.Chain[Coefficient],
  variables : @core.Nat,
  selected : @core.Nat,
) -> Result[@poly.Polynomial, EliminationError] {
  fn go(values : @core.Chain[Coefficient]) -> @core.Chain[@poly.Term]? {
    match values {
      Nil => Some(Nil)
      Cons(head, rest) =>
        match
          (lift_coefficient(head.terms, selected, @core.length(rest)), go(rest)) {
          (Some(terms), Some(tail)) => Some(@core.append(terms, tail))
          _ => None
        }
    }
  }
  match go(values) {
    None => Err(InternalDimension)
    Some(terms) =>
      match @poly.polynomial(variables, terms) {
        Ok(p) => Ok(p)
        Err(_) => Err(InternalDimension)
      }
  }
}

///|
fn lift_value(
  value : @poly.Polynomial,
  selected : @core.Nat,
) -> @poly.Polynomial? {
  match lift_coefficient(@poly.terms(value), selected, Zero) {
    None => None
    Some(terms) =>
      match @poly.polynomial(Succ(@poly.variables(value)), terms) {
        Ok(p) => Some(p)
        Err(_) => None
      }
  }
}

///|
/// Produce a bounded Bezout identity using the division-free adjugate. Two
/// nominal constants return ConstantPairIdentity, since their resultant is one
/// and may not belong to the ideal they generate.
pub fn projection_identity(
  f : Input,
  g : Input,
) -> Result[ProjectionIdentity, EliminationError] {
  if !compatible(f, g) {
    Err(DimensionMismatch)
  } else {
    match (@poly.variables(f.polynomial), @core.add(f.degree, g.degree)) {
      (_, Zero) => Err(ConstantPairIdentity)
      (Zero, _) => Err(InvalidVariable)
      (Succ(remaining), _) =>
        match (as_coefficients(f), as_coefficients(g)) {
          (Some(left), Some(right)) =>
            match bezout(left, right, coefficient_ring(remaining)) {
              None => Err(InternalDimension)
              Some(proof) =>
                match
                  (
                    coefficient_polynomial(proof.value, remaining),
                    coefficient_list_polynomial(
                      proof.u,
                      Succ(remaining),
                      f.variable,
                    ),
                    coefficient_list_polynomial(
                      proof.v,
                      Succ(remaining),
                      f.variable,
                    ),
                  ) {
                  (Ok(value), Ok(u), Ok(v)) =>
                    Ok({ left: f, right: g, value, u, v, })
                  _ => Err(InternalDimension)
                }
            }
          _ => Err(InternalDimension)
        }
    }
  }
}

///|
fn multiplier_bound(
  p : @poly.Polynomial,
  selected : @core.Nat,
  bound : @core.Nat,
) -> Bool {
  if @poly.is_zero(p) {
    true
  } else {
    match variable_degree(p, selected) {
      None => false
      Some(degree) => @core.compare(degree, bound) is Less
    }
  }
}

///|
/// Check only U*f+V*g=lift(value), with the embedded source, variable, nominal
/// degrees, output arity and multiplier bounds bound to the external query.
/// This proves ideal membership, not equality with the resultant determinant.
pub fn check_projection_identity(
  f : Input,
  g : Input,
  value : @poly.Polynomial,
  proof : ProjectionIdentity,
) -> Bool {
  let arity = @poly.variables(f.polynomial)
  if !compatible(f, g) ||
    !f.equal(proof.left) ||
    !g.equal(proof.right) ||
    !value.equal(proof.value) ||
    !(@core.compare(@poly.variables(proof.u), arity) is Equal) ||
    !(@core.compare(@poly.variables(proof.v), arity) is Equal) ||
    !(@core.compare(Succ(@poly.variables(value)), arity) is Equal) ||
    !multiplier_bound(proof.u, f.variable, g.degree) ||
    !multiplier_bound(proof.v, f.variable, f.degree) {
    false
  } else {
    match
      (
        @poly.multiply(proof.u, f.polynomial),
        @poly.multiply(proof.v, g.polynomial),
        lift_value(value, f.variable),
      ) {
      (Ok(left), Ok(right), Some(expected)) =>
        match @poly.add(left, right) {
          Ok(sum) => sum.equal(expected)
          Err(_) => false
        }
      _ => false
    }
  }
}

///|
/// Recomputes the fixed-degree determinant as well as checking the independent
/// polynomial identity. This binds the claimed result to the full query.
pub fn check_projection_result(
  f : Input,
  g : Input,
  value : @poly.Polynomial,
  proof : ProjectionIdentity,
) -> Bool {
  if !check_projection_identity(f, g, value, proof) {
    false
  } else {
    match eliminate(f, g) {
      Ok(expected) => value.equal(expected)
      Err(_) => false
    }
  }
}

///|
pub fn check_elimination(
  f : Input,
  g : Input,
  value : @poly.Polynomial,
) -> Bool {
  match eliminate(f, g) {
    Ok(expected) => value.equal(expected)
    Err(_) => false
  }
}

///|
pub fn check_discrimination(f : Input, value : @poly.Polynomial) -> Bool {
  match discriminate(f) {
    Ok(expected) => value.equal(expected)
    Err(_) => false
  }
}
