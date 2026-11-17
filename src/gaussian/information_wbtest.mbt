///|
test "information reuses second and third cumulants without fourth order products" {
  let source = checked_gaussian(
    @oracle.chain([q(1, 2), q(-1, 3)]),
    matrix(
      @oracle.chain([
        @oracle.chain([q(2, 1), q(1, 2)]),
        @oracle.chain([q(1, 2), q(1, 1)]),
      ]),
      2,
    ),
  )
  let info = information(source).unwrap()
  let jet = fisher_jet(source).unwrap()
  assert_eq(info.fisher(), @riemann.metric(jet))
  assert_eq(info.parent(), source)
  let first = @oracle.array(@riemann.first_derivatives(jet))
  for i in 0..<5 {
    for j in 0..<5 {
      for k in 0..<5 {
        assert_eq(
          @tensor.at(
            info.amari_chentsov(),
            @oracle.chain([i, j, k].map(@oracle.nat)),
          ),
          Ok(entry(first[k], @oracle.nat(i), @oracle.nat(j))),
        )
      }
    }
  }
  let (_, _, state) = prepare_information(source).unwrap()
  for pair in @oracle.array(@avl.entries(state.products)) {
    assert_true(@oracle.int_of_nat(@core.length(pair.0)) <= 3)
  }
  for pair in @oracle.array(@avl.entries(state.moments.cache)) {
    let degree = @oracle.array(pair.0).fold(init=0, fn(sum, power) {
      sum + @oracle.int_of_nat(power)
    })
    assert_true(degree <= 6)
  }
}
