///|
#derive(Eq, Debug)
pub(all) enum BuildError {
  NotUnivariate
  ZeroPolynomial
  PolynomialFailure
}

///|
pub extend BuildError with Eq::{equal, not_equal}

///|
pub extend BuildError with Debug::{to_repr}

///|
/// Squarefree polynomial and its signed Euclidean Sturm sequence.
#derive(Eq, Debug)
pub struct System {
  squarefree : @polynomial.Polynomial
  sequence : @core.Chain[@polynomial.Polynomial]
}

///|
pub extend System with Eq::{equal, not_equal}

///|
pub extend System with Debug::{to_repr}

///|
pub fn system(p : @polynomial.Polynomial) -> Result[System, BuildError] {
  fn sequence(
    a : @polynomial.Polynomial,
    b : @polynomial.Polynomial,
  ) -> @core.Chain[@polynomial.Polynomial]? {
    match @polynomial.is_zero(b) {
      true => Some(Cons(a, Nil))
      false =>
        match @polynomial.normal_form(a, Cons(b, Nil)) {
          Err(_) => None
          Ok(remainder) =>
            match sequence(b, @polynomial.negate(remainder)) {
              None => None
              Some(rest) => Some(Cons(a, rest))
            }
        }
    }
  }
  match
    (
      @core.compare(@polynomial.variables(p), Succ(Zero)),
      @polynomial.is_zero(p),
    ) {
    (_, true) => Err(ZeroPolynomial)
    (Equal, false) =>
      match @polynomial.derivative(p, Zero) {
        None => Err(PolynomialFailure)
        Some(derivative) =>
          match @polynomial.univariate_gcd(p, derivative) {
            Err(_) => Err(PolynomialFailure)
            Ok(gcd) =>
              match @polynomial.divide(p, Cons(gcd, Nil)) {
                Ok({ quotients: Cons(quotient, Nil), remainder, }) =>
                  match @polynomial.is_zero(remainder) {
                    false => Err(PolynomialFailure)
                    true => {
                      let squarefree = @polynomial.monic(quotient)
                      match @polynomial.derivative(squarefree, Zero) {
                        None => Err(PolynomialFailure)
                        Some(derivative) =>
                          match sequence(squarefree, derivative) {
                            None => Err(PolynomialFailure)
                            Some(sequence) => Ok({ squarefree, sequence, })
                          }
                      }
                    }
                  }
                _ => Err(PolynomialFailure)
              }
          }
      }
    _ => Err(NotUnivariate)
  }
}

///|
pub fn squarefree(system : System) -> @polynomial.Polynomial {
  system.squarefree
}

///|
fn variations(signs : @core.Chain[@core.Ordering]) -> @core.Nat {
  fn scan(
    signs : @core.Chain[@core.Ordering],
    previous : @core.Ordering,
    count : @core.Nat,
  ) -> @core.Nat {
    match signs {
      Nil => count
      Cons(Equal, rest) => scan(rest, previous, count)
      Cons(sign, rest) =>
        match (previous, sign) {
          (Less, Greater) | (Greater, Less) => scan(rest, sign, Succ(count))
          _ => scan(rest, sign, count)
        }
    }
  }
  scan(signs, Equal, Zero)
}

///|
fn at(system : System, x : @exact.Rational) -> @core.Nat {
  variations(
    @core.map(system.sequence, fn(p) {
      match @polynomial.evaluate(p, Cons(x, Nil)) {
        None => Equal
        Some(value) => @exact.rational_compare(value, @exact.rational_zero())
      }
    }),
  )
}

///|
fn odd(n : @core.Nat) -> Bool {
  match n {
    Zero => false
    Succ(n) => !odd(n)
  }
}

///|
fn at_infinity(system : System, negative : Bool) -> @core.Nat {
  variations(
    @core.map(system.sequence, fn(p) {
      match @polynomial.terms(p) {
        Nil => Equal
        Cons(term, _) => {
          let sign = @exact.rational_compare(
            term.coefficient,
            @exact.rational_zero(),
          )
          match term.exponents {
            Cons(degree, Nil) =>
              match negative && odd(degree) {
                false => sign
                true =>
                  match sign {
                    Less => Greater
                    Greater => Less
                    Equal => Equal
                  }
              }
            _ => Equal
          }
        }
      }
    }),
  )
}

///|
/// Number of distinct real roots, counting repeated roots once.
pub fn count_all(system : System) -> @core.Nat {
  @core.subtract(at_infinity(system, true), at_infinity(system, false))
}

///|
/// Exactly the half-open interval (lower, upper], including a root at upper.
/// Squarefree reduction makes zero-skipping variations valid at root endpoints.
pub fn count_between(
  system : System,
  lower : @exact.Rational,
  upper : @exact.Rational,
) -> @core.Nat? {
  match @exact.rational_compare(lower, upper) {
    Less => Some(@core.subtract(at(system, lower), at(system, upper)))
    _ => None
  }
}

