///|
fn remainder_only_bits(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  match xs {
    Nil => zero()
    Cons(bit, rest) => {
      let upper = remainder_only_bits(rest, divisor)
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
fn aligned_remainder_only(a : Binary, b : Binary, amount : @core.Nat) -> Binary {
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
  walk(amount, shift_by(amount, b), a)
}

///|
fn trial_general_remainder(a : Binary, b : Binary, limit : @core.Nat) -> Binary {
  match trial_width(a.bits, b.bits, limit) {
    Shorter => a
    Nearby(amount) => aligned_remainder_only(a, b, amount)
    Wider => remainder_only_bits(a.bits, b)
  }
}

///|
fn trial_remainder(a : Binary, b : Binary, limit : @core.Nat) -> Binary? {
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
    _ => Some(trial_general_remainder(a, b, limit))
  }
}

///|
fn trial_remainder_gcd(a : Binary, b : Binary, limit : @core.Nat) -> Binary {
  fn ordered(a : Binary, b : Binary) -> Binary {
    match (a.bits, b.bits) {
      (_, Nil) => a
      (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
      _ => ordered(b, trial_general_remainder(a, b, limit))
    }
  }
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    _ =>
      match compare(a, b) {
        Less => ordered(b, a)
        Equal => a
        _ => ordered(a, b)
      }
  }
}

///|
fn trial_remainder_gcd_two(a : Binary, b : Binary, limit : @core.Nat) -> Binary {
  fn parity_gcd(a : Binary, two : Binary) -> Binary {
    match odd(a) {
      true => one()
      false => two
    }
  }
  fn ordered(a : Binary, b : Binary) -> Binary {
    match b.bits {
      Nil => a
      Cons(true, Nil) => one()
      Cons(false, Cons(true, Nil)) => parity_gcd(a, b)
      _ => ordered(b, trial_general_remainder(a, b, limit))
    }
  }
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
    (Cons(false, Cons(true, Nil)), _) => parity_gcd(b, a)
    (_, Cons(false, Cons(true, Nil))) => parity_gcd(a, b)
    _ =>
      match compare(a, b) {
        Less => ordered(b, a)
        Equal => a
        Greater => ordered(a, b)
      }
  }
}

///|
test "remainder-only path keeps division by zero and every small remainder" {
  for a in 0..<128 {
    let left = @oracle.binary(a)
    assert_eq(trial_remainder(left, zero(), @oracle.nat(8)), None)
    for b in 1..<128 {
      let right = @oracle.binary(b)
      for cutoff in [3, 8] {
        let limit = @oracle.nat(cutoff)
        assert_eq(
          trial_remainder(left, right, limit),
          Some(@oracle.binary(a % b)),
        )
        assert_eq(trial_remainder_gcd(left, right, limit), gcd(left, right))
        assert_eq(trial_remainder_gcd_two(left, right, limit), gcd(left, right))
      }
    }
  }
}

///|
test "quotient-free remainder and gcd with wide and short controls" (
  b : @bench.T,
) {
  let near = @oracle.binary_from_hex("21234567a789cf1323456789abcdef01")
  let a = @oracle.binary_from_hex("d59b8c50c9174c3a71293ab167cd89ef")
  let far = @oracle.binary_from_hex("b1234567a789cf13")
  let limit = @oracle.nat(8)
  for
    (name, a, divisor) in [
      ("near", a, near),
      ("wide", a, far),
      ("small", @oracle.binary(165), @oracle.binary(27)),
      ("tiny", @oracle.binary(3), @oracle.binary(2)),
    ] {
    b.bench(name="divmod remainder \{name}", fn() { b.keep(divmod(a, divisor)) })
    b.bench(name="remainder only \{name}", fn() {
      b.keep(trial_remainder(a, divisor, limit))
    })
    b.bench(name="gcd reference \{name}", fn() { b.keep(gcd(a, divisor)) })
    b.bench(name="gcd remainder only \{name}", fn() {
      b.keep(trial_remainder_gcd(a, divisor, limit))
    })
    b.bench(name="gcd remainder two \{name}", fn() {
      b.keep(trial_remainder_gcd_two(a, divisor, limit))
    })
  }
}
