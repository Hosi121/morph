///|
fn instance_for(p : Int32, g : Int32, h : Int32, bound : Int32) -> Problem {
  let f = @primefield.field(@oracle.binary(p)).unwrap()
  problem(f, @oracle.binary(g), @oracle.binary(h), @oracle.binary(bound)).unwrap()
}

///|
fn integer_log(p : Int32, g : Int32, h : Int32, bound : Int32) -> Int32? {
  let mut power = 1
  for exponent in 0..<bound {
    if power == h {
      return Some(exponent)
    }
    power = power * g % p
  }
  None
}

///|
test "all small prime groups bases targets and bounds match exhaustive integer oracle" {
  for p in [2, 3, 5, 7, 11, 13, 17, 19] {
    let f = @primefield.field(@oracle.binary(p)).unwrap()
    for g in 1..<p {
      for h in 1..<p {
        for bound in 0..<(p + 3) {
          let problem = problem(
            f,
            @oracle.binary(g),
            @oracle.binary(h),
            @oracle.binary(bound),
          ).unwrap()
          let expected = integer_log(p, g, h, bound)
          let actual = baby_step_giant_step(problem)
          assert_eq(
            actual.map(fn(log) { @oracle.int_of_binary(exponent(log)) }),
            expected,
          )
          assert_eq(naive(problem), actual)
          match actual {
            Some(log) => {
              assert_eq(instance(log), problem)
              assert_eq(check(problem, exponent(log)), Some(log))
            }
            None => ()
          }
        }
      }
    }
  }
}

///|
test "exclusive bounds non-generators repeated babies and zero exponents stay distinct" {
  let periodic = instance_for(7, 1, 1, 10)
  assert_eq(
    check(periodic, @oracle.binary(5)).map(exponent),
    Some(@oracle.binary(5)),
  )
  assert_eq(
    baby_step_giant_step(periodic).map(exponent),
    Some(@oracle.binary(0)),
  )
  let bounded = instance_for(17, 3, 13, 4)
  assert_eq(baby_step_giant_step(bounded), None)
  let extended = instance_for(17, 3, 13, 5)
  assert_eq(
    baby_step_giant_step(extended).map(exponent),
    Some(@oracle.binary(4)),
  )
  assert_eq(check(bounded, @oracle.binary(4)), None)
  assert_eq(check(extended, @oracle.binary(3)), None)
  assert_eq(baby_step_giant_step(instance_for(7, 2, 3, 6)), None)
  assert_eq(
    baby_step_giant_step(instance_for(7, 2, 4, 64)).map(exponent),
    Some(@oracle.binary(2)),
  )
  assert_eq(
    baby_step_giant_step(instance_for(7, 1, 1, 1)).map(exponent),
    Some(@oracle.binary(0)),
  )
  assert_eq(baby_step_giant_step(instance_for(7, 1, 2, 100)), None)
  assert_eq(baby_step_giant_step(instance_for(2, 1, 1, 0)), None)
  assert_eq(
    baby_step_giant_step(instance_for(2, 1, 1, 1)).map(exponent),
    Some(@oracle.binary(0)),
  )
}

///|
test "multiplicative-group boundary normalizes units and rejects zero residues" {
  let f = @primefield.field(@oracle.binary(7)).unwrap()
  for (g, h) in [(0, 1), (7, 1), (1, 0), (1, 14)] {
    assert_eq(
      problem(f, @oracle.binary(g), @oracle.binary(h), @oracle.binary(6)),
      None,
    )
  }
  let raw = problem(f, @oracle.binary(9), @oracle.binary(11), @oracle.binary(6)).unwrap()
  assert_eq(base(raw), @oracle.binary(2))
  assert_eq(target(raw), @oracle.binary(4))
  assert_eq(limit(raw), @oracle.binary(6))
  assert_eq(field(raw), f)
  assert_eq(baby_step_giant_step(raw).map(exponent), Some(@oracle.binary(2)))
}
