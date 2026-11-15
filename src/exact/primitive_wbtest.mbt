///|
fn gcd_integer(a : Int32, b : Int32) -> Int32 {
  let mut x = a.abs()
  let mut y = b.abs()
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
fn canonical_matches(
  value : Rational,
  raw_numerator : Int32,
  raw_denominator : Int32,
) -> Unit raise {
  let common = gcd_integer(raw_numerator, raw_denominator)
  assert_eq(@oracle.int_of_integer(numerator(value)), raw_numerator / common)
  assert_eq(@oracle.int_of_binary(denominator(value)), raw_denominator / common)
  assert_eq(
    gcd_integer(
      @oracle.int_of_integer(numerator(value)),
      @oracle.int_of_binary(denominator(value)),
    ),
    1,
  )
  if raw_numerator == 0 {
    assert_false(negative(numerator(value)))
    assert_eq(denominator(value), @binary.one())
  }
}

///|
test "normalize and invariant based half match an independent integer gcd oracle" {
  for n in -256..<257 {
    for d in 1..<129 {
      let value = ratio(@oracle.integer(n), @oracle.binary(d)).unwrap()
      canonical_matches(value, n, d)
      canonical_matches(rational_half(value), n, d * 2)
      canonical_matches(rational_negate(value), -n, d)
    }
  }
  assert_eq(ratio(@oracle.integer(0), @binary.zero()), None)
}

///|
test "comparison shortcuts match independent signed cross products exhaustively" {
  for a in -8..<9 {
    for ad in 1..<10 {
      for b in -8..<9 {
        for bd in 1..<10 {
          let expected = if a * bd < b * ad {
            @core.Less
          } else if a * bd > b * ad {
            @core.Greater
          } else {
            @core.Equal
          }
          assert_eq(
            rational_compare(@oracle.rational(a, ad), @oracle.rational(b, bd)),
            expected,
          )
        }
      }
    }
  }
}

///|
test "nontrivial exact quotients preserve canonical sign and large reciprocal cancellation" {
  for value in 0..<65 {
    for divisor in 1..<33 {
      let product = value * divisor
      assert_eq(
        exact_quotient(@oracle.binary(product), @oracle.binary(divisor)),
        @oracle.binary(value),
      )
      assert_eq(
        integer_quotient(@oracle.integer(-product), @oracle.binary(divisor)),
        @oracle.integer(-value),
      )
    }
  }
  let (below, above) = large_pair()
  let positive_value = ratio(positive(above), below).unwrap()
  let negative_value = rational_negate(positive_value)
  assert_eq(
    rational_multiply(
      positive_value,
      reciprocal(nonzero(positive_value).unwrap()),
    ),
    rational_one(),
  )
  assert_eq(
    rational_multiply(
      negative_value,
      reciprocal(nonzero(negative_value).unwrap()),
    ),
    rational_one(),
  )
  assert_eq(rational_add(positive_value, negative_value), rational_zero())
}

///|
test "short quotient specialization matches every bounded exact product including powers of two" {
  for d in 1..<257 {
    for q in 0..<129 {
      assert_eq(
        exact_quotient(@oracle.binary(d * q), @oracle.binary(d)),
        @oracle.binary(q),
      )
    }
  }
  let (odd, _) = large_pair()
  for shift in 0..<8 {
    let divisor = @binary.multiply(
      odd,
      @binary.power(@oracle.binary(2), @oracle.binary(shift)),
    )
    for q in 0..<34 {
      let value = @binary.multiply(divisor, @oracle.binary(q))
      assert_eq(exact_quotient(value, divisor), @oracle.binary(q))
    }
  }
}

///|
test "signed direct operations preserve value and unique zero on every small pair" {
  for a in -64..<65 {
    for b in -64..<65 {
      let left = @oracle.integer(a)
      let right = @oracle.integer(b)
      for
        pair in [
          (add(left, right), a + b),
          (subtract(left, right), a - b),
          (multiply(left, right), a * b),
        ] {
        assert_eq(@oracle.int_of_integer(pair.0), pair.1)
        assert_eq(negative(pair.0), pair.1 < 0)
      }
    }
  }
  let (large, _) = large_pair()
  let value = positive(large)
  let negative_value = negate(value)
  let zero = positive(@binary.zero())
  let one = positive(@binary.one())
  for signed in [value, negative_value] {
    assert_eq(add(zero, signed), signed)
    assert_eq(subtract(signed, zero), signed)
    assert_eq(multiply(signed, one), signed)
    assert_eq(multiply(signed, negate(one)), negate(signed))
    assert_eq(subtract(signed, signed), zero)
    assert_eq(add(signed, negate(signed)), zero)
    assert_eq(multiply(signed, zero), zero)
  }
}
