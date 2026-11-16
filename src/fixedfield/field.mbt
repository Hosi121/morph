///|
#derive(Eq, Debug)
pub(all) enum FixedError {
  InvalidGroup
  InvalidSubgroup
  InvalidCertificate
  DifferentField
  NotFixed
  DimensionMismatch
  InternalInvariant
}

///|
pub extend FixedError with Eq::{equal, not_equal}

///|
pub extend FixedError with Debug::{to_repr}

///|
/// Untrusted, source-bound proof of the complete invariant vector space.
/// Actions and constraints use the ambient basis [1,alpha,...,i,i*alpha,...].
#derive(Debug)
pub(all) struct Certificate {
  source : @cf.Field
  group : @aut.Certificate
  members : @core.Chain[@core.Nat]
  degree : @core.Nat
  basis : @core.Chain[@cf.Element]
  actions : @core.Chain[@matrix.Matrix[@exact.Rational]]
  constraints : @matrix.Matrix[@exact.Rational]
  rank : @core.Nat
}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// The checked field is represented inside its original ambient CF context.
#derive(Debug)
pub struct Field {
  priv group : @aut.Group
  priv proof : Certificate
}

///|
pub extend Field with Debug::{to_repr}

///|
pub fn group(field : Field) -> @aut.Group {
  field.group
}

///|
pub fn members(field : Field) -> @core.Chain[@core.Nat] {
  field.proof.members
}

///|
pub fn degree(field : Field) -> @core.Nat {
  field.proof.degree
}

///|
pub fn basis(field : Field) -> @core.Chain[@cf.Element] {
  field.proof.basis
}

///|
pub fn certificate(field : Field) -> Certificate {
  field.proof
}

///|
fn same_basis(
  a : @core.Chain[@cf.Element],
  b : @core.Chain[@cf.Element],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) => @cf.equal(x, y) && same_basis(xs, ys)
    _ => false
  }
}

///|
fn same_data(a : Certificate, b : Certificate) -> Bool {
  @cf.same_field(a.source, b.source) &&
  a.members.equal(b.members) &&
  a.degree.equal(b.degree) &&
  same_basis(a.basis, b.basis) &&
  a.actions.equal(b.actions) &&
  a.constraints.equal(b.constraints) &&
  a.rank.equal(b.rank)
}

///|
/// Recompute substitutions and ranks rather than trusting a producer's kernel.
/// Fixedness, independence and rank-nullity prove that no invariant is omitted.
pub fn check(group : @aut.Group, proof : Certificate) -> Bool {
  let source = @aut.source(group)
  if !@cf.same_field(source, proof.source) ||
    !@aut.check_result(source, group, proof.group) {
    return false
  }
  match normalize(group, proof.members) {
    Some(values) => if !values.equal(proof.members) { return false }
    None => return false
  }
  if !subgroup(group, proof.members) ||
    !@core.length(proof.basis).equal(proof.degree) ||
    !@core.multiply(proof.degree, @core.length(proof.members)).equal(
      @cf.degree(source),
    ) ||
    !@core.all(proof.basis, fn(value) {
      @cf.same_field(source, @cf.parent(value)) &&
      fixed_by(group, proof.members, value)
    }) {
    return false
  }
  let expected_actions = match actions(group, proof.members) {
    Some(value) => value
    None => return false
  }
  if !expected_actions.equal(proof.actions) {
    return false
  }
  match constraints(@cf.degree(source), expected_actions) {
    Some(expected) => if !expected.equal(proof.constraints) { return false }
    None => return false
  }
  match (@linear.rref(proof.constraints), basis_matrix(source, proof.basis)) {
    (Some(reduced), Some(columns)) => {
      let rank = @core.length(reduced.pivots)
      if !rank.equal(proof.rank) ||
        !@core.add(rank, proof.degree).equal(@cf.degree(source)) {
        return false
      }
      match @linear.rref(columns) {
        Some(independent) =>
          @core.length(independent.pivots).equal(proof.degree)
        None => false
      }
    }
    _ => false
  }
}

///|
pub fn from_certificate(
  group : @aut.Group,
  proof : Certificate,
) -> Result[Field, FixedError] {
  if check(group, proof) {
    Ok({ group, proof, })
  } else {
    Err(InvalidCertificate)
  }
}

///|
/// Bind both the caller's actual group and the returned field's entire payload.
pub fn check_result(
  group : @aut.Group,
  field : Field,
  proof : Certificate,
) -> Bool {
  same_data(field.proof, proof) &&
  @aut.check_result(@aut.source(group), field.group, proof.group) &&
  check(group, proof) &&
  check(group, field.proof)
}

///|
/// The supplied set is normalized, then validated as a subgroup without closure.
pub fn prepare(
  group : @aut.Group,
  members : @core.Chain[@core.Nat],
) -> Result[Field, FixedError] {
  let source = @aut.source(group)
  let group_proof = @aut.certificate(group)
  if !@aut.check_result(source, group, group_proof) {
    return Err(InvalidGroup)
  }
  let members = match normalize(group, members) {
    Some(values) => values
    None => return Err(InvalidSubgroup)
  }
  if !subgroup(group, members) {
    return Err(InvalidSubgroup)
  }
  let actions = match actions(group, members) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let constraints = match constraints(@cf.degree(source), actions) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let vectors = match
    @linear.solve(
      constraints,
      @core.replicate(@matrix.height(constraints), @exact.rational_zero()),
    ) {
    Some(@linear.Affine(_, values)) => values
    Some(@linear.Unique(_)) => Nil
    _ => return Err(InternalInvariant)
  }
  let basis = match elements(source, vectors) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let rank = match @linear.rref(constraints) {
    Some(value) => @core.length(value.pivots)
    None => return Err(InternalInvariant)
  }
  let proof : Certificate = {
    source,
    group: group_proof,
    members,
    degree: @core.length(basis),
    basis,
    actions,
    constraints,
    rank,
  }
  if check(group, proof) {
    Ok({ group, proof, })
  } else {
    Err(InternalInvariant)
  }
}
