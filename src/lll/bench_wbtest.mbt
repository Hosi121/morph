///|
fn reduce_input(
  input : @matrix.Matrix[@exact.Integer],
  fuel : @core.Nat,
) -> Status? {
  match start(input) {
    Some(machine) => Some(run(machine, fuel))
    None => None
  }
}

///|
test "exact LLL three square including rank validation and final checker" (
  b : @bench.T,
) {
  let input = imat(3, [[1, 1, 1], [-1, 0, 2], [3, 5, 6]])
  let fuel = @oracle.nat(2000)
  b.bench(fn() { b.keep(reduce_input(input, fuel)) })
}

///|
test "exact LLL three square independent checker only" (b : @bench.T) {
  let input = imat(3, [[1, 1, 1], [-1, 0, 2], [3, 5, 6]])
  let result = completed(input)
  b.bench(fn() { b.keep(check(input, transform(result), basis(result))) })
}

///|
test "exact LLL three by four including rank validation and final checker" (
  b : @bench.T,
) {
  let input = imat(4, [[1, 1, 1, 1], [1, 0, 2, 3], [5, 3, 1, 2]])
  let fuel = @oracle.nat(2000)
  b.bench(fn() { b.keep(reduce_input(input, fuel)) })
}

///|
test "Smith then exact LLL dependent three by four including both certificate checks" (
  b : @bench.T,
) {
  let input = imat(4, [[2, 0, 0, 2], [0, 3, 3, 0], [2, 3, 3, 2]])
  b.bench(fn() { b.keep(arbitrary(input)) })
}
