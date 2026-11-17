///|
fn required_amari(model : @infogeom.Model) -> AmariChentsov {
  match amari_chentsov(model) {
    Ok(value) => value
    Err(_) => abort("Amari-Chentsov")
  }
}

///|
fn vec(values : Array[(Int32, Int32)]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(value) { q(value.0, value.1) }))
}

///|
test "Bernoulli Amari Chentsov contractions agree with univariate closed forms" {
  for d in 2..<=9 {
    for a in 1..<d {
      let b = d - a
      let p = point(
        [polynomial(1, [(1, [1])]), polynomial(1, [(1, [0]), (-1, [1])])],
        [(a, d)],
      )
      let model = @infogeom.local_model(p)
      let value = required_amari(model)
      let cubic = q(d * d * d * (b - a), a * a * b * b)
      let difference = q(d * (b - a), a * b)
      assert_eq(tensor_value(Ok(value.covariant()), [0, 0, 0]), cubic)
      assert_eq(tensor_value(Ok(value.difference()), [0, 0, 0]), difference)
      assert_eq(value.norm_squared(), q((b - a) * (b - a), a * b))
      assert_eq(value.trace(), vec([(d * (b - a), a * b)]))
      assert_eq(
        value.evaluate(vec([(2, 1)]), vec([(-3, 1)]), vec([(4, 1)])),
        Ok(@exact.rational_multiply(q(-24, 1), cubic)),
      )
      assert_eq(
        value.product(vec([(2, 1)]), vec([(-3, 1)])),
        Ok(
          @core.Cons(@exact.rational_multiply(q(-6, 1), difference), @core.Nil),
        ),
      )
      assert_eq(value.metric(), @infogeom.fisher(model))
      assert_eq(@infogeom.amari_chentsov(model), @infogeom.cubic(model))
      assert_eq(amari_chentsov_tensor(model), cubic_tensor(model))
    }
  }
}

///|
test "Amari Chentsov tensor is the difference of the dual alpha connections" {
  let p = point(
    [
      polynomial(2, [(1, [2, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [2, 0]), (-1, [0, 1])]),
    ],
    [(1, 2), (1, 3)],
  )
  let model = @infogeom.local_model(p)
  let value = required_amari(model)
  let zero = alpha_raised(model, q(0, 1))
  for alpha in [q(-1, 1), q(0, 1), q(1, 1), q(2, 3)] {
    let actual = alpha_raised(model, alpha)
    for i in 0..<2 {
      for j in 0..<2 {
        for k in 0..<2 {
          let expected = @exact.rational_subtract(
            tensor_value(zero, [i, j, k]),
            @exact.rational_multiply(
              @exact.rational_half(alpha),
              tensor_value(Ok(value.difference()), [i, j, k]),
            ),
          )
          assert_eq(tensor_value(actual, [i, j, k]), expected)
        }
      }
    }
  }
  let lower_plus = @infogeom.alpha_lower(model, q(1, 1)).unwrap()
  let lower_minus = @infogeom.alpha_lower(model, q(-1, 1)).unwrap()
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        let at = fn(slices) {
          matrix_entry(
            @core.nth(slices, @oracle.nat(i)).unwrap(),
            @oracle.nat(j),
            @oracle.nat(k),
          )
        }
        assert_eq(
          @exact.rational_subtract(at(lower_minus), at(lower_plus)),
          tensor_value(Ok(value.covariant()), [i, j, k]),
        )
      }
    }
  }
}

