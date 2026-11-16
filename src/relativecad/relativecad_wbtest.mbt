///|
fn test_poly(values : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(values[i], 1),
            exponents: @core.Cons(@oracle.nat(i), @core.Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_field(negative : Bool) -> @numberfield.Field {
  let root = @real.number({
    polynomial: test_poly([-2, 0, 1]),
    interval: {
      lower: @oracle.rational(if negative { -2 } else { 1 }, 1),
      upper: @oracle.rational(if negative { -1 } else { 2 }, 1),
    },
  }).unwrap()
  let primes : @core.Chain[@binary.Binary] = @oracle.chain(
    [3, 5, 7, 11, 13].map(@oracle.binary),
  )
  match
    @minimal.normalize(
      root,
      primes,
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    Normalized(value, proof) =>
      @numberfield.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("fixture factorization did not finish")
  }
}

///|
fn test_relative(
  field : @numberfield.Field,
  coefficients : Array[Array[Int32]],
) -> @ordered.Polynomial {
  @ordered.polynomial(
    field,
    @oracle.chain(
      coefficients.map(fn(c) {
        @numberfield.element(field, test_poly(c)).unwrap()
      }),
    ),
  ).unwrap()
}

///|
fn completed(problem : Problem) -> Decomposition {
  match run(start(problem).unwrap(), @oracle.nat(2048)).unwrap() {
    Complete(value) => value
    _ => abort("relative CAD fixture budget exhausted")
  }
}

///|
test "fourth root of two Boolean cells and exact rational signs" {
  let field = test_field(false)
  let p = test_relative(field, [[0, -1], [0], [1]])
  let cut = test_relative(field, [[-1], [1]])
  let problem = prepare(
    field,
    Conjunction(Atom(p, LessZero), Atom(cut, GreaterZero)),
  ).unwrap()
  let solution = completed(problem)
  assert_eq(@oracle.array(cells(solution)).map(fn(cell) { cell.holds }), [
    false, false, false, false, true, false, false,
  ])
  assert_true(check(problem, certificate(solution)) is Some(_))
  assert_true(witness(solution) is Some(RationalPoint(_)))
  assert_false(universally_true(solution))
  for y in -3..<=3 {
    let sign = scalar_at(p, @oracle.rational(y, 1)).unwrap()
    assert_eq(sign, if y >= -1 && y <= 1 { @core.Less } else { @core.Greater })
  }
  let equal = completed(prepare(field, Atom(p, EqualZero)).unwrap())
  assert_eq(@oracle.array(cells(equal)).map(fn(cell) { cell.holds }), [
    false, true, false, true, false,
  ])
  assert_true(witness(equal) is Some(AlgebraicPoint(_)))
}

///|
test "negative base embedding constants zero and wrong field" {
  let field = test_field(true)
  let p = test_relative(field, [[0, -1], [0], [1]])
  let solution = completed(prepare(field, Atom(p, GreaterZero)).unwrap())
  assert_eq(@oracle.array(cells(solution)).length(), 1)
  assert_true(universally_true(solution))
  let zero = @ordered.zero(field)
  let tautology = completed(
    prepare(field, Conjunction(Atom(zero, EqualZero), Truth(true))).unwrap(),
  )
  assert_true(universally_true(tautology))
  let falsehood = completed(
    prepare(field, Atom(@ordered.one(field), AtMostZero)).unwrap(),
  )
  assert_true(witness(falsehood) is None)
  let foreign = test_relative(test_field(false), [[1]])
  assert_true(
    prepare(field, Conjunction(Truth(false), Atom(foreign, EqualZero)))
    is Err(DifferentField),
  )
}

///|
test "repeated factors endpoints and resumable persistent state" {
  let field = test_field(false)
  let y = test_relative(field, [[0], [1]])
  let one = test_relative(field, [[-1], [1]])
  let squared = @ordered.multiply(y, y).unwrap()
  let p = @ordered.multiply(squared, @ordered.multiply(one, one).unwrap()).unwrap()
  let problem = prepare(field, Negation(Atom(p, LessZero))).unwrap()
  let machine = start(problem).unwrap()
  assert_true(run(machine, @core.Zero).unwrap() is Paused(_))
  let a = completed(problem)
  assert_true(universally_true(a))
  assert_eq(@oracle.array(cells(a)).length(), 5)
  let mut current = machine
  let mut result : Decomposition? = None
  for _ in 0..<2048 {
    match run(current, @core.Succ(@core.Zero)).unwrap() {
      Paused(next) => current = next
      Complete(value) => {
        result = Some(value)
        break
      }
    }
  }
  assert_eq(certificate(result.unwrap()), certificate(a))
  match run(machine, @oracle.nat(2048)).unwrap() {
    Complete(value) => assert_eq(certificate(value), certificate(a))
    _ => abort("persistent continuation failed")
  }
}

///|
test "missing roots forged signs values and foreign embedding are rejected" {
  let field = test_field(false)
  let p = test_relative(field, [[0, -1], [0], [1]])
  let problem = prepare(field, Atom(p, EqualZero)).unwrap()
  let proof = certificate(completed(problem))
  let wrong : Certificate = {
    ..proof,
    isolation: { ..proof.isolation, roots: @core.Nil, },
  }
  assert_true(check(problem, wrong) is None)
  let wrong : Certificate = { ..proof, cells: @core.Nil, }
  assert_true(check(problem, wrong) is None)
  let first = @oracle.array(proof.cells)[0]
  let rest = @core.drop(@core.Succ(@core.Zero), proof.cells)
  let wrong : Certificate = {
    ..proof,
    cells: @core.Cons({ ..first, holds: !first.holds, }, rest),
  }
  assert_true(check(problem, wrong) is None)
  let wrong : Certificate = {
    ..proof,
    cells: @core.Cons(
      { ..first, signs: @core.Cons(@core.Equal, @core.Nil), },
      rest,
    ),
  }
  assert_true(check(problem, wrong) is None)
  let negative = test_field(true)
  let other = prepare(
    negative,
    Atom(test_relative(negative, [[0, -1], [0], [1]]), EqualZero),
  ).unwrap()
  assert_true(check(other, proof) is None)
}
