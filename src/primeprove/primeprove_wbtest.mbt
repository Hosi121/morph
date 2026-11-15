///|
fn begun(n : Int32, config : Config) -> Machine {
  start(@oracle.binary(n), config).unwrap()
}

///|
fn inspect_proof(proof : Proof, expected : @binary.Binary) -> Unit raise {
  assert_eq(@primality.value(prime(proof)), expected)
  assert_eq(@primality.check(certificate(proof)), Some(prime(proof)))
  assert_eq(@primality.candidate(certificate(proof)), expected)
}

///|
test "small numbers are proved or carry an independently rechecked composite witness" {
  for n in 2..<128 {
    let mut expected = true
    for divisor in 2..<n {
      if n % divisor == 0 {
        expected = false
      }
    }
    match run(begun(n, defaults()), @oracle.nat(5000)) {
      Proven(proof) => {
        assert_true(expected)
        inspect_proof(proof, @oracle.binary(n))
      }
      Composite(proof) => {
        assert_false(expected)
        assert_eq(@primality.composite_value(proof), @oracle.binary(n))
        assert_eq(
          @primality.check_composite(
            @oracle.binary(n),
            @primality.composite_witness(proof),
          ),
          Some(proof),
        )
      }
      _ => abort("small configured proof search must resolve: \{n}")
    }
  }
  assert_eq(start(@oracle.binary(0), defaults()), None)
  assert_eq(start(@oracle.binary(1), defaults()), None)
}

///|
test "fuel zero and one-step chunks preserve exact proof-generation progress" {
  let machine = begun(65537, defaults())
  assert_eq(run(machine, @oracle.nat(0)), Suspended(machine))
  for budget in [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233] {
    let mut chunked = Suspended(machine)
    for _ in 0..<budget {
      chunked = match chunked {
        Suspended(next) => run(next, @oracle.nat(1))
        result => result
      }
    }
    assert_eq(chunked, run(machine, @oracle.nat(budget)))
  }
  match run(machine, @oracle.nat(20)) {
    Suspended(next) =>
      assert_eq(run(next, @oracle.nat(4980)), run(machine, @oracle.nat(5000)))
    _ => abort("fixture must need more than twenty transitions")
  }
}

///|
test "smooth predecessor primes generate their own complete Lucas trees" {
  for n in [257, 65537, 998244353] {
    match run(begun(n, defaults()), @oracle.nat(20000)) {
      Proven(proof) => inspect_proof(proof, @oracle.binary(n))
      _ => abort("smooth predecessor proof must complete: \{n}")
    }
  }
}

///|
test "finite failed rho seeds give inconclusive and explicit strategy restart can recover" {
  let base = defaults()
  let bad : Config = {
    ..base,
    trial_limit: @binary.zero(),
    seeds: Cons((@binary.one(), @binary.zero()), Nil),
  }
  match run(begun(31, bad), @oracle.nat(5000)) {
    Inconclusive(reason, machine) => {
      assert_eq(reason, NoFactor(@oracle.binary(15)))
      assert_eq(subject(machine), @oracle.binary(31))
      assert_eq(run(machine, @oracle.nat(1)), Inconclusive(reason, machine))
      match run(restart(machine, defaults()), @oracle.nat(5000)) {
        Proven(proof) => inspect_proof(proof, @oracle.binary(31))
        _ => abort("default strategy must recover")
      }
    }
    _ => abort("degenerate seed alone cannot resolve the factor fifteen")
  }
  let rho_only : Config = { ..base, trial_limit: @binary.zero(), }
  match run(begun(31, rho_only), @oracle.nat(5000)) {
    Proven(proof) => inspect_proof(proof, @oracle.binary(31))
    _ =>
      abort("configured rho without small trials must factor the predecessor")
  }
}

///|
test "passing a strong pseudoprime screen never becomes a prime verdict" {
  let base = defaults()
  let weak : Config = { ..base, bases: Cons(@oracle.binary(2), Nil), }
  match run(begun(2047, weak), @oracle.nat(5000)) {
    Proven(_) => abort("strong pseudoprime cannot acquire a Lucas proof")
    Composite(proof) =>
      assert_eq(@primality.composite_value(proof), @oracle.binary(2047))
    Suspended(_) | Inconclusive(_, _) => ()
  }
}
