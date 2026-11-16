///|
fn[A] required(result : Result[A, CompileError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("mucalc operation")
  }
}

///|
fn numeric_model(
  edges : Array[Array[Int32]],
  labels : Array[Array[Int32]],
  sparse~ : Bool = false,
) -> Model {
  required(
    model(
      @oracle.chain(
        [
          for i in 0..<edges.length() => {
            State::{
              id: @oracle.nat(if sparse { 5 + 7 * i } else { i }),
              propositions: @oracle.chain(labels[i].map(@oracle.nat)),
              successors: @oracle.chain(
                edges[i].map(fn(j) {
                  @oracle.nat(if sparse { 5 + 7 * j } else { j })
                }),
              ),
            }
          }
        ],
      ),
    ),
  )
}

///|
// Independent numeric semantics over sets represented by finite bit masks.
// Every nested binder starts a fresh bottom/top iteration in its current env.
// No game construction, priority, attractor or strategy routine is used here.
fn interpret(
  formula : Formula,
  edges : Array[Array[Int32]],
  labels : Array[Array[Int32]],
  environment : Array[Int32],
) -> Int32 {
  let n = edges.length()
  let all = (1 << n) - 1
  match formula {
    Truth(value) => if value { all } else { 0 }
    Proposition(p, positive) => {
      let p = @oracle.int_of_nat(p)
      for i = 0, mask = 0; i < n; {
        let present = labels[i].contains(p)
        continue i + 1,
          if (positive && present) || (!positive && !present) {
            mask | (1 << i)
          } else {
            mask
          }
      } nobreak {
        mask
      }
    }
    Bound(index) => environment[@oracle.int_of_nat(index)]
    And(left, right) =>
      interpret(left, edges, labels, environment) &
      interpret(right, edges, labels, environment)
    Or(left, right) =>
      interpret(left, edges, labels, environment) |
      interpret(right, edges, labels, environment)
    Diamond(body) | Box(body) => {
      let target = interpret(body, edges, labels, environment)
      for i = 0, mask = 0; i < n; {
        let holds = match formula {
          Diamond(_) => edges[i].any(fn(j) { (target & (1 << j)) != 0 })
          _ => edges[i].all(fn(j) { (target & (1 << j)) != 0 })
        }
        continue i + 1, if holds { mask | (1 << i) } else { mask }
      } nobreak {
        mask
      }
    }
    Mu(body) | Nu(body) => {
      let mut current = match formula {
        Mu(_) => 0
        _ => all
      }
      for _ in 0..<(n + 2) {
        let next = interpret(body, edges, labels, [current, ..environment])
        if next == current {
          return current
        }
        current = next
      }
      abort("positive finite fixed point did not stabilize")
    }
  }
}

///|
fn solve_compilation(compilation : Compilation) -> Solution {
  match run(start(compilation), @oracle.nat(10000)) {
    Complete(solution) => solution
    Paused(_) => abort("mucalc explicit 10000 solver-step bound exhausted")
    Fault => abort("mucalc parity invariant failure")
  }
}

///|
fn assert_interpretation(
  formula : Formula,
  edges : Array[Array[Int32]],
  labels : Array[Array[Int32]],
  sparse~ : Bool = false,
) -> Unit raise {
  let model = numeric_model(edges, labels, sparse~)
  let compilation = required(compile(model, formula))
  let solution = solve_compilation(compilation)
  let expected = interpret(formula, edges, labels, [])
  for i in 0..<edges.length() {
    assert_eq(
      holds(solution, @oracle.nat(if sparse { 5 + 7 * i } else { i })),
      Some((expected & (1 << i)) != 0),
    )
  }
  assert_eq(
    @oracle.array(satisfying_states(solution)).map(@oracle.int_of_nat),
    [
      for i in 0..<edges.length() if (expected & (1 << i)) != 0 => {
        if sparse {
          5 + 7 * i
        } else {
          i
        }
      }
    ],
  )
  assert_eq(
    @oracle.int_of_nat(@core.length(positions(compilation))),
    edges.length() * @oracle.int_of_nat(@core.length(nodes(compilation))) + 2,
  )
  assert_true(checked(compilation, certificate(solution)) is Some(_))
}

///|
fn formulas_of_size(size : Int32, depth : Int32) -> Array[Formula] {
  if size == 1 {
    let result = [
      Truth(false),
      Truth(true),
      Proposition(@oracle.nat(0), false),
      Proposition(@oracle.nat(0), true),
    ]
    for i in 0..<depth {
      result.push(Bound(@oracle.nat(i)))
    }
    return result
  }
  let result = []
  for body in formulas_of_size(size - 1, depth) {
    result.push(Diamond(body))
    result.push(Box(body))
  }
  for body in formulas_of_size(size - 1, depth + 1) {
    result.push(Mu(body))
    result.push(Nu(body))
  }
  for left_size in 1..<(size - 1) {
    for left in formulas_of_size(left_size, depth) {
      for right in formulas_of_size(size - 1 - left_size, depth) {
        result.push(And(left, right))
        result.push(Or(left, right))
      }
    }
  }
  result
}

