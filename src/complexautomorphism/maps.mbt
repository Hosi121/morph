///|
#derive(Eq, Debug)
pub(all) enum AutomorphismError {
  InvalidRoots
  DifferentField
  InvalidCertificate
  NotMember
  InternalInvariant
}

///|
pub extend AutomorphismError with Eq::{equal, not_equal}

///|
pub extend AutomorphismError with Debug::{to_repr}

///|
/// Public untrusted images of alpha and i, respectively.
#derive(Debug)
pub(all) struct Image {
  real : @cf.Element
  imaginary : @cf.Element
}

///|
pub extend Image with Debug::{to_repr}

///|
/// A checked Q-automorphism of a particular source K(i).
#derive(Debug)
pub struct Automorphism {
  priv field : @cf.Field
  priv images : Image
}

///|
pub extend Automorphism with Debug::{to_repr}

///|
pub fn real_image(value : Automorphism) -> @cf.Element {
  value.images.real
}

///|
pub fn imaginary_image(value : Automorphism) -> @cf.Element {
  value.images.imaginary
}

///|
fn valid_context(value : Automorphism) -> Bool {
  @cf.same_field(value.field, @cf.parent(value.images.real)) &&
  @cf.same_field(value.field, @cf.parent(value.images.imaginary))
}

///|
fn same_image(a : Image, b : Image) -> Bool {
  @cf.equal(a.real, b.real) && @cf.equal(a.imaginary, b.imaginary)
}

///|
pub fn equal(a : Automorphism, b : Automorphism) -> Bool {
  valid_context(a) &&
  valid_context(b) &&
  @cf.same_field(a.field, b.field) &&
  same_image(a.images, b.images)
}

///|
fn coefficient(
  polynomial : @poly.Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(@poly.terms(polynomial), @exact.rational_zero(), fn(
    sum,
    term,
  ) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      @exact.rational_add(sum, term.coefficient)
    } else {
      sum
    }
  })
}

///|
/// Evaluate an existing rational polynomial by exact source-field arithmetic.
fn evaluate(value : @cf.Element, polynomial : @poly.Polynomial) -> @cf.Element? {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  let count : @core.Nat = match @poly.terms(polynomial) {
    Nil => Zero
    Cons({ exponents: Cons(d, Nil), .. }, _) => Succ(d)
    _ => return None
  }
  fn go(
    todo : @core.Chain[@core.Nat],
    accumulated : @cf.Element,
  ) -> @cf.Element? {
    match todo {
      Nil => Some(accumulated)
      Cons(i, rest) =>
        match @cf.multiply(accumulated, value) {
          Ok(product) =>
            match
              @cf.add(
                product,
                @cf.rational(@cf.parent(value), coefficient(polynomial, i)),
              ) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
          Err(_) => None
        }
    }
  }
  go(@core.reverse(@core.indices(count)), @cf.zero(@cf.parent(value)))
}

///|
fn real_generator(field : @cf.Field) -> @cf.Element? {
  let real = @cf.real_field(field)
  match @nf.generator(real) {
    Ok(alpha) =>
      match @cf.element(field, alpha, @nf.zero(real)) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    Err(_) => None
  }
}

///|
/// Send a(alpha)+i*b(alpha) to a(image(alpha))+image(i)*b(image(alpha)).
pub fn apply(
  automorphism : Automorphism,
  value : @cf.Element,
) -> Result[@cf.Element, AutomorphismError] {
  if !valid_context(automorphism) ||
    !@cf.same_field(automorphism.field, @cf.parent(value)) {
    return Err(DifferentField)
  }
  match
    (
      evaluate(
        real_image(automorphism),
        @nf.representative(@cf.real_part(value)),
      ),
      evaluate(
        real_image(automorphism),
        @nf.representative(@cf.imaginary_part(value)),
      ),
    ) {
    (Some(real), Some(imaginary)) =>
      match @cf.multiply(imaginary_image(automorphism), imaginary) {
        Ok(product) =>
          match @cf.add(real, product) {
            Ok(result) => Ok(result)
            Err(_) => Err(InternalInvariant)
          }
        Err(_) => Err(InternalInvariant)
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn image_index(
  images : @core.Chain[Image],
  target : Image,
  index : @core.Nat,
) -> @core.Nat? {
  match images {
    Nil => None
    Cons(image, rest) =>
      if same_image(image, target) {
        Some(index)
      } else {
        image_index(rest, target, Succ(index))
      }
  }
}

///|
/// left after right: substitution determines both images, not an abstract table.
fn compose_images(field : @cf.Field, left : Image, right : Image) -> Image? {
  let automorphism : Automorphism = { field, images: left, }
  match
    (apply(automorphism, right.real), apply(automorphism, right.imaginary)) {
    (Ok(real), Ok(imaginary)) => Some({ real, imaginary, })
    _ => None
  }
}

///|
fn member_index(group : Group, value : Automorphism) -> @core.Nat? {
  if !valid_context(value) || !@cf.same_field(source(group), value.field) {
    None
  } else {
    image_index(group.proof.images, value.images, Zero)
  }
}

///|
pub fn compose(
  group : Group,
  left : Automorphism,
  right : Automorphism,
) -> Result[Automorphism, AutomorphismError] {
  if !@cf.same_field(source(group), left.field) ||
    !@cf.same_field(source(group), right.field) {
    return Err(DifferentField)
  }
  match (member_index(group, left), member_index(group, right)) {
    (Some(_), Some(_)) =>
      match compose_images(source(group), left.images, right.images) {
        Some(images) =>
          match image_index(group.proof.images, images, Zero) {
            Some(_) => Ok({ field: source(group), images, })
            None => Err(InternalInvariant)
          }
        None => Err(InternalInvariant)
      }
    _ => Err(NotMember)
  }
}

///|
pub fn inverse(
  group : Group,
  value : Automorphism,
) -> Result[Automorphism, AutomorphismError] {
  if !@cf.same_field(source(group), value.field) {
    return Err(DifferentField)
  }
  match member_index(group, value) {
    Some(index) =>
      match @core.nth(group.proof.inverses, index) {
        Some(inverse_index) =>
          match @core.nth(group.proof.images, inverse_index) {
            Some(images) => Ok({ field: source(group), images, })
            None => Err(InternalInvariant)
          }
        None => Err(InternalInvariant)
      }
    None => Err(NotMember)
  }
}
