///|
fn review_table(inputs : Int32, bits : Int32) -> Table {
  table(
    @oracle.nat(inputs),
    @oracle.chain([ for row in 0..<(1 << inputs) => (bits & (1 << row)) != 0 ]),
  ).unwrap()
}

///|
/// Independent bit-parallel native programs. Both orders of each NAND input
/// pair are enumerated, rather than reusing the encoder's triangular options.
fn review_possible(inputs : Int32, limit : Int32) -> Array[Bool] {
  let rows = 1 << inputs
  let mask = (1 << rows) - 1
  let reachable = Array::make(1 << rows, false)
  let primary = [
    for input in 0..<inputs => {
      let mut bits = 0
      for row in 0..<rows {
        if (row & (1 << (inputs - input - 1))) != 0 {
          bits = bits | (1 << row)
        }
      }
      bits
    }
  ]
  fn enumerate(values : Array[Int32], remaining : Int32) -> Unit {
    for bits in values {
      reachable[bits] = true
    }
    if remaining > 0 {
      for left in values {
        for right in values {
          let extended = values.copy()
          extended.push((left & right) ^ mask)
          enumerate(extended, remaining - 1)
        }
      }
    }
  }
  enumerate(primary, limit)
  reachable
}

///|
fn review_numeric_cnf(
  formula : @sat.Cnf,
) -> (Array[Array[(Int32, Bool)]], Int32) {
  let clauses = @oracle.array(formula).map(fn(clause) {
    @oracle.array(clause).map(fn(literal) {
      (@oracle.int_of_nat(literal.variable), literal.positive)
    })
  })
  let mut variables = 0
  for clause in clauses {
    for pair in clause {
      let (variable, _) = pair
      variables = variables.max(variable + 1)
    }
  }
  (clauses, variables)
}

///|
fn review_satisfied(
  clauses : Array[Array[(Int32, Bool)]],
  mask : Int32,
) -> Bool {
  clauses.all(fn(clause) {
    clause.any(fn(pair) {
      let (variable, positive) = pair
      ((mask & (1 << variable)) != 0) == positive
    })
  })
}

///|
fn review_model(variables : Int32, mask : Int32) -> @sat.Model {
  @oracle.chain(
    [
      for variable in 0..<variables => {
        @sat.Literal::{
          variable: @oracle.nat(variable),
          positive: (mask & (1 << variable)) != 0,
        }
      }
    ],
  )
}

///|
fn review_network_bits(net : Network) -> Int32 raise {
  let count = @oracle.int_of_nat(input_count(net))
  let program = @oracle.array(gates(net))
  let mut bits = 0
  fn read(
    wire : Wire,
    inputs : Array[Bool],
    values : Array[Bool],
  ) -> Bool raise {
    match wire {
      Input(index) => {
        let index = @oracle.int_of_nat(index)
        assert_true(index < inputs.length())
        inputs[index]
      }
      Gate(index) => {
        let index = @oracle.int_of_nat(index)
        assert_true(index < values.length())
        values[index]
      }
    }
  }
  for row in 0..<(1 << count) {
    let inputs = [
      for input in 0..<count => (row & (1 << (count - input - 1))) != 0
    ]
    let values = []
    for gate in program {
      let left = read(gate.left, inputs, values)
      let right = read(gate.right, inputs, values)
      values.push(!(left && right))
    }
    let result = read(output(net), inputs, values)
    assert_eq(evaluate(net, @oracle.chain(inputs)), Some(result))
    if result {
      bits = bits | (1 << row)
    }
  }
  bits
}

///|
test "review complete CNF-model enumeration agrees with native NAND programs" {
  // The largest complete Boolean enumeration here has eleven CNF variables.
  for (inputs, maximum) in [(0, 2), (1, 2), (2, 1), (3, 0)] {
    for limit in 0..<=maximum {
      let expected = review_possible(inputs, limit)
      for bits in 0..<expected.length() {
        let spec = review_table(inputs, bits)
        let task = problem(spec, @oracle.nat(limit))
        let (clauses, variables) = review_numeric_cnf(cnf(task))
        assert_true(variables <= 11)
        let mut found = false
        for mask in 0..<(1 << variables) {
          if review_satisfied(clauses, mask) {
            found = true
            let model = review_model(variables, mask)
            assert_true(@sat.check_model(cnf(task), model))
            match decode(task, model) {
              None => fail("a complete satisfying model failed decoding")
              Some(net) => {
                assert_eq(review_network_bits(net), bits)
                assert_true(check_network(spec, net))
                assert_true(
                  @oracle.int_of_nat(@core.length(gates(net))) <= limit,
                )
              }
            }
          }
        }
        assert_eq(found, expected[bits])
      }
    }
  }
}

