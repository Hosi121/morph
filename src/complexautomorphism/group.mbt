///|
/// Untrusted full splitting and substitution-table witness.
/// Images are interleaved (root,+i),(root,-i) in the supplied root order.
/// Entry table[left][right] means left after right.
#derive(Debug)
pub(all) struct Certificate {
  source : @cf.Field
  roots : @core.Chain[@cf.Element]
  images : @core.Chain[Image]
  table : @core.Chain[@core.Chain[@core.Nat]]
  identity : @core.Nat
  conjugation : @core.Nat
  inverses : @core.Chain[@core.Nat]
}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Group {
  priv proof : Certificate
  priv identity : Automorphism
  priv conjugation : Automorphism
}

///|
pub extend Group with Debug::{to_repr}

///|
pub fn source(group : Group) -> @cf.Field {
  group.proof.source
}

///|
pub fn roots(group : Group) -> @core.Chain[@cf.Element] {
  group.proof.roots
}

///|
pub fn order(group : Group) -> @core.Nat {
  @cf.degree(source(group))
}

///|
pub fn automorphisms(group : Group) -> @core.Chain[Automorphism] {
  @core.map(group.proof.images, fn(images) {
    Automorphism::{ field: source(group), images, }
  })
}

///|
pub fn identity(group : Group) -> Automorphism {
  group.identity
}

///|
pub fn conjugation(group : Group) -> Automorphism {
  group.conjugation
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
fn valid_roots(field : @cf.Field, values : @core.Chain[@cf.Element]) -> Bool {
  if !@core.length(values).equal(@nf.degree(@cf.real_field(field))) {
    return false
  }
  fn go(todo : @core.Chain[@cf.Element]) -> Bool {
    match todo {
      Nil => true
      Cons(root, rest) => {
        if !@cf.same_field(field, @cf.parent(root)) ||
          @core.any(rest, fn(other) { @cf.equal(root, other) }) {
          return false
        }
        match evaluate(root, @nf.modulus(@cf.real_field(field))) {
          Some(value) => @cf.is_zero(value) && go(rest)
          None => false
        }
      }
    }
  }
  go(values)
}

///|
fn expected_images(
  field : @cf.Field,
  values : @core.Chain[@cf.Element],
) -> @core.Chain[Image] {
  match values {
    Nil => Nil
    Cons(real, rest) => {
      let i = @cf.imaginary_unit(field)
      Cons(
        { real, imaginary: i, },
        Cons({ real, imaginary: @cf.negate(i), }, expected_images(field, rest)),
      )
    }
  }
}

///|
fn actual_table(
  field : @cf.Field,
  images : @core.Chain[Image],
) -> @core.Chain[@core.Chain[@core.Nat]]? {
  fn row(
    left : Image,
    right_images : @core.Chain[Image],
  ) -> @core.Chain[@core.Nat]? {
    match right_images {
      Nil => Some(Nil)
      Cons(right, rest) =>
        match compose_images(field, left, right) {
          Some(composed) =>
            match (image_index(images, composed, Zero), row(left, rest)) {
              (Some(index), Some(tail)) => Some(Cons(index, tail))
              _ => None
            }
          None => None
        }
    }
  }
  fn rows(
    left_images : @core.Chain[Image],
  ) -> @core.Chain[@core.Chain[@core.Nat]]? {
    match left_images {
      Nil => Some(Nil)
      Cons(left, rest) =>
        match (row(left, images), rows(rest)) {
          (Some(head), Some(tail)) => Some(Cons(head, tail))
          _ => None
        }
    }
  }
  rows(images)
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
  fn find(
    index : @core.Nat,
    candidates : @core.Chain[@core.Nat],
  ) -> @core.Nat? {
    match candidates {
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
          (Some(inverse), Some(tail)) => Some(Cons(inverse, tail))
          _ => None
        }
    }
  }
  go(indices)
}

