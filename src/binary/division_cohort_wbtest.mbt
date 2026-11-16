// Frozen pre-alignment production algorithms for same-executable controls.

///|
test "division and gcd cohorts preserve small and wide controls" (b : @bench.T) {
  let short = Array::makei(128, fn(i) {
    (@oracle.binary((i * 37 + 11) % 256), @oracle.binary((i * 19 + 7) % 256))
  })
  let near = Array::makei(32, fn(i) {
    let a = from_bits(
      @oracle.chain(
        Array::makei(128, fn(j) { j == 127 || (i * 3 + j * 17 + 5) % 11 < 6 }),
      ),
    )
    let width = 126 + i % 3
    let other = from_bits(
      @oracle.chain(
        Array::makei(width, fn(j) {
          j == width - 1 || (i * 7 + j * 13 + 1) % 17 < 8
        }),
      ),
    )
    (a, other)
  })
  let wide = Array::makei(32, fn(i) {
    let a = from_bits(
      @oracle.chain(
        Array::makei(128, fn(j) { j == 127 || (i * 3 + j * 17 + 5) % 11 < 6 }),
      ),
    )
    let other = from_bits(
      @oracle.chain(
        Array::makei(16 + i % 32, fn(j) {
          j == 15 + i % 32 || (i * 7 + j * 13 + 1) % 17 < 8
        }),
      ),
    )
    (a, other)
  })
  let limit = @oracle.nat(8)
  for
    (label, cases) in [("short128", short), ("near32", near), ("wide32", wide)] {
    b.bench(name="baseline divmod \{label}", fn() {
      for (a, d) in cases {
        b.keep(division_baseline_divmod(a, d))
      }
    })
    b.bench(name="aligned divmod \{label}", fn() {
      for (a, d) in cases {
        b.keep(trial_divmod(a, d, limit))
      }
    })
    b.bench(name="production divmod \{label}", fn() {
      for (a, d) in cases {
        b.keep(divmod(a, d))
      }
    })
    b.bench(name="aligned remainder \{label}", fn() {
      for (a, d) in cases {
        b.keep(trial_remainder(a, d, limit))
      }
    })
    b.bench(name="production remainder \{label}", fn() {
      for (a, d) in cases {
        b.keep(remainder(a, d))
      }
    })
    b.bench(name="baseline gcd \{label}", fn() {
      for (a, d) in cases {
        b.keep(division_baseline_gcd(a, d))
      }
    })
    b.bench(name="aligned gcd \{label}", fn() {
      for (a, d) in cases {
        b.keep(trial_remainder_gcd(a, d, limit))
      }
    })
    b.bench(name="aligned gcd two \{label}", fn() {
      for (a, d) in cases {
        b.keep(trial_remainder_gcd_two(a, d, limit))
      }
    })
    b.bench(name="production gcd \{label}", fn() {
      for (a, d) in cases {
        b.keep(gcd(a, d))
      }
    })
  }
}

///|
test "production division and gcd agree with every pair of byte sized naturals" {
  for a in 0..<256 {
    let left = @oracle.binary(a)
    for b in 0..<256 {
      let right = @oracle.binary(b)
      if b == 0 {
        assert_eq(divmod(left, right), None)
        assert_eq(remainder(left, right), None)
      } else {
        assert_eq(
          divmod(left, right),
          Some((@oracle.binary(a / b), @oracle.binary(a % b))),
        )
        assert_eq(remainder(left, right), Some(@oracle.binary(a % b)))
      }
      let mut x = a
      let mut y = b
      while y != 0 {
        let r = x % y
        x = y
        y = r
      }
      assert_eq(gcd(left, right), @oracle.binary(x))
    }
  }
}

///|
fn division_baseline_divmod(a : Binary, b : Binary) -> (Binary, Binary)? {
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
        false => Some(divide_bits(a.bits, b))
        true =>
          match compare(a, b) {
            Less => Some((zero(), a))
            Equal => Some((one(), zero()))
            Greater => Some(divide_bits(a.bits, b))
          }
      }
  }
}

///|
fn division_baseline_gcd(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(true, Nil), _) | (_, Cons(true, Nil)) => one()
    _ =>
      match equal_prefix(a.bits, b.bits) {
        false => {
          let (_, r) = divide_bits(a.bits, b)
          division_baseline_gcd(b, r)
        }
        true =>
          match compare(a, b) {
            Equal => a
            Less => division_baseline_gcd(b, a)
            Greater => {
              let (_, r) = divide_bits(a.bits, b)
              division_baseline_gcd(b, r)
            }
          }
      }
  }
}
