// Frozen benchmark controls: only zero/one factories differ.
// Generated in the private worktree; no production implementation is replaced.

///|
fn factory_fresh_add(a : Binary, b : Binary) -> Binary {
  { bits: factory_fresh_add_bits(a.bits, b.bits, false), }
}

///|
fn factory_fresh_add_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  carry : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, next) = factory_fresh_full_adder(x, y, carry)
      Cons(s, factory_fresh_add_bits(xt, yt, next))
    }
    (rest, Nil) | (Nil, rest) =>
      match carry {
        false => rest
        true => factory_fresh_increment_bits(rest)
      }
  }
}

///|
fn factory_fresh_compare(a : Binary, b : Binary) -> @core.Ordering {
  factory_fresh_compare_bits(a.bits, b.bits)
}

///|
fn factory_fresh_compare_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> @core.Ordering {
  match (xs, ys) {
    (Nil, Nil) => Equal
    (Nil, Cons(_, _)) => Less
    (Cons(_, _), Nil) => Greater
    (Cons(x, xt), Cons(y, yt)) =>
      match factory_fresh_compare_bits(xt, yt) {
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
fn factory_fresh_divide_adaptively(a : Binary, b : Binary) -> (Binary, Binary) {
  match factory_fresh_division_width(a.bits, b.bits) {
    Below => (factory_fresh_zero(), a)
    Nearby(amount) => factory_fresh_divide_aligned(a, b, amount)
    Wide => factory_fresh_divide_bits(a.bits, b)
  }
}

///|
fn factory_fresh_divide_aligned(
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
    let (remainder, bit) = match factory_fresh_compare(remainder, aligned) {
      Less => (remainder, false)
      Equal => (factory_fresh_zero(), true)
      Greater =>
        (
          factory_fresh_from_bits(
            factory_fresh_subtract_bits(remainder.bits, aligned.bits, false),
          ),
          true,
        )
    }
    let quotient = factory_fresh_low_bit(bit, quotient)
    match position {
      Zero => ({ bits: quotient, }, remainder)
      Succ(rest) => walk(rest, factory_fresh_half(aligned), remainder, quotient)
    }
  }
  // The divisor is nonzero and canonical at this private boundary.
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a, Nil)
}

///|
fn factory_fresh_divide_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  match xs {
    Nil => (factory_fresh_zero(), factory_fresh_zero())
    Cons(bit, rest) => {
      let (q, r) = factory_fresh_divide_bits(rest, divisor)
      let next : Binary = { bits: factory_fresh_low_bit(bit, r.bits), }
      match factory_fresh_compare(next, divisor) {
        Less => (factory_fresh_double(q), next)
        _ => {
          let reduced = factory_fresh_from_bits(
            factory_fresh_subtract_bits(next.bits, divisor.bits, false),
          )
          ({ bits: Cons(true, q.bits), }, reduced)
        }
      }
    }
  }
}

///|
fn factory_fresh_division_width(
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
    (Cons(_, xs), Cons(_, ys)) => factory_fresh_division_width(xs, ys)
  }
}

///|
fn factory_fresh_divmod(a : Binary, b : Binary) -> (Binary, Binary)? {
  match (a.bits, b.bits) {
    (_, Nil) => None
    (Nil, _) => Some((factory_fresh_zero(), factory_fresh_zero()))
    (_, Cons(true, Nil)) => Some((a, factory_fresh_zero()))
    (_, Cons(false, Cons(true, Nil))) =>
      Some(
        (
          factory_fresh_half(a),
          match factory_fresh_odd(a) {
            true => factory_fresh_one()
            false => factory_fresh_zero()
          },
        ),
      )
    _ =>
      match factory_fresh_equal_prefix(a.bits, b.bits) {
        false => Some(factory_fresh_divide_adaptively(a, b))
        true =>
          match factory_fresh_compare(a, b) {
            Less => Some((factory_fresh_zero(), a))
            Equal => Some((factory_fresh_one(), factory_fresh_zero()))
            Greater => Some(factory_fresh_divide_adaptively(a, b))
          }
      }
  }
}

