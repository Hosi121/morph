///|
// Frozen production composition, including its zero-operand behavior.
fn composed_rational_subtract(a : Rational, b : Rational) -> Rational {
  rational_add(a, rational_negate(b))
}

///|
test "direct rational subtraction preserves independent integer fractions" {
  for n in -8..<9 {
    for d in 1..<10 {
      let left = @oracle.rational(n, d)
      for m in -8..<9 {
        for e in 1..<10 {
          let right = @oracle.rational(m, e)
          let expected = @oracle.rational(n * e - m * d, d * e)
          let actual = subtract_rationals(left, right)
          assert_eq(actual, expected)
          assert_eq(actual, composed_rational_subtract(left, right))
        }
      }
    }
  }
  let (below, above) = large_pair()
  for sign in [false, true] {
    let value = ratio(positive(above), below).unwrap()
    let value = if sign { rational_negate(value) } else { value }
    assert_eq(subtract_rationals(value, value), rational_zero())
    assert_eq(subtract_rationals(value, rational_zero()), value)
    assert_eq(
      subtract_rationals(rational_zero(), value),
      rational_negate(value),
    )
  }
}

///|
test "same ELF direct rational subtraction small corpus" (b : @bench.T) {
  let values = []
  for n in -3..<4 {
    for d in 1..<5 {
      values.push(@oracle.rational(n, d))
    }
  }
  b.bench(name="composed small", fn() {
    for left in values {
      for right in values {
        b.keep(composed_rational_subtract(left, right))
      }
    }
  })
  b.bench(name="direct small", fn() {
    for left in values {
      for right in values {
        b.keep(subtract_rationals(left, right))
      }
    }
  })
}

///|
test "same ELF direct rational subtraction common large denominator" (
  b : @bench.T,
) {
  let (below, above) = large_pair()
  let left = ratio(positive(above), below).unwrap()
  let right = ratio(positive(@binary.add(above, @oracle.binary(2))), below).unwrap()
  b.bench(name="composed common", fn() {
    b.keep(composed_rational_subtract(left, right))
  })
  b.bench(name="direct common", fn() { b.keep(subtract_rationals(left, right)) })
}

///|
test "same ELF direct rational subtraction coprime large denominators" (
  b : @bench.T,
) {
  let (below, above) = large_pair()
  let left = ratio(@oracle.integer(1), below).unwrap()
  let right = ratio(@oracle.integer(2), above).unwrap()
  b.bench(name="composed coprime", fn() {
    b.keep(composed_rational_subtract(left, right))
  })
  b.bench(name="direct coprime", fn() {
    b.keep(subtract_rationals(left, right))
  })
}

///|
test "same ELF direct rational subtraction reverse small corpus" (b : @bench.T) {
  let values = []
  for n in -3..<4 {
    for d in 1..<5 {
      values.push(@oracle.rational(n, d))
    }
  }
  b.bench(name="direct reverse small", fn() {
    for left in values {
      for right in values {
        b.keep(subtract_rationals(left, right))
      }
    }
  })
  b.bench(name="composed reverse small", fn() {
    for left in values {
      for right in values {
        b.keep(composed_rational_subtract(left, right))
      }
    }
  })
}
