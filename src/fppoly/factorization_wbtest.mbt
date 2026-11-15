///|
fn test_certificate(value : Polynomial) -> IrreducibilityCertificate {
  match required(irreducibility(value)) {
    Some(certificate) => certificate
    None => abort("test polynomial must be monic irreducible")
  }
}

///|
fn test_certificates(
  value : Factorization,
) -> @core.Chain[IrreducibilityCertificate] {
  @core.map(value.factors, fn(factor) { test_certificate(factor.polynomial) })
}

///|
fn native_proper_divisor(value : Array[Int32], p : Int32) -> Array[Int32]? {
  for degree in 1..<=((value.length() - 1) / 2) {
    for code in 0..<native_power(p, degree) {
      let divisor = native_polynomial(code, p, degree)
      divisor.push(1)
      if native_divide(value, divisor, p).1.is_empty() {
        return Some(divisor)
      }
    }
  }
  None
}

///|
// Trial enumeration of all monic possible divisors: independent of Berlekamp.
fn native_factor(
  value : Array[Int32],
  p : Int32,
) -> (Int32, Array[Array[Int32]]) {
  let value = native_trim(value, p)
  let unit = value[value.length() - 1]
  let inverse = for candidate in 1..<p {
    if candidate * unit % p == 1 {
      break candidate
    }
  } nobreak {
    abort("native factor unit")
  }
  let mut remaining = value.map(fn(coefficient) { coefficient * inverse % p })
  let result = []
  while remaining.length() > 1 {
    match native_proper_divisor(remaining, p) {
      None => {
        result.push(remaining)
        remaining = [1]
      }
      Some(divisor) => {
        result.push(divisor)
        remaining = native_divide(remaining, divisor, p).0
      }
    }
  }
  (unit, result)
}

///|
fn assert_factor_fixture(
  p : Int32,
  input : Array[Int32],
  unit : Int32,
  expected : Array[(Array[Int32], Int32)],
) -> Unit raise {
  let value = test_polynomial(p, input)
  let result = required(factor(value))
  assert_eq(@oracle.int_of_binary(result.unit), unit)
  let actual = @oracle.array(result.factors)
  assert_eq(actual.length(), expected.length())
  for factor in actual {
    let matching = expected.filter(fn(pair) {
      pair.0 == native(factor.polynomial)
    })
    assert_eq(matching.length(), 1)
    assert_eq(@oracle.int_of_nat(factor.multiplicity), matching[0].1)
  }
  assert_true(check_factorization(value, result, test_certificates(result)))
}

///|
test "Berlekamp factorization and irreducibility exhaust monic small polynomials" {
  for (p, bound) in [(2, 6), (3, 4), (5, 3)] {
    for degree in 1..<=bound {
      for code in 0..<native_power(p, degree) {
        let input = native_polynomial(code, p, degree)
        input.push(1)
        let value = test_polynomial(p, input)
        let expected = native_factor(input, p).1
        let distinct : Array[Array[Int32]] = []
        for factor in expected {
          if !distinct.contains(factor) {
            distinct.push(factor)
          }
        }
        let result = required(factor(value))
        let factors = @oracle.array(result.factors)
        assert_eq(factors.length(), distinct.length())
        for factor in factors {
          let coefficients = native(factor.polynomial)
          assert_true(distinct.contains(coefficients))
          assert_eq(
            @oracle.int_of_nat(factor.multiplicity),
            expected.filter(fn(other) { other == coefficients }).length(),
          )
        }
        assert_true(
          check_factorization(value, result, test_certificates(result)),
        )
        let certificate = required(irreducibility(value))
        assert_eq(certificate is Some(_), expected.length() == 1)
        match certificate {
          Some(certificate) =>
            assert_true(check_irreducible(value, certificate))
          None => ()
        }
        let basis = required(berlekamp_basis(value))
        assert_eq(@oracle.int_of_nat(@core.length(basis)), distinct.length())
        for vector in @oracle.array(basis) {
          assert_eq(power_mod(vector, @oracle.binary(p), value), Ok(vector))
        }
        let scaled = scale(value, @oracle.binary(p - 1))
        let scaled_result = required(factor(scaled))
        assert_eq(@oracle.int_of_binary(scaled_result.unit), p - 1)
        assert_eq(scaled_result.factors, result.factors)
        assert_true(
          check_factorization(
            scaled,
            scaled_result,
            test_certificates(scaled_result),
          ),
        )
      }
    }
  }
}

