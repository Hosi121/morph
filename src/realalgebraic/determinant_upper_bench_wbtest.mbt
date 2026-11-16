///|
fn determinant_client_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<coefficients.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficients[i], 1),
            exponents: @core.Cons(@oracle.nat(i), @core.Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn bench_resultant_client(b : @bench.T, higher : Bool) -> Unit {
  let p = determinant_client_poly(
    if higher {
      [1, 0, -10, 0, 1]
    } else {
      [-2, 0, 1]
    },
  )
  let q = determinant_client_poly([-3, 0, 1])
  let state = resultant_start(p, q, if higher { Product } else { Sum }).unwrap()
  let fuel = @oracle.nat(64)
  b.bench(fn() {
    match resultant_advance(state, fuel).unwrap() {
      ResultantReady(proof) => {
        guard check_resultant(proof) else {
          abort("resultant benchmark proof failed")
        }
        b.keep(proof)
      }
      _ => abort("resultant benchmark budget exhausted")
    }
  })
}

///|
test "prepared degree two sum resultant including certificate check" (
  b : @bench.T,
) {
  bench_resultant_client(b, false)
}

///|
test "prepared degree four by two product resultant including certificate check" (
  b : @bench.T,
) {
  bench_resultant_client(b, true)
}
