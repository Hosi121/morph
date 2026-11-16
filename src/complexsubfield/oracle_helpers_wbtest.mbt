///|
struct OracleSubfieldFixture {
  minimum : Array[@exact.Rational]
  lower : @exact.Rational
  upper : @exact.Rational
  generators : Array[Array[@exact.Rational]]
  generator_minima : Array[Array[@exact.Rational]]
  degree : Int32
  basis : Array[Array[@exact.Rational]]
  monomials : Array[Array[Int32]]
  left_inverse : Array[Array[@exact.Rational]]
  annihilator : Array[Array[@exact.Rational]]
  closure : Array[Array[Array[@exact.Rational]]]
  candidate : Int32
  theta : Array[@exact.Rational]
  primitive_minimum : Array[@exact.Rational]
  power_basis : Array[Array[@exact.Rational]]
  samples : Array[(Array[@exact.Rational], Array[@exact.Rational])]
  inclusions : Array[(Array[@exact.Rational], Array[@exact.Rational]?)]
}

///|
fn oracle_poly(coefficients : Array[@exact.Rational]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{ coefficient, exponents: Cons(@oracle.nat(index), Nil), }
        }
      ],
    ),
  ).unwrap()
}

///|
fn oracle_context(fixture : OracleSubfieldFixture) -> @cf.Field {
  let root : @real.RootCertificate = {
    polynomial: oracle_poly(fixture.minimum),
    interval: { lower: fixture.lower, upper: fixture.upper, },
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
    _ => abort("generated-subfield oracle needs a verified real minimum")
  }
}

///|
fn oracle_value(
  field : @cf.Field,
  values : Array[@exact.Rational],
) -> @cf.Element {
  @cf.from_coordinates(field, @oracle.chain(values)).unwrap()
}

///|
fn oracle_matrix(
  rows : Array[Array[@exact.Rational]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(rows[0].length()),
    @oracle.chain(rows.map(@oracle.chain)),
  ).unwrap()
}

///|
fn oracle_dot(
  left : Array[@exact.Rational],
  right : Array[@exact.Rational],
) -> @exact.Rational {
  let mut result = @exact.rational_zero()
  for index, coefficient in left {
    result = @exact.rational_add(
      result,
      @exact.rational_multiply(coefficient, right[index]),
    )
  }
  result
}

///|
fn oracle_basis_coordinates(
  fixture : OracleSubfieldFixture,
  value : Array[@exact.Rational],
) -> Array[@exact.Rational] {
  fixture.left_inverse.map(fn(row) { oracle_dot(row, value) })
}

///|
fn oracle_assert_span(
  fixture : OracleSubfieldFixture,
  value : Array[@exact.Rational],
) -> Unit raise {
  for row in fixture.annihilator {
    assert_eq(oracle_dot(row, value), @exact.rational_zero())
  }
  let coefficients = oracle_basis_coordinates(fixture, value)
  for row in 0..<value.length() {
    let column = fixture.basis.map(fn(b) { b[row] })
    assert_eq(oracle_dot(coefficients, column), value[row])
  }
}

///|
fn oracle_rank(source : @cf.Field, values : Array[@cf.Element]) -> Int32 {
  let columns = values.map(fn(value) { @oracle.array(@cf.coordinates(value)) })
  let rows = [
    for row in 0..<@oracle.int_of_nat(@cf.degree(source)) => {
      [
        for column in columns => column[row]
      ]
    }
  ]
  @oracle.array(@linear.rref(oracle_matrix(rows)).unwrap().pivots).length()
}

///|
fn oracle_roundtrip(field : Field, value : @cf.Element) -> Unit raise {
  assert_true(contains(field, value))
  let coefficients = coordinates(field, value).unwrap()
  assert_eq(
    @oracle.array(coefficients).length(),
    @oracle.int_of_nat(degree(field)),
  )
  assert_true(@cf.equal(from_coordinates(field, coefficients).unwrap(), value))
}

///|
fn oracle_ready(search : PrimitiveSearch, rounds : Int32) -> Representation {
  if rounds <= 0 {
    abort("finite oracle primitive search exceeded its fixture bound")
  }
  match primitive_advance(search, @oracle.nat(2)).unwrap() {
    PrimitiveReady(rep, _) => rep
    PrimitivePaused(next) => oracle_ready(next, rounds - 1)
  }
}

