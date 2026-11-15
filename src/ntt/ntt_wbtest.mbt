///|
fn checked_plan(p : Int32, root : Int32, n : Int32) -> Plan {
  match @modular.modulus(@oracle.binary(p)) {
    None => abort("test modulus")
    Some(m) =>
      match plan(m, @oracle.binary(root), @oracle.nat(n)) {
        Some(plan) => plan
        None => abort("test plan")
      }
  }
}

///|
fn pow_mod(base : Int32, exponent : Int32, modulus : Int32) -> Int32 {
  let mut result = 1
  for _ in 0..<exponent {
    result = result * base % modulus
  }
  result
}

///|
test "NTT equals direct integer DFT and round trips all binary eight-sample signals" {
  let plan = checked_plan(17, 9, 8)
  for mask in 0..<256 {
    let input = [ for i in 0..<8 => if (mask & (1 << i)) == 0 { 0 } else { 1 } ]
    let xs = @oracle.chain(input.map(@oracle.binary))
    let expected = [
      for k in 0..<8 => {
        let mut sum = 0
        for j in 0..<8 {
          sum += input[j] * pow_mod(9, j * k, 17)
        }
        sum % 17
      }
    ]
    match transform(plan, xs) {
      None => fail("length rejected")
      Some(spectrum) => {
        assert_eq(@oracle.array(spectrum).map(@oracle.int_of_binary), expected)
        assert_eq(inverse(plan, spectrum), Some(xs))
      }
    }
  }
}

///|
test "linear convolution matches school multiplication across lengths and coefficients" {
  let plan = checked_plan(17, 3, 16)
  for nx in 1..<=8 {
    for ny in 1..<=8 {
      let x = [ for i in 0..<nx => (i * 7 + nx * 3) % 31 ]
      let y = [ for i in 0..<ny => (i * 11 + ny) % 29 ]
      let expected = Array::make(nx + ny - 1, 0)
      for i in 0..<nx {
        for j in 0..<ny {
          expected[i + j] = (expected[i + j] + x[i] * y[j]) % 17
        }
      }
      match
        convolve(
          plan,
          @oracle.chain(x.map(@oracle.binary)),
          @oracle.chain(y.map(@oracle.binary)),
        ) {
        None => fail("adequate plan rejected")
        Some(result) =>
          assert_eq(@oracle.array(result).map(@oracle.int_of_binary), expected)
      }
    }
  }
  assert_eq(convolve(plan, Nil, Nil), Some(Nil))
  assert_eq(transform(plan, Nil), None)
  assert_eq(
    convolve(
      checked_plan(17, 13, 4),
      @core.replicate(@oracle.nat(3), @oracle.binary(1)),
      @core.replicate(@oracle.nat(3), @oracle.binary(1)),
    ),
    None,
  )
}

///|
test "bad lengths, composite moduli and nonprimitive roots are rejected" {
  let seventeen = checked_plan(17, 3, 16).modulus
  assert_eq(plan(seventeen, @oracle.binary(1), @oracle.nat(4)), None)
  assert_eq(plan(seventeen, @oracle.binary(3), @oracle.nat(3)), None)
  assert_eq(plan(seventeen, @oracle.binary(3), @oracle.nat(0)), None)
  let composite = @modular.modulus(@oracle.binary(15))
  match composite {
    None => fail("modulus rejected")
    Some(m) => assert_eq(plan(m, @oracle.binary(14), @oracle.nat(2)), None)
  }
  let singleton = checked_plan(17, 1, 1)
  assert_eq(
    transform(singleton, @oracle.chain([@oracle.binary(19)])),
    Some(@oracle.chain([@oracle.binary(2)])),
  )
}
