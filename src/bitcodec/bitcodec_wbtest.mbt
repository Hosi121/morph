///|
test "gamma codes and pair words round trip with exact stream boundaries" {
  let suffix = @oracle.chain([true, false, false, true])
  for n in 1..<=1024 {
    match gamma_encode(@oracle.binary(n)) {
      None => fail("positive number rejected")
      Some(code) =>
        assert_eq(
          gamma_read(@core.append(code, suffix)),
          Some((@oracle.binary(n), suffix)),
        )
    }
  }
  for a in 0..<128 {
    for b in 0..<128 {
      let x = @oracle.binary(a)
      let y = @oracle.binary(b)
      let word = pair_word(x, y)
      assert_eq(decode_pair(word), Some((x, y)))
      assert_eq(read_pair(@core.append(word, suffix)), Some(((x, y), suffix)))
      assert_eq(decode_pair(@core.append(word, suffix)), None)
    }
  }
  assert_eq(gamma_encode(@oracle.binary(0)), None)
  assert_eq(gamma_read(@oracle.chain([false, false, true])), None)
  assert_eq(read_pair(@oracle.chain([true])), None)
}

///|
test "large binary coordinates stay proportional to their bit widths" {
  let a = @binary.from_bits(
    @core.append(
      @core.replicate(@oracle.nat(600), false),
      @core.Cons(true, Nil),
    ),
  )
  let b = @binary.from_bits(
    @core.append(
      @core.replicate(@oracle.nat(400), false),
      @core.Cons(true, Nil),
    ),
  )
  let code = pair_word(a, b)
  assert_eq(@oracle.int_of_nat(@core.length(code)), 2002)
  assert_eq(decode_pair(code), Some((a, b)))
}
