///|
/// A nonempty homogeneous bit block, stored least-significant block first.
/// Public constructors normalize zero lengths, adjacent blocks and high zeros.
#derive(Eq, Debug)
pub(all) struct Run {
  bit : Bool
  length : @binary.Binary
}

///|
pub extend Run with Eq::{equal, not_equal}

///|
pub extend Run with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Number {
  runs : @core.Chain[Run]
}

///|
pub extend Number with Eq::{equal, not_equal}

///|
pub extend Number with Debug::{to_repr}

///|
fn same(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, true) | (false, false) => true
    _ => false
  }
}

///|
// Append one block to a reversed low-to-high result.
fn push(
  bit : Bool,
  length : @binary.Binary,
  reversed : @core.Chain[Run],
) -> @core.Chain[Run] {
  match @binary.is_zero(length) {
    true => reversed
    false =>
      match reversed {
        Cons(previous, rest) =>
          match same(bit, previous.bit) {
            true =>
              Cons({ bit, length: @binary.add(length, previous.length), }, rest)
            false => Cons({ bit, length, }, reversed)
          }
        Nil => Cons({ bit, length, }, Nil)
      }
  }
}

///|
fn finish(reversed : @core.Chain[Run]) -> Number {
  fn trim(rest : @core.Chain[Run]) -> @core.Chain[Run] {
    match rest {
      Cons({ bit: false, .. }, tail) => trim(tail)
      _ => rest
    }
  }
  { runs: @core.reverse(trim(reversed)), }
}

///|
pub fn from_runs(runs : @core.Chain[Run]) -> Number {
  finish(
    @core.fold_left(runs, Nil, fn(reversed, run) {
      push(run.bit, run.length, reversed)
    }),
  )
}

///|
pub fn runs(value : Number) -> @core.Chain[Run] {
  value.runs
}

///|
pub fn zero() -> Number {
  { runs: Nil, }
}

///|
pub fn one() -> Number {
  { runs: Cons({ bit: true, length: @binary.one(), }, Nil), }
}

///|
pub fn is_zero(value : Number) -> Bool {
  match value.runs {
    Nil => true
    _ => false
  }
}

///|
pub fn width(value : Number) -> @binary.Binary {
  @core.fold_left(value.runs, @binary.zero(), fn(total, run) {
    @binary.add(total, run.length)
  })
}

///|
pub fn from_binary(value : @binary.Binary) -> Number {
  finish(
    @core.fold_left(@binary.bits(value), Nil, fn(reversed, bit) {
      push(bit, @binary.one(), reversed)
    }),
  )
}

///|
/// Expansion is explicit and limited by the caller's maximum bit count.
pub fn expand(value : Number, maximum_bits : @binary.Binary) -> @binary.Binary? {
  match @binary.compare(width(value), maximum_bits) {
    Greater => None
    _ => {
      let reversed : @core.Chain[Bool] = @core.fold_left(
        value.runs,
        @core.Nil,
        fn(reversed, run) {
          @core.reverse_onto(
            @core.replicate(@binary.to_nat(run.length), run.bit),
            reversed,
          )
        },
      )
      Some(@binary.from_bits(@core.reverse(reversed)))
    }
  }
}

///|
pub fn shift_left(value : Number, amount : @binary.Binary) -> Number {
  match (@binary.is_zero(amount), value.runs) {
    (true, _) | (_, Nil) => value
    (false, Cons({ bit: false, length, }, rest)) =>
      {
        runs: Cons({ bit: false, length: @binary.add(length, amount), }, rest),
      }
    (false, _) => { runs: Cons({ bit: false, length: amount, }, value.runs), }
  }
}

///|
pub fn shift_right(value : Number, amount : @binary.Binary) -> Number {
  fn walk(
    rest : @core.Chain[Run],
    remaining : @binary.Binary,
  ) -> @core.Chain[Run] {
    match rest {
      Nil => Nil
      Cons(run, tail) =>
        match @binary.compare(remaining, run.length) {
          Less =>
            match @binary.subtract(run.length, remaining) {
              Some(length) => Cons({ bit: run.bit, length, }, tail)
              None => Nil
            }
          Equal => tail
          Greater =>
            match @binary.subtract(remaining, run.length) {
              Some(remaining) => walk(tail, remaining)
              None => Nil
            }
        }
    }
  }
  { runs: walk(value.runs, amount), }
}

///|
// All internal callers consume at most the current nonzero block length.
fn consume(
  rest : @core.Chain[Run],
  amount : @binary.Binary,
) -> @core.Chain[Run] {
  match rest {
    Nil => Nil
    Cons(run, tail) =>
      match @binary.subtract(run.length, amount) {
        Some(length) =>
          match @binary.is_zero(length) {
            true => tail
            false => Cons({ bit: run.bit, length, }, tail)
          }
        None => Nil
      }
  }
}

