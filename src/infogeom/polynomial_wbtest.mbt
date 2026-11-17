///|
fn polynomial(
  variables : Int32,
  terms : Array[(Int32, Int32, Array[Int32])],
) -> @polynomial.Polynomial {
  match
    @polynomial.polynomial(
      @oracle.nat(variables),
      @oracle.chain(
        terms.map(fn(term) {
          {
            coefficient: q(term.0, term.1),
            exponents: @oracle.chain(term.2.map(@oracle.nat)),
          }
        }),
      ),
    ) {
    Ok(value) => value
    Err(_) => abort("invalid test polynomial")
  }
}

///|
fn checked_family(
  dimension : Int32,
  outcomes : Array[@polynomial.Polynomial],
) -> Family {
  match family(@oracle.nat(dimension), @oracle.chain(outcomes)) {
    Ok(value) => value
    Err(_) => abort("expected family")
  }
}

///|
fn checked_point(
  family : Family,
  parameters : Array[(Int32, Int32)],
) -> PolynomialPoint {
  match at(family, vector(parameters)) {
    Ok(value) => value
    Err(_) => abort("expected polynomial point")
  }
}

///|
fn second_value(
  point : PolynomialPoint,
  k : Int32,
  l : Int32,
  i : Int32,
  j : Int32,
) -> @exact.Rational {
  match metric_second(point) {
    None => abort("second metric derivative")
    Some(rows) =>
      match @core.nth(rows, @oracle.nat(k)) {
        None => abort("metric slice")
        Some(tensor) => tensor_value(Some(tensor), l, i, j)
      }
  }
}

///|
test "polynomial model produces categorical jets and all second metric derivatives" {
  let family = checked_family(2, [
    polynomial(2, [(1, 1, [1, 0])]),
    polynomial(2, [(1, 1, [0, 1])]),
    polynomial(2, [(1, 1, [0, 0]), (-1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  assert_eq(family_dimension(family), @oracle.nat(2))
  for a in 1..<4 {
    for b in 1..<(6 - a) {
      let point = checked_point(family, [(a, 6), (b, 6)])
      assert_eq(local_model(point), categorical(a, b, 6))
      // On the affine simplex p=(x,y,1-x-y), g_ij = delta_ij/p_i + 1/p_last.
      let c = 6 - a - b
      for k in 0..<2 {
        for l in 0..<2 {
          for i in 0..<2 {
            for j in 0..<2 {
              let common = q(432, c * c * c)
              let extra = if k == l && l == i && i == j {
                let d = if i == 0 { a } else { b }
                q(432, d * d * d)
              } else {
                q(0, 1)
              }
              assert_eq(
                second_value(point, k, l, i, j),
                @exact.rational_add(common, extra),
              )
            }
          }
        }
      }
    }
  }
}

///|
test "third probability derivatives contribute to nonlinear Fisher curvature jets" {
  let square = checked_family(1, [
    polynomial(1, [(1, 1, [2])]),
    polynomial(1, [(1, 1, [0]), (-1, 1, [2])]),
  ])
  let point = checked_point(square, [(1, 2)])
  assert_eq(fisher(local_model(point)), mat([[(16, 3)]], 1))
  assert_eq(tensor_value(metric_first(local_model(point)), 0, 0, 0), q(64, 9))
  assert_eq(second_value(point, 0, 0, 0, 0), q(896, 27))
  let cube = checked_family(1, [
    polynomial(1, [(1, 1, [3])]),
    polynomial(1, [(1, 1, [0]), (-1, 1, [3])]),
  ])
  let point = checked_point(cube, [(1, 2)])
  // Closed form: for p=t^3, g(t)=9t/(1-t^3), differentiated as a univariate quotient.
  assert_eq(fisher(local_model(point)), mat([[(36, 7)]], 1))
  assert_eq(tensor_value(metric_first(local_model(point)), 0, 0, 0), q(720, 49))
  assert_eq(second_value(point, 0, 0, 0, 0), q(14688, 343))
}

///|
test "family normalization is an identity and positivity is local to each point" {
  assert_true(family(@oracle.nat(1), @core.Nil) is Err(EmptyFamily))
  assert_true(
    family(@oracle.nat(1), @oracle.chain([polynomial(2, [(1, 1, [0, 0])])]))
    is Err(PolynomialDimension),
  )
  // These sum to one only at t=1/2; a pointwise check would incorrectly accept the family.
  assert_true(
    family(
      @oracle.nat(1),
      @oracle.chain([polynomial(1, [(1, 1, [1])]), polynomial(1, [(1, 1, [1])])]),
    )
    is Err(NotNormalizedPolynomial),
  )
  let f = checked_family(1, [
    polynomial(1, [(1, 1, [1])]),
    polynomial(1, [(1, 1, [0]), (-1, 1, [1])]),
  ])
  assert_true(at(f, vector([])) is Err(PointDimension))
  assert_true(at(f, vector([(0, 1)])) is Err(InvalidJet(NotInterior)))
  assert_true(at(f, vector([(2, 1)])) is Err(InvalidJet(NotInterior)))
  assert_eq(
    outcome_polynomials(f),
    @oracle.chain([
      polynomial(1, [(1, 1, [1])]),
      polynomial(1, [(1, 1, [0]), (-1, 1, [1])]),
    ]),
  )
}
