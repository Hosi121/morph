///|
fn binary(n : Int32) -> @binary.Binary {
  fn go(n : Int32) -> @core.Chain[Bool] {
    if n == 0 {
      Nil
    } else {
      Cons(n % 2 == 1, go(n / 2))
    }
  }
  @binary.from_bits(go(n))
}

///|
fn integer(n : Int32) -> Integer {
  if n < 0 {
    negate(positive(binary(-n)))
  } else {
    positive(binary(n))
  }
}

///|
fn machine(n : Integer) -> Int32 {
  fn go(xs : @core.Chain[Bool]) -> Int32 {
    match xs {
      Nil => 0
      Cons(b, rest) => (if b { 1 } else { 0 }) + 2 * go(rest)
    }
  }
  let abs = go(@binary.bits(magnitude(n)))
  if negative(n) {
    -abs
  } else {
    abs
  }
}

///|
fn rational(n : Int32, d : Int32) -> Rational {
  match ratio(integer(n), binary(d)) {
    Some(r) => r
    None => abort("bad test fraction")
  }
}

///|
test "signed binary arithmetic over all pairs from minus sixteen to sixteen" {
  for a in -16..<=16 {
    for b in -16..<=16 {
      assert_eq(machine(add(integer(a), integer(b))), a + b)
      assert_eq(machine(subtract(integer(a), integer(b))), a - b)
      assert_eq(machine(multiply(integer(a), integer(b))), a * b)
      assert_eq(
        compare(integer(a), integer(b)),
        if a < b {
          @core.Less
        } else if a > b {
          @core.Greater
        } else {
          @core.Equal
        },
      )
    }
  }
  assert_eq(negate(integer(0)), integer(0))
}

///|
test "exact rational field identities and normalization" {
  assert_eq(rational(2, 4), rational(1, 2))
  assert_eq(rational(-6, 9), rational(-2, 3))
  assert_eq(rational_add(rational(1, 3), rational(1, 6)), rational(1, 2))
  assert_eq(rational_subtract(rational(2, 3), rational(5, 6)), rational(-1, 6))
  assert_eq(
    rational_multiply(rational(-3, 7), rational(14, 9)),
    rational(-2, 3),
  )
  assert_eq(
    rational_divide(rational(2, 3), rational(-4, 5)),
    Some(rational(-5, 6)),
  )
  assert_eq(ratio(integer(1), binary(0)), None)
  assert_eq(rational_divide(rational_one(), rational_zero()), None)
  for a in -5..<=5 {
    for b in 1..<7 {
      let r = rational(a, b)
      assert_eq(rational_subtract(r, r), rational_zero())
      if a != 0 {
        assert_eq(rational_divide(r, r), Some(rational_one()))
      }
    }
  }
}
