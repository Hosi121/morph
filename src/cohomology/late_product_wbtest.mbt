///|
/// Compute ker(delta_k)/im(delta_(k-1)), preserving explicit representatives.
fn late_product_legacy_compute(
  source : @homology.Complex,
  degree : @core.Nat,
) -> Cohomology? {
  let (delta, previous) = match
    (coboundary(source, degree), incoming(source, degree)) {
    (Some(a), Some(b)) => (a, b)
    _ => return None
  }
  let (outgoing_factor, incoming_factor) = match
    (@gf2.factor(delta), @gf2.factor(previous)) {
    (Some(a), Some(b)) => (a, b)
    _ => return None
  }
  let (outgoing_rank, incoming_rank) = match
    (factor_witness(outgoing_factor), factor_witness(incoming_factor)) {
    (Some(a), Some(b)) => (a, b)
    _ => return None
  }
  // Reuse the actual reduction for the nullspace, without another elimination.
  let kernel = @gf2.nullspace_factor(outgoing_factor)
  let boundaries = match select_columns(previous, incoming_rank.pivots) {
    Some(value) => value
    None => return None
  }
  let n = @matrix.width(delta)
  let candidates = match @matrix.matrix(n, @core.append(boundaries, kernel)) {
    Some(value) => @matrix.transpose(value)
    None => return None
  }
  let cycle_rank = match @gf2.rref(candidates) {
    Some(value) => value
    None => return None
  }
  let cycles = match select_columns(candidates, cycle_rank.pivots) {
    Some(value) => value
    None => return None
  }
  let complement = match
    select_columns(
      @matrix.identity(n, @csscode.scalars()),
      outgoing_rank.pivots,
    ) {
    Some(value) => value
    None => return None
  }
  let basis = match @matrix.matrix(n, @core.append(cycles, complement)) {
    Some(value) => @matrix.transpose(value)
    None => return None
  }
  let inverse_basis = match @gf2.inverse(basis) {
    Some(value) => value
    None => return None
  }
  let incoming_coordinates = match
    @matrix.multiply(inverse_basis, previous, @csscode.scalars()) {
    Some(value) => value
    None => return None
  }
  let representatives = @core.drop(@core.length(boundaries), cycles)
  let result = Group::{
    rank: @core.length(representatives),
    coboundaries: boundaries,
    representatives,
  }
  let witness = Certificate::{
    source,
    degree,
    result,
    outgoing_rank,
    incoming_rank,
    basis,
    inverse_basis,
    incoming_coordinates,
  }
  // Keep the original generic matrix checker as an independent trust boundary.
  validate_certificate(source, degree, result, witness)
}

///|
test "late specialized incoming coordinates preserve full old generic cohomology certificates" {
  let fixtures = [
    [],
    [[0]],
    [[0, 1], [0, 2], [1, 2]],
    [[0, 1, 2]],
    [[0, 1, 2, 3]],
    [
      [0, 1, 2],
      [1, 2, 4],
      [1, 3, 4],
      [1, 3, 6],
      [0, 1, 5],
      [1, 5, 6],
      [2, 3, 5],
      [2, 4, 5],
      [2, 3, 6],
      [0, 2, 6],
      [0, 3, 4],
      [0, 3, 5],
      [4, 5, 6],
      [0, 4, 6],
    ],
  ]
  for facets in fixtures {
    let source = @homology.closure(
      @oracle.chain(
        facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) }),
      ),
    ).unwrap()
    for degree in 0..<=3 {
      let degree = @oracle.nat(degree)
      assert_eq(
        compute(source, degree),
        late_product_legacy_compute(source, degree),
      )
      match compute(source, degree) {
        None => abort("small valid cohomology must compute")
        Some(space) =>
          assert_true(
            check_result(source, degree, result(space), certificate(space)),
          )
      }
    }
  }
}