///|
test "norm is invariant and trace transforms covariantly in a nonlinear chart" {
  let original = point(
    [
      polynomial(2, [(1, [1, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
    ],
    [(2, 9), (1, 9)],
  )
  let changed = point(
    [
      polynomial(2, [(1, [2, 0]), (1, [1, 1])]),
      polynomial(2, [(1, [0, 2])]),
      polynomial(2, [(1, [0, 0]), (-1, [2, 0]), (-1, [1, 1]), (-1, [0, 2])]),
    ],
    [(1, 3), (1, 3)],
  )
  let old = required_amari(@infogeom.local_model(original))
  let new = required_amari(@infogeom.local_model(changed))
  let j = matrix([[(1, 1), (1, 3)], [(0, 1), (2, 3)]], 2)
  assert_eq(old.norm_squared(), new.norm_squared())
  assert_eq(
    pullback_amari_chentsov(@infogeom.local_model(original), j),
    Ok(new.covariant()),
  )
  assert_eq(
    pullback_amari_chentsov(@infogeom.local_model(original), j),
    pullback_cubic(@infogeom.local_model(original), j),
  )
  let old_trace = @oracle.array(old.trace())
  let expected = @oracle.chain([
    old_trace[0],
    @exact.rational_add(
      @exact.rational_multiply(q(1, 3), old_trace[0]),
      @exact.rational_multiply(q(2, 3), old_trace[1]),
    ),
  ])
  assert_eq(new.trace(), expected)
  let u = vec([(1, 1), (2, 1)])
  let v = vec([(-1, 1), (1, 1)])
  let w = vec([(2, 1), (-1, 1)])
  let transform = fn(vector) {
    let a = @oracle.array(vector)
    @core.Cons(
      @exact.rational_add(a[0], @exact.rational_multiply(q(1, 3), a[1])),
      @core.Cons(@exact.rational_multiply(q(2, 3), a[1]), @core.Nil),
    )
  }
  assert_eq(
    new.evaluate(u, v, w),
    old.evaluate(transform(u), transform(v), transform(w)),
  )
  assert_eq(new.evaluate(u, v, w), new.evaluate(w, u, v))
}

///|
test "Gaussian natural Amari Chentsov norm is fourteen across location and scale" {
  for mean in [q(0, 1), q(1, 2), q(-2, 1)] {
    for variance in [q(1, 1), q(3, 2)] {
      let covariance = @matrix.matrix(
        @core.Succ(@core.Zero),
        @core.Cons(@core.Cons(variance, @core.Nil), @core.Nil),
      ).unwrap()
      let source = @gaussian.gaussian(@core.Cons(mean, @core.Nil), covariance).unwrap()
      let value = gaussian_amari_chentsov(source).unwrap()
      assert_eq(value.norm_squared(), q(14, 1))
      let info = @gaussian.information(source).unwrap()
      assert_eq(value.covariant(), info.amari_chentsov())
      assert_eq(value.metric(), info.fisher())
      assert_eq(info.parent(), source)
    }
  }
  let source = @gaussian.gaussian(vec([(0, 1)]), matrix([[(1, 1)]], 1)).unwrap()
  assert_eq(
    gaussian_amari_chentsov(source).unwrap().trace(),
    vec([(0, 1), (6, 1)]),
  )
}

///|
test "singular models and tangent dimensions are explicit and zero dimension is total" {
  let singular = point(
    [
      polynomial(2, [(1, [1, 0]), (1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
    ],
    [(1, 4), (1, 4)],
  )
  assert_true(
    amari_chentsov(@infogeom.local_model(singular))
    is Err(Metric(SingularMetric)),
  )
  assert_true(amari_chentsov_tensor(@infogeom.local_model(singular)) is Ok(_))
  let zero = required_amari(
    @infogeom.local_model(point([polynomial(0, [(1, [])])], [])),
  )
  assert_eq(zero.norm_squared(), q(0, 1))
  assert_eq(zero.trace(), @core.Nil)
  assert_eq(zero.evaluate(@core.Nil, @core.Nil, @core.Nil), Ok(q(0, 1)))
  assert_eq(zero.product(@core.Nil, @core.Nil), Ok(@core.Nil))
  assert_true(
    zero.evaluate(@core.Nil, @core.Nil, vec([(0, 1)]))
    is Err(Tensor(ModeWidthMismatch)),
  )
  assert_true(
    zero.product(vec([(0, 1)]), @core.Nil) is Err(Tensor(ModeWidthMismatch)),
  )
}

///|
test "covariant tensor agrees with direct weighted score moments" {
  let base = @probability.distribution(vec([(1, 6), (1, 3), (1, 2)])).unwrap()
  let statistics = matrix(
    [[(2, 1), (1, 1)], [(-1, 1), (3, 1)], [(1, 1), (-2, 1)]],
    2,
  )
  let point = @infogeom.exponential_point(base, statistics).unwrap()
  let model = @infogeom.local_model(point)
  let value = required_amari(model)
  let scores = @oracle.array(@matrix.rows(@infogeom.scores(model).unwrap())).map(
    @oracle.array,
  )
  let masses = @oracle.array(@probability.masses(base))
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        let mut expected = q(0, 1)
        for x in 0..<3 {
          expected = @exact.rational_add(
            expected,
            @exact.rational_multiply(
              @exact.rational_multiply(masses[x], scores[x][i]),
              @exact.rational_multiply(scores[x][j], scores[x][k]),
            ),
          )
        }
        assert_eq(tensor_value(Ok(value.covariant()), [i, j, k]), expected)
      }
    }
  }
}

///|
test "sufficient Markov splitting preserves the metric and Amari Chentsov data" {
  let point = point(
    [polynomial(1, [(1, [1])]), polynomial(1, [(1, [0]), (-1, [1])])],
    [(1, 3)],
  )
  let source = @infogeom.local_model(point)
  let split = @probability.channel(
    @oracle.chain([
      @probability.distribution(vec([(1, 3), (2, 3), (0, 1)])).unwrap(),
      @probability.distribution(vec([(0, 1), (0, 1), (1, 1)])).unwrap(),
    ]),
  ).unwrap()
  let refined = @infogeom.through(source, split).unwrap()
  let reverse = @probability.bayesian_inverse(
    split,
    @infogeom.distribution(source),
  ).unwrap()
  assert_eq(@infogeom.through(refined, reverse), Ok(source))
  assert_eq(amari_chentsov(refined), amari_chentsov(source))
}
