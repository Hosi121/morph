///|
/// Complete exact automorphisms. table[left][right] means left after right.
#derive(Debug)
pub(all) struct Certificate {
  source : @split.Certificate
  maps : @core.Chain[MapCertificate]
  table : @core.Chain[@core.Chain[@core.Nat]]
  identity : @core.Nat
  inverses : @core.Chain[@core.Nat]
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Group {
  priv source : @split.Splitting
  priv proof : Certificate
  priv identity : Automorphism
}

///|
pub extend Group with Debug::{to_repr}

///|
pub fn source(group : Group) -> @split.Splitting {
  group.source
}

///|
pub fn order(group : Group) -> @core.Nat {
  @split.degree(group.source)
}

///|
pub fn automorphisms(group : Group) -> @core.Chain[Automorphism] {
  @core.map(group.proof.maps, fn(map) { { source: group.source, map, } })
}

///|
pub fn identity(group : Group) -> Automorphism {
  group.identity
}

///|
pub fn composition_table(group : Group) -> @core.Chain[@core.Chain[@core.Nat]] {
  group.proof.table
}

///|
pub fn certificate(group : Group) -> Certificate {
  group.proof
}

///|
fn valid_permutation(
  roots : @core.Chain[@split.Root],
  permutation : @core.Chain[@core.Nat],
) -> Bool {
  fn go(
    todo : @core.Chain[@split.Root],
    indices : @core.Chain[@core.Nat],
  ) -> Bool {
    match (todo, indices) {
      (Nil, Nil) => true
      (Cons(root, rest), Cons(index, tail)) =>
        if @core.any(tail, fn(other) { index.equal(other) }) {
          false
        } else {
          match @core.nth(roots, index) {
            Some(target) =>
              root.multiplicity.equal(target.multiplicity) && go(rest, tail)
            None => false
          }
        }
      _ => false
    }
  }
  go(roots, permutation)
}

///|
fn valid_map(source : @split.Splitting, map : MapCertificate) -> Bool {
  if !valid_permutation(@split.roots(source), map.permutation) ||
    !@cf.same_field(@split.ambient(source), @cf.parent(map.image)) ||
    !@sub.contains(@split.generated_field(source), map.image) {
    return false
  }
  match @cf.evaluate_polynomial(map.image, @split.modulus(source)) {
    Some(value) => if !@cf.is_zero(value) { return false }
    None => return false
  }
  fn action(
    polynomials : @core.Chain[@split.RootImage],
    indices : @core.Chain[@core.Nat],
  ) -> Bool {
    match (polynomials, indices) {
      (Nil, Nil) => true
      (Cons(root, rest), Cons(index, tail)) =>
        match
          (
            @cf.evaluate_polynomial(map.image, root.polynomial),
            @core.nth(@split.roots(source), index),
          ) {
          (Some(image), Some(target)) =>
            @cf.equal(image, target.value) && action(rest, tail)
          _ => false
        }
      _ => false
    }
  }
  action(@split.root_images(source), map.permutation)
}

///|
fn valid_maps(
  source : @split.Splitting,
  maps : @core.Chain[MapCertificate],
) -> Bool {
  match maps {
    Nil => true
    Cons(map, rest) =>
      valid_map(source, map) &&
      !@core.any(rest, fn(other) { @cf.equal(map.image, other.image) }) &&
      valid_maps(source, rest)
  }
}

///|
/// Convert each right image once; every table cell then performs actual field
/// substitution as well as composing its independently stated root action.
fn actual_table(
  source : @split.Splitting,
  maps : @core.Chain[MapCertificate],
) -> @core.Chain[@core.Chain[@core.Nat]]? {
  fn conversions(
    todo : @core.Chain[MapCertificate],
  ) -> @core.Chain[(MapCertificate, @poly.Polynomial)]? {
    match todo {
      Nil => Some(Nil)
      Cons(map, rest) =>
        match
          (
            @sub.to_polynomial(@split.representation(source), map.image),
            conversions(rest),
          ) {
          (Ok(value), Some(tail)) => Some(Cons((map, value.polynomial), tail))
          _ => None
        }
    }
  }
  let rights = match conversions(maps) {
    Some(value) => value
    None => return None
  }
  fn row(
    left : MapCertificate,
    todo : @core.Chain[(MapCertificate, @poly.Polynomial)],
  ) -> @core.Chain[@core.Nat]? {
    match todo {
      Nil => Some(Nil)
      Cons((right, polynomial), rest) =>
        match
          (
            @cf.evaluate_polynomial(left.image, polynomial),
            compose_permutations(left.permutation, right.permutation),
            row(left, rest),
          ) {
          (Some(image), Some(permutation), Some(tail)) =>
            match map_index(maps, { permutation, image, }, Zero) {
              Some(index) => Some(Cons(index, tail))
              None => None
            }
          _ => None
        }
    }
  }
  fn rows(
    todo : @core.Chain[MapCertificate],
  ) -> @core.Chain[@core.Chain[@core.Nat]]? {
    match todo {
      Nil => Some(Nil)
      Cons(left, rest) =>
        match (row(left, rights), rows(rest)) {
          (Some(head), Some(tail)) => Some(Cons(head, tail))
          _ => None
        }
    }
  }
  rows(maps)
}

///|
fn entry(
  table : @core.Chain[@core.Chain[@core.Nat]],
  left : @core.Nat,
  right : @core.Nat,
) -> @core.Nat? {
  match @core.nth(table, left) {
    Some(row) => @core.nth(row, right)
    None => None
  }
}

///|
fn actual_inverses(
  table : @core.Chain[@core.Chain[@core.Nat]],
  identity : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  let indices = @core.indices(@core.length(table))
  fn find(index : @core.Nat, todo : @core.Chain[@core.Nat]) -> @core.Nat? {
    match todo {
      Nil => None
      Cons(candidate, rest) =>
        if entry(table, index, candidate).equal(Some(identity)) &&
          entry(table, candidate, index).equal(Some(identity)) {
          Some(candidate)
        } else {
          find(index, rest)
        }
    }
  }
  fn go(todo : @core.Chain[@core.Nat]) -> @core.Chain[@core.Nat]? {
    match todo {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match (find(index, indices), go(rest)) {
          (Some(head), Some(tail)) => Some(Cons(head, tail))
          _ => None
        }
    }
  }
  go(indices)
}

///|
fn identity_map(source : @split.Splitting) -> MapCertificate {
  {
    permutation: @core.indices(@core.length(@split.roots(source))),
    image: @sub.primitive_element(@split.representation(source)),
  }
}

///|
/// A checked minimal splitting field in characteristic zero has precisely r
/// embeddings, where r is its degree. Hence r distinct sound maps prove full
/// completeness without an exponential rejected-permutation transcript.
pub fn check(source : @split.Splitting, proof : Certificate) -> Bool {
  if !@split.check_result(
      @split.source(source),
      @split.ambient(source),
      source,
      proof.source,
    ) ||
    !@core.length(proof.maps).equal(@split.degree(source)) ||
    !valid_maps(source, proof.maps) ||
    !map_index(proof.maps, identity_map(source), Zero).equal(
      Some(proof.identity),
    ) {
    return false
  }
  match actual_table(source, proof.maps) {
    Some(table) => {
      if !table.equal(proof.table) {
        return false
      }
      match actual_inverses(table, proof.identity) {
        Some(inverses) => inverses.equal(proof.inverses)
        None => false
      }
    }
    None => false
  }
}

///|
fn same_maps(
  a : @core.Chain[MapCertificate],
  b : @core.Chain[MapCertificate],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) => same_map(x, y) && same_maps(xs, ys)
    _ => false
  }
}

