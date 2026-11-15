///|
fn prime(n : Int32) -> Bool {
  if n < 2 {
    return false
  }
  for d in 2..<n {
    if n % d == 0 {
      return false
    }
  }
  true
}

///|
test "all residues over all odd primes below 128 versus brute-force square roots" {
  for p in 0..<128 {
    if p <= 2 || !prime(p) {
      assert_eq(field(@oracle.binary(p)), None)
      continue
    }
    let context = field(@oracle.binary(p)).unwrap()
    for value in 0..<(2 * p) {
      let roots = []
      for candidate in 0..<p {
        if candidate * candidate % p == value % p {
          roots.push(candidate)
        }
      }
      let expected = if roots.is_empty() {
        None
      } else {
        Some(@oracle.binary(roots[0]))
      }
      assert_eq(sqrt(context, @oracle.binary(value)), expected)
      assert_eq(
        character(context, @oracle.binary(value)),
        if value % p == 0 {
          Zero
        } else if roots.is_empty() {
          Nonresidue
        } else {
          Residue
        },
      )
    }
  }
}

///|
test "sixteen powers of two in p-minus-one exercise nontrivial Tonelli corrections" {
  let p = 65537
  let context = field(@oracle.binary(p)).unwrap()
  assert_eq(@oracle.int_of_nat(context.two_power), 16)
  for root in [1, 2, 3, 17, 255, 12345, 32768] {
    let square = root * root % p
    assert_eq(sqrt(context, @oracle.binary(square)), Some(@oracle.binary(root)))
  }
  let squares = Array::make(p, false)
  for x in 0..<p {
    squares[(x.to_int64() * x.to_int64() % p.to_int64()).to_int()] = true
  }
  for n in 1..<64 {
    if !squares[n] {
      assert_eq(sqrt(context, @oracle.binary(n)), None)
    }
  }
}
