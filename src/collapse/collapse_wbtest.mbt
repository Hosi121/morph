///|
fn simplex(vertices : Array[Int32]) -> @core.Chain[@core.Nat] {
  @oracle.chain(vertices.map(@oracle.nat))
}

///|
fn generated(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(@oracle.chain(facets.map(simplex))).unwrap()
}

///|
fn pair(lower : Array[Int32], upper : Array[Int32]) -> Pair {
  { lower: simplex(lower), upper: simplex(upper), }
}

///|
fn finished(source : @homology.Complex) -> Sequence {
  match run(start(source), @oracle.nat(2000)) {
    Stalled(witness) => witness
    _ => abort("small collapse search should finish")
  }
}

///|
fn homology_result(
  source : @homology.Complex,
  degree : Int32,
) -> @homology.ResultGroup raise {
  match @homology.compute(source, @oracle.nat(degree), @oracle.nat(2000)) {
    Computed(witness) => {
      assert_true(
        @homology.check_result(
          source,
          @oracle.nat(degree),
          witness.result,
          witness,
        ),
      )
      witness.result
    }
    _ => abort("small homology computation should finish")
  }
}

///|
fn verify_sequence(
  source : @homology.Complex,
  witness : Sequence,
) -> Unit raise {
  assert_true(check_sequence(source, witness.target, witness))
  for degree in 0..<5 {
    assert_eq(
      homology_result(source, degree),
      homology_result(witness.target, degree),
    )
  }
}

///|
test "elementary edge preserves unreduced H0 with exact orientation and shapes" {
  let source = generated([[0, 1]])
  for free_pair in [pair([0], [0, 1]), pair([1], [0, 1])] {
    let step = elementary(source, free_pair).unwrap()
    assert_true(check(source, step.target, step))
    assert_eq(
      step.orientation,
      @oracle.integer(if free_pair.lower == simplex([0]) { -1 } else { 1 }),
    )
    assert_eq(@core.length(step.maps), @oracle.nat(3))
    let degree_zero = degree_maps(step, @oracle.nat(0)).unwrap()
    assert_eq(@matrix.height(degree_zero.projection), @oracle.nat(1))
    assert_eq(@matrix.width(degree_zero.projection), @oracle.nat(2))
    assert_eq(
      @matrix.rows(degree_zero.projection),
      @oracle.chain([@oracle.chain([@oracle.integer(1), @oracle.integer(1)])]),
    )
    assert_eq(
      @matrix.height(degree_maps(step, @oracle.nat(2)).unwrap().homotopy),
      @oracle.nat(0),
    )
    assert_eq(degree_maps(step, @oracle.nat(3)), None)
  }
}

///|
test "filled triangle tetrahedron and triangulated square collapse to a vertex" {
  for
    source in [
      generated([[0, 1, 2]]),
      generated([[0, 1, 2, 3]]),
      generated([[0, 1, 2], [0, 2, 3]]),
    ] {
    let witness = finished(source)
    assert_eq(
      @core.length(@homology.all_simplices(witness.target)),
      @oracle.nat(1),
    )
    verify_sequence(source, witness)
  }
}

///|
fn projective_plane() -> @homology.Complex {
  generated([
    [0, 1, 2],
    [0, 2, 3],
    [0, 1, 5],
    [0, 4, 5],
    [0, 3, 4],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 5],
    [2, 3, 5],
    [2, 4, 5],
  ])
}

///|
test "circle sphere and projective plane stay while dangling trees disappear" {
  let circle = generated([[0, 1], [0, 2], [1, 2]])
  let sphere = generated([[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]])
  for
    source in [
      generated([]),
      generated([[3]]),
      circle,
      sphere,
      projective_plane(),
    ] {
    let witness = finished(source)
    assert_eq(witness.target, source)
    assert_eq(witness.steps, @core.Nil)
    verify_sequence(source, witness)
  }
  let dangling = generated([[0, 1], [0, 2], [1, 2], [2, 3], [3, 4]])
  let witness = finished(dangling)
  assert_eq(witness.target, circle)
  assert_eq(@core.length(witness.steps), @oracle.nat(2))
  verify_sequence(dangling, witness)
}

