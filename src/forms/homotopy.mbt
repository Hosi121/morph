///|
fn increment_exponent(
  exponents : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match (exponents, index) {
    (Nil, _) => None
    (Cons(power, rest), Zero) => Some(Cons(Succ(power), rest))
    (Cons(power, rest), Succ(previous)) =>
      match increment_exponent(rest, previous) {
        None => None
        Some(tail) => Some(Cons(power, tail))
      }
  }
}

///|
/// Radial polynomial homotopy. Each coefficient monomial of degree r in a
/// positive exterior degree k receives (r+k)^-1 i_E. Mixed degrees are split
/// before division. None at k=0 denotes the zero in exterior degree -1.
pub fn radial_homotopy(value : Form) -> Result[Form?, FormError] {
  fn interior(
    monomial : @poly.Term,
    scale : @exact.Rational,
    remaining : @core.Chain[@core.Nat],
    prefix_reversed : @core.Chain[@core.Nat],
    negative : Bool,
  ) -> Result[@core.Chain[Term], FormError] {
    match remaining {
      Nil => Ok(Nil)
      Cons(index, rest) =>
        match increment_exponent(monomial.exponents, index) {
          None => Err(InternalInvariant)
          Some(exponents) => {
            let scaled = @exact.rational_multiply(monomial.coefficient, scale)
            let coefficient = if negative {
              @exact.rational_negate(scaled)
            } else {
              scaled
            }
            match
              (
                @poly.polynomial(
                  value.variables,
                  Cons({ coefficient, exponents, }, Nil),
                ),
                interior(
                  monomial,
                  scale,
                  rest,
                  Cons(index, prefix_reversed),
                  !negative,
                ),
              ) {
              (Ok(coefficient), Ok(tail)) =>
                Ok(
                  Cons(
                    {
                      coefficient,
                      indices: @core.reverse_onto(prefix_reversed, rest),
                    },
                    tail,
                  ),
                )
              _ => Err(InternalInvariant)
            }
          }
        }
    }
  }
  fn monomials(
    input : @core.Chain[@poly.Term],
    indices : @core.Chain[@core.Nat],
  ) -> Result[@core.Chain[Term], FormError] {
    match input {
      Nil => Ok(Nil)
      Cons(term, rest) => {
        let weight = @core.fold_left(term.exponents, value.degree, @core.add)
        // value.degree is positive at every call, so this denominator is nonzero.
        match
          @exact.ratio(@exact.positive(@binary.one()), @binary.from_nat(weight)) {
          None => Err(InternalInvariant)
          Some(scale) =>
            match
              (
                interior(term, scale, indices, Nil, false),
                monomials(rest, indices),
              ) {
              (Ok(current), Ok(tail)) => Ok(@core.append(current, tail))
              _ => Err(InternalInvariant)
            }
        }
      }
    }
  }
  fn walk(input : @core.Chain[Term]) -> Result[@core.Chain[Term], FormError] {
    match input {
      Nil => Ok(Nil)
      Cons(term, rest) =>
        match
          (monomials(@poly.terms(term.coefficient), term.indices), walk(rest)) {
          (Ok(current), Ok(tail)) => Ok(@core.append(current, tail))
          _ => Err(InternalInvariant)
        }
    }
  }
  match value.degree {
    Zero => Ok(None)
    Succ(previous) =>
      match walk(value.terms) {
        Err(error) => Err(error)
        Ok(input) =>
          match form(value.variables, previous, input) {
            Err(error) => Err(error)
            Ok(result) => Ok(Some(result))
          }
      }
  }
}

///|
/// Checks the original primitive equation and both gradings, without calling
/// radial_homotopy or the primitive producer. Polynomial/d remain shared.
pub fn check_primitive(value : Form, candidate : Form) -> Bool {
  match value.degree {
    Zero => false
    Succ(previous) =>
      if !value.variables.equal(candidate.variables) ||
        !previous.equal(candidate.degree) {
        false
      } else {
        match exterior_derivative(candidate) {
          Err(_) => false
          Ok(actual) => actual.equal(value)
        }
      }
  }
}

///|
/// A fixed polynomial primitive on affine space, only for closed k>0 forms.
/// No primitive is selected for degree-zero constants or nonclosed inputs.
pub fn primitive(value : Form) -> Result[Form, FormError] {
  match value.degree {
    Zero => Err(ZeroDegree)
    Succ(_) =>
      match exterior_derivative(value) {
        Err(error) => Err(error)
        Ok(differential) =>
          if !is_zero(differential) {
            Err(NotClosed)
          } else {
            match radial_homotopy(value) {
              Err(error) => Err(error)
              Ok(None) => Err(InternalInvariant)
              Ok(Some(candidate)) =>
                if check_primitive(value, candidate) {
                  Ok(candidate)
                } else {
                  Err(InternalInvariant)
                }
            }
          }
      }
  }
}
