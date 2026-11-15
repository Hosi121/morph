///|
fn[A] required(result : Result[A, AesError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("AES test operation")
  }
}

///|
fn test_octet(value : Int32) -> Octet {
  match from_binary(@oracle.binary(value)) {
    Some(value) => value
    None => abort("AES test octet")
  }
}

///|
fn native(value : Octet) -> Int32 {
  @oracle.int_of_binary(binary(value))
}

///|
fn test_block(values : Array[Int32]) -> Block {
  match block(@oracle.chain(values.map(test_octet))) {
    Some(value) => value
    None => abort("AES test block")
  }
}

///|
fn native_block(value : Block) -> Array[Int32] {
  @oracle.array(octets(value)).map(native)
}

///|
fn hex_octets(text : String) -> @core.Chain[Octet] {
  let result = []
  let mut high : Int32? = None
  for character in text {
    let digit = match character {
      '0' => 0
      '1' => 1
      '2' => 2
      '3' => 3
      '4' => 4
      '5' => 5
      '6' => 6
      '7' => 7
      '8' => 8
      '9' => 9
      'a' => 10
      'b' => 11
      'c' => 12
      'd' => 13
      'e' => 14
      'f' => 15
      _ => abort("AES fixture hex digit")
    }
    match high {
      None => high = Some(digit)
      Some(value) => {
        result.push(test_octet(value * 16 + digit))
        high = None
      }
    }
  }
  guard high is None else { abort("odd AES fixture hex length") }
  @oracle.chain(result)
}

///|
fn hex_block(text : String) -> Block {
  match block(hex_octets(text)) {
    Some(value) => value
    None => abort("AES fixture block")
  }
}

///|
fn native_multiply(a : Int32, b : Int32) -> Int32 {
  let mut a = a
  let mut b = b
  let mut result = 0
  for _ in 0..<8 {
    if (b & 1) != 0 {
      result = result ^ a
    }
    a = ((a << 1) ^ (if (a & 128) != 0 { 283 } else { 0 })) & 255
    b = b >> 1
  }
  result
}

///|
fn native_mix(values : Array[Int32], inverse : Bool) -> Array[Int32] {
  let matrix = if inverse {
    [[14, 11, 13, 9], [9, 14, 11, 13], [13, 9, 14, 11], [11, 13, 9, 14]]
  } else {
    [[2, 3, 1, 1], [1, 2, 3, 1], [1, 1, 2, 3], [3, 1, 1, 2]]
  }
  let result = Array::make(16, 0)
  for column in 0..<4 {
    for row in 0..<4 {
      for index in 0..<4 {
        result[column * 4 + row] = result[column * 4 + row] ^
          native_multiply(matrix[row][index], values[column * 4 + index])
      }
    }
  }
  result
}

///|
fn assert_sbox_fixture(
  expected : Array[Int32],
  inverse : Array[Int32],
) -> Unit raise {
  let context = required(tables())
  assert_eq(@galois.cardinality(byte_field(context)), @oracle.binary(256))
  for value in 0..<256 {
    let input = test_octet(value)
    assert_eq(native(required(calculate_sbox(context, input))), expected[value])
    assert_eq(native(required(sbox(context, input))), expected[value])
    assert_eq(native(required(inverse_sbox(context, input))), inverse[value])
    assert_eq(
      required(inverse_sbox(context, required(sbox(context, input)))),
      input,
    )
    assert_eq(
      required(sbox(context, required(inverse_sbox(context, input)))),
      input,
    )
  }
}

