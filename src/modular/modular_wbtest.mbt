///|
fn mod(n : Int32) -> Modulus {
  match modulus(@oracle.binary(n)) {
    Some(m) => m
    None => abort("test modulus")
  }
}

///|
test "modular arithmetic and inverse exhaust small composite and prime moduli" {
  for m in 2..<32 {
    let ring = mod(m)
    for a in 0..<40 {
      for b in 0..<40 {
        assert_eq(
          @oracle.int_of_binary(add(ring, @oracle.binary(a), @oracle.binary(b))),
          (a + b) % m,
        )
        assert_eq(
          @oracle.int_of_binary(
            subtract(ring, @oracle.binary(a), @oracle.binary(b)),
          ),
          ((a - b) % m + m) % m,
        )
        assert_eq(
          @oracle.int_of_binary(
            multiply(ring, @oracle.binary(a), @oracle.binary(b)),
          ),
          a * b % m,
        )
      }
      let brute = [ for x in 0..<m if a * x % m == 1 => x ]
      match inverse(ring, @oracle.binary(a)) {
        None => assert_eq(brute, [])
        Some(inv) => {
          assert_eq(brute, [@oracle.int_of_binary(inv)])
          assert_eq(multiply(ring, @oracle.binary(a), inv), @oracle.binary(1))
        }
      }
      for exponent in 0..<12 {
        let mut expected = 1
        for _ in 0..<exponent {
          expected = expected * a % m
        }
        assert_eq(
          @oracle.int_of_binary(
            power(ring, @oracle.binary(a), @oracle.binary(exponent)),
          ),
          expected,
        )
      }
    }
  }
  assert_eq(modulus(@oracle.binary(0)), None)
  assert_eq(modulus(@oracle.binary(1)), None)
}

///|
test "extended Euclid returns valid certificates and exact primality" {
  for a in 0..<40 {
    for b in 0..<40 {
      let (g, x, y) = extended_gcd(@oracle.binary(a), @oracle.binary(b))
      let gcd = @oracle.int_of_binary(g)
      assert_eq(
        a * @oracle.int_of_integer(x) + b * @oracle.int_of_integer(y),
        gcd,
      )
      assert_eq(g, @binary.gcd(@oracle.binary(a), @oracle.binary(b)))
    }
  }
  for n in 0..<256 {
    let mut expected = n >= 2
    for divisor in 2..<n {
      if n % divisor == 0 {
        expected = false
      }
    }
    assert_eq(is_prime(@oracle.binary(n)), expected)
  }
}

///|
test "canonical reduction boundaries and signed residues match machine arithmetic" {
  for m in 2..<40 {
    let ring = mod(m)
    for a in 0..<(m * 3 + 2) {
      assert_eq(@oracle.int_of_binary(reduce(ring, @oracle.binary(a))), a % m)
    }
    for a in -128..<129 {
      assert_eq(
        @oracle.int_of_binary(signed_reduce(ring, @oracle.integer(a))),
        (a % m + m) % m,
      )
    }
  }
}
