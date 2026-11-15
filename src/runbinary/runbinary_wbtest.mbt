///|
fn small(value : Int32) -> Number {
  from_binary(@oracle.binary(value))
}

///|
fn integer(value : Number) -> Int32 {
  @oracle.int_of_binary(expand(value, @oracle.binary(64)).unwrap())
}

///|
test "canonical runs and explicit expansion limit" {
  let input = @oracle.chain([
    Run::{ bit: false, length: @oracle.binary(3), },
    { bit: true, length: @oracle.binary(2), },
    { bit: false, length: @binary.zero(), },
    { bit: true, length: @binary.one(), },
    { bit: false, length: @oracle.binary(9), },
  ])
  let value = from_runs(input)
  assert_eq(integer(value), 56)
  assert_eq(width(value), @oracle.binary(6))
  assert_eq(@oracle.int_of_nat(@core.length(runs(value))), 2)
  assert_eq(expand(value, @oracle.binary(5)), None)
  assert_eq(expand(value, @oracle.binary(6)), Some(@oracle.binary(56)))
  assert_eq(expand(zero(), @binary.zero()), Some(@binary.zero()))
  assert_eq(
    from_runs(@core.Cons({ bit: false, length: @oracle.binary(100), }, Nil)),
    zero(),
  )
}

///|
test "compressed arithmetic agrees with native integer arithmetic" {
  for a in 0..<128 {
    let left = small(a)
    assert_eq(integer(left), a)
    assert_eq(integer(successor(left)), a + 1)
    for b in 0..<128 {
      let right = small(b)
      assert_eq(integer(add(left, right)), a + b)
      assert_eq(integer(multiply(left, right)), a * b)
      assert_eq(
        compare(left, right),
        if a < b {
          @core.Less
        } else if a > b {
          @core.Greater
        } else {
          @core.Equal
        },
      )
      assert_eq(
        subtract(left, right).map(integer),
        if a < b {
          None
        } else {
          Some(a - b)
        },
      )
    }
    for shift in 0..<=12 {
      assert_eq(integer(shift_left(left, @oracle.binary(shift))), a << shift)
      assert_eq(integer(shift_right(left, @oracle.binary(shift))), a >> shift)
    }
  }
}

///|
test "one homogeneous carry or borrow transition is a fixed point" {
  for subtracting in [false, true] {
    let operation = if subtracting { Difference } else { Addition }
    for a in [false, true] {
      for b in [false, true] {
        for flag in [false, true] {
          let (_, next) = digit(operation, a, b, flag)
          let (_, again) = digit(operation, a, b, next)
          assert_eq(again, next)
        }
      }
    }
  }
}

///|
test "positive pairing uses binary run lengths instead of expanding zeros" {
  assert_eq(unpair(zero()), None)
  for a in 0..<=12 {
    for b in 0..<64 {
      let code = pair(@oracle.binary(a), small(b))
      assert_eq(unpair(code), Some((@oracle.binary(a), small(b))))
      assert_eq(
        expand(code, @oracle.binary(32)),
        Some(@binary.pair(@oracle.nat(a), @oracle.binary(b))),
      )
    }
  }
}

///|
test "arithmetic at an unexpandable width stays compressed" {
  let exponent = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  let power = power_of_two(exponent)
  let mersenne = from_runs(@core.Cons({ bit: true, length: exponent, }, Nil))
  assert_eq(add(mersenne, one()), power)
  assert_eq(subtract(power, one()), Some(mersenne))
  assert_eq(subtract(power, power), Some(zero()))
  assert_eq(multiply(power, power), power_of_two(@binary.double(exponent)))
  assert_eq(shift_right(power, exponent), one())
  assert_eq(shift_right(power, @binary.successor(exponent)), zero())
  assert_eq(expand(power, @oracle.binary(4096)), None)
  assert_eq(@oracle.int_of_nat(@core.length(runs(power))), 2)
  let squared = multiply(mersenne, mersenne)
  let expected = from_runs(
    @oracle.chain([
      Run::{ bit: true, length: @binary.one(), },
      { bit: false, length: exponent, },
      { bit: true, length: @binary.subtract(exponent, @binary.one()).unwrap(), },
    ]),
  )
  assert_eq(squared, expected)
  assert_eq(@oracle.int_of_nat(@core.length(runs(squared))), 3)
  assert_eq(unpair(pair(exponent, mersenne)), Some((exponent, mersenne)))
}
