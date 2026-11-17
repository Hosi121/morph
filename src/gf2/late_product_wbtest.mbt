///|
/// Verify the supplied source AND supplied reduction; do not trust embedded claims.
/// This checker performs multiplication and structural RREF checks, no elimination.
fn late_generic_check_certificate(
  input : @matrix.Matrix[Bool],
  result : @rowreduce.Reduction[Bool],
  witness : Certificate,
) -> Bool {
  let height = @matrix.height(input)
  let identity = @matrix.identity(height, scalars())
  witness.source.equal(input) &&
  witness.reduced.equal(result.matrix) &&
  witness.pivots.equal(result.pivots) &&
  result.factor &&
  @matrix.width(witness.reduced).equal(@matrix.width(input)) &&
  @matrix.height(witness.reduced).equal(height) &&
  @matrix.height(witness.transform).equal(height) &&
  @matrix.width(witness.transform).equal(height) &&
  @matrix.height(witness.inverse_transform).equal(height) &&
  @matrix.width(witness.inverse_transform).equal(height) &&
  @matrix.multiply(witness.transform, input, scalars()).equal(
    Some(witness.reduced),
  ) &&
  @matrix.multiply(witness.transform, witness.inverse_transform, scalars()).equal(
    Some(identity),
  ) &&
  @matrix.multiply(witness.inverse_transform, witness.transform, scalars()).equal(
    Some(identity),
  ) &&
  canonical_pivots(witness.reduced).equal(Some(witness.pivots))
}

///|
fn late_product_host(
  a : Array[Array[Bool]],
  b : Array[Array[Bool]],
  width : Int32,
) -> Array[Array[Bool]] {
  a.map(fn(row) {
    Array::makei(width, fn(j) {
      let mut bit = false
      for k in 0..<row.length() {
        bit = bit != (row[k] && b[k][j])
      }
      bit
    })
  })
}

///|
test "late Bool product exhaustive small matrices match host and old generic arithmetic" {
  for height in 0..<=2 {
    for shared in 0..<=2 {
      for width in 0..<=2 {
        for left_bits in 0..<(1 << (height * shared)) {
          let a = Array::makei(height, fn(i) {
            Array::makei(shared, fn(j) {
              (left_bits & (1 << (i * shared + j))) != 0
            })
          })
          for right_bits in 0..<(1 << (shared * width)) {
            let b = Array::makei(shared, fn(i) {
              Array::makei(width, fn(j) {
                (right_bits & (1 << (i * width + j))) != 0
              })
            })
            let left = input(shared, a)
            let right = input(width, b)
            let expected = Some(input(width, late_product_host(a, b, width)))
            assert_eq(multiply(left, right), expected)
            assert_eq(@matrix.multiply(left, right, scalars()), expected)
          }
        }
      }
    }
  }
}

///|
test "late Bool product larger sparse dense zero and dimension failures retain shapes" {
  for
    (height, shared, width) in [
      (0, 7, 5),
      (6, 0, 9),
      (5, 8, 0),
      (7, 11, 13),
      (24, 32, 24),
    ] {
    for seed in 0..<4 {
      let a = Array::makei(height, fn(i) {
        Array::makei(shared, fn(j) {
          seed != 0 &&
          (i * 17 + j * 11 + i * j * 7 + seed) % 13 <
          (if seed == 1 { 2 } else { 7 })
        })
      })
      let b = Array::makei(shared, fn(i) {
        Array::makei(width, fn(j) {
          (i * 13 + j * 19 + i * j * 3 + seed) % 11 < 6
        })
      })
      let left = input(shared, a)
      let right = input(width, b)
      assert_eq(
        multiply(left, right),
        Some(input(width, late_product_host(a, b, width))),
      )
      assert_eq(multiply(left, right), @matrix.multiply(left, right, scalars()))
    }
  }
  for
    (left, right) in [
      (input(2, []), input(3, [])),
      (input(1, [[true]]), input(1, [[true], [false]])),
      (input(2, [[true, false]]), input(0, [])),
    ] {
    assert_eq(multiply(left, right), None)
    assert_eq(@matrix.multiply(left, right, scalars()), None)
  }
}

///|
test "late shared GF2 checker arithmetic matches frozen generic checker on forged witnesses" {
  let source = input(3, [
    [false, true, true],
    [true, true, false],
    [true, true, false],
  ])
  let factor = factor(source).unwrap()
  let result = reduction(factor)
  let proof = certificate(factor).unwrap()
  let identity = input(3, [
    [true, false, false],
    [false, true, false],
    [false, false, true],
  ])
  for
    witness in [
      proof,
      { ..proof, source: identity, },
      { ..proof, reduced: identity, },
      { ..proof, transform: identity, },
      { ..proof, inverse_transform: identity, },
      { ..proof, pivots: @core.Nil, },
      { ..proof, transform: input(0, []), },
    ] {
    assert_eq(
      check_certificate(source, result, witness),
      late_generic_check_certificate(source, result, witness),
    )
  }
  for
    candidate in [
      result,
      { ..result, factor: false, },
      { ..result, pivots: @core.Nil, },
      { ..result, matrix: identity, },
    ] {
    assert_eq(
      check_certificate(source, candidate, proof),
      late_generic_check_certificate(source, candidate, proof),
    )
  }
}
