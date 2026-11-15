///|
/// Only completed Buchberger computations construct a Basis.
#derive(Eq, Debug)
pub struct Basis {
  variables : @core.Nat
  polynomials : @core.Chain[@poly.Polynomial]
}

///|
pub extend Basis with Eq::{equal, not_equal}

///|
pub extend Basis with Debug::{to_repr}

///|
/// An explicit, resumable S-pair queue.
#derive(Eq, Debug)
pub struct State {
  variables : @core.Nat
  candidates : @core.Chain[@poly.Polynomial]
  pairs : @core.Chain[(@poly.Polynomial, @poly.Polynomial)]
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Basis)
  Paused(State)
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn polynomials(basis : Basis) -> @core.Chain[@poly.Polynomial] {
  basis.polynomials
}

///|
pub fn pending(state : State) -> @core.Nat {
  @core.length(state.pairs)
}

///|
fn pairs(
  polynomials : @core.Chain[@poly.Polynomial],
) -> @core.Chain[(@poly.Polynomial, @poly.Polynomial)] {
  match polynomials {
    Nil => Nil
    Cons(p, rest) =>
      @core.append(@core.map(rest, fn(q) { (p, q) }), pairs(rest))
  }
}

///|
/// Cancel leading terms with LCM monomials and exact inverse coefficients.
pub fn s_polynomial(
  a : @poly.Polynomial,
  b : @poly.Polynomial,
) -> Result[@poly.Polynomial, @poly.PolyError] {
  match @core.compare(@poly.variables(a), @poly.variables(b)) {
    Equal =>
      match (@poly.terms(a), @poly.terms(b)) {
        (Cons(left, _), Cons(right, _)) =>
          match @poly.monomial_lcm(left.exponents, right.exponents) {
            None => Err(DimensionMismatch)
            Some(lcm) =>
              match
                (
                  @poly.monomial_quotient(lcm, left.exponents),
                  @poly.monomial_quotient(lcm, right.exponents),
                  @exact.nonzero(left.coefficient),
                  @exact.nonzero(right.coefficient),
                ) {
                (Some(lx), Some(rx), Some(lc), Some(rc)) => {
                  let left_scale : @poly.Term = {
                    coefficient: @exact.reciprocal(lc),
                    exponents: lx,
                  }
                  let right_scale : @poly.Term = {
                    coefficient: @exact.reciprocal(rc),
                    exponents: rx,
                  }
                  match
                    (@poly.scale(a, left_scale), @poly.scale(b, right_scale)) {
                    (Ok(a), Ok(b)) => @poly.subtract(a, b)
                    (Err(error), _) | (_, Err(error)) => Err(error)
                  }
                }
                _ => Err(ZeroDivisor)
              }
          }
        _ => Err(ZeroDivisor)
      }
    _ => Err(DimensionMismatch)
  }
}

///|
pub fn start(
  variables : @core.Nat,
  generators : @core.Chain[@poly.Polynomial],
) -> Result[State, @poly.PolyError] {
  match
    @core.all(generators, fn(p) {
      match @core.compare(@poly.variables(p), variables) {
        Equal => true
        _ => false
      }
    }) {
    false => Err(DimensionMismatch)
    true => {
      let candidates = @core.map(
        @core.filter(generators, fn(p) {
          match @poly.is_zero(p) {
            true => false
            false => true
          }
        }),
        @poly.monic,
      )
      Ok({ variables, candidates, pairs: pairs(candidates), })
    }
  }
}

///|
fn leading_divides(a : @poly.Polynomial, b : @poly.Polynomial) -> Bool {
  match (@poly.terms(a), @poly.terms(b)) {
    (Cons(x, _), Cons(y, _)) => @poly.divides(x.exponents, y.exponents)
    _ => false
  }
}

