///|
fn pa_field(prime : Int32, modulus : Array[Int32]) -> @gf.Field {
  let base = @primefield.field(@oracle.binary(prime)).unwrap()
  let polynomial = @fppoly.polynomial(
    base,
    @oracle.chain(modulus.map(@oracle.binary)),
  )
  @gf.extension(
    polynomial,
    @fppoly.irreducibility(polynomial).unwrap().unwrap(),
  ).unwrap()
}

///|
fn pa_element(field : @gf.Field, values : Array[Int32]) -> @gf.Element {
  @gf.element(
    field,
    @fppoly.polynomial(
      @gf.prime_field(field),
      @oracle.chain(values.map(@oracle.binary)),
    ),
  ).unwrap()
}

///|
fn pa_curve(field : @gf.Field) -> @ec.Curve {
  @ec.curve(field, @gf.zero(field), @gf.one(field)).unwrap()
}

///|
fn pa_points(
  curve : @ec.Curve,
  data : Array[(Array[Int32], Array[Int32])?],
) -> Array[@ec.Point] {
  data.map(fn(row) {
    match row {
      None => @ec.infinity(curve)
      Some((x, y)) =>
        @ec.point(
          curve,
          pa_element(@ec.field(curve), x),
          pa_element(@ec.field(curve), y),
        ).unwrap()
    }
  })
}

///|
fn pa_from_code(field : @gf.Field, code : Int32) -> @gf.Element {
  let prime = @oracle.int_of_binary(@gf.characteristic(field))
  let degree = @oracle.int_of_nat(@gf.degree(field))
  let digits = []
  let mut remaining = code
  for _ in 0..<degree {
    digits.push(remaining % prime)
    remaining /= prime
  }
  pa_element(field, digits)
}

///|
fn pa_error_code(error : PairingError) -> Int32 {
  match error {
    ZeroEvaluation => -1
    PoleEvaluation => -2
    IndeterminateEvaluation => -3
    EvaluationAtInfinity => -4
    _ => abort("unexpected pairing domain error: \{error.to_repr()}")
  }
}

///|
fn pa_check_miller(
  result : Result[MillerValue, PairingError],
  field : @gf.Field,
  code : Int32,
  expected_point : @ec.Point,
) -> Unit raise {
  match result {
    Err(error) => assert_eq(pa_error_code(error), code)
    Ok(result) => {
      assert_true(code > 0)
      assert_true(@ec.equal(multiple(result), expected_point).unwrap())
      assert_true(@ec.check_point(multiple(result)))
      assert_true(value(result).equal(pa_from_code(field, code)))
      assert_false(@gf.is_zero(value(result)))
    }
  }
}

///|
fn pa_verify_lines(
  prime : Int32,
  modulus : Array[Int32],
  data : Array[(Array[Int32], Array[Int32])?],
  sums : Array[Int32],
  line_codes : Array[Int32],
  miller_codes : Array[Int32],
  multiples : Array[Int32],
  scalar_limit : Int32,
) -> Unit raise {
  let field = pa_field(prime, modulus)
  let curve = pa_curve(field)
  let points = pa_points(curve, data)
  let n = points.length()
  assert_eq(sums.length(), n * n)
  assert_eq(multiples.length(), n * scalar_limit)
  assert_eq(line_codes.length(), n * n * n)
  assert_eq(miller_codes.length(), n * scalar_limit * n)
  for i in 0..<n {
    for j in 0..<n {
      for k in 0..<n {
        pa_check_miller(
          line_quotient(points[i], points[j], points[k]),
          field,
          line_codes[(i * n + j) * n + k],
          points[sums[i * n + j]],
        )
      }
    }
    for scalar in 0..<scalar_limit {
      for k in 0..<n {
        pa_check_miller(
          miller(points[i], @oracle.binary(scalar), points[k]),
          field,
          miller_codes[(i * scalar_limit + scalar) * n + k],
          points[multiples[i * scalar_limit + scalar]],
        )
      }
    }
  }
}