///|
fn edges_from_mask(n : Int32, mask : Int32) -> Array[Array[Int32]] {
  [
    for i in 0..<n => {
      [
        for j in 0..<n if (mask & (1 << (i * n + j))) != 0 => j
      ]
    }
  ]
}

///|
fn labels_from_mask(n : Int32, mask : Int32) -> Array[Array[Int32]] {
  [
    for i in 0..<n => if (mask & (1 << i)) != 0 { [0] } else { [] }
  ]
}

///|
test "closed formulas through three syntax nodes exhaust all graphs and one atom labels through two states" {
  let formulas = []
  for size in 1..<4 {
    for formula in formulas_of_size(size, 0) {
      formulas.push(formula)
    }
  }
  assert_eq(formulas.length(), 134)
  let mut models = 0
  for n in 0..<3 {
    for edges in 0..<(1 << (n * n)) {
      for labels in 0..<(1 << n) {
        models += 1
        let edges = edges_from_mask(n, edges)
        let labels = labels_from_mask(n, labels)
        for formula in formulas {
          assert_interpretation(formula, edges, labels)
        }
      }
    }
  }
  assert_eq(models, 69)
}

///|
test "max recurring priorities distinguish outer and inner de Bruijn binders" {
  let x = Bound(@oracle.nat(0))
  let outer = Bound(@oracle.nat(1))
  for
    (formula, expected) in [
      (Mu(x), false),
      (Nu(x), true),
      (Mu(Nu(outer)), false),
      (Nu(Mu(outer)), true),
      (Mu(Nu(x)), true),
      (Nu(Mu(x)), false),
    ] {
    let model = numeric_model([[0]], [[]])
    let compilation = required(compile(model, formula))
    let solution = solve_compilation(compilation)
    assert_eq(holds(solution, @oracle.nat(0)), Some(expected))
    assert_interpretation(formula, [[0]], [[]])
  }
}

///|
test "dead end modalities and negative atoms have the standard empty successor semantics" {
  for labels in [[], [0]] {
    for
      formula in [
        Truth(false),
        Truth(true),
        Proposition(@oracle.nat(0), false),
        Proposition(@oracle.nat(0), true),
        Diamond(Truth(true)),
        Box(Truth(false)),
        Mu(Box(Bound(@oracle.nat(0)))),
        Nu(Diamond(Bound(@oracle.nat(0)))),
      ] {
      assert_interpretation(formula, [[]], [labels])
    }
  }
}

///|
fn temporal_formulas() -> Array[Formula] {
  let p = Proposition(@oracle.nat(0), true)
  let x = Bound(@oracle.nat(0))
  let outer = Bound(@oracle.nat(1))
  [
    Mu(Or(p, Diamond(x))),
    Nu(And(p, Box(x))),
    Mu(Or(p, Box(x))),
    Nu(And(p, Diamond(x))),
    Nu(Mu(Or(And(p, Diamond(outer)), Diamond(x)))),
    Mu(Nu(Or(And(p, Diamond(x)), Diamond(outer)))),
    Nu(Mu(Or(And(p, Box(outer)), Box(x)))),
    Mu(Nu(Or(And(p, Box(x)), Box(outer)))),
  ]
}

///|
test "all three state graphs and one atom labelings compare reachability safety and alternating fixed points" {
  let formulas = temporal_formulas()
  let mut models = 0
  for graph in 0..<512 {
    let edges = edges_from_mask(3, graph)
    for labels in 0..<8 {
      models += 1
      let labels = labels_from_mask(3, labels)
      for formula in formulas {
        assert_interpretation(formula, edges, labels)
      }
    }
  }
  assert_eq(models, 4096)
}

///|
test "compiler binds occurrences to lexical scopes with outer priorities strictly dominating inner binders" {
  let model = numeric_model([[0]], [[]])
  let outer = required(compile(model, Mu(Nu(Bound(@oracle.nat(1))))))
  let ns = @oracle.array(nodes(outer))
  assert_eq(ns.map(fn(node) { @oracle.int_of_nat(node.priority) }), [5, 2, 0])
  assert_eq(ns[2].kind, Jump(@oracle.nat(0)))
  let shadow = required(compile(model, Mu(Nu(Bound(@oracle.nat(0))))))
  let ns = @oracle.array(nodes(shadow))
  assert_eq(ns[2].kind, Jump(@oracle.nat(1)))
  let triple = Mu(Nu(Mu(Bound(@oracle.nat(2)))))
  let deep = required(compile(model, triple))
  assert_eq(
    @oracle.array(nodes(deep)).map(fn(node) {
      @oracle.int_of_nat(node.priority)
    }),
    [7, 4, 3, 0],
  )
  assert_interpretation(triple, [[0]], [[]])
  for
    formula in [
      And(Mu(Bound(@oracle.nat(0))), Nu(Bound(@oracle.nat(0)))),
      Or(Mu(Bound(@oracle.nat(0))), Nu(Bound(@oracle.nat(0)))),
    ] {
    assert_interpretation(formula, [[0]], [[]])
  }
}

