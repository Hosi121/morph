///|
fn benchmark_problem(kind : Int32) -> Problem {
  if kind == 0 {
    prepare(
      Conjunction(
        Atom(poly([-2, 0, 1]), EqualZero),
        Atom(poly([0, 1]), GreaterZero),
      ),
    ).unwrap()
  } else if kind == 1 {
    let mut p = poly([1])
    for root in 1..<=8 {
      p = @polynomial.multiply(p, poly([-root, 1])).unwrap()
    }
    prepare(Atom(p, GreaterZero)).unwrap()
  } else {
    let p = @polynomial.polynomial(
      @oracle.nat(1),
      @oracle.chain([
        @polynomial.Term::{
          coefficient: @oracle.rational(1, 1),
          exponents: Cons(@oracle.nat(2), Nil),
        },
        @polynomial.Term::{
          coefficient: @oracle.rational(-1, 1024),
          exponents: Cons(@oracle.nat(1), Nil),
        },
      ]),
    ).unwrap()
    prepare(Atom(p, LessZero)).unwrap()
  }
}

///|
fn benchmark_query(b : @bench.T, kind : Int32) -> Unit {
  let problem = benchmark_problem(kind)
  let budget = @oracle.nat(4096)
  b.bench(fn() {
    match run(start(problem), budget) {
      Complete(value) => {
        b.keep(value)
        b.keep(check(problem, certificate(value)))
      }
      _ => abort("benchmark query did not finish")
    }
  })
}

///|
test "prepared realcad sqrt two including certificate check" (b : @bench.T) {
  benchmark_query(b, 0)
}

///|
test "prepared realcad eight dense roots including certificate check" (
  b : @bench.T,
) {
  benchmark_query(b, 1)
}

///|
test "prepared realcad close roots including certificate check" (b : @bench.T) {
  benchmark_query(b, 2)
}
