///|
// Frozen pre-sharing helper, retained as an exact result/None oracle.
fn s01_legacy_canonical_columns(
  target_image : @smith.Decomposition,
  cycle_map : @matrix.Matrix[@exact.Integer],
  source_left_inverse : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn normalize(
    form : @smith.Decomposition,
    columns : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match columns {
      Nil => Some(Nil)
      Cons(column, rest) =>
        match
          (
            @smith.class_coordinates(@smith.cokernel(form), column),
            normalize(form, rest),
          ) {
          (Some(column), Some(rest)) => Some(Cons(column, rest))
          _ => None
        }
    }
  }
  match @matrix.multiply(cycle_map, source_left_inverse, integers()) {
    None => None
    Some(lift) =>
      match normalize(target_image, @matrix.rows(@matrix.transpose(lift))) {
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
test "S01 context sharing retains exact columns, bases, empty and None" {
  let d = matrix([[1, 0, 0, 0], [0, 2, 0, 0], [0, 0, 6, 0], [0, 0, 0, 0]], 4)
  let id = matrix([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]], 4)
  let form = @smith.check(d, id, d, id).unwrap()
  let inverse = matrix([[1, 0], [-1, 1]], 2)
  let cycle = matrix([[3, -5], [-5, 8], [8, -9], [-7, 4]], 2)
  assert_eq(
    canonical_columns(form, cycle, inverse),
    s01_legacy_canonical_columns(form, cycle, inverse),
  )
  assert_eq(
    canonical_columns(form, cycle, inverse),
    Some(matrix([[0, 0], [1, 0], [5, 3], [-11, 4]], 2)),
  )
  let empty = matrix([[], [], []], 0)
  let z = matrix([], 0)
  let one = matrix([[1]], 1)
  let bad = matrix([[1], [2], [3]], 1)
  assert_eq(canonical_columns(form, empty, z), Some(empty))
  assert_eq(
    canonical_columns(form, empty, z),
    s01_legacy_canonical_columns(form, empty, z),
  )
  assert_eq(canonical_columns(form, z, one), None)
  assert_eq(canonical_columns(form, bad, one), None)
  assert_eq(
    canonical_columns(form, bad, one),
    s01_legacy_canonical_columns(form, bad, one),
  )
  let wide_zero = matrix([], 2)
  let zero_form = @smith.check(z, z, z, z).unwrap()
  assert_eq(canonical_columns(zero_form, wide_zero, inverse), Some(wide_zero))
  assert_eq(
    canonical_columns(zero_form, wide_zero, inverse),
    s01_legacy_canonical_columns(zero_form, wide_zero, inverse),
  )
  assert_eq(canonical_columns(form, wide_zero, inverse), None)
  assert_eq(
    canonical_columns(form, wide_zero, inverse),
    s01_legacy_canonical_columns(form, wide_zero, inverse),
  )
}
