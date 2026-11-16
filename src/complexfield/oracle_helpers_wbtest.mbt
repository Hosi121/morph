///|
fn oracle_poly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(
            coefficients[index].0,
            coefficients[index].1,
          ),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn oracle_context(base_degree : Int32, constant : Int32) -> Field {
  let coefficients = Array::make(base_degree + 1, (0, 1))
  coefficients[0] = (-constant, 1)
  coefficients[base_degree] = (1, 1)
  let (lower, upper) = if base_degree == 1 {
    (-1, 0)
  } else if constant == 5 {
    (2, 3)
  } else {
    (1, 2)
  }
  let input : @real.RootCertificate = {
    polynomial: oracle_poly(coefficients),
    interval: {
      lower: @oracle.rational(lower, 1),
      upper: @oracle.rational(upper, 1),
    },
  }
  let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
  match
    @minimal.normalize_root(
      input,
      primes,
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Normalized(value, proof) =>
      field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("independent oracle field must have a verified real minimum")
  }
}

///|
fn oracle_element(
  context : Field,
  real : Array[(Int32, Int32)],
  imaginary : Array[(Int32, Int32)],
) -> Element {
  let parent = real_field(context)
  element(
    context,
    @nf.element(parent, oracle_poly(real)).unwrap(),
    @nf.element(parent, oracle_poly(imaginary)).unwrap(),
  ).unwrap()
}

///|
fn assert_complexfield_fixture(
  base_degree : Int32,
  constant : Int32,
  real : Array[(Int32, Int32)],
  imaginary : Array[(Int32, Int32)],
  expected_trace : (Int32, Int32),
  expected_norm : (Int32, Int32),
  expected_minimum : Array[(Int32, Int32)],
  expected_matrix : Array[Array[(Int32, Int32)]],
  expected_relative_trace : Array[(Int32, Int32)],
  expected_relative_norm : Array[(Int32, Int32)],
  expected_inverse : (Array[(Int32, Int32)], Array[(Int32, Int32)])?,
) -> Unit raise {
  let context = oracle_context(base_degree, constant)
  let value = oracle_element(context, real, imaginary)
  assert_eq(@oracle.int_of_nat(degree(context)), 2 * base_degree)
  let expected_trace = @oracle.rational(expected_trace.0, expected_trace.1)
  let expected_norm = @oracle.rational(expected_norm.0, expected_norm.1)
  assert_eq(trace(value).unwrap(), expected_trace)
  assert_eq(norm(value).unwrap(), expected_norm)
  assert_true(check_trace(value, expected_trace))
  assert_true(check_norm(value, expected_norm))
  assert_false(
    check_trace(
      value,
      @exact.rational_add(expected_trace, @exact.rational_one()),
    ),
  )
  assert_false(
    check_norm(value, @exact.rational_add(expected_norm, @exact.rational_one())),
  )
  assert_eq(
    @nf.representative(relative_trace(value).unwrap()),
    oracle_poly(expected_relative_trace),
  )
  assert_eq(
    @nf.representative(relative_norm(value).unwrap()),
    oracle_poly(expected_relative_norm),
  )
  let expected = @matrix.matrix(
    @oracle.nat(2 * base_degree),
    @oracle.chain(
      expected_matrix.map(fn(row) {
        @oracle.chain(row.map(fn(q) { @oracle.rational(q.0, q.1) }))
      }),
    ),
  ).unwrap()
  assert_eq(multiplication_matrix(value).unwrap(), expected)
  let minimum = oracle_poly(expected_minimum)
  assert_eq(minimal_polynomial(value).unwrap(), minimum)
  assert_true(check_minimal_polynomial(value, minimum))
  if expected_minimum.length() <= 2 * base_degree {
    let padded = @poly.multiply(minimum, oracle_poly([(-7, 1), (1, 1)])).unwrap()
    assert_false(check_minimal_polynomial(value, padded))
  }
  match (inverse(value).unwrap(), expected_inverse) {
    (None, None) => assert_true(is_zero(value))
    (Some(actual), Some((real, imaginary))) => {
      let expected = oracle_element(context, real, imaginary)
      assert_true(equal(actual, expected))
      assert_true(equal(multiply(value, actual).unwrap(), one(context)))
    }
    _ =>
      fail("inverse existence disagrees with the independent algebraic oracle")
  }
}

///|
test "independent eighth power remains in the fixed quartic basis" {
  let context = oracle_context(2, 2)
  let value = oracle_element(context, [(0, 1), (1, 1)], [(1, 1)])
  let squared = multiply(value, value).unwrap()
  let fourth = multiply(squared, squared).unwrap()
  let eighth = multiply(fourth, fourth).unwrap()
  let expected = oracle_element(context, [(17, 1)], [(0, 1), (-56, 1)])
  assert_true(equal(eighth, expected))
  assert_eq(
    minimal_polynomial(eighth).unwrap(),
    oracle_poly([(6561, 1), (-34, 1), (1, 1)]),
  )
  assert_true(check_norm(eighth, @oracle.rational(43046721, 1)))
}

///|
test "explicit eighth degree field splits z4 minus two into four distinct roots" {
  let context = oracle_context(4, 2)
  let a = oracle_element(context, [(0, 1), (1, 1)], [(0, 1)])
  let ia = multiply(imaginary_unit(context), a).unwrap()
  let selected = [a, negate(a), ia, negate(ia)]
  for i in 0..<selected.length() {
    for j in (i + 1)..<selected.length() {
      assert_false(equal(selected[i], selected[j]))
    }
  }
  let mut product = [one(context)]
  for root in selected {
    let next = Array::make(product.length() + 1, zero(context))
    for index in 0..<product.length() {
      next[index] = subtract(
        next[index],
        multiply(root, product[index]).unwrap(),
      ).unwrap()
      next[index + 1] = add(next[index + 1], product[index]).unwrap()
    }
    product = next
  }
  assert_eq(product.length(), 5)
  for index in 0..<5 {
    let expected = rational(
      context,
      @oracle.rational(
        if index == 0 {
          -2
        } else if index == 4 {
          1
        } else {
          0
        },
        1,
      ),
    )
    assert_true(equal(product[index], expected))
  }
  assert_true(equal(divide(ia, a).unwrap().unwrap(), imaginary_unit(context)))
  assert_eq(@oracle.int_of_nat(degree(context)), 8)
}
