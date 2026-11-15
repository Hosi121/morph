///|
fn bit_message(data : Bytes) -> @core.Chain[Bool] {
  @oracle.bits_from_bytes(data)
}

///|
fn hex(bits : @core.Chain[Bool]) -> String {
  @oracle.hex_bits(bits)
}

///|
fn assert_hash_bytes(data : Bytes, expected : String) -> Unit raise {
  assert_hash_bits(bit_message(data), expected)
}

///|
fn assert_hash_bits(
  message : @core.Chain[Bool],
  expected : String,
) -> Unit raise {
  match hash(message) {
    None => fail("valid message rejected")
    Some(bits) => {
      assert_eq(@oracle.int_of_nat(@core.length(bits)), 256)
      assert_eq(hex(bits), expected)
    }
  }
}

///|
test "SHA-256 standard empty, abc and multiblock examples" {
  assert_hash_bytes(
    b"", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
  assert_hash_bytes(
    b"abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  assert_hash_bytes(
    b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
  )
}
