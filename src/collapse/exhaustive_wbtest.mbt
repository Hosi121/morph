///|
test "all four vertex complexes agree with independent free pair enumeration and chain contractions" {
  let mut total_candidates = 0
  let mut total_accepted = 0
  assert_eq(collapse_fixtures().length(), 167)
  for fixture in collapse_fixtures() {
    let (facets, pairs) = fixture
    let source = generated(facets)
    let faces = numeric_faces(source)
    let mut accepted = 0
    for lower in faces {
      for upper in faces {
        let actual_pair = pair(lower, upper)
        let expected = pairs.contains((lower, upper))
        total_candidates += 1
        assert_eq(is_free(source, actual_pair), expected)
        match elementary(source, actual_pair) {
          None => assert_false(expected)
          Some(witness) => {
            accepted += 1
            assert_true(expected)
            assert_true(check(source, witness.target, witness))
            assert_eq(
              numeric_faces(witness.target),
              faces.filter(fn(face) { face != lower && face != upper }),
            )
            oracle_check_step(witness)
          }
        }
      }
    }
    assert_eq(accepted, pairs.length())
    total_accepted += accepted
    let result = finished(source)
    assert_true(check_sequence(source, result.target, result))
    let final_faces = numeric_faces(result.target)
    for lower in final_faces {
      for upper in final_faces {
        assert_false(is_free(result.target, pair(lower, upper)))
      }
    }
  }
  assert_eq(total_candidates, 9781)
  assert_eq(total_accepted, 340)
}

///|
test "same shape corruption of every stored matrix entry is rejected" {
  let source = generated([[0, 1, 2, 3]])
  let witness = elementary(source, pair([0, 1, 2], [0, 1, 2, 3])).unwrap()
  for k, original in @oracle.array(witness.maps) {
    for
      selected, matrix in [
        original.inclusion,
        original.projection,
        original.homotopy,
      ] {
      let numeric = numeric_matrix(matrix)
      for row in 0..<numeric.rows.length() {
        for column in 0..<numeric.width {
          let changed_rows = Array::makei(numeric.rows.length(), fn(i) {
            @oracle.chain(
              Array::makei(numeric.width, fn(j) {
                @oracle.integer(
                  numeric.rows[i][j] +
                  (if i == row && j == column { 1 } else { 0 }),
                )
              }),
            )
          })
          let changed = @matrix.matrix(
            @oracle.nat(numeric.width),
            @oracle.chain(changed_rows),
          ).unwrap()
          let bad_degree = if selected == 0 {
            { ..original, inclusion: changed, }
          } else if selected == 1 {
            { ..original, projection: changed, }
          } else {
            { ..original, homotopy: changed, }
          }
          let bad_maps = @core.append(
            @core.take(@oracle.nat(k), witness.maps),
            @core.Cons(bad_degree, @core.drop(@oracle.nat(k + 1), witness.maps)),
          )
          assert_false(
            check(source, witness.target, { ..witness, maps: bad_maps, }),
          )
        }
      }
    }
  }
}
