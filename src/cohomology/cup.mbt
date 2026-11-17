///|
fn evaluate(
  simplices : @core.Chain[@core.Chain[@core.Nat]],
  cochain : @core.Chain[Bool],
  face : @core.Chain[@core.Nat],
) -> Bool {
  match (simplices, cochain) {
    (Cons(simplex, rest), Cons(value, tail)) =>
      match simplex.equal(face) {
        true => value
        false => evaluate(rest, tail, face)
      }
    _ => false
  }
}

///|
/// Alexander-Whitney cup on the global increasing vertex order. The front
/// p-face and back q-face overlap in exactly one vertex. This operation is
/// associative on cochains, but commutes only after passing to cohomology.
pub fn cup(
  source : @homology.Complex,
  left_degree : @core.Nat,
  left : @core.Chain[Bool],
  right_degree : @core.Nat,
  right : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  let left_simplices = @homology.simplices(source, left_degree)
  let right_simplices = @homology.simplices(source, right_degree)
  match
    @core.length(left).equal(@core.length(left_simplices)) &&
    @core.length(right).equal(@core.length(right_simplices)) {
    false => None
    true =>
      Some(
        @core.map(
          @homology.simplices(source, @core.add(left_degree, right_degree)),
          fn(simplex) {
            evaluate(
              left_simplices,
              left,
              @core.take(Succ(left_degree), simplex),
            ) &&
            evaluate(right_simplices, right, @core.drop(left_degree, simplex))
          },
        ),
      )
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Product {
  left_class : @core.Chain[Bool]
  right_class : @core.Chain[Bool]
  cochain : @core.Chain[Bool]
  value : @core.Chain[Bool]
}

///|
pub extend Product with Eq::{equal, not_equal}

///|
pub extend Product with Debug::{to_repr}

///|
/// Bind an actual product to its source, input degrees, and actual cocycles.
#derive(Eq, Debug)
pub(all) struct ProductCertificate {
  source : @homology.Complex
  left_degree : @core.Nat
  right_degree : @core.Nat
  left_cochain : @core.Chain[Bool]
  right_cochain : @core.Chain[Bool]
  result : Product
}

///|
pub extend ProductCertificate with Eq::{equal, not_equal}

///|
pub extend ProductCertificate with Debug::{to_repr}

///|
fn compatible(
  left : Cohomology,
  right : Cohomology,
  target : Cohomology,
) -> Bool {
  let a = left.witness
  let b = right.witness
  let c = target.witness
  a.source.equal(b.source) &&
  a.source.equal(c.source) &&
  c.degree.equal(@core.add(a.degree, b.degree))
}

///|
pub fn check_product(
  left_space : Cohomology,
  left : @core.Chain[Bool],
  right_space : Cohomology,
  right : @core.Chain[Bool],
  target : Cohomology,
  actual : Product,
  witness : ProductCertificate,
) -> Bool {
  compatible(left_space, right_space, target) &&
  witness.source.equal(left_space.witness.source) &&
  witness.left_degree.equal(left_space.witness.degree) &&
  witness.right_degree.equal(right_space.witness.degree) &&
  witness.left_cochain.equal(left) &&
  witness.right_cochain.equal(right) &&
  witness.result.equal(actual) &&
  coordinates(left_space, left).equal(Some(actual.left_class)) &&
  coordinates(right_space, right).equal(Some(actual.right_class)) &&
  cup(witness.source, witness.left_degree, left, witness.right_degree, right).equal(
    Some(actual.cochain),
  ) &&
  coordinates(target, actual.cochain).equal(Some(actual.value))
}

///|
/// Multiply actual cocycles, retaining the raw cup and quotient coordinates.
pub fn cup_product(
  left_space : Cohomology,
  left : @core.Chain[Bool],
  right_space : Cohomology,
  right : @core.Chain[Bool],
  target : Cohomology,
) -> ProductCertificate? {
  match compatible(left_space, right_space, target) {
    false => None
    true =>
      match
        (
          coordinates(left_space, left),
          coordinates(right_space, right),
          cup(
            left_space.witness.source,
            left_space.witness.degree,
            left,
            right_space.witness.degree,
            right,
          ),
        ) {
        (Some(left_class), Some(right_class), Some(cochain)) =>
          match coordinates(target, cochain) {
            None => None
            Some(value) =>
              Some({
                source: left_space.witness.source,
                left_degree: left_space.witness.degree,
                right_degree: right_space.witness.degree,
                left_cochain: left,
                right_cochain: right,
                result: { left_class, right_class, cochain, value, },
              })
          }
        _ => None
      }
  }
}

///|
/// Check a concrete change of both cocycle representatives modulo boundaries.
pub fn check_representative_independence(
  left_space : Cohomology,
  left : @core.Chain[Bool],
  replacement_left : @core.Chain[Bool],
  right_space : Cohomology,
  right : @core.Chain[Bool],
  replacement_right : @core.Chain[Bool],
  target : Cohomology,
) -> Bool {
  equivalent(left_space, left, replacement_left).equal(Some(true)) &&
  equivalent(right_space, right, replacement_right).equal(Some(true)) &&
  (match
    (
      cup_product(left_space, left, right_space, right, target),
      cup_product(
        left_space, replacement_left, right_space, replacement_right, target,
      ),
    ) {
    (Some(a), Some(b)) => a.result.value.equal(b.result.value)
    _ => false
  })
}
