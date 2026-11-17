// Independent Python Fraction full convolution, including normalized unit constructors.

///|
fn unit_fixture(
  n : Int32,
  data : Array[(Int32, Int32, Array[Int32])],
) -> Polynomial {
  polynomial(
    @oracle.nat(n),
    @oracle.chain(
      data.map(fn(t) {
        Term::{
          coefficient: @oracle.rational(t.0, t.1),
          exponents: @oracle.chain(t.2.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn unit_generic_oracle(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match @core.compare(a.variables, b.variables) {
    Equal =>
      Ok({
        variables: a.variables,
        terms: balanced_product_terms(a.terms, b.terms),
      })
    _ => Err(DimensionMismatch)
  }
}

///|
fn unit_sequential_oracle(
  a : Polynomial,
  b : Polynomial,
) -> Result[Polynomial, PolyError] {
  match @core.compare(a.variables, b.variables) {
    Equal =>
      Ok({
        variables: a.variables,
        terms: @core.fold_left(a.terms, Nil, fn(found, term) {
          merge_terms(found, term_times(term, b.terms))
        }),
      })
    _ => Err(DimensionMismatch)
  }
}

///|
test "unit sharing independent Fraction fixture 0" {
  let a = unit_fixture(0, [(-1, 1, [])])

  let b = unit_fixture(0, [(0, 1, []), (-1, 3, []), (1, 3, [])])

  let expected = unit_fixture(0, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 1" {
  let a = unit_fixture(0, [(-1, 1, [])])

  let b = unit_fixture(0, [(0, 1, []), (-1, 3, []), (1, 3, []), (-2, 1, [])])

  let expected = unit_fixture(0, [(2, 1, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 2" {
  let a = unit_fixture(0, [(-1, 1, [])])

  let b = unit_fixture(0, [
    (0, 1, []),
    (-1, 3, []),
    (1, 3, []),
    (-1, 3, []),
    (-2, 2, []),
    (2, 1, []),
    (1, 3, []),
    (0, 2, []),
    (-1, 1, []),
    (-2, 3, []),
    (2, 2, []),
    (1, 1, []),
    (0, 3, []),
    (-1, 2, []),
    (-2, 1, []),
  ])

  let expected = unit_fixture(0, [(7, 6, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 3" {
  let a = unit_fixture(0, [(-2, 2, []), (5, 3, []), (-5, 3, [])])

  let b = unit_fixture(0, [(2, 3, [])])

  let expected = unit_fixture(0, [(-2, 3, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 4" {
  let a = unit_fixture(0, [(1, 1, [])])

  let b = unit_fixture(0, [(0, 1, []), (-1, 3, []), (1, 3, [])])

  let expected = unit_fixture(0, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 5" {
  let a = unit_fixture(0, [(1, 1, [])])

  let b = unit_fixture(0, [(0, 1, []), (-1, 3, []), (1, 3, []), (-2, 1, [])])

  let expected = unit_fixture(0, [(-2, 1, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 6" {
  let a = unit_fixture(0, [(1, 1, [])])

  let b = unit_fixture(0, [
    (0, 1, []),
    (-1, 3, []),
    (1, 3, []),
    (-1, 3, []),
    (-2, 2, []),
    (2, 1, []),
    (1, 3, []),
    (0, 2, []),
    (-1, 1, []),
    (-2, 3, []),
    (2, 2, []),
    (1, 1, []),
    (0, 3, []),
    (-1, 2, []),
    (-2, 1, []),
  ])

  let expected = unit_fixture(0, [(-7, 6, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 7" {
  let a = unit_fixture(0, [(2, 2, []), (5, 3, []), (-5, 3, [])])

  let b = unit_fixture(0, [(2, 3, [])])

  let expected = unit_fixture(0, [(2, 3, [])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 8" {
  let a = unit_fixture(1, [(-1, 1, [0])])

  let b = unit_fixture(1, [(0, 1, [0]), (-1, 3, [0]), (1, 3, [0])])

  let expected = unit_fixture(1, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 9" {
  let a = unit_fixture(1, [(-1, 1, [0])])

  let b = unit_fixture(1, [(0, 1, [0]), (-1, 3, [0]), (1, 3, [0]), (-2, 1, [0])])

  let expected = unit_fixture(1, [(2, 1, [0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 10" {
  let a = unit_fixture(1, [(-1, 1, [0])])

  let b = unit_fixture(1, [
    (0, 1, [0]),
    (-1, 3, [0]),
    (1, 3, [0]),
    (-1, 3, [1]),
    (-2, 2, [0]),
    (2, 1, [4]),
    (1, 3, [3]),
    (0, 2, [2]),
    (-1, 1, [1]),
    (-2, 3, [0]),
    (2, 2, [4]),
    (1, 1, [3]),
    (0, 3, [2]),
    (-1, 2, [1]),
    (-2, 1, [0]),
  ])

  let expected = unit_fixture(1, [
    (-3, 1, [4]),
    (-4, 3, [3]),
    (11, 6, [1]),
    (11, 3, [0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 11" {
  let a = unit_fixture(1, [(-2, 2, [0]), (5, 3, [0]), (-5, 3, [0])])

  let b = unit_fixture(1, [(2, 3, [0])])

  let expected = unit_fixture(1, [(-2, 3, [0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 12" {
  let a = unit_fixture(1, [(1, 1, [0])])

  let b = unit_fixture(1, [(0, 1, [0]), (-1, 3, [0]), (1, 3, [0])])

  let expected = unit_fixture(1, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 13" {
  let a = unit_fixture(1, [(1, 1, [0])])

  let b = unit_fixture(1, [(0, 1, [0]), (-1, 3, [0]), (1, 3, [0]), (-2, 1, [0])])

  let expected = unit_fixture(1, [(-2, 1, [0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 14" {
  let a = unit_fixture(1, [(1, 1, [0])])

  let b = unit_fixture(1, [
    (0, 1, [0]),
    (-1, 3, [0]),
    (1, 3, [0]),
    (-1, 3, [1]),
    (-2, 2, [0]),
    (2, 1, [4]),
    (1, 3, [3]),
    (0, 2, [2]),
    (-1, 1, [1]),
    (-2, 3, [0]),
    (2, 2, [4]),
    (1, 1, [3]),
    (0, 3, [2]),
    (-1, 2, [1]),
    (-2, 1, [0]),
  ])

  let expected = unit_fixture(1, [
    (3, 1, [4]),
    (4, 3, [3]),
    (-11, 6, [1]),
    (-11, 3, [0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 15" {
  let a = unit_fixture(1, [(2, 2, [0]), (5, 3, [0]), (-5, 3, [0])])

  let b = unit_fixture(1, [(2, 3, [0])])

  let expected = unit_fixture(1, [(2, 3, [0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 16" {
  let a = unit_fixture(2, [(-1, 1, [0, 0])])

  let b = unit_fixture(2, [(0, 1, [0, 0]), (-1, 3, [0, 0]), (1, 3, [0, 0])])

  let expected = unit_fixture(2, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 17" {
  let a = unit_fixture(2, [(-1, 1, [0, 0])])

  let b = unit_fixture(2, [
    (0, 1, [0, 0]),
    (-1, 3, [0, 0]),
    (1, 3, [0, 0]),
    (-2, 1, [0, 1]),
  ])

  let expected = unit_fixture(2, [(2, 1, [0, 1])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 18" {
  let a = unit_fixture(2, [(-1, 1, [0, 0])])

  let b = unit_fixture(2, [
    (0, 1, [0, 0]),
    (-1, 3, [0, 0]),
    (1, 3, [0, 0]),
    (-1, 3, [1, 3]),
    (-2, 2, [0, 1]),
    (2, 1, [4, 4]),
    (1, 3, [3, 2]),
    (0, 2, [2, 0]),
    (-1, 1, [1, 3]),
    (-2, 3, [0, 1]),
    (2, 2, [4, 4]),
    (1, 1, [3, 2]),
    (0, 3, [2, 0]),
    (-1, 2, [1, 3]),
    (-2, 1, [0, 1]),
  ])

  let expected = unit_fixture(2, [
    (-3, 1, [4, 4]),
    (-4, 3, [3, 2]),
    (11, 6, [1, 3]),
    (11, 3, [0, 1]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 19" {
  let a = unit_fixture(2, [(-2, 2, [0, 0]), (5, 3, [0, 0]), (-5, 3, [0, 0])])

  let b = unit_fixture(2, [(2, 3, [0, 0])])

  let expected = unit_fixture(2, [(-2, 3, [0, 0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 20" {
  let a = unit_fixture(2, [(1, 1, [0, 0])])

  let b = unit_fixture(2, [(0, 1, [0, 0]), (-1, 3, [0, 0]), (1, 3, [0, 0])])

  let expected = unit_fixture(2, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 21" {
  let a = unit_fixture(2, [(1, 1, [0, 0])])

  let b = unit_fixture(2, [
    (0, 1, [0, 0]),
    (-1, 3, [0, 0]),
    (1, 3, [0, 0]),
    (-2, 1, [0, 1]),
  ])

  let expected = unit_fixture(2, [(-2, 1, [0, 1])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 22" {
  let a = unit_fixture(2, [(1, 1, [0, 0])])

  let b = unit_fixture(2, [
    (0, 1, [0, 0]),
    (-1, 3, [0, 0]),
    (1, 3, [0, 0]),
    (-1, 3, [1, 3]),
    (-2, 2, [0, 1]),
    (2, 1, [4, 4]),
    (1, 3, [3, 2]),
    (0, 2, [2, 0]),
    (-1, 1, [1, 3]),
    (-2, 3, [0, 1]),
    (2, 2, [4, 4]),
    (1, 1, [3, 2]),
    (0, 3, [2, 0]),
    (-1, 2, [1, 3]),
    (-2, 1, [0, 1]),
  ])

  let expected = unit_fixture(2, [
    (3, 1, [4, 4]),
    (4, 3, [3, 2]),
    (-11, 6, [1, 3]),
    (-11, 3, [0, 1]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 23" {
  let a = unit_fixture(2, [(2, 2, [0, 0]), (5, 3, [0, 0]), (-5, 3, [0, 0])])

  let b = unit_fixture(2, [(2, 3, [0, 0])])

  let expected = unit_fixture(2, [(2, 3, [0, 0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 24" {
  let a = unit_fixture(3, [(-1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
  ])

  let expected = unit_fixture(3, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 25" {
  let a = unit_fixture(3, [(-1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
    (-2, 1, [0, 1, 2]),
  ])

  let expected = unit_fixture(3, [(2, 1, [0, 1, 2])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 26" {
  let a = unit_fixture(3, [(-1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
    (-1, 3, [1, 3, 0]),
    (-2, 2, [0, 1, 2]),
    (2, 1, [4, 4, 4]),
    (1, 3, [3, 2, 1]),
    (0, 2, [2, 0, 3]),
    (-1, 1, [1, 3, 0]),
    (-2, 3, [0, 1, 2]),
    (2, 2, [4, 4, 4]),
    (1, 1, [3, 2, 1]),
    (0, 3, [2, 0, 3]),
    (-1, 2, [1, 3, 0]),
    (-2, 1, [0, 1, 2]),
  ])

  let expected = unit_fixture(3, [
    (-3, 1, [4, 4, 4]),
    (-4, 3, [3, 2, 1]),
    (11, 6, [1, 3, 0]),
    (11, 3, [0, 1, 2]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 27" {
  let a = unit_fixture(3, [
    (-2, 2, [0, 0, 0]),
    (5, 3, [0, 0, 0]),
    (-5, 3, [0, 0, 0]),
  ])

  let b = unit_fixture(3, [(2, 3, [0, 0, 0])])

  let expected = unit_fixture(3, [(-2, 3, [0, 0, 0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 28" {
  let a = unit_fixture(3, [(1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
  ])

  let expected = unit_fixture(3, [])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 29" {
  let a = unit_fixture(3, [(1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
    (-2, 1, [0, 1, 2]),
  ])

  let expected = unit_fixture(3, [(-2, 1, [0, 1, 2])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 30" {
  let a = unit_fixture(3, [(1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (0, 1, [0, 0, 0]),
    (-1, 3, [0, 0, 0]),
    (1, 3, [0, 0, 0]),
    (-1, 3, [1, 3, 0]),
    (-2, 2, [0, 1, 2]),
    (2, 1, [4, 4, 4]),
    (1, 3, [3, 2, 1]),
    (0, 2, [2, 0, 3]),
    (-1, 1, [1, 3, 0]),
    (-2, 3, [0, 1, 2]),
    (2, 2, [4, 4, 4]),
    (1, 1, [3, 2, 1]),
    (0, 3, [2, 0, 3]),
    (-1, 2, [1, 3, 0]),
    (-2, 1, [0, 1, 2]),
  ])

  let expected = unit_fixture(3, [
    (3, 1, [4, 4, 4]),
    (4, 3, [3, 2, 1]),
    (-11, 6, [1, 3, 0]),
    (-11, 3, [0, 1, 2]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 31" {
  let a = unit_fixture(3, [
    (2, 2, [0, 0, 0]),
    (5, 3, [0, 0, 0]),
    (-5, 3, [0, 0, 0]),
  ])

  let b = unit_fixture(3, [(2, 3, [0, 0, 0])])

  let expected = unit_fixture(3, [(2, 3, [0, 0, 0])])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 32" {
  let a = unit_fixture(3, [(1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (-2, 1, [0, 0, 0]),
    (-1, 2, [1, 1, 3]),
    (0, 3, [2, 2, 1]),
    (1, 1, [3, 3, 4]),
    (2, 2, [4, 0, 2]),
    (-2, 3, [5, 1, 0]),
    (-1, 1, [6, 2, 3]),
    (0, 2, [7, 3, 1]),
    (1, 3, [8, 0, 4]),
    (2, 1, [9, 1, 2]),
    (-2, 2, [10, 2, 0]),
    (-1, 3, [11, 3, 3]),
    (0, 1, [12, 0, 1]),
    (1, 2, [13, 1, 4]),
    (2, 3, [14, 2, 2]),
    (-2, 1, [15, 3, 0]),
    (-1, 2, [16, 0, 3]),
    (0, 3, [17, 1, 1]),
    (1, 1, [18, 2, 4]),
    (2, 2, [19, 3, 2]),
    (-2, 3, [20, 0, 0]),
    (-1, 1, [21, 1, 3]),
    (0, 2, [22, 2, 1]),
    (1, 3, [23, 3, 4]),
    (2, 1, [24, 0, 2]),
    (-2, 2, [25, 1, 0]),
    (-1, 3, [26, 2, 3]),
    (0, 1, [27, 3, 1]),
  ])

  let expected = unit_fixture(3, [
    (-1, 3, [26, 2, 3]),
    (-1, 1, [25, 1, 0]),
    (2, 1, [24, 0, 2]),
    (1, 3, [23, 3, 4]),
    (-1, 1, [21, 1, 3]),
    (-2, 3, [20, 0, 0]),
    (1, 1, [19, 3, 2]),
    (1, 1, [18, 2, 4]),
    (-1, 2, [16, 0, 3]),
    (-2, 1, [15, 3, 0]),
    (2, 3, [14, 2, 2]),
    (1, 2, [13, 1, 4]),
    (-1, 3, [11, 3, 3]),
    (-1, 1, [10, 2, 0]),
    (2, 1, [9, 1, 2]),
    (1, 3, [8, 0, 4]),
    (-1, 1, [6, 2, 3]),
    (-2, 3, [5, 1, 0]),
    (1, 1, [4, 0, 2]),
    (1, 1, [3, 3, 4]),
    (-1, 2, [1, 1, 3]),
    (-2, 1, [0, 0, 0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 33" {
  let a = unit_fixture(3, [(-1, 1, [0, 0, 0])])

  let b = unit_fixture(3, [
    (-2, 1, [0, 0, 0]),
    (-1, 2, [1, 1, 3]),
    (0, 3, [2, 2, 1]),
    (1, 1, [3, 3, 4]),
    (2, 2, [4, 0, 2]),
    (-2, 3, [5, 1, 0]),
    (-1, 1, [6, 2, 3]),
    (0, 2, [7, 3, 1]),
    (1, 3, [8, 0, 4]),
    (2, 1, [9, 1, 2]),
    (-2, 2, [10, 2, 0]),
    (-1, 3, [11, 3, 3]),
    (0, 1, [12, 0, 1]),
    (1, 2, [13, 1, 4]),
    (2, 3, [14, 2, 2]),
    (-2, 1, [15, 3, 0]),
    (-1, 2, [16, 0, 3]),
    (0, 3, [17, 1, 1]),
    (1, 1, [18, 2, 4]),
    (2, 2, [19, 3, 2]),
    (-2, 3, [20, 0, 0]),
    (-1, 1, [21, 1, 3]),
    (0, 2, [22, 2, 1]),
    (1, 3, [23, 3, 4]),
    (2, 1, [24, 0, 2]),
    (-2, 2, [25, 1, 0]),
    (-1, 3, [26, 2, 3]),
    (0, 1, [27, 3, 1]),
  ])

  let expected = unit_fixture(3, [
    (1, 3, [26, 2, 3]),
    (1, 1, [25, 1, 0]),
    (-2, 1, [24, 0, 2]),
    (-1, 3, [23, 3, 4]),
    (1, 1, [21, 1, 3]),
    (2, 3, [20, 0, 0]),
    (-1, 1, [19, 3, 2]),
    (-1, 1, [18, 2, 4]),
    (1, 2, [16, 0, 3]),
    (2, 1, [15, 3, 0]),
    (-2, 3, [14, 2, 2]),
    (-1, 2, [13, 1, 4]),
    (1, 3, [11, 3, 3]),
    (1, 1, [10, 2, 0]),
    (-2, 1, [9, 1, 2]),
    (-1, 3, [8, 0, 4]),
    (1, 1, [6, 2, 3]),
    (2, 3, [5, 1, 0]),
    (-1, 1, [4, 0, 2]),
    (-1, 1, [3, 3, 4]),
    (1, 2, [1, 1, 3]),
    (2, 1, [0, 0, 0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 34" {
  let a = unit_fixture(3, [(2, 3, [0, 0, 0])])

  let b = unit_fixture(3, [
    (-2, 1, [0, 0, 0]),
    (-1, 2, [1, 1, 3]),
    (0, 3, [2, 2, 1]),
    (1, 1, [3, 3, 4]),
    (2, 2, [4, 0, 2]),
    (-2, 3, [5, 1, 0]),
    (-1, 1, [6, 2, 3]),
    (0, 2, [7, 3, 1]),
    (1, 3, [8, 0, 4]),
    (2, 1, [9, 1, 2]),
    (-2, 2, [10, 2, 0]),
    (-1, 3, [11, 3, 3]),
    (0, 1, [12, 0, 1]),
    (1, 2, [13, 1, 4]),
    (2, 3, [14, 2, 2]),
    (-2, 1, [15, 3, 0]),
    (-1, 2, [16, 0, 3]),
    (0, 3, [17, 1, 1]),
    (1, 1, [18, 2, 4]),
    (2, 2, [19, 3, 2]),
    (-2, 3, [20, 0, 0]),
    (-1, 1, [21, 1, 3]),
    (0, 2, [22, 2, 1]),
    (1, 3, [23, 3, 4]),
    (2, 1, [24, 0, 2]),
    (-2, 2, [25, 1, 0]),
    (-1, 3, [26, 2, 3]),
    (0, 1, [27, 3, 1]),
  ])

  let expected = unit_fixture(3, [
    (-2, 9, [26, 2, 3]),
    (-2, 3, [25, 1, 0]),
    (4, 3, [24, 0, 2]),
    (2, 9, [23, 3, 4]),
    (-2, 3, [21, 1, 3]),
    (-4, 9, [20, 0, 0]),
    (2, 3, [19, 3, 2]),
    (2, 3, [18, 2, 4]),
    (-1, 3, [16, 0, 3]),
    (-4, 3, [15, 3, 0]),
    (4, 9, [14, 2, 2]),
    (1, 3, [13, 1, 4]),
    (-2, 9, [11, 3, 3]),
    (-2, 3, [10, 2, 0]),
    (4, 3, [9, 1, 2]),
    (2, 9, [8, 0, 4]),
    (-2, 3, [6, 2, 3]),
    (-4, 9, [5, 1, 0]),
    (2, 3, [4, 0, 2]),
    (2, 3, [3, 3, 4]),
    (-1, 3, [1, 1, 3]),
    (-4, 3, [0, 0, 0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 35" {
  let a = unit_fixture(2, [
    (-2, 1, [0, 0]),
    (-1, 1, [1, 0]),
    (0, 1, [2, 0]),
    (1, 1, [3, 0]),
    (2, 1, [4, 0]),
    (-2, 1, [5, 0]),
    (-1, 1, [0, 1]),
    (0, 1, [1, 1]),
    (1, 1, [2, 1]),
    (2, 1, [3, 1]),
    (-2, 1, [4, 1]),
    (-1, 1, [5, 1]),
    (0, 1, [0, 2]),
    (1, 1, [1, 2]),
    (2, 1, [2, 2]),
    (-2, 1, [3, 2]),
    (-1, 1, [4, 2]),
    (0, 1, [5, 2]),
    (1, 1, [0, 3]),
    (2, 1, [1, 3]),
    (-2, 1, [2, 3]),
    (-1, 1, [3, 3]),
    (0, 1, [4, 3]),
    (1, 1, [5, 3]),
  ])

  let b = unit_fixture(2, [
    (-3, 1, [0, 0]),
    (-2, 1, [1, 0]),
    (-1, 1, [2, 0]),
    (0, 1, [3, 0]),
    (1, 1, [4, 0]),
    (2, 1, [5, 0]),
    (3, 1, [0, 1]),
    (-3, 1, [1, 1]),
    (-2, 1, [2, 1]),
    (-1, 1, [3, 1]),
    (0, 1, [4, 1]),
    (1, 1, [5, 1]),
    (2, 1, [0, 2]),
    (3, 1, [1, 2]),
    (-3, 1, [2, 2]),
    (-2, 1, [3, 2]),
    (-1, 1, [4, 2]),
    (0, 1, [5, 2]),
  ])

  let expected = unit_fixture(2, [
    (1, 1, [10, 4]),
    (2, 1, [10, 3]),
    (-1, 1, [10, 2]),
    (-4, 1, [10, 1]),
    (-4, 1, [10, 0]),
    (-1, 1, [9, 5]),
    (1, 1, [9, 3]),
    (-2, 1, [9, 2]),
    (-3, 1, [9, 1]),
    (2, 1, [9, 0]),
    (-2, 1, [8, 5]),
    (-1, 1, [8, 4]),
    (5, 1, [8, 1]),
    (4, 1, [8, 0]),
    (-2, 1, [7, 5]),
    (2, 1, [7, 3]),
    (8, 1, [7, 2]),
    (7, 1, [7, 1]),
    (3, 1, [7, 0]),
    (7, 1, [6, 5]),
    (5, 1, [6, 4]),
    (3, 1, [6, 3]),
    (-4, 1, [6, 2]),
    (5, 1, [6, 1]),
    (7, 1, [5, 5]),
    (6, 1, [5, 4]),
    (-9, 1, [5, 3]),
    (2, 1, [5, 2]),
    (-13, 1, [5, 1]),
    (-4, 1, [5, 0]),
    (-2, 1, [4, 5]),
    (-11, 1, [4, 4]),
    (3, 1, [4, 3]),
    (2, 1, [4, 2]),
    (4, 1, [4, 1]),
    (-10, 1, [4, 0]),
    (-16, 1, [3, 5]),
    (-3, 1, [3, 4]),
    (14, 1, [3, 2]),
    (-1, 1, [3, 1]),
    (-2, 1, [3, 0]),
    (-1, 1, [2, 5]),
    (-7, 1, [2, 4]),
    (9, 1, [2, 3]),
    (5, 1, [2, 1]),
    (4, 1, [2, 0]),
    (7, 1, [1, 5]),
    (5, 1, [1, 4]),
    (-8, 1, [1, 3]),
    (-8, 1, [1, 2]),
    (5, 1, [1, 1]),
    (7, 1, [1, 0]),
    (2, 1, [0, 5]),
    (3, 1, [0, 4]),
    (-5, 1, [0, 3]),
    (-7, 1, [0, 2]),
    (-3, 1, [0, 1]),
    (6, 1, [0, 0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit sharing independent Fraction fixture 36" {
  let a = unit_fixture(3, [(1, 1, [0, 1, 0])])

  let b = unit_fixture(3, [
    (-2, 1, [0, 0, 0]),
    (-1, 2, [1, 1, 3]),
    (0, 3, [2, 2, 1]),
    (1, 1, [3, 3, 4]),
    (2, 2, [4, 0, 2]),
    (-2, 3, [5, 1, 0]),
    (-1, 1, [6, 2, 3]),
    (0, 2, [7, 3, 1]),
    (1, 3, [8, 0, 4]),
    (2, 1, [9, 1, 2]),
    (-2, 2, [10, 2, 0]),
    (-1, 3, [11, 3, 3]),
    (0, 1, [12, 0, 1]),
    (1, 2, [13, 1, 4]),
    (2, 3, [14, 2, 2]),
    (-2, 1, [15, 3, 0]),
    (-1, 2, [16, 0, 3]),
    (0, 3, [17, 1, 1]),
    (1, 1, [18, 2, 4]),
    (2, 2, [19, 3, 2]),
    (-2, 3, [20, 0, 0]),
    (-1, 1, [21, 1, 3]),
    (0, 2, [22, 2, 1]),
    (1, 3, [23, 3, 4]),
    (2, 1, [24, 0, 2]),
    (-2, 2, [25, 1, 0]),
    (-1, 3, [26, 2, 3]),
    (0, 1, [27, 3, 1]),
  ])

  let expected = unit_fixture(3, [
    (-1, 3, [26, 3, 3]),
    (-1, 1, [25, 2, 0]),
    (2, 1, [24, 1, 2]),
    (1, 3, [23, 4, 4]),
    (-1, 1, [21, 2, 3]),
    (-2, 3, [20, 1, 0]),
    (1, 1, [19, 4, 2]),
    (1, 1, [18, 3, 4]),
    (-1, 2, [16, 1, 3]),
    (-2, 1, [15, 4, 0]),
    (2, 3, [14, 3, 2]),
    (1, 2, [13, 2, 4]),
    (-1, 3, [11, 4, 3]),
    (-1, 1, [10, 3, 0]),
    (2, 1, [9, 2, 2]),
    (1, 3, [8, 1, 4]),
    (-1, 1, [6, 3, 3]),
    (-2, 3, [5, 2, 0]),
    (1, 1, [4, 1, 2]),
    (1, 1, [3, 4, 4]),
    (-1, 2, [1, 2, 3]),
    (-2, 1, [0, 1, 0]),
  ])

  assert_eq(multiply(a, b), Ok(expected))

  assert_eq(multiply(b, a), Ok(expected))

  assert_eq(multiply(a, b), unit_generic_oracle(a, b))

  assert_eq(multiply(a, b), unit_sequential_oracle(a, b))
}

///|
test "unit multiplication dimensions precede empty and unit checks" {
  let zero = zero(@oracle.nat(2))

  let one = unit_fixture(0, [(1, 1, [])])

  assert_eq(multiply(zero, one), Err(DimensionMismatch))

  assert_eq(multiply(one, zero), Err(DimensionMismatch))
}
