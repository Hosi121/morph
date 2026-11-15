///|
test "Warshall Bool 24 vertices" (b : @bench.T) {
  let n = 24
  let rows = @oracle.chain(
    [
      for i in 0..<n => {
        @oracle.chain([ for j in 0..<n => i == j || (i * 17 + j * 7) % 11 < 2 ])
      }
    ],
  )
  let input = match @matrix.matrix(@oracle.nat(n), rows) {
    Some(m) => m
    None => abort("benchmark shape")
  }
  let ops = @algebra.booleans()
  b.bench(fn() { b.keep(@matrix.warshall(input, ops)) })
}
