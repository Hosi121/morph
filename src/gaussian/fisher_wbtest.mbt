///|
fn required_jet(source : Gaussian) -> @riemann.MetricJet {
  match fisher_jet(source) {
    Ok(value) => value
    Err(_) => abort("Fisher jet")
  }
}

///|
test "univariate Gaussian natural metric derivatives equal known cumulants" {
  let source = checked_gaussian(
    @oracle.chain([q(0, 1)]),
    matrix(@oracle.chain([@oracle.chain([q(1, 1)])]), 1),
  )
  let jet = required_jet(source)
  assert_eq(
    @riemann.metric(jet),
    matrix(
      @oracle.chain([
        @oracle.chain([q(1, 1), q(0, 1)]),
        @oracle.chain([q(0, 1), q(2, 1)]),
      ]),
      2,
    ),
  )
  let first = @riemann.first_derivatives(jet)
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        let count = i + j + k
        let expected = if count == 1 {
          q(2, 1)
        } else if count == 3 {
          q(8, 1)
        } else {
          q(0, 1)
        }
        let slice = match @core.nth(first, @oracle.nat(k)) {
          Some(value) => value
          None => abort("first")
        }
        assert_eq(entry(slice, @oracle.nat(i), @oracle.nat(j)), expected)
      }
    }
  }
  let second = @riemann.second_derivatives(jet)
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        for l in 0..<2 {
          let count = i + j + k + l
          let expected = if count == 2 {
            q(8, 1)
          } else if count == 4 {
            q(48, 1)
          } else {
            q(0, 1)
          }
          let row = match @core.nth(second, @oracle.nat(k)) {
            Some(value) => value
            None => abort("second")
          }
          let slice = match @core.nth(row, @oracle.nat(l)) {
            Some(value) => value
            None => abort("second")
          }
          assert_eq(entry(slice, @oracle.nat(i), @oracle.nat(j)), expected)
        }
      }
    }
  }
}

///|
test "Gaussian mean and variance family has constant sectional curvature minus one half" {
  for mean in [q(0, 1), q(1, 2), q(-2, 1)] {
    for variance in [q(1, 1), q(3, 2)] {
      let source = checked_gaussian(
        @oracle.chain([mean]),
        matrix(@oracle.chain([@oracle.chain([variance])]), 1),
      )
      let jet = required_jet(source)
      let geometry = @riemann.curvature(@riemann.connection(jet))
      assert_eq(@riemann.scalar_curvature(geometry), q(-1, 1))
      assert_eq(
        @riemann.sectional_curvature(
          geometry,
          @oracle.chain([q(1, 1), q(0, 1)]),
          @oracle.chain([q(0, 1), q(1, 1)]),
        ),
        Some(q(-1, 2)),
      )
      assert_true(@riemann.is_positive_definite(jet))
    }
  }
}

///|
test "bivariate Gaussian Fisher matrix agrees with direct covariance identities" {
  let mu = [q(1, 1), q(-1, 2)]
  let sigma = [[q(2, 1), q(1, 2)], [q(1, 2), q(1, 1)]]
  let source = checked_gaussian(
    @oracle.chain(mu),
    matrix(@oracle.chain(sigma.map(@oracle.chain)), 2),
  )
  let jet = required_jet(source)
  let metric = @riemann.metric(jet)
  assert_eq(@matrix.width(metric), @oracle.nat(5))
  let stats = [(0, -1), (1, -1), (0, 0), (0, 1), (1, 1)]
  for a in 0..<5 {
    for b in 0..<5 {
      let (i, j) = stats[a]
      let (k, l) = stats[b]
      let expected = if j < 0 && l < 0 {
        sigma[i][k]
      } else if j < 0 {
        @exact.rational_add(
          @exact.rational_multiply(mu[k], sigma[i][l]),
          @exact.rational_multiply(mu[l], sigma[i][k]),
        )
      } else if l < 0 {
        @exact.rational_add(
          @exact.rational_multiply(mu[i], sigma[k][j]),
          @exact.rational_multiply(mu[j], sigma[k][i]),
        )
      } else {
        let terms = [
          @exact.rational_multiply(sigma[i][k], sigma[j][l]),
          @exact.rational_multiply(sigma[i][l], sigma[j][k]),
          @exact.rational_multiply(
            @exact.rational_multiply(mu[i], mu[k]),
            sigma[j][l],
          ),
          @exact.rational_multiply(
            @exact.rational_multiply(mu[i], mu[l]),
            sigma[j][k],
          ),
          @exact.rational_multiply(
            @exact.rational_multiply(mu[j], mu[k]),
            sigma[i][l],
          ),
          @exact.rational_multiply(
            @exact.rational_multiply(mu[j], mu[l]),
            sigma[i][k],
          ),
        ]
        terms.fold(init=q(0, 1), @exact.rational_add)
      }
      assert_eq(entry(metric, @oracle.nat(a), @oracle.nat(b)), expected)
    }
  }
  assert_true(@riemann.is_positive_definite(jet))
  assert_eq(
    @core.length(
      match sufficient_statistics(source) {
        Some(value) => value
        None => abort("statistics")
      },
    ),
    @oracle.nat(5),
  )
}