///|
test "Frobenius and Bezout certificates reject altered shapes values and fields" {
  let value = test_polynomial(2, [1, 1, 0, 1])
  let certificate = test_certificate(value)
  assert_true(check_irreducible(value, certificate))
  assert_false(check_irreducible(test_polynomial(2, [1, 0, 1, 1]), certificate))
  assert_false(
    check_irreducible(value, { ..certificate, frobenius: @core.Nil, }),
  )
  assert_false(check_irreducible(value, { ..certificate, coprime: @core.Nil, }))
  assert_false(
    check_irreducible(value, {
      ..certificate,
      frobenius: @core.append(
        certificate.frobenius,
        @core.Cons(indeterminate(test_field(2)), Nil),
      ),
    }),
  )
  let powers = @oracle.array(certificate.frobenius)
  powers[0] = required(add(powers[0], one(test_field(2))))
  assert_false(
    check_irreducible(value, {
      ..certificate,
      frobenius: @oracle.chain(powers),
    }),
  )
  powers[0] = zero(test_field(3))
  assert_false(
    check_irreducible(value, {
      ..certificate,
      frobenius: @oracle.chain(powers),
    }),
  )
  let witness = @oracle.array(certificate.coprime)[0]
  assert_false(
    check_irreducible(value, {
      ..certificate,
      coprime: @core.Cons(
        { ..witness, left: zero(test_field(2)), right: zero(test_field(2)), },
        Nil,
      ),
    }),
  )
  assert_false(
    check_irreducible(value, {
      ..certificate,
      coprime: @core.Cons({ ..witness, left: zero(test_field(3)), }, Nil),
    }),
  )
  assert_false(
    check_irreducible(value, {
      ..certificate,
      coprime: @core.append(certificate.coprime, certificate.coprime),
    }),
  )
  assert_eq(irreducibility(zero(test_field(2))), Ok(None))
  assert_eq(irreducibility(one(test_field(2))), Ok(None))
  assert_eq(irreducibility(test_polynomial(3, [2, 0, 2])), Ok(None))
}

///|
test "factorization certificates reject wrong units multiplicities omissions order and fields" {
  let value = test_polynomial(3, [0, 1, 0, 1])
  let result = required(factor(value))
  let certificates = test_certificates(result)
  assert_true(check_factorization(value, result, certificates))
  assert_false(
    check_factorization(
      value,
      { ..result, unit: @oracle.binary(0), },
      certificates,
    ),
  )
  assert_false(
    check_factorization(
      value,
      { ..result, unit: @oracle.binary(2), },
      certificates,
    ),
  )
  assert_false(
    check_factorization(
      value,
      { ..result, unit: @oracle.binary(4), },
      certificates,
    ),
  )
  assert_false(check_factorization(value, result, @core.Nil))
  assert_false(
    check_factorization(value, { ..result, factors: @core.Nil, }, @core.Nil),
  )
  let factors = @oracle.array(result.factors)
  let proofs = @oracle.array(certificates)
  assert_eq(factors.length(), 2)
  assert_false(
    check_factorization(
      value,
      { ..result, factors: @oracle.chain(factors.rev()), },
      @oracle.chain(proofs.rev()),
    ),
  )
  let original = factors[0]
  factors[0] = { ..original, multiplicity: @oracle.nat(0), }
  assert_false(
    check_factorization(
      value,
      { ..result, factors: @oracle.chain(factors), },
      certificates,
    ),
  )
  factors[0] = { ..original, multiplicity: @oracle.nat(2), }
  assert_false(
    check_factorization(
      value,
      { ..result, factors: @oracle.chain(factors), },
      certificates,
    ),
  )
  factors[0] = {
    polynomial: indeterminate(test_field(2)),
    multiplicity: @oracle.nat(1),
  }
  assert_false(
    check_factorization(
      value,
      { ..result, factors: @oracle.chain(factors), },
      certificates,
    ),
  )
  assert_eq(factor(zero(test_field(2))), Err(ZeroPolynomial))
  assert_eq(berlekamp_basis(zero(test_field(2))), Err(ZeroPolynomial))
  let unit = constant(test_field(5), @oracle.binary(3))
  let units = required(factor(unit))
  assert_eq(units.factors, @core.Nil)
  assert_true(check_factorization(unit, units, @core.Nil))
}
