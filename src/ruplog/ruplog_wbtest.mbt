///|
fn lit(variable : Int32, positive : Bool) -> @sat.Literal {
  { variable: @oracle.nat(variable), positive, }
}

///|
fn formula(clauses : Array[Array[@sat.Literal]]) -> @sat.Cnf {
  @oracle.chain(clauses.map(@oracle.chain))
}

///|
fn ids(values : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(values.map(@oracle.binary))
}

///|
fn certificate(
  id : Int32,
  clause : Array[@sat.Literal],
  hints : Array[Int32],
) -> Certificate {
  {
    steps: @core.Cons(
      {
        id: @oracle.binary(id),
        clause: @oracle.chain(clause),
        hints: ids(hints),
      },
      Nil,
    ),
  }
}

///|
fn ternary(code : Int32) -> @sat.Clause {
  let result = []
  let mut code = code
  for variable in 0..<3 {
    let digit = code % 3
    code /= 3
    if digit != 0 {
      result.push(lit(variable, digit == 1))
    }
  }
  @oracle.chain(result)
}

///|
fn brute(cnf : @sat.Cnf) -> Bool {
  let clauses = @oracle.array(cnf).map(@oracle.array)
  for mask in 0..<8 {
    if clauses.all(fn(clause) {
        clause.any(fn(literal) {
          ((mask & (1 << @oracle.int_of_nat(literal.variable))) != 0) ==
          literal.positive
        })
      }) {
      return true
    }
  }
  false
}

///|
test "generated certificates agree with truth tables on all three-clause three-variable formulas" {
  for a in 0..<27 {
    for b in 0..<27 {
      for c in 0..<27 {
        let cnf = @oracle.chain([ternary(a), ternary(b), ternary(c)])
        let expected = brute(cnf)
        match @cdcl.run(@cdcl.start(cnf), @oracle.nat(1000)) {
          Satisfiable(model) => {
            assert_true(expected)
            assert_true(@sat.check_model(cnf, model))
          }
          Unsatisfiable(proof) => {
            assert_false(expected)
            let logged = build(cnf, proof).unwrap()
            assert_true(check(cnf, logged))
            assert_true(check_prepared(prepare(cnf), logged))
            assert_true(@cdcl.check_refutation(cnf, erase(logged)))
          }
          _ => fail("tiny input must finish")
        }
      }
    }
  }
}

///|
test "all nonempty small candidate lemma lists agree with the unhinted RUP checker" {
  for a in 0..<27 {
    for b in 0..<27 {
      let cnf = @oracle.chain([ternary(a), ternary(b)])
      let input = prepare(cnf)
      for candidate in 1..<27 {
        let proof = @cdcl.Rup(@oracle.chain([ternary(candidate), @core.Nil]))
        let expected = @cdcl.check_refutation(cnf, proof)
        match build_prepared(input, proof) {
          None => assert_false(expected)
          Some(logged) => {
            assert_true(expected)
            assert_false(brute(cnf))
            assert_true(check_prepared(input, logged))
            assert_true(@cdcl.check_refutation(cnf, erase(logged)))
          }
        }
      }
    }
  }
}

///|
test "clause IDs and order-sensitive unit hints reject corrupt certificates" {
  let cnf = formula([
    [lit(0, true)],
    [lit(0, false), lit(1, true)],
    [lit(1, false)],
  ])
  let proof = @cdcl.Rup(@core.Cons(@core.Nil, Nil))
  let expected = certificate(4, [], [1, 2, 3])
  assert_eq(first_derived_id(prepare(cnf)), @oracle.binary(4))
  assert_eq(build(cnf, proof), Some(expected))
  assert_eq(@oracle.int_of_nat(hint_count(expected)), 3)
  assert_true(check(cnf, expected))
  for bad_id in [0, 1, 3, 5, 99] {
    assert_false(check(cnf, certificate(bad_id, [], [1, 2, 3])))
  }
  for
    bad_hints in [
      [],
      [0],
      [4],
      [99],
      [2, 1, 3],
      [1, 3],
      [1, 2],
      [1, 2, 3, 99],
      [1, 1, 2, 3],
      [1, 2, 1],
    ] {
    assert_false(check(cnf, certificate(4, [], bad_hints)))
  }
  assert_false(check(cnf, { steps: @core.Nil, }))
  assert_false(check(cnf, certificate(4, [lit(0, true)], [1])))
  let empty_first = Certificate::{
    steps: @oracle.chain([
      Step::{ id: @oracle.binary(4), clause: @core.Nil, hints: ids([1, 2, 3]), },
      Step::{ id: @oracle.binary(5), clause: @core.Nil, hints: ids([4]), },
    ]),
  }
  assert_false(check(cnf, empty_first))
}

///|
test "learned-clause dependencies cannot be removed reordered or referenced before addition" {
  let cnf = formula([
    [lit(0, true), lit(1, true)],
    [lit(0, false), lit(1, true)],
    [lit(0, true), lit(1, false)],
    [lit(0, false), lit(1, false)],
  ])
  let proof = @cdcl.Rup(
    @oracle.chain([@oracle.chain([lit(0, true)]), @core.Nil]),
  )
  let logged = build(cnf, proof).unwrap()
  assert_true(check(cnf, logged))
  let steps = @oracle.array(logged.steps)
  assert_eq(steps.length(), 2)
  assert_eq(steps[0].id, @oracle.binary(5))
  assert_eq(steps[1].id, @oracle.binary(6))
  assert_false(check(cnf, { steps: @oracle.chain([steps[1]]), }))
  assert_false(check(cnf, { steps: @oracle.chain([steps[1], steps[0]]), }))
  assert_false(
    check(cnf, {
      steps: @oracle.chain([{ ..steps[1], id: @oracle.binary(5), }]),
    }),
  )
  let self_reference = { ..steps[0], hints: ids([5]), }
  assert_false(
    check(cnf, { steps: @oracle.chain([self_reference, steps[1]]), }),
  )
  let duplicate_id = { ..steps[1], id: steps[0].id, }
  assert_false(check(cnf, { steps: @oracle.chain([steps[0], duplicate_id]), }))
}

