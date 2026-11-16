///|
// Numeric tests use carryless integer bit polynomials, independent of the
// symbolic Boolean-chain operations and Frobenius-orbit generator construction.
fn native_multiply(a : Int32, b : Int32) -> Int32 {
  for a = a, b = b, result = 0; b != 0; {
    continue a << 1, b >> 1, if (b & 1) != 0 { result ^ a } else { result }
  } nobreak {
    result
  }
}

///|
fn native_remainder(value : Int32, divisor : Int32) -> Int32 {
  let mut value = value
  while value != 0 && value.clz() <= divisor.clz() {
    value = value ^ (divisor << (divisor.clz() - value.clz()))
  }
  value
}

///|
fn native_gcd(a : Int32, b : Int32) -> Int32 {
  for a = a, b = b; b != 0; {
    continue b, native_remainder(a, b)
  } nobreak {
    a
  }
}

///|
fn native_quotient(value : Int32, divisor : Int32) -> Int32 {
  let mut value = value
  let mut result = 0
  while value != 0 && value.clz() <= divisor.clz() {
    let shift = divisor.clz() - value.clz()
    result = result ^ (1 << shift)
    value = value ^ (divisor << shift)
  }
  result
}

///|
fn gf_multiply(modulus : Int32, a : Int32, b : Int32) -> Int32 {
  native_remainder(native_multiply(a, b), modulus)
}

///|
fn gf_power(modulus : Int32, a : Int32, exponent : Int32) -> Int32 {
  for base = a, exponent = exponent, result = 1; exponent != 0; {
    continue gf_multiply(modulus, base, base),
      exponent >> 1,
      if (exponent & 1) != 0 {
        gf_multiply(modulus, result, base)
      } else {
        result
      }
  } nobreak {
    result
  }
}

///|
fn native_evaluate(modulus : Int32, polynomial : Int32, point : Int32) -> Int32 {
  for i = 31 - polynomial.clz(), result = 0; i >= 0; {
    continue i - 1,
      gf_multiply(modulus, result, point) ^ ((polynomial >> i) & 1)
  } nobreak {
    result
  }
}

///|
// Find the least-degree monic binary polynomial that vanishes at the point.
// No conjugacy classes or extension-field polynomial products are used here.
fn native_minimal(modulus : Int32, point : Int32) -> Int32 {
  for degree in 1..<(32 - modulus.clz()) {
    for tail in 0..<(1 << degree) {
      let polynomial = (1 << degree) | tail
      if native_evaluate(modulus, polynomial, point) == 0 {
        return polynomial
      }
    }
  }
  abort("binary minimal polynomial oracle")
}

///|
fn native_generator(modulus : Int32, root : Int32, t : Int32) -> Int32 {
  for j = 1, result = 1; j <= 2 * t; {
    let minimal = native_minimal(modulus, gf_power(modulus, root, j))
    continue j + 1,
      native_multiply(
        native_quotient(result, native_gcd(result, minimal)),
        minimal,
      )
  } nobreak {
    result
  }
}

///|
fn native_encode(generator : Int32, message : Int32) -> Int32 {
  let shifted = message << (31 - generator.clz())
  shifted ^ native_remainder(shifted, generator)
}

///|
fn bit_word(value : Int32, width : Int32) -> @core.Chain[Bool] {
  @oracle.chain([ for i in 0..<width => ((value >> i) & 1) != 0 ])
}

///|
fn native_word(values : @core.Chain[Bool]) -> Int32 {
  let values = @oracle.array(values)
  for i = 0, result = 0; i < values.length(); {
    continue i + 1, if values[i] { result | (1 << i) } else { result }
  } nobreak {
    result
  }
}

///|
fn[A] required(result : Result[A, CodeError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("BCH operation")
  }
}

///|
fn[A] algebra_required(result : Result[A, @galois.FieldError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("BCH field operation")
  }
}

///|
fn test_field(p : Int32, coefficients : Array[Int32]) -> @galois.Field {
  let prime = match @primefield.field(@oracle.binary(p)) {
    Some(value) => value
    None => abort("BCH prime")
  }
  let polynomial = @fppoly.polynomial(
    prime,
    @oracle.chain(coefficients.map(@oracle.binary)),
  )
  let certificate = match @fppoly.irreducibility(polynomial) {
    Ok(Some(value)) => value
    _ => abort("BCH irreducibility")
  }
  match @galois.extension(polynomial, certificate) {
    Some(value) => value
    None => abort("BCH extension")
  }
}