///|
fn absolute(x : @exact.Rational) -> @exact.Rational {
  match @exact.rational_compare(x, @exact.rational_zero()) {
    Less => @exact.rational_negate(x)
    _ => x
  }
}

///|
/// Cauchy bound 1+max absolute nonleading coefficient of the monic squarefree part.
pub fn bound(system : System) -> @exact.Rational {
  let rest : @core.Chain[@polynomial.Term] = match
    @polynomial.terms(system.squarefree) {
    Nil => Nil
    Cons(_, rest) => rest
  }
  let maximum = @core.fold_left(rest, @exact.rational_zero(), fn(best, term) {
    let value = absolute(term.coefficient)
    match @exact.rational_compare(value, best) {
      Greater => value
      _ => best
    }
  })
  @exact.rational_add(@exact.rational_one(), maximum)
}

///|
#derive(Eq, Debug)
pub(all) struct Interval {
  lower : @exact.Rational
  upper : @exact.Rational
}

///|
pub extend Interval with Eq::{equal, not_equal}

///|
pub extend Interval with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Span {
  interval : Interval
  lower_variations : @core.Nat
  upper_variations : @core.Nat
}

///|
pub extend Span with Eq::{equal, not_equal}

///|
pub extend Span with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Isolation {
  system : System
  pending : @core.Chain[Span]
  accepted : @core.Chain[Interval]
}

///|
pub extend Isolation with Eq::{equal, not_equal}

///|
pub extend Isolation with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Isolated(@core.Chain[Interval])
  Paused(Isolation)
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn isolate(system : System) -> Isolation {
  let upper = bound(system)
  let lower = @exact.rational_negate(upper)
  {
    system,
    pending: Cons(
      {
        interval: { lower, upper, },
        lower_variations: at(system, lower),
        upper_variations: at(system, upper),
      },
      Nil,
    ),
    accepted: Nil,
  }
}

///|
/// Fuel counts interval nodes; polynomial evaluation and rational arithmetic are within a node.
pub fn advance(state : Isolation, fuel : @core.Nat) -> Progress {
  match state.pending {
    Nil => Isolated(@core.reverse(state.accepted))
    Cons(span, rest) =>
      match fuel {
        Zero => Paused(state)
        Succ(fuel) =>
          match @core.subtract(span.lower_variations, span.upper_variations) {
            Zero => advance({ ..state, pending: rest, }, fuel)
            Succ(Zero) =>
              advance(
                {
                  ..state,
                  pending: rest,
                  accepted: Cons(span.interval, state.accepted),
                },
                fuel,
              )
            Succ(Succ(_)) => {
              let middle = @exact.rational_half(
                @exact.rational_add(span.interval.lower, span.interval.upper),
              )
              let changes = at(state.system, middle)
              let left : Span = {
                interval: { lower: span.interval.lower, upper: middle, },
                lower_variations: span.lower_variations,
                upper_variations: changes,
              }
              let right : Span = {
                interval: { lower: middle, upper: span.interval.upper, },
                lower_variations: changes,
                upper_variations: span.upper_variations,
              }
              advance(
                { ..state, pending: Cons(left, Cons(right, rest)), },
                fuel,
              )
            }
          }
      }
  }
}

///|
/// Narrow an interval already containing exactly one distinct root by bisection.
pub fn refine(
  system : System,
  interval : Interval,
  steps : @core.Nat,
) -> Interval? {
  fn bisect(interval : Interval, steps : @core.Nat) -> Interval {
    match steps {
      Zero => interval
      Succ(rest) => {
        let middle = @exact.rational_half(
          @exact.rational_add(interval.lower, interval.upper),
        )
        match @core.subtract(at(system, interval.lower), at(system, middle)) {
          Zero => bisect({ lower: middle, upper: interval.upper, }, rest)
          _ => bisect({ lower: interval.lower, upper: middle, }, rest)
        }
      }
    }
  }
  match count_between(system, interval.lower, interval.upper) {
    Some(Succ(Zero)) => Some(bisect(interval, steps))
    _ => None
  }
}

///|
/// Check sorted disjoint single-root intervals and coverage of all distinct real roots.
/// Re-evaluates Sturm counts; does not repeat the isolation search.
pub fn check_isolation(
  system : System,
  intervals : @core.Chain[Interval],
) -> Bool {
  fn ordered(
    intervals : @core.Chain[Interval],
    previous : @exact.Rational?,
  ) -> Bool {
    match intervals {
      Nil => true
      Cons(interval, rest) => {
        let separate = match previous {
          None => true
          Some(upper) =>
            match @exact.rational_compare(upper, interval.lower) {
              Greater => false
              _ => true
            }
        }
        match
          (separate, count_between(system, interval.lower, interval.upper)) {
          (true, Some(Succ(Zero))) => ordered(rest, Some(interval.upper))
          _ => false
        }
      }
    }
  }
  match @core.compare(@core.length(intervals), count_all(system)) {
    Equal => ordered(intervals, None)
    _ => false
  }
}
