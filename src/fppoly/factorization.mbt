///|
#derive(Eq, Debug)
pub(all) struct Factor {
  polynomial : Polynomial
  multiplicity : @core.Nat
}

///|
pub extend Factor with Eq::{equal, not_equal}

///|
pub extend Factor with Debug::{to_repr}

///|
/// The unit is nonzero and reduced; factors are monic, distinct and ordered by
/// degree then lexicographically by their ascending coefficient lists.
#derive(Eq, Debug)
pub(all) struct Factorization {
  unit : @binary.Binary
  factors : @core.Chain[Factor]
}

///|
pub extend Factorization with Eq::{equal, not_equal}

///|
pub extend Factorization with Debug::{to_repr}

///|
/// A basis of ker(Q-I), where column j of Q is x^(p*j) modulo the input.
/// The producer uses general prime-field row reduction; splitting is separate.
pub fn berlekamp_basis(
  value : Polynomial,
) -> Result[@core.Chain[Polynomial], PolyError] {
  fn columns(
    current : Polynomial,
    xp : Polynomial,
    remaining : @core.Nat,
    n : @core.Nat,
  ) -> Result[@core.Chain[@core.Chain[@binary.Binary]], PolyError] {
    match remaining {
      Zero => Ok(Nil)
      Succ(rest) =>
        match product_remainder(current, xp, value) {
          Err(error) => Err(error)
          Ok(next) =>
            match columns(next, xp, rest, n) {
              Err(error) => Err(error)
              Ok(tail) =>
                Ok(
                  Cons(
                    @core.take(
                      n,
                      @core.append(
                        current.coefficients,
                        @core.replicate(n, @binary.zero()),
                      ),
                    ),
                    tail,
                  ),
                )
            }
        }
    }
  }
  match degree(value) {
    None => Err(ZeroPolynomial)
    Some(Zero) => Ok(Nil)
    Some(Succ(_) as n) =>
      match
        power_mod(indeterminate(value.field), characteristic(value), value) {
        Err(error) => Err(error)
        Ok(xp) =>
          match columns(one(value.field), xp, n, n) {
            Err(error) => Err(error)
            Ok(cols) => {
              let indices = @core.indices(n)
              let modulus = @primefield.modulus(value.field)
              let rows = @core.map(indices, fn(row) {
                @core.map(indices, fn(column) {
                  let entry = match @core.nth(cols, column) {
                    None => @binary.zero()
                    Some(coefficients) =>
                      match @core.nth(coefficients, row) {
                        None => @binary.zero()
                        Some(entry) => entry
                      }
                  }
                  match row.equal(column) {
                    true => @modular.subtract(modulus, entry, @binary.one())
                    false => entry
                  }
                })
              })
              match @matrix.matrix(n, rows) {
                None => Err(InternalInvariant)
                Some(matrix) =>
                  match
                    @rowreduce.solve(
                      @primefield.arithmetic(value.field),
                      matrix,
                      @core.replicate(n, @binary.zero()),
                    ) {
                    Some(Affine(_, basis)) =>
                      Ok(
                        @core.map(basis, fn(coefficients) {
                          polynomial(value.field, coefficients)
                        }),
                      )
                    _ => Err(InternalInvariant)
                  }
              }
            }
          }
      }
  }
}

