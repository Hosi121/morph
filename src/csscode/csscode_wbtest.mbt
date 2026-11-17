///|
fn bits(width : Int32, mask : Int32) -> @core.Chain[Bool] {
  @oracle.chain(Array::makei(width, fn(i) { (mask & (1 << i)) != 0 }))
}

///|
fn masks(width : Int32, rows : Array[Int32]) -> @matrix.Matrix[Bool] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(fn(row) { bits(width, row) })),
  ).unwrap()
}

///|
fn code(width : Int32, hx : Array[Int32], hz : Array[Int32]) -> Code {
  validate(masks(width, hx), masks(width, hz)).unwrap()
}

///|
fn complex(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn find(code : Code, axis : Axis) -> DistanceWitness {
  // Small batches keep both fuel and recursive call depth bounded.
  fn finish_search(state : DistanceState, batches : Int32) -> DistanceWitness {
    if batches <= 0 {
      abort("fixture distance exceeded its finite budget")
    }
    match run_distance(state, @oracle.nat(64)) {
      Found(witness) => witness
      Paused(next) => finish_search(next, batches - 1)
      NoLogical => abort("expected a nontrivial logical operator")
    }
  }
  finish_search(start_distance(code, axis), 1024)
}

///|
fn verify_minimum(
  code : Code,
  axis : Axis,
  witness : DistanceWitness,
) -> Unit raise {
  fn finish_check(check : DistanceCheck, batches : Int32) -> Bool {
    if batches <= 0 {
      abort("fixture verification exceeded its finite budget")
    }
    match check {
      Verified => true
      Rejected => false
      CheckPaused(state) =>
        finish_check(resume_check(state, @oracle.nat(64)), batches - 1)
    }
  }
  assert_true(
    finish_check(check_distance(code, axis, witness, @oracle.nat(0)), 1024),
  )
}

///|
fn parity(value : Int32) -> Bool {
  let mut value = value
  let mut odd = false
  while value != 0 {
    odd = !odd
    value = value & (value - 1)
  }
  odd
}

///|
fn verify_fixture(
  n : Int32,
  hx : Array[Int32],
  hz : Array[Int32],
  expected : Array[Int32],
  sets : Array[Int32],
) -> Unit raise {
  let code = code(n, hx, hz)
  let p = parameters(code)
  assert_eq(
    [
      @oracle.int_of_nat(p.rank_x),
      @oracle.int_of_nat(p.rank_z),
      @oracle.int_of_nat(p.logical),
      distance_value(code, X),
      distance_value(code, Z),
    ],
    expected,
  )
  assert_true(check_parameters(code, p, certificate(code)))
  for vector in 0..<(1 << n) {
    let v = bits(n, vector)
    assert_eq(
      syndrome(code, X, v),
      Some(@oracle.chain(hz.map(fn(row) { parity(row & vector) }))),
    )
    assert_eq(
      syndrome(code, Z, v),
      Some(@oracle.chain(hx.map(fn(row) { parity(row & vector) }))),
    )
    assert_eq(in_stabilizer(code, X, v), Some((sets[0] & (1 << vector)) != 0))
    assert_eq(in_stabilizer(code, Z, v), Some((sets[1] & (1 << vector)) != 0))
    assert_eq(is_logical(code, X, v), Some((sets[2] & (1 << vector)) != 0))
    assert_eq(is_logical(code, Z, v), Some((sets[3] & (1 << vector)) != 0))
  }
  // Duplicated/permuted rows and zero checks must preserve all parameters.
  let redundant = validate(
    masks(n, [..hx.rev(), ..hx, 0]),
    masks(n, [..hz.rev(), ..hz, 0]),
  ).unwrap()
  assert_eq(parameters(redundant), p)
  assert_eq(distance_value(redundant, X), expected[3])
  assert_eq(distance_value(redundant, Z), expected[4])
}

///|
fn verify_topology(code : Code, expected : Array[Int32]) -> Unit raise {
  let p = parameters(code)
  assert_eq(
    [
      @oracle.int_of_nat(p.physical),
      @oracle.int_of_nat(p.rank_x),
      @oracle.int_of_nat(p.rank_z),
      @oracle.int_of_nat(p.logical),
    ],
    expected[:4].to_owned(),
  )
  assert_true(check_parameters(code, p, certificate(code)))
  for i, axis in [X, Z] {
    let witness = find(code, axis)
    assert_eq(@oracle.int_of_nat(witness.distance), expected[4 + i])
    verify_minimum(code, axis, witness)
  }
}

///|
fn distance_value(code : Code, axis : Axis) -> Int32 {
  match run_distance(start_distance(code, axis), @oracle.nat(0)) {
    NoLogical => -1
    _ => @oracle.int_of_nat(find(code, axis).distance)
  }
}

///|
test "GF2 parity differs from Boolean reachability and shape validation is exact" {
  assert_false(xor(true, true))
  let pair = masks(2, [3])
  assert_true(commute(pair, pair))
  assert_eq(
    @matrix.multiply(pair, @matrix.transpose(pair), scalars()),
    Some(masks(1, [0])),
  )
  assert_eq(
    @matrix.multiply(pair, @matrix.transpose(pair), @algebra.booleans()),
    Some(masks(1, [1])),
  )
  assert_eq(validate(masks(1, [1]), masks(1, [1])), None)
  assert_eq(validate(masks(2, []), masks(3, [])), None)
  assert_eq(@matrix.matrix(@oracle.nat(2), @oracle.chain([bits(1, 1)])), None)
  let empty = code(0, [], [])
  assert_eq(parameters(empty).logical, @oracle.nat(0))
  assert_eq(run_distance(start_distance(empty, X), @oracle.nat(0)), NoLogical)
  let full = code(2, [], [])
  assert_eq(parameters(full).logical, @oracle.nat(2))
  assert_eq(distance_value(full, X), 1)
  assert_eq(distance_value(full, Z), 1)
  assert_eq(syndrome(full, X, bits(1, 0)), None)
  assert_eq(in_stabilizer(full, X, bits(3, 0)), None)
  assert_eq(is_logical(full, Z, bits(1, 0)), None)
  assert_eq(is_logical(full, Z, bits(2, 0)), Some(false))
}

///|
test "Steane code has one logical qubit and exact X and Z distance three" {
  let steane = code(7, [85, 102, 120], [85, 102, 120])
  assert_eq(parameters(steane), Parameters::{
    physical: @oracle.nat(7),
    rank_x: @oracle.nat(3),
    rank_z: @oracle.nat(3),
    logical: @oracle.nat(1),
  })
  assert_true(check_parameters(steane, parameters(steane), certificate(steane)))
  for axis in [X, Z] {
    let witness = find(steane, axis)
    assert_eq(witness.distance, @oracle.nat(3))
    assert_eq(weight(witness.vector), @oracle.nat(3))
    verify_minimum(steane, axis, witness)
    assert_eq(is_logical(steane, axis, witness.vector), Some(true))
    for i in 0..<7 {
      assert_true(
        @oracle.array(syndrome(steane, axis, bits(7, 1 << i)).unwrap()).contains(
          true,
        ),
      )
    }
  }
}

///|
test "resumption neither skips nor repeats candidates and fuel exhaustion stays explicit" {
  let steane = code(7, [85, 102, 120], [85, 102, 120])
  let initial = start_distance(steane, X)
  assert_eq(run_distance(initial, @oracle.nat(0)), Paused(initial))
  guard run_distance(initial, @oracle.nat(1)) is Paused(one) else {
    abort("one candidate cannot solve Steane distance")
  }
  assert_eq(progress(one), (@oracle.nat(1), @oracle.nat(1)))
  assert_eq(
    run_distance(one, @oracle.nat(8)),
    run_distance(initial, @oracle.nat(9)),
  )
  let mut state = initial
  let mut completed = false
  for _ in 0..<128 {
    if !completed {
      match run_distance(state, @oracle.nat(1)) {
        Paused(next) => state = next
        Found(witness) => {
          assert_eq(witness, find(steane, X))
          completed = true
        }
        NoLogical => abort("Steane has a logical qubit")
      }
    }
  }
  assert_true(completed)
  match check_distance(steane, X, find(steane, X), @oracle.nat(0)) {
    CheckPaused(_) => ()
    _ => abort("distance-three minimum verification needs candidate fuel")
  }
}

///|
test "algebraic rank certificates reject source result transforms pivots and noncanonical reductions" {
  let good_code = code(3, [3, 3, 0], [])
  let good = certificate(good_code)
  let actual = parameters(good_code)
  assert_eq(actual.rank_x, @oracle.nat(1))
  assert_eq(actual.logical, @oracle.nat(2))
  assert_true(check_parameters(good_code, actual, good))
  assert_false(check_parameters(code(3, [5], []), actual, good))
  assert_false(
    check_parameters(good_code, { ..actual, logical: @oracle.nat(1), }, good),
  )
  assert_false(
    check_parameters(good_code, actual, {
      ..good,
      result: { ..actual, logical: @oracle.nat(1), },
    }),
  )
  assert_false(
    check_rank(good.x_rank.source, { ..good.x_rank, pivots: @core.Nil, }),
  )
  assert_false(
    check_rank(good.x_rank.source, {
      ..good.x_rank,
      source: masks(3, [5, 5, 0]),
    }),
  )
  assert_false(
    check_rank(good.x_rank.source, {
      ..good.x_rank,
      transform: masks(3, [0, 0, 0]),
    }),
  )
  assert_false(
    check_rank(good.x_rank.source, {
      ..good.x_rank,
      inverse_transform: masks(3, [0, 0, 0]),
    }),
  )
  assert_false(
    check_rank(good.x_rank.source, {
      ..good.x_rank,
      reduced: masks(3, [5, 0, 0]),
    }),
  )
  assert_eq(canonical_pivots(masks(3, [0, 1])), None)
  assert_eq(canonical_pivots(masks(3, [2, 1])), None)
  assert_eq(canonical_pivots(masks(3, [3, 2])), None)
}

///|
test "distance witnesses reject wrong source axis weight stabilizers and nonminimum logicals" {
  let plain = code(3, [], [])
  let witness = find(plain, Z)
  assert_eq(check_distance(plain, Z, witness, @oracle.nat(0)), Verified)
  assert_eq(
    check_distance(code(3, [3], []), Z, witness, @oracle.nat(1)),
    Rejected,
  )
  assert_eq(check_distance(plain, X, witness, @oracle.nat(1)), Rejected)
  assert_eq(
    check_distance(
      plain,
      Z,
      { ..witness, distance: @oracle.nat(0), },
      @oracle.nat(1),
    ),
    Rejected,
  )
  assert_eq(
    check_distance(plain, Z, { ..witness, vector: bits(3, 0), }, @oracle.nat(1)),
    Rejected,
  )
  assert_eq(
    check_distance(plain, Z, { ..witness, vector: bits(4, 1), }, @oracle.nat(1)),
    Rejected,
  )
  let heavier = { ..witness, vector: bits(3, 3), distance: @oracle.nat(2), }
  assert_eq(check_distance(plain, Z, heavier, @oracle.nat(1)), Rejected)
  let stabilized = code(3, [], [1])
  assert_eq(
    check_distance(
      stabilized,
      Z,
      { ..witness, source: stabilized, vector: bits(3, 1), },
      @oracle.nat(1),
    ),
    Rejected,
  )
}

///|
test "chain adapter circle and tetrahedral sphere use edge qubits and preserve zero shapes" {
  let circle = from_complex(complex([[0, 1], [0, 2], [1, 2]]), @oracle.nat(1)).unwrap()
  assert_eq(parameters(circle).physical, @oracle.nat(3))
  assert_eq(parameters(circle).logical, @oracle.nat(1))
  assert_eq(distance_value(circle, Z), 3)
  assert_eq(distance_value(circle, X), 1)
  let sphere = from_complex(
    complex([[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]),
    @oracle.nat(1),
  ).unwrap()
  assert_eq(parameters(sphere).physical, @oracle.nat(6))
  assert_eq(parameters(sphere).logical, @oracle.nat(0))
  assert_eq(distance_value(sphere, X), -1)
  assert_eq(distance_value(sphere, Z), -1)
  let empty = from_complex(complex([]), @oracle.nat(0)).unwrap()
  assert_eq(parameters(empty).physical, @oracle.nat(0))
  let point = from_complex(complex([[4]]), @oracle.nat(0)).unwrap()
  assert_eq(parameters(point).logical, @oracle.nat(1))
  assert_eq(distance_value(point, X), 1)
  assert_eq(distance_value(point, Z), 1)
  let beyond = from_complex(complex([[4]]), @oracle.nat(7)).unwrap()
  assert_eq(parameters(beyond).physical, @oracle.nat(0))
}
