///|
fn polynomial(data : Array[(Int32, Array[Int32])]) -> @poly.Polynomial {
  let terms = @oracle.chain(
    data.map(fn(t) {
      @poly.Term::{
        coefficient: @oracle.rational(t.0, 1),
        exponents: @oracle.chain(t.1.map(@oracle.nat)),
      }
    }),
  )
  match @poly.polynomial(@oracle.nat(3), terms) {
    Ok(p) => p
    Err(_) => abort("benchmark polynomial")
  }
}

///|
test "Buchberger separable three-variable quadratics" (b : @bench.T) {
  let generators = @oracle.chain([
    polynomial([(1, [2, 0, 0]), (-1, [0, 0, 0])]),
    polynomial([(1, [0, 2, 0]), (-1, [0, 0, 0])]),
    polynomial([(1, [0, 0, 2]), (-1, [0, 0, 0])]),
  ])
  let variables = @oracle.nat(3)
  let fuel = @oracle.nat(500)
  b.bench(fn() { b.keep(@groebner.buchberger(variables, generators, fuel)) })
}

///|
test "Buchberger coupled three-variable quadratics" (b : @bench.T) {
  let generators = @oracle.chain([
    polynomial([(1, [1, 1, 0]), (-1, [0, 0, 1])]),
    polynomial([(1, [0, 1, 1]), (-1, [1, 0, 0])]),
    polynomial([(1, [1, 0, 1]), (-1, [0, 1, 0])]),
  ])
  let variables = @oracle.nat(3)
  let fuel = @oracle.nat(500)
  b.bench(fn() { b.keep(@groebner.buchberger(variables, generators, fuel)) })
}
