///|
fn ec_field(prime : Int32, modulus : Array[Int32]) -> @gf.Field {
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
fn ec_element(field : @gf.Field, coefficients : Array[Int32]) -> @gf.Element {
  @gf.element(
    field,
    @fppoly.polynomial(
      @gf.prime_field(field),
      @oracle.chain(coefficients.map(@oracle.binary)),
    ),
  ).unwrap()
}

///|
fn ec_native(value : @gf.Element) -> Array[Int32] {
  @oracle.array(@fppoly.coefficients(@gf.representative(value))).map(
    @oracle.int_of_binary,
  )
}

///|
fn ec_expected_point(
  curve : Curve,
  native : (Array[Int32], Array[Int32])?,
) -> Point {
  match native {
    None => infinity(curve)
    Some((x, y)) =>
      point(curve, ec_element(curve.field, x), ec_element(curve.field, y)).unwrap()
  }
}

///|
fn ec_same(actual : Point, expected : Point) -> Unit raise {
  assert_true(equal(actual, expected).unwrap())
  assert_true(check_point(actual))
  assert_eq(coordinates(actual).unwrap(), coordinates(expected).unwrap())
}

///|
test "extension coordinates are checked and Jacobian normalization preserves values" {
  let field = ec_field(5, [2, 0, 1])
  let c = curve(field, @gf.one(field), @gf.one(field)).unwrap()
  let p = ec_expected_point(c, Some(([1, 2], [1, 1])))
  assert_true(check_point(p))
  let unit = infinity(c)
  ec_same(add(unit, p).unwrap(), p)
  ec_same(add(p, unit).unwrap(), p)
  ec_same(add(p, negate(p)).unwrap(), unit)
  ec_same(double(p).unwrap(), add(p, p).unwrap())
  ec_same(scale(p, @oracle.binary(2)).unwrap(), double(p).unwrap())
  ec_same(scale(p, @oracle.binary(0)).unwrap(), unit)
  let z = ec_element(field, [0, 1])
  let zz = @gf.multiply(z, z).unwrap()
  let scaled : Point = {
    curve: c,
    x: @gf.multiply(p.x, zz).unwrap(),
    y: @gf.multiply(p.y, @gf.multiply(zz, z).unwrap()).unwrap(),
    z,
  }
  ec_same(scaled, p)
  ec_same(add(scaled, p).unwrap(), double(p).unwrap())
  ec_same(double(scaled).unwrap(), double(p).unwrap())
  let normalized = normalize(scaled).unwrap()
  assert_true(normalized.z.equal(@gf.one(field)))
  ec_same(normalized, p)
  ec_same(normalize(unit).unwrap(), unit)
}

///|
test "field presentation and curve checks precede identity special cases" {
  let f = ec_field(5, [2, 0, 1])
  let other = ec_field(5, [3, 0, 1])
  let c = curve(f, @gf.one(f), @gf.one(f)).unwrap()
  let d = curve(other, @gf.one(other), @gf.one(other)).unwrap()
  let different = curve(f, @gf.zero(f), @gf.one(f)).unwrap()
  assert_false(same_curve(c, d))
  assert_false(same_curve(c, different))
  assert_true(add(infinity(c), infinity(d)) is Err(DifferentCurve))
  assert_true(equal(infinity(c), infinity(d)) is Err(DifferentCurve))
  assert_true(add(infinity(c), infinity(different)) is Err(DifferentCurve))
  assert_true(point(c, @gf.zero(other), @gf.one(f)) is Err(FieldMismatch))
  assert_true(curve(f, @gf.one(other), @gf.one(f)) is Err(FieldMismatch))
  assert_true(curve(f, @gf.zero(f), @gf.zero(f)) is Err(SingularCurve))
  assert_true(point(c, @gf.zero(f), @gf.zero(f)) is Err(InvalidPoint))
  for prime in [2, 3] {
    let small = ec_field(prime, [0, 1])
    assert_true(
      curve(small, @gf.one(small), @gf.one(small))
      is Err(UnsupportedCharacteristic),
    )
    assert_true(curve(small, @gf.one(f), @gf.one(small)) is Err(FieldMismatch))
  }
  let p = point(c, @gf.zero(f), @gf.one(f)).unwrap()
  assert_false(check_point({ ..p, x: @gf.zero(other), }))
  assert_false(check_point({ ..infinity(c), x: @gf.zero(f), }))
  assert_false(check_point({ ..p, curve: { ..c, b: @gf.zero(f), }, }))
}

///|
test "degree one extension agrees with existing prime affine elliptic group" {
  for prime in [5, 7] {
    let f = ec_field(prime, [0, 1])
    let base = @finitefield.field(@oracle.binary(prime)).unwrap()
    for a in 0..<prime {
      for b in 0..<prime {
        let old_curve = @affine.curve(
          base,
          @oracle.binary(a),
          @oracle.binary(b),
        )
        let c = curve(
          f,
          @gf.constant(f, @oracle.binary(a)),
          @gf.constant(f, @oracle.binary(b)),
        )
        match (c, old_curve) {
          (Err(SingularCurve), None) => ()
          (Ok(c), Some(old_curve)) => {
            let points = [(infinity(c), @affine.infinity(old_curve))]
            for x in 0..<prime {
              for y in 0..<prime {
                let old = @affine.point(
                  old_curve,
                  @oracle.binary(x),
                  @oracle.binary(y),
                )
                let next = point(
                  c,
                  @gf.constant(f, @oracle.binary(x)),
                  @gf.constant(f, @oracle.binary(y)),
                )
                match (next, old) {
                  (Err(InvalidPoint), None) => ()
                  (Ok(next), Some(old)) => points.push((next, old))
                  _ => fail("degree-one point acceptance disagrees")
                }
              }
            }
            for (p, old_p) in points {
              for (q, old_q) in points {
                let actual = coordinates(add(p, q).unwrap()).unwrap()
                let expected = @affine.coordinates(
                  @affine.add(old_p, old_q).unwrap(),
                )
                match (actual, expected) {
                  (AtInfinity, @affine.Infinity) => ()
                  (Affine(x, y), @affine.Affine(u, v)) => {
                    assert_eq(
                      ec_native(x),
                      if @oracle.int_of_binary(u) == 0 {
                        []
                      } else {
                        [@oracle.int_of_binary(u)]
                      },
                    )
                    assert_eq(
                      ec_native(y),
                      if @oracle.int_of_binary(v) == 0 {
                        []
                      } else {
                        [@oracle.int_of_binary(v)]
                      },
                    )
                  }
                  _ => fail("degree-one group addition disagrees")
                }
              }
            }
          }
          _ => fail("degree-one curve acceptance disagrees")
        }
      }
    }
  }
}
