///|
/// Split at a bit position: value = low + (high shifted by position).
pub fn split_at(value : Number, position : @binary.Binary) -> (Number, Number) {
  fn walk(
    rest : @core.Chain[Run],
    remaining : @binary.Binary,
    low_reversed : @core.Chain[Run],
  ) -> (Number, Number) {
    match (@binary.is_zero(remaining), rest) {
      (true, _) => (finish(low_reversed), { runs: rest, })
      (_, Nil) => (finish(low_reversed), zero())
      (false, Cons(run, tail)) =>
        match @binary.compare(remaining, run.length) {
          Less => {
            let low = finish(push(run.bit, remaining, low_reversed))
            let high = Number::{ runs: consume(rest, remaining), }
            (low, high)
          }
          _ => {
            let low_reversed = push(run.bit, run.length, low_reversed)
            match @binary.subtract(remaining, run.length) {
              None => (finish(low_reversed), zero())
              Some(remaining) => walk(tail, remaining, low_reversed)
            }
          }
        }
    }
  }
  walk(value.runs, position, Nil)
}

///|
fn power_exponent(value : Number) -> @binary.Binary? {
  fn single(
    length : @binary.Binary,
    exponent : @binary.Binary,
  ) -> @binary.Binary? {
    match @binary.compare(length, @binary.one()) {
      Equal => Some(exponent)
      _ => None
    }
  }
  match value.runs {
    Cons({ bit: true, length, }, Nil) => single(length, @binary.zero())
    Cons({ bit: false, length: exponent, }, Cons({ bit: true, length, }, Nil)) =>
      single(length, exponent)
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub struct Division {
  dividend : Number
  divisor : Number
  quotient : Number
  remainder : Number
}

///|
pub extend Division with Eq::{equal, not_equal}

///|
pub extend Division with Debug::{to_repr}

///|
pub fn quotient(result : Division) -> Number {
  result.quotient
}

///|
pub fn remainder(result : Division) -> Number {
  result.remainder
}

///|
/// Independent of the division search: verify the Euclidean identity and bound.
pub fn check_division(
  a : Number,
  b : Number,
  q : Number,
  r : Number,
) -> Division? {
  match (is_zero(b), compare(r, b), compare(add(multiply(q, b), r), a)) {
    (false, Less, Equal) =>
      Some({ dividend: a, divisor: b, quotient: q, remainder: r, })
    _ => None
  }
}

///|
#derive(Eq, Debug)
pub struct DivisionSearch {
  dividend : Number
  divisor : Number
  quotient : Number
  remainder : Number
  transitions : @core.Nat
}

///|
pub extend DivisionSearch with Eq::{equal, not_equal}

///|
pub extend DivisionSearch with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum DivisionStatus {
  Divided(Division)
  DivisionPaused(DivisionSearch)
  DivisionFault(DivisionSearch)
}

///|
pub extend DivisionStatus with Eq::{equal, not_equal}

///|
pub extend DivisionStatus with Debug::{to_repr}

///|
pub fn start_division(a : Number, b : Number) -> DivisionSearch? {
  match is_zero(b) {
    true => None
    false =>
      Some({
        dividend: a,
        divisor: b,
        quotient: zero(),
        remainder: a,
        transitions: Zero,
      })
  }
}

///|
pub fn division_transitions(search : DivisionSearch) -> @core.Nat {
  search.transitions
}

///|
fn finish_division(search : DivisionSearch) -> DivisionStatus {
  match
    check_division(
      search.dividend,
      search.divisor,
      search.quotient,
      search.remainder,
    ) {
    Some(result) => Divided(result)
    None => DivisionFault(search)
  }
}

///|
pub fn step_division(search : DivisionSearch) -> DivisionStatus {
  let search = { ..search, transitions: Succ(search.transitions), }
  match compare(search.remainder, search.divisor) {
    Less => finish_division(search)
    _ =>
      match power_exponent(search.divisor) {
        Some(exponent) => {
          let (low, high) = split_at(search.remainder, exponent)
          finish_division({
            ..search,
            quotient: add(search.quotient, high),
            remainder: low,
          })
        }
        None =>
          match
            @binary.subtract(width(search.remainder), width(search.divisor)) {
            None => DivisionFault(search)
            Some(exponent) => {
              let aligned = shift_left(search.divisor, exponent)
              let chosen = match compare(search.remainder, aligned) {
                Less =>
                  match @binary.subtract(exponent, @binary.one()) {
                    None => None
                    Some(exponent) =>
                      Some((exponent, shift_right(aligned, @binary.one())))
                  }
                _ => Some((exponent, aligned))
              }
              match chosen {
                None => DivisionFault(search)
                Some((exponent, aligned)) =>
                  match subtract(search.remainder, aligned) {
                    None => DivisionFault(search)
                    Some(rest) =>
                      DivisionPaused({
                        ..search,
                        quotient: add(search.quotient, power_of_two(exponent)),
                        remainder: rest,
                      })
                  }
              }
            }
          }
      }
  }
}

///|
/// Fuel counts transitions, not time, output bits, or elementary Boolean steps.
pub fn run_division(
  search : DivisionSearch,
  fuel : @core.Nat,
) -> DivisionStatus {
  match fuel {
    Zero => DivisionPaused(search)
    Succ(rest) =>
      match step_division(search) {
        DivisionPaused(next) => run_division(next, rest)
        result => result
      }
  }
}

///|
/// For nonzero Mersenne operands, gcd(two^a-one,two^b-one)=two^gcd(a,b)-one.
pub fn mersenne_gcd(a : Number, b : Number) -> Number? {
  match (a.runs, b.runs) {
    (
      Cons({ bit: true, length: left, }, Nil),
      Cons({ bit: true, length: right, }, Nil),
    ) =>
      Some({
        runs: Cons({ bit: true, length: @binary.gcd(left, right), }, Nil),
      })
    _ => None
  }
}
