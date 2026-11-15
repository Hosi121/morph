///|
fn tiny_gcd_pairs() -> Array[(@binary.Binary, @binary.Binary)] {
  let pairs = []
  // Exclude 0/1/equal and operand 2, which existing/direct GCD shortcuts cover.
  for a in 3..<16 {
    for b in 3..<16 {
      if a != b {
        pairs.push((@oracle.binary(a), @oracle.binary(b)))
      }
    }
  }
  pairs
}

///|
test "all tiny gcd constructions equal an independent Euclidean integer oracle" {
  for a in 0..<16 {
    for b in 0..<16 {
      let left = @oracle.binary(a)
      let right = @oracle.binary(b)
      let expected = @oracle.binary(gcd_integer(a, b))
      assert_eq(candidate_gcd_table(left, right), expected)
      assert_eq(candidate_gcd_first(left, right), expected)
      assert_eq(candidate_gcd_second(left, right), expected)
      assert_eq(candidate_gcd_third(left, right), expected)
    }
  }
}

///|
test "tiny gcd full truth table without operand two" (b : @bench.T) {
  let pairs = tiny_gcd_pairs()
  b.bench(fn() {
    for pair in pairs {
      b.keep(candidate_gcd_table(pair.0, pair.1))
    }
  })
}

///|
test "tiny gcd first MTBDD order without operand two" (b : @bench.T) {
  let pairs = tiny_gcd_pairs()
  b.bench(fn() {
    for pair in pairs {
      b.keep(candidate_gcd_first(pair.0, pair.1))
    }
  })
}

///|
test "tiny gcd second MTBDD order without operand two" (b : @bench.T) {
  let pairs = tiny_gcd_pairs()
  b.bench(fn() {
    for pair in pairs {
      b.keep(candidate_gcd_second(pair.0, pair.1))
    }
  })
}

///|
test "tiny gcd third MTBDD order without operand two" (b : @bench.T) {
  let pairs = tiny_gcd_pairs()
  b.bench(fn() {
    for pair in pairs {
      b.keep(candidate_gcd_third(pair.0, pair.1))
    }
  })
}

///|
test "tiny gcd existing Stein bounded backend without operand two" (
  b : @bench.T,
) {
  let pairs = tiny_gcd_pairs()
  b.bench(fn() {
    for pair in pairs {
      b.keep(@binary.stein_gcd(pair.0, pair.1))
    }
  })
}
