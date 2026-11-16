///|
test "prepared four quartic field norms including multiplication matrices" (
  b : @bench.T,
) {
  let (root, proof) = test_normalized(
    [(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)],
    (3, 1),
    (4, 1),
  )
  let field = field_result(root, proof, @oracle.nat(256)).unwrap()
  let values = [[1, 1, -2, 1], [-3, 0, 1, 1], [2, -1, 1, 0], [1, 0, 0, 1]].map(fn(
    cs,
  ) {
    element(field, test_integer_poly(cs)).unwrap()
  })
  b.bench(fn() {
    for value in values {
      b.keep(norm(value).unwrap())
    }
  })
}
