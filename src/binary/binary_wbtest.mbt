///|
test "binary arithmetic exhaustive small domain" {
  for a in 0..<96 {
    for b in 0..<96 {
      let x = @oracle.binary(a)
      let y = @oracle.binary(b)
      assert_eq(@oracle.int_of_binary(add(x, y)), a + b)
      assert_eq(@oracle.int_of_binary(multiply(x, y)), a * b)
      assert_eq(
        compare(x, y),
        if a < b {
          @core.Less
        } else if a > b {
          @core.Greater
        } else {
          @core.Equal
        },
      )
      match subtract(x, y) {
        None => assert_true(a < b)
        Some(z) => assert_eq(@oracle.int_of_binary(z), a - b)
      }
      match divmod(x, y) {
        None => assert_eq(b, 0)
        Some((q, r)) => {
          assert_eq(@oracle.int_of_binary(q), a / b)
          assert_eq(@oracle.int_of_binary(r), a % b)
        }
      }
    }
  }
}

///|
test "carry chains, normalization, power, gcd and unary round trip" {
  assert_eq(@oracle.int_of_binary(successor(@oracle.binary(65535))), 65536)
  assert_eq(@oracle.int_of_binary(from_bits(Cons(false, Cons(false, Nil)))), 0)
  assert_eq(
    @oracle.int_of_binary(power(@oracle.binary(3), @oracle.binary(9))),
    19683,
  )
  assert_eq(
    @oracle.int_of_binary(gcd(@oracle.binary(1071), @oracle.binary(462))),
    21,
  )
  for n in 0..<128 {
    assert_eq(from_nat(to_nat(@oracle.binary(n))), @oracle.binary(n))
    assert_eq(@oracle.int_of_binary(double(@oracle.binary(n))), n * 2)
    assert_eq(@oracle.int_of_binary(half(@oracle.binary(n))), n / 2)
  }
}

///|
test "word concatenation needs width and pairing preserves both coordinates" {
  // The raw low word 01 (little endian) has width 2, even though its value is 2.
  let low = @core.Cons(false, Cons(true, Nil))
  let high = bits(@oracle.binary(7))
  assert_eq(
    @oracle.int_of_binary(from_bits(concat_words(low, high))),
    2 + 4 * 7,
  )
  // [true,false] has value 1 but width 2; canonicalizing before concat changes it.
  let padded = @core.Cons(true, Cons(false, Nil))
  assert_eq(
    @oracle.int_of_binary(from_bits(concat_words(padded, high))),
    1 + 4 * 7,
  )
  for a in 0..<10 {
    for b in 0..<32 {
      let unary = to_nat(@oracle.binary(a))
      let encoded = pair(unary, @oracle.binary(b))
      assert_eq(@oracle.int_of_binary(encoded), (1 << a) * (2 * b + 1))
      assert_eq(unpair(encoded), Some((unary, @oracle.binary(b))))
    }
  }
  assert_eq(unpair(zero()), None)
}
