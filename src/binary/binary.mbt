///|
/// Canonical little-endian Bool list; Nil is zero, highest stored bit is true.
#derive(Eq, Debug)
pub struct Binary {
  bits : @core.Chain[Bool]
}

///|
pub extend Binary with Eq::{equal, not_equal}

///|
pub extend Binary with Debug::{to_repr}

///|
fn trim(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Nil
    Cons(bit, rest) => {
      let tail = trim(rest)
      match (bit, tail) {
        (false, Nil) => Nil
        _ => Cons(bit, tail)
      }
    }
  }
}

///|
pub fn from_bits(bits : @core.Chain[Bool]) -> Binary {
  { bits: trim(bits), }
}

///|
pub fn bits(n : Binary) -> @core.Chain[Bool] {
  n.bits
}

///|
pub fn zero() -> Binary {
  { bits: Nil, }
}

///|
pub fn one() -> Binary {
  { bits: Cons(true, Nil), }
}

///|
pub fn is_zero(n : Binary) -> Bool {
  match n.bits {
    Nil => true
    Cons(_, _) => false
  }
}

///|
/// (sum, carry). The full truth table is the arithmetic primitive.
pub fn full_adder(a : Bool, b : Bool, carry : Bool) -> (Bool, Bool) {
  match (a, b, carry) {
    (false, false, false) => (false, false)
    (false, false, true) | (false, true, false) | (true, false, false) =>
      (true, false)
    (true, true, true) => (true, true)
    _ => (false, true)
  }
}

///|
fn add_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  carry : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, next) = full_adder(x, y, carry)
      Cons(s, add_bits(xt, yt, next))
    }
    (rest, Nil) | (Nil, rest) =>
      match carry {
        false => rest
        true => increment_bits(rest)
      }
  }
}

///|
pub fn add(a : Binary, b : Binary) -> Binary {
  { bits: add_bits(a.bits, b.bits, false), }
}

///|
pub fn successor(n : Binary) -> Binary {
  { bits: increment_bits(n.bits), }
}

///|
fn increment_bits(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Cons(true, Nil)
    Cons(false, rest) => Cons(true, rest)
    Cons(true, rest) => Cons(false, increment_bits(rest))
  }
}

///|
fn compare_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> @core.Ordering {
  match (xs, ys) {
    (Nil, Nil) => Equal
    (Nil, Cons(_, _)) => Less
    (Cons(_, _), Nil) => Greater
    (Cons(x, xt), Cons(y, yt)) =>
      match compare_bits(xt, yt) {
        Equal =>
          match (x, y) {
            (false, true) => Less
            (true, false) => Greater
            _ => Equal
          }
        order => order
      }
  }
}

///|
pub fn compare(a : Binary, b : Binary) -> @core.Ordering {
  compare_bits(a.bits, b.bits)
}

///|
fn negate_bit(x : Bool) -> Bool {
  match x {
    true => false
    false => true
  }
}

///|
fn subtract_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  borrow : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Nil, _) => Nil
    (Cons(x, xt), Nil) => {
      let (s, carry) = full_adder(x, true, negate_bit(borrow))
      Cons(s, subtract_bits(xt, Nil, negate_bit(carry)))
    }
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, carry) = full_adder(x, negate_bit(y), negate_bit(borrow))
      Cons(s, subtract_bits(xt, yt, negate_bit(carry)))
    }
  }
}

///|
/// Underflow is explicit, rather than silently saturating or wrapping.
pub fn subtract(a : Binary, b : Binary) -> Binary? {
  match compare(a, b) {
    Less => None
    _ => Some(from_bits(subtract_bits(a.bits, b.bits, false)))
  }
}

///|
fn low_bit(bit : Bool, rest : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match (bit, rest) {
    (false, Nil) => Nil
    _ => Cons(bit, rest)
  }
}

///|
pub fn double(n : Binary) -> Binary {
  { bits: low_bit(false, n.bits), }
}

///|
pub fn half(n : Binary) -> Binary {
  match n.bits {
    Nil => n
    Cons(_, tail) => { bits: tail, }
  }
}

