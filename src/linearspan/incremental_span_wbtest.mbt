///|
fn span_vector(values : Array[(Int32, Int32)]) -> @core.Chain[@exact.Rational] {
  @oracle.chain(values.map(fn(q) { @oracle.rational(q.0, q.1) }))
}

///|
fn integer_vector(x : Int32, y : Int32) -> @core.Chain[@exact.Rational] {
  span_vector([(x, 1), (y, 1)])
}

///|
fn independent_state(
  state : State,
  vector : @core.Chain[@exact.Rational],
) -> State {
  match insert(state, vector).unwrap() {
    Independent(next) => next
    _ => abort("fixture column must be independent")
  }
}

///|
fn legacy_solution(
  vectors : @core.Chain[@core.Chain[@exact.Rational]],
  vector : @core.Chain[@exact.Rational],
) -> @linear.Solution {
  let matrix = @matrix.transpose(
    @matrix.matrix(@core.length(vector), vectors).unwrap(),
  )
  @linear.solve(matrix, vector).unwrap()
}

///|
test "incremental span zero dimensions rank cap bad dimensions and persistence" {
  let empty0 = empty(@oracle.nat(0))
  assert_eq(insert(empty0, Nil), Ok(Dependent(Nil)))
  assert_eq(
    insert(empty0, Cons(@oracle.rational(0, 1), Nil)),
    Err(DimensionMismatch),
  )
  let initial = empty(@oracle.nat(2))
  assert_eq(insert(initial, Nil), Err(DimensionMismatch))
  assert_eq(insert(initial, integer_vector(0, 0)), Ok(Dependent(Nil)))
  let y = independent_state(initial, integer_vector(0, 2))
  let full = independent_state(y, integer_vector(3, 4))
  assert_eq(rank(initial), @oracle.nat(0))
  assert_eq(rank(y), @oracle.nat(1))
  assert_eq(rank(full), dimension(full))
  assert_eq(
    insert(y, integer_vector(0, 6)),
    Ok(Dependent(span_vector([(3, 1)]))),
  )
  assert_eq(
    insert(full, integer_vector(6, 14)),
    Ok(Dependent(span_vector([(3, 1), (2, 1)]))),
  )
  assert_eq(
    insert(full, integer_vector(0, 0)),
    Ok(Dependent(span_vector([(0, 1), (0, 1)]))),
  )
  // A separate branch and a dimension failure cannot change an older state.
  let other = independent_state(y, integer_vector(1, 0))
  assert_eq(
    insert(other, integer_vector(1, 2)),
    Ok(Dependent(span_vector([(1, 1), (1, 1)]))),
  )
  assert_eq(
    insert(full, Cons(@oracle.rational(1, 1), Nil)),
    Err(DimensionMismatch),
  )
  assert_eq(independent_state(y, integer_vector(3, 4)), full)
}

///|
/// Exhaust all three-vector sequences in {-1,0,1}^2. Direct 2x2 determinants
/// and Cramer's rule independently decide each step; full linear.solve is a
/// second oracle. Dependent vectors do not alter the original basis order.
test "incremental span exhaustive finite vectors with determinant and legacy oracles" {
  for ax in -1..<=1 {
    for ay in -1..<=1 {
      for bx in -1..<=1 {
        for by in -1..<=1 {
          for cx in -1..<=1 {
            for cy in -1..<=1 {
              let mut state = empty(@oracle.nat(2))
              let mut original : @core.Chain[@core.Chain[@exact.Rational]] = Nil
              let originals : Array[(Int32, Int32)] = []
              for pair in [(ax, ay), (bx, by), (cx, cy)] {
                let (x, y) = pair
                let vector = integer_vector(x, y)
                let expected : @core.Chain[@exact.Rational]? = match
                  originals.length() {
                  0 => if x == 0 && y == 0 { Some(Nil) } else { None }
                  1 => {
                    let (a, b) = originals[0]
                    if a * y - b * x != 0 {
                      None
                    } else {
                      let (n, d) = if a != 0 { (x, a) } else { (y, b) }
                      Some(
                        span_vector([
                          (
                            if d < 0 {
                              -n
                            } else {
                              n
                            },
                            if d < 0 {
                              -d
                            } else {
                              d
                            },
                          ),
                        ]),
                      )
                    }
                  }
                  _ => {
                    let (a, b) = originals[0]
                    let (c, d) = originals[1]
                    let det = a * d - b * c
                    let ns = [(x * d - y * c, det), (a * y - b * x, det)]
                    Some(
                      span_vector(
                        ns.map(fn(q) { if q.1 < 0 { (-q.0, -q.1) } else { q } }),
                      ),
                    )
                  }
                }
                let actual = insert(state, vector).unwrap()
                let legacy = legacy_solution(original, vector)
                match (expected, actual) {
                  (Some(coefficients), Dependent(cs)) => {
                    assert_eq(cs, coefficients)
                    assert_eq(legacy, @linear.Unique(coefficients))
                  }
                  (None, Independent(next)) => {
                    assert_eq(legacy, @linear.Inconsistent)
                    assert_eq(rank(next), @core.Succ(rank(state)))
                    state = next
                    original = @core.append(original, Cons(vector, Nil))
                    originals.push(pair)
                  }
                  _ =>
                    fail(
                      "incremental decision disagrees with direct determinants",
                    )
                }
              }
            }
          }
        }
      }
    }
  }
}

///|
fn fraction_fixture(
  dimension : Int32,
  vectors : Array[Array[(Int32, Int32)]],
  expected : Array[Array[(Int32, Int32)]?],
) -> Unit raise {
  let mut state = empty(@oracle.nat(dimension))
  let mut originals : @core.Chain[@core.Chain[@exact.Rational]] = Nil
  for i, vector in vectors {
    let v = span_vector(vector)
    match (insert(state, v).unwrap(), expected[i]) {
      (Dependent(cs), Some(witness)) => {
        let expected_cs = span_vector(witness)
        assert_eq(cs, expected_cs)
        assert_eq(legacy_solution(originals, v), @linear.Unique(expected_cs))
      }
      (Independent(next), None) => {
        assert_eq(legacy_solution(originals, v), @linear.Inconsistent)
        assert_eq(rank(state), @core.length(originals))
        state = next
        originals = @core.append(originals, Cons(v, Nil))
      }
      _ => fail("Python Fraction full-system oracle disagrees")
    }
  }
}