///|
fn minimum(a : @binary.Binary, b : @binary.Binary) -> @binary.Binary {
  match @binary.compare(a, b) {
    Greater => b
    _ => a
  }
}

///|
pub fn compare(a : Number, b : Number) -> @core.Ordering {
  fn high(xs : @core.Chain[Run], ys : @core.Chain[Run]) -> @core.Ordering {
    match (xs, ys) {
      (Nil, Nil) => Equal
      (Nil, _) => Less
      (_, Nil) => Greater
      (Cons(x, _), Cons(y, _)) =>
        match (x.bit, y.bit) {
          (false, true) => Less
          (true, false) => Greater
          _ => {
            let amount = minimum(x.length, y.length)
            high(consume(xs, amount), consume(ys, amount))
          }
        }
    }
  }
  match @binary.compare(width(a), width(b)) {
    Equal => high(@core.reverse(a.runs), @core.reverse(b.runs))
    result => result
  }
}

///|
priv enum Operation {
  Addition
  Difference
}

///|
fn digit(
  operation : Operation,
  a : Bool,
  b : Bool,
  flag : Bool,
) -> (Bool, Bool) {
  match operation {
    Addition => @binary.full_adder(a, b, flag)
    Difference => {
      let (sum, carry) = @binary.full_adder(a, !b, !flag)
      (sum, !carry)
    }
  }
}

///|
// For a homogeneous input block the carry/borrow stabilizes after one bit.
// Emit the first output, then the entire remaining constant block at once.
fn combine(operation : Operation, a : Number, b : Number) -> Number {
  fn walk(
    xs : @core.Chain[Run],
    ys : @core.Chain[Run],
    flag : Bool,
    reversed : @core.Chain[Run],
  ) -> Number {
    match (xs, ys) {
      (Nil, Nil) => {
        let reversed = match (operation, flag) {
          (Addition, true) => push(true, @binary.one(), reversed)
          _ => reversed
        }
        finish(reversed)
      }
      _ => {
        let (x, y, amount) = match (xs, ys) {
          (Cons(x, _), Cons(y, _)) =>
            (x.bit, y.bit, minimum(x.length, y.length))
          (Cons(x, _), Nil) => (x.bit, false, x.length)
          (Nil, Cons(y, _)) => (false, y.bit, y.length)
          _ => (false, false, @binary.zero())
        }
        let (first, next) = digit(operation, x, y, flag)
        let (later, _) = digit(operation, x, y, next)
        let reversed = push(first, @binary.one(), reversed)
        let reversed = match @binary.subtract(amount, @binary.one()) {
          Some(rest) => push(later, rest, reversed)
          None => reversed
        }
        walk(consume(xs, amount), consume(ys, amount), next, reversed)
      }
    }
  }
  walk(a.runs, b.runs, false, Nil)
}

///|
pub fn add(a : Number, b : Number) -> Number {
  combine(Addition, a, b)
}

///|
pub fn successor(value : Number) -> Number {
  add(value, one())
}

///|
pub fn subtract(a : Number, b : Number) -> Number? {
  match compare(a, b) {
    Less => None
    _ => Some(combine(Difference, a, b))
  }
}

///|
/// Each one-run contributes value * (two^length - one) * two^offset.
pub fn multiply(a : Number, b : Number) -> Number {
  let (result, _) = @core.fold_left(b.runs, (zero(), @binary.zero()), fn(
    state,
    run,
  ) {
    let (result, offset) = state
    let result = match run.bit {
      false => result
      true => {
        let low = shift_left(a, offset)
        let high = shift_left(low, run.length)
        add(result, combine(Difference, high, low))
      }
    }
    (result, @binary.add(offset, run.length))
  })
  result
}

///|
pub fn power_of_two(exponent : @binary.Binary) -> Number {
  shift_left(one(), exponent)
}

///|
/// A positive pairing code: two^a * (two*b + one), without expanding zeros.
pub fn pair(a : @binary.Binary, b : Number) -> Number {
  shift_left(successor(shift_left(b, @binary.one())), a)
}

///|
pub fn unpair(value : Number) -> (@binary.Binary, Number)? {
  match value.runs {
    Nil => None
    Cons(run, _) => {
      let exponent = match run.bit {
        true => @binary.zero()
        false => run.length
      }
      let odd = shift_right(value, exponent)
      Some((exponent, shift_right(odd, @binary.one())))
    }
  }
}
