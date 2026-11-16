///|
fn review_relabel_solution(
  value : SolutionCertificate,
  sys : SystemCertificate,
) -> SolutionCertificate {
  {
    system: sys,
    bound: { ..value.bound, system: sys, },
    whole: { ..value.whole, system: sys, },
    roots: @core.map(value.roots, fn(root) {
      { system: sys, count: { ..root.count, system: sys, }, }
    }),
  }
}

///|
test "independent dependent extension is the selected parent root not a free quotient" {
  for positive in [true, false] {
    let first = review_sqrt2(positive)
    let second = extension(
      p(first.field, [-2, 0, 1]),
      if positive {
        interval(1, 2)
      } else {
        interval(-2, -1)
      },
    )
    let alpha = must(embed(second.field, first.generator))
    let beta = second.generator
    let difference = must(scalar_subtract(beta, alpha))
    assert_false(
      representative(difference) == representative(scalar_zero(second.field)),
    )
    sign_is(difference, @core.Equal)
    assert_true(scalar_inverse(difference) is Err(ZeroDivisor))
    let dropped = must(
      polynomial(
        second.field,
        @oracle.chain([s(second.field, 7), difference, difference]),
      ),
    )
    assert_eq(degree(dropped), Some(@oracle.nat(0)))
    equal_is(must(evaluate(dropped, beta)), s(second.field, 7))
    // beta+alpha vanishes on the unselected component beta=-alpha. Its inverse
    // exists at beta=alpha and equals alpha/4, for either real embedding.
    let denominator = must(scalar_add(beta, alpha))
    let inverse = must(scalar_inverse(denominator))
    let expected = must(scalar_divide(alpha, s(second.field, 4)))
    equal_is(inverse, expected)
    sign_is(inverse, if positive { @core.Greater } else { @core.Less })
    equal_is(
      must(scalar_multiply(denominator, inverse)),
      scalar_one(second.field),
    )
    let unit = must(
      polynomial(
        second.field,
        @oracle.chain([scalar_one(second.field), difference]),
      ),
    )
    let dividend = p(second.field, [2, 3, 1])
    let divided = must(divide(dividend, unit))
    assert_true(must(polynomial_equal(divided.quotient, dividend)))
    assert_true(is_zero(divided.remainder))
    let value = must(scalar_add(scalar_one(second.field), difference))
    let foreign = must(scalar_sign(value)).certificate
    assert_true(check_scalar(value, @core.Greater, foreign))
    assert_false(check_scalar(scalar_one(second.field), @core.Greater, foreign))
  }
}

///|
test "independent coherent foreign contexts preserve sign but cannot replace certificates" {
  let base = rational_field()
  let definition = p(base, [-2, 0, 1])
  let first = review_sqrt2(true)
  let wide = extension(definition, interval(0, 2))
  let negative = review_sqrt2(false)
  let positive_in_negative = scalar_negate(negative.generator)
  assert_false(same_field(first.field, wide.field))
  assert_false(same_field(first.field, negative.field))
  for other in [wide.generator, positive_in_negative] {
    let proof = must(scalar_sign(other)).certificate
    assert_eq(proof.sign, @core.Greater)
    assert_false(check_scalar(first.generator, @core.Greater, proof))
    assert_true(scalar_equal(first.generator, other) is Err(DifferentField))
    assert_true(embed(first.field, other) is Err(DifferentField))
  }
  let a = p(first.field, [-2, 0, 1])
  let b = p(wide.field, [-2, 0, 1])
  let sys = must(system(b))
  let root = must(root_in_interval(sys, interval(1, 2)))
  let proof = root_certificate(root)
  assert_false(check_system(a, system_certificate(sys)))
  assert_false(check_root(a, proof))
  assert_false(check_root_result(a, root, proof))
  assert_true(root_from_certificate(a, proof) is Err(InvalidCertificate))
}