///|
fn factory_fresh_double(n : Binary) -> Binary {
  { bits: factory_fresh_low_bit(false, n.bits), }
}

///|
fn factory_fresh_equal_prefix(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> Bool {
  match (xs, ys) {
    (
      Cons(a, Cons(b, Cons(c, Cons(d, _)))),
      Cons(w, Cons(x, Cons(y, Cons(z, _)))),
    ) =>
      factory_fresh_same_bit(a, w) &&
      factory_fresh_same_bit(b, x) &&
      factory_fresh_same_bit(c, y) &&
      factory_fresh_same_bit(d, z)
    _ => true
  }
}

///|
fn factory_fresh_from_bits(bits : @core.Chain[Bool]) -> Binary {
  { bits: factory_fresh_trim(bits), }
}

///|
fn factory_fresh_full_adder(a : Bool, b : Bool, carry : Bool) -> (Bool, Bool) {
  match (a, b, carry) {
    (false, false, false) => (false, false)
    (false, false, true) | (false, true, false) | (true, false, false) =>
      (true, false)
    (true, true, true) => (true, true)
    _ => (false, true)
  }
}

///|
fn factory_fresh_gcd(a : Binary, b : Binary) -> Binary {
  factory_fresh_gcd_adaptively(a, b)
}

///|
fn factory_fresh_gcd_adaptively(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => factory_fresh_one()
    (Cons(false, Cons(true, Nil)), _) => factory_fresh_gcd_two(b, a)
    (_, Cons(false, Cons(true, Nil))) => factory_fresh_gcd_two(a, b)
    _ =>
      match factory_fresh_compare(a, b) {
        Less => factory_fresh_gcd_ordered(b, a)
        Equal => a
        Greater => factory_fresh_gcd_ordered(a, b)
      }
  }
}

///|
fn factory_fresh_gcd_ordered(a : Binary, b : Binary) -> Binary {
  match b.bits {
    Nil => a
    Cons(true, Nil) => factory_fresh_one()
    Cons(false, Cons(true, Nil)) => factory_fresh_gcd_two(a, b)
    _ => factory_fresh_gcd_ordered(b, factory_fresh_remainder_adaptively(a, b))
  }
}

///|
fn factory_fresh_gcd_two(a : Binary, two : Binary) -> Binary {
  match factory_fresh_odd(a) {
    true => factory_fresh_one()
    false => two
  }
}

///|
fn factory_fresh_half(n : Binary) -> Binary {
  match n.bits {
    Nil => n
    Cons(_, tail) => { bits: tail, }
  }
}

///|
fn factory_fresh_increment_bits(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Cons(true, Nil)
    Cons(false, rest) => Cons(true, rest)
    Cons(true, rest) => Cons(false, factory_fresh_increment_bits(rest))
  }
}

///|
fn factory_fresh_low_bit(
  bit : Bool,
  rest : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match (bit, rest) {
    (false, Nil) => Nil
    _ => Cons(bit, rest)
  }
}

///|
fn factory_fresh_multiply(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) | (_, Nil) => factory_fresh_zero()
    (Cons(true, Nil), _) => b
    (_, Cons(true, Nil)) => a
    (Cons(false, Cons(true, Nil)), _) => factory_fresh_double(b)
    (_, Cons(false, Cons(true, Nil))) => factory_fresh_double(a)
    _ => factory_fresh_multiply_bits(a.bits, b)
  }
}

///|
fn factory_fresh_multiply_bits(xs : @core.Chain[Bool], b : Binary) -> Binary {
  match xs {
    Nil => factory_fresh_zero()
    Cons(bit, rest) => {
      let shifted = factory_fresh_double(factory_fresh_multiply_bits(rest, b))
      match bit {
        false => shifted
        true => factory_fresh_add(b, shifted)
      }
    }
  }
}

///|
fn factory_fresh_negate_bit(x : Bool) -> Bool {
  match x {
    true => false
    false => true
  }
}

///|
fn factory_fresh_odd(n : Binary) -> Bool {
  match n.bits {
    Nil => false
    Cons(bit, _) => bit
  }
}

