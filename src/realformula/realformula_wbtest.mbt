///|
fn test_polynomial(
  arity : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @polynomial.Polynomial {
  let result = @polynomial.polynomial(
    @oracle.nat(arity),
    @oracle.chain(
      terms.map(fn(term) {
        let (numerator, denominator, exponents) = term
        @polynomial.Term::{
          coefficient: @oracle.rational(numerator, denominator),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  )
  match result {
    Ok(polynomial) => polynomial
    Err(_) => abort("invalid test polynomial")
  }
}

///|
fn test_variable(arity : Int32, slot : Int32) -> @polynomial.Polynomial {
  test_polynomial(arity, [
    (1, 1, Array::makei(arity, fn(i) { if i == slot { 1 } else { 0 } })),
  ])
}

///|
/// Independent machine-integer rational sign oracle. It does not call the
/// package's polynomial evaluator or sign/relation helpers. Fixture sizes keep
/// the unreduced numerator/denominator within machine integer range.
fn oracle_sign(
  polynomial : @polynomial.Polynomial,
  values : Array[Int32],
) -> Int32 {
  if @oracle.int_of_nat(@polynomial.variables(polynomial)) != values.length() {
    abort("oracle polynomial arity mismatch")
  }
  let mut numerator = 0
  let mut denominator = 1
  for term in @oracle.array(@polynomial.terms(polynomial)) {
    let mut term_numerator = @oracle.int_of_integer(
      @exact.numerator(term.coefficient),
    )
    let term_denominator = @oracle.int_of_binary(
      @exact.denominator(term.coefficient),
    )
    for i, exponent in @oracle.array(term.exponents) {
      for _ in 0..<@oracle.int_of_nat(exponent) {
        term_numerator *= values[i]
      }
    }
    numerator = numerator * term_denominator + term_numerator * denominator
    denominator *= term_denominator
  }
  if numerator < 0 {
    -1
  } else if numerator > 0 {
    1
  } else {
    0
  }
}

///|
fn oracle_relation(relation : @realcad.Relation, sign : Int32) -> Bool {
  match relation {
    LessZero => sign < 0
    AtMostZero => sign <= 0
    EqualZero => sign == 0
    NotZero => sign != 0
    AtLeastZero => sign >= 0
    GreaterZero => sign > 0
  }
}

///|
fn oracle_source(
  formula : Formula,
  values : Array[Int32],
  domain : Array[Int32],
) -> Bool {
  match formula {
    Truth(value) => value
    Atom(polynomial, relation) =>
      oracle_relation(relation, oracle_sign(polynomial, values))
    Negation(body) => !oracle_source(body, values, domain)
    Conjunction(left, right) =>
      oracle_source(left, values, domain) &&
      oracle_source(right, values, domain)
    Disjunction(left, right) =>
      oracle_source(left, values, domain) ||
      oracle_source(right, values, domain)
    Exists(body) =>
      domain.any(fn(value) { oracle_source(body, [..values, value], domain) })
    Forall(body) =>
      domain.all(fn(value) { oracle_source(body, [..values, value], domain) })
  }
}

///|
fn oracle_matrix(formula : @realcad.Formula, values : Array[Int32]) -> Bool {
  match formula {
    Truth(value) => value
    Atom(polynomial, relation) =>
      oracle_relation(relation, oracle_sign(polynomial, values))
    Negation(body) => !oracle_matrix(body, values)
    Conjunction(left, right) =>
      oracle_matrix(left, values) && oracle_matrix(right, values)
    Disjunction(left, right) =>
      oracle_matrix(left, values) || oracle_matrix(right, values)
  }
}

///|
fn oracle_prefix(
  prefix : @core.Chain[Quantifier],
  matrix : @realcad.Formula,
  values : Array[Int32],
  domain : Array[Int32],
) -> Bool {
  match prefix {
    Nil => oracle_matrix(matrix, values)
    Cons(Exists, rest) =>
      domain.any(fn(value) {
        oracle_prefix(rest, matrix, [..values, value], domain)
      })
    Cons(Forall, rest) =>
      domain.all(fn(value) {
        oracle_prefix(rest, matrix, [..values, value], domain)
      })
  }
}

///|
fn test_assignments(
  arity : Int32,
  domain : Array[Int32],
) -> Array[Array[Int32]] {
  if arity == 0 {
    [[]]
  } else {
    let result = []
    for previous in test_assignments(arity - 1, domain) {
      for value in domain {
        result.push([..previous, value])
      }
    }
    result
  }
}

///|
fn test_normalize(free_count : Int32, formula : Formula) -> Prenex {
  match normalize(@oracle.nat(free_count), formula) {
    Ok(prenex) => prenex
    Err(_) => abort("unexpected normalization failure")
  }
}

///|
fn test_matrix_invariants(
  formula : @realcad.Formula,
  arity : @core.Nat,
) -> Bool {
  match formula {
    Truth(_) => true
    Atom(polynomial, _) => @polynomial.variables(polynomial).equal(arity)
    Negation(_) => false
    Conjunction(left, right) | Disjunction(left, right) =>
      test_matrix_invariants(left, arity) &&
      test_matrix_invariants(right, arity)
  }
}

///|
fn check_generated_fixture(
  free_count : Int32,
  domain : Array[Int32],
  formula : Formula,
  expected : Array[Bool],
) -> Unit raise {
  let prenex = test_normalize(free_count, formula)
  assert_eq(source(prenex), formula)
  assert_eq(free_variables(prenex), @oracle.nat(free_count))
  assert_true(test_matrix_invariants(matrix(prenex), variables(prenex)))
  assert_eq(
    check(@oracle.nat(free_count), formula, certificate(prenex)),
    Some(prenex),
  )
  let assignments = test_assignments(free_count, domain)
  assert_eq(assignments.length(), expected.length())
  for i, values in assignments {
    let direct = oracle_source(formula, values, domain)
    let normalized = oracle_prefix(
      quantifiers(prenex),
      matrix(prenex),
      values,
      domain,
    )
    assert_eq(direct, expected[i])
    assert_eq(normalized, expected[i])
  }
}

///|
fn test_injections(
  source_arity : Int32,
  target_arity : Int32,
) -> Array[Array[Int32]] {
  if source_arity == 0 {
    [[]]
  } else {
    let result = []
    for previous in test_injections(source_arity - 1, target_arity) {
      for slot in 0..<target_arity {
        if !previous.contains(slot) {
          result.push([..previous, slot])
        }
      }
    }
    result
  }
}

///|
test "all small polynomial slot injections agree on every small target assignment" {
  let mut embeddings = 0
  let mut assignments = 0
  for old_arity in 0..<4 {
    let terms = [
      (1, 2, Array::make(old_arity, 1)),
      (-3, 1, Array::make(old_arity, 0)),
    ]
    for slot in 0..<old_arity {
      terms.push(
        (
          -1,
          3,
          Array::makei(old_arity, fn(i) { if i == slot { 2 } else { 0 } }),
        ),
      )
    }
    let original = test_polynomial(old_arity, terms)
    for target_arity in old_arity..<5 {
      for injection in test_injections(old_arity, target_arity) {
        let renamed = match
          rename_polynomial(
            original,
            @oracle.nat(target_arity),
            @oracle.chain(injection.map(@oracle.nat)),
          ) {
          Ok(result) => result
          Err(_) => abort("valid injection rejected")
        }
        embeddings += 1
        for target_values in test_assignments(target_arity, [-1, 0, 1]) {
          let source_values = injection.map(fn(slot) { target_values[slot] })
          assert_eq(
            oracle_sign(original, source_values),
            oracle_sign(renamed, target_values),
          )
          assignments += 1
        }
      }
    }
  }
  assert_eq(embeddings, 65)
  assert_eq(assignments, 3805)
}

///|
test "sibling binders keep distinct slots before hoisting" {
  let difference = test_polynomial(2, [(1, 1, [0, 1]), (-1, 1, [1, 0])])
  let formula = Conjunction(
    Exists(Atom(difference, EqualZero)),
    Exists(Atom(difference, NotZero)),
  )
  let prenex = test_normalize(1, formula)
  assert_eq(quantifiers(prenex), @oracle.chain([Quantifier::Exists, Exists]))
  let first = test_polynomial(3, [(1, 1, [0, 1, 0]), (-1, 1, [1, 0, 0])])
  let second = test_polynomial(3, [(1, 1, [0, 0, 1]), (-1, 1, [1, 0, 0])])
  assert_eq(
    matrix(prenex),
    @realcad.Conjunction(Atom(first, EqualZero), Atom(second, NotZero)),
  )
  check_generated_fixture(1, [-1, 0, 1], formula, [true, true, true])
  check_generated_fixture(
    1,
    [-1, 0, 1],
    Conjunction(
      Exists(Atom(difference, EqualZero)),
      Forall(Atom(difference, NotZero)),
    ),
    [false, false, false],
  )
}

///|
test "invalid local atom arity is checked in every branch" {
  let wrong = Atom(@polynomial.zero(@oracle.nat(1)), EqualZero)
  assert_eq(normalize(@oracle.nat(0), wrong), Err(ArityMismatch))
  assert_eq(
    normalize(@oracle.nat(0), Conjunction(Truth(false), wrong)),
    Err(ArityMismatch),
  )
  assert_eq(
    normalize(@oracle.nat(0), Disjunction(Truth(true), wrong)),
    Err(ArityMismatch),
  )
  assert_eq(normalize(@oracle.nat(1), Exists(wrong)), Err(ArityMismatch))
  assert_eq(
    normalize(@oracle.nat(0), Exists(Forall(wrong))),
    Err(ArityMismatch),
  )
}

///|
test "certificate binds source input arity prefix matrix and output" {
  let formula = Negation(Exists(Atom(test_variable(2, 1), LessZero)))
  let prenex = test_normalize(1, formula)
  let claim = certificate(prenex)
  assert_eq(check(@oracle.nat(1), formula, claim), Some(prenex))
  assert_eq(check(@oracle.nat(1), Truth(true), claim), None)
  assert_eq(check(@oracle.nat(0), formula, claim), None)
  assert_eq(
    check(@oracle.nat(1), formula, { ..claim, free_variables: @oracle.nat(0), }),
    None,
  )
  assert_eq(
    check(@oracle.nat(1), formula, { ..claim, source: Truth(true), }),
    None,
  )
  assert_eq(
    check(@oracle.nat(1), formula, {
      ..claim,
      quantifiers: @oracle.chain([Quantifier::Exists]),
    }),
    None,
  )
  assert_eq(
    check(@oracle.nat(1), formula, { ..claim, matrix: @realcad.Truth(true), }),
    None,
  )
  let other = test_normalize(1, Exists(Atom(test_variable(2, 1), EqualZero)))
  assert_eq(check(@oracle.nat(1), formula, certificate(other)), None)
}

///|
test "zero variables and empty atom families preserve unused binders" {
  for free_count in 0..<3 {
    for value in [false, true] {
      let formula : Formula = Forall(Negation(Exists(Negation(Truth(value)))))
      let prenex = test_normalize(free_count, formula)
      assert_eq(
        quantifiers(prenex),
        @oracle.chain([Quantifier::Forall, Forall]),
      )
      assert_eq(matrix(prenex), @realcad.Truth(value))
      assert_eq(variables(prenex), @oracle.nat(free_count + 2))
      assert_eq(qf_atoms(matrix(prenex)), @core.Nil)
      assert_eq(
        evaluate_signs(matrix(prenex), @core.Nil, @core.Nil),
        Some(value),
      )
      for values in test_assignments(free_count, [-1, 0, 1]) {
        assert_eq(
          oracle_prefix(quantifiers(prenex), matrix(prenex), values, [-1, 0, 1]),
          value,
        )
      }
    }
  }
  let zero = Atom(@polynomial.zero(@oracle.nat(0)), EqualZero)
  check_generated_fixture(0, [0], zero, [true])
}

///|
test "all six relations and complements match independent numeric signs" {
  let relations : Array[@realcad.Relation] = [
    LessZero,
    AtMostZero,
    EqualZero,
    NotZero,
    AtLeastZero,
    GreaterZero,
  ]
  for relation in relations {
    assert_eq(complement(complement(relation)), relation)
    for value in [-1, 0, 1] {
      let sign : @core.Ordering = if value < 0 {
        Less
      } else if value > 0 {
        Greater
      } else {
        Equal
      }
      assert_eq(
        relation_holds(relation, sign),
        oracle_relation(relation, value),
      )
      assert_eq(
        relation_holds(complement(relation), sign),
        !oracle_relation(relation, value),
      )
      let formula = Negation(Atom(test_variable(1, 0), relation))
      let prenex = test_normalize(1, formula)
      assert_eq(
        matrix(prenex),
        @realcad.Atom(test_variable(1, 0), complement(relation)),
      )
      assert_eq(
        oracle_matrix(matrix(prenex), [value]),
        oracle_source(formula, [value], [-1, 0, 1]),
      )
    }
  }
}

///|
test "sign evaluation validates lists and all Boolean branches" {
  let p = test_variable(1, 0)
  let q = test_polynomial(1, [(1, 1, [2]), (-1, 1, [0])])
  let formula = @realcad.Conjunction(
    Atom(p, GreaterZero),
    Disjunction(Atom(q, EqualZero), Negation(Atom(p, NotZero))),
  )
  assert_eq(qf_atoms(formula), @oracle.chain([p, q]))
  assert_eq(
    evaluate_signs(
      formula,
      @oracle.chain([p, q]),
      @oracle.chain([@core.Greater, Equal]),
    ),
    Some(true),
  )
  assert_eq(
    evaluate_signs(
      formula,
      @oracle.chain([q, p]),
      @oracle.chain([@core.Equal, Greater]),
    ),
    Some(true),
  )
  assert_eq(
    evaluate_signs(formula, @oracle.chain([p]), @oracle.chain([@core.Greater])),
    None,
  )
  assert_eq(
    evaluate_signs(
      formula,
      @oracle.chain([p, q]),
      @oracle.chain([@core.Greater]),
    ),
    None,
  )
  assert_eq(
    evaluate_signs(
      @realcad.Truth(true),
      @core.Nil,
      @oracle.chain([@core.Equal]),
    ),
    None,
  )
  assert_eq(
    evaluate_signs(
      formula,
      @oracle.chain([p, p, q]),
      @oracle.chain([@core.Greater, Less, Equal]),
    ),
    None,
  )
  assert_eq(
    evaluate_signs(
      @realcad.Conjunction(Truth(false), Atom(q, EqualZero)),
      @oracle.chain([p]),
      @oracle.chain([@core.Greater]),
    ),
    None,
  )
  assert_eq(
    evaluate_signs(
      @realcad.Disjunction(Truth(true), Atom(q, EqualZero)),
      @oracle.chain([p]),
      @oracle.chain([@core.Greater]),
    ),
    None,
  )
}

///|
test "polynomial embeddings validate zero polynomial arity and maps" {
  let p = test_polynomial(2, [(2, 3, [2, 1]), (-1, 2, [0, 1]), (3, 1, [0, 0])])
  let mapped = match
    rename_polynomial(
      p,
      @oracle.nat(3),
      @oracle.chain([@oracle.nat(2), @oracle.nat(0)]),
    ) {
    Ok(result) => result
    Err(_) => abort("embedding failed")
  }
  assert_eq(
    mapped,
    test_polynomial(3, [
      (2, 3, [1, 0, 2]),
      (-1, 2, [1, 0, 0]),
      (3, 1, [0, 0, 0]),
    ]),
  )
  for values in test_assignments(3, [-1, 0, 1]) {
    assert_eq(
      oracle_sign(p, [values[2], values[0]]),
      oracle_sign(mapped, values),
    )
  }
  for polynomial in [p, @polynomial.zero(@oracle.nat(2))] {
    assert_eq(
      rename_polynomial(
        polynomial,
        @oracle.nat(3),
        @oracle.chain([@oracle.nat(0)]),
      ),
      Err(ArityMismatch),
    )
    assert_eq(
      rename_polynomial(
        polynomial,
        @oracle.nat(3),
        @oracle.chain([@oracle.nat(0), @oracle.nat(0)]),
      ),
      Err(InvalidRenaming),
    )
    assert_eq(
      rename_polynomial(
        polynomial,
        @oracle.nat(3),
        @oracle.chain([@oracle.nat(0), @oracle.nat(3)]),
      ),
      Err(InvalidRenaming),
    )
  }
  assert_eq(
    rename_polynomial(
      @polynomial.zero(@oracle.nat(0)),
      @oracle.nat(0),
      @core.Nil,
    ),
    Ok(@polynomial.zero(@oracle.nat(0))),
  )
}
