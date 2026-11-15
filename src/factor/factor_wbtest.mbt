///|
fn trajectory(n : Int32, seed : Int32, c : Int32) -> Machine {
  start(@oracle.binary(n), @oracle.binary(seed), @oracle.binary(c)).unwrap()
}

///|
fn checked_product(split : Split, n : Int32) -> Unit raise {
  assert_eq(number(split), @oracle.binary(n))
  assert_true(@oracle.int_of_binary(divisor(split)) > 1)
  assert_true(@oracle.int_of_binary(cofactor(split)) > 1)
  assert_eq(
    @binary.multiply(divisor(split), cofactor(split)),
    @oracle.binary(n),
  )
  assert_eq(check_factor(number(split), divisor(split)), Some(split))
}

///|
test "nontrivial factor checker agrees with independent small integer divisibility" {
  for n in 0..<128 {
    for d in 0..<132 {
      match check_factor(@oracle.binary(n), @oracle.binary(d)) {
        None => assert_false(d > 1 && d < n && n % d == 0)
        Some(split) => {
          assert_true(d > 1 && d < n && n % d == 0)
          assert_eq(@oracle.int_of_binary(cofactor(split)), n / d)
          checked_product(split, n)
        }
      }
    }
  }
}

///|
test "fixed rho seeds find nontrivial splits and every result rechecks" {
  for
    (n, c) in [
      (4, 1),
      (6, 1),
      (9, 1),
      (15, 1),
      (21, 2),
      (25, 2),
      (49, 1),
      (77, 1),
      (91, 1),
      (143, 1),
      (8051, 1),
      (10403, 1),
      (1022117, 1),
      (455459, 1),
    ] {
    match run(trajectory(n, 2, c), @oracle.nat(256)) {
      Found(split) => checked_product(split, n)
      _ => abort("rho fixture failed: \{n}")
    }
  }
}

///|
fn integer_gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = a.abs()
  let mut y = b.abs()
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
test "Floyd states and terminal decisions match an independent integer model" {
  for n in 2..<64 {
    for seed in 0..<4 {
      for c in 0..<4 {
        let mut machine = trajectory(n, seed, c)
        let mut slow = seed % n
        let mut fast = slow
        for index in 1..<=16 {
          if n > 2 && n % 2 == 0 {
            match step(machine) {
              Found(split) => assert_eq(divisor(split), @oracle.binary(2))
              _ => abort("even input must split")
            }
            break
          }
          slow = (slow * slow + c) % n
          fast = (fast * fast + c) % n
          fast = (fast * fast + c) % n
          let g = integer_gcd(slow - fast, n)
          match step(machine) {
            Suspended(next) => {
              assert_eq(g, 1)
              assert_eq(@oracle.int_of_binary(next.slow), slow)
              assert_eq(@oracle.int_of_binary(next.fast), fast)
              assert_eq(@oracle.int_of_nat(iterations(next)), index)
              machine = next
            }
            Failed(next) => {
              assert_eq(g, n)
              assert_eq(@oracle.int_of_nat(iterations(next)), index)
              break
            }
            Found(split) => {
              assert_true(g > 1 && g < n)
              assert_eq(divisor(split), @oracle.binary(g))
              checked_product(split, n)
              break
            }
          }
        }
      }
    }
  }
}

///|
test "zero fuel and segmented execution preserve the exact Floyd state" {
  let machine = trajectory(1022117, 2, 1)
  assert_eq(run(machine, @oracle.nat(0)), Suspended(machine))
  for budget in 0..<20 {
    let once = run(machine, @oracle.nat(budget))
    let mut chunked = Suspended(machine)
    for _ in 0..<budget {
      chunked = match chunked {
        Suspended(next) => run(next, @oracle.nat(1))
        result => result
      }
    }
    assert_eq(chunked, once)
    match once {
      Suspended(next) => assert_eq(@oracle.int_of_nat(iterations(next)), budget)
      _ => ()
    }
  }
  let first = run(machine, @oracle.nat(7))
  match first {
    Suspended(next) =>
      assert_eq(run(next, @oracle.nat(249)), run(machine, @oracle.nat(256)))
    _ => abort("fixture must suspend")
  }
}

///|
test "failed seed is explicit and fresh deterministic parameters can recover" {
  let failed = run(trajectory(91, 1, 0), @oracle.nat(1))
  match failed {
    Failed(machine) => {
      assert_eq(@oracle.int_of_nat(iterations(machine)), 1)
      assert_eq(target(machine), @oracle.binary(91))
      assert_eq(
        run(machine, @oracle.nat(1)),
        Failed({ ..machine, iterations: @oracle.nat(2), }),
      )
    }
    _ => abort("constant orbit must fail")
  }
  match run(trajectory(91, 2, 1), @oracle.nat(20)) {
    Found(split) => checked_product(split, 91)
    _ => abort("replacement seed must find factor")
  }
  assert_eq(
    start(@oracle.binary(0), @oracle.binary(2), @oracle.binary(1)),
    None,
  )
  assert_eq(
    start(@oracle.binary(1), @oracle.binary(2), @oracle.binary(1)),
    None,
  )
}

///|
test "prime targets can fail or suspend but never produce a nontrivial factor" {
  for n in [2, 3, 5, 7, 11, 17, 31, 127] {
    for seed in 0..<6 {
      match run(trajectory(n, seed, 1), @oracle.nat(64)) {
        Found(_) => abort("prime cannot split")
        _ => ()
      }
    }
  }
}
