///|
priv enum DivisionWidth {
  Below
  Nearby(@core.Nat)
  Wide
}

///|
let division_alignment_limit : @core.Nat = @core.Succ(
  Succ(Succ(Succ(Succ(Succ(Succ(Succ(Zero))))))),
)

///|
fn division_width(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> DivisionWidth {
  fn remaining(
    xs : @core.Chain[Bool],
    fuel : @core.Nat,
    count : @core.Nat,
  ) -> DivisionWidth {
    match (xs, fuel) {
      (Nil, _) => Nearby(count)
      (_, Zero) => Wide
      (Cons(_, tail), Succ(rest)) => remaining(tail, rest, Succ(count))
    }
  }
  match (xs, ys) {
    (_, Nil) => remaining(xs, division_alignment_limit, Zero)
    (Nil, _) => Below
    (Cons(_, xs), Cons(_, ys)) => division_width(xs, ys)
  }
}

///|
fn divide_aligned(
  a : Binary,
  b : Binary,
  amount : @core.Nat,
) -> (Binary, Binary) {
  fn walk(
    position : @core.Nat,
    aligned : Binary,
    remainder : Binary,
    quotient : @core.Chain[Bool],
  ) -> (Binary, Binary) {
    let (remainder, bit) = match compare(remainder, aligned) {
      Less => (remainder, false)
      Equal => (zero(), true)
      Greater =>
        (from_bits(subtract_bits(remainder.bits, aligned.bits, false)), true)
    }
    let quotient = low_bit(bit, quotient)
    match position {
      Zero => ({ bits: quotient, }, remainder)
      Succ(rest) => walk(rest, half(aligned), remainder, quotient)
    }
  }
  // The divisor is nonzero and canonical at this private boundary.
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a, Nil)
}

///|
fn divide_adaptively(a : Binary, b : Binary) -> (Binary, Binary) {
  match division_width(a.bits, b.bits) {
    Below => (zero(), a)
    Nearby(amount) => divide_aligned(a, b, amount)
    Wide => divide_bits(a.bits, b)
  }
}

///|
fn remainder_bits(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  match xs {
    Nil => zero()
    Cons(bit, rest) => {
      let upper = remainder_bits(rest, divisor)
      let next = Binary::{ bits: low_bit(bit, upper.bits), }
      match compare(next, divisor) {
        Less => next
        Equal => zero()
        Greater => from_bits(subtract_bits(next.bits, divisor.bits, false))
      }
    }
  }
}

///|
fn remainder_aligned(a : Binary, b : Binary, amount : @core.Nat) -> Binary {
  fn walk(position : @core.Nat, aligned : Binary, rest : Binary) -> Binary {
    let rest = match compare(rest, aligned) {
      Less => rest
      Equal => zero()
      Greater => from_bits(subtract_bits(rest.bits, aligned.bits, false))
    }
    match position {
      Zero => rest
      Succ(position) => walk(position, half(aligned), rest)
    }
  }
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a)
}

///|
fn remainder_adaptively(a : Binary, b : Binary) -> Binary {
  match division_width(a.bits, b.bits) {
    Below => a
    Nearby(amount) => remainder_aligned(a, b, amount)
    Wide => remainder_bits(a.bits, b)
  }
}

///|
/// The same remainder as divmod, without constructing an unused quotient.
pub fn remainder(a : Binary, b : Binary) -> Binary? {
  match (a.bits, b.bits) {
    (_, Nil) => None
    (Nil, _) | (_, Cons(true, Nil)) => Some(zero())
    (_, Cons(false, Cons(true, Nil))) =>
      Some(
        match odd(a) {
          true => one()
          false => zero()
        },
      )
    _ =>
      match equal_prefix(a.bits, b.bits) {
        false => Some(remainder_adaptively(a, b))
        true =>
          match compare(a, b) {
            Less => Some(a)
            Equal => Some(zero())
            Greater => Some(remainder_adaptively(a, b))
          }
      }
  }
}

///|
fn gcd_two(a : Binary, two : Binary) -> Binary {
  match odd(a) {
    true => one()
    false => two
  }
}

///|
// After the first ordering, every Euclidean remainder is strictly below b.
fn gcd_ordered(a : Binary, b : Binary) -> Binary {
  match b.bits {
    Nil => a
    Cons(true, Nil) => one()
    Cons(false, Cons(true, Nil)) => gcd_two(a, b)
    _ => gcd_ordered(b, remainder_adaptively(a, b))
  }
}

///|
fn gcd_adaptively(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
    (Cons(false, Cons(true, Nil)), _) => gcd_two(b, a)
    (_, Cons(false, Cons(true, Nil))) => gcd_two(a, b)
    _ =>
      match compare(a, b) {
        Less => gcd_ordered(b, a)
        Equal => a
        Greater => gcd_ordered(a, b)
      }
  }
}
