///|
fn bareiss_rat(
  negative : Bool,
  numerator : String,
  denominator : String,
) -> @exact.Rational {
  let n = @exact.positive(@oracle.binary_from_hex(numerator))
  @exact.ratio(
    if negative {
      @exact.negate(n)
    } else {
      n
    },
    @oracle.binary_from_hex(denominator),
  ).unwrap()
}

///|
fn bareiss_matrix(
  rows : Array[Array[@exact.Rational]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(rows.length()),
    @oracle.chain(rows.map(@oracle.chain)),
  ).unwrap()
}

///|
fn bareiss_fixture(
  matrix : @matrix.Matrix[@exact.Rational],
  expected : @exact.Rational,
  integer : Bool,
) -> Unit raise {
  assert_eq(determinant(matrix), Ok(expected))
  assert_eq(@linear.determinant(matrix), Some(expected))
  if integer {
    let ints = @matrix.matrix(
      @matrix.width(matrix),
      @core.map(@matrix.rows(matrix), fn(row) {
        @core.map(row, @exact.numerator)
      }),
    ).unwrap()
    assert_eq(integer_determinant(ints), Ok(@exact.numerator(expected)))
  }
}

///|
test "Bareiss exact signed division rejects all remainders and zero divisors" {
  for numerator in -16..<=16 {
    for denominator in -8..<=8 {
      let n = @exact.numerator(@oracle.rational(numerator, 1))
      let d = @exact.numerator(@oracle.rational(denominator, 1))
      if denominator == 0 {
        assert_eq(exact_divide(n, d), Err(ZeroDivisor))
      } else if numerator % denominator != 0 {
        assert_eq(exact_divide(n, d), Err(InexactDivision))
      } else {
        assert_eq(
          exact_divide(n, d),
          Ok(@exact.numerator(@oracle.rational(numerator / denominator, 1))),
        )
      }
    }
  }
}

///|
test "Bareiss guards shapes and reports injected inexact intermediate division" {
  let non_square = @matrix.matrix(
    @oracle.nat(2),
    @oracle.chain([
      @oracle.chain([@oracle.rational(1, 1), @oracle.rational(2, 1)]),
    ]),
  ).unwrap()
  assert_eq(determinant(non_square), Err(NotSquare))
  let one = @exact.numerator(@oracle.rational(1, 1))
  let zero = @exact.numerator(@oracle.rational(0, 1))
  let two = @exact.numerator(@oracle.rational(2, 1))
  assert_eq(
    determinant_rows(
      @oracle.chain([@oracle.chain([one, zero]), @oracle.chain([zero, one])]),
      two,
      false,
    ),
    Err(InexactDivision),
  )
}
