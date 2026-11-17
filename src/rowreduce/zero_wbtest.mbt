///|
fn mod_five(value : Int32) -> Int32 {
  (value % 5 + 5) % 5
}

///|
fn five_field(multiply : (Int32, Int32) -> Int32) -> Field[Int32] {
  {
    zero: 0,
    one: 1,
    add: fn(a, b) { mod_five(a + b) },
    subtract: fn(a, b) { mod_five(a - b) },
    negate: fn(a) { mod_five(-a) },
    multiply,
    inverse: fn(a) {
      match mod_five(a) {
        1 => Some(1)
        2 => Some(3)
        3 => Some(2)
        4 => Some(4)
        _ => None
      }
    },
  }
}

///|
fn integer_matrix(values : Array[Array[Int32]]) -> @matrix.Matrix[Int32] {
  @matrix.matrix(
    @oracle.nat(values[0].length()),
    @oracle.chain(values.map(@oracle.chain)),
  ).unwrap()
}

///|
test "explicit canonical zero predicate skips whole zero-factor row operations" {
  let mut products = 0
  let field = five_field(fn(a, b) {
    products += 1
    mod_five(a * b)
  })
  let input = integer_matrix([[1, 0], [0, 1]])
  let generic = rref(field, input)
  let generic_products = products
  products = 0
  assert_eq(rref_with_zero(field, fn(a) { a == 0 }, input), generic)
  assert_eq(generic_products, 10)
  assert_eq(products, 6)
  assert_eq(
    inverse_with_zero(field, fn(a) { a == 0 }, input),
    inverse(field, input),
  )
  assert_eq(
    solve_with_zero(field, fn(a) { a == 0 }, input, @oracle.chain([2, 3])),
    Some(Unique(@oracle.chain([2, 3]))),
  )
}

///|
test "generic entry point retains inverse-driven unreduced coefficient behavior" {
  let field = five_field(fn(a, b) { mod_five(a * b) })
  let input = integer_matrix([[1, 0, 0], [0, 0, 5]])
  let reduced = rref(field, input).unwrap()
  assert_eq(reduced.matrix, integer_matrix([[1, 0, 0], [0, 0, 0]]))
  assert_eq(reduced.pivots, @oracle.chain([@oracle.nat(0)]))
  assert_eq(
    solve(field, input, @oracle.chain([6, 5])),
    Some(
      Affine(
        @oracle.chain([1, 0, 0]),
        @oracle.chain([@oracle.chain([0, 1, 0]), @oracle.chain([0, 0, 1])]),
      ),
    ),
  )
}
