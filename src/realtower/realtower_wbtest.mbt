///|
fn[A] must(value : Result[A, TowerError]) -> A raise {
  match value {
    Ok(a) => a
    Err(e) => fail("unexpected tower error: \{e.to_repr()}")
  }
}

///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn s(field : Field, n : Int32) -> Scalar {
  rational(field, q(n, 1))
}

///|
fn p(field : Field, values : Array[Int32]) -> Polynomial raise {
  must(polynomial(field, @oracle.chain(values.map(fn(n) { s(field, n) }))))
}

///|
fn interval(a : Int32, b : Int32) -> @sturm.Interval {
  { lower: q(a, 1), upper: q(b, 1), }
}

///|
fn extension(value : Polynomial, span : @sturm.Interval) -> Extension raise {
  must(adjoin(must(root_in_interval(must(system(value)), span))))
}

///|
fn sign_is(value : Scalar, expected : @core.Ordering) -> Unit raise {
  let result = must(scalar_sign(value))
  assert_true(result.sign.equal(expected))
  assert_true(check_scalar(value, expected, result.certificate))
}

///|
fn equal_is(a : Scalar, b : Scalar) -> Unit raise {
  assert_true(must(scalar_equal(a, b)))
}

///|
fn finish(state : State, remaining : Int32) -> SolutionSet raise {
  if remaining <= 0 {
    fail("test isolation fuel exhausted")
  } else {
    match must(advance(state, @oracle.nat(1))) {
      Isolated(result) => result
      Paused(next) => finish(next, remaining - 1)
    }
  }
}

///|
test "rational base scalar arithmetic and polynomial source binding" {
  let field = rational_field()
  let a = rational(field, q(2, 3))
  let b = rational(field, q(-5, 7))
  equal_is(must(scalar_add(a, b)), rational(field, q(-1, 21)))
  equal_is(must(scalar_multiply(a, b)), rational(field, q(-10, 21)))
  equal_is(must(scalar_divide(a, b)), rational(field, q(-14, 15)))
  assert_true(scalar_inverse(scalar_zero(field)) is Err(ZeroDivisor))
  let poly = p(field, [1, -2, 1])
  let sys = must(system(poly))
  assert_true(check_system(poly, system_certificate(sys)))
  assert_false(check_system(p(field, [2, -2, 1]), system_certificate(sys)))
  assert_true(must(polynomial_equal(squarefree(sys), p(field, [-1, 1]))))
  let division = must(divide(poly, p(field, [-1, 1])))
  assert_true(is_zero(division.remainder))
  assert_true(must(polynomial_equal(division.quotient, p(field, [-1, 1]))))
  equal_is(
    must(evaluate_rational(must(derivative(poly)), q(2, 1))),
    s(field, 2),
  )
}

///|
test "reducible selected root inverse and nonzero residue semantic zero" {
  let base = rational_field()
  // (y-1)(y-2), with beta=1 selected by (0,1].
  let ext = extension(p(base, [2, -3, 1]), interval(0, 1))
  let beta = ext.generator
  sign_is(beta, Greater)
  equal_is(beta, s(ext.field, 1))
  let zero = must(scalar_subtract(beta, s(ext.field, 1)))
  assert_false(
    representative(zero).equal(representative(scalar_zero(ext.field))),
  )
  sign_is(zero, Equal)
  assert_true(scalar_inverse(zero) is Err(ZeroDivisor))
  // beta-2 is a zero divisor modulo the reducible definition, but is -1 here.
  let value = must(scalar_subtract(beta, s(ext.field, 2)))
  let inverse = must(scalar_inverse(value))
  sign_is(inverse, Less)
  equal_is(inverse, s(ext.field, -1))
  equal_is(must(scalar_multiply(value, inverse)), scalar_one(ext.field))
  let trimmed = must(
    polynomial(ext.field, @oracle.chain([s(ext.field, 7), zero])),
  )
  assert_true(degree(trimmed) is Some(Zero))
}

///|
test "negative conjugate and context and ancestor rejection" {
  let base = rational_field()
  let poly = p(base, [-2, 0, 1])
  let positive = extension(poly, interval(1, 2))
  let negative = extension(poly, interval(-2, -1))
  sign_is(positive.generator, Greater)
  sign_is(negative.generator, Less)
  assert_false(same_field(positive.field, negative.field))
  assert_true(embed(positive.field, negative.generator) is Err(DifferentField))
  assert_true(embed(base, positive.generator) is Err(DifferentField))
  assert_true(
    scalar_add(positive.generator, negative.generator) is Err(DifferentField),
  )
  assert_true(
    polynomial(positive.field, Cons(negative.generator, Nil))
    is Err(DifferentField),
  )
  let proof = must(scalar_sign(positive.generator)).certificate
  assert_false(check_scalar(negative.generator, Greater, proof))
  assert_false(check_scalar(positive.generator, Less, proof))
  equal_is(must(embed(positive.field, s(base, 5))), s(positive.field, 5))
}