///|
fn test_plan(modulus : Int32, t : Int32) -> Plan {
  let degree = 31 - modulus.clz()
  let field = test_field(2, [ for i in 0..<(degree + 1) => (modulus >> i) & 1 ])
  let root = algebra_required(@galois.generator(field))
  required(plan(field, root, @oracle.nat((1 << degree) - 1), @oracle.nat(t)))
}

///|
fn assert_roundtrip(
  plan : Plan,
  encoded : Int32,
  message : Int32,
  mask : Int32,
) -> Unit raise {
  let n = @oracle.int_of_nat(plan.length)
  let received = bit_word(encoded ^ mask, n)
  let decoded = required(decode(plan, received))
  assert_eq(native_word(decoded.message), message)
  assert_eq(native_word(decoded.corrected), encoded)
  assert_eq(
    @oracle.array(decoded.error_positions).map(@oracle.int_of_nat),
    [
      for i in 0..<n if ((mask >> i) & 1) != 0 => i
    ],
  )
  assert_true(check(plan, received, decoded))
  assert_true(check_codeword(plan, decoded.corrected))
}

///|
test "primitive BCH three and seven exhaust every message and correctable mask" {
  for fixture in [(0b111, 1), (0b1011, 1), (0b1011, 2), (0b1011, 3)] {
    let (modulus, t) = fixture
    let plan = test_plan(modulus, t)
    let n = @oracle.int_of_nat(plan.length)
    let k = @oracle.int_of_nat(plan.message_size)
    let generator = native_generator(modulus, 2, t)
    assert_eq(native_word(generator_polynomial(plan)), generator)
    for message in 0..<(1 << k) {
      let encoded = native_encode(generator, message)
      assert_eq(
        native_word(required(encode(plan, bit_word(message, k)))),
        encoded,
      )
      for mask in 0..<(1 << n) {
        if mask.popcnt() <= t {
          assert_roundtrip(plan, encoded, message, mask)
        }
      }
    }
  }
}

///|
test "standard BCH fifteen seven five reconstructs generator and exhausts two error patterns" {
  let plan = test_plan(0b10011, 2)
  let generator = native_generator(0b10011, 2, 2)
  assert_eq(generator, 0b111010001)
  assert_eq(native_word(generator_polynomial(plan)), generator)
  assert_eq(@oracle.int_of_nat(message_size(plan)), 7)
  assert_eq(@oracle.int_of_nat(@core.length(minimal_polynomials(plan))), 2)
  let mut minimum = 15
  for message in 0..<128 {
    let encoded = native_encode(generator, message)
    assert_eq(
      native_word(required(encode(plan, bit_word(message, 7)))),
      encoded,
    )
    assert_true(check_codeword(plan, bit_word(encoded, 15)))
    if message != 0 {
      minimum = minimum.min(encoded.popcnt())
    }
  }
  assert_eq(minimum, 5)
  let message = 0b1011010
  let encoded = native_encode(generator, message)
  for mask in 0..<(1 << 15) {
    if mask.popcnt() <= 2 {
      assert_roundtrip(plan, encoded, message, mask)
    }
  }
}

///|
fn field_symbol(field : @galois.Field, value : Int32) -> @galois.Element {
  let width = @oracle.int_of_nat(@galois.degree(field))
  algebra_required(
    @galois.element(
      field,
      @fppoly.polynomial(
        @galois.prime_field(field),
        @oracle.chain(
          [
            for i in 0..<width => @oracle.binary((value >> i) & 1)
          ],
        ),
      ),
    ),
  )
}

///|
fn native_syndrome(
  modulus : Int32,
  root : Int32,
  t : Int32,
  received : Int32,
) -> Array[Int32] {
  [
    for j in 1..<(2 * t + 1) => {
      native_evaluate(modulus, received, gf_power(modulus, root, j))
    }
  ]
}

///|
fn native_symbol(value : @galois.Element) -> Int32 {
  let coefficients = @oracle.array(
    @fppoly.coefficients(@galois.representative(value)),
  )
  for i = 0, result = 0; i < coefficients.length(); {
    continue i + 1, result | (@oracle.int_of_binary(coefficients[i]) << i)
  } nobreak {
    result
  }
}

