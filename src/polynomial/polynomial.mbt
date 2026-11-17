///|
/// Exponent vectors use the fixed variable order, with the first variable largest.
#derive(Eq, Debug)
pub(all) struct Term {
  coefficient : @exact.Rational
  exponents : @core.Chain[@core.Nat]
}

///|
pub extend Term with Eq::{equal, not_equal}

///|
pub extend Term with Debug::{to_repr}

///|
/// Sparse canonical polynomial: lex-descending monomials, no zero coefficients,
/// no duplicate monomials, and all exponent vectors have the stored dimension.
#derive(Eq, Debug)
pub struct Polynomial {
  variables : @core.Nat
  terms : @core.Chain[Term]
}

///|
pub extend Polynomial with Eq::{equal, not_equal}

///|
pub extend Polynomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum PolyError {
  DimensionMismatch
  ZeroDivisor
}

///|
pub extend PolyError with Eq::{equal, not_equal}

///|
pub extend PolyError with Debug::{to_repr}

///|
/// Lexicographic monomial order; callers compare vectors of equal length.
pub fn compare_monomial(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(x, xt), Cons(y, yt)) =>
      match @core.compare(x, y) {
        Equal => compare_monomial(xt, yt)
        order => order
      }
  }
}

///|
fn nonzero(term : Term) -> Bool {
  match @exact.nonzero(term.coefficient) {
    None => false
    Some(_) => true
  }
}

///|
fn insert(term : Term, terms : @core.Chain[Term]) -> @core.Chain[Term] {
  match nonzero(term) {
    false => terms
    true =>
      match terms {
        Nil => Cons(term, Nil)
        Cons(head, rest) =>
          match compare_monomial(term.exponents, head.exponents) {
            Greater => Cons(term, terms)
            Less => Cons(head, insert(term, rest))
            Equal => {
              let combined : Term = {
                coefficient: @exact.rational_add(
                  term.coefficient,
                  head.coefficient,
                ),
                exponents: head.exponents,
              }
              match nonzero(combined) {
                true => Cons(combined, rest)
                false => rest
              }
            }
          }
      }
  }
}

///|
pub fn polynomial(
  variables : @core.Nat,
  terms : @core.Chain[Term],
) -> Result[Polynomial, PolyError] {
  match
    @core.all(terms, fn(term) {
      match @core.compare(@core.length(term.exponents), variables) {
        Equal => true
        _ => false
      }
    }) {
    false => Err(DimensionMismatch)
    true => {
      let canonical : @core.Chain[Term] = @core.fold_left(terms, @core.Nil, fn(
        found,
        term,
      ) {
        insert(term, found)
      })
      Ok({ variables, terms: canonical, })
    }
  }
}

///|
pub fn variables(p : Polynomial) -> @core.Nat {
  p.variables
}

///|
pub fn terms(p : Polynomial) -> @core.Chain[Term] {
  p.terms
}

///|
pub fn zero(variables : @core.Nat) -> Polynomial {
  { variables, terms: Nil, }
}

///|
pub fn is_zero(p : Polynomial) -> Bool {
  match p.terms {
    Nil => true
    _ => false
  }
}

///|
pub fn constant(
  variables : @core.Nat,
  coefficient : @exact.Rational,
) -> Polynomial {
  match @exact.nonzero(coefficient) {
    None => zero(variables)
    Some(_) =>
      {
        variables,
        terms: Cons(
          { coefficient, exponents: @core.replicate(variables, Zero), },
          Nil,
        ),
      }
  }
}

///|
fn merge_terms(
  a : @core.Chain[Term],
  b : @core.Chain[Term],
) -> @core.Chain[Term] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xt), Cons(y, yt)) =>
      match compare_monomial(x.exponents, y.exponents) {
        Greater => Cons(x, merge_terms(xt, b))
        Less => Cons(y, merge_terms(a, yt))
        Equal => {
          let combined : Term = {
            coefficient: @exact.rational_add(x.coefficient, y.coefficient),
            exponents: x.exponents,
          }
          let rest = merge_terms(xt, yt)
          match nonzero(combined) {
            true => Cons(combined, rest)
            false => rest
          }
        }
      }
  }
}

///|
pub fn negate(p : Polynomial) -> Polynomial {
  {
    variables: p.variables,
    terms: @core.map(p.terms, fn(term) {
      {
        coefficient: @exact.rational_negate(term.coefficient),
        exponents: term.exponents,
      }
    }),
  }
}

///|
pub fn add(a : Polynomial, b : Polynomial) -> Result[Polynomial, PolyError] {
  match @core.compare(a.variables, b.variables) {
    Equal =>
      Ok({ variables: a.variables, terms: merge_terms(a.terms, b.terms), })
    _ => Err(DimensionMismatch)
  }
}

