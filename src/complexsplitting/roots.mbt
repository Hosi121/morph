///|
#derive(Debug)
pub(all) struct Root {
  value : @cf.Element
  multiplicity : @core.Nat
}

///|
pub extend Root with Debug::{to_repr}

///|
#derive(Debug)
pub(all) struct RootImage {
  polynomial : @poly.Polynomial
  multiplicity : @core.Nat
  conversion : @sub.ConversionCertificate
}

///|
pub extend RootImage with Debug::{to_repr}

///|
fn polynomial_degree(source : @poly.Polynomial) -> @core.Nat? {
  match @poly.terms(source) {
    Cons({ exponents: Cons(degree, Nil), .. }, _) => Some(degree)
    _ => None
  }
}

///|
fn valid_source(source : @poly.Polynomial) -> Bool {
  @poly.variables(source).equal(Succ(Zero)) && !@poly.is_zero(source)
}

///|
fn root_values(values : @core.Chain[Root]) -> @core.Chain[@cf.Element] {
  @core.map(values, fn(root) { root.value })
}

///|
/// Check the exact first nonzero derivative, rather than only root membership.
fn exact_multiplicity(
  polynomial : @poly.Polynomial,
  value : @cf.Element,
  remaining : @core.Nat,
) -> Bool {
  let evaluated = match @cf.evaluate_polynomial(value, polynomial) {
    Some(result) => result
    None => return false
  }
  match remaining {
    Zero => !@cf.is_zero(evaluated)
    Succ(rest) =>
      @cf.is_zero(evaluated) &&
      (match @poly.derivative(polynomial, Zero) {
        Some(derivative) => exact_multiplicity(derivative, value, rest)
        None => false
      })
  }
}

///|
/// Distinct roots with exact positive multiplicities summing to degree are a
/// complete splitting. This binds the original polynomial including its scale.
fn valid_roots(
  source : @poly.Polynomial,
  ambient : @cf.Field,
  values : @core.Chain[Root],
) -> Bool {
  if !valid_source(source) {
    return false
  }
  let degree = match polynomial_degree(source) {
    Some(value) => value
    None => return false
  }
  let count = @core.fold_left(values, @core.Zero, fn(sum, root) {
    @core.add(sum, root.multiplicity)
  })
  if !count.equal(degree) {
    return false
  }
  fn go(todo : @core.Chain[Root]) -> Bool {
    match todo {
      Nil => true
      Cons(root, rest) =>
        !@core.is_zero(root.multiplicity) &&
        @cf.same_field(ambient, @cf.parent(root.value)) &&
        !@core.any(rest, fn(other) { @cf.equal(root.value, other.value) }) &&
        exact_multiplicity(source, root.value, root.multiplicity) &&
        go(rest)
    }
  }
  go(values)
}

///|
fn same_roots(a : @core.Chain[Root], b : @core.Chain[Root]) -> Bool {
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
fn check_images(
  representation : @sub.Representation,
  values : @core.Chain[Root],
  images : @core.Chain[RootImage],
) -> Bool {
  match (values, images) {
    (Nil, Nil) => true
    (Cons(root, rest), Cons(image, tail)) =>
      root.multiplicity.equal(image.multiplicity) &&
      @sub.check_conversion_for(
        representation,
        root.value,
        image.polynomial,
        image.conversion,
      ) &&
      check_images(representation, rest, tail)
    _ => false
  }
}

///|
fn make_images(
  representation : @sub.Representation,
  values : @core.Chain[Root],
) -> @core.Chain[RootImage]? {
  match values {
    Nil => Some(Nil)
    Cons(root, rest) =>
      match
        (
          @sub.to_polynomial(representation, root.value),
          make_images(representation, rest),
        ) {
        (Ok(converted), Some(tail)) =>
          Some(
            Cons(
              {
                polynomial: converted.polynomial,
                multiplicity: root.multiplicity,
                conversion: converted.certificate,
              },
              tail,
            ),
          )
        _ => None
      }
  }
}
