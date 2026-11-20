///|
fn matrix(
  values : Array[Array[(Int32, Int32)]],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  match
    @matrix.matrix(
      @oracle.nat(width),
      @oracle.chain(
        values.map(fn(row) {
          @oracle.chain(row.map(fn(pair) { q(pair.0, pair.1) }))
        }),
      ),
    ) {
    Some(value) => value
    None => abort("matrix")
  }
}

///|
fn tensor_value(
  value : Result[@tensor.Tensor[@exact.Rational], GeometryError],
  indices : Array[Int32],
) -> @exact.Rational {
  let tensor = match value {
    Ok(value) => value
    Err(_) => abort("tensor")
  }
  match @tensor.at(tensor, @oracle.chain(indices.map(@oracle.nat))) {
    Ok(value) => value
    Err(_) => abort("tensor coordinates")
  }
}

///|
test "shared tensor mode product raises the connection output index" {
  let p = point(
    [
      polynomial(2, [(1, [2, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [2, 0]), (-1, [0, 1])]),
    ],
    [(1, 2), (1, 3)],
  )
  let model = @infogeom.local_model(p)
  let geometry = required(curvature(p))
  let expected = @riemann.christoffel_second(
    @riemann.curvature_connection(geometry),
  )
  let actual = alpha_raised(model, q(0, 1))
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        assert_eq(
          Some(tensor_value(actual, [i, j, k])),
          @riemann.component3(
            expected,
            @oracle.nat(k),
            @oracle.nat(i),
            @oracle.nat(j),
          ),
        )
      }
    }
  }
}

///|
test "cubic tensor pullback agrees with nonlinear probability differentiation" {
  let original = point(
    [
      polynomial(2, [(1, [1, 0])]),
      polynomial(2, [(1, [0, 1])]),
      polynomial(2, [(1, [0, 0]), (-1, [1, 0]), (-1, [0, 1])]),
    ],
    [(2, 9), (1, 9)],
  )
  let transformed = point(
    [
      polynomial(2, [(1, [2, 0]), (1, [1, 1])]),
      polynomial(2, [(1, [0, 2])]),
      polynomial(2, [(1, [0, 0]), (-1, [2, 0]), (-1, [1, 1]), (-1, [0, 2])]),
    ],
    [(1, 3), (1, 3)],
  )
  let model = @infogeom.local_model(original)
  let j = matrix([[(1, 1), (1, 3)], [(0, 1), (2, 3)]], 2)
  assert_eq(
    pullback_cubic(model, j),
    cubic_tensor(@infogeom.local_model(transformed)),
  )
  assert_true(
    pullback_cubic(model, matrix([[(1, 1)]], 1))
    is Err(Tensor(ModeWidthMismatch)),
  )
  let scalar_map = matrix([[], []], 0)
  let empty = match pullback_cubic(model, scalar_map) {
    Ok(value) => value
    Err(_) => abort("zero dimension")
  }
  assert_eq(
    @tensor.shape(empty),
    @oracle.chain([@core.Zero, @core.Zero, @core.Zero]),
  )
  assert_eq(@tensor.entries(empty), @core.Nil)
}

///|
test "tensor contraction handles a zero-dimensional probability manifold" {
  let p = point([polynomial(0, [(1, [])])], [])
  assert_eq(scalar_by_contraction(required(curvature(p))), Ok(q(0, 1)))
}

///|
// Retain the materialized rank-four route as an independent finite reference.
fn scalar_outer_reference(
  value : @riemann.Curvature,
) -> Result[@exact.Rational, GeometryError] {
  let jet = @riemann.connection_jet(@riemann.curvature_connection(value))
  let d = @riemann.dimension(jet)
  fn matrix_tensor(
    rows : @riemann.Tensor2,
  ) -> Result[@tensor.Tensor[@exact.Rational], GeometryError] {
    let flat = @core.reverse(
      @core.fold_left(rows, @core.Nil, fn(reversed, row) {
        @core.reverse_onto(row, reversed)
      }),
    )
    match @tensor.from_flat(Cons(d, Cons(d, @core.Nil)), flat) {
      Ok(value) => Ok(value)
      Err(error) => Err(Tensor(error))
    }
  }
  let inverse = match
    matrix_tensor(@matrix.rows(@riemann.inverse_metric(jet))) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ricci = match matrix_tensor(@riemann.ricci(value)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let product = @tensor.product(@algebra.rationals(), inverse, ricci)
  let first = match
    @tensor.contract(@algebra.rationals(), product, Zero, Succ(Succ(Zero))) {
    Ok(value) => value
    Err(error) => return Err(Tensor(error))
  }
  match @tensor.contract(@algebra.rationals(), first, Zero, Succ(Zero)) {
    Err(error) => Err(Tensor(error))
    Ok(scalar) =>
      match @tensor.at(scalar, @core.Nil) {
        Ok(value) => Ok(value)
        Err(error) => Err(Tensor(error))
      }
  }
}

///|
test "scalar contraction agrees with the outer reference for rational metric jets" {
  let zero = matrix([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2)
  // g(x) = exp(2 phi(x)) H at x=0, grad phi=0, Hess phi=diag(1/2,1/3).
  // In dimension two, scalar = -2 trace(H^-1 Hess phi).
  for
    (h, expected) in [
      (matrix([[(3, 2), (1, 2)], [(1, 2), (3, 2)]], 2), q(-5, 4)),
      (matrix([[(1, 1), (1, 2)], [(1, 2), (-1, 1)]], 2), q(-4, 15)),
    ] {
    let second11 = @matrix.matrix(
      @oracle.nat(2),
      @core.map(@matrix.rows(h), fn(row) {
        @core.map(row, fn(x) { @exact.rational_multiply(q(2, 3), x) })
      }),
    ).unwrap()
    let jet = @riemann.metric_jet(
      h,
      @oracle.chain([zero, zero]),
      @oracle.chain([@oracle.chain([h, zero]), @oracle.chain([zero, second11])]),
    ).unwrap()
    let value = @riemann.curvature(@riemann.connection(jet))
    assert_eq(@riemann.scalar_curvature(value), expected)
    assert_eq(scalar_outer_reference(value), Ok(expected))
    assert_eq(scalar_by_contraction(value), Ok(expected))
  }
  for parameters in [[], [(1, 2)], [(1, 4), (1, 4)], [(1, 5), (1, 5), (1, 5)]] {
    let d = parameters.length()
    let variables = [
      for i in 0..<d => {
        polynomial(d, [(1, [ for j in 0..<d => if i == j { 1 } else { 0 } ])])
      }
    ]
    let rest = polynomial(
      d,
      [
        (1, Array::make(d, 0)),
        ..[
          for i in 0..<d => {
            (-1, [ for j in 0..<d => if i == j { 1 } else { 0 } ])
          }
        ],
      ],
    )
    let value = required(curvature(point([..variables, rest], parameters)))
    assert_eq(scalar_outer_reference(value), Ok(q(d * (d - 1), 4)))
    assert_eq(scalar_by_contraction(value), scalar_outer_reference(value))
  }
}
