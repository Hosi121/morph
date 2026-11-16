///|
fn review_native_polynomial_product(
  a : Array[Int32],
  b : Array[Int32],
) -> Array[Int32] {
  let product = Array::make(a.length() + b.length() - 1, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      product[i + j] += a[i] * b[j]
    }
  }
  product
}

///|
test "independent realalgebraic review 144 nonminimal root selections match exact known half-open roots" {
  let first = [0, -2, -1, 1] // x(x+1)(x-2)
  let repeated = review_native_polynomial_product(first, first)
  let second = [-2, -3, 3, 2] // (x+2)(2x+1)(x-1)
  let definitions = [
    first.map(fn(c) { (c, 1) }),
    repeated.map(fn(c) { (c, 1) }),
    second.map(fn(c) { (c, 1) }),
    second.map(fn(c) { (-3 * c, 5) }),
  ]
  let roots = [[-2, 0, 4], [-2, 0, 4], [-4, -1, 2], [-4, -1, 2]]
  let endpoints = [-6, -4, -2, -1, 0, 1, 2, 4, 6]
  let mut checks = 0
  for i in 0..<definitions.length() {
    let polynomial = test_polynomial(definitions[i])
    for li in 0..<endpoints.length() {
      for ui in (li + 1)..<endpoints.length() {
        let lower = endpoints[li]
        let upper = endpoints[ui]
        let selected = roots[i].filter(fn(r) { lower < r && r <= upper })
        let root : RootCertificate = {
          polynomial,
          interval: review_interval(lower, upper),
        }
        if selected.length() == 1 {
          let actual = number(root).unwrap()
          assert_true(check_root(root))
          assert_compared(
            actual,
            rational(@oracle.rational(selected[0], 2)).unwrap(),
            Equal,
            0,
          )
          let refined = refine(actual, @oracle.nat(3)).unwrap()
          let exact = @oracle.rational(selected[0], 2)
          assert_eq(
            @exact.rational_compare(interval(refined).lower, exact),
            Less,
          )
          assert_false(
            @exact.rational_compare(interval(refined).upper, exact) == Less,
          )
        } else {
          assert_true(number(root) is Err(InvalidInterval))
          assert_false(check_root(root))
        }
        checks += 1
      }
    }
  }
  assert_eq(checks, 144)
}
