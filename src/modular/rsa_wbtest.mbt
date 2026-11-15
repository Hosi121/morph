///|
test "textbook RSA round trips every representative, including non-coprime messages" {
  match rsa_key(@oracle.binary(11), @oracle.binary(13), @oracle.binary(7)) {
    None => fail("valid small key rejected")
    Some(key) => {
      assert_eq(@oracle.int_of_binary(key.private_exponent), 103)
      for message in 0..<143 {
        let plain = @oracle.binary(message)
        let mut expected = 1
        for _ in 0..<7 {
          expected = expected * message % 143
        }
        match rsa_encrypt(key, plain) {
          None => fail("valid representative rejected")
          Some(cipher) => {
            assert_eq(@oracle.int_of_binary(cipher), expected)
            assert_eq(rsa_decrypt(key, cipher), Some(plain))
          }
        }
      }
      assert_eq(rsa_encrypt(key, @oracle.binary(143)), None)
      assert_eq(rsa_decrypt(key, @oracle.binary(143)), None)
    }
  }
  assert_eq(
    rsa_key(@oracle.binary(9), @oracle.binary(13), @oracle.binary(7)),
    None,
  )
  assert_eq(
    rsa_key(@oracle.binary(11), @oracle.binary(11), @oracle.binary(7)),
    None,
  )
  assert_eq(
    rsa_key(@oracle.binary(11), @oracle.binary(13), @oracle.binary(6)),
    None,
  )
  assert_eq(
    rsa_key(@oracle.binary(11), @oracle.binary(13), @oracle.binary(1)),
    None,
  )
}