///|
fn factory_fresh_one() -> Binary {
  previous_one_factory()
}

///|
fn factory_fresh_remainder_adaptively(a : Binary, b : Binary) -> Binary {
  match factory_fresh_division_width(a.bits, b.bits) {
    Below => a
    Nearby(amount) => factory_fresh_remainder_aligned(a, b, amount)
    Wide => factory_fresh_remainder_bits(a.bits, b)
  }
}

///|
fn factory_fresh_remainder_aligned(
  a : Binary,
  b : Binary,
  amount : @core.Nat,
) -> Binary {
  fn walk(position : @core.Nat, aligned : Binary, rest : Binary) -> Binary {
    let rest = match factory_fresh_compare(rest, aligned) {
      Less => rest
      Equal => factory_fresh_zero()
      Greater =>
        factory_fresh_from_bits(
          factory_fresh_subtract_bits(rest.bits, aligned.bits, false),
        )
    }
    match position {
      Zero => rest
      Succ(position) => walk(position, factory_fresh_half(aligned), rest)
    }
  }
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a)
}

///|
fn factory_fresh_remainder_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> Binary {
  match xs {
    Nil => factory_fresh_zero()
    Cons(bit, rest) => {
      let upper = factory_fresh_remainder_bits(rest, divisor)
      let next = Binary::{ bits: factory_fresh_low_bit(bit, upper.bits), }
      match factory_fresh_compare(next, divisor) {
        Less => next
        Equal => factory_fresh_zero()
        Greater =>
          factory_fresh_from_bits(
            factory_fresh_subtract_bits(next.bits, divisor.bits, false),
          )
      }
    }
  }
}

///|
fn factory_fresh_same_bit(a : Bool, b : Bool) -> Bool {
  match a {
    false => !b
    true => b
  }
}

///|
fn factory_fresh_subtract(a : Binary, b : Binary) -> Binary? {
  match factory_fresh_compare(a, b) {
    Less => None
    _ =>
      Some(
        factory_fresh_from_bits(
          factory_fresh_subtract_bits(a.bits, b.bits, false),
        ),
      )
  }
}

///|
fn factory_fresh_subtract_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  borrow : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Nil, _) => Nil
    (Cons(x, xt), Nil) => {
      let (s, carry) = factory_fresh_full_adder(
        x,
        true,
        factory_fresh_negate_bit(borrow),
      )
      Cons(
        s,
        factory_fresh_subtract_bits(xt, Nil, factory_fresh_negate_bit(carry)),
      )
    }
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, carry) = factory_fresh_full_adder(
        x,
        factory_fresh_negate_bit(y),
        factory_fresh_negate_bit(borrow),
      )
      Cons(
        s,
        factory_fresh_subtract_bits(xt, yt, factory_fresh_negate_bit(carry)),
      )
    }
  }
}

///|
fn factory_fresh_trim(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Nil
    Cons(bit, rest) => {
      let tail = factory_fresh_trim(rest)
      match (bit, tail) {
        (false, Nil) => Nil
        _ => Cons(bit, tail)
      }
    }
  }
}

///|
fn factory_fresh_zero() -> Binary {
  previous_zero_factory()
}

///|
fn factory_shared_add(a : Binary, b : Binary) -> Binary {
  { bits: factory_shared_add_bits(a.bits, b.bits, false), }
}

///|
fn factory_shared_add_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  carry : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, next) = factory_shared_full_adder(x, y, carry)
      Cons(s, factory_shared_add_bits(xt, yt, next))
    }
    (rest, Nil) | (Nil, rest) =>
      match carry {
        false => rest
        true => factory_shared_increment_bits(rest)
      }
  }
}

///|
fn factory_shared_compare(a : Binary, b : Binary) -> @core.Ordering {
  factory_shared_compare_bits(a.bits, b.bits)
}

