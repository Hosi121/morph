///|
fn test_poly(values : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(values[i].0, values[i].1),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_integer_poly(values : Array[Int32]) -> @poly.Polynomial {
  test_poly(values.map(fn(c) { (c, 1) }))
}

///|
fn test_root(
  values : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @real.RootCertificate {
  {
    polynomial: test_integer_poly(values),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }
}

///|
fn test_primes() -> @core.Chain[@binary.Binary] {
  @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
}

///|
fn test_equal(a : @real.Number, b : @real.Number) -> Unit raise {
  match @real.compare(a, b, @oracle.nat(100)).unwrap() {
    @real.Compared(order, proof) => {
      assert_eq(order, Equal)
      assert_true(@real.check_comparison_result(order, proof))
    }
    _ => fail("exact root equality did not complete")
  }
}

///|
fn test_normalize(value : @real.Number) -> (@real.Number, Certificate) {
  match
    normalize(
      value,
      test_primes(),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    Normalized(value, proof) => (value, proof)
    _ => abort("small normalizer fixture unresolved")
  }
}

///|
fn test_degree(p : @poly.Polynomial) -> Int32 {
  match @poly.terms(p) {
    Cons(head, _) =>
      match head.exponents {
        Cons(n, Nil) => @oracle.int_of_nat(n)
        _ => abort("univariate degree")
      }
    _ => -1
  }
}

///|
fn native_product(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      out[i + j] += a[i] * b[j]
    }
  }
  out
}

///|
test "minimal normalization proves zero rational and square root minimal polynomials" {
  for (numerator, denominator) in [(0, 1), (1, 2), (-7, 3), (2, 1)] {
    let input = @real.rational(@oracle.rational(numerator, denominator)).unwrap()
    let (output, proof) = test_normalize(input)
    assert_eq(
      @real.definition(output),
      test_poly([(-numerator, denominator), (1, 1)]),
    )
    assert_eq(check(proof, @oracle.nat(256)), @zass.Proven)
    assert_eq(check_result(output, proof, @oracle.nat(256)), @zass.Proven)
    assert_eq(
      check_normalization(input, output, proof, @oracle.nat(256)),
      @zass.Proven,
    )
    assert_eq(@real.interval(output), @real.interval(input))
    test_equal(input, output)
  }
  let input = @real.number(test_root([0, -2, 0, 1], (1, 1), (2, 1))).unwrap()
  let (output, proof) = test_normalize(input)
  assert_eq(test_degree(@real.definition(input)), 3)
  assert_eq(@real.definition(output), test_integer_poly([-2, 0, 1]))
  assert_eq(check_result(output, proof, @oracle.nat(256)), @zass.Proven)
  test_equal(input, output)
}

///|
test "minimal normalization removes irrelevant real complex and repeated defining factors" {
  let minimal = [-2, 0, 1]
  let full = native_product(native_product(minimal, [-3, 1]), [1, 0, 1])
  let input = @real.number(test_root(full, (1, 1), (2, 1))).unwrap()
  let (output, proof) = test_normalize(input)
  assert_eq(test_degree(@real.definition(input)), 5)
  assert_eq(@real.definition(output), test_integer_poly(minimal))
  assert_eq(
    check_normalization(input, output, proof, @oracle.nat(256)),
    @zass.Proven,
  )
  let repeated = native_product(native_product(minimal, minimal), [1, 0, 1])
  let raw : @real.RootCertificate = {
    polynomial: test_poly(repeated.map(fn(c) { (-3 * c, 5) })),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }
  let input = @real.number(raw).unwrap()
  match
    normalize_root(
      raw,
      test_primes(),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    Normalized(output, proof) => {
      assert_eq(@real.definition(output), test_integer_poly(minimal))
      assert_eq(proof.input, raw)
      assert_true(
        @oracle.array(proof.factorization.factors).any(fn(f) {
          @oracle.int_of_nat(f.multiplicity) == 2
        }),
      )
      assert_eq(
        check_normalization(input, output, proof, @oracle.nat(256)),
        @zass.Proven,
      )
      test_equal(input, output)
    }
    _ => fail("repeated nonmonic rational input unresolved")
  }
}

