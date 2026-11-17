///|
test "public Amari Chentsov structure matches independent nontrivial finite models" {
  for f in ir_finites() {
    let point = @infogeom.at(ir_family(f), ir_values(f.point)).unwrap()
    let model = @infogeom.local_model(point)
    let value = amari_chentsov(model).unwrap()
    assert_eq(value.metric(), ir_matrix(f.metric, 2), msg=f.name)
    assert_eq(
      @tensor.entries(value.covariant()),
      ir_values(f.cubic),
      msg=f.name,
    )
    assert_eq(ir_q(f.alphas[1].alpha), @oracle.rational(1, 1), msg=f.name)
    assert_eq(ir_q(f.alphas[2].alpha), @oracle.rational(-1, 1), msg=f.name)
    let expected = Array::makei(8, fn(i) {
      @exact.rational_subtract(
        ir_q(f.alphas[2].coefficients[i]),
        ir_q(f.alphas[1].coefficients[i]),
      )
    })
    assert_eq(
      @tensor.entries(value.difference()),
      @oracle.chain(expected),
      msg=f.name,
    )
    assert_eq(
      @infogeom.amari_chentsov(model),
      @infogeom.cubic(model),
      msg=f.name,
    )
  }
}