///|
fn pa_verify_tate(
  prime : Int32,
  modulus : Array[Int32],
  data : Array[(Array[Int32], Array[Int32])?],
  sums : Array[Int32],
  n : Int32,
  exponent : Int32,
  torsion : Array[Int32],
  expected_values : Array[Int32],
  shifts : Array[Array[Int32]],
  raw_numerators : Array[Int32],
  raw_denominators : Array[Int32],
  image : Array[Int32],
  error_examples : Array[(Int32, Int32, Int32, Int32)],
) -> Unit raise {
  let field = pa_field(prime, modulus)
  let curve = pa_curve(field)
  let points = pa_points(curve, data)
  let count = points.length()
  let parameters = parameters(curve, @oracle.binary(n)).unwrap()
  assert_eq(
    @oracle.int_of_binary(field_size(parameters)),
    @oracle.int_of_binary(@gf.cardinality(field)),
  )
  assert_eq(@oracle.int_of_binary(final_exponent(parameters)), exponent)
  assert_eq(expected_values.length(), torsion.length() * count)
  assert_eq(shifts.length(), expected_values.length())
  assert_eq(raw_numerators.length(), expected_values.length() * 3)
  assert_eq(raw_denominators.length(), expected_values.length() * 3)
  assert_eq(sums.length(), count * count)
  if n == 2 {
    let canonical = points.map(fn(p) { @ec.coordinates(p).unwrap() })
    let cardinality = @oracle.int_of_binary(@gf.cardinality(field))
    for xcode in 0..<cardinality {
      for ycode in 0..<cardinality {
        let x = pa_from_code(field, xcode)
        let y = pa_from_code(field, ycode)
        let known = canonical.any(fn(value) {
          match value {
            @ec.AtInfinity => false
            @ec.Affine(u, v) => u.equal(x) && v.equal(y)
          }
        })
        match @ec.point(curve, x, y) {
          Ok(p) => {
            assert_true(known)
            assert_true(@ec.check_point(p))
          }
          Err(@ec.InvalidPoint) => assert_false(known)
          Err(_) => fail("unexpected extension point construction error")
        }
      }
    }
  }
  let unit = @gf.one(field)
  let matrix : Array[Array[@gf.Element]] = []
  let mut non_torsion_second_seen = false
  for row in 0..<torsion.length() {
    let pi = torsion[row]
    let values : Array[@gf.Element] = []
    for qi in 0..<count {
      let index = row * count + qi
      let expected = pa_from_code(field, expected_values[index])
      let selected = shifts[index]
      assert_eq(selected.length(), 3)
      let mut checked = unit
      for j in 0..<selected.length() {
        let shift = points[selected[j]]
        let result = reduced_tate(parameters, points[pi], points[qi], shift).unwrap()
        assert_true(result.equal(expected))
        checked = result
        assert_true(@gf.power(result, @oracle.binary(n)).unwrap().equal(unit))
        let top_code = raw_numerators[index * 3 + j]
        let bottom_code = raw_denominators[index * 3 + j]
        if top_code == 0 || bottom_code == 0 {
          assert_eq(top_code, 0)
          assert_eq(bottom_code, 0)
          assert_true(pi == 0 || qi == 0)
          assert_true(result.equal(unit))
        } else {
          let translated = @ec.add(points[qi], shift).unwrap()
          let top = miller(points[pi], @oracle.binary(n), translated).unwrap()
          let bottom = miller(points[pi], @oracle.binary(n), shift).unwrap()
          assert_true(value(top).equal(pa_from_code(field, top_code)))
          assert_true(value(bottom).equal(pa_from_code(field, bottom_code)))
          assert_true(@ec.is_infinity(multiple(top)))
          assert_true(@ec.is_infinity(multiple(bottom)))
          let quotient = @gf.divide(value(top), value(bottom)).unwrap()
          assert_true(
            @gf.power(quotient, @oracle.binary(exponent))
            .unwrap()
            .equal(expected),
          )
        }
        if !@ec.is_infinity(@ec.scale(points[qi], @oracle.binary(n)).unwrap()) &&
          !result.equal(unit) {
          non_torsion_second_seen = true
        }
      }
      values.push(checked)
    }
    matrix.push(values)
  }
  if n == 2 || n == 3 {
    assert_true(non_torsion_second_seen)
  }
  assert_eq(torsion.length() * image.length(), count)
  for i in 0..<count {
    let expected = torsion.any(fn(index) { index == i })
    assert_eq(
      @ec.is_infinity(@ec.scale(points[i], @oracle.binary(n)).unwrap()),
      expected,
    )
  }
  let actual_image = points.map(fn(p) {
    @ec.scale(p, @oracle.binary(n)).unwrap()
  })
  for i in 0..<count {
    let expected = image.any(fn(index) { index == i })
    let actual = actual_image.any(fn(p) { @ec.equal(p, points[i]).unwrap() })
    assert_eq(actual, expected)
    let in_right_kernel = matrix.all(fn(row) { row[i].equal(unit) })
    assert_eq(in_right_kernel, expected)
  }
  for i in 0..<torsion.length() {
    assert_eq(matrix[i].all(fn(x) { x.equal(unit) }), torsion[i] == 0)
    for qi in 0..<count {
      for image_index in image {
        assert_true(
          matrix[i][sums[qi * count + image_index]].equal(matrix[i][qi]),
        )
      }
      for qj in 0..<count {
        let product = @gf.multiply(matrix[i][qi], matrix[i][qj]).unwrap()
        assert_true(product.equal(matrix[i][sums[qi * count + qj]]))
      }
    }
    for j in 0..<torsion.length() {
      let sum = sums[torsion[i] * count + torsion[j]]
      let target = pa_index(torsion, sum)
      for qi in 0..<count {
        assert_true(
          @gf.multiply(matrix[i][qi], matrix[j][qi])
          .unwrap()
          .equal(matrix[target][qi]),
        )
      }
    }
  }
  for (pi, qi, si, code) in error_examples {
    match reduced_tate(parameters, points[pi], points[qi], points[si]) {
      Ok(_) => fail("expected explicit partial evaluation error")
      Err(error) => assert_eq(pa_error_code(error), code)
    }
  }
}

///|
fn pa_index(values : Array[Int32], target : Int32) -> Int32 {
  for i in 0..<values.length() {
    if values[i] == target {
      return i
    }
  }
  abort("host torsion table is not closed")
}

///|
fn pa_verify_large(
  prime : Int32,
  modulus : Array[Int32],
  data : Array[(Array[Int32], Array[Int32])?],
  code : Int32,
) -> Unit raise {
  let field = pa_field(prime, modulus)
  let curve = pa_curve(field)
  let points = pa_points(curve, data)
  let scalar = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(200)),
    @oracle.binary(17),
  )
  pa_check_miller(miller(points[0], scalar, points[1]), field, code, points[2])
  assert_true(
    @ec.equal(@ec.scale(points[0], scalar).unwrap(), points[2]).unwrap(),
  )
}