///|
test "explicit normalization lowers sqrt2 squared degree and proves sqrt2 plus sqrt3 irreducible" {
  let a = @real.number(test_root([-2, 0, 1], (1, 1), (2, 1))).unwrap()
  let b = @real.number(test_root([-3, 0, 1], (1, 1), (2, 1))).unwrap()
  let square = match @real.multiply(a, a, @oracle.nat(100)).unwrap() {
    @real.ArithmeticReady(value, proof) => {
      assert_true(@real.check_arithmetic_result(value, proof))
      value
    }
    _ => abort("sqrt square")
  }
  assert_eq(test_degree(@real.definition(square)), 2)
  let (minimal_square, proof) = test_normalize(square)
  assert_eq(@real.definition(minimal_square), test_integer_poly([-2, 1]))
  assert_eq(check_result(minimal_square, proof, @oracle.nat(256)), @zass.Proven)
  test_equal(minimal_square, @real.rational(@oracle.rational(2, 1)).unwrap())
  let sum = match @real.add(a, b, @oracle.nat(100)).unwrap() {
    @real.ArithmeticReady(value, proof) => {
      assert_true(@real.check_arithmetic_result(value, proof))
      value
    }
    _ => abort("sqrt sum")
  }
  let (minimal_sum, proof) = test_normalize(sum)
  assert_eq(@real.definition(minimal_sum), test_integer_poly([1, 0, -10, 0, 1]))
  assert_eq(check_result(minimal_sum, proof, @oracle.nat(256)), @zass.Proven)
  test_equal(sum, minimal_sum)
}

