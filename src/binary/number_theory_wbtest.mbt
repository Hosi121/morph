///|
test "Stein GCD agrees with integer Euclid and long-division GCD" {
  for a in 0..<96 {
    for b in 0..<96 {
      let mut x = a
      let mut y = b
      while y != 0 {
        let r = x % y
        x = y
        y = r
      }
      let result = stein_gcd(@oracle.binary(a), @oracle.binary(b))
      assert_eq(@oracle.int_of_binary(result), x)
      assert_eq(result, gcd(@oracle.binary(a), @oracle.binary(b)))
    }
  }
}

///|
test "integer square root and remainder exhaust the first four thousand inputs" {
  for n in 0..<4096 {
    let mut expected = 0
    while (expected + 1) * (expected + 1) <= n {
      expected += 1
    }
    let (root, remainder) = sqrt_rem(@oracle.binary(n))
    assert_eq(@oracle.int_of_binary(root), expected)
    assert_eq(@oracle.int_of_binary(remainder), n - expected * expected)
  }
  let large_root = from_bits(
    @core.append(@core.replicate(@oracle.nat(100), false), Cons(true, Nil)),
  )
  let square = karatsuba(large_root, large_root)
  assert_eq(sqrt_rem(successor(square)), (large_root, one()))
}

///|
test "fast doubling Fibonacci machine oracle and Cassini certificates" {
  let mut previous = 0
  let mut next = 1
  for n in 0..<=30 {
    let (a, b) = fibonacci_pair(@oracle.binary(n))
    assert_eq(@oracle.int_of_binary(a), previous)
    assert_eq(@oracle.int_of_binary(b), next)
    let total = previous + next
    previous = next
    next = total
  }
  for n in [64, 65, 200, 201, 1000] {
    let (a, b) = fibonacci_pair(@oracle.binary(n))
    let left = karatsuba(b, b)
    let right = karatsuba(a, add(a, b))
    assert_eq(
      if n % 2 == 0 {
        subtract(left, right)
      } else {
        subtract(right, left)
      },
      Some(one()),
    )
  }
}
