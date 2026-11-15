///|
fn bit_message(data : Bytes) -> @core.Chain[Bool] {
  let bits = []
  for byte in data {
    for i in 0..<8 {
      bits.push((byte.to_int() & (1 << (7 - i))) != 0)
    }
  }
  @oracle.chain(bits)
}

///|
fn hex(bits : @core.Chain[Bool]) -> String {
  let data = @oracle.array(bits)
  let alphabet = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  let result = StringBuilder()
  for i in 0..<(data.length() / 4) {
    let mut digit = 0
    for j in 0..<4 {
      digit = digit * 2 + (if data[i * 4 + j] { 1 } else { 0 })
    }
    result.write_char(alphabet[digit])
  }
  result.to_string()
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
