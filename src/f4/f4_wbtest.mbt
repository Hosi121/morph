///|
fn test_poly(
  n : Int32,
  data : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(n),
    @oracle.chain(
      data.map(fn(t) {
        {
          coefficient: @oracle.rational(t.0, t.1),
          exponents: @oracle.chain(t.2.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_complete(n : Int32, inputs : @core.Chain[@poly.Polynomial]) -> Basis {
  match f4(@oracle.nat(n), inputs, @oracle.nat(100)).unwrap() {
    Complete(basis) => basis
    _ => abort("F4 fixture exceeded batch fuel")
  }
}

///|
fn buchberger_complete(
  n : Int32,
  inputs : @core.Chain[@poly.Polynomial],
) -> @groebner.Basis {
  match
    @groebner.buchberger(@oracle.nat(n), inputs, @oracle.nat(1000)).unwrap() {
    @groebner.Complete(basis) => basis
    _ => abort("Buchberger fixture exceeded fuel")
  }
}

///|
test "F4 batches multiple critical pairs through symbolic preprocessing and a Macaulay matrix" {
  let f = test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])])
  let g = test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let h = test_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])])
  let inputs = @oracle.chain([f, g, h])
  let basis = test_complete(2, inputs)
  assert_eq(verify(basis), Ok(true))
  let expected = @oracle.chain([
    test_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
    test_poly(2, [(1, 1, [0, 3]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_true(
    @oracle.array(history(basis)).any(fn(batch) {
      @oracle.int_of_nat(batch.selected_pairs) > 1
    }),
  )
  assert_true(
    @oracle.array(history(basis)).any(fn(batch) {
      @oracle.int_of_nat(batch.reducer_rows) > 0
    }),
  )
  for batch in @oracle.array(history(basis)) {
    assert_eq(
      @oracle.int_of_nat(batch.seed_rows),
      2 * @oracle.int_of_nat(batch.selected_pairs),
    )
    assert_true(@oracle.int_of_nat(batch.columns) > 0)
  }
  assert_eq(
    @groebner.polynomials(buchberger_complete(2, inputs)),
    polynomials(basis),
  )
}

///|
test "F4 exact witnesses survive final interreduction with equal leading monomials" {
  let a = test_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 1])])
  let b = test_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1])])
  let inputs = @oracle.chain([a, b])
  let result = test_complete(2, inputs)
  assert_eq(
    polynomials(result),
    @oracle.chain([
      test_poly(2, [(1, 1, [1, 0])]),
      test_poly(2, [(1, 1, [0, 1])]),
    ]),
  )
  assert_eq(verify(result), Ok(true))
}

///|
test "F4 fuel pauses and resumes exactly with dimension validation zero and unit ideals" {
  let a = test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])])
  let b = test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let inputs = @oracle.chain([a, a, @poly.zero(@oracle.nat(2)), b])
  let state = start(@oracle.nat(2), inputs).unwrap()
  assert_eq(run(state, Zero), Ok(Paused(state)))
  assert_eq(start(@oracle.nat(1), inputs), Err(DimensionMismatch))
  let expected = test_complete(2, inputs)
  let mut current = state
  let mut finished = false
  for _ in 0..<100 {
    match run(current, @oracle.nat(1)).unwrap() {
      Paused(next) => current = next
      Complete(actual) => {
        assert_eq(actual, expected)
        finished = true
        break
      }
    }
  }
  assert_true(finished)
  assert_eq(verify(expected), Ok(true))
  for n in [0, 1, 3] {
    for inputs in [@core.Nil, @oracle.chain([@poly.zero(@oracle.nat(n))])] {
      let result = test_complete(n, inputs)
      assert_eq(polynomials(result), Nil)
      assert_eq(verify(result), Ok(true))
    }
    let inputs = @oracle.chain([
      @poly.constant(@oracle.nat(n), @oracle.rational(2, 3)),
    ])
    let result = test_complete(n, inputs)
    assert_eq(
      polynomials(result),
      @oracle.chain([@poly.constant(@oracle.nat(n), @exact.rational_one())]),
    )
    assert_eq(verify(result), Ok(true))
  }
}

