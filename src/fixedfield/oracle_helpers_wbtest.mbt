///|
struct OracleValue {
  real : Array[(Int32, Int32)]
  imaginary : Array[(Int32, Int32)]
}

///|
struct OracleSubgroup {
  members : Array[Int32]
  degree : Int32
  basis : Array[OracleValue]
  generator : OracleValue
  minimum : Array[(Int32, Int32)]
  generator_coordinates : Array[(Int32, Int32)]
  sample_coordinates : Array[Array[(Int32, Int32)]?]
}

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
  let root : @real.RootCertificate = {
    polynomial: oracle_poly(coefficients),
    interval: {
      lower: @oracle.rational(if base_degree == 1 { -1 } else { 1 }, 1),
      upper: @oracle.rational(if base_degree == 1 { 0 } else { 2 }, 1),
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
    _ => abort("fixed-field oracle needs a verified real minimum")
  }
}

///|
fn oracle_element(field : @cf.Field, value : OracleValue) -> @cf.Element {
  let parent = @cf.real_field(field)
  @cf.element(
    field,
    @nf.element(parent, oracle_poly(value.real)).unwrap(),
    @nf.element(parent, oracle_poly(value.imaginary)).unwrap(),
  ).unwrap()
}

///|
fn oracle_rationals(
  values : Array[(Int32, Int32)],
) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(q) { @oracle.rational(q.0, q.1) }))
}

///|
fn oracle_signed_coefficient(
  columns : Array[Int32],
  row : Int32,
  column : Int32,
) -> Int32 {
  let signed = columns[column]
  if signed == row + 1 {
    1
  } else if signed == -row - 1 {
    -1
  } else {
    0
  }
}

///|
fn oracle_action_matrix(
  columns : Array[Int32],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(columns.length()),
    @oracle.chain(
      [
        for row in 0..<columns.length() => {
          @oracle.chain(
            [
              for column in 0..<columns.length() => {
                @oracle.rational(
                  oracle_signed_coefficient(columns, row, column),
                  1,
                )
              }
            ],
          )
        }
      ],
    ),
  ).unwrap()
}

///|
fn oracle_constraints(
  actions : Array[Array[Int32]],
  members : Array[Int32],
) -> @matrix.Matrix[@exact.Rational] {
  let dimension = actions[0].length()
  let rows : Array[@core.Chain[@exact.Rational]] = []
  for map_index in members {
    for row in 0..<dimension {
      rows.push(
        @oracle.chain(
          [
            for column in 0..<dimension => {
              @oracle.rational(
                oracle_signed_coefficient(actions[map_index], row, column) -
                (if row == column { 1 } else { 0 }),
                1,
              )
            }
          ],
        ),
      )
    }
  }
  @matrix.matrix(@oracle.nat(dimension), @oracle.chain(rows)).unwrap()
}

///|
fn oracle_assert_rank(
  elements : Array[@cf.Element],
  dimension : Int32,
  expected_rank : Int32,
) -> Unit raise {
  let columns = elements.map(fn(element) {
    @oracle.array(@cf.coordinates(element))
  })
  let matrix = @matrix.matrix(
    @oracle.nat(elements.length()),
    @oracle.chain(
      [
        for row in 0..<dimension => {
          @oracle.chain(
            [
              for column in 0..<columns.length() => columns[column][row]
            ],
          )
        }
      ],
    ),
  ).unwrap()
  let rank = @oracle.array(@linear.rref(matrix).unwrap().pivots).length()
  assert_eq(rank, expected_rank)
}

///|
fn oracle_roundtrip(field : Field, value : @cf.Element) -> Unit raise {
  assert_true(contains(field, value))
  let actual_coordinates = coordinates(field, value).unwrap()
  assert_eq(
    @oracle.array(actual_coordinates).length(),
    @oracle.int_of_nat(degree(field)),
  )
  assert_true(
    @cf.equal(from_coordinates(field, actual_coordinates).unwrap(), value),
  )
}