///|
fn same_roots(
  a : @core.Chain[@cf.Element],
  b : @core.Chain[@cf.Element],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) => @cf.equal(x, y) && same_roots(xs, ys)
    _ => false
  }
}

///|
fn same_images(a : @core.Chain[Image], b : @core.Chain[Image]) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) => same_image(x, y) && same_images(xs, ys)
    _ => false
  }
}

///|
fn same_certificate(a : Certificate, b : Certificate) -> Bool {
  @cf.same_field(a.source, b.source) &&
  same_roots(a.roots, b.roots) &&
  same_images(a.images, b.images) &&
  a.table.equal(b.table) &&
  a.identity.equal(b.identity) &&
  a.conjugation.equal(b.conjugation) &&
  a.inverses.equal(b.inverses)
}

///|
/// Recheck all roots and generator images, then rederive every composition
/// by substitution. Merely satisfying abstract finite-group laws is insufficient.
pub fn check(field : @cf.Field, proof : Certificate) -> Bool {
  if !@cf.same_field(field, proof.source) ||
    !valid_roots(field, proof.roots) ||
    !same_images(proof.images, expected_images(field, proof.roots)) {
    return false
  }
  let alpha = match real_generator(field) {
    Some(value) => value
    None => return false
  }
  let i = @cf.imaginary_unit(field)
  match
    (
      image_index(proof.images, { real: alpha, imaginary: i, }, Zero),
      image_index(
        proof.images,
        { real: alpha, imaginary: @cf.negate(i), },
        Zero,
      ),
    ) {
    (Some(identity), Some(conjugation)) =>
      if !identity.equal(proof.identity) ||
        !conjugation.equal(proof.conjugation) {
        return false
      }
    _ => return false
  }
  match actual_table(field, proof.images) {
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
pub fn from_certificate(
  field : @cf.Field,
  proof : Certificate,
) -> Result[Group, AutomorphismError] {
  if !check(field, proof) {
    return Err(InvalidCertificate)
  }
  match
    (
      @core.nth(proof.images, proof.identity),
      @core.nth(proof.images, proof.conjugation),
    ) {
    (Some(identity), Some(conjugation)) =>
      Ok({
        proof,
        identity: { field, images: identity, },
        conjugation: { field, images: conjugation, },
      })
    _ => Err(InvalidCertificate)
  }
}

///|
/// Bind the actual private group payload and both returned special handles.
pub fn check_result(
  field : @cf.Field,
  group : Group,
  proof : Certificate,
) -> Bool {
  if !same_certificate(group.proof, proof) || !check(field, proof) {
    return false
  }
  match
    (
      @core.nth(proof.images, proof.identity),
      @core.nth(proof.images, proof.conjugation),
    ) {
    (Some(identity), Some(conjugation)) =>
      equal(group.identity, { field, images: identity, }) &&
      equal(group.conjugation, { field, images: conjugation, })
    _ => false
  }
}

///|
/// Conditional full automorphism enumeration of an explicitly split K(i).
/// Exactly d distinct roots of alpha's minimum must already belong to source.
pub fn prepare(
  field : @cf.Field,
  values : @core.Chain[@cf.Element],
) -> Result[Group, AutomorphismError] {
  if !valid_roots(field, values) {
    return Err(InvalidRoots)
  }
  let images = expected_images(field, values)
  let alpha = match real_generator(field) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let i = @cf.imaginary_unit(field)
  let identity = match
    image_index(images, { real: alpha, imaginary: i, }, Zero) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let conjugation = match
    image_index(images, { real: alpha, imaginary: @cf.negate(i), }, Zero) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let table = match actual_table(field, images) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let inverses = match actual_inverses(table, identity) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let proof : Certificate = {
    source: field,
    roots: values,
    images,
    table,
    identity,
    conjugation,
    inverses,
  }
  match from_certificate(field, proof) {
    Ok(group) => Ok(group)
    Err(_) => Err(InternalInvariant)
  }
}