///|
fn factory_shared_compare_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> @core.Ordering {
  match (xs, ys) {
    (Nil, Nil) => Equal
    (Nil, Cons(_, _)) => Less
    (Cons(_, _), Nil) => Greater
    (Cons(x, xt), Cons(y, yt)) =>
      match factory_shared_compare_bits(xt, yt) {
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
fn factory_shared_divide_adaptively(a : Binary, b : Binary) -> (Binary, Binary) {
  match factory_shared_division_width(a.bits, b.bits) {
    Below => (factory_shared_zero(), a)
    Nearby(amount) => factory_shared_divide_aligned(a, b, amount)
    Wide => factory_shared_divide_bits(a.bits, b)
  }
}

///|
fn factory_shared_divide_aligned(
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
    let (remainder, bit) = match factory_shared_compare(remainder, aligned) {
      Less => (remainder, false)
      Equal => (factory_shared_zero(), true)
      Greater =>
        (
          factory_shared_from_bits(
            factory_shared_subtract_bits(remainder.bits, aligned.bits, false),
          ),
          true,
        )
    }
    let quotient = factory_shared_low_bit(bit, quotient)
    match position {
      Zero => ({ bits: quotient, }, remainder)
      Succ(rest) =>
        walk(rest, factory_shared_half(aligned), remainder, quotient)
    }
  }
  // The divisor is nonzero and canonical at this private boundary.
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a, Nil)
}

///|
fn factory_shared_divide_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  match xs {
    Nil => (factory_shared_zero(), factory_shared_zero())
    Cons(bit, rest) => {
      let (q, r) = factory_shared_divide_bits(rest, divisor)
      let next : Binary = { bits: factory_shared_low_bit(bit, r.bits), }
      match factory_shared_compare(next, divisor) {
        Less => (factory_shared_double(q), next)
        _ => {
          let reduced = factory_shared_from_bits(
            factory_shared_subtract_bits(next.bits, divisor.bits, false),
          )
          ({ bits: Cons(true, q.bits), }, reduced)
        }
      }
    }
  }
}

///|
fn factory_shared_division_width(
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
    (Cons(_, xs), Cons(_, ys)) => factory_shared_division_width(xs, ys)
  }
}

///|
fn factory_shared_divmod(a : Binary, b : Binary) -> (Binary, Binary)? {
  match (a.bits, b.bits) {
    (_, Nil) => None
    (Nil, _) => Some((factory_shared_zero(), factory_shared_zero()))
    (_, Cons(true, Nil)) => Some((a, factory_shared_zero()))
    (_, Cons(false, Cons(true, Nil))) =>
      Some(
        (
          factory_shared_half(a),
          match factory_shared_odd(a) {
            true => factory_shared_one()
            false => factory_shared_zero()
          },
        ),
      )
    _ =>
      match factory_shared_equal_prefix(a.bits, b.bits) {
        false => Some(factory_shared_divide_adaptively(a, b))
        true =>
          match factory_shared_compare(a, b) {
            Less => Some((factory_shared_zero(), a))
            Equal => Some((factory_shared_one(), factory_shared_zero()))
            Greater => Some(factory_shared_divide_adaptively(a, b))
          }
      }
  }
}

///|
fn factory_shared_double(n : Binary) -> Binary {
  { bits: factory_shared_low_bit(false, n.bits), }
}

///|
fn factory_shared_equal_prefix(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
) -> Bool {
  match (xs, ys) {
    (
      Cons(a, Cons(b, Cons(c, Cons(d, _)))),
      Cons(w, Cons(x, Cons(y, Cons(z, _)))),
    ) =>
      factory_shared_same_bit(a, w) &&
      factory_shared_same_bit(b, x) &&
      factory_shared_same_bit(c, y) &&
      factory_shared_same_bit(d, z)
    _ => true
  }
}

///|
fn factory_shared_from_bits(bits : @core.Chain[Bool]) -> Binary {
  { bits: factory_shared_trim(bits), }
}

///|
fn factory_shared_full_adder(a : Bool, b : Bool, carry : Bool) -> (Bool, Bool) {
  match (a, b, carry) {
    (false, false, false) => (false, false)
    (false, false, true) | (false, true, false) | (true, false, false) =>
      (true, false)
    (true, true, true) => (true, true)
    _ => (false, true)
  }
}

