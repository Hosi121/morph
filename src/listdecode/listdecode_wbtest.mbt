///|
fn[A] required(result : Result[A, DecodeError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("listdecode operation")
  }
}

///|
fn native(values : @core.Chain[@binary.Binary]) -> Array[Int32] {
  @oracle.array(values).map(@oracle.int_of_binary)
}

///|
fn word(values : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(values.map(@oracle.binary))
}

///|
fn test_plan(
  p : Int32,
  xs : Array[Int32],
  k : Int32,
  a : Int32,
  s : Int32,
  d : Int32,
) -> Plan {
  let field = match @primefield.field(@oracle.binary(p)) {
    Some(field) => field
    None => abort("listdecode prime")
  }
  required(
    plan(
      field,
      word([ for i in 0..<p => i ]),
      word(xs),
      @oracle.nat(k),
      @oracle.nat(a),
      @oracle.nat(s),
      @oracle.nat(d),
    ),
  )
}

///|
fn complete(plan : Plan, received : Array[Int32]) -> Decoded {
  match required(decode(plan, word(received), @oracle.nat(1000))) {
    Complete(result) => result
    Suspended(_) => abort("listdecode unexpected budget exhaustion")
  }
}

///|
fn native_evaluate(p : Int32, coefficients : Array[Int32], x : Int32) -> Int32 {
  for i = coefficients.length() - 1, value = 0; i >= 0; {
    continue i - 1, (value * x + coefficients[i]) % p
  } nobreak {
    value
  }
}

///|
fn digits(value : Int32, p : Int32, k : Int32) -> Array[Int32] {
  let mut rest = value
  [
    for _ in 0..<k => {
      let digit = rest % p
      rest /= p
      digit
    }
  ]
}

///|
fn native_codeword(
  p : Int32,
  xs : Array[Int32],
  message : Array[Int32],
) -> Array[Int32] {
  xs.map(fn(x) { native_evaluate(p, message, x) })
}

///|
fn native_count(a : Array[Int32], b : Array[Int32]) -> Int32 {
  for i = 0, count = 0; i < a.length(); {
    continue i + 1, count + (if a[i] == b[i] { 1 } else { 0 })
  } nobreak {
    count
  }
}

///|
fn message_id(p : Int32, message : Array[Int32]) -> Int32 {
  for i = message.length() - 1, result = 0; i >= 0; {
    continue i - 1, result * p + message[i]
  } nobreak {
    result
  }
}

///|
fn assert_oracle(
  plan : Plan,
  p : Int32,
  received : Array[Int32],
) -> Decoded raise {
  let xs = native(points(plan))
  let k = @oracle.int_of_nat(message_size(plan))
  let a = @oracle.int_of_nat(minimum_agreements(plan))
  let size = for i = 0, size = 1; i < k; {
    continue i + 1, size * p
  } nobreak {
    size
  }
  // The only full message enumeration is this independent numeric test oracle.
  let expected = [
    for code in 0..<size if native_count(
      native_codeword(p, xs, digits(code, p, k)),
      received,
    ) >=
    a => code
  ]
  let decoded = complete(plan, received)
  let actual = @oracle.array(decoded.candidates).map(fn(candidate) {
    message_id(p, native(candidate.message))
  })
  actual.sort()
  assert_eq(actual, expected)
  assert_true(check_interpolation(plan, word(received), decoded.interpolation))
  assert_true(check_witnesses(plan, word(received), decoded))
  for candidate in @oracle.array(decoded.candidates) {
    assert_true(check_candidate(plan, word(received), candidate))
  }
  decoded
}

///|
test "Sudan multiplicity one exhausts all received words over F5 length four" {
  let plan = test_plan(5, [0, 1, 2, 3], 2, 3, 1, 2)
  for received in 0..<625 {
    ignore(assert_oracle(plan, 5, digits(received, 5, 4)))
  }
}

///|
test "Guruswami Sudan multiplicity two exhausts all received words over F3 length three" {
  let plan = test_plan(3, [0, 1, 2], 2, 2, 2, 3)
  assert_eq(@oracle.int_of_nat(@core.length(monomials(plan))), 10)
  assert_eq(@oracle.int_of_nat(constraint_count(plan)), 9)
  let mut multiple = 0
  for received in 0..<27 {
    let decoded = assert_oracle(plan, 3, digits(received, 3, 3))
    if @oracle.int_of_nat(@core.length(decoded.candidates)) > 1 {
      multiple += 1
    }
  }
  assert_true(multiple > 0)
}

///|
test "F11 length nine dimension three multiplicity two decodes radius four" {
  let plan = test_plan(11, [0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 5, 2, 9)
  assert_eq(@oracle.int_of_nat(@core.length(monomials(plan))), 30)
  assert_eq(@oracle.int_of_nat(constraint_count(plan)), 27)
  let sent = native_codeword(11, native(points(plan)), [3, 2, 4])
  let received = sent.copy()
  for position in [0, 2, 5, 8] {
    received[position] = (received[position] + position + 1) % 11
  }
  let decoded = assert_oracle(plan, 11, received)
  assert_true(
    @oracle.array(decoded.candidates).any(fn(candidate) {
      native(candidate.message) == [3, 2, 4]
    }),
  )
  assert_eq(native_count(sent, received), 5)
  assert_true(4 > (9 - 3) / 2)
}