///|
fn assert_nearest(
  plan : Plan,
  generator : Int32,
  received : Int32,
) -> Unit raise {
  let n = @oracle.int_of_nat(plan.length)
  let k = @oracle.int_of_nat(plan.message_size)
  let t = @oracle.int_of_nat(plan.errors)
  let nearby = [
    for message in 0..<(1 << k) if (native_encode(generator, message) ^ received).popcnt() <=
    t => message
  ]
  let received_word = bit_word(received, n)
  match decode(plan, received_word) {
    Ok(decoded) => {
      assert_eq(nearby.length(), 1)
      assert_eq(native_word(decoded.message), nearby[0])
      assert_eq(
        native_word(decoded.corrected),
        native_encode(generator, nearby[0]),
      )
      assert_true(check(plan, received_word, decoded))
    }
    Err(Uncorrectable) => assert_eq(nearby.length(), 0)
    _ => fail("unexpected BCH decoding error")
  }
}

///|
test "every received word for length three and seven agrees with nearest codeword oracle" {
  for fixture in [(0b111, 1), (0b1011, 1), (0b1011, 2), (0b1011, 3)] {
    let (modulus, t) = fixture
    let plan = test_plan(modulus, t)
    let generator = native_generator(modulus, 2, t)
    let n = @oracle.int_of_nat(plan.length)
    assert_true(valid(validate(plan)))
    for received in 0..<(1 << n) {
      assert_nearest(plan, generator, received)
    }
  }
}

///|
test "BCH fifteen zero word triples show both failure and certified miscorrection beyond radius" {
  let plan = test_plan(0b10011, 2)
  let generator = native_generator(0b10011, 2, 2)
  let mut failures = 0
  let mut miscorrections = 0
  for received in 0..<(1 << 15) {
    if received.popcnt() == 3 {
      assert_nearest(plan, generator, received)
      match decode(plan, bit_word(received, 15)) {
        Err(Uncorrectable) => failures += 1
        Ok(decoded) => {
          assert_true(native_word(decoded.corrected) != 0)
          miscorrections += 1
        }
        _ => fail("unexpected BCH triple behavior")
      }
    }
  }
  assert_eq(failures, 275)
  assert_eq(miscorrections, 180)
  // A transmitted nonzero codeword is undetectable if the zero word was sent.
  let received = native_encode(generator, 1)
  let decoded = required(decode(plan, bit_word(received, 15)))
  assert_eq(native_word(decoded.message), 1)
  assert_eq(@oracle.int_of_nat(@core.length(decoded.error_positions)), 0)
  assert_true(check(plan, bit_word(received, 15), decoded))
}

///|
test "zero radius and degree one field retain every binary message and trailing zeros" {
  for modulus in [0b11, 0b111, 0b1011] {
    let degree = 31 - modulus.clz()
    let field = test_field(
      2,
      [
        for i in 0..<(degree + 1) => (modulus >> i) & 1
      ],
    )
    // In GF(2) the sole nonzero element has exact order one.
    let root = if degree == 1 {
      @galois.one(field)
    } else {
      algebra_required(@galois.generator(field))
    }
    let n = (1 << degree) - 1
    let plan = required(plan(field, root, @oracle.nat(n), @oracle.nat(0)))
    assert_true(valid(validate(plan)))
    assert_eq(native_word(generator_polynomial(plan)), 1)
    assert_eq(@oracle.int_of_nat(message_size(plan)), n)
    assert_eq(@oracle.int_of_nat(@core.length(minimal_polynomials(plan))), 0)
    for message in 0..<(1 << n) {
      assert_eq(
        required(encode(plan, bit_word(message, n))),
        bit_word(message, n),
      )
      assert_roundtrip(plan, message, message, 0)
      assert_eq(
        @oracle.int_of_nat(
          @core.length(required(syndrome(plan, bit_word(message, n)))),
        ),
        0,
      )
    }
  }
}

