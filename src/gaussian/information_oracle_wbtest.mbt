///|
test "public lower cumulants match independent Gaussian log partition derivatives" {
  for f in ir_gaussians() {
    let source = gaussian(
      ir_values(f.mean),
      ir_matrix(f.covariance, f.dimension),
    ).unwrap()
    let value = information(source).unwrap()
    assert_eq(value.parent(), source, msg=f.name)
    assert_eq(ir_flat_matrix(value.fisher()), ir_values(f.metric), msg=f.name)
    assert_eq(
      @tensor.entries(value.amari_chentsov()),
      ir_values(f.first),
      msg=f.name,
    )
  }
}