///|
fn proper_split(
  value : Polynomial,
  splitter : Polynomial,
  scalar : @binary.Binary,
) -> Result[Polynomial, PolyError] {
  match @binary.compare(scalar, characteristic(value)) {
    Less =>
      match gcd(value, subtract_raw(splitter, constant(value.field, scalar))) {
        Err(error) => Err(error)
        Ok(divisor) =>
          match divisor.equal(one(value.field)) || divisor.equal(value) {
            true => proper_split(value, splitter, @binary.successor(scalar))
            false => Ok(divisor)
          }
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn pth_root(value : Polynomial) -> Result[Polynomial, PolyError] {
  fn collect(
    todo : @core.Chain[@binary.Binary],
    exponent : @binary.Binary,
  ) -> Result[@core.Chain[@binary.Binary], PolyError] {
    match todo {
      Nil => Ok(Nil)
      Cons(coefficient, rest) =>
        match @binary.divmod(exponent, characteristic(value)) {
          None => Err(InternalInvariant)
          Some((_, remainder)) =>
            match @binary.is_zero(remainder) {
              true =>
                match collect(rest, @binary.successor(exponent)) {
                  Err(error) => Err(error)
                  Ok(tail) => Ok(Cons(coefficient, tail))
                }
              false =>
                match @binary.is_zero(coefficient) {
                  false => Err(InternalInvariant)
                  true => collect(rest, @binary.successor(exponent))
                }
            }
        }
    }
  }
  match collect(value.coefficients, @binary.zero()) {
    Err(error) => Err(error)
    Ok(coefficients) => Ok(polynomial(value.field, coefficients))
  }
}

///|
fn factor_monic(
  value : Polynomial,
) -> Result[@core.Chain[Polynomial], PolyError] {
  fn split_by(
    divisor : Polynomial,
  ) -> Result[@core.Chain[Polynomial], PolyError] {
    match divide(value, divisor) {
      Err(error) => Err(error)
      Ok({ quotient, remainder, }) =>
        match is_zero(remainder) {
          false => Err(InternalInvariant)
          true =>
            match (factor_monic(divisor), factor_monic(quotient)) {
              (Ok(left), Ok(right)) => Ok(@core.append(left, right))
              (Err(error), _) | (_, Err(error)) => Err(error)
            }
        }
    }
  }
  match degree(value) {
    None | Some(Zero) => Ok(Nil)
    Some(Succ(_)) =>
      match gcd(value, derivative(value)) {
        Err(error) => Err(error)
        Ok(repeated) =>
          match repeated.equal(value) {
            true =>
              match pth_root(value) {
                Err(error) => Err(error)
                Ok(root) =>
                  match factor_monic(root) {
                    Err(error) => Err(error)
                    Ok(factors) => {
                      // A nonconstant p-th power has degree at least p, so
                      // this Nat conversion is bounded by the input degree.
                      let count = @binary.to_nat(characteristic(value))
                      Ok(
                        @core.fold_left(@core.replicate(count, ()), Nil, fn(
                          result,
                          _,
                        ) {
                          @core.append(factors, result)
                        }),
                      )
                    }
                  }
              }
            false =>
              match repeated.equal(one(value.field)) {
                false => split_by(repeated)
                true =>
                  match berlekamp_basis(value) {
                    Err(error) => Err(error)
                    Ok(basis) =>
                      match
                        @core.filter(basis, fn(value) {
                          match degree(value) {
                            Some(Succ(_)) => true
                            _ => false
                          }
                        }) {
                        Nil => Ok(Cons(value, Nil))
                        Cons(splitter, _) =>
                          match proper_split(value, splitter, @binary.zero()) {
                            Err(error) => Err(error)
                            Ok(divisor) => split_by(divisor)
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
fn compare_coefficients(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(x, xs), Cons(y, ys)) =>
      match @binary.compare(x, y) {
        Equal => compare_coefficients(xs, ys)
        order => order
      }
  }
}

///|
fn compare_polynomials(a : Polynomial, b : Polynomial) -> @core.Ordering {
  match
    @core.compare(@core.length(a.coefficients), @core.length(b.coefficients)) {
    Equal => compare_coefficients(a.coefficients, b.coefficients)
    order => order
  }
}

///|
fn insert_factor(
  value : Polynomial,
  factors : @core.Chain[Factor],
) -> @core.Chain[Factor] {
  match factors {
    Nil => Cons({ polynomial: value, multiplicity: Succ(Zero), }, Nil)
    Cons(head, tail) =>
      match compare_polynomials(value, head.polynomial) {
        Less => Cons({ polynomial: value, multiplicity: Succ(Zero), }, factors)
        Equal => Cons({ ..head, multiplicity: Succ(head.multiplicity), }, tail)
        Greater => Cons(head, insert_factor(value, tail))
      }
  }
}

///|
/// Deterministic Berlekamp splitting, recursively separating repeated factors
/// and extracting p-th roots when the formal derivative vanishes.
pub fn factor(value : Polynomial) -> Result[Factorization, PolyError] {
  match leading(value) {
    None => Err(ZeroPolynomial)
    Some(unit) =>
      match monic(value) {
        Err(error) => Err(error)
        Ok(normalized) =>
          match factor_monic(normalized) {
            Err(error) => Err(error)
            Ok(factors) =>
              Ok({
                unit,
                factors: @core.fold_left(factors, Nil, fn(result, value) {
                  insert_factor(value, result)
                }),
              })
          }
      }
  }
}

///|
fn factor_power(value : Polynomial, count : @core.Nat) -> Polynomial {
  match count {
    Zero => one(value.field)
    Succ(rest) => multiply_raw(value, factor_power(value, rest))
  }
}

///|
/// Verify ordered monic irreducible factors, positive multiplicities and exact
/// reconstruction. Certificates must align one-for-one with the distinct factors.
pub fn check_factorization(
  value : Polynomial,
  result : Factorization,
  certificates : @core.Chain[IrreducibilityCertificate],
) -> Bool {
  fn visit(
    factors : @core.Chain[Factor],
    proofs : @core.Chain[IrreducibilityCertificate],
    previous : Polynomial?,
    product : Polynomial,
  ) -> Bool {
    match (factors, proofs) {
      (Nil, Nil) => product.equal(value)
      (Cons(head, tail), Cons(proof, rest)) => {
        let ordered = match previous {
          None => true
          Some(previous) =>
            compare_polynomials(previous, head.polynomial) is Less
        }
        match head.multiplicity {
          Zero => false
          Succ(_) =>
            match
              compatible(value, head.polynomial) &&
              ordered &&
              check_irreducible(head.polynomial, proof) {
              false => false
              true =>
                visit(
                  tail,
                  rest,
                  Some(head.polynomial),
                  multiply_raw(
                    product,
                    factor_power(head.polynomial, head.multiplicity),
                  ),
                )
            }
        }
      }
      _ => false
    }
  }
  match
    @binary.is_zero(result.unit) ||
    is_zero(value) ||
    !(@binary.compare(result.unit, characteristic(value)) is Less) {
    true => false
    false =>
      visit(
        result.factors,
        certificates,
        None,
        constant(value.field, result.unit),
      )
  }
}
