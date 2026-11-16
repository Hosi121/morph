///|
fn review_field(
  coefficients : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> @numberfield.Field {
  let polynomial = @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<coefficients.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficients[i].0, coefficients[i].1),
            exponents: Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
  let source = @real.number({
    polynomial,
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
  match
    @minimal.normalize(
      source,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @numberfield.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("review scalar field did not normalize")
  }
}

///|
fn review_relative_polynomial(
  field : @numberfield.Field,
  terms : Array[(Int32, Int32, Int32, Int32)],
) -> @ordered.Polynomial {
  let mut degree = -1
  for (_, _, _, power) in terms {
    if degree < power {
      degree = power
    }
  }
  let coefficients = [
    for power in 0..<(degree + 1) => {
      let selected_terms = terms.filter(fn(term) { term.3 == power })
      let coefficient = @poly.polynomial(
        @oracle.nat(1),
        @oracle.chain(
          selected_terms.map(fn(term) {
            @poly.Term::{
              coefficient: @oracle.rational(term.0, term.1),
              exponents: Cons(@oracle.nat(term.2), Nil),
            }
          }),
        ),
      ).unwrap()
      @numberfield.element(field, coefficient).unwrap()
    }
  ]
  @ordered.polynomial(field, @oracle.chain(coefficients)).unwrap()
}

///|
fn review_decompose(problem : Problem) -> Decomposition {
  let initial = start(problem).unwrap()
  let paused = match run(initial, Zero).unwrap() {
    Paused(state) => state
    _ => abort("zero review fuel must pause")
  }
  match run(paused, @oracle.nat(1024)).unwrap() {
    Complete(value) => value
    _ => abort("finite independent review fibre paused")
  }
}

///|
fn review_relative_fixture(
  field_polynomial : Array[(Int32, Int32)],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
  atoms : Array[Array[(Int32, Int32, Int32, Int32)]],
  build : (Array[@ordered.Polynomial]) -> Formula,
  expected_signs : Array[Array[Int32]],
  expected_truth : Array[Bool],
) -> Unit raise {
  let field = review_field(field_polynomial, lower, upper)
  let declared = atoms.map(fn(p) { review_relative_polynomial(field, p) })
  let problem = prepare(field, build(declared)).unwrap()
  let value = review_decompose(problem)
  let proof = certificate(value)
  assert_true(check(problem, proof) is Some(_))
  let actual = @oracle.array(cells(value))
  let actual_atoms = @oracle.array(polynomials(problem))
  let unique = []
  for p in declared {
    if !unique.any(fn(q) { @ordered.equal(p, q) }) {
      unique.push(p)
    }
  }
  assert_eq(actual_atoms.length(), unique.length())
  assert_eq(actual.length(), expected_truth.length())
  let mut exists = false
  let mut forall = true
  for i in 0..<actual.length() {
    let signs = @oracle.array(actual[i].signs)
    assert_eq(signs.length(), actual_atoms.length())
    for j in 0..<actual_atoms.length() {
      let mut index = -1
      for k in 0..<declared.length() {
        if @ordered.equal(actual_atoms[j], declared[k]) {
          index = k
          break
        }
      }
      assert_true(index >= 0)
      let expected = expected_signs[i][index]
      assert_eq(
        signs[j],
        if expected < 0 {
          Less
        } else if expected > 0 {
          Greater
        } else {
          Equal
        },
      )
    }
    assert_eq(actual[i].holds, expected_truth[i])
    exists = exists || expected_truth[i]
    forall = forall && expected_truth[i]
  }
  assert_eq(witness(value) is Some(_), exists)
  assert_eq(universally_true(value), forall)
}

///|
test "independent relative certificate mutations cannot drop sectors roots or signs" {
  let field = review_field([(-2, 1), (0, 1), (1, 1)], (1, 1), (2, 1))
  let p = review_relative_polynomial(field, [(1, 1, 0, 1), (-1, 1, 1, 0)])
  let problem = prepare(field, Atom(p, GreaterZero)).unwrap()
  let value = review_decompose(problem)
  let proof = certificate(value)
  let table = @oracle.array(proof.cells)
  assert_eq(table.length(), 3)
  assert_true(check(problem, { ..proof, cells: Nil, }) is None)
  assert_true(
    check(problem, { ..proof, cells: @core.drop(Succ(Zero), proof.cells), })
    is None,
  )
  assert_true(
    check(problem, { ..proof, cells: @core.reverse(proof.cells), }) is None,
  )
  let missing = @oracle.chain([table[0], table[2]])
  assert_true(check(problem, { ..proof, cells: missing, }) is None)
  let wrong = table.copy()
  wrong[1] = { ..table[1], holds: !table[1].holds, }
  assert_true(check(problem, { ..proof, cells: @oracle.chain(wrong), }) is None)
  wrong[1] = { ..table[1], signs: Cons(Greater, Nil), }
  assert_true(check(problem, { ..proof, cells: @oracle.chain(wrong), }) is None)
  wrong[1] = { ..table[1], sample: RationalPoint(@oracle.rational(100, 1)), }
  assert_true(check(problem, { ..proof, cells: @oracle.chain(wrong), }) is None)
  assert_true(
    check(problem, { ..proof, isolation: { ..proof.isolation, roots: Nil, }, })
    is None,
  )
  let changed_formula = prepare(field, Atom(p, AtLeastZero)).unwrap()
  assert_true(check(changed_formula, proof) is None)
}

///|
test "independent relative checker binds base conjugate and preparation rejects foreign atoms" {
  let positive = review_field([(-2, 1), (0, 1), (1, 1)], (1, 1), (2, 1))
  let negative = review_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  let terms = [(1, 1, 0, 1), (-1, 1, 1, 0)]
  let p = review_relative_polynomial(positive, terms)
  let q = review_relative_polynomial(negative, terms)
  let first = prepare(positive, Atom(p, GreaterZero)).unwrap()
  let second = prepare(negative, Atom(q, GreaterZero)).unwrap()
  let proof = certificate(review_decompose(first))
  assert_true(prepare(positive, Atom(q, GreaterZero)) is Err(DifferentField))
  assert_true(check(second, proof) is None)
}