///|
pub fn subtract(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  add(a, negate(b))
}

///|
fn monomial_product(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match (a, b) {
    (Cons(x, xt), Cons(y, yt)) =>
      Cons(@core.add(x, y), monomial_product(xt, yt))
    _ => Nil
  }
}

///|
fn term_times(term : Term, terms : @core.Chain[Term]) -> @core.Chain[Term] {
  match nonzero(term) {
    false => Nil
    true =>
      @core.map(terms, fn(other) {
        {
          coefficient: @exact.rational_multiply(
            term.coefficient,
            other.coefficient,
          ),
          exponents: monomial_product(term.exponents, other.exponents),
        }
      })
  }
}

///|
pub fn multiply(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match @core.compare(a.variables, b.variables) {
    Equal =>
      Ok({
        variables: a.variables,
        terms: balanced_product_terms(a.terms, b.terms),
      })
    _ => Err(DimensionMismatch)
  }
}

///|
pub fn scale(p : Polynomial, term : Term) -> Result[Polynomial, PolyError] {
  match @core.compare(p.variables, @core.length(term.exponents)) {
    Equal => Ok({ variables: p.variables, terms: term_times(term, p.terms), })
    _ => Err(DimensionMismatch)
  }
}

///|
pub fn divides(a : @core.Chain[@core.Nat], b : @core.Chain[@core.Nat]) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xt), Cons(y, yt)) =>
      match @core.compare(x, y) {
        Greater => false
        _ => divides(xt, yt)
      }
    _ => false
  }
}

///|
pub fn monomial_quotient(
  numerator : @core.Chain[@core.Nat],
  denominator : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match divides(denominator, numerator) {
    false => None
    true => {
      fn go(
        a : @core.Chain[@core.Nat],
        b : @core.Chain[@core.Nat],
      ) -> @core.Chain[@core.Nat] {
        match (a, b) {
          (Cons(x, xt), Cons(y, yt)) => Cons(@core.subtract(x, y), go(xt, yt))
          _ => Nil
        }
      }
      Some(go(numerator, denominator))
    }
  }
}

