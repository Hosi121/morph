///|
fn vector(values : Array[(Int32, Int32)]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(value) { @oracle.rational(value.0, value.1) }))
}

///|
fn checked(values : Array[(Int32, Int32)]) -> Distribution {
  match distribution(vector(values)) {
    Some(value) => value
    None => abort("invalid test distribution")
  }
}

///|
fn required(value : Distribution?) -> Distribution {
  match value {
    Some(value) => value
    None => abort("expected distribution")
  }
}

///|
test "constructors preserve the closed simplex and reject malformed measures" {
  assert_eq(distribution(@core.Nil), None)
  assert_eq(distribution(vector([(0, 1), (0, 1)])), None)
  assert_eq(distribution(vector([(2, 1), (-1, 1)])), None)
  assert_eq(distribution(vector([(1, 3), (1, 3)])), None)
  assert_eq(normalize(vector([(0, 1), (0, 1)])), None)
  assert_eq(normalize(vector([(-1, 1), (2, 1)])), None)
  assert_eq(uniform(@core.Zero), None)
  assert_eq(bernoulli(@oracle.rational(4, 3)), None)
  assert_eq(bernoulli(@oracle.rational(-1, 3)), None)
  assert_eq(
    required(bernoulli(@oracle.rational(0, 1))),
    checked([(1, 1), (0, 1)]),
  )
  assert_eq(
    required(uniform(@oracle.nat(3))),
    checked([(1, 3), (1, 3), (1, 3)]),
  )
  assert_eq(is_interior(checked([(1, 1), (0, 1)])), false)
  assert_eq(is_interior(checked([(1, 3), (2, 3)])), true)
  assert_eq(mass(checked([(1, 1)]), @oracle.nat(1)), None)
}

///|
test "enumerated integer measures agree with independent fraction expectations and variances" {
  // The host oracle clears denominators: E[X]=sum(w*x)/sum(w).
  for a in 0..<=4 {
    for b in 0..<=4 {
      for c in 0..<=4 {
        let total = a + b + c
        if total == 0 {
          continue
        }
        let d = required(normalize(vector([(a, 1), (b, 1), (c, 1)])))
        assert_eq(masses(d), vector([(a, total), (b, total), (c, total)]))
        let values = vector([(-2, 1), (1, 1), (3, 1)])
        let first = -2 * a + b + 3 * c
        let second = 4 * a + b + 9 * c
        assert_eq(expectation(d, values), Some(@oracle.rational(first, total)))
        assert_eq(
          variance(d, values),
          Some(@oracle.rational(second * total - first * first, total * total)),
        )
        assert_eq(
          event_probability(d, @oracle.chain([true, false, true])),
          Some(@oracle.rational(a + c, total)),
        )
        let conditioned = condition(d, @oracle.chain([true, false, true]))
        if a + c == 0 {
          assert_eq(conditioned, None)
        } else {
          assert_eq(
            masses(required(conditioned)),
            vector([(a, a + c), (0, 1), (c, a + c)]),
          )
        }
        let evidence = a + 2 * b + 3 * c
        let posterior = required(bayes(d, vector([(1, 1), (2, 1), (3, 1)])))
        assert_eq(
          masses(posterior),
          vector([(a, evidence), (2 * b, evidence), (3 * c, evidence)]),
        )
      }
    }
  }
}

///|
test "independent products and coarse graining preserve marginal laws" {
  for a in 0..<=4 {
    for b in 0..<=4 {
      let p = required(bernoulli(@oracle.rational(a, 4)))
      let q = required(bernoulli(@oracle.rational(b, 4)))
      let joint = product(p, q)
      assert_eq(
        masses(joint),
        vector([
          ((4 - a) * (4 - b), 16),
          ((4 - a) * b, 16),
          (a * (4 - b), 16),
          (a * b, 16),
        ]),
      )
      assert_eq(
        pushforward(
          joint,
          @oracle.nat(2),
          @oracle.chain([
            @oracle.nat(0),
            @oracle.nat(0),
            @oracle.nat(1),
            @oracle.nat(1),
          ]),
        ),
        Some(p),
      )
      assert_eq(
        pushforward(
          joint,
          @oracle.nat(2),
          @oracle.chain([
            @oracle.nat(0),
            @oracle.nat(1),
            @oracle.nat(0),
            @oracle.nat(1),
          ]),
        ),
        Some(q),
      )
      assert_eq(total_variation(p, q), Some(@oracle.rational((a - b).abs(), 4)))
      assert_eq(
        mixture(p, q, @oracle.rational(1, 2)),
        bernoulli(@oracle.rational(a + b, 8)),
      )
    }
  }
}

///|
test "dimension mismatches and impossible evidence are explicit" {
  let p = checked([(1, 1), (0, 1)])
  assert_eq(expectation(p, vector([(1, 1)])), None)
  assert_eq(covariance(p, vector([(1, 1)]), vector([(1, 1), (2, 1)])), None)
  assert_eq(condition(p, @oracle.chain([false, true])), None)
  assert_eq(condition(p, @oracle.chain([true])), None)
  assert_eq(event_probability(p, @oracle.chain([true])), None)
  assert_eq(bayes(p, vector([(0, 1), (1, 1)])), None)
  assert_eq(bayes(p, vector([(1, 1), (-1, 1)])), None)
  assert_eq(bayes(p, vector([(1, 1)])), None)
  assert_eq(mixture(p, p, @oracle.rational(2, 1)), None)
  assert_eq(mixture(p, checked([(1, 1)]), @oracle.rational(0, 1)), None)
  assert_eq(total_variation(p, checked([(1, 1)])), None)
  assert_eq(
    pushforward(p, @core.Zero, @oracle.chain([@core.Zero, @core.Zero])),
    None,
  )
  assert_eq(pushforward(p, @oracle.nat(1), @oracle.chain([@core.Zero])), None)
  assert_eq(
    pushforward(p, @oracle.nat(1), @oracle.chain([@core.Zero, @oracle.nat(1)])),
    None,
  )
}
