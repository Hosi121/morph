///|
/// Recheck source scaling, the selected real cube root, the actual real
/// compositum, all three formulas, exact vanishing and pairwise distinctness.
/// Irreducibility budget exhaustion remains Undecided.
pub fn check(
  source : @poly.Polynomial,
  proof : Certificate,
  fuel : @core.Nat,
) -> @zass.Verdict {
  let (scale, radicand) = match source_data(source) {
    Some(data) => data
    None => return @zass.Refuted
  }
  if !proof.source.equal(source) ||
    !proof.scale.equal(scale) ||
    !proof.radicand.equal(radicand) ||
    !proof.cube_root.polynomial.equal(@poly.monic(source)) {
    return @zass.Refuted
  }
  let alpha = match @real.number(proof.cube_root) {
    Ok(alpha) => alpha
    Err(_) => return @zass.Refuted
  }
  if !@real.root_certificate(alpha).equal(proof.cube_root) {
    return @zass.Refuted
  }
  let beta = match sqrt_three() {
    Ok(beta) => beta
    Err(_) => return @zass.Refuted
  }
  match @comp.check_result(alpha, beta, proof.common, proof.composition, fuel) {
    @zass.Proven => ()
    verdict => return verdict
  }
  let (field, values) = match formula_roots(proof.common) {
    Ok(result) => result
    Err(_) => return @zass.Refuted
  }
  if !@nf.certificate(@cf.real_field(field)).equal(
      @nf.certificate(@cf.real_field(proof.field)),
    ) ||
    !same_roots(values, proof.roots) ||
    !actual_roots(source, proof.roots) {
    @zass.Refuted
  } else {
    @zass.Proven
  }
}

///|
pub fn check_result(
  source : @poly.Polynomial,
  value : Common,
  proof : Certificate,
  fuel : @core.Nat,
) -> @zass.Verdict {
  if !@nf.certificate(@cf.real_field(value.field)).equal(
      @nf.certificate(@cf.real_field(proof.field)),
    ) ||
    !same_roots(value.values, proof.roots) {
    @zass.Refuted
  } else {
    check(source, proof, fuel)
  }
}