///|
test "sparse state and proposition IDs modal targets duplicate edges and empty models are explicit" {
  let s = State::{
    id: @oracle.nat(13),
    propositions: @oracle.chain([@oracle.nat(7)]),
    successors: @oracle.chain([@oracle.nat(5), @oracle.nat(5)]),
  }
  let t = State::{
    id: @oracle.nat(5),
    propositions: @core.Nil,
    successors: @oracle.chain([@oracle.nat(13)]),
  }
  let kripke = required(model(@oracle.chain([s, t])))
  assert_eq(
    @oracle.int_of_nat(
      @core.length(@oracle.array(states(kripke))[0].successors),
    ),
    1,
  )
  let literal = required(compile(kripke, Proposition(@oracle.nat(7), true)))
  let solution = solve_compilation(literal)
  assert_eq(holds(solution, @oracle.nat(13)), Some(true))
  assert_eq(holds(solution, @oracle.nat(5)), Some(false))
  assert_eq(holds(solution, @oracle.nat(0)), None)
  assert_eq(
    position_id(literal, @oracle.nat(13), @oracle.nat(0)),
    Some(@oracle.nat(0)),
  )
  assert_eq(
    position_id(literal, @oracle.nat(5), @oracle.nat(0)),
    Some(@oracle.nat(1)),
  )
  assert_eq(position_id(literal, @oracle.nat(5), @oracle.nat(1)), None)
  assert_eq(position_id(literal, @oracle.nat(99), @oracle.nat(0)), None)
  let diamond = solve_compilation(
    required(compile(kripke, Diamond(Proposition(@oracle.nat(7), true)))),
  )
  assert_eq(holds(diamond, @oracle.nat(13)), Some(false))
  assert_eq(holds(diamond, @oracle.nat(5)), Some(true))
  for formula in temporal_formulas() {
    assert_interpretation(formula, [[1], [0]], [[], [0]], sparse=true)
  }
  let empty = required(model(@core.Nil))
  for
    formula in [
      Truth(false),
      Truth(true),
      Mu(Bound(@oracle.nat(0))),
      Nu(Bound(@oracle.nat(0))),
    ] {
    let compilation = required(compile(empty, formula))
    assert_eq(@oracle.int_of_nat(@core.length(positions(compilation))), 2)
    let solution = solve_compilation(compilation)
    assert_eq(@oracle.int_of_nat(@core.length(satisfying_states(solution))), 0)
    assert_eq(holds(solution, @oracle.nat(0)), None)
  }
}

///|
test "invalid graph identities and out of scope variables are rejected even under dead ends" {
  let s = State::{
    id: @oracle.nat(7),
    propositions: @core.Nil,
    successors: @core.Nil,
  }
  assert_eq(model(@oracle.chain([s, s])), Err(DuplicateState))
  assert_eq(
    model(
      @oracle.chain([{ ..s, successors: @oracle.chain([@oracle.nat(8)]), }]),
    ),
    Err(UnknownSuccessor),
  )
  assert_eq(
    model(
      @oracle.chain([
        { ..s, propositions: @oracle.chain([@oracle.nat(0), @oracle.nat(0)]), },
      ]),
    ),
    Err(DuplicateLabel),
  )
  for model in [numeric_model([[]], [[]]), numeric_model([], [])] {
    for
      formula in [
        Bound(@oracle.nat(0)),
        Diamond(Bound(@oracle.nat(0))),
        Box(Bound(@oracle.nat(0))),
        Or(Mu(Bound(@oracle.nat(0))), Bound(@oracle.nat(0))),
      ] {
      assert_eq(compile(model, formula), Err(UnboundVariable(@oracle.nat(0))))
    }
    assert_eq(
      compile(model, Mu(Bound(@oracle.nat(1)))),
      Err(UnboundVariable(@oracle.nat(1))),
    )
    assert_eq(
      compile(model, Mu(Nu(Bound(@oracle.nat(2))))),
      Err(UnboundVariable(@oracle.nat(2))),
    )
  }
}

