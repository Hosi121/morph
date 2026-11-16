///|
fn[A, B] map_result(
  values : @core.Chain[A],
  transform : (A) -> Result[B, CadError],
) -> Result[@core.Chain[B], CadError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match transform(value) {
        Err(error) => Err(error)
        Ok(head) =>
          match map_result(rest, transform) {
            Ok(tail) => Ok(Cons(head, tail))
            Err(error) => Err(error)
          }
      }
  }
}

///|
fn scalar_power(
  value : @tower.Scalar,
  exponent : @core.Nat,
) -> Result[@tower.Scalar, CadError] {
  match exponent {
    Zero => Ok(@tower.scalar_one(@tower.scalar_field(value)))
    Succ(Zero) => Ok(value)
    _ => {
      let (half, odd) = @core.halve_nat(exponent)
      match scalar_power(value, half) {
        Err(error) => Err(error)
        Ok(part) =>
          match @tower.scalar_multiply(part, part) {
            Err(error) => Err(TowerFailure(error))
            Ok(square) =>
              if odd {
                match @tower.scalar_multiply(value, square) {
                  Ok(answer) => Ok(answer)
                  Err(error) => Err(TowerFailure(error))
                }
              } else {
                Ok(square)
              }
          }
      }
    }
  }
}

///|
fn evaluate_term(
  coefficient : @tower.Scalar,
  exponents : @core.Chain[@core.Nat],
  coordinates : @core.Chain[@tower.Scalar],
) -> Result[@tower.Scalar, CadError] {
  match (exponents, coordinates) {
    (Nil, Nil) => Ok(coefficient)
    (Cons(Zero, rest), Cons(_, tail)) => evaluate_term(coefficient, rest, tail)
    (Cons(exponent, rest), Cons(value, tail)) =>
      match scalar_power(value, exponent) {
        Err(error) => Err(error)
        Ok(power) =>
          match @tower.scalar_multiply(coefficient, power) {
            Ok(next) => evaluate_term(next, rest, tail)
            Err(error) => Err(TowerFailure(error))
          }
      }
    _ => Err(WrongArity)
  }
}

///|
/// Substitute the prefix, leaving the next variable as a dense univariate
/// polynomial. No conversion to machine numerics or absolute minimal field.
fn specialize(
  point : Point,
  polynomial : @poly.Polynomial,
) -> Result[@tower.Polynomial, CadError] {
  let prefix = @core.length(point.coordinates)
  if !@poly.variables(polynomial).equal(Succ(prefix)) {
    Err(WrongArity)
  } else {
    fn sum(
      terms : @core.Chain[@poly.Term],
      accumulated : @tower.Polynomial,
    ) -> Result[@tower.Polynomial, CadError] {
      match terms {
        Nil => Ok(accumulated)
        Cons(term, rest) =>
          match @core.split_exact(prefix, term.exponents) {
            Some((exponents, Cons(power, Nil))) =>
              match
                evaluate_term(
                  @tower.rational(point.field, term.coefficient),
                  exponents,
                  point.coordinates,
                ) {
                Err(error) => Err(error)
                Ok(value) =>
                  match
                    @tower.polynomial(
                      point.field,
                      @core.replicate_onto(
                        power,
                        @tower.scalar_zero(point.field),
                        Cons(value, Nil),
                      ),
                    ) {
                    Err(error) => Err(TowerFailure(error))
                    Ok(monomial) =>
                      match @tower.add(accumulated, monomial) {
                        Ok(next) => sum(rest, next)
                        Err(error) => Err(TowerFailure(error))
                      }
                  }
              }
            _ => Err(WrongArity)
          }
      }
    }
    sum(@poly.terms(polynomial), @tower.zero(point.field))
  }
}

///|
pub fn evaluate_polynomial(
  point : Point,
  polynomial : @poly.Polynomial,
) -> Result[@tower.Scalar, CadError] {
  if !@poly.variables(polynomial).equal(@core.length(point.coordinates)) {
    Err(WrongArity)
  } else {
    fn sum(
      terms : @core.Chain[@poly.Term],
      accumulated : @tower.Scalar,
    ) -> Result[@tower.Scalar, CadError] {
      match terms {
        Nil => Ok(accumulated)
        Cons(term, rest) =>
          match
            evaluate_term(
              @tower.rational(point.field, term.coefficient),
              term.exponents,
              point.coordinates,
            ) {
            Err(error) => Err(error)
            Ok(value) =>
              match @tower.scalar_add(accumulated, value) {
                Ok(next) => sum(rest, next)
                Err(error) => Err(TowerFailure(error))
              }
          }
      }
    }
    sum(@poly.terms(polynomial), @tower.scalar_zero(point.field))
  }
}

///|
pub fn evaluate_formula(
  point : Point,
  formula : @qf.Formula,
) -> Result[Bool, CadError] {
  let atoms = @logic.qf_atoms(formula)
  match
    map_result(atoms, fn(p) {
      match evaluate_polynomial(point, p) {
        Err(error) => Err(error)
        Ok(value) =>
          match @tower.scalar_sign(value) {
            Ok(result) => Ok(result.sign)
            Err(error) => Err(TowerFailure(error))
          }
      }
    }) {
    Err(error) => Err(error)
    Ok(signs) =>
      match @logic.evaluate_signs(formula, atoms, signs) {
        Some(value) => Ok(value)
        None => Err(InternalInvariant)
      }
  }
}

