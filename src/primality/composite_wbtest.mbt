///|
fn integer_power(base : Int32, exponent : Int32, modulus : Int32) -> Int32 {
  let mut result = 1
  for _ in 0..<exponent {
    result = result * base % modulus
  }
  result
}

///|
fn integer_strong(n : Int32, base : Int32) -> Bool {
  if n <= 2 || n % 2 == 0 || base < 1 || base >= n {
    return false
  }
  let mut d = n - 1
  let mut s = 0
  while d % 2 == 0 {
    d = d / 2
    s = s + 1
  }
  if integer_power(base, d, n) == 1 {
    return false
  }
  for j in 0..<s {
    if integer_power(base, d * (1 << j), n) == n - 1 {
      return false
    }
  }
  true
}

///|
test "strong witness checker matches independent small integer powers" {
  for n in 0..<128 {
    for a in 0..<(n + 2) {
      let result = check_composite(@oracle.binary(n), Strong(@oracle.binary(a)))
      match result {
        None => assert_false(integer_strong(n, a))
        Some(proof) => {
          assert_true(integer_strong(n, a))
          assert_false(trial_prime(n))
          assert_eq(composite_value(proof), @oracle.binary(n))
          assert_eq(composite_witness(proof), Strong(@oracle.binary(a)))
        }
      }
    }
  }
}

///|
test "divisor compositeness checks reject trivial and nondividing claims" {
  for n in 0..<64 {
    for divisor in 0..<66 {
      match
        check_composite(@oracle.binary(n), Divisor(@oracle.binary(divisor))) {
        None => assert_false(divisor > 1 && divisor < n && n % divisor == 0)
        Some(proof) => {
          assert_true(divisor > 1 && divisor < n && n % divisor == 0)
          assert_eq(composite_value(proof), @oracle.binary(n))
        }
      }
    }
  }
}

///|
test "passing strong pseudoprimes remain inconclusive until a witness is supplied" {
  assert_eq(
    screen(@oracle.binary(2047), Cons(@oracle.binary(2), Nil)),
    Inconclusive,
  )
  match
    screen(
      @oracle.binary(2047),
      Cons(@oracle.binary(2), Cons(@oracle.binary(3), Nil)),
    ) {
    Composite(proof) =>
      assert_eq(composite_witness(proof), Strong(@oracle.binary(3)))
    Inconclusive => abort("base three exposes this pseudoprime")
  }
  let n = @oracle.binary(1373653)
  let bases = @oracle.chain([2, 3].map(@oracle.binary))
  assert_eq(screen(n, bases), Inconclusive)
  match screen(n, @oracle.chain([2, 3, 5].map(@oracle.binary))) {
    Composite(proof) =>
      assert_eq(composite_witness(proof), Strong(@oracle.binary(5)))
    Inconclusive => abort("base five exposes this pseudoprime")
  }
  match screen(@oracle.binary(561), Cons(@oracle.binary(2), Nil)) {
    Composite(proof) => assert_eq(composite_value(proof), @oracle.binary(561))
    Inconclusive => abort("Carmichael number fails the strong test")
  }
}

///|
test "empty bases invalid bases small inputs and prime inputs give no false verdict" {
  for n in [0, 1, 2, 3, 5, 7, 11, 17, 31, 127] {
    let bases = @oracle.chain([0, 1, 2, 3, 5, n, n + 1].map(@oracle.binary))
    assert_eq(screen(@oracle.binary(n), bases), Inconclusive)
  }
  assert_eq(screen(@oracle.binary(9), Nil), Inconclusive)
  assert_eq(
    screen(@oracle.binary(9), @oracle.chain([0, 9, 10].map(@oracle.binary))),
    Inconclusive,
  )
  match screen(@oracle.binary(4), Nil) {
    Composite(proof) =>
      assert_eq(composite_witness(proof), Divisor(@oracle.binary(2)))
    Inconclusive => abort("even composite is exposed without bases")
  }
}
