///|
test "FGLM cached span agrees with legacy solves across immutable pause branches" {
  let source = test_source(2, [
    test_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    test_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
  ])
  let initial = match start(source, GrevLex, @oracle.nat(3)).unwrap() {
    Paused(s) => s
    _ => abort("finite source must pause")
  }
  let expected = test_convert(source, GrevLex)
  let mut current = initial
  let mut completed = false
  for _ in 0..<40 {
    assert_eq(@linearspan.dimension(current.span_state), dimension(expected))
    assert_eq(
      @linearspan.rank(current.span_state),
      @core.length(current.standards),
    )
    assert_eq(@core.length(current.vectors), @core.length(current.standards))
    for values in [[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1], [2, -3, 1]] {
      let vector = @oracle.chain(values.map(fn(x) { @oracle.rational(x, 3) }))
      let (actual, next) = cached_span(current, vector).unwrap()
      match (span(current.vectors, vector).unwrap(), actual) {
        (Dependent(a), Dependent(b)) => {
          assert_eq(a, b)
          assert_eq(next, current.span_state)
        }
        (Independent, Independent) =>
          assert_eq(
            @linearspan.rank(next),
            Succ(@linearspan.rank(current.span_state)),
          )
        _ => fail("cache differs from full independent column solve")
      }
    }
    assert_eq(run(current, Zero), Ok(Paused(current)))
    assert_eq(step(current), step(current))
    match step(current).unwrap() {
      Paused(next) => current = next
      Complete(actual) => {
        assert_eq(actual, expected)
        assert_eq(verify(actual), Ok(true))
        completed = true
        break
      }
      _ => fail("unexpected dimension limit")
    }
  }
  assert_true(completed)
  // Resuming from the untouched original snapshot yields the same certificate,
  // result ordering, statistics and number of heap pops.
  assert_eq(run(initial, @oracle.nat(100)), Ok(Complete(expected)))
  assert_eq(state_statistics(initial).processed, Zero)
  assert_eq(@linearspan.rank(initial.span_state), Zero)
}
