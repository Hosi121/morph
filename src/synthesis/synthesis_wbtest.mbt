///|
fn small_table(inputs : Int32, bits : Int32) -> Table {
  table(
    @oracle.nat(inputs),
    @oracle.chain(
      Array::makei(1 << inputs, fn(row) { (bits & (1 << row)) != 0 }),
    ),
  ).unwrap()
}

///|
// Independent native enumeration of every topological NAND program. No CNF.
fn possible_tables(inputs : Int32, limit : Int32) -> Array[Bool] {
  let rows = 1 << inputs
  let mask = (1 << rows) - 1
  let found = Array::make(1 << rows, false)
  let primary = Array::makei(inputs, fn(input) {
    let mut bits = 0
    for row in 0..<rows {
      if (row & (1 << (inputs - input - 1))) != 0 {
        bits = bits | (1 << row)
      }
    }
    bits
  })
  fn enumerate(values : Array[Int32], remaining : Int32) -> Unit {
    for value in values {
      found[value] = true
    }
    if remaining > 0 {
      for left in 0..<values.length() {
        for right in left..<values.length() {
          let next = values.copy()
          next.push((values[left] & values[right]) ^ mask)
          enumerate(next, remaining - 1)
        }
      }
    }
  }
  enumerate(primary, limit)
  found
}

///|
test "all two-input functions through five gates agree with program enumeration" {
  let fuel = @oracle.nat(100000)
  for limit in 0..<=5 {
    let expected = possible_tables(2, limit)
    for bits in 0..<16 {
      let spec = small_table(2, bits)
      let problem = problem(spec, @oracle.nat(limit))
      match run(start(problem), fuel) {
        Found(net) => {
          assert_true(expected[bits])
          assert_true(check_network(spec, net))
          assert_eq(@oracle.int_of_nat(@core.length(gates(net))), limit)
        }
        Impossible(proof) => {
          assert_false(expected[bits])
          assert_true(check_impossibility(problem, proof))
        }
        Paused(_) => fail("small synthesis exhausted fuel")
        InvariantViolation => fail("invalid model or proof")
      }
    }
  }
}

///|
test "XOR has a four-NAND witness and a checked three-gate lower bound" {
  let spec = small_table(2, 6)
  let larger = problem(spec, @oracle.nat(4))
  let fuel = @oracle.nat(100000)
  match run(start(larger), fuel) {
    Found(net) => {
      assert_true(check_network(spec, net))
      for row in 0..<4 {
        let inputs = @oracle.chain([(row & 2) != 0, (row & 1) != 0])
        assert_eq(evaluate(net, inputs), Some(row == 1 || row == 2))
      }
    }
    _ => fail("four NANDs must implement XOR")
  }
  let smaller = problem(spec, @oracle.nat(3))
  match run(start(smaller), fuel) {
    Impossible(proof) => {
      assert_true(check_impossibility(smaller, proof))
      assert_false(check_impossibility(larger, proof))
    }
    _ => fail("three NANDs cannot implement XOR")
  }
}

///|
test "resumption and malformed network boundaries" {
  let spec = small_table(2, 7)
  let problem = problem(spec, @core.Succ(Zero))
  let search = start(problem)
  match run(search, Zero) {
    Paused(search) =>
      match run(search, @oracle.nat(1000)) {
        Found(net) => assert_true(check_network(spec, net))
        _ => fail("one NAND should suffice")
      }
    _ => fail("zero fuel must pause")
  }
  assert_eq(table(@core.Succ(Zero), @core.Nil), None)
  assert_eq(network(Zero, @core.Nil, Input(Zero)), None)
  assert_eq(
    network(
      @core.Succ(Zero),
      @core.Cons({ left: Gate(Zero), right: Input(Zero), }, Nil),
      Gate(Zero),
    ),
    None,
  )
  let identity = network(@core.Succ(Zero), @core.Nil, Input(Zero)).unwrap()
  assert_eq(evaluate(identity, @core.Nil), None)
  assert_eq(evaluate(identity, @core.Cons(true, Nil)), Some(true))
  assert_false(check_network(small_table(1, 1), identity))
  assert_eq(decode(problem, @core.Nil), None)
  assert_false(check_impossibility(problem, @cdcl.Rup(@core.Nil)))
}

///|
test "no implicit constants or wires in a zero-input library" {
  for constant in 0..<2 {
    for limit in 0..<=2 {
      let problem = problem(small_table(0, constant), @oracle.nat(limit))
      match run(start(problem), @oracle.nat(1000)) {
        Impossible(proof) => assert_true(check_impossibility(problem, proof))
        _ => fail("no available input for NAND")
      }
    }
  }
}