///|
fn oracle_assert_subfield(fixture : OracleSubfieldFixture) -> Unit raise {
  let source = oracle_context(fixture)
  let values = fixture.generators.map(fn(value) { oracle_value(source, value) })
  for index, value in values {
    assert_eq(
      @cf.minimal_polynomial(value).unwrap(),
      oracle_poly(fixture.generator_minima[index]),
    )
  }
  let requested = @oracle.chain(values)
  let independent_basis = fixture.basis.map(fn(value) {
    oracle_value(source, value)
  })
  let expected : Certificate = {
    source,
    generators: requested,
    degree: @oracle.nat(fixture.degree),
    basis: @oracle.chain(independent_basis),
    monomials: @oracle.chain(
      fixture.monomials.map(fn(xs) { @oracle.chain(xs.map(@oracle.nat)) }),
    ),
  }
  assert_eq(@cf.degree(source), @oracle.nat(fixture.theta.length()))
  assert_eq(oracle_rank(source, independent_basis), fixture.degree)
  assert_true(check(source, requested, expected))
  let imported = from_certificate(source, requested, expected).unwrap()
  assert_true(check_result(source, requested, imported, expected))
  let actual = generate(source, requested).unwrap()
  assert_eq(degree(actual), @oracle.nat(fixture.degree))
  assert_true(@cf.same_field(ambient(actual), source))
  assert_eq(@oracle.array(generators(actual)).length(), values.length())
  for index, value in @oracle.array(generators(actual)) {
    assert_true(@cf.equal(value, values[index]))
  }
  assert_true(check_result(source, requested, actual, certificate(actual)))
  let actual_basis = @oracle.array(basis(actual))
  assert_eq(actual_basis.length(), fixture.degree)
  assert_eq(oracle_rank(source, actual_basis), fixture.degree)
  // A different producer ordering is valid. Compare the two exact spans.
  for value in actual_basis {
    oracle_assert_span(fixture, @oracle.array(@cf.coordinates(value)))
    oracle_roundtrip(imported, value)
  }
  for index, value in independent_basis {
    oracle_roundtrip(actual, value)
    for generator_index, generator in values {
      let product = @cf.multiply(value, generator).unwrap()
      let expected_coordinates = fixture.closure[index][generator_index]
      assert_eq(
        coordinates(imported, product).unwrap(),
        @oracle.chain(expected_coordinates),
      )
      assert_true(
        @cf.equal(
          from_coordinates(imported, @oracle.chain(expected_coordinates)).unwrap(),
          product,
        ),
      )
    }
  }
  // This closed, independent full ambient space contains every input. False
  // monomial witnesses must still reject it when it exceeds the generated field.
  if fixture.degree < fixture.theta.length() {
    let ambient_basis = [
      for column in 0..<fixture.theta.length() => {
        oracle_value(
          source,
          [
            for row in 0..<fixture.theta.length() => {
              if row == column {
                @exact.rational_one()
              } else {
                @exact.rational_zero()
              }
            }
          ],
        )
      }
    ]
    assert_eq(oracle_rank(source, ambient_basis), fixture.theta.length())
    let oversized : Certificate = {
      ..expected,
      degree: @cf.degree(source),
      basis: @oracle.chain(ambient_basis),
      monomials: @oracle.chain(
        ambient_basis.map(fn(_) {
          @oracle.chain(values.map(fn(_) { @oracle.nat(0) }))
        }),
      ),
    }
    assert_false(check(source, requested, oversized))
    assert_true(
      from_certificate(source, requested, oversized) is Err(InvalidCertificate),
    )
  }
  let independent_primitive : PrimitiveCertificate = {
    field: expected,
    candidate: @oracle.nat(fixture.candidate),
    theta: oracle_value(source, fixture.theta),
    modulus: oracle_poly(fixture.primitive_minimum),
    power_basis: oracle_matrix(fixture.power_basis),
  }
  let rep = from_primitive_certificate(imported, independent_primitive).unwrap()
  assert_true(check_primitive_result(imported, rep, independent_primitive))
  assert_true(@cf.equal(primitive_element(rep), independent_primitive.theta))
  assert_eq(modulus(rep), independent_primitive.modulus)
  assert_eq(
    primitive_certificate(rep).power_basis,
    independent_primitive.power_basis,
  )
  let start = primitive_start(actual)
  let resumed = match primitive_advance(start, @oracle.nat(0)).unwrap() {
    PrimitivePaused(next) => {
      assert_eq(primitive_next_candidate(next), primitive_next_candidate(start))
      next
    }
    _ => abort("zero primitive trial budget must pause")
  }
  let produced = oracle_ready(resumed, 16)
  assert_eq(degree(representation_field(produced)), @oracle.nat(fixture.degree))
  oracle_assert_span(
    fixture,
    @oracle.array(@cf.coordinates(primitive_element(produced))),
  )
  assert_true(
    check_primitive_result(actual, produced, primitive_certificate(produced)),
  )
  for (sample, expected_coefficients) in fixture.samples {
    let value = oracle_value(source, sample)
    let expected_polynomial = oracle_poly(expected_coefficients)
    assert_eq(
      coordinates(imported, value).unwrap(),
      @oracle.chain(oracle_basis_coordinates(fixture, sample)),
    )
    oracle_roundtrip(actual, value)
    let conversion = to_polynomial(rep, value).unwrap()
    assert_eq(conversion.polynomial, expected_polynomial)
    assert_true(
      check_conversion_for(
        rep,
        value,
        expected_polynomial,
        conversion.certificate,
      ),
    )
    let independent_conversion : ConversionCertificate = {
      representation: independent_primitive,
      input: value,
      polynomial: expected_polynomial,
    }
    assert_true(
      check_conversion_for(
        rep, value, expected_polynomial, independent_conversion,
      ),
    )
    assert_true(
      @cf.equal(from_polynomial(rep, expected_polynomial).unwrap(), value),
    )
    let unreduced = @poly.add(
      expected_polynomial,
      independent_primitive.modulus,
    ).unwrap()
    assert_true(@cf.equal(from_polynomial(rep, unreduced).unwrap(), value))
    assert_false(
      check_conversion_for(rep, value, unreduced, {
        ..independent_conversion,
        polynomial: unreduced,
      }),
    )
    assert_false(
      check_conversion_for(
        rep,
        @cf.add(value, @cf.one(source)).unwrap(),
        expected_polynomial,
        independent_conversion,
      ),
    )
  }
  for (sample, inclusion) in fixture.inclusions {
    let value = oracle_value(source, sample)
    match inclusion {
      None => {
        assert_false(contains(actual, value))
        assert_false(contains(imported, value))
        assert_true(coordinates(imported, value) is Err(NotInSubfield))
        assert_true(to_polynomial(rep, value) is Err(NotInSubfield))
      }
      Some(expected_coordinates) => {
        oracle_roundtrip(actual, value)
        assert_eq(
          coordinates(imported, value).unwrap(),
          @oracle.chain(expected_coordinates),
        )
      }
    }
  }
}