///|
test "minimal normalization treats prime lift subset and proof budgets as unresolved" {
  let input = @real.number(test_root([-2, 0, 1], (1, 1), (2, 1))).unwrap()
  assert_true(
    normalize(input, Nil, @oracle.nat(40), @oracle.nat(256), @oracle.nat(256)).unwrap()
    is Unresolved(NoGoodPrime),
  )
  assert_true(
    normalize(
      input,
      @oracle.chain([@oracle.binary(2)]),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap()
    is Unresolved(NoGoodPrime),
  )
  assert_true(
    normalize(
      input,
      @oracle.chain([@oracle.binary(3)]),
      Zero,
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap()
    is Unresolved(LiftBudget),
  )
  assert_true(
    normalize(input, test_primes(), @oracle.nat(40), Zero, @oracle.nat(256)).unwrap()
    is Unresolved(SubsetBudget),
  )
  assert_true(
    normalize(input, test_primes(), @oracle.nat(40), @oracle.nat(256), Zero).unwrap()
    is Unresolved(VerificationBudget),
  )
  let (_, proof) = test_normalize(input)
  assert_eq(check(proof, Zero), @zass.Undecided)
  assert_true(
    normalize_root(
      test_root([-2, 0, 1], (-2, 1), (2, 1)),
      test_primes(),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    )
    is Err(InvalidInput),
  )
}

///|
test "minimal checker rejects another factor conjugate payload and product-only factorization proof" {
  let original = @real.number(test_root([6, -2, -3, 1], (1, 1), (2, 1))).unwrap() // (x^2-2)(x-3)
  let (output, proof) = test_normalize(original)
  let wrong_conjugate = @real.number(test_root([-2, 0, 1], (-2, 1), (-1, 1))).unwrap()
  assert_eq(
    check_result(wrong_conjugate, proof, @oracle.nat(256)),
    @zass.Refuted,
  )
  assert_eq(
    check(
      { ..proof, result: @real.root_certificate(wrong_conjugate), },
      @oracle.nat(256),
    ),
    @zass.Refuted,
  )
  let other_factor = @real.rational(@oracle.rational(3, 1)).unwrap()
  assert_eq(check_result(other_factor, proof, @oracle.nat(256)), @zass.Refuted)
  assert_eq(
    check({ ..proof, selected: @oracle.nat(99), }, @oracle.nat(256)),
    @zass.Refuted,
  )
  let wrong_input = @real.number(test_root([6, -2, -3, 1], (-2, 1), (-1, 1))).unwrap()
  assert_eq(
    check_normalization(wrong_input, output, proof, @oracle.nat(256)),
    @zass.Refuted,
  )
  let negative_proof : Certificate = {
    ..proof,
    input: @real.root_certificate(wrong_input),
    result: @real.root_certificate(wrong_conjugate),
  }
  assert_eq(
    check_result(wrong_conjugate, negative_proof, @oracle.nat(256)),
    @zass.Proven,
  )
  assert_eq(
    check_normalization(
      original,
      wrong_conjugate,
      negative_proof,
      @oracle.nat(256),
    ),
    @zass.Refuted,
  )
  let factors = @oracle.array(proof.factorization.factors)
  for index in 0..<factors.length() {
    if index == @oracle.int_of_nat(proof.selected) {
      continue
    }
    let wrong_root : @real.RootCertificate = {
      polynomial: integer_polynomial(factors[index].polynomial).unwrap(),
      interval: {
        lower: @oracle.rational(2, 1),
        upper: @oracle.rational(3, 1),
      },
    }
    assert_true(@real.check_root(wrong_root))
    assert_eq(
      check(
        { ..proof, selected: @oracle.nat(index), result: wrong_root, },
        @oracle.nat(256),
      ),
      @zass.Refuted,
    )
  }
  let full = [-2, 0, -1, 0, 1] // (x^2-2)(x^2+1)
  let reducible = @real.number(test_root(full, (1, 1), (2, 1))).unwrap()
  let (_, actual) = test_normalize(reducible)
  let factor = @core.nth(actual.factorization.factors, actual.selected).unwrap()
  let forged_factor : @zass.Factor = {
    polynomial: @zass.polynomial(@oracle.chain(full.map(@oracle.integer))),
    multiplicity: Succ(Zero),
    certificate: factor.certificate,
  }
  assert_true(
    @zass.check_product(forged_factor.polynomial, {
      content: @oracle.integer(1),
      factors: Cons(forged_factor, Nil),
    }),
  )
  let forged : Certificate = {
    ..actual,
    factorization: {
      unit: @oracle.rational(1, 1),
      factors: Cons(forged_factor, Nil),
    },
    selected: Zero,
    result: @real.root_certificate(reducible),
  }
  assert_true(@real.check_root(forged.result))
  assert_eq(check_result(reducible, forged, @oracle.nat(256)), @zass.Refuted)
}

///|
fn assert_minpoly_fixture(
  input : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
  expected : Array[(Int32, Int32)],
) -> Unit raise {
  let root : @real.RootCertificate = {
    polynomial: test_poly(input),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }
  let original = @real.number(root).unwrap()
  match
    normalize_root(
      root,
      test_primes(),
      @oracle.nat(40),
      @oracle.nat(512),
      @oracle.nat(512),
    ).unwrap() {
    Normalized(value, proof) => {
      assert_eq(@real.definition(value), test_poly(expected))
      assert_true(
        test_degree(@real.definition(value)) <
        test_degree(@real.definition(original)),
      )
      assert_eq(@real.interval(value), root.interval)
      assert_eq(check_result(value, proof, @oracle.nat(512)), @zass.Proven)
      assert_eq(
        check_normalization(original, value, proof, @oracle.nat(512)),
        @zass.Proven,
      )
      let independent = @real.number({
        polynomial: test_poly(expected),
        interval: root.interval,
      }).unwrap()
      test_equal(value, independent)
    }
    _ => fail("independent minpoly fixture unresolved")
  }
}

///|
test "minimal factor selection excludes a different root exactly at the lower endpoint" {
  for
    (coefficients, lower, expected) in [([0, -1, 1], 0, 1), ([2, -3, 1], 1, 2)] {
    let original = @real.number(
      test_root(coefficients, (lower, 1), (expected, 1)),
    ).unwrap()
    let (result, proof) = test_normalize(original)
    assert_eq(@real.definition(result), test_integer_poly([-expected, 1]))
    assert_eq(
      check_normalization(original, result, proof, @oracle.nat(256)),
      @zass.Proven,
    )
  }
}