///|
fn factory_shared_gcd(a : Binary, b : Binary) -> Binary {
  factory_shared_gcd_adaptively(a, b)
}

///|
fn factory_shared_gcd_adaptively(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => factory_shared_one()
    (Cons(false, Cons(true, Nil)), _) => factory_shared_gcd_two(b, a)
    (_, Cons(false, Cons(true, Nil))) => factory_shared_gcd_two(a, b)
    _ =>
      match factory_shared_compare(a, b) {
        Less => factory_shared_gcd_ordered(b, a)
        Equal => a
        Greater => factory_shared_gcd_ordered(a, b)
      }
  }
}

///|
fn factory_shared_gcd_ordered(a : Binary, b : Binary) -> Binary {
  match b.bits {
    Nil => a
    Cons(true, Nil) => factory_shared_one()
    Cons(false, Cons(true, Nil)) => factory_shared_gcd_two(a, b)
    _ =>
      factory_shared_gcd_ordered(b, factory_shared_remainder_adaptively(a, b))
  }
}

///|
fn factory_shared_gcd_two(a : Binary, two : Binary) -> Binary {
  match factory_shared_odd(a) {
    true => factory_shared_one()
    false => two
  }
}

///|
fn factory_shared_half(n : Binary) -> Binary {
  match n.bits {
    Nil => n
    Cons(_, tail) => { bits: tail, }
  }
}

///|
fn factory_shared_increment_bits(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Cons(true, Nil)
    Cons(false, rest) => Cons(true, rest)
    Cons(true, rest) => Cons(false, factory_shared_increment_bits(rest))
  }
}

///|
fn factory_shared_low_bit(
  bit : Bool,
  rest : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match (bit, rest) {
    (false, Nil) => Nil
    _ => Cons(bit, rest)
  }
}

///|
fn factory_shared_multiply(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) | (_, Nil) => factory_shared_zero()
    (Cons(true, Nil), _) => b
    (_, Cons(true, Nil)) => a
    (Cons(false, Cons(true, Nil)), _) => factory_shared_double(b)
    (_, Cons(false, Cons(true, Nil))) => factory_shared_double(a)
    _ => factory_shared_multiply_bits(a.bits, b)
  }
}

///|
fn factory_shared_multiply_bits(xs : @core.Chain[Bool], b : Binary) -> Binary {
  match xs {
    Nil => factory_shared_zero()
    Cons(bit, rest) => {
      let shifted = factory_shared_double(factory_shared_multiply_bits(rest, b))
      match bit {
        false => shifted
        true => factory_shared_add(b, shifted)
      }
    }
  }
}

///|
fn factory_shared_negate_bit(x : Bool) -> Bool {
  match x {
    true => false
    false => true
  }
}

///|
fn factory_shared_odd(n : Binary) -> Bool {
  match n.bits {
    Nil => false
    Cons(bit, _) => bit
  }
}

///|
fn factory_shared_one() -> Binary {
  canonical_one()
}

///|
fn factory_shared_remainder_adaptively(a : Binary, b : Binary) -> Binary {
  match factory_shared_division_width(a.bits, b.bits) {
    Below => a
    Nearby(amount) => factory_shared_remainder_aligned(a, b, amount)
    Wide => factory_shared_remainder_bits(a.bits, b)
  }
}

///|
fn factory_shared_remainder_aligned(
  a : Binary,
  b : Binary,
  amount : @core.Nat,
) -> Binary {
  fn walk(position : @core.Nat, aligned : Binary, rest : Binary) -> Binary {
    let rest = match factory_shared_compare(rest, aligned) {
      Less => rest
      Equal => factory_shared_zero()
      Greater =>
        factory_shared_from_bits(
          factory_shared_subtract_bits(rest.bits, aligned.bits, false),
        )
    }
    match position {
      Zero => rest
      Succ(position) => walk(position, factory_shared_half(aligned), rest)
    }
  }
  let aligned = Binary::{ bits: @core.replicate_onto(amount, false, b.bits), }
  walk(amount, aligned, a)
}

