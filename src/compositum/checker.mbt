///|
fn comparison_binds(
  proof : @real.ComparisonCertificate,
  left : @real.RootCertificate,
  right : @real.RootCertificate,
) -> Bool {
  proof.left.equal(left) &&
  proof.right.equal(right) &&
  @real.check_comparison(proof)
}

///|
fn selection_valid(
  points : @core.Chain[@variety.ProjectedPoint],
  rows : @core.Chain[SelectionRow],
  proof : Certificate,
) -> Bool {
  match (points, rows) {
    (Nil, Nil) => true
    (Cons(point, rest), Cons(row, tail)) => {
      let expected = @variety.PointCertificate::{
        shape: proof.separation.solutions.shape,
        parameter: @real.root_certificate(@variety.projected_parameter(point)),
      }
      row.left.point.equal(expected) &&
      row.right.point.equal(expected) &&
      row.left.index.equal(Zero) &&
      row.right.index.equal(Succ(Zero)) &&
      @variety.check_coordinate(row.left) &&
      @variety.check_coordinate(row.right) &&
      comparison_binds(row.left_comparison, row.left.result, proof.left) &&
      comparison_binds(row.right_comparison, row.right.result, proof.right) &&
      selection_valid(rest, tail, proof)
    }
    _ => false
  }
}

///|
fn primitive_relation(
  field : @nf.Field,
  x : @nf.Element,
  y : @nf.Element,
  seed : @binary.Binary,
) -> Bool {
  let scalar = @nf.rational(field, @exact.whole(@exact.positive(seed)))
  match @nf.multiply(scalar, y) {
    Err(_) => false
    Ok(product) =>
      match (@nf.add(x, product), @nf.generator(field)) {
        (Ok(sum), Ok(generator)) => @nf.equal(sum, generator)
        _ => false
      }
  }
}

///|
/// Reconstruct the original Cartesian Problem from the externally supplied
/// Numbers. Verify full separated coverage, every conjugate comparison, unique
/// selection, Proven minimal factor, quotient maps, primitive relation, and
/// both real embeddings. No producer search or coordinate interpolation reruns.
pub fn check(
  left : @real.Number,
  right : @real.Number,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  if !proof.left.equal(@real.root_certificate(left)) ||
    !proof.right.equal(@real.root_certificate(right)) {
    return @zass.Refuted
  }
  let field = match @nf.field(proof.minimal, verification_fuel) {
    Ok(field) => field
    Err(@nf.VerificationBudget) => return @zass.Undecided
    Err(_) => return @zass.Refuted
  }
  let problem = match source_problem(left, right) {
    Ok(problem) => problem
    Err(_) => return @zass.Refuted
  }
  let separated = match
    @variety.separation_from_certificate(problem, proof.separation) {
    Ok(separated) => separated
    Err(_) => return @zass.Refuted
  }
  let points = match @variety.projected_points(separated) {
    Ok(points) => points
    Err(_) => return @zass.Refuted
  }
  if !selection_valid(points, proof.selection, proof) {
    return @zass.Refuted
  }
  match unique_index(proof.selection) {
    Some(index) => if !index.equal(proof.selected) { return @zass.Refuted }
    None => return @zass.Refuted
  }
  let point = match @core.nth(points, proof.selected) {
    Some(point) => point
    None => return @zass.Refuted
  }
  if !proof.minimal.input.equal(
      @real.root_certificate(@variety.projected_parameter(point)),
    ) {
    return @zass.Refuted
  }
  let (x, y) = match @variety.projected_coordinate_expressions(point) {
    Cons(x, Cons(y, Nil)) =>
      match (@nf.element(field, x), @nf.element(field, y)) {
        (Ok(x), Ok(y)) => (x, y)
        _ => return @zass.Refuted
      }
    _ => return @zass.Refuted
  }
  if !primitive_relation(field, x, y, proof.separation.augmentation.seed) ||
    !@nf.check_realization(x, proof.left_embedding) ||
    !@nf.check_realization(y, proof.right_embedding) ||
    !comparison_binds(
      proof.left_equality,
      proof.left_embedding.result,
      proof.left,
    ) ||
    !comparison_binds(
      proof.right_equality,
      proof.right_embedding.result,
      proof.right,
    ) ||
    !proof.left_equality.order.equal(Equal) ||
    !proof.right_equality.order.equal(Equal) {
    @zass.Refuted
  } else {
    @zass.Proven
  }
}

///|
/// Authenticate the separately returned Common payload, including the exact
/// minimal certificate, both parent contexts, and both canonical residues.
pub fn check_result(
  left : @real.Number,
  right : @real.Number,
  value : Common,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  if !@nf.certificate(value.field).equal(proof.minimal) ||
    !@nf.same_field(@nf.parent(value.left), value.field) ||
    !@nf.same_field(@nf.parent(value.right), value.field) ||
    !@nf.representative(value.left).equal(proof.left_embedding.input) ||
    !@nf.representative(value.right).equal(proof.right_embedding.input) {
    @zass.Refuted
  } else {
    check(left, right, proof, verification_fuel)
  }
}