///|
fn checked_divide(
  dividend : @tower.Polynomial,
  divisor : @tower.Polynomial,
) -> Result[@tower.Division, CadError] {
  match @tower.divide(dividend, divisor) {
    Err(error) => Err(TowerFailure(error))
    Ok(division) =>
      match @tower.multiply(division.quotient, divisor) {
        Err(error) => Err(TowerFailure(error))
        Ok(product) =>
          match @tower.add(product, division.remainder) {
            Err(error) => Err(TowerFailure(error))
            Ok(reconstructed) =>
              match @tower.polynomial_equal(dividend, reconstructed) {
                Ok(true) => Ok(division)
                Ok(false) => Err(InternalInvariant)
                Err(error) => Err(TowerFailure(error))
              }
          }
      }
  }
}

///|
fn root_union_gcd(
  left : @tower.Polynomial,
  right : @tower.Polynomial,
) -> Result[@tower.Polynomial, CadError] {
  if @tower.is_zero(right) {
    match @tower.monic(left) {
      Ok(answer) => Ok(answer)
      Err(error) => Err(TowerFailure(error))
    }
  } else {
    match @tower.divide(left, right) {
      Err(error) => Err(TowerFailure(error))
      Ok(division) =>
        match (@tower.degree(division.remainder), @tower.degree(right)) {
          (None, _) => root_union_gcd(right, division.remainder)
          (Some(a), Some(b)) =>
            if @core.compare(a, b) is Less {
              root_union_gcd(right, division.remainder)
            } else {
              Err(InternalInvariant)
            }
          _ => Err(InternalInvariant)
        }
    }
  }
}

///|
/// Each step verifies A|G, P|G and G|(A*P). Thus G has precisely the union
/// of real roots, even when A and P share factors. The growing full product
/// is never passed to a squarefree PRS computation.
fn root_union_pair(
  accumulated : @tower.Polynomial,
  polynomial : @tower.Polynomial,
) -> Result[@tower.Polynomial, CadError] {
  match checked_divide(accumulated, polynomial) {
    Err(error) => Err(error)
    Ok(existing) =>
      if @tower.is_zero(existing.remainder) {
        Ok(accumulated)
      } else {
        match root_union_gcd(accumulated, polynomial) {
          Err(error) => Err(error)
          Ok(gcd) =>
            match checked_divide(accumulated, gcd) {
              Err(error) => Err(error)
              Ok(part) =>
                if !@tower.is_zero(part.remainder) {
                  Err(InternalInvariant)
                } else {
                  match @tower.multiply(part.quotient, polynomial) {
                    Err(error) => Err(TowerFailure(error))
                    Ok(raw) =>
                      match @tower.monic(raw) {
                        Err(error) => Err(TowerFailure(error))
                        Ok(candidate) =>
                          match @tower.multiply(accumulated, polynomial) {
                            Err(error) => Err(TowerFailure(error))
                            Ok(pair_product) =>
                              match
                                (
                                  checked_divide(candidate, accumulated),
                                  checked_divide(candidate, polynomial),
                                  checked_divide(pair_product, candidate),
                                ) {
                                (Ok(a), Ok(b), Ok(c)) =>
                                  if @tower.is_zero(a.remainder) &&
                                    @tower.is_zero(b.remainder) &&
                                    @tower.is_zero(c.remainder) {
                                    Ok(candidate)
                                  } else {
                                    Err(InternalInvariant)
                                  }
                                (Err(error), _, _)
                                | (_, Err(error), _)
                                | (_, _, Err(error)) => Err(error)
                              }
                          }
                      }
                  }
                }
            }
        }
      }
  }
}

///|
fn root_union(
  systems : @core.Chain[@tower.System?],
  accumulated : @tower.Polynomial,
) -> Result[@tower.Polynomial, CadError] {
  match systems {
    Nil => Ok(accumulated)
    Cons(None, rest) => root_union(rest, accumulated)
    Cons(Some(system), rest) => {
      let p = @tower.squarefree(system)
      match @tower.degree(p) {
        None => Err(InternalInvariant)
        Some(Zero) => root_union(rest, accumulated)
        Some(_) =>
          if @tower.degree(accumulated) is Some(Zero) {
            root_union(rest, p)
          } else {
            match root_union_pair(accumulated, p) {
              Ok(next) => root_union(rest, next)
              Err(error) => Err(error)
            }
          }
      }
    }
  }
}

///|
fn prepare_fibre(
  point : Point,
  family : @core.Chain[@poly.Polynomial],
) -> Result[Fibre, CadError] {
  match map_result(family, fn(p) { specialize(point, p) }) {
    Err(error) => Err(error)
    Ok(polynomials) =>
      match
        map_result(polynomials, fn(p) {
          if @tower.is_zero(p) {
            Ok(None)
          } else {
            match @tower.system(p) {
              Ok(system) => Ok(Some(system))
              Err(error) => Err(TowerFailure(error))
            }
          }
        }) {
        Err(error) => Err(error)
        Ok(systems) =>
          match root_union(systems, @tower.one(point.field)) {
            Err(error) => Err(error)
            Ok(root_polynomial) =>
              match @tower.system(root_polynomial) {
                Err(error) => Err(TowerFailure(error))
                Ok(system) =>
                  Ok({ polynomials, systems, root_polynomial, system, })
              }
          }
      }
  }
}