///|
test "alternative primitive root and nonprimitive defining indeterminate are handled exactly" {
  // The irreducible x^4+x^3+x^2+x+1 has x of order5, not15.
  let field = test_field(2, [1, 1, 1, 1, 1])
  let nonprimitive = algebra_required(@galois.generator(field))
  assert_eq(
    plan(field, nonprimitive, @oracle.nat(15), @oracle.nat(2)),
    Err(InvalidPlan),
  )
  let root = field_symbol(field, 3)
  assert_eq(gf_power(0b11111, 3, 15), 1)
  let plan = required(plan(field, root, @oracle.nat(15), @oracle.nat(2)))
  assert_true(valid(validate(plan)))
  let generator = native_generator(0b11111, 3, 2)
  assert_eq(native_word(generator_polynomial(plan)), generator)
  for message in [0, 1, 42, 127] {
    let encoded = native_encode(generator, message)
    assert_eq(
      native_word(required(encode(plan, bit_word(message, 7)))),
      encoded,
    )
    for mask in [0, 1, 1 << 14, (1 << 3) | (1 << 12)] {
      assert_roundtrip(plan, encoded, message, mask)
      assert_eq(
        @oracle.array(required(syndrome(plan, bit_word(encoded ^ mask, 15)))).map(
          native_symbol,
        ),
        native_syndrome(0b11111, 3, 2, encoded ^ mask),
      )
    }
  }
}

///|
test "invalid lengths fields roots and excessive radii are rejected" {
  let good = test_plan(0b10011, 2)
  let field = field_of(good)
  for n in [0, 1, 3, 7, 14, 16] {
    assert_eq(
      plan(field, root(good), @oracle.nat(n), @oracle.nat(0)),
      Err(InvalidPlan),
    )
  }
  for t in [8, 15] {
    assert_eq(
      plan(field, root(good), @oracle.nat(15), @oracle.nat(t)),
      Err(InvalidPlan),
    )
  }
  for
    root in [
      @galois.zero(field),
      @galois.one(field),
      field_symbol(field, gf_power(0b10011, 2, 3)),
    ] {
    assert_eq(
      plan(field, root, @oracle.nat(15), @oracle.nat(2)),
      Err(InvalidPlan),
    )
  }
  let foreign = test_field(2, [1, 1, 1])
  assert_eq(
    plan(
      field,
      algebra_required(@galois.generator(foreign)),
      @oracle.nat(15),
      @oracle.nat(2),
    ),
    Err(FieldMismatch),
  )
  let odd = test_field(3, [1, 0, 1])
  assert_eq(
    plan(
      odd,
      algebra_required(@galois.generator(odd)),
      @oracle.nat(8),
      @oracle.nat(1),
    ),
    Err(InvalidPlan),
  )
  for width in [0, 6, 8, 15] {
    assert_eq(encode(good, bit_word(0, width)), Err(LengthMismatch))
  }
  for width in [0, 7, 14, 16] {
    assert_eq(syndrome(good, bit_word(0, width)), Err(LengthMismatch))
    assert_eq(decode(good, bit_word(0, width)), Err(LengthMismatch))
    assert_false(check_codeword(good, bit_word(0, width)))
  }
}

///|
test "result checker rejects forged messages words distances and position metadata" {
  let plan = test_plan(0b10011, 2)
  let encoded = native_encode(native_generator(0b10011, 2, 2), 37)
  let received = bit_word(encoded ^ 0b1001, 15)
  let decoded = required(decode(plan, received))
  assert_true(check(plan, received, decoded))
  assert_false(check(plan, received, { ..decoded, message: bit_word(0, 7), }))
  assert_false(
    check(plan, received, { ..decoded, corrected: bit_word(0, 15), }),
  )
  assert_false(
    check(plan, received, {
      ..decoded,
      error_positions: @oracle.chain([@oracle.nat(3), @oracle.nat(0)]),
    }),
  )
  assert_false(
    check(plan, received, {
      ..decoded,
      error_positions: @oracle.chain([
        @oracle.nat(0),
        @oracle.nat(3),
        @oracle.nat(3),
      ]),
    }),
  )
  assert_false(
    check(plan, received, {
      ..decoded,
      error_positions: @oracle.chain([@oracle.nat(0)]),
    }),
  )
  assert_false(check(plan, bit_word(encoded, 14), decoded))
  assert_false(check(plan, received, { ..decoded, message: bit_word(37, 8), }))
  assert_false(
    check(plan, bit_word(encoded ^ 0b111, 15), {
      ..decoded,
      error_positions: @oracle.chain([
        @oracle.nat(0),
        @oracle.nat(1),
        @oracle.nat(2),
      ]),
    }),
  )
}

