///|
test "prepared NF multiply matches machine long division and old generic path" {
  let fixtures : Array[(Field, Array[Int64])] = [
    (test_field([(0, 1), (1, 1)], (-1, 1), (0, 1)), [0, 1]),
    (test_sqrt2(), [-2, 0, 1]),
    (
      test_field([(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)], (3, 1), (4, 1)),
      [1, 0, -10, 0, 1],
    ),
  ]
  let inputs : Array[Array[Int64]] = [
    [],
    [0],
    [-2],
    [0, 1],
    [1, -1, 2, -2],
    [-2, 0, 0, 1, 0, -1, 1],
  ]
  for (f, monic) in fixtures {
    for aa in inputs {
      for bb in inputs {
        let a = element(f, test_poly(aa.map(fn(n) { (n, 1L) }))).unwrap()
        let b = element(f, test_poly(bb.map(fn(n) { (n, 1L) }))).unwrap()
        let dense = Array::make(aa.length() + bb.length(), 0L)
        for i in 0..<aa.length() {
          for j in 0..<bb.length() {
            dense[i + j] = dense[i + j] + aa[i] * bb[j]
          }
        }
        let expected = kernel_remainder(dense, monic)
        let actual = multiply(a, b).unwrap()
        assert_eq(
          representative(actual),
          test_poly(expected.map(fn(n) { (n, 1L) })),
        )
        let generic = element(
          f,
          @poly.multiply(representative(a), representative(b)).unwrap(),
        ).unwrap()
        assert_true(equal(actual, generic))
        assert_true(same_field(parent(actual), f))
        assert_true(equal(multiply(a, zero(f)).unwrap(), zero(f)))
      }
    }
  }
}

///|
test "prepared reducer handles rational nonmonic divisors against generic remainder" {
  let moduli = [
    test_poly([(-2, 3), (0, 1), (1, 3)]),
    test_poly([(1, 2), (0, 1), (-5, 1), (0, 1), (1, 2)]),
  ]
  for modulus in moduli {
    let d = match @poly.terms(modulus) {
      Cons({ exponents: Cons(d, Nil), .. }, _) => d
      _ => abort("nonmonic fixture has no degree")
    }
    let reduction = @poly.negate(@poly.monic(modulus))
    let inputs = [
      [],
      [(1L, 3L)],
      [(0L, 1L), (0L, 1L), (0L, 1L), (-2L, 3L), (1L, 2L), (-1L, 3L), (2L, 1L)],
    ]
    for input in inputs {
      let polynomial = test_poly(input)
      assert_eq(
        prepared_remainder(polynomial, reduction, d).unwrap(),
        @poly.normal_form(polynomial, Cons(modulus, Nil)).unwrap(),
      )
    }
  }
}

///|
test "prepared field multiplication retains context and normalization rejection behavior" {
  let f = test_field([(-4, 1), (0, 1), (2, 1)], (1, 1), (2, 1))
  assert_eq(modulus(f), test_integer_poly([-2, 0, 1]))
  let a = generator(f).unwrap()
  assert_true(equal(multiply(a, a).unwrap(), rational(f, test_rational(2, 1))))
  let conjugate = test_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  let refined = test_field([(-2, 1), (0, 1), (1, 1)], (7, 5), (3, 2))
  for other in [conjugate, refined] {
    match multiply(a, generator(other).unwrap()) {
      Err(DifferentField) => ()
      _ => fail("prepared multiplication lost the selected root interval")
    }
  }
  let proof = certificate(f)
  let nonmonic_result = {
    ..proof,
    result: { ..proof.result, polynomial: test_integer_poly([-4, 0, 2]), },
  }
  assert_true(
    field(nonmonic_result, @oracle.nat(256)) is Err(InvalidCertificate),
  )
  assert_true(field(proof, Zero) is Err(VerificationBudget))
  assert_true(element(f, @poly.zero(@oracle.nat(2))) is Err(DimensionMismatch))
}