///|
test "F4 certificate checker rejects a larger ideal a missing generator and altered combinations" {
  let xy = test_poly(2, [(1, 1, [1, 1])])
  let x = test_poly(2, [(1, 1, [1, 0])])
  let one = @poly.constant(@oracle.nat(2), @exact.rational_one())
  let result = test_complete(2, @oracle.chain([xy]))
  let valid = certificate(result)
  assert_eq(check(@oracle.nat(2), @oracle.chain([xy]), valid), Ok(true))
  let fake : Certificate = {
    polynomials: @oracle.chain([x]),
    combinations: @oracle.chain([@oracle.chain([one])]),
  }
  assert_eq(
    @poly.normal_form(xy, fake.polynomials).unwrap(),
    @poly.zero(@oracle.nat(2)),
  )
  assert_eq(check(@oracle.nat(2), @oracle.chain([xy]), fake), Ok(false))
  assert_eq(
    check(@oracle.nat(2), @oracle.chain([xy]), {
      polynomials: Nil,
      combinations: Nil,
    }),
    Ok(false),
  )
  assert_eq(
    check(@oracle.nat(2), @oracle.chain([xy]), {
      ..valid,
      combinations: @oracle.chain([@oracle.chain([@poly.zero(@oracle.nat(2))])]),
    }),
    Ok(false),
  )
  assert_eq(
    check(@oracle.nat(2), @oracle.chain([xy]), { ..valid, combinations: Nil, }),
    Ok(false),
  )
  assert_eq(
    check(@oracle.nat(2), @oracle.chain([xy]), {
      ..valid,
      combinations: @oracle.chain([Nil]),
    }),
    Err(DimensionMismatch),
  )
}

///|
fn assert_sympy_fixture(
  n : Int32,
  inputs : Array[Array[(Int32, Int32, Array[Int32])]],
  expected : Array[Array[(Int32, Int32, Array[Int32])]],
) -> Unit raise {
  let inputs = @oracle.chain(inputs.map(fn(terms) { test_poly(n, terms) }))
  let expected = @oracle.chain(expected.map(fn(terms) { test_poly(n, terms) }))
  let actual = test_complete(n, inputs)
  assert_eq(polynomials(actual), expected)
  assert_eq(verify(actual), Ok(true))
  assert_eq(@groebner.polynomials(buchberger_complete(n, inputs)), expected)
}

///|
test "one F4 matrix batch proves every selected S pair has zero normal form in the enlarged basis" {
  let inputs = @oracle.chain([
    test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
    test_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
  ])
  let before = start(@oracle.nat(2), inputs).unwrap()
  let degree = @core.minimum(@oracle.nat(3), @oracle.nat(2))
  let selected = @core.filter(before.pairs, fn(p) {
    @core.compare(p.degree, degree).equal(Equal)
  })
  assert_eq(@oracle.int_of_nat(@core.length(selected)), 2)
  let seeds = seed_rows(selected).unwrap()
  let preprocessed = symbolic_preprocessing(seeds, before.candidates).unwrap()
  assert_true(
    @oracle.int_of_nat(@core.length(preprocessed)) >
    @oracle.int_of_nat(@core.length(seeds)),
  )
  let (reduced, _) = macaulay_reduce(
    before.variables,
    @core.length(inputs),
    preprocessed,
  ).unwrap()
  for row in @oracle.array(reduced) {
    assert_eq(
      reconstruct(before.variables, inputs, row.combination).unwrap(),
      row.value,
    )
  }
  let after = match step(before).unwrap() {
    Paused(state) => state
    _ => abort("expected actual matrix batch")
  }
  let enlarged = @core.map(after.candidates, fn(row) { row.value })
  for p in @oracle.array(selected) {
    let s = @groebner.s_polynomial(p.left.value, p.right.value).unwrap()
    assert_true(@poly.is_zero(@poly.normal_form(s, enlarged).unwrap()))
  }
}

///|
test "F4 checker independently needs all S pairs even when both ideal inclusions already hold" {
  let a = test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])])
  let b = test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let n = @oracle.nat(2)
  let one = @poly.constant(n, @exact.rational_one())
  let zero = @poly.zero(n)
  let inputs = @oracle.chain([a, b])
  let unreduced : Certificate = {
    polynomials: inputs,
    combinations: @oracle.chain([
      @oracle.chain([one, zero]),
      @oracle.chain([zero, one]),
    ]),
  }
  assert_eq(check(n, inputs, unreduced), Ok(false))
  assert_eq(
    check(n, @oracle.chain([zero]), {
      polynomials: @oracle.chain([zero]),
      combinations: @oracle.chain([@oracle.chain([zero])]),
    }),
    Ok(false),
  )
}

///|
test "F4 ideal witnesses follow input permutation rational rescaling duplicates and added zero inputs" {
  let n = @oracle.nat(2)
  let a = test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])])
  let b = test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])])
  let first = test_complete(2, @oracle.chain([a, b]))
  let scaled_a = @poly.scale(a, scalar_term(n, @oracle.rational(-7, 11))).unwrap()
  let scaled_b = @poly.scale(b, scalar_term(n, @oracle.rational(13, 17))).unwrap()
  let changed = @oracle.chain([scaled_b, @poly.zero(n), scaled_a, scaled_b])
  let second = test_complete(2, changed)
  assert_eq(polynomials(second), polynomials(first))
  assert_eq(verify(second), Ok(true))
  assert_eq(check(n, changed, certificate(first)), Err(DimensionMismatch))
}
