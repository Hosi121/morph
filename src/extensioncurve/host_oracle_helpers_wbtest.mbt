///|
fn ec_elements(field : @gf.Field) -> Array[@gf.Element] {
  let prime = @oracle.int_of_binary(@gf.characteristic(field))
  let degree = @oracle.int_of_nat(@gf.degree(field))
  let q = @oracle.int_of_binary(@gf.cardinality(field))
  let values = []
  for index in 0..<q {
    let digits = []
    let mut remaining = index
    for _ in 0..<degree {
      digits.push(remaining % prime)
      remaining /= prime
    }
    values.push(ec_element(field, digits))
  }
  values
}

///|
fn ec_verify_case(
  prime : Int32,
  modulus : Array[Int32],
  coefficient_a : Array[Int32],
  coefficient_b : Array[Int32],
  native_points : Array[(Array[Int32], Array[Int32])?],
  table : Array[Int32],
  orders : Array[Int32],
  large_index : Int32,
  large_expected : Int32,
  associativity : Bool,
) -> Unit raise {
  let field = ec_field(prime, modulus)
  let c = curve(
    field,
    ec_element(field, coefficient_a),
    ec_element(field, coefficient_b),
  ).unwrap()
  let points = native_points.map(fn(data) { ec_expected_point(c, data) })
  let n = points.length()
  assert_eq(table.length(), n * n)
  assert_eq(orders.length(), n)
  let expected_coordinates = points.map(fn(p) { coordinates(p).unwrap() })
  let elements = ec_elements(field)
  for x in elements {
    for y in elements {
      let expected = points.any(fn(p) {
        !is_infinity(p) && p.x.equal(x) && p.y.equal(y)
      })
      match point(c, x, y) {
        Ok(p) => {
          assert_true(expected)
          assert_true(check_point(p))
        }
        Err(InvalidPoint) => assert_false(expected)
        Err(_) => fail("host oracle point acceptance error")
      }
    }
  }
  let sums = []
  for i in 0..<n {
    let row = []
    for j in 0..<n {
      let result = add(points[i], points[j]).unwrap()
      assert_true(check_point(result))
      assert_eq(
        coordinates(result).unwrap(),
        expected_coordinates[table[i * n + j]],
      )
      row.push(result)
    }
    sums.push(row)
  }
  for i in 0..<n {
    assert_true(is_infinity(add(points[i], negate(points[i])).unwrap()))
    assert_true(
      is_infinity(scale(points[i], @oracle.binary(orders[i])).unwrap()),
    )
    ec_same(double(points[i]).unwrap(), sums[i][i])
    let mut expected = 0
    for scalar in 0..<(2 * n + 1) {
      let actual = scale(points[i], @oracle.binary(scalar)).unwrap()
      assert_true(equal(actual, points[expected]).unwrap())
      expected = table[expected * n + i]
    }
  }
  if associativity {
    for i in 0..<n {
      for j in 0..<n {
        for k in 0..<n {
          let left = add(sums[i][j], points[k]).unwrap()
          let right = add(points[i], sums[j][k]).unwrap()
          let expected = points[table[table[i * n + j] * n + k]]
          assert_true(equal(left, right).unwrap())
          assert_true(equal(left, expected).unwrap())
          assert_true(check_point(left))
        }
      }
    }
  }
  let large = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(200)),
    @oracle.binary(17),
  )
  ec_same(scale(points[large_index], large).unwrap(), points[large_expected])
}

///|
fn ec_verify_singularity(expected : Array[Bool]) -> Unit raise {
  let field = ec_field(5, [2, 0, 1])
  let values = ec_elements(field)
  assert_eq(expected.length(), values.length() * values.length())
  for i in 0..<values.length() {
    for j in 0..<values.length() {
      match curve(field, values[i], values[j]) {
        Ok(_) => assert_false(expected[i * values.length() + j])
        Err(SingularCurve) => assert_true(expected[i * values.length() + j])
        Err(_) => fail("host discriminant oracle unexpected error")
      }
    }
  }
}
