///|
fn test_poly(
  n : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(n),
    @oracle.chain(
      terms.map(fn(t) {
        {
          coefficient: @oracle.rational(t.0, t.1),
          exponents: @oracle.chain(t.2.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_source(n : Int32, inputs : Array[@poly.Polynomial]) -> @f4.Basis {
  match
    @f4.f4(@oracle.nat(n), @oracle.chain(inputs), @oracle.nat(100)).unwrap() {
    @f4.Complete(source) => source
    _ => abort("source F4 did not complete")
  }
}

///|
fn test_convert(source : @f4.Basis, target : Order) -> Basis {
  match convert(source, target, @oracle.nat(128), @oracle.nat(1000)).unwrap() {
    Complete(basis) => basis
    _ => abort("FGLM small conversion did not complete")
  }
}

///|
test "FGLM changes a lex F4 basis into graded bases by quotient linear dependence" {
  let source = test_source(2, [
    test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
  ])
  let expected = @oracle.chain([
    test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
    test_poly(2, [(1, 1, [0, 2]), (-1, 1, [1, 0])]),
  ])
  for target in [GradedLex, GrevLex] {
    let result = test_convert(source, target)
    assert_eq(polynomials(result), expected)
    assert_eq(@oracle.int_of_nat(dimension(result)), 3)
    assert_eq(verify(result), Ok(true))
    assert_eq(@oracle.int_of_nat(statistics(result).independent), 3)
    assert_eq(@oracle.int_of_nat(statistics(result).dependent), 3)
  }
  let identity = test_convert(source, Lex)
  assert_eq(polynomials(identity), @f4.polynomials(source))
  assert_eq(verify(identity), Ok(true))
}

///|
test "FGLM three variable grevlex and graded lex use different target staircases" {
  let source = test_source(3, [
    test_poly(3, [(1, 1, [1, 0, 0]), (-1, 1, [0, 0, 3])]),
    test_poly(3, [(1, 1, [0, 1, 0]), (-1, 1, [0, 0, 2])]),
    test_poly(3, [(1, 1, [0, 0, 5]), (-1, 1, [0, 0, 0])]),
  ])
  let graded = test_convert(source, GradedLex)
  let reverse = test_convert(source, GrevLex)
  assert_eq(verify(graded), Ok(true))
  assert_eq(verify(reverse), Ok(true))
  assert_eq(@oracle.int_of_nat(dimension(graded)), 5)
  let xz = @oracle.chain([1, 0, 1].map(@oracle.nat))
  let yy = @oracle.chain([0, 2, 0].map(@oracle.nat))
  assert_true(contains(standard_monomials(reverse), xz))
  assert_false(contains(standard_monomials(reverse), yy))
  assert_true(contains(standard_monomials(graded), yy))
  assert_false(contains(standard_monomials(graded), xz))
}

///|
test "FGLM rejects positive dimension caps finite dimension and resumes exact state" {
  let source = test_source(2, [
    test_poly(2, [(1, 1, [2, 0])]),
    test_poly(2, [(1, 1, [0, 3])]),
  ])
  assert_eq(
    start(source, GrevLex, @oracle.nat(5)).unwrap(),
    Undecided(DimensionLimit),
  )
  let state = match start(source, GrevLex, @oracle.nat(6)).unwrap() {
    Paused(state) => state
    _ => abort("dimension six staircase must fit")
  }
  assert_eq(run(state, Zero), Ok(Paused(state)))
  let expected = test_convert(source, GrevLex)
  let mut current = state
  let mut finished = false
  for _ in 0..<100 {
    match run(current, Succ(Zero)).unwrap() {
      Paused(next) => current = next
      Complete(actual) => {
        assert_eq(actual, expected)
        finished = true
        break
      }
      _ => fail("unexpected undecided during resume")
    }
  }
  assert_true(finished)
  assert_eq(@oracle.int_of_nat(dimension(expected)), 6)
  let curve = test_source(2, [test_poly(2, [(1, 1, [1, 1])])])
  assert_eq(start(curve, GrevLex, @oracle.nat(100)), Err(PositiveDimension))
  let zero = test_source(2, [])
  assert_eq(start(zero, Lex, @oracle.nat(1)), Err(PositiveDimension))
}

///|
test "FGLM unit ideal and zero variable quotient have precise dimensions" {
  for n in [0, 1, 3] {
    let unit = test_source(n, [
      @poly.constant(@oracle.nat(n), @oracle.rational(2, 3)),
    ])
    let basis = match convert(unit, GrevLex, Zero, Zero).unwrap() {
      Complete(basis) => basis
      _ => abort("unit ideal needs no staircase or target pops")
    }
    assert_eq(dimension(basis), Zero)
    assert_eq(standard_monomials(basis), Nil)
    assert_eq(verify(basis), Ok(true))
  }
  let scalar = test_source(0, [])
  assert_eq(start(scalar, Lex, Zero).unwrap(), Undecided(DimensionLimit))
  let result = test_convert(scalar, GrevLex)
  assert_eq(dimension(result), Succ(Zero))
  assert_eq(polynomials(result), Nil)
  assert_eq(standard_monomials(result), Cons(Nil, Nil))
  assert_eq(verify(result), Ok(true))
}

///|
test "FGLM linear dependence solves columns exactly and refuses dependent state vectors" {
  let vectors = @oracle.chain([
    @oracle.chain([1, 2].map(fn(x) { @oracle.rational(x, 1) })),
    @oracle.chain([3, 4].map(fn(x) { @oracle.rational(x, 1) })),
  ])
  match
    span(vectors, @oracle.chain([5, 8].map(fn(x) { @oracle.rational(x, 1) }))).unwrap() {
    Dependent(coefficients) =>
      assert_eq(
        coefficients,
        @oracle.chain([@oracle.rational(2, 1), @oracle.rational(1, 1)]),
      )
    _ => fail("expected an exact non-symmetric column dependence")
  }
  let vector = @oracle.chain([1, 2].map(fn(x) { @oracle.rational(x, 1) }))
  match
    span(
      Cons(vector, Nil),
      @oracle.chain([2, 1].map(fn(x) { @oracle.rational(x, 1) })),
    ).unwrap() {
    Independent => ()
    _ => fail("linearly independent vector")
  }
  assert_true(
    span(Cons(vector, Cons(vector, Nil)), vector) is Err(InternalInvariant),
  )
}

///|
test "FGLM checker rejects altered linear witnesses missing generators and a larger ideal" {
  let source = test_source(2, [
    test_poly(2, [(1, 1, [2, 0])]),
    test_poly(2, [(1, 1, [0, 2])]),
  ])
  let result = test_convert(source, GrevLex)
  let valid = certificate(result)
  assert_eq(check(source, valid), Ok(true))
  assert_eq(
    check(source, { ..valid, polynomials: Nil, relations: Nil, }),
    Ok(false),
  )
  match valid.relations {
    Cons(first, rest) =>
      match first.coefficients {
        Cons(c, tail) =>
          assert_eq(
            check(source, {
              ..valid,
              relations: Cons(
                {
                  ..first,
                  coefficients: Cons(
                    @exact.rational_add(c, @exact.rational_one()),
                    tail,
                  ),
                },
                rest,
              ),
            }),
            Ok(false),
          )
        _ => fail("nonunit relations have standard coefficients")
      }
    _ => fail("expected relations")
  }
  let x = test_poly(2, [(1, 1, [1, 0])])
  let y = test_poly(2, [(1, 1, [0, 1])])
  let fake : Certificate = {
    order: GrevLex,
    polynomials: @oracle.chain([x, y]),
    relations: @oracle.chain([
      {
        monomial: @oracle.chain([1, 0].map(@oracle.nat)),
        standard_monomials: Nil,
        coefficients: Nil,
      },
      {
        monomial: @oracle.chain([0, 1].map(@oracle.nat)),
        standard_monomials: Nil,
        coefficients: Nil,
      },
    ]),
  }
  assert_eq(check(source, fake), Ok(false))
}

///|
fn assert_sympy_fixture(
  n : Int32,
  target : Order,
  inputs : Array[Array[(Int32, Int32, Array[Int32])]],
  expected : Array[Array[(Int32, Int32, Array[Int32])]],
  expected_dimension : Int32,
  expected_standards : Array[Array[Int32]],
) -> Unit raise {
  let source = test_source(n, inputs.map(fn(terms) { test_poly(n, terms) }))
  let result = match
    convert(source, target, @oracle.nat(expected_dimension), @oracle.nat(1000)).unwrap() {
    Complete(basis) => basis
    _ => abort("exact dimension cap should complete")
  }
  assert_eq(
    polynomials(result),
    @oracle.chain(expected.map(fn(terms) { test_poly(n, terms) })),
  )
  assert_eq(@oracle.int_of_nat(dimension(result)), expected_dimension)
  assert_eq(
    standard_monomials(result),
    @oracle.chain(
      expected_standards.map(fn(m) { @oracle.chain(m.map(@oracle.nat)) }),
    ),
  )
  assert_eq(verify(result), Ok(true))
  if expected_dimension > 0 {
    assert_eq(
      start(source, target, @oracle.nat(expected_dimension - 1)).unwrap(),
      Undecided(DimensionLimit),
    )
  }
  // Complete has retained an explicit linear-dependence witness for every row.
  assert_eq(
    @core.length(certificate(result).relations),
    @core.length(polynomials(result)),
  )
}

///|
test "FGLM persistent heap visits duplicates once and prunes relation multiples" {
  let source = test_source(2, [
    test_poly(2, [(1, 1, [2, 0])]),
    test_poly(2, [(1, 1, [0, 3])]),
  ])
  for target in [Lex, GradedLex, GrevLex] {
    let mut state = match start(source, target, @oracle.nat(6)).unwrap() {
      Paused(state) => state
      _ => abort("expected initialized quotient")
    }
    let visited = []
    let mut finished = false
    for _ in 0..<100 {
      match
        @heap.pop(state.queue, fn(a, b) { compare_monomial(target, a, b) }) {
        Some((m, _)) => {
          assert_false(visited.contains(m))
          if visited.length() > 0 {
            assert_false(
              compare_monomial(target, visited[visited.length() - 1], m) ==
              Greater,
            )
          }
          visited.push(m)
        }
        None => ()
      }
      match step(state).unwrap() {
        Paused(next) => state = next
        Complete(result) => {
          let stats = statistics(result)
          assert_eq(@oracle.int_of_nat(stats.processed), visited.length())
          assert_eq(@oracle.int_of_nat(stats.independent), 6)
          assert_true(@oracle.int_of_nat(stats.processed) <= 13)
          assert_true(@oracle.int_of_nat(stats.skipped) > 0)
          assert_eq(verify(result), Ok(true))
          finished = true
          break
        }
        _ => fail("no cap decision after initialized state")
      }
    }
    assert_true(finished)
  }
}
