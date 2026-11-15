///|
test "Smith three square transformation and independent checker" (b : @bench.T) {
  let input = imat(3, [[12, 6, 4], [3, 9, 6], [2, 16, 14]])
  let machine = start(input)
  let fuel = @oracle.nat(2000)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}

///|
test "Smith three square independent checker only" (b : @bench.T) {
  let input = imat(3, [[12, 6, 4], [3, 9, 6], [2, 16, 14]])
  let form = completed(input)
  b.bench(fn() { b.keep(check(input, left(form), diagonal(form), right(form))) })
}

///|
test "Smith four square transformation and independent checker" (b : @bench.T) {
  let input = imat(4, [
    [6, 12, 0, 4],
    [3, 9, 6, 2],
    [2, 16, 14, 8],
    [4, 0, 10, 12],
  ])
  let machine = start(input)
  let fuel = @oracle.nat(2000)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}
