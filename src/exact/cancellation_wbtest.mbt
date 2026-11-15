///|
test "cross-cancelled rational operations match integer fractions exhaustively" {
  for a in -8..<=8 {
    for ad in 1..<=9 {
      for b in -8..<=8 {
        for bd in 1..<=9 {
          let x = @oracle.rational(a, ad)
          let y = @oracle.rational(b, bd)
          assert_eq(
            rational_add(x, y),
            @oracle.rational(a * bd + b * ad, ad * bd),
          )
          assert_eq(rational_multiply(x, y), @oracle.rational(a * b, ad * bd))
        }
      }
    }
  }
}

///|
test "large shared factors cancel and canonical zero retains denominator one" {
  let power = @binary.power(@oracle.binary(2), @oracle.binary(256))
  let below = @binary.subtract(power, @binary.one()).unwrap()
  let above = @binary.successor(power)
  let x = ratio(positive(above), below).unwrap()
  assert_eq(
    rational_multiply(x, reciprocal(nonzero(x).unwrap())),
    rational_one(),
  )
  assert_eq(rational_add(x, rational_negate(x)), rational_zero())
  assert_eq(rational_multiply(x, rational_zero()), rational_zero())
  let half = @oracle.rational(1, 2)
  assert_eq(
    rational_multiply(x, half),
    normalize(x.numerator, @binary.double(x.denominator)),
  )
}