///|
test "review assignments and malformed table lengths include the zero-input row" {
  for inputs in 0..<=5 {
    let rows = @oracle.array(assignments(@oracle.nat(inputs))).map(
      @oracle.array,
    )
    assert_eq(rows.length(), 1 << inputs)
    for row, values in rows {
      assert_eq(values.length(), inputs)
      for input, value in values {
        assert_eq(value, (row & (1 << (inputs - input - 1))) != 0)
      }
    }
    assert_true(
      table(
        @oracle.nat(inputs),
        @oracle.chain(Array::make((1 << inputs) - 1, false)),
      )
      is None,
    )
    assert_true(
      table(
        @oracle.nat(inputs),
        @oracle.chain(Array::make((1 << inputs) + 1, false)),
      )
      is None,
    )
  }
  assert_true(table(@core.Zero, @core.Nil) is None)
  assert_true(table(@core.Zero, @core.Cons(false, Nil)) is Some(_))
  assert_true(table(@core.Zero, @core.Cons(true, Nil)) is Some(_))
}

///|
test "review network validation rejects every invalid two-gate wire boundary" {
  let z = @core.Zero
  let one = @oracle.nat(1)
  let two = @oracle.nat(2)
  let valid_first : Nand = { left: Input(z), right: Input(z), }
  for invalid in [Input(one), Input(two), Gate(z), Gate(one), Gate(two)] {
    assert_true(
      network(
        one,
        @oracle.chain([{ left: invalid, right: Input(z), }]),
        Gate(z),
      )
      is None,
    )
    assert_true(
      network(
        one,
        @oracle.chain([{ left: Input(z), right: invalid, }]),
        Gate(z),
      )
      is None,
    )
  }
  for invalid in [Input(one), Input(two), Gate(one), Gate(two)] {
    assert_true(
      network(
        one,
        @oracle.chain([valid_first, { left: invalid, right: Gate(z), }]),
        Gate(one),
      )
      is None,
    )
    assert_true(
      network(
        one,
        @oracle.chain([valid_first, { left: Gate(z), right: invalid, }]),
        Gate(one),
      )
      is None,
    )
  }
  for invalid in [Input(one), Input(two), Gate(two), Gate(@oracle.nat(3))] {
    assert_true(
      network(
        one,
        @oracle.chain([valid_first, { left: Gate(z), right: Gate(z), }]),
        invalid,
      )
      is None,
    )
  }
  for output in [Input(z), Gate(z)] {
    assert_true(network(z, @core.Nil, output) is None)
  }
  let net = network(one, @oracle.chain([valid_first]), Gate(z)).unwrap()
  assert_eq(evaluate(net, @core.Nil), None)
  assert_eq(evaluate(net, @oracle.chain([false, false])), None)
  assert_eq(review_network_bits(net), 1)
}

///|
fn review_result(
  outcome : Outcome,
  spec : Table,
  task : Problem,
) -> (Network?, @cdcl.Proof?) raise {
  match outcome {
    Found(net) => {
      assert_true(check_network(spec, net))
      let expected = @oracle.array(truth_table(spec))
      let bits = review_network_bits(net)
      for row, value in expected {
        assert_eq((bits & (1 << row)) != 0, value)
      }
      (Some(net), None)
    }
    Impossible(proof) => {
      assert_true(check_impossibility(task, proof))
      (None, Some(proof))
    }
    _ => fail("review synthesis search did not terminate")
  }
}

///|
test "review zero fuel immutable resumption and at-most bounds for all unary tables" {
  for limit in 0..<=5 {
    let expected = review_possible(1, limit)
    for bits in 0..<4 {
      let spec = review_table(1, bits)
      let task = problem(spec, @oracle.nat(limit))
      let initial = start(task)
      assert_true(run(initial, @core.Zero) is Paused(_))
      let whole = review_result(run(initial, @oracle.nat(100000)), spec, task)
      let resumed = for state = initial, transitions = 0 {
        assert_true(transitions < 100000)
        match run(state, @oracle.nat(1)) {
          Paused(next) => continue next, transitions + 1
          terminal => break review_result(terminal, spec, task)
        }
      }
      assert_eq(resumed, whole)
      assert_eq(
        review_result(run(initial, @oracle.nat(100000)), spec, task),
        whole,
      )
      let (found, _) = whole
      assert_eq(found is Some(_), expected[bits])
    }
  }
}

