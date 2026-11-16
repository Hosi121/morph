///|
fn oracle_poly(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, q in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(q.0, q.1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn oracle_context(base_degree : Int32, constant : Int32) -> @cf.Field {
  let coefficients = Array::make(base_degree + 1, (0, 1))
  coefficients[0] = (-constant, 1)
  coefficients[base_degree] = (1, 1)
  let lower = if base_degree == 1 { -1 } else { 1 }
  let upper = if base_degree == 1 { 0 } else { 2 }
  let root : @real.RootCertificate = {
    polynomial: oracle_poly(coefficients),
    interval: {
      lower: @oracle.rational(lower, 1),
      upper: @oracle.rational(upper, 1),
    },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("primitive-coordinate oracle needs a verified real minimum")
  }
}

///|
fn oracle_element(
  field : @cf.Field,
  real : Array[(Int32, Int32)],
  imaginary : Array[(Int32, Int32)],
) -> @cf.Element {
  let parent = @cf.real_field(field)
  @cf.element(
    field,
    @nf.element(parent, oracle_poly(real)).unwrap(),
    @nf.element(parent, oracle_poly(imaginary)).unwrap(),
  ).unwrap()
}

///|
fn oracle_matrix(
  rows : Array[Array[(Int32, Int32)]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(rows.length()),
    @oracle.chain(
      rows.map(fn(row) {
        @oracle.chain(row.map(fn(q) { @oracle.rational(q.0, q.1) }))
      }),
    ),
  ).unwrap()
}

///|
fn oracle_assert_conversion(
  rep : Representation,
  input : @cf.Element,
  expected_coefficients : Array[(Int32, Int32)],
) -> Unit raise {
  let expected = oracle_poly(expected_coefficients)
  let actual = to_polynomial(rep, input).unwrap()
  assert_eq(actual.polynomial, expected)
  assert_true(check_conversion_for(rep, input, expected, actual.certificate))
  assert_true(@cf.equal(from_polynomial(rep, expected).unwrap(), input))
}

///|
fn oracle_assert_primitive_fixture(
  base_degree : Int32,
  constant : Int32,
  expected_modulus : Array[(Int32, Int32)],
  expected_basis : Array[Array[(Int32, Int32)]],
  expected_inverse : Array[Array[(Int32, Int32)]],
  expected_alpha_image : Array[(Int32, Int32)],
  expected_imaginary_image : Array[(Int32, Int32)],
  samples : Array[
    (Array[(Int32, Int32)], Array[(Int32, Int32)], Array[(Int32, Int32)]),
  ],
  products : Array[
    (
      Int32,
      Int32,
      (Array[(Int32, Int32)], Array[(Int32, Int32)], Array[(Int32, Int32)]),
    ),
  ],
) -> Unit raise {
  let field = oracle_context(base_degree, constant)
  let rep = prepare(field).unwrap()
  let theta = oracle_element(field, samples[0].0, samples[0].1)
  let expected : Certificate = {
    source: field,
    theta,
    modulus: oracle_poly(expected_modulus),
    basis: oracle_matrix(expected_basis),
    inverse_basis: oracle_matrix(expected_inverse),
    real_generator_image: oracle_poly(expected_alpha_image),
    imaginary_unit_image: oracle_poly(expected_imaginary_image),
  }
  assert_eq(degree(rep), @oracle.nat(2 * base_degree))
  assert_true(@cf.same_field(source(rep), field))
  assert_true(@cf.equal(generator(rep), theta))
  assert_eq(modulus(rep), expected.modulus)
  assert_eq(basis_matrix(rep), expected.basis)
  assert_eq(inverse_basis_matrix(rep), expected.inverse_basis)
  assert_eq(real_generator_image(rep), expected.real_generator_image)
  assert_eq(imaginary_unit_image(rep), expected.imaginary_unit_image)
  assert_true(check(field, expected))
  assert_true(check(field, certificate(rep)))
  let imported = from_certificate(field, expected).unwrap()
  assert_eq(basis_matrix(imported), expected.basis)
  assert_eq(inverse_basis_matrix(imported), expected.inverse_basis)
  let alpha = @cf.element(
    field,
    @nf.generator(@cf.real_field(field)).unwrap(),
    @nf.zero(@cf.real_field(field)),
  ).unwrap()
  assert_true(
    @cf.equal(
      from_polynomial(rep, expected.real_generator_image).unwrap(),
      alpha,
    ),
  )
  assert_true(
    @cf.equal(
      from_polynomial(rep, expected.imaginary_unit_image).unwrap(),
      @cf.imaginary_unit(field),
    ),
  )
  let values = samples.map(fn(sample) {
    oracle_element(field, sample.0, sample.1)
  })
  for index, sample in samples {
    oracle_assert_conversion(rep, values[index], sample.2)
  }
  for (left, right, expected_product) in products {
    let actual = @cf.multiply(values[left], values[right]).unwrap()
    let expected_value = oracle_element(
      field,
      expected_product.0,
      expected_product.1,
    )
    assert_true(@cf.equal(actual, expected_value))
    oracle_assert_conversion(rep, actual, expected_product.2)
    let unreduced = @poly.multiply(
      oracle_poly(samples[left].2),
      oracle_poly(samples[right].2),
    ).unwrap()
    assert_eq(
      @poly.normal_form(unreduced, Cons(expected.modulus, Nil)).unwrap(),
      oracle_poly(expected_product.2),
    )
    assert_true(
      @cf.equal(from_polynomial(rep, unreduced).unwrap(), expected_value),
    )
  }
}
