///|
fn polynomial_fixture(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial raise {
  match
    @poly.polynomial(
      @oracle.nat(variables),
      @oracle.chain(
        terms.map(fn(term) {
          let (coefficient, powers) = term
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: @oracle.chain(powers.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(p) => p
    Err(_) => fail("invalid test polynomial")
  }
}

///|
fn finish(problem : Problem, fuel : Int32) -> Decomposition raise {
  match run(start(problem), @oracle.nat(fuel)) {
    Ok(Complete(result)) => result
    Ok(Paused(_)) => fail("test exhausted transition budget")
    Err(error) => {
      debug_inspect(error, content="")
      fail("CAD error")
    }
  }
}

///|
fn make_problem(variables : Int32, formula : @qf.Formula) -> Problem raise {
  match prepare(@oracle.nat(variables), formula) {
    Ok(problem) => problem
    Err(_) => fail("CAD prepare")
  }
}

///|
test "zero dimensions and arbitrary empty families cover the nonempty real domain" {
  for variables in 0..<=4 {
    let problem = make_problem(variables, @qf.Truth(true))
    let result = finish(problem, 200)
    assert_true(check_result(problem, result, certificate(result)))
    let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain(
      [
        for i in 0..<variables => {
          if i % 2 == 0 {
            @logic.Quantifier::Forall
          } else {
            @logic.Quantifier::Exists
          }
        }
      ],
    )
    assert_eq(sentence(result, prefix), Ok(true))
  }
}

///|
test "one variable irrational roots agree with exact rational signs and checked QE" {
  let p = polynomial_fixture(1, [(1, [2]), (-2, [0])])
  let problem = make_problem(1, @qf.Atom(p, @qf.AtLeastZero))
  let result = finish(problem, 500)
  let proof = certificate(result)
  assert_true(check_result(problem, result, proof))
  assert_eq(
    sentence(result, @core.Cons(@logic.Quantifier::Exists, @core.Nil)),
    Ok(true),
  )
  assert_eq(
    sentence(result, @core.Cons(@logic.Quantifier::Forall, @core.Nil)),
    Ok(false),
  )
  let qe = match eliminate(result, @oracle.nat(1), @core.Nil) {
    Ok(v) => v
    Err(_) => fail("QE")
  }
  assert_true(
    check_elimination_result(
      problem,
      @oracle.nat(1),
      @core.Nil,
      qe,
      elimination_certificate(qe),
    ),
  )
  for numerator in -7..<=7 {
    let point = rational_point(
      @core.Cons(@oracle.rational(numerator, 3), @core.Nil),
    )
    assert_eq(
      evaluate_formula(point, quantifier_free(qe)),
      Ok(numerator * numerator >= 18),
    )
  }
  match witness(result) {
    Ok(Some(point)) => assert_true(check_witness(problem, point))
    _ => fail("witness")
  }
}

///|
test "two and three variable linear fibres preserve quantifier alternation" {
  for variables in 2..<=3 {
    let terms = Array(capacity=0)
    for index in 0..<variables {
      terms.push(
        (
          if index == variables - 1 {
            1
          } else {
            -1
          },
          [
            for j in 0..<variables => if j == index { 1 } else { 0 }
          ],
        ),
      )
    }
    let p = polynomial_fixture(variables, terms)
    let problem = make_problem(variables, @qf.Atom(p, @qf.EqualZero))
    let result = finish(problem, 5000)
    assert_true(check_result(problem, result, certificate(result)))
    let yes : @core.Chain[@logic.Quantifier] = @oracle.chain(
      [
        for i in 0..<variables => {
          if i == variables - 1 {
            @logic.Quantifier::Exists
          } else {
            @logic.Quantifier::Forall
          }
        }
      ],
    )
    let no : @core.Chain[@logic.Quantifier] = @oracle.chain(
      [
        for _ in 0..<variables => @logic.Quantifier::Forall
      ],
    )
    assert_eq(sentence(result, yes), Ok(true))
    assert_eq(sentence(result, no), Ok(false))
  }
}

///|
test "continuations, malformed arity and certificate source substitutions" {
  let p = polynomial_fixture(1, [(1, [1])])
  let problem = make_problem(1, @qf.Atom(p, @qf.GreaterZero))
  let initial = start(problem)
  assert_true(run(initial, @core.Zero) is Ok(Paused(_)))
  let result = finish(problem, 300)
  let proof = certificate(result)
  assert_true(check(problem, proof) is Some(_))
  assert_true(check(problem, { ..proof, arity: @oracle.nat(2), }) is None)
  let other = make_problem(1, @qf.Atom(p, @qf.AtMostZero))
  let other_result = finish(other, 300)
  assert_true(check(problem, certificate(other_result)) is None)
  assert_false(check_result(problem, other_result, proof))
  assert_true(check(problem, { ..proof, tree: Leaf(true), }) is None)
  assert_true(
    prepare(@oracle.nat(2), @qf.Atom(p, @qf.EqualZero)) is Err(WrongArity),
  )
  assert_false(check_witness(problem, rational_point(@core.Nil)))
}

///|
test "circle projection returns a genuine rational polynomial quantifier-free formula" {
  let circle = polynomial_fixture(2, [(1, [2, 0]), (1, [0, 2]), (-1, [0, 0])])
  let problem = make_problem(2, @qf.Atom(circle, @qf.EqualZero))
  let result = finish(problem, 20000)
  assert_true(check_result(problem, result, certificate(result)))
  let prefix : @core.Chain[@logic.Quantifier] = @core.Cons(
    @logic.Quantifier::Exists,
    @core.Nil,
  )
  let qe = match eliminate(result, @oracle.nat(1), prefix) {
    Ok(v) => v
    Err(_) => fail("circle QE")
  }
  assert_true(
    check_elimination_result(
      problem,
      @oracle.nat(1),
      prefix,
      qe,
      elimination_certificate(qe),
    ),
  )
  for numerator in -9..<=9 {
    let point = rational_point(
      @core.Cons(@oracle.rational(numerator, 5), @core.Nil),
    )
    assert_eq(
      evaluate_formula(point, quantifier_free(qe)),
      Ok(numerator * numerator <= 25),
    )
  }
}

///|
test "four-variable affine relation supports full quantifier alternation" {
  let p = polynomial_fixture(4, [
    (1, [0, 0, 0, 1]),
    (-1, [1, 0, 0, 0]),
    (-1, [0, 1, 0, 0]),
    (-1, [0, 0, 1, 0]),
  ])
  let problem = make_problem(4, @qf.Atom(p, @qf.EqualZero))
  let result = finish(problem, 30000)
  assert_true(check_result(problem, result, certificate(result)))
  let yes : @core.Chain[@logic.Quantifier] = @oracle.chain([
    @logic.Quantifier::Forall,
    @logic.Quantifier::Exists,
    @logic.Quantifier::Forall,
    @logic.Quantifier::Exists,
  ])
  let no : @core.Chain[@logic.Quantifier] = @oracle.chain([
    @logic.Quantifier::Exists,
    @logic.Quantifier::Forall,
    @logic.Quantifier::Exists,
    @logic.Quantifier::Forall,
  ])
  assert_eq(sentence(result, yes), Ok(true))
  assert_eq(sentence(result, no), Ok(false))
}

///|
test "three-variable sphere eliminates to the exact closed disk with two free variables" {
  let sphere = polynomial_fixture(3, [
    (1, [2, 0, 0]),
    (1, [0, 2, 0]),
    (1, [0, 0, 2]),
    (-1, [0, 0, 0]),
  ])
  let problem = make_problem(3, @qf.Atom(sphere, @qf.EqualZero))
  let result = finish(problem, 40000)
  assert_true(check_result(problem, result, certificate(result)))
  let prefix : @core.Chain[@logic.Quantifier] = @core.Cons(
    @logic.Quantifier::Exists,
    @core.Nil,
  )
  let qe = match eliminate(result, @oracle.nat(2), prefix) {
    Ok(v) => v
    Err(_) => fail("sphere QE")
  }
  for x in -4..<=4 {
    for y in -4..<=4 {
      let point = rational_point(
        @oracle.chain([@oracle.rational(x, 3), @oracle.rational(y, 3)]),
      )
      assert_eq(
        evaluate_formula(point, quantifier_free(qe)),
        Ok(x * x + y * y <= 9),
      )
    }
  }
  assert_true(
    check_elimination_result(
      problem,
      @oracle.nat(2),
      prefix,
      qe,
      elimination_certificate(qe),
    ),
  )
}

///|
test "irrational coefficient nullification retains the whole final fibre" {
  let root = polynomial_fixture(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])])
  let zero_y = polynomial_fixture(3, [(1, [0, 1, 0])])
  let nullified = polynomial_fixture(3, [
    (1, [2, 0, 1]),
    (-2, [0, 0, 1]),
    (-1, [0, 1, 0]),
  ])
  let positive_z = polynomial_fixture(3, [(1, [0, 0, 1])])
  let matrix = @qf.Conjunction(
    @qf.Atom(root, @qf.EqualZero),
    @qf.Conjunction(
      @qf.Atom(zero_y, @qf.EqualZero),
      @qf.Conjunction(
        @qf.Atom(nullified, @qf.EqualZero),
        @qf.Atom(positive_z, @qf.GreaterZero),
      ),
    ),
  )
  let problem = make_problem(3, matrix)
  let result = finish(problem, 40000)
  assert_true(check_result(problem, result, certificate(result)))
  let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain([
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
  ])
  assert_eq(sentence(result, prefix), Ok(true))
  match witness(result) {
    Ok(Some(point)) => assert_true(check_witness(problem, point))
    _ => fail("nullification witness")
  }
}

///|
test "three nested radical coordinates are exact reusable tower values" {
  let px = polynomial_fixture(3, [(1, [2, 0, 0]), (-2, [0, 0, 0])])
  let py = polynomial_fixture(3, [(1, [0, 2, 0]), (-1, [1, 0, 0])])
  let pz = polynomial_fixture(3, [(1, [0, 0, 2]), (-1, [0, 1, 0])])
  let x = polynomial_fixture(3, [(1, [1, 0, 0])])
  let y = polynomial_fixture(3, [(1, [0, 1, 0])])
  let z = polynomial_fixture(3, [(1, [0, 0, 1])])
  let matrix = @qf.Conjunction(
    @qf.Atom(px, @qf.EqualZero),
    @qf.Conjunction(
      @qf.Atom(py, @qf.EqualZero),
      @qf.Conjunction(
        @qf.Atom(pz, @qf.EqualZero),
        @qf.Conjunction(
          @qf.Atom(x, @qf.GreaterZero),
          @qf.Conjunction(
            @qf.Atom(y, @qf.GreaterZero),
            @qf.Atom(z, @qf.GreaterZero),
          ),
        ),
      ),
    ),
  )
  let problem = make_problem(3, matrix)
  let result = finish(problem, 40000)
  assert_true(check_result(problem, result, certificate(result)))
  let prefix : @core.Chain[@logic.Quantifier] = @oracle.chain([
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
    @logic.Quantifier::Exists,
  ])
  assert_eq(sentence(result, prefix), Ok(true))
  match witness(result) {
    Ok(Some(point)) => {
      assert_true(check_witness(problem, point))
      let z = match @core.nth(coordinates(point), @oracle.nat(2)) {
        Some(v) => v
        None => fail("third coordinate")
      }
      let eighth = match scalar_power(z, @oracle.nat(8)) {
        Ok(v) => v
        Err(_) => fail("eighth power")
      }
      assert_eq(
        @tower.scalar_equal(
          eighth,
          @tower.rational(point_field(point), @oracle.rational(2, 1)),
        ),
        Ok(true),
      )
    }
    _ => fail("radical witness")
  }
}

///|
test "complete stack and quantifier proof bundles stay bound to their original input" {
  let x = polynomial_fixture(1, [(1, [1])])
  let shifted_x = polynomial_fixture(1, [(1, [1]), (-1, [0])])
  let problem = make_problem(1, @qf.Atom(x, @qf.GreaterZero))
  let other = make_problem(1, @qf.Atom(shifted_x, @qf.GreaterZero))
  let result = finish(problem, 300)
  let other_result = finish(other, 300)
  let proof = certificate(result)
  match (proof.tree, certificate(other_result).tree) {
    (Stack(isolation, cells), Stack(other_isolation, other_cells)) => {
      assert_true(
        check(problem, { ..proof, tree: Stack(other_isolation, other_cells), })
        is None,
      )
      assert_true(
        check(problem, {
          ..proof,
          tree: Stack(isolation, @core.reverse(cells)),
        })
        is None,
      )
      assert_true(
        check(problem, {
          ..proof,
          tree: Stack(isolation, @core.drop(@oracle.nat(1), cells)),
        })
        is None,
      )
      match cells {
        Cons(first, rest) => {
          let wrong_signs = @core.map(first.signs, fn(s) {
            match s {
              Less => @core.Greater
              Greater => @core.Less
              Equal => @core.Less
            }
          })
          assert_true(
            check(problem, {
              ..proof,
              tree: Stack(
                isolation,
                @core.Cons({ ..first, signs: wrong_signs, }, rest),
              ),
            })
            is None,
          )
          assert_true(
            check(problem, {
              ..proof,
              tree: Stack(
                isolation,
                @core.Cons({ ..first, subtree: Leaf(true), }, rest),
              ),
            })
            is None,
          )
        }
        _ => fail("empty stack")
      }
      assert_true(
        check(problem, {
          ..proof,
          tree: Stack({ ..isolation, roots: @core.Nil, }, cells),
        })
        is None,
      )
    }
    _ => fail("stack proof")
  }
  let exists : @core.Chain[@logic.Quantifier] = @core.Cons(
    @logic.Quantifier::Exists,
    @core.Nil,
  )
  let forall : @core.Chain[@logic.Quantifier] = @core.Cons(
    @logic.Quantifier::Forall,
    @core.Nil,
  )
  let qe = match eliminate(result, @core.Zero, exists) {
    Ok(v) => v
    Err(_) => fail("exists QE")
  }
  let wrong_qe = match eliminate(result, @core.Zero, forall) {
    Ok(v) => v
    Err(_) => fail("forall QE")
  }
  assert_true(
    check_elimination(
      problem,
      @core.Zero,
      exists,
      elimination_certificate(wrong_qe),
    )
    is None,
  )
  assert_false(
    check_elimination_result(
      problem,
      @core.Zero,
      exists,
      wrong_qe,
      elimination_certificate(qe),
    ),
  )
}
