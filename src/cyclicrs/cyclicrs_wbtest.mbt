///|
struct NativeField {
  p : Int32
  modulus : Array[Int32]
  width : Int32
  size : Int32
  binary_modulus : Int32
}

///|
fn native_field(p : Int32, modulus : Array[Int32]) -> NativeField {
  let width = modulus.length() - 1
  let size = for i = 0, size = 1; i < width; {
    continue i + 1, size * p
  } nobreak {
    size
  }
  let binary_modulus = for i = 0, value = 0; i < modulus.length(); {
    continue i + 1, value | (modulus[i] << i)
  } nobreak {
    value
  }
  { p, modulus, width, size, binary_modulus, }
}

///|
fn digits(field : NativeField, value : Int32) -> Array[Int32] {
  let mut rest = value
  [
    for _ in 0..<field.width => {
      let digit = rest % field.p
      rest /= field.p
      digit
    }
  ]
}

///|
fn from_digits(field : NativeField, values : Array[Int32]) -> Int32 {
  for i = values.length() - 1, result = 0; i >= 0; {
    continue i - 1, result * field.p + values[i]
  } nobreak {
    result
  }
}

///|
fn native_add(field : NativeField, a : Int32, b : Int32) -> Int32 {
  if field.p == 2 {
    return a ^ b
  }
  let a = digits(field, a)
  let b = digits(field, b)
  from_digits(field, [ for i in 0..<field.width => (a[i] + b[i]) % field.p ])
}

///|
fn native_negate(field : NativeField, value : Int32) -> Int32 {
  if field.p == 2 {
    return value
  }
  from_digits(
    field,
    digits(field, value).map(fn(value) { (field.p - value) % field.p }),
  )
}

///|
// Characteristic two uses machine carryless shift/XOR reduction, independently
// of the kernel's dense Binary-coefficient convolution and polynomial division.
fn native_multiply(field : NativeField, a : Int32, b : Int32) -> Int32 {
  if field.p == 2 {
    let mut a = a
    let mut b = b
    let mut result = 0
    while b != 0 {
      if (b & 1) != 0 {
        result = result ^ a
      }
      b = b >> 1
      a = a << 1
      if (a & field.size) != 0 {
        a = a ^ field.binary_modulus
      }
    }
    return result
  }
  let a = digits(field, a)
  let b = digits(field, b)
  let product = Array::make(field.width * 2 - 1, 0)
  for i in 0..<field.width {
    for j in 0..<field.width {
      product[i + j] += a[i] * b[j]
    }
  }
  for degree = product.length() - 1; degree >= field.width; degree = degree - 1 {
    let scalar = (product[degree] % field.p + field.p) % field.p
    for j in 0..<field.modulus.length() {
      product[degree - field.width + j] -= scalar * field.modulus[j]
    }
  }
  from_digits(
    field,
    product[:field.width]
    .to_owned()
    .map(fn(value) { (value % field.p + field.p) % field.p }),
  )
}