///|
pub fn odd(n : Binary) -> Bool {
  match n.bits {
    Nil => false
    Cons(bit, _) => bit
  }
}

///|
fn multiply_bits(xs : @core.Chain[Bool], b : Binary) -> Binary {
  match xs {
    Nil => zero()
    Cons(bit, rest) => {
      let shifted = double(multiply_bits(rest, b))
      match bit {
        false => shifted
        true => add(b, shifted)
      }
    }
  }
}

///|
pub fn multiply(a : Binary, b : Binary) -> Binary {
  multiply_bits(a.bits, b)
}

///|
/// Long division consumes high bits first via recursive descent.
fn divide_bits(xs : @core.Chain[Bool], divisor : Binary) -> (Binary, Binary) {
  match xs {
    Nil => (zero(), zero())
    Cons(bit, rest) => {
      let (q, r) = divide_bits(rest, divisor)
      let next : Binary = { bits: low_bit(bit, r.bits), }
      match compare(next, divisor) {
        Less => (double(q), next)
        _ => {
          let reduced = from_bits(subtract_bits(next.bits, divisor.bits, false))
          ({ bits: Cons(true, q.bits), }, reduced)
        }
      }
    }
  }
}

///|
pub fn divmod(a : Binary, b : Binary) -> (Binary, Binary)? {
  match b.bits {
    Nil => None
    Cons(_, _) => Some(divide_bits(a.bits, b))
  }
}

///|
pub fn gcd(a : Binary, b : Binary) -> Binary {
  match b.bits {
    Nil => a
    Cons(_, _) => {
      let (_, r) = divide_bits(a.bits, b)
      gcd(b, r)
    }
  }
}

///|
/// Exponentiation by squaring, with a binary exponent.
pub fn power(base : Binary, exponent : Binary) -> Binary {
  match exponent.bits {
    Nil => one()
    Cons(bit, rest) => {
      let p = power(base, { bits: rest, })
      let square = multiply(p, p)
      match bit {
        false => square
        true => multiply(base, square)
      }
    }
  }
}

///|
pub fn from_nat(n : @core.Nat) -> Binary {
  fn split(value : @core.Nat, half : @core.Nat) -> (@core.Nat, Bool) {
    match value {
      Zero => (half, false)
      Succ(Zero) => (half, true)
      Succ(Succ(rest)) => split(rest, Succ(half))
    }
  }
  fn convert(value : @core.Nat) -> @core.Chain[Bool] {
    match value {
      Zero => Nil
      Succ(_) => {
        let (half, low) = split(value, Zero)
        Cons(low, convert(half))
      }
    }
  }
  { bits: convert(n), }
}

///|
/// This conversion expands a binary numeral to a unary numeral.
pub fn to_nat(n : Binary) -> @core.Nat {
  match n.bits {
    Nil => Zero
    Cons(bit, rest) => {
      let half = to_nat({ bits: rest, })
      let twice = @core.add(half, half)
      match bit {
        false => twice
        true => Succ(twice)
      }
    }
  }
}

///|
/// Word concatenation: value(low ++ high) = low + 2^width(low) * high.
/// Raw lists retain leading zeros, unlike Binary's canonical representation.
pub fn concat_words(
  low : @core.Chain[Bool],
  high : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  @core.append(low, high)
}

///|
/// A bijection N x N -> positive N: pair(a,b) = 2^a * (2*b+1).
pub fn pair(a : @core.Nat, b : Binary) -> Binary {
  { bits: @core.append(@core.replicate(a, false), Cons(true, b.bits)), }
}

///|
/// Zero has no pair. Leading false bits are counted structurally.
pub fn unpair(code : Binary) -> (@core.Nat, Binary)? {
  fn walk(xs : @core.Chain[Bool], zeros : @core.Nat) -> (@core.Nat, Binary)? {
    match xs {
      Nil => None
      Cons(false, rest) => walk(rest, Succ(zeros))
      Cons(true, rest) => Some((zeros, { bits: rest, }))
    }
  }
  walk(code.bits, Zero)
}
