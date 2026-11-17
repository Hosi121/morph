///|
// Frozen pre-sharing helper, retained as an exact result/None oracle.
fn s01_legacy_canonical_columns(
  target_homology : @homology.Certificate,
  cycle_map : @matrix.Matrix[@exact.Integer],
  source_left_inverse : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn normalize(
    columns : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match columns {
      Nil => Some(Nil)
      Cons(column, rest) =>
        match
          (
            @smith.class_coordinates(
              @smith.cokernel(target_homology.image_form),
              column,
            ),
            normalize(rest),
          ) {
          (Some(column), Some(rest)) => Some(Cons(column, rest))
          _ => None
        }
    }
  }
  match @matrix.multiply(cycle_map, source_left_inverse, integers()) {
    None => None
    Some(lift) =>
      match normalize(@matrix.rows(@matrix.transpose(lift))) {
        None => None
        Some(columns) =>
          match @matrix.matrix(@matrix.height(lift), columns) {
            None => None
            Some(rows) => Some(@matrix.transpose(rows))
          }
      }
  }
}

///|
test "S01 induced private context preserves old whole results and failures" {
  let source = generated([[0], [1], [2], [3]])
  let target = completed(source, 0)
  let cycle = imat([[3, -5], [-5, 8], [8, -9], [-7, 4]], 2)
  let inverse = imat([[1, 0], [-1, 1]], 2)
  assert_eq(
    canonical_columns(target, cycle, inverse),
    s01_legacy_canonical_columns(target, cycle, inverse),
  )
  let empty = imat([[], [], []], 0)
  let z = imat([], 0)
  let one = imat([[1]], 1)
  let bad = imat([[1], [2], [3]], 1)
  assert_eq(canonical_columns(target, empty, z), Some(empty))
  assert_eq(
    canonical_columns(target, empty, z),
    s01_legacy_canonical_columns(target, empty, z),
  )
  assert_eq(canonical_columns(target, z, one), None)
  assert_eq(canonical_columns(target, bad, one), None)
  assert_eq(
    canonical_columns(target, bad, one),
    s01_legacy_canonical_columns(target, bad, one),
  )
  let rp = completed(projective_plane(), 1)
  let torsion_cycle = imat(Array::makei(10, fn(i) { [i - 7, 3 - i] }), 2)
  assert_eq(
    canonical_columns(rp, torsion_cycle, inverse),
    s01_legacy_canonical_columns(rp, torsion_cycle, inverse),
  )
  let wide_zero = imat([], 2)
  let zero_target = completed(generated([]), 0)
  assert_eq(canonical_columns(zero_target, wide_zero, inverse), Some(wide_zero))
  assert_eq(
    canonical_columns(zero_target, wide_zero, inverse),
    s01_legacy_canonical_columns(zero_target, wide_zero, inverse),
  )
  assert_eq(canonical_columns(target, wide_zero, inverse), None)
  assert_eq(
    canonical_columns(target, wide_zero, inverse),
    s01_legacy_canonical_columns(target, wide_zero, inverse),
  )
}
