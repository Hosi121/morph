///|
fn mask_bits(width : Int32, mask : Int32) -> @core.Chain[Bool] {
  @oracle.chain(Array::makei(width, fn(i) { (mask & (1 << i)) != 0 }))
}

///|
fn bit_mask(vector : @core.Chain[Bool]) -> Int32 {
  let mut value = 0
  for i, bit in @oracle.array(vector) {
    if bit {
      value = value | (1 << i)
    }
  }
  value
}

///|
fn combine_classes(
  basis : Array[@core.Chain[Bool]],
  mask : Int32,
  width : Int32,
) -> @core.Chain[Bool] {
  let mut value = mask_bits(width, 0)
  for i, vector in basis {
    if (mask & (1 << i)) != 0 {
      value = xor_vectors(value, vector)
    }
  }
  value
}

///|
fn tensor_product(
  tensor : Array[Array[Int32]],
  left : Int32,
  right : Int32,
) -> Int32 {
  let mut value = 0
  for entry in tensor {
    if ((left >> entry[0]) & (right >> entry[1]) & 1) != 0 {
      value = value ^ (1 << entry[2])
    }
  }
  value
}

///|
fn verify_oracle_fixture(
  facets : Array[Array[Int32]],
  widths : Array[Int32],
  boundaries : Array[Array[Int32]],
  oracle_representatives : Array[Array[Int32]],
  cycles : Array[Array[Array[Int32]]],
  tensors : Array[Array[Array[Array[Int32]]]],
  products : Array[Array[Int32]],
  exhaustive : Bool,
) -> Unit raise {
  let source = complex(facets)
  let ring = compute_ring(source).unwrap()
  let actual = ring_result(ring)
  assert_true(check_ring(source, actual, ring_certificate(ring)))
  let spaces = widths.mapi(fn(d, _) { compute(source, @oracle.nat(d)).unwrap() })
  let basis_coordinates = spaces.mapi(fn(d, space) {
    oracle_representatives[d].map(fn(vector) {
      coordinates(space, mask_bits(widths[d], vector)).unwrap()
    })
  })
  for d, space in spaces {
    let group = result(space)
    assert_eq(
      @oracle.int_of_nat(group.rank),
      oracle_representatives[d].length(),
    )
    assert_true(check_result(source, @oracle.nat(d), group, certificate(space)))
    for vector in @oracle.array(group.coboundaries) {
      assert_true(boundaries[d].contains(bit_mask(vector)))
    }
    for vector in @oracle.array(group.representatives) {
      assert_true(cycles[d].any(fn(entry) { entry[0] == bit_mask(vector) }))
      assert_false(boundaries[d].contains(bit_mask(vector)))
    }
    for entry in cycles[d] {
      let vector = mask_bits(widths[d], entry[0])
      let value = coordinates(space, vector).unwrap()
      assert_eq(
        value,
        combine_classes(
          basis_coordinates[d],
          entry[1],
          oracle_representatives[d].length(),
        ),
      )
      assert_eq(
        equivalent(space, vector, representative(space, value).unwrap()),
        Some(true),
      )
      assert_eq(zero_vector(value), boundaries[d].contains(entry[0]))
    }
    if exhaustive {
      for vector in 0..<(1 << widths[d]) {
        let value = coordinates(space, mask_bits(widths[d], vector))
        assert_eq(
          value is Some(_),
          cycles[d].any(fn(entry) { entry[0] == vector }),
        )
      }
    }
  }
  for product in products {
    let (p, i, q, j, expected) = (
      product[0],
      product[1],
      product[2],
      product[3],
      product[4],
    )
    let value = multiply(
      ring,
      @oracle.nat(p),
      basis_coordinates[p][i],
      @oracle.nat(q),
      basis_coordinates[q][j],
    ).unwrap()
    if p + q < spaces.length() {
      assert_eq(
        value,
        combine_classes(
          basis_coordinates[p + q],
          expected,
          oracle_representatives[p + q].length(),
        ),
      )
    } else {
      assert_true(zero_vector(value))
    }
  }
  for p in 0..<widths.length() {
    for q in 0..<widths.length() {
      let output_width = if p + q < widths.length() { widths[p + q] } else { 0 }
      if exhaustive {
        // Every cochain pair, including noncocycles, is checked against the
        // independent Python face-join tensor on all four-vertex complexes.
        for a in 0..<(1 << widths[p]) {
          for b in 0..<(1 << widths[q]) {
            let product = cup(
              source,
              @oracle.nat(p),
              mask_bits(widths[p], a),
              @oracle.nat(q),
              mask_bits(widths[q], b),
            ).unwrap()
            assert_eq(
              product,
              mask_bits(output_width, tensor_product(tensors[p][q], a, b)),
            )
          }
        }
        for a in cycles[p] {
          for b in cycles[q] {
            let product = cup(
              source,
              @oracle.nat(p),
              mask_bits(widths[p], a[0]),
              @oracle.nat(q),
              mask_bits(widths[q], b[0]),
            ).unwrap()
            let class_product = multiply(
              ring,
              @oracle.nat(p),
              coordinates(spaces[p], mask_bits(widths[p], a[0])).unwrap(),
              @oracle.nat(q),
              coordinates(spaces[q], mask_bits(widths[q], b[0])).unwrap(),
            ).unwrap()
            if p + q < spaces.length() {
              assert_eq(
                coordinates(spaces[p + q], product),
                Some(class_product),
              )
            } else {
              assert_eq(product, Nil)
            }
          }
        }
      }
      // Bilinear Leibniz identity on every pair of elementary cochains.
      for i in 0..<widths[p] {
        for j in 0..<widths[q] {
          let a = mask_bits(widths[p], 1 << i)
          let b = mask_bits(widths[q], 1 << j)
          let product = cup(source, @oracle.nat(p), a, @oracle.nat(q), b).unwrap()
          let derivative = apply_matrix(
            coboundary(source, @oracle.nat(p + q)).unwrap(),
            product,
          ).unwrap()
          let da = apply_matrix(coboundary(source, @oracle.nat(p)).unwrap(), a).unwrap()
          let db = apply_matrix(coboundary(source, @oracle.nat(q)).unwrap(), b).unwrap()
          let first = cup(source, @oracle.nat(p + 1), da, @oracle.nat(q), b).unwrap()
          let second = cup(source, @oracle.nat(p), a, @oracle.nat(q + 1), db).unwrap()
          assert_eq(derivative, xor_vectors(first, second))
        }
      }
    }
  }
}

