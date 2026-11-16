///|
#derive(Eq, Debug)
pub(all) enum FglmError {
  InvalidSource
  PositiveDimension
  DimensionMismatch
  ZeroDivisor
  InternalInvariant
}

///|
pub extend FglmError with Eq::{equal, not_equal}

///|
pub extend FglmError with Debug::{to_repr}

///|
/// Variable order is fixed: the first variable is largest in all three orders.
#derive(Eq, Debug)
pub(all) enum Order {
  Lex
  GradedLex
  GrevLex
}

///|
pub extend Order with Eq::{equal, not_equal}

///|
pub extend Order with Debug::{to_repr}

///|
fn[A] polynomial_result(
  value : Result[A, @poly.PolyError],
) -> Result[A, FglmError] {
  match value {
    Ok(value) => Ok(value)
    Err(@poly.DimensionMismatch) => Err(DimensionMismatch)
    Err(@poly.ZeroDivisor) => Err(ZeroDivisor)
  }
}

///|
fn total_degree(value : @core.Chain[@core.Nat]) -> @core.Nat {
  @core.fold_left(value, Zero, @core.add)
}

///|
fn reverse_order(value : @core.Ordering) -> @core.Ordering {
  match value {
    Less => Greater
    Greater => Less
    Equal => Equal
  }
}

///|
/// Compare exponent vectors of the same dimension under an admissible order.
pub fn compare_monomial(
  order : Order,
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match order {
    Lex => @poly.compare_monomial(a, b)
    GradedLex | GrevLex =>
      match @core.compare(total_degree(a), total_degree(b)) {
        Equal =>
          match order {
            GrevLex =>
              reverse_order(
                @poly.compare_monomial(@core.reverse(a), @core.reverse(b)),
              )
            _ => @poly.compare_monomial(a, b)
          }
        other => other
      }
  }
}

///|
/// Polynomial storage remains canonical lex; target leading selection is separate.
pub fn leading(order : Order, value : @poly.Polynomial) -> @poly.Term? {
  @core.fold_left(@poly.terms(value), None, fn(best, term) {
    match best {
      None => Some(term)
      Some(previous) =>
        if compare_monomial(order, term.exponents, previous.exponents).equal(
            Greater,
          ) {
          Some(term)
        } else {
          best
        }
    }
  })
}

///|
fn monomial(
  variables : @core.Nat,
  exponents : @core.Chain[@core.Nat],
) -> Result[@poly.Polynomial, FglmError] {
  polynomial_result(
    @poly.polynomial(
      variables,
      Cons({ coefficient: @exact.rational_one(), exponents, }, Nil),
    ),
  )
}

///|
pub fn normal_form(
  order : Order,
  value : @poly.Polynomial,
  divisors : @core.Chain[@poly.Polynomial],
) -> Result[@poly.Polynomial, FglmError] {
  let variables = @poly.variables(value)
  if !@core.all(divisors, fn(p) {
      @core.compare(@poly.variables(p), variables).equal(Equal)
    }) {
    return Err(DimensionMismatch)
  }
  if @core.any(divisors, @poly.is_zero) {
    return Err(ZeroDivisor)
  }
  fn find(
    todo : @core.Chain[@poly.Polynomial],
    term : @poly.Term,
  ) -> (@poly.Polynomial, @poly.Term)? {
    match todo {
      Nil => None
      Cons(p, rest) =>
        match leading(order, p) {
          None => None
          Some(head) =>
            match
              (
                @poly.monomial_quotient(term.exponents, head.exponents),
                @exact.nonzero(head.coefficient),
              ) {
              (Some(exponents), Some(coefficient)) =>
                Some(
                  (
                    p,
                    {
                      coefficient: @exact.rational_multiply(
                        term.coefficient,
                        @exact.reciprocal(coefficient),
                      ),
                      exponents,
                    },
                  ),
                )
              _ => find(rest, term)
            }
        }
    }
  }
  fn reduce(
    todo : @poly.Polynomial,
    remainder : @poly.Polynomial,
  ) -> Result[@poly.Polynomial, FglmError] {
    match leading(order, todo) {
      None => Ok(remainder)
      Some(term) =>
        match find(divisors, term) {
          Some((p, multiplier)) =>
            match @poly.scale(p, multiplier) {
              Err(_) => Err(InternalInvariant)
              Ok(multiple) =>
                match @poly.subtract(todo, multiple) {
                  Err(_) => Err(InternalInvariant)
                  Ok(next) => reduce(next, remainder)
                }
            }
          None =>
            match @poly.polynomial(variables, Cons(term, Nil)) {
              Err(_) => Err(InternalInvariant)
              Ok(head) =>
                match (@poly.subtract(todo, head), @poly.add(remainder, head)) {
                  (Ok(next), Ok(remainder)) => reduce(next, remainder)
                  _ => Err(InternalInvariant)
                }
            }
        }
    }
  }
  reduce(value, @poly.zero(variables))
}

///|
pub fn s_polynomial(
  order : Order,
  a : @poly.Polynomial,
  b : @poly.Polynomial,
) -> Result[@poly.Polynomial, FglmError] {
  if !@core.compare(@poly.variables(a), @poly.variables(b)).equal(Equal) {
    return Err(DimensionMismatch)
  }
  match (leading(order, a), leading(order, b)) {
    (Some(x), Some(y)) =>
      match @poly.monomial_lcm(x.exponents, y.exponents) {
        None => Err(DimensionMismatch)
        Some(lcm) =>
          match
            (
              @poly.monomial_quotient(lcm, x.exponents),
              @poly.monomial_quotient(lcm, y.exponents),
              @exact.nonzero(x.coefficient),
              @exact.nonzero(y.coefficient),
            ) {
            (Some(lx), Some(rx), Some(lc), Some(rc)) =>
              match
                (
                  @poly.scale(a, {
                    coefficient: @exact.reciprocal(lc),
                    exponents: lx,
                  }),
                  @poly.scale(b, {
                    coefficient: @exact.reciprocal(rc),
                    exponents: rx,
                  }),
                ) {
                (Ok(a), Ok(b)) => polynomial_result(@poly.subtract(a, b))
                _ => Err(InternalInvariant)
              }
            _ => Err(InternalInvariant)
          }
      }
    _ => Err(ZeroDivisor)
  }
}