///|
test "independent whole source substitutions fail despite identical squarefree roots" {
  let field = rational_field()
  let common = p(field, [2, -3, 1])
  let source = must(multiply(common, p(field, [-1, 1])))
  let other = must(multiply(common, p(field, [-2, 1])))
  let a = finish(must(start(source)), 100)
  let b = finish(must(start(other)), 100)
  let pa = solution_certificate(a)
  let pb = solution_certificate(b)
  assert_true(
    must(
      polynomial_equal(
        squarefree(must(system(source))),
        squarefree(must(system(other))),
      ),
    ),
  )
  assert_true(check_isolation(source, pa))
  assert_true(check_isolation(other, pb))
  assert_false(check_isolation(source, pb))
  assert_false(check_isolation_result(source, b, pb))
  assert_false(check_system(source, pb.system))
  assert_true(
    system_from_certificate(source, pb.system) is Err(InvalidCertificate),
  )
  // Rebinding every source field yields a valid certificate only when its
  // actual interval/count claims are true for the new source.
  let relabeled = review_relabel_solution(pb, pa.system)
  assert_true(check_isolation(source, relabeled))
  let foreign = p(field, [2, 3, 1])
  let foreign_result = finish(must(start(foreign)), 100)
  let foreign_proof = solution_certificate(foreign_result)
  let forged = review_relabel_solution(foreign_proof, pa.system)
  assert_false(check_isolation(source, forged))
  let forged_root = @core.nth(forged.roots, @oracle.nat(0)).unwrap()
  assert_false(check_root(source, forged_root))
  assert_true(
    root_from_certificate(source, forged_root) is Err(InvalidCertificate),
  )
}

///|
test "independent coherent counts bounds and whole solution payloads are checked" {
  let field = rational_field()
  let source = p(field, [-2, 0, 1])
  let other = p(field, [-3, 0, 1])
  let sys = must(system(source))
  let foreign = must(system(other))
  let span = interval(1, 2)
  let count = must(count_between(sys, span))
  let foreign_count = must(count_between(foreign, span))
  assert_eq(count.count, foreign_count.count)
  assert_false(check_count(sys, span, count.count, foreign_count))
  assert_false(
    check_count(sys, interval(0, 1), foreign_count.count, {
      ..foreign_count,
      system: system_certificate(sys),
      interval: interval(0, 1),
    }),
  )
  let proof = system_certificate(sys)
  // Strict bound: 1+sum|nonleading monic coefficients| is 3, so equality fails.
  assert_false(check_bound(sys, { system: proof, bound: q(3, 1), }))
  assert_true(check_bound(sys, { system: proof, bound: q(4, 1), }))
  assert_false(
    check_bound(sys, { system: system_certificate(foreign), bound: q(4, 1), }),
  )
  let result = finish(must(start(source)), 100)
  let cert = solution_certificate(result)
  let roots = @oracle.array(roots(result))
  assert_eq(roots.length(), 2)
  assert_false(check_root_result(source, roots[0], root_certificate(roots[1])))
  assert_false(
    check_isolation(source, { ..cert, roots: @core.reverse(cert.roots), }),
  )
  assert_false(
    check_isolation(source, {
      ..cert,
      roots: @core.Cons(
        root_certificate(roots[0]),
        @core.Cons(root_certificate(roots[0]), @core.Nil),
      ),
    }),
  )
}

///|
test "independent opaque system sequence and squarefree payload substitutions rejected" {
  let field = rational_field()
  let source = p(field, [-2, 0, 1])
  let no_roots = p(field, [1, 0, 1])
  let sys = must(system(source))
  let foreign = must(system(no_roots))
  let forged_system = System::{ ..sys, sequence: foreign.sequence, }
  let span = interval(-2, 2)
  let false_count = must(count_between(forged_system, span))
  assert_eq(false_count.count, @oracle.nat(0))
  assert_false(check_count(forged_system, span, false_count.count, false_count))
  let root = must(root_in_interval(sys, interval(1, 2)))
  let forged_root = Root::{
    ..root,
    system: {
      ..root.system,
      squarefree: foreign.squarefree,
      sequence: foreign.sequence,
    },
  }
  assert_false(check_root_result(source, forged_root, root_certificate(root)))
  assert_true(adjoin(forged_root) is Err(InvalidCertificate))
  assert_false(
    check_bound(forged_system, {
      system: system_certificate(sys),
      bound: q(4, 1),
    }),
  )
  let result = finish(must(start(source)), 100)
  let forged_result = SolutionSet::{ ..result, system: forged_system, }
  assert_false(
    check_isolation_result(source, forged_result, solution_certificate(result)),
  )
}
