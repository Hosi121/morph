///|
test "nonunit small gcd corpus through exact common factor" (b : @bench.T) {
  let pairs = []
  for index in 0..<128 {
    let left = 2 + (index * 73 + 19) % 254
    let right = 2 + (index * 137 + 43) % 254
    pairs.push((@oracle.binary(left), @oracle.binary(right)))
  }
  b.bench(fn() {
    for pair in pairs {
      b.keep(common_factor(pair.0, pair.1))
    }
  })
}

///|
test "mixed width common factor control excludes small dispatch" (b : @bench.T) {
  let pairs = []
  for width in [16, 32, 64, 128] {
    let power = @binary.power(@oracle.binary(2), @oracle.binary(width))
    let below = @binary.subtract(power, @binary.one()).unwrap()
    let above = @binary.successor(power)
    pairs.push((below, above))
    pairs.push(
      (
        @binary.multiply(below, @oracle.binary(6)),
        @binary.multiply(below, @oracle.binary(10)),
      ),
    )
    pairs.push((power, @binary.add(above, @oracle.binary(42))))
  }
  b.bench(fn() {
    for pair in pairs {
      b.keep(common_factor(pair.0, pair.1))
    }
  })
}