///|
fn assert_transform_fixture(
  context : Tables,
  initial_key : String,
  input : String,
  stages : Array[(String, String)],
) -> Unit raise {
  let mut previous = hex_block(input)
  let mut first = true
  for (operation, output) in stages {
    let expected = hex_block(output)
    match operation {
      "Substitution" => {
        assert_eq(sub_bytes(context, previous), Ok(expected))
        assert_eq(inverse_sub_bytes(context, expected), Ok(previous))
      }
      "ShiftRow" => {
        assert_eq(shift_rows(previous), expected)
        assert_eq(inverse_shift_rows(expected), previous)
      }
      "MixColumn" => {
        assert_eq(mix_columns(previous), expected)
        assert_eq(inverse_mix_columns(expected), previous)
      }
      "KeyAddition" =>
        if first {
          assert_eq(add_round_key(previous, hex_block(initial_key)), expected)
        }
      _ => abort("unknown official AES stage")
    }
    previous = expected
    first = false
  }
}

///|
test "fixed octets reject malformed widths and AES multiplication exhausts native products" {
  for value in 0..<256 {
    let a = test_octet(value)
    assert_eq(native(a), value)
    assert_eq(octet(bits(a)), Some(a))
    assert_eq(native(xtime(a)), native_multiply(value, 2))
    for other in 0..<256 {
      let b = test_octet(other)
      assert_eq(native(xor(a, b)), value ^ other)
      assert_eq(native(multiply(a, b)), native_multiply(value, other))
    }
  }
  for width in [0, 1, 7, 9, 16] {
    assert_eq(octet(@core.replicate(@oracle.nat(width), false)), None)
  }
  for value in [256, 257, 65535] {
    assert_eq(from_binary(@oracle.binary(value)), None)
  }
  for size in [0, 1, 15, 17, 32] {
    assert_eq(block(@core.replicate(@oracle.nat(size), zero())), None)
  }
  assert_eq(native(multiply(test_octet(87), test_octet(19))), 254)
}

///|
test "specialized field products agree with Galois basis products and preserve byte identity" {
  let context = required(tables())
  for value in 0..<256 {
    let a = test_octet(value)
    let algebraic = required(to_galois(context, a))
    assert_eq(from_galois(context, algebraic), Ok(a))
    for bit in 0..<8 {
      let b = test_octet(1 << bit)
      let product = match
        @galois.multiply(algebraic, required(to_galois(context, b))) {
        Ok(value) => value
        Err(_) => abort("AES Galois basis multiplication")
      }
      assert_eq(from_galois(context, product), Ok(multiply(a, b)))
    }
  }
  let foreign_polynomial = @fppoly.polynomial(
    @galois.prime_field(byte_field(context)),
    @oracle.chain([1, 1, 1].map(@oracle.binary)),
  )
  let proof = match @fppoly.irreducibility(foreign_polynomial) {
    Ok(Some(value)) => value
    _ => abort("foreign AES field")
  }
  let foreign = match @galois.extension(foreign_polynomial, proof) {
    Some(value) => value
    None => abort("foreign AES extension")
  }
  assert_eq(
    from_galois(context, @galois.zero(foreign)),
    Err(Algebra(@galois.FieldMismatch)),
  )
}

///|
test "column-major permutations and direct inverse matrices agree on every state basis bit" {
  let indices = test_block([ for i in 0..<16 => i ])
  assert_eq(native_block(shift_rows(indices)), [
    0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11,
  ])
  assert_eq(inverse_shift_rows(shift_rows(indices)), indices)
  for position in 0..<16 {
    for bit in 0..<8 {
      let values = Array::make(16, 0)
      values[position] = 1 << bit
      let state = test_block(values)
      assert_eq(native_block(mix_columns(state)), native_mix(values, false))
      assert_eq(
        native_block(inverse_mix_columns(state)),
        native_mix(values, true),
      )
      assert_eq(inverse_mix_columns(mix_columns(state)), state)
      assert_eq(mix_columns(inverse_mix_columns(state)), state)
    }
  }
  for family in 0..<48 {
    let values = [
      for i in 0..<16 => (family * 73 + i * i * 13 + i * 17) % 256
    ]
    let state = test_block(values)
    assert_eq(native_block(mix_columns(state)), native_mix(values, false))
    assert_eq(
      native_block(inverse_mix_columns(state)),
      native_mix(values, true),
    )
    assert_eq(add_round_key(add_round_key(state, indices), indices), state)
  }
}
