///|
fn make_poly(
  n : Int32,
  data : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  let terms = @oracle.chain(
    data.map(fn(t) {
      @poly.Term::{
        coefficient: @oracle.rational(t.0, t.1),
        exponents: @oracle.chain(t.2.map(@oracle.nat)),
      }
    }),
  )
  match @poly.polynomial(@oracle.nat(n), terms) {
    Ok(p) => p
    Err(_) => abort("test polynomial")
  }
}

///|
fn[A] required(result : Result[A, @poly.PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("test polynomial operation")
  }
}

///|
fn complete(n : Int32, generators : @core.Chain[@poly.Polynomial]) -> Basis {
  match required(buchberger(@oracle.nat(n), generators, @oracle.nat(1000))) {
    Complete(basis) => basis
    Paused(_) => abort("small fixture exceeded S-pair budget")
  }
}

///|
test "Buchberger resumes exactly, rejects bad dimensions and handles duplicate zero generators" {
  let f = make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])])
  let g = make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let generators = @oracle.chain([f, g])
  let full = complete(2, generators)
  let mut state = required(start(@oracle.nat(2), generators))
  let initial = state
  assert_eq(required(run(state, @oracle.nat(0))), Paused(initial))
  let mut finished = false
  for _ in 0..<1000 {
    match required(run(state, @oracle.nat(1))) {
      Paused(next) => state = next
      Complete(basis) => {
        assert_eq(basis, full)
        finished = true
        break
      }
    }
  }
  assert_true(finished)
  assert_eq(
    complete(2, @oracle.chain([f, f, @poly.zero(@oracle.nat(2)), g])),
    full,
  )
  assert_eq(start(@oracle.nat(1), generators), Err(@poly.DimensionMismatch))
  let fake : Basis = { variables: @oracle.nat(2), polynomials: generators, }
  assert_eq(verify(fake), Ok(false))
}
