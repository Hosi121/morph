///|
fn large_pair() -> (@binary.Binary, @binary.Binary) {
  let power = @binary.power(@oracle.binary(2), @oracle.binary(127))
  (@binary.subtract(power, @binary.one()).unwrap(), @binary.successor(power))
}

///|
test "normalize coprime one hundred twenty eight bit fraction" (b : @bench.T) {
  let (below, above) = large_pair()
  let numerator = positive(above)
  b.bench(fn() { b.keep(ratio(numerator, below)) })
}

///|
test "normalize shared one hundred twenty seven bit factor" (b : @bench.T) {
  let (below, _) = large_pair()
  let numerator = positive(@binary.multiply(below, @oracle.binary(6)))
  let denominator = @binary.multiply(below, @oracle.binary(10))
  b.bench(fn() { b.keep(ratio(numerator, denominator)) })
}

///|
test "half reduced even numerator with large odd denominator" (b : @bench.T) {
  let (below, above) = large_pair()
  let value = ratio(positive(@binary.double(below)), above).unwrap()
  b.bench(fn() { b.keep(rational_half(value)) })
}

///|
test "half reduced odd numerator with large denominator" (b : @bench.T) {
  let (below, above) = large_pair()
  let value = ratio(positive(above), below).unwrap()
  b.bench(fn() { b.keep(rational_half(value)) })
}

///|
test "add common one hundred twenty seven bit denominator" (b : @bench.T) {
  let (below, _) = large_pair()
  let a = ratio(@oracle.integer(1), below).unwrap()
  let c = ratio(@oracle.integer(2), below).unwrap()
  b.bench(fn() { b.keep(rational_add(a, c)) })
}

///|
test "add coprime large denominators control" (b : @bench.T) {
  let (below, above) = large_pair()
  let a = ratio(@oracle.integer(1), below).unwrap()
  let c = ratio(@oracle.integer(2), above).unwrap()
  b.bench(fn() { b.keep(rational_add(a, c)) })
}

///|
test "compare opposite signs with large numerator denominator" (b : @bench.T) {
  let (below, above) = large_pair()
  let a = ratio(positive(above), below).unwrap()
  let c = rational_negate(a)
  b.bench(fn() { b.keep(rational_compare(a, c)) })
}

///|
test "compare common large denominator" (b : @bench.T) {
  let (below, above) = large_pair()
  let a = ratio(positive(above), below).unwrap()
  let c = ratio(positive(@binary.add(above, @oracle.binary(2))), below).unwrap()
  b.bench(fn() { b.keep(rational_compare(a, c)) })
}

///|
test "cross cancelled reciprocal product one hundred twenty eight bits" (
  b : @bench.T,
) {
  let (below, above) = large_pair()
  let a = ratio(positive(above), below).unwrap()
  let c = reciprocal(nonzero(a).unwrap())
  b.bench(fn() { b.keep(rational_multiply(a, c)) })
}

///|
test "signed integer add subtract multiply zero and unit corpus" (b : @bench.T) {
  let values = @oracle.chain(
    [-256, -17, -1, 0, 1, 19, 257].map(@oracle.integer),
  )
  b.bench(fn() {
    b.keep(
      @core.map(values, fn(a) {
        @core.map(values, fn(c) { (add(a, c), subtract(a, c), multiply(a, c)) })
      }),
    )
  })
}
