///|
test "Karatsuba exact products against school multiplication and modular machine oracle" {
  for width in [65, 67, 127, 129, 255, 257, 511, 513, 1023] {
    for family in 0..<3 {
      let a = from_bits(
        @oracle.chain(
          [
            for i in 0..<width => {
              i == width - 1 || (i * 17 + family * 7) % 11 < 6
            }
          ],
        ),
      )
      let b = from_bits(
        @oracle.chain(
          [
            for i in 0..<(width + 7) => {
              i == width + 6 || (i * 13 + family * 3) % 7 < 4
            }
          ],
        ),
      )
      let product = karatsuba(a, b)
      assert_eq(product, multiply(a, b))
      fn residue(n : Binary) -> Int32 {
        @oracle.array(@core.reverse(bits(n))).fold(init=0, fn(value, bit) {
          let digit = if bit { 1 } else { 0 }
          (value * 2 + digit) % 1009
        })
      }
      assert_eq(residue(product), residue(a) * residue(b) % 1009)
    }
  }
  let ones = from_bits(@core.replicate(@oracle.nat(257), true))
  assert_eq(karatsuba(ones, ones), multiply(ones, ones))
  assert_eq(karatsuba(ones, zero()), zero())
  assert_eq(
    karatsuba(@oracle.binary(3), ones),
    multiply(@oracle.binary(3), ones),
  )
}
