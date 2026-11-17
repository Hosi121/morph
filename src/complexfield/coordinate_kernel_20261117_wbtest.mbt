///|
test "shared coordinate scan preserves the fixed complex basis and exact roundtrip" {
  let fields = [
    cf_real_field([0, 1], (-1, 1), (0, 1)),
    cf_real_field([-2, 0, 1], (1, 1), (2, 1)),
    cf_real_field([1, 0, -10, 0, 1], (3, 1), (4, 1)),
  ]
  for k in fields {
    let f = field(k)
    let d = @oracle.int_of_nat(@nf.degree(k))
    for sparse in [true, false] {
      let aa = [
        for i in 0..<d => {
          if sparse && i != d - 1 {
            (0, 1)
          } else {
            (i - 2, i + 2)
          }
        }
      ]
      let bb = [
        for i in 0..<d => if sparse && i != 0 { (0, 1) } else { (2 - i, i + 3) }
      ]
      let a = @nf.element(k, cf_poly(aa)).unwrap()
      let b = @nf.element(k, cf_poly(bb)).unwrap()
      let z = element(f, a, b).unwrap()
      let expected = @core.append(
        @oracle.chain(aa.map(fn(pair) { cf_rational(pair.0, pair.1) })),
        @oracle.chain(bb.map(fn(pair) { cf_rational(pair.0, pair.1) })),
      )
      assert_eq(coordinates(z), expected)
      assert_true(equal(from_coordinates(f, expected).unwrap(), z))
    }
    assert_eq(
      coordinates(zero(f)),
      @core.replicate(degree(f), cf_rational(0, 1)),
    )
    assert_true(from_coordinates(f, Nil) is Err(DimensionMismatch))
  }
}
