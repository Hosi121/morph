///|
test "signed binary arithmetic over all pairs from minus sixteen to sixteen" {
  for a in -16..<=16 {
    for b in -16..<=16 {
      assert_eq(
        @oracle.int_of_integer(add(@oracle.integer(a), @oracle.integer(b))),
        a + b,
      )
      assert_eq(
        @oracle.int_of_integer(subtract(@oracle.integer(a), @oracle.integer(b))),
        a - b,
      )
      assert_eq(
        @oracle.int_of_integer(multiply(@oracle.integer(a), @oracle.integer(b))),
        a * b,
      )
      assert_eq(
        compare(@oracle.integer(a), @oracle.integer(b)),
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
  assert_eq(negate(@oracle.integer(0)), @oracle.integer(0))
}

///|
test "exact rational field identities and normalization" {
  assert_eq(@oracle.rational(2, 4), @oracle.rational(1, 2))
  assert_eq(@oracle.rational(-6, 9), @oracle.rational(-2, 3))
  assert_eq(
    rational_add(@oracle.rational(1, 3), @oracle.rational(1, 6)),
    @oracle.rational(1, 2),
  )
  assert_eq(
    rational_subtract(@oracle.rational(2, 3), @oracle.rational(5, 6)),
    @oracle.rational(-1, 6),
  )
  assert_eq(
    rational_multiply(@oracle.rational(-3, 7), @oracle.rational(14, 9)),
    @oracle.rational(-2, 3),
  )
  assert_eq(
    rational_divide(@oracle.rational(2, 3), @oracle.rational(-4, 5)),
    Some(@oracle.rational(-5, 6)),
  )
  assert_eq(ratio(@oracle.integer(1), @oracle.binary(0)), None)
  assert_eq(rational_divide(rational_one(), rational_zero()), None)
  for a in -5..<=5 {
    for b in 1..<7 {
      let r = @oracle.rational(a, b)
      assert_eq(rational_subtract(r, r), rational_zero())
      if a != 0 {
        assert_eq(rational_divide(r, r), Some(rational_one()))
      }
    }
  }
}