///|
test "all solver fuel boundaries resume and certificate tampering cannot change satisfaction" {
  let compilation = required(
    compile(
      numeric_model([[0, 1], [1]], [[], [0]]),
      Mu(Or(Proposition(@oracle.nat(0), true), Diamond(Bound(@oracle.nat(0))))),
    ),
  )
  let initial = start(compilation)
  assert_eq(run(initial, @oracle.nat(0)), Paused(initial))
  let mut machine = initial
  let mut steps = 0
  let mut answer : Solution? = None
  for _ in 0..<1024 {
    match step(machine) {
      Paused(next) => {
        machine = next
        steps += 1
      }
      Complete(solution) => {
        steps += 1
        answer = Some(solution)
        break
      }
      Fault => fail("valid evaluation game must not fault")
    }
  }
  let expected = answer.unwrap()
  for fuel in 0..<steps {
    match run(initial, @oracle.nat(fuel)) {
      Paused(state) => {
        assert_eq(run(state, @oracle.nat(0)), Paused(state))
        assert_eq(run(state, @oracle.nat(steps - fuel)), Complete(expected))
      }
      _ => fail("fuel exhaustion must remain paused")
    }
  }
  assert_eq(run(initial, @oracle.nat(steps)), Complete(expected))
  assert_eq(run(initial, @oracle.nat(steps + 1)), Complete(expected))
  let good = certificate(expected)
  assert_true(checked(compilation, good) is Some(_))
  assert_true(checked(compilation, { ..good, even_region: @core.Nil, }) is None)
  assert_true(checked(compilation, { ..good, odd_region: @core.Nil, }) is None)
  assert_true(
    checked(compilation, { ..good, even_strategy: @core.Nil, }) is None,
  )
  assert_true(
    checked(compilation, {
      ..good,
      even_region: good.odd_region,
      odd_region: good.even_region,
    })
    is None,
  )
  let true_comp = required(compile(numeric_model([[]], [[]]), Truth(true)))
  let false_comp = required(compile(numeric_model([[]], [[]]), Truth(false)))
  assert_true(
    checked(false_comp, certificate(solve_compilation(true_comp))) is None,
  )
}

///|
fn assert_fixture(
  formula : Formula,
  edges : Array[Array[Int32]],
  labels : Array[Array[Int32]],
  expected : Array[Int32],
) -> Unit raise {
  assert_eq(
    interpret(formula, edges, labels, []),
    expected.fold(init=0, fn(mask, i) { mask | (1 << i) }),
  )
  for sparse in [false, true] {
    let compilation = required(
      compile(numeric_model(edges, labels, sparse~), formula),
    )
    let solution = solve_compilation(compilation)
    assert_eq(
      @oracle.array(satisfying_states(solution)).map(@oracle.int_of_nat),
      expected.map(fn(i) { if sparse { 5 + 7 * i } else { i } }),
    )
    assert_true(checked(compilation, certificate(solution)) is Some(_))
  }
}

///|
fn dual(formula : Formula) -> Formula {
  match formula {
    Truth(value) => Truth(!value)
    Proposition(p, positive) => Proposition(p, !positive)
    Bound(index) => Bound(index)
    And(a, b) => Or(dual(a), dual(b))
    Or(a, b) => And(dual(a), dual(b))
    Diamond(body) => Box(dual(body))
    Box(body) => Diamond(dual(body))
    Mu(body) => Nu(dual(body))
    Nu(body) => Mu(dual(body))
  }
}

///|
test "three binder alternation shared outer references and syntactic duality exhaust two state two atom models" {
  let p = Proposition(@oracle.nat(0), true)
  let q = Proposition(@oracle.nat(1), true)
  let innermost = Bound(@oracle.nat(0))
  let middle = Bound(@oracle.nat(1))
  let outermost = Bound(@oracle.nat(2))
  let formulas = [
    Nu(
      Mu(
        Nu(
          Or(
            And(p, Diamond(outermost)),
            And(q, Or(Box(middle), Diamond(innermost))),
          ),
        ),
      ),
    ),
    Mu(
      Nu(
        Mu(
          And(
            Or(p, Box(outermost)),
            Or(q, And(Diamond(middle), Box(innermost))),
          ),
        ),
      ),
    ),
    Nu(And(Mu(Or(p, Diamond(middle))), Nu(And(q, Box(middle))))),
  ]
  for graph in 0..<16 {
    let edges = edges_from_mask(2, graph)
    for bits in 0..<16 {
      let labels = [
        for i in 0..<2 => {
          [
            for p in 0..<2 if (bits & (1 << (i * 2 + p))) != 0 => p
          ]
        }
      ]
      for formula in formulas {
        assert_interpretation(formula, edges, labels)
        assert_interpretation(dual(formula), edges, labels)
        assert_eq(
          interpret(dual(formula), edges, labels, []),
          3 ^ interpret(formula, edges, labels, []),
        )
      }
    }
  }
}
