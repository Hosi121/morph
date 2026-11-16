///|
struct OracleValue {
  real : Array[(Int32, Int32)]
  imaginary : Array[(Int32, Int32)]
}

///|
struct OracleSampleImages {
  left : OracleValue
  right : OracleValue
  sum : OracleValue
  product : OracleValue
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
    _ => abort("split automorphism oracle needs a verified real minimum")
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
fn oracle_assert_group_fixture(
  base_degree : Int32,
  constant : Int32,
  expected_roots : Array[OracleValue],
  expected_table : Array[Array[Int32]],
  expected_identity : Int32,
  expected_conjugation : Int32,
  expected_inverses : Array[Int32],
  expected_actions : Array[Array[Int32]],
  sample_left : OracleValue,
  sample_right : OracleValue,
  expected_sample_images : Array[OracleSampleImages],
) -> Unit raise {
  let field = oracle_context(base_degree, constant)
  let root_values = expected_roots.map(fn(value) {
    oracle_element(field, value)
  })
  let root_chain = @oracle.chain(root_values)
  let group = prepare(field, root_chain).unwrap()
  let maps = @oracle.array(automorphisms(group))
  let image_pairs : Array[Image] = []
  for root in root_values {
    image_pairs.push({ real: root, imaginary: @cf.imaginary_unit(field), })
    image_pairs.push({
      real: root,
      imaginary: @cf.negate(@cf.imaginary_unit(field)),
    })
  }
  let expected : Certificate = {
    source: field,
    roots: root_chain,
    images: @oracle.chain(image_pairs),
    table: @oracle.chain(
      expected_table.map(fn(row) { @oracle.chain(row.map(@oracle.nat)) }),
    ),
    identity: @oracle.nat(expected_identity),
    conjugation: @oracle.nat(expected_conjugation),
    inverses: @oracle.chain(expected_inverses.map(@oracle.nat)),
  }
  assert_true(@cf.same_field(source(group), field))
  assert_eq(order(group), @oracle.nat(2 * base_degree))
  assert_eq(maps.length(), 2 * base_degree)
  assert_eq(composition_table(group), expected.table)
  assert_true(equal(identity(group), maps[expected_identity]))
  assert_true(equal(conjugation(group), maps[expected_conjugation]))
  assert_true(check(field, expected))
  assert_true(check(field, certificate(group)))
  assert_true(check_result(field, group, expected))
  let imported = from_certificate(field, expected).unwrap()
  assert_true(check_result(field, imported, certificate(group)))
  let actual_roots = @oracle.array(roots(group))
  assert_eq(actual_roots.length(), root_values.length())
  for index, root in actual_roots {
    assert_true(@cf.equal(root, root_values[index]))
  }
  let left = oracle_element(field, sample_left)
  let right = oracle_element(field, sample_right)
  let sum = @cf.add(left, right).unwrap()
  let product = @cf.multiply(left, right).unwrap()
  for index, mapping in maps {
    assert_true(@cf.equal(real_image(mapping), image_pairs[index].real))
    assert_true(
      @cf.equal(imaginary_image(mapping), image_pairs[index].imaginary),
    )
    assert_true(
      equal(inverse(group, mapping).unwrap(), maps[expected_inverses[index]]),
    )
    for root_index, root in root_values {
      assert_true(
        @cf.equal(
          apply(mapping, root).unwrap(),
          root_values[expected_actions[index][root_index]],
        ),
      )
    }
    let expected_images = expected_sample_images[index]
    let actual_left = apply(mapping, left).unwrap()
    let actual_right = apply(mapping, right).unwrap()
    assert_true(
      @cf.equal(actual_left, oracle_element(field, expected_images.left)),
    )
    assert_true(
      @cf.equal(actual_right, oracle_element(field, expected_images.right)),
    )
    let expected_sum = oracle_element(field, expected_images.sum)
    let expected_product = oracle_element(field, expected_images.product)
    assert_true(@cf.equal(apply(mapping, sum).unwrap(), expected_sum))
    assert_true(
      @cf.equal(@cf.add(actual_left, actual_right).unwrap(), expected_sum),
    )
    assert_true(@cf.equal(apply(mapping, product).unwrap(), expected_product))
    assert_true(
      @cf.equal(
        @cf.multiply(actual_left, actual_right).unwrap(),
        expected_product,
      ),
    )
    for right_index, right_mapping in maps {
      assert_true(
        equal(
          compose(group, mapping, right_mapping).unwrap(),
          maps[expected_table[index][right_index]],
        ),
      )
    }
  }
  let other_field = oracle_context(2, 3)
  assert_false(check(other_field, expected))
  assert_false(check(field, { ..expected, source: other_field, }))
  assert_false(check_result(other_field, group, expected))
  assert_true(from_certificate(other_field, expected) is Err(_))
  assert_true(apply(maps[0], @cf.one(other_field)) is Err(_))
}
