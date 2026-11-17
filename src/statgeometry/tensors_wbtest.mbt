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
