///|
enum TrialWidth {
  Shorter
  Nearby(@core.Nat)
  Wider
}

///|
fn trial_width(
  xs : @core.Chain[Bool],
  ys : @core.Chain[Bool],
  limit : @core.Nat,
) -> TrialWidth {
  fn remaining(
    xs : @core.Chain[Bool],
    fuel : @core.Nat,
    count : @core.Nat,
  ) -> TrialWidth {
    match (xs, fuel) {
      (Nil, _) => Nearby(count)
      (_, Zero) => Wider
      (Cons(_, tail), Succ(rest)) => remaining(tail, rest, Succ(count))
    }
  }
  match (xs, ys) {
    (_, Nil) => remaining(xs, limit, Zero)
    (Nil, _) => Shorter
    (Cons(_, xs), Cons(_, ys)) => trial_width(xs, ys, limit)
  }
}

///|
fn trial_aligned_divide(
  a : Binary,
  b : Binary,
  amount : @core.Nat,
) -> (Binary, Binary) {
  fn walk(
    position : @core.Nat,
    aligned : Binary,
    remainder : Binary,
    quotient : Binary,
  ) -> (Binary, Binary) {
    let (remainder, bit) = match compare(remainder, aligned) {
      Less => (remainder, false)
      Equal => (zero(), true)
      Greater =>
        (from_bits(subtract_bits(remainder.bits, aligned.bits, false)), true)
    }
    let quotient = Binary::{ bits: low_bit(bit, quotient.bits), }
    match position {
      Zero => (quotient, remainder)
      Succ(rest) => walk(rest, half(aligned), remainder, quotient)
    }
  }
  walk(amount, shift_by(amount, b), a, zero())
}

///|
fn trial_general_divide(
  a : Binary,
  b : Binary,
  limit : @core.Nat,
) -> (Binary, Binary) {
  match trial_width(a.bits, b.bits, limit) {
    Shorter => (zero(), a)
    Nearby(amount) => trial_aligned_divide(a, b, amount)
    Wider => divide_bits(a.bits, b)
  }
}

///|
fn trial_divmod(a : Binary, b : Binary, limit : @core.Nat) -> (Binary, Binary)? {
  match (a.bits, b.bits) {
    (_, Nil) => None
    (Nil, _) => Some((zero(), zero()))
    (_, Cons(true, Nil)) => Some((a, zero()))
    (_, Cons(false, Cons(true, Nil))) =>
      Some(
        (
          half(a),
          match odd(a) {
            true => one()
            false => zero()
          },
        ),
      )
    _ =>
      match equal_prefix(a.bits, b.bits) {
        false => Some(trial_general_divide(a, b, limit))
        true =>
          match compare(a, b) {
            Less => Some((zero(), a))
            Equal => Some((one(), zero()))
            Greater => Some(trial_general_divide(a, b, limit))
          }
      }
  }
}

///|
fn trial_ordered_gcd(a : Binary, b : Binary, limit : @core.Nat) -> Binary {
  match (a.bits, b.bits) {
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
    _ => {
      let (_, rest) = match equal_prefix(a.bits, b.bits) {
        false => trial_general_divide(a, b, limit)
        true =>
          match compare(a, b) {
            Equal => (one(), zero())
            _ => trial_general_divide(a, b, limit)
          }
      }
      trial_ordered_gcd(b, rest, limit)
    }
  }
}

///|
fn trial_gcd(a : Binary, b : Binary, limit : @core.Nat) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
    _ =>
      match compare(a, b) {
        Less => trial_ordered_gcd(b, a, limit)
        _ => trial_ordered_gcd(a, b, limit)
      }
  }
}

///|
test "bounded aligned division agrees with native integer quotient and Euclid" {
  for cutoff in [0, 1, 3, 5, 8] {
    let limit = @oracle.nat(cutoff)
    for a in 0..<128 {
      for b in 1..<128 {
        let left = @oracle.binary(a)
        let right = @oracle.binary(b)
        assert_eq(
          trial_divmod(left, right, limit),
          Some((@oracle.binary(a / b), @oracle.binary(a % b))),
        )
        let mut x = a
        let mut y = b
        while y != 0 {
          let r = x % y
          x = y
          y = r
        }
        assert_eq(trial_gcd(left, right, limit), @oracle.binary(x))
      }
    }
  }
}

///|
test "aligned division cutoffs and general gcd workloads" (b : @bench.T) {
  let a = @oracle.binary_from_hex("d59b8c50c9174c3a71293ab167cd89ef")
  let near = @oracle.binary_from_hex("21234567a789cf1323456789abcdef01")
  let far = @oracle.binary_from_hex("b1234567a789cf13")
  let factor = subtract(power(@oracle.binary(2), @oracle.binary(127)), one()).unwrap()
  let low = multiply(@oracle.binary(6), factor)
  let high = multiply(@oracle.binary(10), factor)
  b.bench(name="reference near quotient", fn() { b.keep(divmod(a, near)) })
  b.bench(name="reference wide quotient", fn() { b.keep(divmod(a, far)) })
  b.bench(name="reference gcd", fn() { b.keep(gcd(a, far)) })
  b.bench(name="reference gcd smaller first", fn() { b.keep(gcd(low, high)) })
  for cutoff in [0, 1, 3, 5, 8] {
    let limit = @oracle.nat(cutoff)
    b.bench(name="near quotient limit \{cutoff}", fn() {
      b.keep(trial_divmod(a, near, limit))
    })
    b.bench(name="wide quotient limit \{cutoff}", fn() {
      b.keep(trial_divmod(a, far, limit))
    })
    b.bench(name="gcd limit \{cutoff}", fn() {
      b.keep(trial_gcd(a, far, limit))
    })
    b.bench(name="gcd smaller first limit \{cutoff}", fn() {
      b.keep(trial_gcd(low, high, limit))
    })
  }
}
