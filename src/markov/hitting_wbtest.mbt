///|
fn fraction_hitting_fixture(
  rows : Array[Array[(Int32, Int32)]],
  targets : Array[Int32],
  probabilities : Array[(Int32, Int32)],
  times : Array[(Int32, Int32)?],
) -> Unit raise {
  let value = kernel(fraction_rows(rows)).unwrap()
  let target_indices = @oracle.chain(targets.map(@oracle.nat))
  let result = hitting(value, target_indices).unwrap()
  let expected_times = @oracle.chain(
    times.map(fn(duration) {
      match duration {
        None => Infinite
        Some((n, d)) => Finite(@oracle.rational(n, d))
      }
    }),
  )
  assert_eq(hitting_kernel(result), value)
  assert_eq(hitting_targets(result), target_indices)
  assert_eq(hitting_probabilities(result), fraction_vector(probabilities))
  assert_eq(expected_hitting_times(result), expected_times)
  assert_true(check_hitting(value, target_indices, result))
  let paths = @oracle.array(hitting_paths(result))
  for i in 0..<paths.length() {
    assert_eq(paths[i] is None, probabilities[i].0 == 0)
    match paths[i] {
      None => ()
      Some(path) =>
        assert_true(@oracle.int_of_nat(@core.length(path)) <= rows.length())
    }
  }
}

///|
test "hitting uses time zero and handles empty duplicate or invalid targets" {
  let swap = kernel(fraction_rows([[(0, 1), (1, 1)], [(1, 1), (0, 1)]])).unwrap()
  let target = @oracle.chain([@oracle.nat(0)])
  let result = hitting(swap, target).unwrap()
  assert_eq(hitting_probabilities(result), fraction_vector([(1, 1), (1, 1)]))
  assert_eq(
    expected_hitting_times(result),
    @oracle.chain([
      Finite(@oracle.rational(0, 1)),
      Finite(@oracle.rational(1, 1)),
    ]),
  )
  let empty = hitting(swap, Nil).unwrap()
  assert_eq(hitting_probabilities(empty), fraction_vector([(0, 1), (0, 1)]))
  assert_eq(expected_hitting_times(empty), @oracle.chain([Infinite, Infinite]))
  assert_eq(hitting(swap, @oracle.chain([@oracle.nat(2)])), Err(InvalidState))
  let all = hitting(
    swap,
    @oracle.chain([@oracle.nat(1), @oracle.nat(0), @oracle.nat(1)]),
  ).unwrap()
  assert_eq(
    hitting_targets(all),
    @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
  )
  assert_eq(
    expected_hitting_times(all),
    @oracle.chain([
      Finite(@oracle.rational(0, 1)),
      Finite(@oracle.rational(0, 1)),
    ]),
  )
  assert_true(!check_hitting(swap, Nil, result))
  assert_true(!check_hitting(identity(@oracle.nat(2)).unwrap(), target, result))
}

///|
test "partial absorption is not a finite conditional expected time" {
  let value = kernel(
    fraction_rows([
      [(0, 1), (1, 2), (1, 2)],
      [(0, 1), (1, 1), (0, 1)],
      [(0, 1), (0, 1), (1, 1)],
    ]),
  ).unwrap()
  let target = @oracle.chain([@oracle.nat(1)])
  let result = hitting(value, target).unwrap()
  assert_eq(
    hitting_probabilities(result),
    fraction_vector([(1, 2), (1, 1), (0, 1)]),
  )
  assert_eq(
    expected_hitting_times(result),
    @oracle.chain([Infinite, Finite(@oracle.rational(0, 1)), Infinite]),
  )
  // This wrong vector satisfies every target/harmonic equation, but is not the
  // minimal nonnegative solution: the closed class at state 2 must get zero.
  let harmonic = {
    ..result,
    chances: fraction_vector([(3, 4), (1, 1), (1, 2)]),
  }
  assert_true(!check_hitting(value, target, harmonic))
  let wrong_time = {
    ..result,
    times: @oracle.chain([
      Finite(@oracle.rational(1, 1)),
      Finite(@oracle.rational(0, 1)),
      Infinite,
    ]),
  }
  assert_true(!check_hitting(value, target, wrong_time))
}

///|
test "hitting checker rejects invalid or incomplete reachability witnesses" {
  let value = kernel(
    fraction_rows([
      [(0, 1), (1, 2), (1, 2)],
      [(0, 1), (1, 1), (0, 1)],
      [(0, 1), (0, 1), (1, 1)],
    ]),
  ).unwrap()
  let target = @oracle.chain([@oracle.nat(1)])
  let result = hitting(value, target).unwrap()
  let wrongly_unreachable = {
    ..result,
    paths: @oracle.chain([None, Some(@oracle.chain([@oracle.nat(1)])), None]),
  }
  assert_true(!check_hitting(value, target, wrongly_unreachable))
  let wrong_end = {
    ..result,
    paths: @oracle.chain([
      Some(@oracle.chain([@oracle.nat(0), @oracle.nat(2)])),
      Some(@oracle.chain([@oracle.nat(1)])),
      None,
    ]),
  }
  assert_true(!check_hitting(value, target, wrong_end))
  let zero_edge = {
    ..result,
    paths: @oracle.chain([
      Some(@oracle.chain([@oracle.nat(0), @oracle.nat(0), @oracle.nat(1)])),
      Some(@oracle.chain([@oracle.nat(1)])),
      None,
    ]),
  }
  assert_true(!check_hitting(value, target, zero_edge))
  assert_true(!check_hitting(value, target, { ..result, paths: Nil, }))
  assert_true(
    !check_hitting(value, target, {
      ..result,
      chances: fraction_vector([(-1, 1), (1, 1), (0, 1)]),
    }),
  )
}

///|
test "known geometric and consecutive heads times satisfy the original equations" {
  fraction_hitting_fixture(
    [[(1, 2), (1, 2)], [(0, 1), (1, 1)]],
    [1],
    [(1, 1), (1, 1)],
    [Some((2, 1)), Some((0, 1))],
  )
  fraction_hitting_fixture(
    [
      [(1, 2), (1, 2), (0, 1)],
      [(1, 2), (0, 1), (1, 2)],
      [(0, 1), (0, 1), (1, 1)],
    ],
    [2],
    [(1, 1), (1, 1), (1, 1)],
    [Some((6, 1)), Some((4, 1)), Some((0, 1))],
  )
  let value = kernel(fraction_rows([[(1, 2), (1, 2)], [(0, 1), (1, 1)]])).unwrap()
  let target = @oracle.chain([@oracle.nat(1)])
  let result = hitting(value, target).unwrap()
  assert_true(
    !check_hitting(value, target, {
      ..result,
      times: @oracle.chain([
        Finite(@oracle.rational(1, 1)),
        Finite(@oracle.rational(0, 1)),
      ]),
    }),
  )
  assert_true(
    !check_hitting(value, target, {
      ..result,
      times: @oracle.chain([
        Finite(@oracle.rational(-2, 1)),
        Finite(@oracle.rational(0, 1)),
      ]),
    }),
  )
  assert_true(
    !check_hitting(value, target, {
      ..result,
      times: @oracle.chain([
        Finite(@oracle.rational(2, 1)),
        Finite(@oracle.rational(1, 1)),
      ]),
    }),
  )
}