///|
pub fn monomial_lcm(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match (a, b) {
    (Nil, Nil) => Some(Nil)
    (Cons(x, xt), Cons(y, yt)) =>
      match monomial_lcm(xt, yt) {
        None => None
        Some(rest) =>
          Some(
            Cons(
              match @core.compare(x, y) {
                Greater => x
                _ => y
              },
              rest,
            ),
          )
      }
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Division {
  quotients : @core.Chain[Polynomial]
  remainder : Polynomial
}

///|
pub extend Division with Eq::{equal, not_equal}

///|
pub extend Division with Debug::{to_repr}

///|
/// Multivariate division in fixed lex order and the supplied divisor order.
pub fn divide(
  dividend : Polynomial,
  divisors : @core.Chain[Polynomial],
) -> Result[Division, PolyError] {
  fn find(
    divisors : @core.Chain[Polynomial],
    term : Term,
    index : @core.Nat,
  ) -> (Polynomial, Term, @core.Nat)? {
    match divisors {
      Nil => None
      Cons(divisor, rest) =>
        match divisor.terms {
          Nil => find(rest, term, Succ(index))
          Cons(leading, _) =>
            match
              (
                monomial_quotient(term.exponents, leading.exponents),
                @exact.nonzero(leading.coefficient),
              ) {
              (Some(exponents), Some(coefficient)) =>
                Some(
                  (
                    divisor,
                    {
                      coefficient: @exact.rational_multiply(
                        term.coefficient,
                        @exact.reciprocal(coefficient),
                      ),
                      exponents,
                    },
                    index,
                  ),
                )
              _ => find(rest, term, Succ(index))
            }
        }
    }
  }
  fn update(
    quotients : @core.Chain[Polynomial],
    index : @core.Nat,
    term : Term,
  ) -> @core.Chain[Polynomial] {
    match (quotients, index) {
      (Nil, _) => Nil
      (Cons(q, rest), Zero) =>
        Cons({ variables: q.variables, terms: insert(term, q.terms), }, rest)
      (Cons(q, rest), Succ(index)) => Cons(q, update(rest, index, term))
    }
  }
  fn reduce(
    todo : @core.Chain[Term],
    reversed : @core.Chain[Term],
    quotients : @core.Chain[Polynomial],
  ) -> Division {
    match todo {
      Nil =>
        {
          quotients,
          remainder: {
            variables: dividend.variables,
            terms: @core.reverse(reversed),
          },
        }
      Cons(term, rest) =>
        match find(divisors, term, Zero) {
          None => reduce(rest, Cons(term, reversed), quotients)
          Some((divisor, multiplier, index)) => {
            let negative = @core.map(term_times(multiplier, divisor.terms), fn(
              term,
            ) {
              {
                coefficient: @exact.rational_negate(term.coefficient),
                exponents: term.exponents,
              }
            })
            reduce(
              merge_terms(todo, negative),
              reversed,
              update(quotients, index, multiplier),
            )
          }
        }
    }
  }
  let same_dimension = @core.all(divisors, fn(p) {
    match @core.compare(p.variables, dividend.variables) {
      Equal => true
      _ => false
    }
  })
  match (same_dimension, @core.any(divisors, is_zero)) {
    (false, _) => Err(DimensionMismatch)
    (_, true) => Err(ZeroDivisor)
    (true, false) =>
      Ok(
        reduce(
          dividend.terms,
          Nil,
          @core.map(divisors, fn(_) { zero(dividend.variables) }),
        ),
      )
  }
}

///|
pub fn normal_form(
  dividend : Polynomial,
  divisors : @core.Chain[Polynomial],
) -> Result[Polynomial, PolyError] {
  remainder_only(dividend, divisors)
}

///|
pub fn monic(p : Polynomial) -> Polynomial {
  match p.terms {
    Nil => p
    Cons(leading, _) =>
      match @exact.nonzero(leading.coefficient) {
        None => p
        Some(coefficient) => {
          let factor = @exact.reciprocal(coefficient)
          {
            variables: p.variables,
            terms: @core.map(p.terms, fn(term) {
              {
                coefficient: @exact.rational_multiply(factor, term.coefficient),
                exponents: term.exponents,
              }
            }),
          }
        }
      }
  }
}

///|
pub fn univariate_gcd(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match
    (
      @core.compare(a.variables, Succ(Zero)),
      @core.compare(b.variables, Succ(Zero)),
    ) {
    (Equal, Equal) =>
      match is_zero(b) {
        true => Ok(monic(a))
        false =>
          match normal_form(a, Cons(b, Nil)) {
            Err(error) => Err(error)
            Ok(remainder) => univariate_gcd(b, remainder)
          }
      }
    _ => Err(DimensionMismatch)
  }
}

///|
pub fn derivative(p : Polynomial, variable : @core.Nat) -> Polynomial? {
  fn decrement(
    exponents : @core.Chain[@core.Nat],
    index : @core.Nat,
  ) -> @core.Chain[@core.Nat] {
    match (exponents, index) {
      (Nil, _) => Nil
      (Cons(Succ(power), rest), Zero) => Cons(power, rest)
      (Cons(power, rest), Succ(index)) => Cons(power, decrement(rest, index))
      _ => exponents
    }
  }
  fn differentiate(terms : @core.Chain[Term]) -> @core.Chain[Term] {
    match terms {
      Nil => Nil
      Cons(term, rest) =>
        match @core.nth(term.exponents, variable) {
          None | Some(Zero) => differentiate(rest)
          Some(Succ(_) as power) =>
            Cons(
              {
                coefficient: @exact.rational_multiply(
                  term.coefficient,
                  @exact.whole(@exact.positive(@binary.from_nat(power))),
                ),
                exponents: decrement(term.exponents, variable),
              },
              differentiate(rest),
            )
        }
    }
  }
  match @core.compare(variable, p.variables) {
    Less => Some({ variables: p.variables, terms: differentiate(p.terms), })
    _ => None
  }
}

///|
fn evaluate_generic(
  p : Polynomial,
  values : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  fn power(
    base : @exact.Rational,
    exponent : @core.Chain[Bool],
  ) -> @exact.Rational {
    match exponent {
      Nil => @exact.rational_one()
      Cons(bit, rest) => {
        let half = power(base, rest)
        let square = @exact.rational_multiply(half, half)
        match bit {
          false => square
          true => @exact.rational_multiply(base, square)
        }
      }
    }
  }
  fn term_value(term : Term) -> @exact.Rational {
    match @core.zip(term.exponents, values) {
      None => @exact.rational_zero()
      Some(pairs) =>
        @core.fold_left(pairs, term.coefficient, fn(product, pair) {
          let (exponent, value) = pair
          @exact.rational_multiply(
            product,
            power(value, @binary.bits(@binary.from_nat(exponent))),
          )
        })
    }
  }
  match @core.compare(p.variables, @core.length(values)) {
    Equal =>
      Some(
        @core.fold_left(p.terms, @exact.rational_zero(), fn(sum, term) {
          @exact.rational_add(sum, term_value(term))
        }),
      )
    _ => None
  }
}