///|
pub fn check_result(
  source : @split.Splitting,
  result : Group,
  proof : Certificate,
) -> Bool {
  check(source, proof) &&
  @split.check_result(
    @split.source(source),
    @split.ambient(source),
    result.source,
    proof.source,
  ) &&
  @split.check_result(
    @split.source(source),
    @split.ambient(source),
    result.source,
    result.proof.source,
  ) &&
  same_maps(result.proof.maps, proof.maps) &&
  result.proof.table.equal(proof.table) &&
  result.proof.identity.equal(proof.identity) &&
  result.proof.inverses.equal(proof.inverses) &&
  same_context(source, result.identity.source) &&
  same_map(identity_map(source), result.identity.map)
}

///|
pub fn from_certificate(
  source : @split.Splitting,
  proof : Certificate,
) -> Result[Group, GaloisError] {
  if !check(source, proof) {
    return Err(InvalidCertificate)
  }
  Ok({ source, proof, identity: { source, map: identity_map(source), }, })
}

///|
fn finish(
  source : @split.Splitting,
  maps : @core.Chain[MapCertificate],
) -> Result[Progress, GaloisError] {
  let identity = match map_index(maps, identity_map(source), Zero) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let table = match actual_table(source, maps) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let inverses = match actual_inverses(table, identity) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let proof : Certificate = {
    source: @split.certificate(source),
    maps,
    table,
    identity,
    inverses,
  }
  // Source was checked at start; each accepted map was checked at its trial.
  // Rechecking this public witness remains independently available via check.
  Ok(
    Ready(
      { source, proof, identity: { source, map: identity_map(source), }, },
      proof,
    ),
  )
}
