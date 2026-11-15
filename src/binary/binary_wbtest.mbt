///|
fn number(n : Int32) -> Binary {
  fn go(n : Int32) -> @core.Chain[Bool] {
    if n == 0 {
      Nil
    } else {
      Cons(n % 2 == 1, go(n / 2))
    }
  }
  from_bits(go(n))
}

///|
fn integer(n : Binary) -> Int32 {
  fn go(xs : @core.Chain[Bool]) -> Int32 {
    match xs {
      Nil => 0
      Cons(bit, rest) => (if bit { 1 } else { 0 }) + 2 * go(rest)
    }
  }
  go(bits(n))
}

///|
test "binary arithmetic exhaustive small domain" {
  for a in 0..<96 {
    for b in 0..<96 {
      let x = number(a)
      let y = number(b)
      assert_eq(integer(add(x, y)), a + b)
      assert_eq(integer(multiply(x, y)), a * b)
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
        Some(z) => assert_eq(integer(z), a - b)
      }
      match divmod(x, y) {
        None => assert_eq(b, 0)
        Some((q, r)) => {
          assert_eq(integer(q), a / b)
          assert_eq(integer(r), a % b)
        }
      }
    }
  }
}

///|
test "carry chains, normalization, power, gcd and unary round trip" {
  assert_eq(integer(successor(number(65535))), 65536)
  assert_eq(integer(from_bits(Cons(false, Cons(false, Nil)))), 0)
  assert_eq(integer(power(number(3), number(9))), 19683)
  assert_eq(integer(gcd(number(1071), number(462))), 21)
  for n in 0..<128 {
    assert_eq(from_nat(to_nat(number(n))), number(n))
    assert_eq(integer(double(number(n))), n * 2)
    assert_eq(integer(half(number(n))), n / 2)
  }
}

///|
test "word concatenation needs width and pairing preserves both coordinates" {
  // The raw low word 01 (little endian) has width 2, even though its value is 2.
  let low = @core.Cons(false, Cons(true, Nil))
  let high = bits(number(7))
  assert_eq(integer(from_bits(concat_words(low, high))), 2 + 4 * 7)
  // [true,false] has value 1 but width 2; canonicalizing before concat changes it.
  let padded = @core.Cons(true, Cons(false, Nil))
  assert_eq(integer(from_bits(concat_words(padded, high))), 1 + 4 * 7)
  for a in 0..<10 {
    for b in 0..<32 {
      let unary = to_nat(number(a))
      let encoded = pair(unary, number(b))
      assert_eq(integer(encoded), (1 << a) * (2 * b + 1))
      assert_eq(unpair(encoded), Some((unary, number(b))))
    }
  }
  assert_eq(unpair(zero()), None)
}