///|
test "nonfree codimension wrong missing and noncanonical pairs are rejected" {
  let triangle = generated([[0, 1, 2]])
  let circle = generated([[0, 1], [0, 2], [1, 2]])
  for
    free_pair in [
      pair([0], [0, 1]),
      pair([0], [0, 1, 2]),
      pair([], [0]),
      pair([0, 1], [1, 0, 2]),
      pair([9], [8, 9]),
      pair([0, 1, 2], [0, 1, 2]),
    ] {
    assert_false(is_free(triangle, free_pair))
    assert_eq(elementary(triangle, free_pair), None)
  }
  assert_eq(elementary(circle, pair([0], [0, 1])), None)
  assert_eq(
    elementary(generated([[0, 1, 2], [0, 1, 3]]), pair([0, 1], [0, 1, 2])),
    None,
  )
}

///|
test "untrusted witness orientation matrices maps and endpoint tampering is rejected" {
  let source = generated([[0, 1, 2]])
  let witness = elementary(source, pair([0, 1], [0, 1, 2])).unwrap()
  assert_false(
    check(source, witness.target, {
      ..witness,
      orientation: @exact.negate(witness.orientation),
    }),
  )
  assert_false(
    check(source, witness.target, { ..witness, pair: pair([0, 2], [0, 1, 2]), }),
  )
  assert_false(check(generated([[0, 1, 2], [9]]), witness.target, witness))
  assert_false(check(source, generated([[0]]), witness))
  assert_false(
    check(source, witness.target, { ..witness, source: witness.target, }),
  )
  assert_false(check(source, witness.target, { ..witness, target: source, }))
  assert_false(check(source, witness.target, { ..witness, maps: @core.Nil, }))
  for degree in 0..<4 {
    let k = @oracle.nat(degree)
    let original = degree_maps(witness, k).unwrap()
    let empty = @matrix.matrix(@oracle.nat(2), @core.Nil).unwrap()
    for
      wrong in [
        { ..original, inclusion: empty, },
        { ..original, projection: empty, },
        { ..original, homotopy: empty, },
      ] {
      let changed = @core.append(
        @core.take(k, witness.maps),
        @core.Cons(wrong, @core.drop(@core.Succ(k), witness.maps)),
      )
      assert_false(check(source, witness.target, { ..witness, maps: changed, }))
    }
  }
  let degree_one = degree_maps(witness, @oracle.nat(1)).unwrap()
  let wrong_h = zero_map(
    @matrix.height(degree_one.homotopy),
    @matrix.width(degree_one.homotopy),
  ).unwrap()
  let changed = @core.Cons(
    degree_maps(witness, @oracle.nat(0)).unwrap(),
    @core.Cons(
      { ..degree_one, homotopy: wrong_h, },
      @core.drop(@oracle.nat(2), witness.maps),
    ),
  )
  assert_false(check(source, witness.target, { ..witness, maps: changed, }))
}

///|
test "immutable continuation meters candidate attempts and sequences bind actual endpoints" {
  let source = generated([[0, 1, 2]])
  let initial = start(source)
  assert_eq(run(initial, @oracle.nat(0)), Paused(initial))
  let one_shot = finished(source)
  let mut current = initial
  let mut attempts = 0
  let mut done = false
  while !done && attempts < 2000 {
    match run(current, @oracle.nat(1)) {
      Paused(next) => {
        assert_true(
          check_sequence(source, sequence(next).target, sequence(next)),
        )
        current = next
      }
      Stalled(witness) => {
        assert_eq(witness, one_shot)
        done = true
      }
      InvalidWitness => abort("valid continuation must not fail")
    }
    attempts += 1
  }
  assert_true(done)
  assert_true(attempts > 3)
  assert_false(check_sequence(generated([[8]]), one_shot.target, one_shot))
  assert_false(check_sequence(source, generated([[8]]), one_shot))
  assert_false(
    check_sequence(source, one_shot.target, {
      ..one_shot,
      steps: @core.reverse(one_shot.steps),
    }),
  )
}