///|
fn factory_shared_remainder_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> Binary {
  match xs {
    Nil => factory_shared_zero()
    Cons(bit, rest) => {
      let upper = factory_shared_remainder_bits(rest, divisor)
      let next = Binary::{ bits: factory_shared_low_bit(bit, upper.bits), }
      match factory_shared_compare(next, divisor) {
        Less => next
        Equal => factory_shared_zero()
        Greater =>
          factory_shared_from_bits(
            factory_shared_subtract_bits(next.bits, divisor.bits, false),
          )
      }
    }
  }
}

///|
fn factory_shared_same_bit(a : Bool, b : Bool) -> Bool {
  match a {
    false => !b
    true => b
  }
}

///|
fn factory_shared_subtract(a : Binary, b : Binary) -> Binary? {
  match factory_shared_compare(a, b) {
    Less => None
    _ =>
      Some(
        factory_shared_from_bits(
          factory_shared_subtract_bits(a.bits, b.bits, false),
        ),
      )
  }
}

///|
fn factory_shared_subtract_bits(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  borrow : Bool,
) -> @core.Chain[Bool] {
  match (xs, ys) {
    (Nil, _) => Nil
    (Cons(x, xt), Nil) => {
      let (s, carry) = factory_shared_full_adder(
        x,
        true,
        factory_shared_negate_bit(borrow),
      )
      Cons(
        s,
        factory_shared_subtract_bits(xt, Nil, factory_shared_negate_bit(carry)),
      )
    }
    (Cons(x, xt), Cons(y, yt)) => {
      let (s, carry) = factory_shared_full_adder(
        x,
        factory_shared_negate_bit(y),
        factory_shared_negate_bit(borrow),
      )
      Cons(
        s,
        factory_shared_subtract_bits(xt, yt, factory_shared_negate_bit(carry)),
      )
    }
  }
}

///|
fn factory_shared_trim(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Nil
    Cons(bit, rest) => {
      let tail = factory_shared_trim(rest)
      match (bit, tail) {
        (false, Nil) => Nil
        _ => Cons(bit, tail)
      }
    }
  }
}

///|
fn factory_shared_zero() -> Binary {
  canonical_zero()
}

///|
test "shared Binary constants preserve canonical boundaries and arithmetic" {
  assert_eq(canonical_zero(), @oracle.binary(0))
  assert_eq(canonical_one(), @oracle.binary(1))
  for a in 0..<256 {
    for b in 0..<256 {
      let x = @oracle.binary(a)
      let y = @oracle.binary(b)
      assert_eq(factory_shared_add(x, y), @oracle.binary(a + b))
      assert_eq(factory_shared_multiply(x, y), @oracle.binary(a * b))
      let expected = if b == 0 {
        None
      } else {
        Some((@oracle.binary(a / b), @oracle.binary(a % b)))
      }
      assert_eq(factory_shared_divmod(x, y), expected)
      assert_eq(factory_shared_gcd(x, y), gcd(x, y))
    }
  }
}

///|
test "same ELF mixed small Binary factory cohort" (b : @bench.T) {
  let pairs = []
  for index in 0..<128 {
    let a = (index * 73 + 19) % 65
    let c = (index * 137 + 43) % 65
    pairs.push((@oracle.binary(a), @oracle.binary(c)))
  }
  b.bench(name="fresh small128", fn() {
    for pair in pairs {
      b.keep(factory_fresh_add(pair.0, pair.1))
      b.keep(factory_fresh_subtract(pair.0, pair.1))
      b.keep(factory_fresh_multiply(pair.0, pair.1))
      b.keep(factory_fresh_divmod(pair.0, pair.1))
      b.keep(factory_fresh_gcd(pair.0, pair.1))
    }
  })
  b.bench(name="shared small128", fn() {
    for pair in pairs {
      b.keep(factory_shared_add(pair.0, pair.1))
      b.keep(factory_shared_subtract(pair.0, pair.1))
      b.keep(factory_shared_multiply(pair.0, pair.1))
      b.keep(factory_shared_divmod(pair.0, pair.1))
      b.keep(factory_shared_gcd(pair.0, pair.1))
    }
  })
}
