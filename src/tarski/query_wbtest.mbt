///|
fn test_rational(value : (Bool, String, String)) -> @exact.Rational {
  let positive = @exact.positive(@oracle.binary_from_hex(value.1))
  @exact.ratio(
    if value.0 {
      @exact.negate(positive)
    } else {
      positive
    },
    @oracle.binary_from_hex(value.2),
  ).unwrap()
}

///|
fn test_polynomial(values : Array[(Bool, String, String)]) -> @poly.Polynomial {
  @poly.polynomial(
    Succ(Zero),
    @oracle.chain(
      values.mapi(fn(i, value) {
        {
          coefficient: test_rational(value),
          exponents: Cons(@oracle.nat(i), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn small(values : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    Succ(Zero),
    @oracle.chain(
      values.mapi(fn(i, value) {
        {
          coefficient: @oracle.rational(value, 1),
          exponents: Cons(@oracle.nat(i), Nil),
        }
      }),
    ),
  ).unwrap()
}

///|
fn span(lower : Int32, upper : Int32) -> @sturm.Interval {
  { lower: @oracle.rational(lower, 1), upper: @oracle.rational(upper, 1), }
}

///|
fn native_sign(value : @exact.Rational) -> Int32 {
  match @exact.rational_compare(value, @exact.rational_zero()) {
    Less => -1
    Equal => 0
    Greater => 1
  }
}

///|
fn assert_query_fixture(
  p : Array[(Bool, String, String)],
  q : Array[(Bool, String, String)],
  lower : (Bool, String, String),
  upper : (Bool, String, String),
  expected : Int32,
  expected_sequence : Array[Array[(Bool, String, String)]],
  lower_signs : Array[Int32],
  upper_signs : Array[Int32],
  epsilon : (Bool, String, String),
) -> Unit raise {
  let p = test_polynomial(p)
  let q = test_polynomial(q)
  let interval : @sturm.Interval = {
    lower: test_rational(lower),
    upper: test_rational(upper),
  }
  let result = query(p, q, interval).unwrap()
  assert_eq(@oracle.int_of_integer(result.value), expected)
  assert_true(
    check_query_result(p, q, interval, result.value, result.certificate),
  )
  assert_eq(
    @oracle.array(result.certificate.sequence),
    expected_sequence.map(test_polynomial),
  )
  assert_eq(
    @oracle.array(result.certificate.lower_jets).map(fn(j) {
      native_sign(j.value)
    }),
    lower_signs,
  )
  assert_eq(
    @oracle.array(result.certificate.upper_jets).map(fn(j) {
      native_sign(j.value)
    }),
    upper_signs,
  )
  let epsilon = test_rational(epsilon)
  assert_true(
    @exact.rational_compare(epsilon, @exact.rational_zero()) == Greater,
  )
  let samples = @oracle.array(result.certificate.sequence)
  assert_eq(
    samples.map(fn(p) {
      native_sign(
        @poly.evaluate(
          p,
          Cons(@exact.rational_add(interval.lower, epsilon), Nil),
        ).unwrap(),
      )
    }),
    lower_signs,
  )
  assert_eq(
    samples.map(fn(p) {
      native_sign(
        @poly.evaluate(
          p,
          Cons(@exact.rational_add(interval.upper, epsilon), Nil),
        ).unwrap(),
      )
    }),
    upper_signs,
  )
  assert_false(
    check_query_result(
      p,
      q,
      interval,
      @exact.add(result.value, @oracle.integer(1)),
      result.certificate,
    ),
  )
}

///|
fn assert_root_fixture(
  p : Array[(Bool, String, String)],
  q : Array[(Bool, String, String)],
  lower : (Bool, String, String),
  upper : (Bool, String, String),
  expected : Int32,
) -> Unit raise {
  let root : @real.RootCertificate = {
    polynomial: test_polynomial(p),
    interval: { lower: test_rational(lower), upper: test_rational(upper), },
  }
  let q = test_polynomial(q)
  let result = root_sign(root, q).unwrap()
  let expected : @core.Ordering = if expected < 0 {
    Less
  } else if expected > 0 {
    Greater
  } else {
    Equal
  }
  assert_eq(result.sign, expected)
  assert_true(check_root_sign(root, q, result.sign, result.certificate))
  assert_eq(result.certificate.root.interval, root.interval)
  assert_eq(result.certificate.query_certificate.interval, root.interval)
  let value = @real.number(root).unwrap()
  let via_number = sign_at(value, q).unwrap()
  assert_eq(via_number.sign, expected)
  assert_true(check_sign_at(value, q, via_number.sign, via_number.certificate))
  let wrong = if result.sign == Less { @core.Greater } else { @core.Less }
  assert_false(check_root_sign(root, q, wrong, result.certificate))
}

///|
test "negative upper endpoint roots require right limits instead of zero skipping" {
  let p = small([0, 0, 1])
  let q = small([-1])
  let interval = span(-1, 0)
  let result = query(p, q, interval).unwrap()
  assert_eq(@oracle.int_of_integer(result.value), -1)
  assert_eq(
    @oracle.array(result.certificate.lower_jets).map(fn(j) {
      @oracle.int_of_nat(j.order)
    }),
    [0, 0],
  )
  assert_eq(
    @oracle.array(result.certificate.upper_jets).map(fn(j) {
      @oracle.int_of_nat(j.order)
    }),
    [2, 1],
  )
  assert_eq(@oracle.int_of_integer(query(p, q, span(0, 1)).unwrap().value), 0)
  assert_eq(
    @oracle.int_of_integer(
      query(small([0, 0, 0, 1]), q, interval).unwrap().value,
    ),
    -1,
  )
}

///|
test "zero and constant cases and invalid domains are explicit" {
  assert_eq(query(small([]), small([1]), span(-1, 1)), Err(ZeroPolynomial))
  assert_eq(query(small([1]), small([0]), span(1, 1)), Err(InvalidInterval))
  assert_eq(query(small([1]), small([1]), span(2, 1)), Err(InvalidInterval))
  let result = query(small([-5]), small([1, 2, 3]), span(-3, 3)).unwrap()
  assert_eq(@oracle.int_of_integer(result.value), 0)
  assert_true(
    check_query_result(
      small([-5]),
      small([1, 2, 3]),
      span(-3, 3),
      result.value,
      result.certificate,
    ),
  )
  assert_eq(
    @oracle.int_of_integer(
      query(small([-2, 0, 1]), small([]), span(-2, 2)).unwrap().value,
    ),
    0,
  )
  assert_true(
    query(@poly.zero(@oracle.nat(2)), small([1]), span(-1, 1))
    is Err(NotUnivariate),
  )
  assert_true(
    root_sign(
      { polynomial: small([-1, 0, 1]), interval: span(-2, 2), },
      small([1]),
    )
    is Err(InvalidRoot),
  )
}

///|
test "quotient identity termination degree and jet certificates reject tampering" {
  let p = small([-2, 0, 1])
  let q = small([1])
  let interval = span(-2, 2)
  let proof = query(p, q, interval).unwrap().certificate
  assert_true(check_query(p, q, interval, proof))
  assert_false(check_query(p, q, interval, { ..proof, quotients: Nil, }))
  assert_false(
    check_query(p, q, interval, {
      ..proof,
      sequence: @core.take(@oracle.nat(2), proof.sequence),
      quotients: @core.take(Succ(Zero), proof.quotients),
    }),
  )
  let sequence = @oracle.array(proof.sequence)
  assert_false(
    check_query(p, q, interval, {
      ..proof,
      sequence: Cons(
        sequence[0],
        Cons(sequence[1], Cons(@poly.negate(sequence[2]), Nil)),
      ),
    }),
  )
  assert_false(check_query(p, q, interval, { ..proof, lower_jets: Nil, }))
  let jets = @oracle.array(proof.lower_jets)
  let not_minimal : RightJet = {
    order: Succ(Zero),
    value: @oracle.rational(-4, 1),
  }
  assert_false(
    check_query(p, q, interval, {
      ..proof,
      lower_jets: Cons(not_minimal, @core.drop(Succ(Zero), proof.lower_jets)),
    }),
  )
  assert_false(
    check_query(p, q, interval, {
      ..proof,
      lower_jets: Cons(
        { ..jets[0], value: @exact.rational_zero(), },
        @core.drop(Succ(Zero), proof.lower_jets),
      ),
    }),
  )
  assert_false(
    check_query(p, q, interval, {
      ..proof,
      result: @exact.negate(proof.result),
    }),
  )
  assert_false(check_query(small([-4, 0, 2]), q, interval, proof))
  assert_false(check_query(p, small([0, 1]), interval, proof))
  assert_false(check_query(p, q, span(-3, 3), proof))
}

///|
test "common roots repeated roots and query additivity do not count multiplicity" {
  let p = @poly.multiply(
    @poly.multiply(small([1, 1]), small([1, 1])).unwrap(),
    @poly.multiply(small([0, 0, 0, 1]), small([-1, 1])).unwrap(),
  ).unwrap()
  let q = small([-1, 1])
  let whole = query(p, q, span(-1, 1)).unwrap().value
  let left = query(p, q, span(-1, 0)).unwrap().value
  let right = query(p, q, span(0, 1)).unwrap().value
  assert_eq(whole, @exact.add(left, right))
  assert_eq(@oracle.int_of_integer(whole), -1)
  assert_eq(
    @oracle.int_of_integer(query(p, small([1]), span(-2, 2)).unwrap().value),
    3,
  )
  assert_eq(
    @oracle.int_of_integer(query(p, small([0, 1]), span(-2, 2)).unwrap().value),
    0,
  )
  assert_eq(
    @oracle.int_of_integer(
      query(p, small([0, 0, 1]), span(-2, 2)).unwrap().value,
    ),
    2,
  )
}

///|
test "one-root sign payload query and selected conjugate are bound" {
  let root : @real.RootCertificate = {
    polynomial: small([-2, 0, 1]),
    interval: span(1, 2),
  }
  let other : @real.RootCertificate = {
    polynomial: root.polynomial,
    interval: span(-2, -1),
  }
  let q = small([0, 1])
  let result = root_sign(root, q).unwrap()
  assert_eq(result.sign, Greater)
  assert_true(check_root_sign(root, q, result.sign, result.certificate))
  let forged : SignResult = { sign: Less, certificate: result.certificate, }
  assert_false(check_root_sign(root, q, forged.sign, forged.certificate))
  assert_false(
    check_root_sign(root, q, Less, { ..result.certificate, sign: Less, }),
  )
  assert_true(@real.check_root(other))
  assert_false(check_root_sign(other, q, Greater, result.certificate))
  assert_false(
    check_root_sign(other, q, Greater, { ..result.certificate, root: other, }),
  )
  assert_false(
    check_root_sign(root, small([-2, 0, 1]), result.sign, result.certificate),
  )
  assert_eq(root_sign(root, root.polynomial).unwrap().sign, Equal)
  assert_eq(root_sign(root, small([-3, 0, 1])).unwrap().sign, Less)
}

///|
test "a cancelling multi-root query cannot masquerade as an algebraic zero sign" {
  let root : @real.RootCertificate = {
    polynomial: small([-2, 0, 1]),
    interval: span(-2, 2),
  }
  let q = small([0, 1])
  assert_eq(
    @oracle.int_of_integer(
      query(root.polynomial, q, root.interval).unwrap().value,
    ),
    0,
  )
  assert_true(root_sign(root, q) is Err(InvalidRoot))
  let valid : @real.RootCertificate = { ..root, interval: span(1, 2), }
  let proof = root_sign(valid, q).unwrap().certificate
  assert_false(check_root_sign(valid, q, Equal, { ..proof, sign: Equal, }))
  assert_false(
    check_root_sign(valid, q, Greater, {
      ..proof,
      query_certificate: {
        ..proof.query_certificate,
        result: @oracle.integer(2),
      },
    }),
  )
}
