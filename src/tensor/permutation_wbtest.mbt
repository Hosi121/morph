///|
test "higher-rank rectangular permutations match complete independent index loops" {
  let shapes = [
    [2, 3, 4],
    [2, 1, 3, 2],
    [2, 1, 2, 3, 2],
    [1, 1, 1, 1, 1],
    [2, 1, 0, 3, 2],
  ]
  let mut checked = 0
  for dimensions in shapes {
    let value = numbered(dimensions)
    for order in permutations(dimensions.length()) {
      let (wanted_shape, wanted_entries) = host_permute(
        dimensions,
        host_entries(value),
        order,
      )
      let actual = permute(value, nat_list(order)).unwrap()
      assert_eq(host_shape(actual), wanted_shape)
      assert_eq(host_entries(actual), wanted_entries)
      checked += 1
    }
  }
  assert_eq(checked, 390)
}

///|
test "permutation index retains non-Eq entries across rectangular axes" {
  let dimensions = [2, 3, 1]
  let functions = Array::makei(6, fn(i) { fn() { i - 3 } })
  let value = from_flat(nat_list(dimensions), @oracle.chain(functions)).unwrap()
  for order in permutations(dimensions.length()) {
    let actual = permute(value, nat_list(order)).unwrap()
    let (wanted_shape, wanted_entries) = host_permute(
      dimensions,
      Array::makei(6, fn(i) { i - 3 }),
      order,
    )
    assert_eq(host_shape(actual), wanted_shape)
    assert_eq(@oracle.array(entries(actual)).map(fn(f) { f() }), wanted_entries)
  }
}