///|
test "cup is not strictly commutative on cochains and malformed shapes fail" {
  let source = complex([[0, 1, 2]])
  let a = mask_bits(3, 1)
  let b = mask_bits(3, 4)
  assert_eq(
    cup(source, @oracle.nat(1), a, @oracle.nat(1), b),
    Some(mask_bits(1, 1)),
  )
  assert_eq(
    cup(source, @oracle.nat(1), b, @oracle.nat(1), a),
    Some(mask_bits(1, 0)),
  )
  assert_eq(
    cup(source, @oracle.nat(1), mask_bits(2, 0), @oracle.nat(1), b),
    None,
  )
  let degree = compute(source, @oracle.nat(1)).unwrap()
  let target = compute(source, @oracle.nat(2)).unwrap()
  assert_eq(cup_product(degree, a, degree, b, target), None)
}

///|
test "actual cup witnesses bind both cocycles classes source and result" {
  let source = complex([[0, 1], [1, 2], [0, 2]])
  let zero = compute(source, @oracle.nat(0)).unwrap()
  let one = compute(source, @oracle.nat(1)).unwrap()
  let unit = mask_bits(3, 7)
  let cycle = representative(one, mask_bits(1, 1)).unwrap()
  let good = cup_product(zero, unit, one, cycle, one).unwrap()
  let actual = good.result
  assert_true(check_product(zero, unit, one, cycle, one, actual, good))
  assert_false(
    check_product(zero, mask_bits(3, 0), one, cycle, one, actual, good),
  )
  assert_false(check_product(zero, unit, one, cycle, zero, actual, good))
  assert_false(
    check_product(
      zero,
      unit,
      one,
      cycle,
      one,
      { ..actual, value: mask_bits(1, 0), },
      good,
    ),
  )
  assert_false(
    check_product(zero, unit, one, cycle, one, actual, {
      ..good,
      left_degree: @oracle.nat(1),
    }),
  )
  assert_false(
    check_product(zero, unit, one, cycle, one, actual, {
      ..good,
      source: complex([[0, 1]]),
    }),
  )
  assert_false(
    check_product(zero, unit, one, cycle, one, actual, {
      ..good,
      result: { ..actual, cochain: mask_bits(3, 0), },
    }),
  )
  for
    forged in [
      { ..actual, value: mask_bits(1, 0), },
      { ..actual, cochain: mask_bits(3, 0), },
      { ..actual, left_class: mask_bits(1, 0), },
      { ..actual, right_class: mask_bits(1, 0), },
    ] {
    assert_false(
      check_product(zero, unit, one, cycle, one, forged, {
        ..good,
        result: forged,
      }),
    )
  }
  let boundary = @core.nth(result(one).coboundaries, @oracle.nat(0)).unwrap()
  assert_true(
    check_representative_independence(
      zero,
      unit,
      unit,
      one,
      cycle,
      xor_vectors(cycle, boundary),
      one,
    ),
  )
  assert_false(
    check_representative_independence(
      zero,
      unit,
      mask_bits(3, 0),
      one,
      cycle,
      cycle,
      one,
    ),
  )
}

