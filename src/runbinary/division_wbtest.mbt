///|
test "compressed Euclidean division and split agree with integers" {
  for a in 0..<128 {
    let value = small(a)
    for position in 0..<=10 {
      let (low, high) = split_at(value, @oracle.binary(position))
      assert_eq(integer(low), a % (1 << position))
      assert_eq(integer(high), a >> position)
    }
    assert_eq(start_division(value, zero()), None)
    for b in 1..<64 {
      let divisor = small(b)
      let search = start_division(value, divisor).unwrap()
      match run_division(search, @oracle.nat(64)) {
        Divided(result) => {
          assert_eq(integer(quotient(result)), a / b)
          assert_eq(integer(remainder(result)), a % b)
          assert_eq(
            check_division(value, divisor, quotient(result), remainder(result)),
            Some(result),
          )
        }
        _ => fail("small division must finish")
      }
    }
  }
}

///|
test "division certificates and chunked fuel" {
  let search = start_division(small(103), small(3)).unwrap()
  assert_eq(run_division(search, Zero), DivisionPaused(search))
  let whole = run_division(search, @oracle.nat(100))
  let mut current = search
  for _ in 0..<100 {
    match run_division(current, @core.Succ(Zero)) {
      DivisionPaused(next) => {
        assert_eq(
          @oracle.int_of_nat(division_transitions(next)),
          @oracle.int_of_nat(division_transitions(current)) + 1,
        )
        current = next
      }
      done => {
        assert_eq(done, whole)
        break
      }
    }
  }
  assert_eq(check_division(small(103), small(3), small(33), small(4)), None)
  assert_eq(check_division(small(103), small(3), small(34), small(2)), None)
  assert_eq(check_division(small(103), zero(), zero(), small(103)), None)
}

///|
test "huge powers divide in compressed form and Mersenne gcd reduces exponents" {
  let exponent = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  let half_exponent = @binary.half(exponent)
  let a = power_of_two(exponent)
  let b = power_of_two(half_exponent)
  match run_division(start_division(a, b).unwrap(), @core.Succ(Zero)) {
    Divided(result) => {
      assert_eq(quotient(result), b)
      assert_eq(remainder(result), zero())
    }
    _ => fail("power-of-two divisor needs one transition")
  }
  let all = from_runs(@core.Cons({ bit: true, length: exponent, }, Nil))
  let (low, high) = split_at(all, half_exponent)
  assert_eq(low, high)
  assert_eq(width(low), half_exponent)
  for x in 1..<=12 {
    for y in 1..<=12 {
      let a = small((1 << x) - 1)
      let b = small((1 << y) - 1)
      assert_eq(
        expand(mersenne_gcd(a, b).unwrap(), @oracle.binary(32)),
        Some(
          @binary.gcd(
            @oracle.binary((1 << x) - 1),
            @oracle.binary((1 << y) - 1),
          ),
        ),
      )
    }
  }
  assert_eq(mersenne_gcd(all, low), Some(low))
  match run_division(start_division(all, small(3)).unwrap(), @oracle.nat(3)) {
    DivisionPaused(state) => {
      assert_eq(@oracle.int_of_nat(division_transitions(state)), 3)
      assert_eq(
        add(multiply(state.quotient, state.divisor), state.remainder),
        all,
      )
    }
    _ => fail("a dense huge quotient must remain fuel bounded")
  }
  assert_eq(mersenne_gcd(zero(), all), None)
  assert_eq(mersenne_gcd(small(5), all), None)
}
