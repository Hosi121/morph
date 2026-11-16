///|
fn previous_zero_factory() -> Binary {
  { bits: Nil, }
}

///|
fn previous_one_factory() -> Binary {
  { bits: Cons(true, Nil), }
}

///|
test "cached Binary zero and one factories" (b : @bench.T) {
  b.bench(fn() {
    b.keep(canonical_zero())
    b.keep(canonical_one())
  })
}

///|
test "previous Binary zero and one factories same executable" (b : @bench.T) {
  b.bench(fn() {
    b.keep(previous_zero_factory())
    b.keep(previous_one_factory())
  })
}

///|
test "Binary mixed small input arithmetic cohort" (b : @bench.T) {
  let pairs = []
  for index in 0..<128 {
    let a = (index * 73 + 19) % 65
    let c = (index * 137 + 43) % 65
    pairs.push((@oracle.binary(a), @oracle.binary(c)))
  }
  b.bench(fn() {
    for pair in pairs {
      b.keep(add(pair.0, pair.1))
      b.keep(subtract(pair.0, pair.1))
      b.keep(multiply(pair.0, pair.1))
      b.keep(divmod(pair.0, pair.1))
      b.keep(gcd(pair.0, pair.1))
    }
  })
}
