///|
fn test_polynomial(values : Array[(Int32, Int32)]) -> @poly.Polynomial {
  sparse(
    @oracle.chain(values.map(fn(pair) { @oracle.rational(pair.0, pair.1) })),
  ).unwrap()
}

///|
fn test_integer_polynomial(values : Array[Int32]) -> @poly.Polynomial {
  test_polynomial(values.map(fn(c) { (c, 1) }))
}

///|
fn test_number(
  values : Array[Int32],
  lower : (Int32, Int32),
  upper : (Int32, Int32),
) -> Number {
  number({
    polynomial: test_integer_polynomial(values),
    interval: {
      lower: @oracle.rational(lower.0, lower.1),
      upper: @oracle.rational(upper.0, upper.1),
    },
  }).unwrap()
}

///|
fn assert_compared(
  a : Number,
  b : Number,
  expected : @core.Ordering,
  fuel : Int32,
) -> Unit raise {
  match compare(a, b, @oracle.nat(fuel)).unwrap() {
    Compared(order, proof) => {
      assert_eq(order, expected)
      assert_true(check_comparison(proof))
      let wrong = match order {
        Less => @core.Greater
        _ => @core.Less
      }
      assert_false(check_comparison({ ..proof, order: wrong, }))
      assert_false(
        check_comparison({
          ..proof,
          left_refined: {
            lower: @oracle.rational(-100, 1),
            upper: @oracle.rational(100, 1),
          },
        }),
      )
    }
    _ => fail("comparison unexpectedly paused")
  }
}

///|
test "construction checks half-open single-root semantics" {
  assert_true(
    number({
      polynomial: test_integer_polynomial([0]),
      interval: {
        lower: @oracle.rational(-1, 1),
        upper: @oracle.rational(1, 1),
      },
    })
    is Err(InvalidDefinition),
  )
  for
    (lower, upper) in [
      ((0, 1), (0, 1)),
      ((2, 1), (1, 1)),
      ((-2, 1), (2, 1)),
      ((1, 1), (2, 1)),
    ] {
    assert_true(
      number({
        polynomial: test_integer_polynomial([-1, 0, 1]),
        interval: {
          lower: @oracle.rational(lower.0, lower.1),
          upper: @oracle.rational(upper.0, upper.1),
        },
      })
      is Err(InvalidInterval),
    )
  }
  let root = test_number([-1, 0, 1], (-2, 1), (-1, 1))
  assert_true(check_root(root_certificate(root)))
  assert_compared(root, rational(@oracle.rational(-1, 1)).unwrap(), Equal, 0)
  let repeated = test_number([1, -2, 1], (0, 1), (1, 1))
  assert_compared(repeated, rational(@oracle.rational(1, 1)).unwrap(), Equal, 0)
}

///|
test "exact comparison handles gcd equality and disjoint endpoints" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = test_number([-3, 0, 1], (1, 1), (2, 1))
  assert_true(compare(a, b, Zero).unwrap() is ComparisonPaused(_))
  assert_compared(a, b, Less, 1)
  assert_compared(b, a, Greater, 1)
  let same = test_number([-2, 0, -1, 0, 1], (1, 1), (2, 1))
  assert_compared(a, same, Equal, 0)
  assert_compared(test_number([-2, 0, 1], (-2, 1), (-1, 1)), a, Less, 0)
  assert_compared(
    rational(@oracle.rational(0, 1)).unwrap(),
    rational(@oracle.rational(1, 1)).unwrap(),
    Less,
    0,
  )
}

///|
test "close unequal roots pause then resume without an approximate equality" {
  let a = test_number([-2, 0, 1], (1, 1), (2, 1))
  let b = number({
    polynomial: test_polynomial([(-2049, 1024), (0, 1), (1, 1)]),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }).unwrap()
  let state = match compare(a, b, @oracle.nat(3)).unwrap() {
    ComparisonPaused(state) => state
    _ => abort("close roots must remain unresolved after three bisections")
  }
  match compare_advance(state, @oracle.nat(20)).unwrap() {
    Compared(Less, proof) => assert_true(check_comparison(proof))
    _ => fail("close roots must separate")
  }
}