///|
test "negated lemma assumptions and strict canonical addition syntax are checked" {
  let cnf = formula([
    [lit(0, true), lit(1, true)],
    [lit(0, false), lit(1, true)],
  ])
  let input = prepare(cnf)
  let positive = checked_canonical(@oracle.chain([lit(1, true)])).unwrap()
  let negative = checked_canonical(@oracle.chain([lit(1, false)])).unwrap()
  assert_true(
    replay(input.database, ids([1, 2]), checker_assumptions(positive, Empty)),
  )
  assert_false(
    replay(input.database, ids([1, 2]), checker_assumptions(negative, Empty)),
  )
  assert_false(check(cnf, certificate(3, [], [1, 2])))
  for
    clause in [
      [lit(0, true), lit(0, true)],
      [lit(0, true), lit(0, false)],
      [lit(1, true), lit(0, true)],
    ] {
    assert_true(checked_canonical(@oracle.chain(clause)) is None)
  }
}

///|
test "original tautologies and duplicates preserve IDs while tautological source lemmas are omitted" {
  let cnf = formula([
    [lit(0, true), lit(0, false), lit(0, true)],
    [lit(1, true), lit(1, true)],
    [lit(1, false), lit(1, false)],
  ])
  let proof = @cdcl.Rup(
    @oracle.chain([@oracle.chain([lit(2, true), lit(2, false)]), @core.Nil]),
  )
  let logged = build(cnf, proof).unwrap()
  assert_eq(logged, certificate(4, [], [2, 3]))
  assert_true(check(cnf, logged))
  assert_true(@cdcl.check_refutation(cnf, erase(logged)))
  assert_false(check(cnf, certificate(4, [], [1, 2, 3])))
  let forged_tautology = Step::{
    id: @oracle.binary(4),
    clause: @oracle.chain([lit(0, true), lit(0, false)]),
    hints: ids([2, 3]),
  }
  let last = Step::{
    id: @oracle.binary(5),
    clause: @core.Nil,
    hints: ids([2, 3]),
  }
  assert_false(check(cnf, { steps: @oracle.chain([forged_tautology, last]), }))
  assert_true(build(@core.Nil, @cdcl.Rup(@core.Nil)) is None)
  assert_true(
    build(cnf, @cdcl.Rup(@core.Cons(@oracle.chain([lit(1, true)]), Nil)))
    is None,
  )
  let empty = formula([[]])
  assert_eq(
    build(empty, @cdcl.Rup(@core.Cons(@core.Nil, Nil))),
    Some(certificate(2, [], [1])),
  )
  assert_false(check(@core.Nil, certificate(1, [], [])))
}

///|
test "source lemma sorting repetition and duplicate literals preserve checked meaning" {
  let cnf = formula([[lit(0, true)], [lit(0, false)]])
  let proof = @cdcl.Rup(
    @oracle.chain([
      @oracle.chain([lit(1, true), lit(0, true), lit(0, true)]),
      @oracle.chain([lit(0, true)]),
      @oracle.chain([lit(0, true)]),
      @core.Nil,
    ]),
  )
  let logged = build(cnf, proof).unwrap()
  assert_true(check(cnf, logged))
  assert_true(@cdcl.check_refutation(cnf, erase(logged)))
  let steps = @oracle.array(logged.steps)
  assert_eq(steps.length(), 4)
  assert_eq(steps[0].clause, @oracle.chain([lit(0, true), lit(1, true)]))
  assert_eq(steps[1].clause, steps[2].clause)
  assert_false(
    check(cnf, {
      steps: @oracle.chain([
        { ..steps[0], clause: @oracle.chain([lit(1, true), lit(0, true)]), },
        steps[1],
        steps[2],
        steps[3],
      ]),
    }),
  )
}

///|
fn pigeonhole(pigeons : Int32, holes : Int32) -> @sat.Cnf {
  let clauses = []
  for pigeon in 0..<pigeons {
    clauses.push([ for hole in 0..<holes => lit(pigeon * holes + hole, true) ])
  }
  for hole in 0..<holes {
    for left in 0..<pigeons {
      for right in (left + 1)..<pigeons {
        clauses.push([
          lit(left * holes + hole, false),
          lit(right * holes + hole, false),
        ])
      }
    }
  }
  formula(clauses)
}

///|
test "learned pigeonhole proofs enrich without changing the old SAT API" {
  for holes in 1..<=5 {
    let cnf = pigeonhole(holes + 1, holes)
    match @cdcl.run(@cdcl.start(cnf), @oracle.nat(20000)) {
      Unsatisfiable(proof) => {
        let logged = build(cnf, proof).unwrap()
        assert_true(check(cnf, logged))
        assert_true(@cdcl.check_refutation(cnf, erase(logged)))
        if holes > 1 {
          assert_true(@oracle.array(logged.steps).length() > 1)
        }
      }
      _ => fail("pigeonhole input must be refuted")
    }
  }
}
