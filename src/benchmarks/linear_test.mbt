///|
test "exact rational four-by-four inverse including Gauss-Jordan" (b : @bench.T) {
  let rows = [[3, 1, 0, 2], [1, 4, 1, 0], [0, 1, 5, 1], [2, 0, 1, 6]].map(fn(
    row,
  ) {
    @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
  })
  let matrix = @matrix.matrix(@oracle.nat(4), @oracle.chain(rows)).unwrap()
  b.bench(fn() { b.keep(@linear.inverse(matrix)) })
}
