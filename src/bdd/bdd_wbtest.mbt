///|
fn source(variable : Int32) -> @circuit.Expr {
  @circuit.Variable(@oracle.nat(variable))
}

///|
fn labels(values : Array[Int32]) -> @core.Chain[@core.Nat] {
  @oracle.chain(values.map(@oracle.nat))
}

///|
fn model(variables : Int32, mask : Int32) -> @sat.Model {
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
fn direct(expression : @circuit.Expr, mask : Int32) -> Bool {
  match expression {
    Constant(value) => value
    Variable(variable) => (mask & (1 << @oracle.int_of_nat(variable))) != 0
    Negation(value) => !direct(value, mask)
    Conjunction(left, right) => direct(left, mask) && direct(right, mask)
    Disjunction(left, right) => direct(left, mask) || direct(right, mask)
    Exclusive(left, right) => direct(left, mask) != direct(right, mask)
    Select(condition, when_true, when_false) =>
      if direct(condition, mask) {
        direct(when_true, mask)
      } else {
        direct(when_false, mask)
      }
  }
}

///|
fn dnf(variables : Int32, bits : Int32) -> @circuit.Expr {
  let mut expression = @circuit.Constant(false)
  for row in 0..<(1 << variables) {
    if (bits & (1 << row)) != 0 {
      let mut term = @circuit.Constant(true)
      for variable in 0..<variables {
        let literal = if (row & (1 << variable)) != 0 {
          source(variable)
        } else {
          @circuit.Negation(source(variable))
        }
        term = @circuit.Conjunction(term, literal)
      }
      expression = @circuit.Disjunction(expression, term)
    }
  }
  expression
}

///|
fn shannon(variables : Int32, bits : Int32) -> @circuit.Expr {
  fn visit(variable : Int32, row : Int32) -> @circuit.Expr {
    if variable == variables {
      @circuit.Constant((bits & (1 << row)) != 0)
    } else {
      @circuit.Select(
        source(variable),
        visit(variable + 1, row | (1 << variable)),
        visit(variable + 1, row),
      )
    }
  }
  visit(0, 0)
}

///|
fn check_diagram(
  diagram : Diagram,
  expression : @circuit.Expr,
  variables : Int32,
) -> Unit raise {
  assert_true(valid(diagram))
  assert_true(node_count(diagram) is Some(_))
  let mut satisfiable = false
  for mask in 0..<(1 << variables) {
    let expected = direct(expression, mask)
    let assignment = model(variables, mask)
    assert_eq(evaluate(diagram, assignment), Some(expected))
    assert_eq(@circuit.evaluate(expression, assignment), Some(expected))
    satisfiable = satisfiable || expected
  }
  match pick_model(diagram) {
    None => assert_false(satisfiable)
    Some(assignment) => {
      assert_true(satisfiable)
      assert_eq(evaluate(diagram, assignment), Some(true))
      assert_eq(@circuit.evaluate(expression, assignment), Some(true))
    }
  }
}

///|
test "every three-variable function compiles canonically in all six explicit orders" {
  for bits in 0..<256 {
    let expression = dnf(3, bits)
    let alternative = shannon(3, bits)
    for
      order in [
        [0, 1, 2],
        [0, 2, 1],
        [1, 0, 2],
        [1, 2, 0],
        [2, 0, 1],
        [2, 1, 0],
      ] {
      let diagram = compile(expression, labels(order)).unwrap()
      let second = compile(alternative, labels(order)).unwrap()
      check_diagram(diagram, expression, 3)
      assert_eq(equivalent(diagram, second), Some(true))
      assert_eq(node_count(diagram), node_count(second))
      assert_true(@oracle.int_of_nat(node_count(diagram).unwrap()) <= 7)
      let negative = negate(diagram).unwrap()
      assert_true(valid(negative))
      for mask in 0..<8 {
        assert_eq(
          evaluate(negative, model(3, mask)),
          Some((bits & (1 << mask)) == 0),
        )
      }
    }
  }
}

///|
test "binary apply imports distinct managers before comparing their colliding IDs" {
  let order = labels([0, 1])
  let x = compile(source(0), order).unwrap()
  let y = compile(source(1), order).unwrap()
  assert_true(same_edge(x.root, y.root))
  assert_eq(equivalent(x, y), Some(false))
  let both = apply(Conjunction, x, y).unwrap()
  check_diagram(both, @circuit.Conjunction(source(0), source(1)), 2)
  let either = compile(@circuit.Disjunction(source(0), source(1)), order).unwrap()
  let direct_both = compile(@circuit.Conjunction(source(0), source(1)), order).unwrap()
  assert_true(same_edge(either.root, direct_both.root))
  assert_eq(equivalent(either, direct_both), Some(false))
  assert_eq(equivalent(both, direct_both), Some(true))
  let saved = node_count(x)
  let _ = apply(Exclusive, x, y).unwrap()
  assert_eq(node_count(x), saved)
  check_diagram(x, source(0), 2)
}

///|
test "all pairs of two-variable functions agree under every binary operation" {
  for order in [[0, 1], [1, 0]] {
    for left in 0..<16 {
      for right in 0..<16 {
        let a = compile(dnf(2, left), labels(order)).unwrap()
        let b = compile(shannon(2, right), labels(order)).unwrap()
        for operation in [Conjunction, Disjunction, Exclusive] {
          let result = apply(operation, a, b).unwrap()
          assert_true(valid(result))
          let expected = match operation {
            Conjunction => left & right
            Disjunction => left | right
            Exclusive => left ^ right
          }
          for mask in 0..<4 {
            assert_eq(
              evaluate(result, model(2, mask)),
              Some((expected & (1 << mask)) != 0),
            )
          }
        }
      }
    }
  }
}

///|
test "restriction agrees with Boolean substitution for every small function and variable" {
  for bits in 0..<256 {
    for ordering in [[0, 1, 2], [2, 1, 0]] {
      let diagram = compile(shannon(3, bits), labels(ordering)).unwrap()
      for variable in 0..<3 {
        for positive in [false, true] {
          let result = restrict(diagram, {
            variable: @oracle.nat(variable),
            positive,
          }).unwrap()
          assert_true(valid(result))
          assert_eq(order(result), labels(ordering))
          for mask in 0..<8 {
            let substituted = if positive {
              mask | (1 << variable)
            } else {
              mask & (7 ^ (1 << variable))
            }
            assert_eq(
              evaluate(result, model(3, mask)),
              Some((bits & (1 << substituted)) != 0),
            )
          }
        }
      }
    }
  }
}

///|
test "empty duplicate missing sparse and incompatible variable orders have explicit boundaries" {
  let empty = @core.Nil
  let truth = compile(@circuit.Constant(true), empty).unwrap()
  let falsehood = compile(@circuit.Constant(false), empty).unwrap()
  assert_eq(node_count(truth), Some(@core.Zero))
  assert_eq(node_count(falsehood), Some(@core.Zero))
  assert_eq(pick_model(truth), Some(@core.Nil))
  assert_eq(pick_model(falsehood), None)
  assert_eq(evaluate(truth, @core.Nil), Some(true))
  assert_true(compile(source(0), empty) is None)
  assert_true(compile(@circuit.Constant(false), labels([0, 0])) is None)
  let x = compile(source(0), labels([0, 1])).unwrap()
  let reversed = compile(source(0), labels([1, 0])).unwrap()
  assert_true(apply(Conjunction, x, reversed) is None)
  assert_eq(equivalent(x, reversed), None)
  assert_true(
    restrict(x, { variable: @oracle.nat(2), positive: true, }) is None,
  )
  assert_eq(evaluate(x, @core.Nil), None)
  assert_eq(
    evaluate(
      x,
      @oracle.chain([
        { variable: @oracle.nat(0), positive: true, },
        { variable: @oracle.nat(0), positive: false, },
      ]),
    ),
    None,
  )
  let sparse_order = labels([65535])
  let sparse = compile(source(65535), sparse_order).unwrap()
  assert_true(valid(sparse))
  let assignment = pick_model(sparse).unwrap()
  assert_eq(evaluate(sparse, assignment), Some(true))
  assert_eq(@circuit.evaluate(source(65535), assignment), Some(true))
}

///|
test "BDD satisfiability agrees with old DPLL and a truth table on all three-variable functions" {
  for bits in 0..<256 {
    let expression = dnf(3, bits)
    let diagram = compile(expression, labels([0, 1, 2])).unwrap()
    let encoding = @circuit.compile(@core.Cons(expression, Nil))
    let formula = @circuit.cnf(encoding)
    match @sat.solve(formula) {
      Satisfiable(assignment) => {
        assert_true(bits != 0)
        assert_true(@sat.check_model(formula, assignment))
        assert_true(pick_model(diagram) is Some(_))
      }
      Unsatisfiable(proof) => {
        assert_eq(bits, 0)
        assert_true(@sat.check_refutation(formula, proof))
        assert_true(pick_model(diagram) is None)
      }
    }
  }
}

///|
test "structural checker rejects missing decisions and unreduced or misordered nodes" {
  let diagram = compile(
    @circuit.Conjunction(source(0), source(1)),
    labels([0, 1]),
  ).unwrap()
  assert_true(valid(diagram))
  let missing = { ..diagram, root: Decision(diagram.manager.next), }
  assert_false(valid(missing))
  assert_true(node_count(missing) is None)
  assert_eq(evaluate(missing, model(2, 0)), None)
  match diagram.root {
    Terminal(_) => fail("conjunction must have a decision")
    Decision(id) => {
      let node = lookup(diagram.manager.nodes, @binary.bits(id)).unwrap()
      let unreduced = { ..node, high: node.low, }
      let manager = {
        ..diagram.manager,
        nodes: insert(diagram.manager.nodes, @binary.bits(id), unreduced),
      }
      assert_false(valid({ ..diagram, manager, }))
      let cycle = { ..node, low: diagram.root, }
      let manager = {
        ..diagram.manager,
        nodes: insert(diagram.manager.nodes, @binary.bits(id), cycle),
      }
      assert_false(valid({ ..diagram, manager, }))
    }
  }
}
