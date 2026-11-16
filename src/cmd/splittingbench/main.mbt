///|
/// Only finite input/output scheduling uses machine values.
fn polynomial(constant : Int32) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain([
      @poly.Term::{
        coefficient: @oracle.rational(1, 1),
        exponents: Cons(@oracle.nat(3), Nil),
      },
      @poly.Term::{
        coefficient: @oracle.rational(-constant, 1),
        exponents: Cons(Zero, Nil),
      },
    ]),
  ).unwrap()
}

///|
fn budget() -> @split.Budget {
  {
    algebra: {
      attempts: @oracle.nat(12),
      work: @oracle.nat(3000),
      coordinate: @oracle.nat(1000),
      comparison: @oracle.nat(1000),
      primes: @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      lift: @oracle.nat(100),
      subset: @oracle.nat(500),
      verification: @oracle.nat(500),
      realization: @oracle.nat(1000),
    },
    primitive: @oracle.nat(12),
  }
}

///|
fn finish(state : @split.Search) -> @split.Splitting {
  match @split.advance(state, budget()).unwrap() {
    @split.Ready(value, proof) => {
      if !@split.check_result(
          @split.source(value),
          @split.ambient(value),
          value,
          proof,
        ) {
        abort("source-bound splitting certificate failed")
      }
      value
    }
    @split.Paused(next, _) => finish(next)
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() == 0 {
    abort("mode required")
  }
  let mode = args[args.length() - 1]
  let unity = mode == "cartesian-unity" || mode == "radical-unity"
  let constant = if unity { 1 } else { 2 }
  let source_text = if unity { "z^3-1" } else { "z^3-2" }
  let source = polynomial(constant)
  let state = if mode == "cartesian" || mode == "cartesian-unity" {
    @split.start_cartesian(source).unwrap()
  } else if mode == "radical" || mode == "radical-unity" {
    @split.start(source).unwrap()
  } else {
    abort("unknown mode")
  }
  let value = finish(state)
  let degree = @oracle.int_of_nat(@split.degree(value))
  let ambient = @oracle.int_of_nat(@cf.degree(@split.ambient(value)))
  let count = @oracle.int_of_nat(@core.length(@split.roots(value)))
  if degree != (if unity { 2 } else { 6 }) ||
    ambient != 2 * degree ||
    count != 3 {
    abort("wrong exact splitting degree or root count")
  }
  println(
    "{\"source\":\"\{source_text}\",\"splitting_degree\":\{degree},\"ambient_degree\":\{ambient},\"roots\":\{count},\"checked\":true}",
  )
}
