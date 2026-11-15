///|
test "rational reciprocal product with 128-bit factors" (b : @bench.T) {
  let power = @binary.power(@oracle.binary(2), @oracle.binary(127))
  let denominator = @binary.subtract(power, @binary.one()).unwrap()
  let numerator = @binary.successor(power)
  let a = @exact.ratio(@exact.positive(numerator), denominator).unwrap()
  let reciprocal = @exact.reciprocal(@exact.nonzero(a).unwrap())
  b.bench(fn() { b.keep(@exact.rational_multiply(a, reciprocal)) })
}

///|
test "rational sum with a shared 127-bit denominator" (b : @bench.T) {
  let denominator = @binary.subtract(
    @binary.power(@oracle.binary(2), @oracle.binary(127)),
    @binary.one(),
  ).unwrap()
  let a = @exact.ratio(@oracle.integer(1), denominator).unwrap()
  let c = @exact.ratio(@oracle.integer(2), denominator).unwrap()
  b.bench(fn() { b.keep(@exact.rational_add(a, c)) })
}

///|
test "two-phase simplex rational optimum including tableau initialization" (
  b : @bench.T,
) {
  let rows = [[2, 1], [1, 2], [-1, 0], [0, -1]].map(fn(row) {
    @oracle.chain(row.map(fn(n) { @oracle.rational(n, 1) }))
  })
  let a = @matrix.matrix(@oracle.nat(2), @oracle.chain(rows)).unwrap()
  let bounds = @oracle.chain(
    [4, 4, -1, -1].map(fn(n) { @oracle.rational(n, 1) }),
  )
  let costs = @oracle.chain([1, 1].map(fn(n) { @oracle.rational(n, 1) }))
  let p = @simplex.problem(a, bounds, costs).unwrap()
  let fuel = @oracle.nat(64)
  b.bench(fn() { b.keep(@simplex.run(@simplex.start(p), fuel)) })
}

///|
test "Sturm quintic squarefree sequence and full root isolation" (b : @bench.T) {
  let terms = @oracle.chain([
    @poly.Term::{
      coefficient: @oracle.rational(1, 1),
      exponents: @core.Cons(@oracle.nat(5), Nil),
    },
    @poly.Term::{
      coefficient: @oracle.rational(-1, 1),
      exponents: @core.Cons(@oracle.nat(1), Nil),
    },
    @poly.Term::{
      coefficient: @oracle.rational(-1, 1),
      exponents: @core.Cons(@oracle.nat(0), Nil),
    },
  ])
  let p = @poly.polynomial(@oracle.nat(1), terms).unwrap()
  let fuel = @oracle.nat(128)
  b.bench(fn() {
    let system = @sturm.system(p).unwrap()
    b.keep(@sturm.advance(@sturm.isolate(system), fuel))
  })
}