///|
/// Input must already be a Groebner basis. First retain minimal leading
/// monomials, then reduce every remaining polynomial against all the others.
fn reduced(
  candidates : @core.Chain[@poly.Polynomial],
) -> Result[@core.Chain[@poly.Polynomial], @poly.PolyError] {
  fn minimal(
    todo : @core.Chain[@poly.Polynomial],
    kept : @core.Chain[@poly.Polynomial],
  ) -> @core.Chain[@poly.Polynomial] {
    match todo {
      Nil => @core.reverse(kept)
      Cons(p, rest) =>
        match
          @core.any(@core.append(rest, kept), fn(q) { leading_divides(q, p) }) {
          true => minimal(rest, kept)
          false => minimal(rest, Cons(p, kept))
        }
    }
  }
  fn interreduce(
    todo : @core.Chain[@poly.Polynomial],
    prefix : @core.Chain[@poly.Polynomial],
  ) -> Result[@core.Chain[@poly.Polynomial], @poly.PolyError] {
    match todo {
      Nil => Ok(Nil)
      Cons(p, rest) =>
        match @poly.normal_form(p, @core.reverse_onto(prefix, rest)) {
          Err(error) => Err(error)
          Ok(normal) =>
            match interreduce(rest, Cons(p, prefix)) {
              Err(error) => Err(error)
              Ok(tail) => Ok(Cons(@poly.monic(normal), tail))
            }
        }
    }
  }
  match interreduce(minimal(candidates, Nil), Nil) {
    Err(error) => Err(error)
    Ok(normal) =>
      Ok(
        @sorting.merge_sort(normal, fn(a, b) {
          match (@poly.terms(a), @poly.terms(b)) {
            (Cons(x, _), Cons(y, _)) =>
              match @poly.compare_monomial(x.exponents, y.exponents) {
                Less => Greater
                Greater => Less
                Equal => Equal
              }
            _ => Equal
          }
        }),
      )
  }
}

///|
/// One S-pair reduction; an empty queue performs final interreduction.
pub fn step(state : State) -> Result[Progress, @poly.PolyError] {
  match state.pairs {
    Nil =>
      match reduced(state.candidates) {
        Err(error) => Err(error)
        Ok(polynomials) =>
          Ok(Complete({ variables: state.variables, polynomials, }))
      }
    Cons((a, b), rest) =>
      match s_polynomial(a, b) {
        Err(error) => Err(error)
        Ok(s) =>
          match @poly.normal_form(s, state.candidates) {
            Err(error) => Err(error)
            Ok(remainder) =>
              match @poly.is_zero(remainder) {
                true =>
                  Ok(
                    Paused({
                      variables: state.variables,
                      candidates: state.candidates,
                      pairs: rest,
                    }),
                  )
                false => {
                  let new = @poly.monic(remainder)
                  let extra = @core.map(state.candidates, fn(old) { (new, old) })
                  Ok(
                    Paused({
                      variables: state.variables,
                      candidates: Cons(new, state.candidates),
                      pairs: @core.append(extra, rest),
                    }),
                  )
                }
              }
          }
      }
  }
}

///|
/// Fuel counts S-pair reductions plus one finalization. A single polynomial
/// reduction may be expensive, so this is not a wall-time or allocation limit.
pub fn run(
  state : State,
  fuel : @core.Nat,
) -> Result[Progress, @poly.PolyError] {
  match fuel {
    Zero => Ok(Paused(state))
    Succ(rest) =>
      match step(state) {
        Err(error) => Err(error)
        Ok(Paused(next)) => run(next, rest)
        Ok(Complete(basis)) => Ok(Complete(basis))
      }
  }
}

///|
pub fn buchberger(
  variables : @core.Nat,
  generators : @core.Chain[@poly.Polynomial],
  fuel : @core.Nat,
) -> Result[Progress, @poly.PolyError] {
  match start(variables, generators) {
    Err(error) => Err(error)
    Ok(state) => run(state, fuel)
  }
}

///|
pub fn normal_form(
  basis : Basis,
  p : @poly.Polynomial,
) -> Result[@poly.Polynomial, @poly.PolyError] {
  match @core.compare(basis.variables, @poly.variables(p)) {
    Equal => @poly.normal_form(p, basis.polynomials)
    _ => Err(DimensionMismatch)
  }
}

///|
/// Buchberger's criterion; verifies the S-pairs without running the search.
pub fn verify(basis : Basis) -> Result[Bool, @poly.PolyError] {
  fn check(
    pending : @core.Chain[(@poly.Polynomial, @poly.Polynomial)],
  ) -> Result[Bool, @poly.PolyError] {
    match pending {
      Nil => Ok(true)
      Cons((a, b), rest) =>
        match s_polynomial(a, b) {
          Err(error) => Err(error)
          Ok(s) =>
            match normal_form(basis, s) {
              Err(error) => Err(error)
              Ok(remainder) =>
                match @poly.is_zero(remainder) {
                  true => check(rest)
                  false => Ok(false)
                }
            }
        }
    }
  }
  check(pairs(basis.polynomials))
}