///|
test "construction validation rejects independently forged orbit polynomial and plan fields" {
  let plan = test_plan(0b10011, 2)
  let first = match minimal_polynomials(plan) {
    Cons(first, _) => first
    _ => abort("BCH factors")
  }
  assert_true(check_minimal_polynomial(plan.field, first))
  assert_false(
    check_minimal_polynomial(plan.field, { ..first, conjugates: @core.Nil, }),
  )
  assert_false(
    check_minimal_polynomial(plan.field, {
      ..first,
      conjugates: @core.reverse(first.conjugates),
    }),
  )
  assert_false(
    check_minimal_polynomial(plan.field, {
      ..first,
      conjugates: @core.append(first.conjugates, first.conjugates),
    }),
  )
  assert_false(
    check_minimal_polynomial(plan.field, { ..first, coefficients: @core.Nil, }),
  )
  assert_false(
    check_minimal_polynomial(plan.field, {
      ..first,
      coefficients: @oracle.chain([true]),
    }),
  )
  assert_eq(
    lower(plan.field, @oracle.chain([plan.root])),
    Err(NonbinaryCoefficient),
  )
  assert_false(valid(validate({ ..plan, root: @galois.one(plan.field), })))
  assert_false(valid(validate({ ..plan, length: @oracle.nat(14), })))
  assert_false(valid(validate({ ..plan, parity: @oracle.nat(7), })))
  assert_false(valid(validate({ ..plan, message_size: @oracle.nat(8), })))
  assert_false(valid(validate({ ..plan, errors: @oracle.nat(8), })))
  assert_false(valid(validate({ ..plan, roots: @core.Nil, })))
  assert_false(valid(validate({ ..plan, inverse_points: @core.Nil, })))
  assert_false(valid(validate({ ..plan, factors: @core.Nil, })))
  assert_false(
    valid(
      validate({ ..plan, factors: @core.append(plan.factors, plan.factors), }),
    ),
  )
  assert_false(valid(validate({ ..plan, generator: @oracle.chain([true]), })))
  assert_false(valid(validate({ ..plan, generator: @core.Nil, })))
  assert_false(
    valid(validate({ ..plan, generator: @oracle.chain([true, false]), })),
  )
}

///|
test "all 32768 received BCH fifteen words agree with independent bounded distance oracle" {
  let plan = test_plan(0b10011, 2)
  let generator = native_generator(0b10011, 2, 2)
  for received in 0..<(1 << 15) {
    assert_nearest(plan, generator, received)
  }
}

///|
test "BCH fifteen triple error radius and BCH thirty one double radius exhaust masks" {
  for fixture in [(0b10011, 3), (0b100101, 2)] {
    let (modulus, t) = fixture
    let plan = test_plan(modulus, t)
    let generator = native_generator(modulus, 2, t)
    assert_true(valid(validate(plan)))
    assert_eq(native_word(plan.generator), generator)
    let n = @oracle.int_of_nat(plan.length)
    let k = @oracle.int_of_nat(plan.message_size)
    let message = if n == 15 { 0b10101 } else { 0b101011010101 }
    let encoded = native_encode(generator, message)
    assert_eq(
      native_word(required(encode(plan, bit_word(message, k)))),
      encoded,
    )
    assert_roundtrip(plan, encoded, message, 0)
    for i in 0..<n {
      assert_roundtrip(plan, encoded, message, 1 << i)
      for j in (i + 1)..<n {
        assert_roundtrip(plan, encoded, message, (1 << i) | (1 << j))
        if t == 3 {
          for l in (j + 1)..<n {
            assert_roundtrip(
              plan,
              encoded,
              message,
              (1 << i) | (1 << j) | (1 << l),
            )
          }
        }
      }
    }
  }
}

///|
test "GF64 BCH length63 keeps binary words and corrects errors in both endpoint positions" {
  let plan = test_plan(0b1000011, 3)
  assert_true(valid(validate(plan)))
  assert_eq(native_word(plan.generator), native_generator(0b1000011, 2, 3))
  let k = @oracle.int_of_nat(plan.message_size)
  let message = @oracle.chain(
    [
      for i in 0..<k => (i * i + i / 3 + 1) % 2 == 1
    ],
  )
  let encoded = required(encode(plan, message))
  assert_eq(@core.drop(plan.parity, encoded), message)
  assert_eq(@oracle.int_of_nat(@core.length(encoded)), 63)
  assert_true(check_codeword(plan, encoded))
  for positions in [[], [0], [62], [0, 31, 62], [1, 2, 3], [57, 60, 61]] {
    let received = @oracle.array(encoded)
    for position in positions {
      received[position] = !received[position]
    }
    let received = @oracle.chain(received)
    let decoded = required(decode(plan, received))
    assert_eq(decoded.corrected, encoded)
    assert_eq(decoded.message, message)
    assert_eq(
      @oracle.array(decoded.error_positions).map(@oracle.int_of_nat),
      positions,
    )
    assert_true(check(plan, received, decoded))
  }
}