///|
fn oracle_assert_fixed_fields(
  base_degree : Int32,
  constant : Int32,
  expected_roots : Array[OracleValue],
  expected_actions : Array[Array[Int32]],
  samples : Array[OracleValue],
  subgroups : Array[OracleSubgroup],
) -> Unit raise {
  let ambient = oracle_context(base_degree, constant)
  let aut_group = @aut.prepare(
    ambient,
    @oracle.chain(
      expected_roots.map(fn(value) { oracle_element(ambient, value) }),
    ),
  ).unwrap()
  let sample_values = samples.map(fn(value) { oracle_element(ambient, value) })
  let other_ambient = oracle_context(2, 3)
  let other_alpha = @cf.element(
    other_ambient,
    @nf.generator(@cf.real_field(other_ambient)).unwrap(),
    @nf.zero(@cf.real_field(other_ambient)),
  ).unwrap()
  let other_group = @aut.prepare(
    other_ambient,
    @oracle.chain([other_alpha, @cf.negate(other_alpha)]),
  ).unwrap()
  for subgroup in subgroups {
    let canonical_members = @oracle.chain(subgroup.members.map(@oracle.nat))
    let requested = subgroup.members.rev()
    for map_index in subgroup.members {
      requested.push(map_index)
    }
    let actual = prepare(aut_group, @oracle.chain(requested.map(@oracle.nat))).unwrap()
    assert_eq(members(actual), canonical_members)
    assert_eq(degree(actual), @oracle.nat(subgroup.degree))
    assert_true(
      @aut.check_result(ambient, group(actual), @aut.certificate(aut_group)),
    )
    let independent_basis = subgroup.basis.map(fn(value) {
      oracle_element(ambient, value)
    })
    oracle_assert_rank(independent_basis, 2 * base_degree, subgroup.degree)
    let actual_basis = @oracle.array(basis(actual))
    assert_eq(actual_basis.length(), subgroup.degree)
    oracle_assert_rank(actual_basis, 2 * base_degree, subgroup.degree)
    for value in independent_basis {
      oracle_roundtrip(actual, value)
    }
    let expected : Certificate = {
      source: ambient,
      group: @aut.certificate(aut_group),
      members: canonical_members,
      degree: @oracle.nat(subgroup.degree),
      basis: @oracle.chain(independent_basis),
      actions: @oracle.chain(
        subgroup.members.map(fn(map_index) {
          oracle_action_matrix(expected_actions[map_index])
        }),
      ),
      constraints: oracle_constraints(expected_actions, subgroup.members),
      rank: @oracle.nat(2 * base_degree - subgroup.degree),
    }
    let proof = certificate(actual)
    assert_eq(proof.actions, expected.actions)
    assert_eq(proof.constraints, expected.constraints)
    assert_eq(proof.rank, expected.rank)
    assert_true(check(aut_group, proof))
    assert_true(check_result(aut_group, actual, proof))
    assert_true(check(aut_group, expected))
    let imported = from_certificate(aut_group, expected).unwrap()
    assert_true(check_result(aut_group, imported, expected))
    let generator = oracle_element(ambient, subgroup.generator)
    assert_eq(
      @cf.minimal_polynomial(generator).unwrap(),
      oracle_poly(subgroup.minimum),
    )
    oracle_roundtrip(actual, generator)
    assert_eq(
      coordinates(imported, generator).unwrap(),
      oracle_rationals(subgroup.generator_coordinates),
    )
    oracle_roundtrip(imported, generator)
    oracle_roundtrip(actual, @cf.multiply(generator, generator).unwrap())
    oracle_roundtrip(actual, @cf.inverse(generator).unwrap().unwrap())
    for index, sample in sample_values {
      match subgroup.sample_coordinates[index] {
        None => {
          assert_false(contains(actual, sample))
          assert_false(contains(imported, sample))
          assert_true(coordinates(actual, sample) is Err(NotFixed))
        }
        Some(expected_coordinates) => {
          oracle_roundtrip(actual, sample)
          oracle_roundtrip(imported, sample)
          assert_eq(
            coordinates(imported, sample).unwrap(),
            oracle_rationals(expected_coordinates),
          )
        }
      }
    }
    assert_false(check(other_group, expected))
    assert_false(check(aut_group, { ..expected, source: other_ambient, }))
    assert_false(check_result(other_group, actual, proof))
    assert_true(from_certificate(other_group, expected) is Err(_))
    assert_false(contains(actual, @cf.one(other_ambient)))
    assert_true(
      coordinates(actual, @cf.one(other_ambient)) is Err(DifferentField),
    )
  }
}
