///|
fn integer_matrix() -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(3),
    @oracle.chain([
      @oracle.chain([12, 6, 4].map(@oracle.integer)),
      @oracle.chain([3, 9, 6].map(@oracle.integer)),
      @oracle.chain([2, 16, 14].map(@oracle.integer)),
    ]),
  ).unwrap()
}

///|
test "Smith three square generation and independent checker exact baseline" (
  b : @bench.T,
) {
  let machine = @smith.start(integer_matrix())
  let fuel = @oracle.nat(2000)
  b.bench(fn() { b.keep(@smith.run(machine, fuel)) })
}

///|
test "Smith three square independent checker exact baseline" (b : @bench.T) {
  let input = integer_matrix()
  let form = match @smith.run(@smith.start(input), @oracle.nat(2000)) {
    Done(form) => form
    _ => abort("fixed Smith benchmark must finish")
  }
  b.bench(fn() {
    b.keep(
      @smith.check(
        input,
        @smith.left(form),
        @smith.diagonal(form),
        @smith.right(form),
      ),
    )
  })
}

///|
test "simplex two phase optimum exact baseline" (b : @bench.T) {
  let a = @matrix.matrix(
    @oracle.nat(2),
    @oracle.chain([
      @oracle.chain([2, 1].map(fn(x) { @oracle.rational(x, 1) })),
      @oracle.chain([1, 2].map(fn(x) { @oracle.rational(x, 1) })),
      @oracle.chain([-1, 0].map(fn(x) { @oracle.rational(x, 1) })),
      @oracle.chain([0, -1].map(fn(x) { @oracle.rational(x, 1) })),
    ]),
  ).unwrap()
  let bounds = @oracle.chain(
    [4, 4, -1, -1].map(fn(x) { @oracle.rational(x, 1) }),
  )
  let costs = @oracle.chain([1, 1].map(fn(x) { @oracle.rational(x, 1) }))
  let problem = @simplex.problem(a, bounds, costs).unwrap()
  let fuel = @oracle.nat(64)
  b.bench(fn() { b.keep(@simplex.run(@simplex.start(problem), fuel)) })
}