///|
test "torus and wedge share integer homology but cup rings distinguish them" {
  let torus = complex([
    [0, 1, 2],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 6],
    [0, 1, 5],
    [1, 5, 6],
    [2, 3, 5],
    [2, 4, 5],
    [2, 3, 6],
    [0, 2, 6],
    [0, 3, 4],
    [0, 3, 5],
    [4, 5, 6],
    [0, 4, 6],
  ])
  let wedge = complex([
    [0, 1],
    [1, 2],
    [0, 2],
    [0, 3],
    [3, 4],
    [0, 4],
    [0, 5, 6],
    [0, 5, 7],
    [0, 6, 7],
    [5, 6, 7],
  ])
  let rings = [compute_ring(torus).unwrap(), compute_ring(wedge).unwrap()]
  for index, source in [torus, wedge] {
    let ring = rings[index]
    assert_eq(
      @oracle.array(ring_result(ring).groups).map(fn(group) {
        @oracle.int_of_nat(group.rank)
      }),
      [1, 2, 1],
    )
    for d, rank in [1, 2, 1] {
      match @homology.compute(source, @oracle.nat(d), @oracle.nat(2000)) {
        Computed(witness) => {
          assert_eq(witness.result.free_rank, @oracle.nat(rank))
          assert_eq(witness.result.torsion, Nil)
          assert_true(
            @homology.check_result(
              source,
              @oracle.nat(d),
              witness.result,
              witness,
            ),
          )
        }
        _ =>
          abort("focused integer-homology fixture exceeded its finite budget")
      }
    }
    let a = mask_bits(2, 1)
    let b = mask_bits(2, 2)
    assert_eq(
      multiply(ring, @oracle.nat(1), a, @oracle.nat(1), a),
      Some(mask_bits(1, 0)),
    )
    assert_eq(
      multiply(ring, @oracle.nat(1), b, @oracle.nat(1), b),
      Some(mask_bits(1, 0)),
    )
    assert_eq(
      multiply(ring, @oracle.nat(1), a, @oracle.nat(1), b),
      Some(mask_bits(1, if index == 0 { 1 } else { 0 })),
    )
    assert_eq(
      multiply(ring, @oracle.nat(1), b, @oracle.nat(1), a),
      Some(mask_bits(1, if index == 0 { 1 } else { 0 })),
    )
  }
}

///|
test "projective plane square and disconnected degree zero units are exact" {
  let plane = complex([
    [0, 1, 2],
    [0, 2, 3],
    [0, 1, 5],
    [0, 4, 5],
    [0, 3, 4],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 5],
    [2, 3, 5],
    [2, 4, 5],
  ])
  let ring = compute_ring(plane).unwrap()
  assert_eq(
    @oracle.array(ring_result(ring).groups).map(fn(group) {
      @oracle.int_of_nat(group.rank)
    }),
    [1, 1, 1],
  )
  assert_eq(
    multiply(
      ring,
      @oracle.nat(1),
      mask_bits(1, 1),
      @oracle.nat(1),
      mask_bits(1, 1),
    ),
    Some(mask_bits(1, 1)),
  )
  let disconnected = compute_ring(complex([[0], [1]])).unwrap()
  assert_eq(ring_result(disconnected).unit, mask_bits(2, 3))
  assert_eq(
    multiply(
      disconnected,
      @oracle.nat(0),
      mask_bits(2, 1),
      @oracle.nat(0),
      mask_bits(2, 1),
    ),
    Some(mask_bits(2, 1)),
  )
  assert_eq(
    multiply(
      disconnected,
      @oracle.nat(0),
      mask_bits(2, 1),
      @oracle.nat(0),
      mask_bits(2, 2),
    ),
    Some(mask_bits(2, 0)),
  )
  let empty = compute_ring(complex([])).unwrap()
  assert_eq(ring_result(empty).unit, Nil)
  assert_eq(ring_result(empty).table, Nil)
  assert_eq(
    multiply(empty, @oracle.nat(0), Nil, @oracle.nat(0), Nil),
    Some(Nil),
  )
}

///|
test "ring certificates reject missing duplicate reordered or forged table entries" {
  let source = complex([[0, 1], [1, 2], [0, 2]])
  let ring = compute_ring(source).unwrap()
  let good = ring_certificate(ring)
  let actual = ring_result(ring)
  let entries = @oracle.array(actual.table)
  let first = entries[0]
  for
    bad_table in [
      @core.drop(@oracle.nat(1), actual.table),
      @core.Cons(first, actual.table),
      @core.reverse(actual.table),
      @core.Cons(
        { ..first, value: mask_bits(1, 0), },
        @core.drop(@oracle.nat(1), actual.table),
      ),
    ] {
    let bad = { ..actual, table: bad_table, }
    assert_false(check_ring(source, bad, { ..good, result: bad, }))
  }
  let bad_unit = { ..actual, unit: mask_bits(1, 0), }
  assert_false(check_ring(source, bad_unit, { ..good, result: bad_unit, }))
  assert_false(
    check_ring(source, actual, { ..good, degrees: @core.reverse(good.degrees), }),
  )
  assert_false(
    check_ring(source, actual, {
      ..good,
      degrees: @core.drop(@oracle.nat(1), good.degrees),
    }),
  )
  assert_false(check_ring(complex([[0, 1]]), actual, good))
  assert_eq(
    multiply(ring, @oracle.nat(1), mask_bits(2, 0), @oracle.nat(0), actual.unit),
    None,
  )
}
