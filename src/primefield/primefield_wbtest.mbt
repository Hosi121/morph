///|
fn certificate(p : Int32) -> @primality.Certificate {
  match p {
    2 => Two
    3 => Lucas(@oracle.binary(3), @oracle.binary(2), Cons(certificate(2), Nil))
    5 =>
      Lucas(
        @oracle.binary(5),
        @oracle.binary(2),
        Cons(certificate(2), Cons(certificate(2), Nil)),
      )
    _ => abort("small prime certificate")
  }
}

///|
test "general prime field validates all small candidates including two" {
  for n in 0..<128 {
    let mut expected = n >= 2
    for d in 2..<n {
      if n % d == 0 {
        expected = false
      }
    }
    match field(@oracle.binary(n)) {
      None => assert_false(expected)
      Some(f) => {
        assert_true(expected)
        assert_eq(@modular.value(modulus(f)), @oracle.binary(n))
      }
    }
  }
}

///|
test "checked prime and exact trial entry points construct the same field" {
  for p in [2, 3, 5] {
    let prime = @primality.check(certificate(p)).unwrap()
    assert_eq(from_prime(prime), field(@oracle.binary(p)))
  }
  for n in [0, 1, 4, 6, 8, 9, 15, 21, 25, 49] {
    assert_eq(field(@oracle.binary(n)), None)
  }
}

///|
test "GF two three five arithmetic and all small inverse claims match integers" {
  for p in [2, 3, 5] {
    let f = field(@oracle.binary(p)).unwrap()
    let ops = arithmetic(f)
    assert_eq(ops.zero, @oracle.binary(0))
    assert_eq(ops.one, @oracle.binary(1))
    for a in 0..<16 {
      assert_eq(
        @oracle.int_of_binary((ops.negate)(@oracle.binary(a))),
        (-a % p + p) % p,
      )
      match (ops.inverse)(@oracle.binary(a)) {
        None => assert_eq(a % p, 0)
        Some(inverse) => {
          assert_true(a % p != 0)
          assert_eq(a * @oracle.int_of_binary(inverse) % p, 1)
          assert_eq((ops.multiply)(@oracle.binary(a), inverse), ops.one)
          assert_true(@oracle.int_of_binary(inverse) < p)
        }
      }
      for b in 0..<16 {
        assert_eq(
          @oracle.int_of_binary((ops.add)(@oracle.binary(a), @oracle.binary(b))),
          (a + b) % p,
        )
        assert_eq(
          @oracle.int_of_binary(
            (ops.subtract)(@oracle.binary(a), @oracle.binary(b)),
          ),
          ((a - b) % p + p) % p,
        )
        assert_eq(
          @oracle.int_of_binary(
            (ops.multiply)(@oracle.binary(a), @oracle.binary(b)),
          ),
          a * b % p,
        )
      }
    }
  }
}

///|
test "GF two arithmetic works with generic Gauss Jordan reduction" {
  let f = field(@oracle.binary(2)).unwrap()
  let ops = arithmetic(f)
  let matrix = @matrix.matrix(
    @oracle.nat(2),
    @oracle.chain([
      @oracle.chain([1, 1].map(@oracle.binary)),
      @oracle.chain([0, 1].map(@oracle.binary)),
    ]),
  ).unwrap()
  assert_eq(@rowreduce.inverse(ops, matrix), Some(matrix))
  assert_eq(@rowreduce.determinant(ops, matrix), Some(@oracle.binary(1)))
  assert_eq(
    @rowreduce.solve(ops, matrix, @oracle.chain([1, 0].map(@oracle.binary))),
    Some(@rowreduce.Unique(@oracle.chain([1, 0].map(@oracle.binary)))),
  )
}
