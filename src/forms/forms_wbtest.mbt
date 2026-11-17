///|
fn fixture_polynomial(
  count : Int32,
  input : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(count),
    @oracle.chain(
      input.map(fn(entry) {
        let (n, d, exponents) = entry
        @poly.Term::{
          coefficient: @oracle.rational(n, d),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn fixture_terms(
  count : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> @core.Chain[Term] {
  @oracle.chain(
    input.map(fn(entry) {
      let (coefficient, indices) = entry
      Term::{
        coefficient: fixture_polynomial(count, coefficient),
        indices: @oracle.chain(indices.map(@oracle.nat)),
      }
    }),
  )
}

///|
fn fixture_form(
  count : Int32,
  grade : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> Form {
  form(@oracle.nat(count), @oracle.nat(grade), fixture_terms(count, input)).unwrap()
}

///|
fn fraction_form_fixture(
  count : Int32,
  grade : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  expected : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  derivative : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> Unit raise {
  let value = fixture_form(count, grade, input)
  assert_eq(variables(value), @oracle.nat(count))
  assert_eq(degree(value), @oracle.nat(grade))
  // Expected canonical Terms bypass the Form constructor being tested.
  assert_eq(terms(value), fixture_terms(count, expected))
  let actual = exterior_derivative(value).unwrap()
  assert_eq(variables(actual), @oracle.nat(count))
  assert_eq(degree(actual), @oracle.nat(grade + 1))
  assert_eq(terms(actual), fixture_terms(count, derivative))
  assert_eq(
    exterior_derivative(actual),
    Ok(zero(@oracle.nat(count), @oracle.nat(grade + 2))),
  )
}

///|
fn fraction_wedge_fixture(
  count : Int32,
  p : Int32,
  q : Int32,
  a : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  b : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  expected : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> Unit raise {
  let left = fixture_form(count, p, a)
  let right = fixture_form(count, q, b)
  let product = wedge(left, right).unwrap()
  assert_eq(degree(product), @oracle.nat(p + q))
  assert_eq(terms(product), fixture_terms(count, expected))
  let reversed = wedge(right, left).unwrap()
  assert_eq(product, if p * q % 2 == 0 { reversed } else { negate(reversed) })
  let first = wedge(exterior_derivative(left).unwrap(), right).unwrap()
  let second = wedge(left, exterior_derivative(right).unwrap()).unwrap()
  let signed = if p % 2 == 0 { second } else { negate(second) }
  assert_eq(exterior_derivative(product), add(first, signed))
}

///|
test "all form input is validated before zero or repeated-index elimination" {
  let n = @oracle.nat(2)
  let k = @oracle.nat(2)
  let repeated = @oracle.chain([@oracle.nat(0), @oracle.nat(0)])
  let invalid = @oracle.chain([@oracle.nat(2), @oracle.nat(2)])
  assert_eq(
    form(
      n,
      k,
      Cons({ coefficient: @poly.zero(@oracle.nat(3)), indices: repeated, }, Nil),
    ),
    Err(CoefficientDimension),
  )
  assert_eq(
    form(n, k, Cons({ coefficient: @poly.zero(n), indices: invalid, }, Nil)),
    Err(IndexOutOfRange),
  )
  assert_eq(
    form(
      n,
      k,
      Cons({ coefficient: @poly.zero(n), indices: Cons(Zero, Nil), }, Nil),
    ),
    Err(ComponentDegree),
  )
  let input : @core.Chain[Term] = Cons(
    Term::{ coefficient: @poly.zero(n), indices: repeated, },
    Cons({ coefficient: @poly.zero(n), indices: invalid, }, Nil),
  )
  assert_eq(form(n, k, input), Err(IndexOutOfRange))
  assert_eq(
    form(
      Zero,
      Succ(Zero),
      Cons({ coefficient: @poly.zero(Zero), indices: Cons(Zero, Nil), }, Nil),
    ),
    Err(IndexOutOfRange),
  )
  assert_eq(
    form(
      n,
      @oracle.nat(3),
      Cons(
        {
          coefficient: fixture_polynomial(2, [(1, 1, [0, 0])]),
          indices: @oracle.chain([
            @oracle.nat(0),
            @oracle.nat(1),
            @oracle.nat(0),
          ]),
        },
        Nil,
      ),
    ),
    Ok(zero(n, @oracle.nat(3))),
  )
  assert_eq(add(zero(n, Zero), zero(n, Succ(Zero))), Err(DegreeMismatch))
  assert_eq(wedge(zero(Zero, Zero), zero(n, Zero)), Err(DimensionMismatch))
}

///|
test "permutations have inversion signs and equal terms cancel canonically" {
  let value = fixture_form(3, 3, [
    ([(2, 1, [1, 0, 0])], [2, 1, 0]),
    ([(3, 1, [0, 0, 0])], [1, 2, 0]),
  ])
  assert_eq(
    terms(value),
    fixture_terms(3, [([(-2, 1, [1, 0, 0]), (3, 1, [0, 0, 0])], [0, 1, 2])]),
  )
  assert_eq(add(value, negate(value)), Ok(zero(@oracle.nat(3), @oracle.nat(3))))
  let one = scalar(fixture_polynomial(0, [(1, 1, [])]))
  assert_eq(wedge(one, one), Ok(one))
  assert_eq(exterior_derivative(one), Ok(zero(Zero, Succ(Zero))))
}
