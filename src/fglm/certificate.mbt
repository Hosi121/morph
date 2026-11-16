///|
/// A linear dependence NF(m) = sum(c_i NF(t_i)), with every t_i smaller than m
/// in the target order. The exact relation polynomial is reconstructed by check.
#derive(Eq, Debug)
pub(all) struct Relation {
  monomial : @core.Chain[@core.Nat]
  standard_monomials : @core.Chain[@core.Chain[@core.Nat]]
  coefficients : @core.Chain[@exact.Rational]
}

///|
pub extend Relation with Eq::{equal, not_equal}

///|
pub extend Relation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  order : Order
  polynomials : @core.Chain[@poly.Polynomial]
  relations : @core.Chain[Relation]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
fn relation_polynomial(
  variables : @core.Nat,
  value : Relation,
) -> Result[@poly.Polynomial, FglmError] {
  if !@core.compare(@core.length(value.monomial), variables).equal(Equal) ||
    !@core.all(value.standard_monomials, fn(m) {
      @core.compare(@core.length(m), variables).equal(Equal)
    }) {
    return Err(DimensionMismatch)
  }
  match @core.zip(value.standard_monomials, value.coefficients) {
    None => Err(DimensionMismatch)
    Some(pairs) =>
      polynomial_result(
        @poly.polynomial(
          variables,
          Cons(
            { coefficient: @exact.rational_one(), exponents: value.monomial, },
            @core.map(pairs, fn(pair) {
              let (exponents, c) = pair
              { coefficient: @exact.rational_negate(c), exponents, }
            }),
          ),
        ),
      )
  }
}

///|
/// Verify relation witnesses, target-to-source membership, source-to-target
/// membership and all target S-pairs. No heap, staircase enumeration, or linear
/// dependence solve is replayed by this checker.
pub fn check(
  source : @f4.Basis,
  value : Certificate,
) -> Result[Bool, FglmError] {
  match @f4.verify(source) {
    Ok(true) => ()
    _ => return Err(InvalidSource)
  }
  let variables = @f4.variables(source)
  let old = @f4.polynomials(source)
  let basis = value.polynomials
  if !@core.all(basis, fn(p) {
      @core.compare(@poly.variables(p), variables).equal(Equal)
    }) {
    return Err(DimensionMismatch)
  }
  if @core.any(basis, @poly.is_zero) {
    return Ok(false)
  }
  fn witnesses(
    polynomials : @core.Chain[@poly.Polynomial],
    relations : @core.Chain[Relation],
  ) -> Result[Bool, FglmError] {
    match (polynomials, relations) {
      (Nil, Nil) => Ok(true)
      (Cons(p, rest), Cons(relation, tail)) => {
        if !unique(relation.standard_monomials) ||
          !@core.all(relation.standard_monomials, fn(m) {
            compare_monomial(value.order, m, relation.monomial).equal(Less)
          }) {
          return Ok(false)
        }
        match relation_polynomial(variables, relation) {
          Err(error) => Err(error)
          Ok(reconstructed) =>
            if !reconstructed.equal(p) {
              Ok(false)
            } else {
              match @poly.normal_form(p, old) {
                Err(_) => Err(InternalInvariant)
                Ok(normal) =>
                  if @poly.is_zero(normal) {
                    witnesses(rest, tail)
                  } else {
                    Ok(false)
                  }
              }
            }
        }
      }
      _ => Ok(false)
    }
  }
  fn source_membership(
    todo : @core.Chain[@poly.Polynomial],
  ) -> Result[Bool, FglmError] {
    match todo {
      Nil => Ok(true)
      Cons(p, rest) =>
        match normal_form(value.order, p, basis) {
          Err(error) => Err(error)
          Ok(normal) =>
            if @poly.is_zero(normal) {
              source_membership(rest)
            } else {
              Ok(false)
            }
        }
    }
  }
  fn row_pairs(
    p : @poly.Polynomial,
    todo : @core.Chain[@poly.Polynomial],
  ) -> Result[Bool, FglmError] {
    match todo {
      Nil => Ok(true)
      Cons(q, rest) =>
        match s_polynomial(value.order, p, q) {
          Err(error) => Err(error)
          Ok(s) =>
            match normal_form(value.order, s, basis) {
              Err(error) => Err(error)
              Ok(normal) =>
                if @poly.is_zero(normal) {
                  row_pairs(p, rest)
                } else {
                  Ok(false)
                }
            }
        }
    }
  }
  fn all_pairs(
    todo : @core.Chain[@poly.Polynomial],
  ) -> Result[Bool, FglmError] {
    match todo {
      Nil => Ok(true)
      Cons(p, rest) =>
        match row_pairs(p, rest) {
          Ok(true) => all_pairs(rest)
          other => other
        }
    }
  }
  match (witnesses(basis, value.relations), source_membership(old)) {
    (Ok(true), Ok(true)) => all_pairs(basis)
    (Err(error), _) | (_, Err(error)) => Err(error)
    _ => Ok(false)
  }
}
