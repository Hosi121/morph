///|
fn checked_field() -> CheckedField[@binary.Binary, String] {
  let field = test_field(5)
  {
    zero: field.zero,
    one: field.one,
    add: fn(a, b) { Ok((field.add)(a, b)) },
    subtract: fn(a, b) { Ok((field.subtract)(a, b)) },
    negate: fn(a) { Ok((field.negate)(a)) },
    multiply: fn(a, b) { Ok((field.multiply)(a, b)) },
    inverse: fn(a) { Ok((field.inverse)(a)) },
  }
}

///|
test "checked BM agrees with total dictionaries and preserves arithmetic errors" {
  let field = checked_field()
  for
    input in [
      [],
      [0],
      [1, 0],
      [0, 0, 1],
      [1, 2, 4, 3, 1, 2],
      [0, 1, 1, 2, 3, 0, 3],
    ] {
    let input = @oracle.chain(input.map(@oracle.binary))
    let expected = match berlekamp_massey(test_field(5), input) {
      Some(value) => value
      None => abort("checked BM expectation")
    }
    assert_eq(checked_berlekamp_massey(field, input), Ok(expected))
    assert_eq(checked_check(field, input, expected), Ok(true))
  }
  let input = @oracle.chain([@oracle.binary(1), @oracle.binary(2)])
  assert_eq(
    checked_berlekamp_massey(
      { ..field, add: fn(_, _) { Err("addition") }, },
      input,
    ),
    Err(Arithmetic("addition")),
  )
  assert_eq(
    checked_berlekamp_massey(
      { ..field, inverse: fn(_) { Err("inversion") }, },
      input,
    ),
    Err(Arithmetic("inversion")),
  )
  assert_eq(
    checked_berlekamp_massey({ ..field, inverse: fn(_) { Ok(None) }, }, input),
    Err(InvalidField),
  )
  let recurrence = {
    length: @oracle.nat(1),
    connection: @oracle.chain([@oracle.binary(1), @oracle.binary(3)]),
  }
  assert_eq(
    checked_check(
      { ..field, add: fn(_, _) { Err("check addition") }, },
      input,
      recurrence,
    ),
    Err(Arithmetic("check addition")),
  )
  assert_eq(
    checked_check(field, input, { ..recurrence, connection: @core.Nil, }),
    Ok(false),
  )
}
