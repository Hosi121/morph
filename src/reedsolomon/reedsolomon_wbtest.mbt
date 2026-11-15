///|
fn make_plan(p : Int32, n : Int32, k : Int32, t : Int32) -> Plan {
  let field = @finitefield.field(@oracle.binary(p)).unwrap()
  plan(
    field,
    @oracle.nat(k),
    @oracle.nat(t),
    @oracle.chain([ for x in 0..<n => @oracle.binary(x) ]),
  ).unwrap()
}

///|
test "all 343 quadratic messages and every single symbol corruption over the field of seven" {
  let context = make_plan(7, 5, 3, 1)
  for message in 0..<343 {
    let coefficients = [message % 7, message / 7 % 7, message / 49]
    let source = @oracle.chain(coefficients.map(@oracle.binary))
    let encoded = encode(context, source).unwrap()
    let native = @oracle.array(encoded).map(@oracle.int_of_binary)
    assert_eq(
      native,
      [
        for x in 0..<5 => {
          (coefficients[0] + coefficients[1] * x + coefficients[2] * x * x) % 7
        }
      ],
    )
    let intact = decode(context, encoded).unwrap()
    assert_eq(intact.message, source)
    assert_eq(intact.error_positions, Nil)
    for position in 0..<5 {
      for delta in 1..<7 {
        let received = native.copy()
        received[position] = (received[position] + delta) % 7
        let received = @oracle.chain(received.map(@oracle.binary))
        let decoded = decode(context, received).unwrap()
        assert_eq(decoded.message, source)
        assert_eq(decoded.corrected, encoded)
        assert_eq(
          decoded.error_positions,
          @core.Cons(@oracle.nat(position), Nil),
        )
        assert_true(
          check(context, @core.map(received, fn(x) { Some(x) }), decoded),
        )
      }
    }
  }
}

///|
test "all two-error locations with several nonzero magnitudes over the field of seventeen" {
  let context = make_plan(17, 7, 3, 2)
  for sample in 0..<16 {
    let source = @oracle.chain(
      [sample, (sample * 7 + 3) % 17, (sample * 11 + 5) % 17].map(
        @oracle.binary,
      ),
    )
    let encoded = @oracle.array(encode(context, source).unwrap()).map(
      @oracle.int_of_binary,
    )
    assert_eq(
      decode(context, @oracle.chain(encoded.map(@oracle.binary))).unwrap().message,
      source,
    )
    for a in 0..<7 {
      for b in (a + 1)..<7 {
        for da in [1, 2, 16] {
          for db in [1, 2, 16] {
            let received = encoded.copy()
            received[a] = (received[a] + da) % 17
            received[b] = (received[b] + db) % 17
            let received = @oracle.chain(received.map(@oracle.binary))
            let decoded = decode(context, received).unwrap()
            assert_eq(decoded.message, source)
            assert_eq(
              decoded.error_positions,
              @oracle.chain([@oracle.nat(a), @oracle.nat(b)]),
            )
            assert_true(
              check(context, @core.map(received, fn(x) { Some(x) }), decoded),
            )
          }
        }
      }
    }
  }
}

///|
test "every erasure mask with remaining error capacity and rejection outside the nearest-codeword radius" {
  let context = make_plan(17, 9, 3, 3)
  let source = @oracle.chain([3, 1, 4].map(@oracle.binary))
  let encoded = @oracle.array(encode(context, source).unwrap()).map(
    @oracle.int_of_binary,
  )
  for mask in 0..<512 {
    let retained = [ for i in 0..<9 if (mask & (1 << i)) == 0 => i + 0 ]
    let remaining = if retained.length() >= 3 {
      (retained.length() - 3) / 2
    } else {
      0
    }
    let received : Array[@binary.Binary?] = [
      for i in 0..<9 => {
        if (mask & (1 << i)) != 0 {
          None
        } else {
          let corrupt = retained[:remaining].to_owned().contains(i)
          Some(
            @oracle.binary((encoded[i] + (if corrupt { 1 } else { 0 })) % 17),
          )
        }
      }
    ]
    match decode_erasures(context, @oracle.chain(received)) {
      None => assert_true(retained.length() < 3)
      Some(decoded) => {
        assert_true(retained.length() >= 3)
        assert_eq(decoded.message, source)
        assert_true(check(context, @oracle.chain(received), decoded))
      }
    }
  }
  let small = make_plan(5, 4, 2, 1)
  for code in 0..<625 {
    let received = [ for i in 0..<4 => code / [1, 5, 25, 125][i] % 5 ]
    let nearby = []
    for a in 0..<5 {
      for b in 0..<5 {
        let mut distance = 0
        for x in 0..<4 {
          if received[x] != (a + b * x) % 5 {
            distance += 1
          }
        }
        if distance <= 1 {
          nearby.push([a, b])
        }
      }
    }
    assert_true(nearby.length() <= 1)
    match decode(small, @oracle.chain(received.map(@oracle.binary))) {
      None => assert_true(nearby.is_empty())
      Some(decoded) => {
        assert_eq(nearby.length(), 1)
        assert_eq(
          @oracle.array(decoded.message).map(@oracle.int_of_binary),
          nearby[0],
        )
      }
    }
  }
}

///|
test "shape, point distinctness, correction reports and forged results" {
  let context = make_plan(7, 5, 3, 1)
  assert_eq(encode(context, @oracle.chain([@oracle.binary(1)])), None)
  assert_eq(decode(context, @oracle.chain([@oracle.binary(1)])), None)
  let received = @oracle.chain(
    [0, 1, 0, 0, 0].map(fn(n) { Some(@oracle.binary(n)) }),
  )
  let decoded = decode_erasures(context, received).unwrap()
  assert_true(check(context, received, decoded))
  assert_false(check(context, received, { ..decoded, error_positions: Nil, }))
  assert_false(
    check(context, received, {
      ..decoded,
      message: @oracle.chain([1, 0, 0].map(@oracle.binary)),
    }),
  )
  let field = @finitefield.field(@oracle.binary(7)).unwrap()
  assert_eq(plan(field, @oracle.nat(3), @oracle.nat(2), context.points), None)
  assert_eq(plan(field, Zero, Zero, context.points), None)
  assert_eq(
    plan(
      field,
      @oracle.nat(1),
      Zero,
      @oracle.chain([@oracle.binary(1), @oracle.binary(1)]),
    ),
    None,
  )
  assert_eq(
    plan(field, @oracle.nat(1), Zero, @oracle.chain([@oracle.binary(7)])),
    None,
  )
}