///|
test "depth two and three nested radicals close ordered arithmetic" {
  let base = rational_field()
  let first = extension(p(base, [-2, 0, 1]), interval(1, 2))
  let alpha = first.generator
  let second_poly = must(
    polynomial(
      first.field,
      @oracle.chain([
        scalar_negate(alpha),
        scalar_zero(first.field),
        scalar_one(first.field),
      ]),
    ),
  )
  let second = extension(second_poly, interval(1, 2))
  let beta = second.generator
  let a2 = must(embed(second.field, alpha))
  equal_is(must(scalar_multiply(beta, beta)), a2)
  sign_is(must(scalar_subtract(a2, beta)), Greater)
  let third_poly = must(
    polynomial(
      second.field,
      @oracle.chain([
        scalar_negate(beta),
        scalar_zero(second.field),
        scalar_one(second.field),
      ]),
    ),
  )
  let third = extension(third_poly, interval(1, 2))
  let gamma = third.generator
  let b3 = must(embed(third.field, beta))
  let a3 = must(embed(third.field, alpha))
  equal_is(must(scalar_multiply(gamma, gamma)), b3)
  let fourth_power = must(scalar_multiply(b3, b3))
  equal_is(fourth_power, a3)
  equal_is(must(scalar_multiply(fourth_power, fourth_power)), s(third.field, 2))
  sign_is(must(scalar_subtract(b3, gamma)), Greater)
  sign_is(must(scalar_subtract(a3, b3)), Greater)
  let difference = must(scalar_subtract(gamma, s(third.field, 1)))
  let inverse = must(scalar_inverse(difference))
  equal_is(must(scalar_multiply(difference, inverse)), scalar_one(third.field))
  sign_is(inverse, Greater)
  assert_true(embed(second.field, gamma) is Err(DifferentField))
}

///|
test "endpoint roots repeated factors and rational all roots cover" {
  let field = rational_field()
  // (x-1)^2*x^3*(x+1), roots -1,0,1, counted once.
  let poly = must(
    multiply(
      must(multiply(p(field, [1, -2, 1]), p(field, [0, 0, 0, 1]))),
      p(field, [1, 1]),
    ),
  )
  let sys = must(system(poly))
  assert_true(
    must(count_between(sys, interval(-1, 0))).count.equal(@oracle.nat(1)),
  )
  assert_true(
    must(count_between(sys, interval(0, 1))).count.equal(@oracle.nat(1)),
  )
  assert_true(
    must(count_between(sys, interval(-2, -1))).count.equal(@oracle.nat(1)),
  )
  assert_true(
    must(count_between(sys, interval(-1, 1))).count.equal(@oracle.nat(2)),
  )
  let initial = must(isolate(sys))
  assert_true(must(advance(initial, Zero)) is Paused(_))
  let result = finish(initial, 100)
  let proof = solution_certificate(result)
  assert_true(@core.length(roots(result)).equal(@oracle.nat(3)))
  assert_true(check_isolation(poly, proof))
  assert_true(check_isolation_result(poly, result, proof))
  assert_true(check_bound(sys, proof.bound))
  let head = @oracle.array(roots(result))[0]
  assert_true(check_root_result(poly, head, root_certificate(head)))
  let refined = must(refine(head, @oracle.nat(3)))
  assert_true(check_root_result(poly, refined, root_certificate(refined)))
  assert_false(check_root_result(poly, refined, root_certificate(head)))
  assert_true(
    must(root_from_certificate(poly, root_certificate(head))).equal(head),
  )
  assert_true(must(system_from_certificate(poly, proof.system)).equal(sys))
  assert_false(check_isolation(p(field, [1, 1]), proof))
  assert_false(check_isolation(poly, { ..proof, roots: Nil, }))
  assert_false(
    check_isolation(poly, { ..proof, whole: { ..proof.whole, count: Zero, }, }),
  )
  assert_false(
    check_isolation(poly, {
      ..proof,
      bound: { ..proof.bound, bound: q(0, 1), },
    }),
  )
}

///|
test "no roots constants invalid intervals and semantic leading zeros" {
  let field = rational_field()
  let no_roots = p(field, [1, 0, 1])
  let result = finish(must(start(no_roots)), 100)
  assert_true(roots(result) is Nil)
  assert_true(
    check_isolation_result(no_roots, result, solution_certificate(result)),
  )
  let constant = p(field, [7])
  let constants = finish(must(start(constant)), 100)
  assert_true(roots(constants) is Nil)
  assert_true(check_isolation(constant, solution_certificate(constants)))
  assert_true(system(zero(field)) is Err(ZeroPolynomial))
  let sys = must(system(no_roots))
  assert_true(count_between(sys, interval(1, 1)) is Err(InvalidInterval))
  assert_true(root_in_interval(sys, interval(-2, 2)) is Err(InvalidInterval))
}
