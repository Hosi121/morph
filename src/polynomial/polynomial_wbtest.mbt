///|
fn poly(n : Int32, terms : Array[(Int32, Array[Int32])]) -> Polynomial {
  let data = @oracle.chain(
    terms.map(fn(term) {
      Term::{
        coefficient: @oracle.rational(term.0, 1),
        exponents: @oracle.chain(term.1.map(@oracle.nat)),
      }
    }),
  )
  match polynomial(@oracle.nat(n), data) {
    Ok(p) => p
    Err(_) => abort("test polynomial")
  }
}

///|
fn[A] required(result : Result[A, PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("test operation")
  }
}

///|
fn int_power(base : Int32, exponent : Int32) -> Int32 {
  for i = 0, acc = 1; i < exponent; {
    continue i + 1, acc * base
  } nobreak {
    acc
  }
}

///|
test "canonical sparse arithmetic, lex division, derivatives and rational evaluation" {
  let f = poly(2, [(1, [2, 0]), (1, [0, 1])])
  let g = poly(2, [(1, [1, 0]), (-1, [0, 1])])
  let divided = required(divide(f, @core.Cons(g, Nil)))
  assert_eq(
    divided.quotients,
    @oracle.chain([poly(2, [(1, [1, 0]), (1, [0, 1])])]),
  )
  assert_eq(divided.remainder, poly(2, [(1, [0, 2]), (1, [0, 1])]))
  assert_eq(
    required(
      add(
        required(multiply(@oracle.array(divided.quotients)[0], g)),
        divided.remainder,
      ),
    ),
    f,
  )
  assert_eq(derivative(f, @oracle.nat(0)), Some(poly(2, [(2, [1, 0])])))
  assert_eq(derivative(f, @oracle.nat(1)), Some(poly(2, [(1, [0, 0])])))
  assert_eq(
    evaluate(f, @oracle.chain([@oracle.rational(1, 2), @oracle.rational(1, 3)])),
    Some(@oracle.rational(7, 12)),
  )
  assert_eq(
    poly(1, [(1, [2]), (-1, [2]), (0, [1]), (3, [0])]),
    poly(1, [(3, [0])]),
  )
  assert_eq(required(subtract(f, f)), zero(@oracle.nat(2)))
  assert_eq(divide(f, @oracle.chain([zero(@oracle.nat(2))])), Err(ZeroDivisor))
  assert_eq(add(f, poly(1, [])), Err(DimensionMismatch))
}

///|
test "polynomial gcd is monic and preserves shared factors" {
  let shared = poly(1, [(1, [1]), (-1, [0])])
  let a = required(multiply(shared, poly(1, [(2, [1]), (4, [0])])))
  let b = required(multiply(shared, poly(1, [(3, [1]), (9, [0])])))
  assert_eq(univariate_gcd(a, b), Ok(shared))
  assert_eq(
    univariate_gcd(zero(@oracle.nat(1)), zero(@oracle.nat(1))),
    Ok(zero(@oracle.nat(1))),
  )
  assert_eq(univariate_gcd(poly(2, []), poly(2, [])), Err(DimensionMismatch))
}

///|
test "division certificates and derivative evaluations on generated bivariate polynomials" {
  let g = poly(2, [(1, [1, 0]), (-1, [0, 1])])
  for family in 0..<24 {
    let data = [
      for i in 0..<8 => {
        ((family * 3 + i * 7) % 5 - 2, [(i + family) % 4, (i * 3 + family) % 4])
      }
    ]
    let f = poly(2, data)
    let divided = required(divide(f, @core.Cons(g, Nil)))
    assert_eq(
      required(
        add(
          required(multiply(@oracle.array(divided.quotients)[0], g)),
          divided.remainder,
        ),
      ),
      f,
    )
    for term in @oracle.array(divided.remainder.terms) {
      assert_eq(@oracle.int_of_nat(@oracle.array(term.exponents)[0]), 0)
    }
    for x in -2..<=2 {
      for y in -2..<=2 {
        let mut expected = 0
        for (c, powers) in data {
          if powers[0] > 0 {
            expected += c *
              powers[0] *
              int_power(x, powers[0] - 1) *
              int_power(y, powers[1])
          }
        }
        assert_eq(
          evaluate(
            derivative(f, @oracle.nat(0)).unwrap(),
            @oracle.chain([@oracle.rational(x, 1), @oracle.rational(y, 1)]),
          ),
          Some(@oracle.rational(expected, 1)),
        )
      }
    }
  }
}
