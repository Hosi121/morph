///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn vector(values : Array[(Int32, Int32)]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(pair) { q(pair.0, pair.1) }))
}

///|
fn mat(
  values : Array[Array[(Int32, Int32)]],
  width : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  match @matrix.matrix(@oracle.nat(width), @oracle.chain(values.map(vector))) {
    Some(value) => value
    None => abort("invalid test matrix")
  }
}

///|
fn required(result : Result[Model, ModelError]) -> Model {
  match result {
    Ok(value) => value
    Err(_) => abort("expected model")
  }
}

///|
fn tensor_value(
  value : Tensor?,
  i : Int32,
  j : Int32,
  k : Int32,
) -> @exact.Rational {
  match value {
    None => abort("expected tensor")
    Some(slices) =>
      match @core.nth(slices, @oracle.nat(i)) {
        None => abort("missing tensor slice")
        Some(slice) => entry(slice, @oracle.nat(j), @oracle.nat(k))
      }
  }
}

///|
fn categorical(a : Int32, b : Int32, denominator : Int32) -> Model {
  let zero = mat([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2)
  required(
    model(
      @oracle.nat(2),
      @oracle.chain([
        {
          probability: q(a, denominator),
          gradient: vector([(1, 1), (0, 1)]),
          hessian: zero,
        },
        {
          probability: q(b, denominator),
          gradient: vector([(0, 1), (1, 1)]),
          hessian: zero,
        },
        {
          probability: q(denominator - a - b, denominator),
          gradient: vector([(-1, 1), (-1, 1)]),
          hessian: zero,
        },
      ]),
    ),
  )
}

///|
test "categorical Fisher and inverse agree with closed forms at every small rational point" {
  for denominator in 3..<=9 {
    for a in 1..<(denominator - 1) {
      for b in 1..<(denominator - a) {
        let c = denominator - a - b
        let m = categorical(a, b, denominator)
        let expected = mat(
          [
            [(denominator * (a + c), a * c), (denominator, c)],
            [(denominator, c), (denominator * (b + c), b * c)],
          ],
          2,
        )
        assert_eq(fisher(m), expected)
        let inverse = mat(
          [
            [
              (a * (denominator - a), denominator * denominator),
              (-a * b, denominator * denominator),
            ],
            [
              (-a * b, denominator * denominator),
              (b * (denominator - b), denominator * denominator),
            ],
          ],
          2,
        )
        assert_eq(@linear.inverse(fisher(m)), Some(inverse))
        assert_eq(
          natural_gradient(m, vector([(1, 1), (0, 1)])),
          Ok(
            vector([
              (a * (denominator - a), denominator * denominator),
              (-a * b, denominator * denominator),
            ]),
          ),
        )
        let score = match scores(m) {
          Some(value) => value
          None => abort("scores")
        }
        for i in 0..<2 {
          let column = match @matrix.column(score, @oracle.nat(i)) {
            Some(value) => value
            None => abort("column")
          }
          assert_eq(
            @probability.expectation(distribution(m), column),
            Some(q(0, 1)),
          )
        }
      }
    }
  }
}

///|
test "cubic tensor and dual connections satisfy normalization, symmetry and duality" {
  let m = categorical(1, 2, 6)
  let t = cubic(m)
  let dg = metric_first(m)
  for i in 0..<2 {
    for j in 0..<2 {
      for k in 0..<2 {
        let expected = if i == 0 && j == 0 && k == 0 {
          q(32, 1)
        } else if i == 1 && j == 1 && k == 1 {
          q(5, 1)
        } else {
          q(-4, 1)
        }
        assert_eq(tensor_value(t, i, j, k), expected)
        assert_eq(tensor_value(t, i, j, k), tensor_value(t, k, i, j))
        assert_eq(tensor_value(dg, k, i, j), @exact.rational_negate(expected))
        assert_eq(tensor_value(alpha_lower(m, q(-1, 1)), i, j, k), q(0, 1))
        for alpha in -2..<=2 {
          let left = tensor_value(alpha_lower(m, q(alpha, 1)), i, j, k)
          let right = tensor_value(alpha_lower(m, q(-alpha, 1)), i, k, j)
          assert_eq(@exact.rational_add(left, right), tensor_value(dg, i, j, k))
        }
      }
    }
  }
}

///|
test "nonlinear Bernoulli chart uses probability Hessians in the connection" {
  // theta=t^2 at t=1/2: p=(3/4,1/4), dp=(-1,1), ddp=(-2,2).
  let m = required(
    model(
      @oracle.nat(1),
      @oracle.chain([
        {
          probability: q(3, 4),
          gradient: vector([(-1, 1)]),
          hessian: mat([[(-2, 1)]], 1),
        },
        {
          probability: q(1, 4),
          gradient: vector([(1, 1)]),
          hessian: mat([[(2, 1)]], 1),
        },
      ]),
    ),
  )
  assert_eq(fisher(m), mat([[(16, 3)]], 1))
  assert_eq(tensor_value(cubic(m), 0, 0, 0), q(128, 9))
  assert_eq(tensor_value(metric_first(m), 0, 0, 0), q(64, 9))
  assert_eq(tensor_value(alpha_lower(m, q(0, 1)), 0, 0, 0), q(32, 9))
  assert_eq(tensor_value(alpha_lower(m, q(1, 1)), 0, 0, 0), q(-32, 9))
  assert_eq(tensor_value(alpha_lower(m, q(-1, 1)), 0, 0, 0), q(32, 3))
  assert_eq(natural_gradient(m, vector([(1, 1)])), Ok(vector([(3, 16)])))
}

///|
test "redundant coordinates retain a singular Fisher form and reject natural gradient inversion" {
  let zero = mat([[(0, 1), (0, 1)], [(0, 1), (0, 1)]], 2)
  let m = required(
    model(
      @oracle.nat(2),
      @oracle.chain([
        {
          probability: q(1, 2),
          gradient: vector([(1, 1), (1, 1)]),
          hessian: zero,
        },
        {
          probability: q(1, 2),
          gradient: vector([(-1, 1), (-1, 1)]),
          hessian: zero,
        },
      ]),
    ),
  )
  assert_eq(fisher(m), mat([[(4, 1), (4, 1)], [(4, 1), (4, 1)]], 2))
  assert_eq(
    natural_gradient(m, vector([(1, 1), (1, 1)])),
    Err(SingularInformation),
  )
  assert_eq(
    natural_gradient(m, vector([(1, 1), (0, 1)])),
    Err(SingularInformation),
  )
  assert_eq(natural_gradient(m, vector([(1, 1)])), Err(DimensionMismatch))
}

///|
test "malformed jets fail before computations and zero-dimensional points are valid" {
  let one = @oracle.nat(1)
  let jet = SampleJet::{
    probability: q(1, 1),
    gradient: vector([(0, 1)]),
    hessian: mat([[(0, 1)]], 1),
  }
  assert_eq(model(one, @core.Nil), Err(EmptySampleSpace))
  assert_eq(
    model(one, @oracle.chain([{ ..jet, probability: q(0, 1), }])),
    Err(NotInterior),
  )
  assert_eq(
    model(one, @oracle.chain([{ ..jet, probability: q(-1, 1), }])),
    Err(NotInterior),
  )
  assert_eq(
    model(one, @oracle.chain([{ ..jet, probability: q(1, 2), }])),
    Err(NotNormalized),
  )
  assert_eq(
    model(one, @oracle.chain([{ ..jet, gradient: vector([(1, 1)]), }])),
    Err(DerivativeNotNormalized),
  )
  assert_eq(
    model(one, @oracle.chain([{ ..jet, hessian: mat([[(1, 1)]], 1), }])),
    Err(DerivativeNotNormalized),
  )
  assert_eq(
    model(one, @oracle.chain([{ ..jet, gradient: @core.Nil, }])),
    Err(DimensionMismatch),
  )
  assert_eq(
    model(
      @oracle.nat(2),
      @oracle.chain([
        {
          ..jet,
          gradient: vector([(0, 1), (0, 1)]),
          hessian: mat([[(0, 1), (1, 1)], [(0, 1), (0, 1)]], 2),
        },
      ]),
    ),
    Err(HessianNotSymmetric),
  )
  let point = required(
    model(
      @core.Zero,
      @oracle.chain([
        { probability: q(1, 1), gradient: @core.Nil, hessian: mat([], 0), },
      ]),
    ),
  )
  assert_eq(natural_gradient(point, @core.Nil), Ok(@core.Nil))
  assert_eq(cubic(point), Some(@core.Nil))
}
