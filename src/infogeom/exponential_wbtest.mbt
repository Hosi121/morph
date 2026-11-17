///|
fn exp_point(
  base : Array[(Int32, Int32)],
  statistics : Array[Array[(Int32, Int32)]],
  dimension : Int32,
) -> ModelPoint {
  let distribution = match @probability.distribution(vector(base)) {
    Some(value) => value
    None => abort("base")
  }
  match exponential_point(distribution, mat(statistics, dimension)) {
    Ok(value) => value
    Err(_) => abort("exponential jet")
  }
}

///|
test "Bernoulli natural-coordinate jets equal exact cumulant derivatives" {
  for denominator in 2..<=8 {
    for a in 1..<denominator {
      let point = exp_point(
        [(denominator - a, denominator), (a, denominator)],
        [[(0, 1)], [(1, 1)]],
        1,
      )
      let m = local_model(point)
      let variance = q(a * (denominator - a), denominator * denominator)
      let third = q(
        a * (denominator - a) * (denominator - 2 * a),
        denominator * denominator * denominator,
      )
      let fourth = q(
        a *
        (denominator - a) *
        (denominator * denominator - 6 * a * (denominator - a)),
        denominator * denominator * denominator * denominator,
      )
      assert_eq(
        fisher(m),
        mat([[(a * (denominator - a), denominator * denominator)]], 1),
      )
      assert_eq(tensor_value(cubic(m), 0, 0, 0), third)
      assert_eq(tensor_value(metric_first(m), 0, 0, 0), third)
      assert_eq(second_value(point, 0, 0, 0, 0), fourth)
      assert_eq(tensor_value(alpha_lower(m, q(1, 1)), 0, 0, 0), q(0, 1))
      assert_eq(tensor_value(alpha_lower(m, q(-1, 1)), 0, 0, 0), third)
      assert_eq(
        natural_gradient(m, vector([(1, 1)])),
        Ok(
          @core.Cons(
            match @exact.rational_divide(q(1, 1), variance) {
              Some(value) => value
              None => abort("variance")
            },
            @core.Nil,
          ),
        ),
      )
    }
  }
}

///|
test "exponential Fisher matrix is covariance and constant statistics expose redundancy" {
  let p = exp_point(
    [(1, 6), (1, 3), (1, 2)],
    [[(1, 1), (0, 1)], [(0, 1), (1, 1)], [(0, 1), (0, 1)]],
    2,
  )
  assert_eq(
    fisher(local_model(p)),
    mat([[(5, 36), (-1, 18)], [(-1, 18), (2, 9)]], 2),
  )
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        assert_eq(
          tensor_value(alpha_lower(local_model(p), q(1, 1)), i, j, k),
          q(0, 1),
        )
        assert_eq(
          tensor_value(metric_first(local_model(p)), i, j, k),
          tensor_value(cubic(local_model(p)), i, j, k),
        )
      }
    }
  }
  let redundant = exp_point([(1, 2), (1, 2)], [[(1, 1)], [(1, 1)]], 1)
  assert_eq(fisher(local_model(redundant)), mat([[(0, 1)]], 1))
  assert_eq(
    natural_gradient(local_model(redundant), vector([(0, 1)])),
    Err(SingularInformation),
  )
  let boundary = match @probability.distribution(vector([(1, 1), (0, 1)])) {
    Some(value) => value
    None => abort("boundary")
  }
  assert_true(
    exponential_point(boundary, mat([[(0, 1)], [(1, 1)]], 1))
    is Err(NotInterior),
  )
  assert_true(
    exponential_point(boundary, mat([[(0, 1)]], 1)) is Err(DimensionMismatch),
  )
}

///|
test "third jet constructor checks every shape, permutation symmetry and normalization" {
  let p = exp_point([(1, 2), (1, 2)], [[(0, 1)], [(1, 1)]], 1)
  let m = local_model(p)
  assert_true(model_point(m, @core.Nil) is Err(ThirdDerivativeShape))
  assert_true(
    model_point(m, @oracle.chain([@core.Nil, @core.Nil]))
    is Err(ThirdDerivativeShape),
  )
  let bad = @oracle.chain([
    @oracle.chain([mat([[(1, 1)]], 1)]),
    @oracle.chain([mat([[(0, 1)]], 1)]),
  ])
  assert_true(model_point(m, bad) is Err(ThirdDerivativeNotNormalized))
  let symmetric = third_derivatives(p)
  assert_true(model_point(m, symmetric) is Ok(_))
  let m = categorical(1, 2, 6)
  let a = @oracle.chain([
    mat([[(0, 1), (1, 1)], [(0, 1), (0, 1)]], 2),
    mat([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2),
  ])
  let b = @core.map(a, fn(matrix) {
    mat(
      @oracle.array(@matrix.rows(matrix)).map(fn(row) {
        @oracle.array(row).map(fn(x) {
          (-@oracle.int_of_integer(@exact.numerator(x)), 1)
        })
      }),
      2,
    )
  })
  let zero = @oracle.chain([
    mat([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2),
    mat([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2),
  ])
  assert_true(
    model_point(m, @oracle.chain([a, b, zero])) is Err(ThirdDerivativeSymmetry),
  )
}
