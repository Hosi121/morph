///|
fn traced(machine : Machine, budget : Int32) -> (Status, Int32, Int32, Int32) {
  let mut status = Suspended(machine)
  let mut used = 0
  let mut rho = 0
  let mut witnesses = 0
  for _ in 0..<budget {
    match status {
      Suspended(machine) => {
        match machine.control {
          Rho(_, _) => rho = rho + 1
          Witness(_, _, _) => witnesses = witnesses + 1
          _ => ()
        }
        status = step(machine)
        used = used + 1
      }
      _ => break
    }
  }
  (status, used, rho, witnesses)
}

///|
test "sixty one and sixty four bit smooth predecessor primes bootstrap without external evidence" {
  for hex in ["1fffffffffffffff", "ffffffff00000001"] {
    let n = @oracle.binary_from_hex(hex)
    let machine = start(n, defaults()).unwrap()
    let (status, steps, rho, witnesses) = traced(machine, 20000)
    match status {
      Proven(proof) => inspect_proof(proof, n)
      _ => abort("large smooth proof must complete: \{hex}")
    }
    assert_true(steps < 20000)
    assert_true(witnesses > 0)
    if hex == "ffffffff00000001" {
      assert_true(rho > 0)
    }
  }
}

///|
test "large composite is returned only with a rechecked root witness" {
  let n = @oracle.binary_from_hex("e8d6ca6163")
  match run(start(n, defaults()).unwrap(), @oracle.nat(20000)) {
    Composite(proof) => {
      assert_eq(@primality.composite_value(proof), n)
      assert_eq(
        @primality.check_composite(n, @primality.composite_witness(proof)),
        Some(proof),
      )
    }
    _ => abort("fixed large semiprime must have a strong witness")
  }
}