///|
fn native_power(field : NativeField, value : Int32, exponent : Int32) -> Int32 {
  for base = value, rest = exponent, result = 1; rest > 0; {
    continue native_multiply(field, base, base),
      rest / 2,
      if rest % 2 == 1 {
        native_multiply(field, result, base)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
fn native_poly_multiply(
  field : NativeField,
  a : Array[Int32],
  b : Array[Int32],
) -> Array[Int32] {
  if a.is_empty() || b.is_empty() {
    return []
  }
  let result = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      result[i + j] = native_add(
        field,
        result[i + j],
        native_multiply(field, a[i], b[j]),
      )
    }
  }
  result
}

///|
fn native_evaluate(
  field : NativeField,
  polynomial : Array[Int32],
  point : Int32,
) -> Int32 {
  for i = polynomial.length() - 1, result = 0; i >= 0; {
    continue i - 1,
      native_add(field, polynomial[i], native_multiply(field, point, result))
  } nobreak {
    result
  }
}

///|
fn native_generator(
  field : NativeField,
  root : Int32,
  t : Int32,
) -> Array[Int32] {
  for j = 1, result = [1]; j <= t * 2; {
    continue j + 1,
      native_poly_multiply(field, result, [
        native_negate(field, native_power(field, root, j)),
        1,
      ])
  } nobreak {
    result
  }
}

///|
fn native_encode(
  field : NativeField,
  generator : Array[Int32],
  message : Array[Int32],
) -> Array[Int32] {
  let parity = generator.length() - 1
  let shifted = Array::make(parity + message.length(), 0)
  for i in 0..<message.length() {
    shifted[parity + i] = message[i]
  }
  let remainder = shifted.copy()
  for degree = remainder.length() - 1; degree >= parity; degree = degree - 1 {
    let scalar = remainder[degree]
    for j in 0..<generator.length() {
      remainder[degree - parity + j] = native_add(
        field,
        remainder[degree - parity + j],
        native_negate(field, native_multiply(field, scalar, generator[j])),
      )
    }
  }
  for i in 0..<parity {
    shifted[i] = native_negate(field, remainder[i])
  }
  shifted
}

///|
fn native_syndrome(
  field : NativeField,
  root : Int32,
  t : Int32,
  received : Array[Int32],
) -> Array[Int32] {
  [
    for j in 1..<(t * 2 + 1) => {
      native_evaluate(field, received, native_power(field, root, j))
    }
  ]
}

///|
fn[A] required(result : Result[A, CodeError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("cyclic RS test operation")
  }
}

///|
fn[A] algebra_required(result : Result[A, @galois.FieldError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("cyclic RS test algebra")
  }
}

///|
fn extension_field(field : NativeField) -> @galois.Field {
  let prime = match @primefield.field(@oracle.binary(field.p)) {
    Some(value) => value
    None => abort("cyclic RS prime")
  }
  let polynomial = @fppoly.polynomial(
    prime,
    @oracle.chain(field.modulus.map(@oracle.binary)),
  )
  let certificate = match @fppoly.irreducibility(polynomial) {
    Ok(Some(value)) => value
    _ => abort("cyclic RS irreducibility")
  }
  match @galois.extension(polynomial, certificate) {
    Some(value) => value
    None => abort("cyclic RS field")
  }
}

///|
fn symbol(
  field : @galois.Field,
  native : NativeField,
  value : Int32,
) -> @galois.Element {
  algebra_required(
    @galois.element(
      field,
      @fppoly.polynomial(
        @galois.prime_field(field),
        @oracle.chain(digits(native, value).map(@oracle.binary)),
      ),
    ),
  )
}

///|
fn native_symbol(field : NativeField, value : @galois.Element) -> Int32 {
  from_digits(
    field,
    @oracle.array(@fppoly.coefficients(@galois.representative(value))).map(
      @oracle.int_of_binary,
    ),
  )
}

///|
fn word(
  plan : Plan,
  native : NativeField,
  values : Array[Int32],
) -> @core.Chain[@galois.Element] {
  @oracle.chain(values.map(fn(value) { symbol(field_of(plan), native, value) }))
}

///|
fn native_word(
  field : NativeField,
  word : @core.Chain[@galois.Element],
) -> Array[Int32] {
  @oracle.array(word).map(fn(value) { native_symbol(field, value) })
}

///|
fn test_plan(
  native : NativeField,
  root : Int32,
  order : Int32,
  n : Int32,
  t : Int32,
) -> Plan {
  let field = extension_field(native)
  required(
    plan(
      field,
      symbol(field, native, root),
      @oracle.nat(order),
      @oracle.nat(n),
      @oracle.nat(t),
    ),
  )
}

///|
fn assert_correction(
  plan : Plan,
  native : NativeField,
  root : Int32,
  message : Array[Int32],
  encoded : Array[Int32],
  positions : Array[Int32],
  values : Array[Int32],
  check_result~ : Bool = true,
) -> Unit raise {
  let received = encoded.copy()
  for i in 0..<positions.length() {
    received[positions[i]] = native_add(
      native,
      received[positions[i]],
      values[i],
    )
  }
  let symbolic = word(plan, native, received)
  assert_eq(
    native_word(native, required(syndrome(plan, symbolic))),
    native_syndrome(native, root, @oracle.int_of_nat(radius(plan)), received),
  )
  let decoded = required(decode(plan, symbolic))
  assert_eq(native_word(native, decoded.message), message)
  assert_eq(native_word(native, decoded.corrected), encoded)
  assert_eq(
    @oracle.array(decoded.error_positions).map(@oracle.int_of_nat),
    positions,
  )
  assert_eq(native_word(native, decoded.error_values), values)
  if check_result {
    assert_true(check(plan, symbolic, decoded))
  }
}

///|
fn assert_cyclic_fixture(
  p : Int32,
  modulus : Array[Int32],
  alpha : Int32,
  order : Int32,
  n : Int32,
  t : Int32,
  message : Array[Int32],
  encoded : Array[Int32],
  positions : Array[Int32],
  magnitudes : Array[Int32],
  expected_syndromes : Array[Int32],
  expected_locator : Array[Int32],
  expected_evaluator : Array[Int32],
) -> Unit raise {
  let native = native_field(p, modulus)
  let plan = test_plan(native, alpha, order, n, t)
  assert_eq(
    native_word(native, required(encode(plan, word(plan, native, message)))),
    encoded,
  )
  let received = encoded.copy()
  for i in 0..<positions.length() {
    received[positions[i]] = native_add(
      native,
      received[positions[i]],
      magnitudes[i],
    )
  }
  let syndromes = required(syndrome(plan, word(plan, native, received)))
  assert_eq(native_word(native, syndromes), expected_syndromes)
  let recurrence = match
    @recurrence.checked_berlekamp_massey(bm_field(plan.field), syndromes) {
    Ok(value) => value
    Err(_) => abort("fixture BM")
  }
  assert_eq(native_word(native, recurrence.connection), expected_locator)
  let product = algebra_required(
    polynomial_multiply(plan.field, syndromes, recurrence.connection),
  )
  assert_eq(
    native_word(native, trim(@core.take(@oracle.nat(t * 2), product))),
    expected_evaluator,
  )
  assert_correction(
    plan, native, alpha, message, encoded, positions, magnitudes,
  )
}

///|
test "all GF4 length-three received words agree with an independent nearest-codeword oracle" {
  let field = native_field(2, [1, 1, 1])
  let plan = test_plan(field, 2, 3, 3, 1)
  assert_eq(
    native_word(field, generator_polynomial(plan)),
    native_generator(field, 2, 1),
  )
  for code in 0..<64 {
    let received = [code % 4, code / 4 % 4, code / 16 % 4]
    let nearby = [
      for value in 0..<4 if received
      .filter(fn(other) { other != value })
      .length() <=
      1 => value
    ]
    match decode(plan, word(plan, field, received)) {
      Ok(decoded) => {
        assert_eq(nearby.length(), 1)
        assert_eq(native_word(field, decoded.message), [nearby[0]])
        assert_eq(native_word(field, decoded.corrected), [
          nearby[0],
          nearby[0],
          nearby[0],
        ])
        assert_true(check(plan, word(plan, field, received), decoded))
      }
      Err(Uncorrectable) => assert_eq(nearby.length(), 0)
      _ => fail("unexpected GF4 decoder failure")
    }
  }
}

///|
test "GF16 length fifteen radius two exhausts single errors and all double-error positions" {
  let field = native_field(2, [1, 1, 0, 0, 1])
  let plan = test_plan(field, 2, 15, 15, 2)
  let message = [ for i in 0..<11 => (i * i + 3 * i + 1) % 16 ]
  message[10] = 0
  let expected = native_encode(field, native_generator(field, 2, 2), message)
  assert_eq(
    native_word(field, generator_polynomial(plan)),
    native_generator(field, 2, 2),
  )
  assert_eq(
    native_word(field, required(encode(plan, word(plan, field, message)))),
    expected,
  )
  assert_correction(plan, field, 2, message, expected, [], [])
  for position in 0..<15 {
    for value in 1..<16 {
      assert_correction(plan, field, 2, message, expected, [position], [value])
    }
  }
  for left in 0..<15 {
    for right in (left + 1)..<15 {
      for values in [[1, 1], [1, 15], [7, 9], [15, 2]] {
        assert_correction(
          plan,
          field,
          2,
          message,
          expected,
          [left, right],
          values,
        )
      }
    }
  }
}

///|
test "GF9 radius two exhausts odd-characteristic error magnitudes and double-error positions" {
  let field = native_field(3, [1, 0, 1])
  let plan = test_plan(field, 4, 8, 8, 2)
  let message = [1, 3, 4, 8]
  let expected = native_encode(field, native_generator(field, 4, 2), message)
  assert_eq(
    native_word(field, required(encode(plan, word(plan, field, message)))),
    expected,
  )
  for position in 0..<8 {
    for value in 1..<9 {
      assert_correction(plan, field, 4, message, expected, [position], [value])
    }
  }
  for left in 0..<8 {
    for right in (left + 1)..<8 {
      for a in 1..<9 {
        for b in 1..<9 {
          assert_correction(plan, field, 4, message, expected, [left, right], [
            a, b,
          ])
        }
      }
    }
  }
}

///|
test "full GF7 cyclic code agrees with the existing Berlekamp-Welch decoder after evaluation scaling" {
  let field = native_field(7, [0, 1])
  let plan = test_plan(field, 3, 6, 6, 1)
  let message = [1, 2, 3, 4]
  let encoded = native_encode(field, native_generator(field, 3, 1), message)
  let old_field = match @finitefield.field(@oracle.binary(7)) {
    Some(value) => value
    None => abort("old RS field")
  }
  let points = @oracle.chain(
    [
      for i in 0..<6 => @oracle.binary(native_power(field, 3, i))
    ],
  )
  let old_plan = match
    @reedsolomon.plan(old_field, @oracle.nat(4), @oracle.nat(1), points) {
    Some(value) => value
    None => abort("old RS plan")
  }
  for position in 0..<6 {
    for magnitude in 1..<7 {
      let received = encoded.copy()
      received[position] = native_add(field, received[position], magnitude)
      let decoded = required(decode(plan, word(plan, field, received)))
      let scaled = @oracle.chain(
        received.map(fn(value) { @oracle.binary(value * 6 % 7) }),
      )
      let old = match @reedsolomon.decode(old_plan, scaled) {
        Some(value) => value
        None => abort("old BW decode")
      }
      assert_eq(
        @oracle.array(old.corrected).map(@oracle.int_of_binary),
        native_word(field, decoded.corrected).map(fn(value) { value * 6 % 7 }),
      )
      assert_true(
        @reedsolomon.check(
          old_plan,
          @core.map(scaled, fn(value) { Some(value) }),
          old,
        ),
      )
      assert_true(check(plan, word(plan, field, received), decoded))
    }
  }
}

///|
test "GF256 length 255 corrects every single-error position and distributed double errors" {
  let field = native_field(2, [1, 0, 1, 1, 1, 0, 0, 0, 1])
  let plan = test_plan(field, 2, 255, 255, 2)
  let message = [ for i in 0..<251 => (i * 29 + i * i + 7) % 256 ]
  let expected = native_encode(field, native_generator(field, 2, 2), message)
  assert_eq(
    native_word(field, required(encode(plan, word(plan, field, message)))),
    expected,
  )
  for position in 0..<255 {
    assert_correction(
      plan,
      field,
      2,
      message,
      expected,
      [position],
      [position * 31 % 255 + 1],
      check_result=position == 0 || position == 254,
    )
  }
  for family in 0..<32 {
    let a = family * 7 % 255
    let b = (family * 11 + 254) % 255
    let b = if a == b { (b + 1) % 255 } else { b }
    let x = family * 37 % 255 + 1
    let y = (family * 53 + 17) % 255 + 1
    let (positions, magnitudes) = if a < b {
      ([a, b], [x, y])
    } else {
      ([b, a], [y, x])
    }
    assert_correction(
      plan,
      field,
      2,
      message,
      expected,
      positions,
      magnitudes,
      check_result=family == 0,
    )
  }
}

///|
test "shortening and zero-error plans preserve systematic order and exact checks" {
  let field = native_field(2, [1, 1, 0, 0, 1])
  let plan = test_plan(field, 2, 15, 11, 2)
  let message = [0, 1, 2, 3, 4, 5, 0]
  let encoded = native_encode(field, native_generator(field, 2, 2), message)
  assert_eq(length(plan), @oracle.nat(11))
  assert_eq(message_size(plan), @oracle.nat(7))
  assert_eq(radius(plan), @oracle.nat(2))
  assert_eq(root_order(plan), @oracle.nat(15))
  assert_eq(native_symbol(field, root(plan)), 2)
  assert_correction(plan, field, 2, message, encoded, [0, 10], [15, 7])
  let trivial = test_plan(field, 1, 1, 1, 0)
  assert_correction(trivial, field, 1, [7], [7], [], [])
  let subgroup_root = native_power(field, 2, 3)
  let subgroup = test_plan(field, subgroup_root, 5, 5, 1)
  let message = [1, 2, 7]
  let encoded = native_encode(
    field,
    native_generator(field, subgroup_root, 1),
    message,
  )
  assert_correction(subgroup, field, subgroup_root, message, encoded, [4], [15])
}

///|
test "beyond the radius a valid nearest-codeword result can differ from the transmitted message" {
  let field = native_field(2, [1, 1, 1])
  let plan = test_plan(field, 2, 3, 3, 1)
  // Sent [0,0,0], but two corruptions give [1,1,0]. Its radius-one
  // neighbor is [1,1,1], so a bounded-distance decoder returns 1.
  let received = word(plan, field, [1, 1, 0])
  let decoded = required(decode(plan, received))
  assert_eq(native_word(field, decoded.message), [1])
  assert_eq(native_word(field, decoded.corrected), [1, 1, 1])
  assert_true(check(plan, received, decoded))
}

///|
test "bad orders sizes foreign symbols and forged decoded metadata are rejected" {
  let native = native_field(2, [1, 1, 0, 0, 1])
  let field = extension_field(native)
  let alpha = symbol(field, native, 2)
  for
    (order, n, t) in [
      (0, 1, 0),
      (15, 0, 0),
      (15, 16, 2),
      (16, 15, 2),
      (14, 14, 2),
      (15, 4, 2),
    ] {
    assert_eq(
      plan(field, alpha, @oracle.nat(order), @oracle.nat(n), @oracle.nat(t)),
      Err(InvalidPlan),
    )
  }
  assert_eq(
    plan(
      field,
      @galois.zero(field),
      @oracle.nat(15),
      @oracle.nat(15),
      @oracle.nat(2),
    ),
    Err(InvalidPlan),
  )
  assert_eq(
    plan(
      field,
      symbol(field, native, native_power(native, 2, 3)),
      @oracle.nat(15),
      @oracle.nat(15),
      @oracle.nat(2),
    ),
    Err(InvalidPlan),
  )
  let foreign = test_plan(native_field(3, [1, 0, 1]), 4, 8, 8, 2)
  assert_eq(
    plan(field, root(foreign), @oracle.nat(15), @oracle.nat(15), @oracle.nat(2)),
    Err(FieldMismatch),
  )
  let plan = required(
    plan(field, alpha, @oracle.nat(15), @oracle.nat(15), @oracle.nat(2)),
  )
  assert_eq(encode(plan, @core.Nil), Err(LengthMismatch))
  assert_eq(decode(plan, @core.Nil), Err(LengthMismatch))
  assert_eq(syndrome(plan, @core.Nil), Err(LengthMismatch))
  let mixed = @core.Cons(
    @galois.zero(field_of(foreign)),
    @core.replicate(@oracle.nat(14), @galois.zero(field)),
  )
  assert_eq(decode(plan, mixed), Err(FieldMismatch))
  assert_eq(syndrome(plan, mixed), Err(FieldMismatch))
  let mixed_message = @core.Cons(
    @galois.zero(field_of(foreign)),
    @core.replicate(@oracle.nat(10), @galois.zero(field)),
  )
  assert_eq(encode(plan, mixed_message), Err(FieldMismatch))
  assert_eq(
    @recurrence.checked_berlekamp_massey(
      bm_field(field),
      @core.Cons(@galois.one(field_of(foreign)), Nil),
    ),
    Err(@recurrence.Arithmetic(@galois.FieldMismatch)),
  )
  let message = @core.replicate(@oracle.nat(11), @galois.zero(field))
  let encoded = required(encode(plan, message))
  let decoded = required(decode(plan, encoded))
  assert_true(check(plan, encoded, decoded))
  assert_false(check(plan, encoded, { ..decoded, message: @core.Nil, }))
  assert_false(check(plan, encoded, { ..decoded, corrected: mixed, }))
  assert_false(
    check(plan, encoded, {
      ..decoded,
      error_positions: @core.Cons(@oracle.nat(0), Nil),
    }),
  )
  assert_false(
    check(plan, encoded, {
      ..decoded,
      error_values: @core.Cons(@galois.one(field), Nil),
    }),
  )
  let received_values = Array::make(15, 0)
  received_values[0] = 1
  received_values[14] = 2
  let received = word(plan, native, received_values)
  let decoded = required(decode(plan, received))
  assert_true(check(plan, received, decoded))
  assert_false(
    check(plan, received, {
      ..decoded,
      error_positions: @core.reverse(decoded.error_positions),
    }),
  )
  assert_false(
    check(plan, received, {
      ..decoded,
      error_values: @core.reverse(decoded.error_values),
    }),
  )
}