///|
test "minimal factors retain shorter Frobenius orbits instead of assuming extension degree" {
  for fixture in [(0b10011, 3), (0b1000011, 5), (0b1000011, 11)] {
    let (modulus, t) = fixture
    let plan = test_plan(modulus, t)
    assert_true(valid(validate(plan)))
    if t < 11 {
      assert_eq(native_word(plan.generator), native_generator(modulus, 2, t))
    }
    let degrees = @oracle.array(plan.factors).map(fn(factor) {
      @oracle.int_of_nat(@core.length(factor.conjugates))
    })
    if t == 3 {
      assert_eq(degrees, [4, 4, 2])
    }
    if t == 5 {
      assert_eq(degrees, [6, 6, 6, 6, 3])
    }
    if t == 11 {
      assert_eq(degrees, [6, 6, 6, 6, 3, 6, 6, 6, 2])
    }
  }
}

///|
fn assert_fixture(
  modulus : Int32,
  alpha : Int32,
  n : Int32,
  t : Int32,
  generator : Array[Bool],
  message : Array[Bool],
  encoded : Array[Bool],
  positions : Array[Int32],
  syndromes : Array[Int32],
  locator : Array[Int32],
) -> Unit raise {
  let degree = 31 - modulus.clz()
  let field = test_field(2, [ for i in 0..<(degree + 1) => (modulus >> i) & 1 ])
  let root = field_symbol(field, alpha)
  let plan = required(plan(field, root, @oracle.nat(n), @oracle.nat(t)))
  assert_true(valid(validate(plan)))
  assert_eq(generator_polynomial(plan), @oracle.chain(generator))
  let message = @oracle.chain(message)
  let codeword = required(encode(plan, message))
  assert_eq(codeword, @oracle.chain(encoded))
  assert_true(check_codeword(plan, codeword))
  assert_eq(@core.drop(plan.parity, codeword), message)
  let received = encoded.copy()
  for position in positions {
    received[position] = !received[position]
  }
  let received = @oracle.chain(received)
  let observed = required(syndrome(plan, received))
  assert_eq(@oracle.array(observed).map(native_symbol), syndromes)
  let recurrence = match
    @recurrence.checked_berlekamp_massey(bm_field(field), observed) {
    Ok(value) => value
    _ => abort("BCH fixture BM")
  }
  assert_eq(@oracle.array(recurrence.connection).map(native_symbol), locator)
  let decoded = required(decode(plan, received))
  assert_eq(decoded.corrected, codeword)
  assert_eq(decoded.message, message)
  assert_eq(
    @oracle.array(decoded.error_positions).map(@oracle.int_of_nat),
    positions,
  )
  assert_true(check(plan, received, decoded))
}

///|
// Gulliver ELEC405/511 "Decoding BCH Codes", Example9-4 (slides10–11).
// The published received polynomial is 1+x^9+x^11+x^14 and errors13,16,19.
test "published BCH thirty one triple error example retains the documented convention" {
  let plan = test_plan(0b100101, 3)
  let received = (1 << 0) | (1 << 9) | (1 << 11) | (1 << 14)
  assert_eq(native_word(generator_polynomial(plan)), 0x8faf)
  let observed = required(syndrome(plan, bit_word(received, 31)))
  assert_eq(@oracle.array(observed).map(native_symbol), [1, 1, 9, 1, 15, 11])
  let decoded = required(decode(plan, bit_word(received, 31)))
  assert_eq(@oracle.array(decoded.error_positions).map(@oracle.int_of_nat), [
    13, 16, 19,
  ])
  assert_eq(
    native_word(decoded.corrected),
    received ^ (1 << 13) ^ (1 << 16) ^ (1 << 19),
  )
  assert_true(check(plan, bit_word(received, 31), decoded))
}
