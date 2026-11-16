///|
#derive(Eq, Debug)
pub(all) enum GaloisError {
  InvalidSource
  InvalidCertificate
  DifferentField
  NotInField
  NotMember
  InternalInvariant
}

///|
pub extend GaloisError with Eq::{equal, not_equal}

///|
pub extend GaloisError with Debug::{to_repr}

///|
/// Untrusted root permutation and image of the source primitive element.
#derive(Debug)
pub(all) struct MapCertificate {
  permutation : @core.Chain[@core.Nat]
  image : @cf.Element
}

///|
pub extend MapCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Automorphism {
  priv source : @split.Splitting
  priv map : MapCertificate
}

///|
pub extend Automorphism with Debug::{to_repr}

///|
pub fn permutation(value : Automorphism) -> @core.Chain[@core.Nat] {
  value.map.permutation
}

///|
pub fn generator_image(value : Automorphism) -> @cf.Element {
  value.map.image
}

///|
fn same_map(a : MapCertificate, b : MapCertificate) -> Bool {
  a.permutation.equal(b.permutation) && @cf.equal(a.image, b.image)
}

///|
fn same_roots(
  a : @core.Chain[@split.Root],
  b : @core.Chain[@split.Root],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) =>
      @cf.equal(x.value, y.value) &&
      x.multiplicity.equal(y.multiplicity) &&
      same_roots(xs, ys)
    _ => false
  }
}

///|
/// Compare the actual primitive coordinates and generating roots, rather than
/// ambient field alone: distinct minimal subfields can share one ambient field.
fn same_context(a : @split.Splitting, b : @split.Splitting) -> Bool {
  let ap = @split.certificate(a)
  let bp = @split.certificate(b)
  ap.source.equal(bp.source) &&
  @cf.same_field(ap.ambient, bp.ambient) &&
  same_roots(ap.roots, bp.roots) &&
  @split.degree(a).equal(@split.degree(b)) &&
  @split.modulus(a).equal(@split.modulus(b)) &&
  @cf.equal(
    @sub.primitive_element(@split.representation(a)),
    @sub.primitive_element(@split.representation(b)),
  ) &&
  ap.primitive.candidate.equal(bp.primitive.candidate) &&
  ap.primitive.power_basis.equal(bp.primitive.power_basis) &&
  ap.generated.monomials.equal(bp.generated.monomials)
}

///|
pub fn equal(a : Automorphism, b : Automorphism) -> Bool {
  same_context(a.source, b.source) && same_map(a.map, b.map)
}

///|
fn apply_image(
  source : @split.Splitting,
  image : @cf.Element,
  value : @cf.Element,
) -> Result[@cf.Element, GaloisError] {
  if !@cf.same_field(@split.ambient(source), @cf.parent(value)) ||
    !@cf.same_field(@split.ambient(source), @cf.parent(image)) {
    return Err(DifferentField)
  }
  match @sub.to_polynomial(@split.representation(source), value) {
    Ok(conversion) =>
      match @cf.evaluate_polynomial(image, conversion.polynomial) {
        Some(result) => Ok(result)
        None => Err(InternalInvariant)
      }
    Err(@sub.NotInSubfield) => Err(NotInField)
    Err(_) => Err(InternalInvariant)
  }
}

///|
/// The domain is the minimal generated splitting field, not all ambient values.
pub fn apply(
  automorphism : Automorphism,
  value : @cf.Element,
) -> Result[@cf.Element, GaloisError] {
  apply_image(automorphism.source, automorphism.map.image, value)
}

///|
fn map_index(
  maps : @core.Chain[MapCertificate],
  target : MapCertificate,
  index : @core.Nat,
) -> @core.Nat? {
  match maps {
    Nil => None
    Cons(map, rest) =>
      if same_map(map, target) {
        Some(index)
      } else {
        map_index(rest, target, Succ(index))
      }
  }
}

///|
fn member_index(group : Group, value : Automorphism) -> @core.Nat? {
  if same_context(group.source, value.source) {
    map_index(group.proof.maps, value.map, Zero)
  } else {
    None
  }
}

///|
fn compose_permutations(
  left : @core.Chain[@core.Nat],
  right : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match right {
    Nil => Some(Nil)
    Cons(index, rest) =>
      match (@core.nth(left, index), compose_permutations(left, rest)) {
        (Some(head), Some(tail)) => Some(Cons(head, tail))
        _ => None
      }
  }
}

///|
/// left after right; substitution computes the primitive image independently
/// of the finite group table, and the root action must agree as well.
pub fn compose(
  group : Group,
  left : Automorphism,
  right : Automorphism,
) -> Result[Automorphism, GaloisError] {
  match (member_index(group, left), member_index(group, right)) {
    (Some(_), Some(_)) =>
      match
        (
          apply(left, right.map.image),
          compose_permutations(left.map.permutation, right.map.permutation),
        ) {
        (Ok(image), Some(permutation)) => {
          let map : MapCertificate = { permutation, image, }
          match map_index(group.proof.maps, map, Zero) {
            Some(_) => Ok({ source: group.source, map, })
            None => Err(InternalInvariant)
          }
        }
        _ => Err(InternalInvariant)
      }
    _ => Err(NotMember)
  }
}

///|
pub fn inverse(
  group : Group,
  value : Automorphism,
) -> Result[Automorphism, GaloisError] {
  match member_index(group, value) {
    Some(index) =>
      match @core.nth(group.proof.inverses, index) {
        Some(inverse) =>
          match @core.nth(group.proof.maps, inverse) {
            Some(map) => Ok({ source: group.source, map, })
            None => Err(InternalInvariant)
          }
        None => Err(InternalInvariant)
      }
    None => Err(NotMember)
  }
}
