///|
fn signed_reduce_before_n04(m : Modulus, a : @exact.Integer) -> @binary.Binary {
  let remainder = reduce(m, @exact.magnitude(a))
  match @exact.negative(a) {
    false => remainder
    true => subtract(m, @binary.zero(), remainder)
  }
}

///|
test "N04 signed residue exhaustive host and legacy oracle" {
  for m in 0..<65 {
    let ring = Modulus::{ value: @oracle.binary(m), }
    for a in -257..<258 {
      let value = @oracle.integer(a)
      let actual = signed_reduce(ring, value)
      assert_eq(actual, signed_reduce_before_n04(ring, value))
      assert_eq(
        @oracle.int_of_binary(actual),
        if m == 0 {
          0
        } else {
          (a % m + m) % m
        },
      )
    }
  }
  assert_eq(modulus(@binary.zero()), None)
  assert_eq(modulus(@binary.one()), None)
}

///|
test "N04 Python bigint full signed residue fixtures" {
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("2"), }
    let positive = @exact.positive(@oracle.binary_from_hex("1"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("1"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("2"), }
    let positive = @exact.positive(@oracle.binary_from_hex("2"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("0"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("11"), }
    let positive = @exact.positive(@oracle.binary_from_hex("10"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("1"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("11"), }
    let positive = @exact.positive(@oracle.binary_from_hex("11"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("0"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("11"), }
    let positive = @exact.positive(@oracle.binary_from_hex("12"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("10"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("10001"), }
    let positive = @exact.positive(@oracle.binary_from_hex("10000"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("1"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("10001"), }
    let positive = @exact.positive(@oracle.binary_from_hex("10001"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("0"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("10001"), }
    let positive = @exact.positive(@oracle.binary_from_hex("10002"))
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("10000"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("10001"), }
    let positive = @exact.positive(
      @oracle.binary_from_hex(
        "f123456789abcdeff123456789abcdeff123456789abcdeff123456789abcdef",
      ),
    )
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("9ddf"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{ value: @oracle.binary_from_hex("10001"), }
    let positive = @exact.positive(
      @oracle.binary_from_hex(
        "f123456789abcdeff123456789abcdeff123456789abcdeff123456789abcdef",
      ),
    )
    let input = positive
    let actual = signed_reduce(ring, input)
    assert_eq(actual, @oracle.binary_from_hex("6222"))
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{
      value: @oracle.binary_from_hex("7fffffffffffffffffffffffffffffff"),
    }
    let positive = @exact.positive(
      @oracle.binary_from_hex(
        "f123456789abcdeff123456789abcdeff123456789abcdeff123456789abcdef",
      ),
    )
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(
      actual,
      @oracle.binary_from_hex("2c962fc962fc96302c962fc962fc962d"),
    )
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  {
    let ring = Modulus::{
      value: @oracle.binary_from_hex(
        "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
      ),
    }
    let positive = @exact.positive(
      @oracle.binary_from_hex(
        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      ),
    )
    let input = @exact.negate(positive)
    let actual = signed_reduce(ring, input)
    assert_eq(
      actual,
      @oracle.binary_from_hex(
        "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffe02ede",
      ),
    )
    assert_eq(actual, signed_reduce_before_n04(ring, input))
  }
  let ring = Modulus::{
    value: @oracle.binary_from_hex(
      "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
    ),
  }
  let positive = @exact.positive(
    @oracle.binary_from_hex(
      "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    ),
  )
  let input = positive
  let actual = signed_reduce(ring, input)
  assert_eq(actual, @oracle.binary_from_hex("1fd10f"))
  assert_eq(actual, signed_reduce_before_n04(ring, input))
}
