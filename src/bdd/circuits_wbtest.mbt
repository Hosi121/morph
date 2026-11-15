///|
fn adder_order(width : Int32, interleaved : Bool) -> @core.Chain[@core.Nat] {
  let result = []
  if interleaved {
    for bit in 0..<width {
      result.push(bit)
      result.push(width + bit)
    }
  } else {
    for variable in 0..<(width + width) {
      result.push(variable)
    }
  }
  result.push(width + width)
  labels(result)
}

///|
fn carry_expression(width : Int32) -> @circuit.Expr {
  @core.last(@circuit.adder_outputs(@oracle.nat(width), Propagate)).unwrap()
}

///|
fn mismatch_expression(width : Int32) -> @circuit.Expr {
  let left = @circuit.adder_outputs(@oracle.nat(width), Propagate)
  let right = @circuit.adder_outputs(@oracle.nat(width), Multiplexer)
  @core.fold_left(@core.zip(left, right).unwrap(), @circuit.Constant(false), fn(
    expression,
    pair,
  ) {
    let (left, right) = pair
    @circuit.Disjunction(expression, @circuit.Exclusive(left, right))
  })
}

///|
test "adder equivalence agrees with full truth tables and both SAT engines" {
  for width in 0..<=4 {
    let expression = mismatch_expression(width)
    for interleaved in [false, true] {
      let diagram = compile(expression, adder_order(width, interleaved)).unwrap()
      check_diagram(diagram, expression, width + width + 1)
      assert_true(same_edge(diagram.root, Terminal(false)))
      assert_eq(node_count(diagram), Some(@core.Zero))
    }
    let encoding = @circuit.adder_miter(
      @oracle.nat(width),
      Propagate,
      Multiplexer,
    ).unwrap()
    let formula = @circuit.cnf(encoding)
    match @sat.solve(formula) {
      Unsatisfiable(proof) => assert_true(@sat.check_refutation(formula, proof))
      _ => fail("old DPLL must refute the equivalent adders")
    }
    match @cdcl.run(@cdcl.start(formula), @oracle.nat(20000)) {
      Unsatisfiable(proof) =>
        assert_true(@cdcl.check_refutation(formula, proof))
      _ => fail("CDCL must refute the equivalent adders")
    }
  }
}

///|
test "carry ROBDD order dependence preserves exact arithmetic truth tables" {
  let observations = []
  for width in [1, 2, 4, 6] {
    let expression = carry_expression(width)
    let blocked = compile(expression, adder_order(width, false)).unwrap()
    let interleaved = compile(expression, adder_order(width, true)).unwrap()
    assert_true(valid(blocked))
    assert_true(valid(interleaved))
    let mask = (1 << width) - 1
    for row in 0..<(1 << (width + width + 1)) {
      let a = row & mask
      let b = (row >> width) & mask
      let carry = (row >> (width + width)) & 1
      let expected = (a + b + carry) >> width != 0
      let assignment = model(width + width + 1, row)
      assert_eq(evaluate(blocked, assignment), Some(expected))
      assert_eq(evaluate(interleaved, assignment), Some(expected))
    }
    observations.push([
      width,
      @oracle.int_of_nat(node_count(blocked).unwrap()),
      @oracle.int_of_nat(node_count(interleaved).unwrap()),
      @oracle.int_of_binary(allocated_count(blocked)),
      @oracle.int_of_binary(allocated_count(interleaved)),
    ])
  }
  debug_inspect(
    observations,
    content=(
      #|[
      #|  [1, 4, 4, 11, 11],
      #|  [2, 11, 10, 31, 28],
      #|  [4, 53, 22, 163, 98],
      #|  [6, 221, 34, 709, 216],
      #|]
    ),
  )
}

///|
test "carry width eight with blocked variables" (b : @bench.T) {
  let expression = carry_expression(8)
  let ordering = adder_order(8, false)
  let example = compile(expression, ordering).unwrap()
  println(
    "blocked width=8, reachable=\{@oracle.int_of_nat(node_count(example).unwrap())}, allocated=\{@oracle.int_of_binary(allocated_count(example))}",
  )
  b.bench(fn() { b.keep(compile(expression, ordering)) })
}

///|
test "same carry width eight with interleaved variables" (b : @bench.T) {
  let expression = carry_expression(8)
  let ordering = adder_order(8, true)
  let example = compile(expression, ordering).unwrap()
  println(
    "interleaved width=8, reachable=\{@oracle.int_of_nat(node_count(example).unwrap())}, allocated=\{@oracle.int_of_binary(allocated_count(example))}",
  )
  b.bench(fn() { b.keep(compile(expression, ordering)) })
}
