///|
test "rational zero product reuses canonical zero in either argument" (
  b : @bench.T,
) {
  let (below, above) = large_pair()
  let value = ratio(positive(above), below).unwrap()
  let zero = rational_zero()
  b.bench(fn() {
    b.keep(rational_multiply(value, zero))
    b.keep(rational_multiply(zero, value))
  })
}

///|
test "rational subtraction common large denominator" (b : @bench.T) {
  let (below, above) = large_pair()
  let left = ratio(positive(above), below).unwrap()
  let right = ratio(positive(@binary.add(above, @oracle.binary(2))), below).unwrap()
  b.bench(fn() { b.keep(rational_subtract(left, right)) })
}

///|
test "rational subtraction coprime large denominator control" (b : @bench.T) {
  let (below, above) = large_pair()
  let left = ratio(@oracle.integer(1), below).unwrap()
  let right = ratio(@oracle.integer(2), above).unwrap()
  b.bench(fn() { b.keep(rational_subtract(left, right)) })
}

///|
test "rational subtraction small numerator denominator corpus" (b : @bench.T) {
  let values = []
  for n in -3..<4 {
    for d in 1..<5 {
      values.push(@oracle.rational(n, d))
    }
  }
  b.bench(fn() {
    for left in values {
      for right in values {
        b.keep(rational_subtract(left, right))
      }
    }
  })
}