///|
test "review decode rejects missing contradictory and multiple topology selectors" {
  let spec = review_table(2, 7)
  let task = problem(spec, @oracle.nat(1))
  let model = match @cdcl.run(@cdcl.start(cnf(task)), @oracle.nat(10000)) {
    Satisfiable(model) => model
    _ => fail("NAND synthesis CNF must be satisfiable")
  }
  assert_true(decode(task, model) is Some(_))
  assert_true(decode(task, @core.Nil) is None)
  for literal in @oracle.array(model) {
    assert_true(decode(task, @core.Cons(@sat.negate(literal), model)) is None)
  }
  match task.stages {
    Cons(choices, _) => {
      let choices = @oracle.array(choices)
      assert_true(choices.length() > 1)
      let selectors = choices.map(fn(choice) { choice.literal.variable })
      let doubled = @core.map(model, fn(literal) {
        if selectors.any(fn(variable) { variable.equal(literal.variable) }) {
          { ..literal, positive: true, }
        } else {
          literal
        }
      })
      assert_true(decode(task, doubled) is None)
    }
    _ => fail("one gate must have topology selectors")
  }
  assert_false(check_impossibility(task, @cdcl.Rup(@core.Nil)))
  assert_false(check_impossibility(task, @cdcl.Rup(@core.Cons(@core.Nil, Nil))))
  let no_inputs = problem(review_table(0, 0), @oracle.nat(0))
  assert_true(
    check_impossibility(no_inputs, @cdcl.Rup(@core.Cons(@core.Nil, Nil))),
  )
}

///|
test "review one-hot clauses exactly match a single selected bit including no choices" {
  for size in 0..<=6 {
    let literals = @oracle.chain(
      [
        for variable in 0..<size => {
          @sat.Literal::{ variable: @oracle.nat(variable), positive: true, }
        }
      ],
    )
    let initial = Builder::{ next: @oracle.nat(size), clauses_rev: @core.Nil, }
    let encoded = one_hot(literals, initial)
    let (clauses, _) = review_numeric_cnf(encoded.clauses_rev)
    for mask in 0..<(1 << size) {
      let selected = [
        for variable in 0..<size if (mask & (1 << variable)) != 0 => variable
      ]
      assert_eq(review_satisfied(clauses, mask), selected.length() == 1)
    }
  }
}

///|
test "review guarded NAND clauses match every fixed and prior-gate signal valuation" {
  let candidates : Array[Wire] = [
    Input(@oracle.nat(0)),
    Input(@oracle.nat(1)),
    Gate(@oracle.nat(0)),
    Gate(@oracle.nat(1)),
  ]
  let literal = fn(variable) {
    @sat.Literal::{ variable: @oracle.nat(variable), positive: true, }
  }
  let initial = Builder::{ next: @oracle.nat(4), clauses_rev: @core.Nil, }
  for inputs in 0..<4 {
    let row = Row::{
      inputs: @oracle.chain([(inputs & 1) != 0, (inputs & 2) != 0]),
      values: @oracle.chain([literal(0), literal(1)]),
    }
    for left in candidates {
      for right in candidates {
        let choice = Choice::{
          literal: literal(2),
          gate: Nand::{ left, right, },
        }
        let encoded = gate_constraints(
          @core.Cons(choice, Nil),
          row,
          literal(3),
          initial,
        )
        let (clauses, _) = review_numeric_cnf(encoded.clauses_rev)
        for mask in 0..<16 {
          let read = fn(wire) {
            match wire {
              Input(index) => (inputs & (1 << @oracle.int_of_nat(index))) != 0
              Gate(index) => (mask & (1 << @oracle.int_of_nat(index))) != 0
            }
          }
          let selected = (mask & 4) != 0
          let output = (mask & 8) != 0
          let expected = !selected || output == !(read(left) && read(right))
          assert_eq(review_satisfied(clauses, mask), expected)
        }
      }
    }
  }
}
