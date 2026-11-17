///|
priv struct Cumulants {
  moments : Moments
  centered : @core.Chain[@polynomial.Polynomial]
  products : Cache
}

///|
fn variable(n : @core.Nat, i : @core.Nat) -> @polynomial.Polynomial? {
  match
    @polynomial.polynomial(
      n,
      Cons(
        {
          coefficient: @exact.rational_one(),
          exponents: @core.map(@core.indices(n), fn(j) {
            if i.equal(j) {
              Succ(Zero)
            } else {
              Zero
            }
          }),
        },
        Nil,
      ),
    ) {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
/// Statistic order: all X_i, then X_i X_j with i<=j in row-major order.
/// These are natural coordinates of the full nondegenerate Gaussian family.
pub fn sufficient_statistics(
  source : Gaussian,
) -> @core.Chain[@polynomial.Polynomial]? {
  let n = dimension(source)
  let indices = @core.indices(n)
  fn variables(
    indices : @core.Chain[@core.Nat],
  ) -> @core.Chain[@polynomial.Polynomial]? {
    match indices {
      Nil => Some(Nil)
      Cons(i, rest) =>
        match (variable(n, i), variables(rest)) {
          (Some(value), Some(rest)) => Some(Cons(value, rest))
          _ => None
        }
    }
  }
  let linear = match variables(indices) {
    Some(value) => value
    None => return None
  }
  fn products(
    values : @core.Chain[@polynomial.Polynomial],
  ) -> @core.Chain[@polynomial.Polynomial]? {
    match values {
      Nil => Some(Nil)
      Cons(value, rest) => {
        fn row(
          values : @core.Chain[@polynomial.Polynomial],
        ) -> @core.Chain[@polynomial.Polynomial]? {
          match values {
            Nil => Some(Nil)
            Cons(other, tail) =>
              match (@polynomial.multiply(value, other), row(tail)) {
                (Ok(value), Some(rest)) => Some(Cons(value, rest))
                _ => None
              }
          }
        }
        match (row(values), products(rest)) {
          (Some(row), Some(rest)) => Some(@core.append(row, rest))
          _ => None
        }
      }
    }
  }
  match products(linear) {
    None => None
    Some(quadratic) => Some(@core.append(linear, quadratic))
  }
}

///|
fn center_statistics(
  plan : Moments,
  values : @core.Chain[@polynomial.Polynomial],
) -> Result[(@core.Chain[@polynomial.Polynomial], Moments), GaussianError] {
  match values {
    Nil => Ok((Nil, plan))
    Cons(value, rest) =>
      match expectation_with(plan, value) {
        Err(error) => Err(error)
        Ok((mean, plan)) =>
          match
            @polynomial.subtract(
              value,
              @polynomial.constant(dimension(plan.source), mean),
            ) {
            Err(_) => Err(InternalShape)
            Ok(centered) =>
              match center_statistics(plan, rest) {
                Err(error) => Err(error)
                Ok((rest, plan)) => Ok((Cons(centered, rest), plan))
              }
          }
      }
  }
}

///|
fn insert_index(
  values : @core.Chain[@core.Nat],
  i : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match values {
    Nil => Cons(i, Nil)
    Cons(j, rest) =>
      match @core.compare(i, j) {
        Greater => Cons(j, insert_index(rest, i))
        _ => Cons(i, values)
      }
  }
}

///|
fn joint(
  state : Cumulants,
  indices : @core.Chain[@core.Nat],
) -> Result[(@exact.Rational, Cumulants), GaussianError] {
  let key = @core.fold_left(indices, @core.Nil, insert_index)
  match @avl.lookup(state.products, key, compare_exponents) {
    Some(value) => Ok((value, state))
    None => {
      let product = @core.fold_left(
        key,
        Ok(
          @polynomial.constant(
            dimension(state.moments.source),
            @exact.rational_one(),
          ),
        ),
        fn(accumulated, i) {
          match accumulated {
            Err(error) => Err(error)
            Ok(accumulated) =>
              match @core.nth(state.centered, i) {
                None => Err(InternalShape)
                Some(p) =>
                  match @polynomial.multiply(accumulated, p) {
                    Ok(value) => Ok(value)
                    Err(_) => Err(InternalShape)
                  }
              }
          }
        },
      )
      match product {
        Err(error) => Err(error)
        Ok(product) =>
          match expectation_with(state.moments, product) {
            Err(error) => Err(error)
            Ok((value, plan)) =>
              Ok(
                (
                  value,
                  {
                    moments: plan,
                    centered: state.centered,
                    products: @avl.put(
                      state.products,
                      key,
                      value,
                      compare_exponents,
                    ),
                  },
                ),
              )
          }
      }
    }
  }
}

///|
fn build_tensor(
  shape : @core.Chain[@core.Nat],
  state : Cumulants,
  entry : (Cumulants, @core.Chain[@core.Nat]) -> Result[
    (@exact.Rational, Cumulants),
    GaussianError,
  ],
) -> Result[(@tensor.Tensor[@exact.Rational], Cumulants), GaussianError] {
  let coordinates = @tensor.entries(
    @tensor.tabulate(shape, fn(indices) { indices }),
  )
  let result = @core.fold_left(coordinates, Ok((@core.Nil, state)), fn(
    accumulated,
    indices,
  ) {
    match accumulated {
      Err(error) => Err(error)
      Ok((reversed, state)) =>
        match entry(state, indices) {
          Err(error) => Err(error)
          Ok((value, state)) => Ok((Cons(value, reversed), state))
        }
    }
  })
  match result {
    Err(error) => Err(error)
    Ok((reversed, state)) =>
      match @tensor.from_flat(shape, @core.reverse(reversed)) {
        Err(_) => Err(InternalShape)
        Ok(value) => Ok((value, state))
      }
  }
}

///|
fn tensor_value(
  value : @tensor.Tensor[@exact.Rational],
  indices : @core.Chain[@core.Nat],
) -> @exact.Rational {
  match @tensor.at(value, indices) {
    Ok(value) => value
    Err(_) => @exact.rational_zero()
  }
}

///|
fn prepare_information(
  source : Gaussian,
) -> Result[
  (@tensor.Tensor[@exact.Rational], @tensor.Tensor[@exact.Rational], Cumulants),
  GaussianError,
] {
  let statistics = match sufficient_statistics(source) {
    Some(value) => value
    None => return Err(InternalShape)
  }
  let (centered, plan) = match center_statistics(moments(source), statistics) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let state = Cumulants::{ moments: plan, centered, products: @avl.empty(), }
  let d = @core.length(centered)
  let (metric, state) = match
    build_tensor(Cons(d, Cons(d, Nil)), state, joint) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (first_tensor, state) = match
    build_tensor(Cons(d, Cons(d, Cons(d, Nil))), state, joint) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((metric, first_tensor, state))
}

///|

///|
/// Fisher metric two-jet in natural coordinates (linear/quadratic statistics).
/// Second, third and fourth cumulants are evaluated by exact Gaussian moments.
/// No density values, quadrature or finite-difference approximations are used.
pub fn fisher_jet(
  source : Gaussian,
) -> Result[@riemann.MetricJet, GaussianError] {
  let (metric, first_tensor, state) = match prepare_information(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let d = @core.length(state.centered)
  let indices = @core.indices(d)
  let (second_tensor, _) = match
    build_tensor(Cons(d, Cons(d, Cons(d, Cons(d, Nil)))), state, fn(
      state,
      coordinates,
    ) {
      match coordinates {
        Cons(i, Cons(j, Cons(k, Cons(l, Nil)))) =>
          match joint(state, coordinates) {
            Err(error) => Err(error)
            Ok((fourth, state)) => {
              let pairs = @exact.rational_add(
                @exact.rational_add(
                  @exact.rational_multiply(
                    tensor_value(metric, Cons(i, Cons(j, Nil))),
                    tensor_value(metric, Cons(k, Cons(l, Nil))),
                  ),
                  @exact.rational_multiply(
                    tensor_value(metric, Cons(i, Cons(k, Nil))),
                    tensor_value(metric, Cons(j, Cons(l, Nil))),
                  ),
                ),
                @exact.rational_multiply(
                  tensor_value(metric, Cons(i, Cons(l, Nil))),
                  tensor_value(metric, Cons(j, Cons(k, Nil))),
                ),
              )
              Ok((@exact.rational_subtract(fourth, pairs), state))
            }
          }
        _ => Err(InternalShape)
      }
    }) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  fn matrix(
    f : (@core.Nat, @core.Nat) -> @exact.Rational,
  ) -> @matrix.Matrix[@exact.Rational]? {
    @matrix.matrix(
      d,
      @core.map(indices, fn(i) { @core.map(indices, fn(j) { f(i, j) }) }),
    )
  }
  let value = match
    matrix(fn(i, j) { tensor_value(metric, Cons(i, Cons(j, Nil))) }) {
    Some(value) => value
    None => return Err(InternalShape)
  }
  fn matrices(
    f : (@core.Nat) -> @matrix.Matrix[@exact.Rational]?,
  ) -> @core.Chain[@matrix.Matrix[@exact.Rational]]? {
    fn walk_rows(
      indices : @core.Chain[@core.Nat],
    ) -> @core.Chain[@matrix.Matrix[@exact.Rational]]? {
      match indices {
        Nil => Some(Nil)
        Cons(i, rest) =>
          match (f(i), walk_rows(rest)) {
            (Some(matrix), Some(rest)) => Some(Cons(matrix, rest))
            _ => None
          }
      }
    }
    walk_rows(indices)
  }
  let first = match
    matrices(fn(k) {
      matrix(fn(i, j) {
        tensor_value(first_tensor, Cons(k, Cons(i, Cons(j, Nil))))
      })
    }) {
    Some(value) => value
    None => return Err(InternalShape)
  }
  fn second_rows(
    ks : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@matrix.Matrix[@exact.Rational]]]? {
    match ks {
      Nil => Some(Nil)
      Cons(k, rest) =>
        match
          (
            matrices(fn(l) {
              matrix(fn(i, j) {
                tensor_value(
                  second_tensor,
                  Cons(k, Cons(l, Cons(i, Cons(j, Nil)))),
                )
              })
            }),
            second_rows(rest),
          ) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
    }
  }
  let second = match second_rows(indices) {
    Some(value) => value
    None => return Err(InternalShape)
  }
  match @riemann.metric_jet(value, first, second) {
    Ok(value) => Ok(value)
    Err(error) => Err(Geometry(error))
  }
}
