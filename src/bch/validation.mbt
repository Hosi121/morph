///|
/// Individually inspectable construction checks. Validation reconstructs every
/// conjugacy factor and their Boolean product, rather than trusting metadata.
#derive(Eq, Debug)
pub(all) struct Validation {
  binary_field : Bool
  root_field : Bool
  primitive_length : Bool
  exact_root_order : Bool
  designed_roots : Bool
  inverse_points : Bool
  minimal_factors : Bool
  generator_product : Bool
  cyclic_divisor : Bool
  dimensions : Bool
}

///|
pub extend Validation with Eq::{equal, not_equal}

///|
pub extend Validation with Debug::{to_repr}

///|
pub fn valid(validation : Validation) -> Bool {
  validation.binary_field &&
  validation.root_field &&
  validation.primitive_length &&
  validation.exact_root_order &&
  validation.designed_roots &&
  validation.inverse_points &&
  validation.minimal_factors &&
  validation.generator_product &&
  validation.cyclic_divisor &&
  validation.dimensions
}

///|
/// Check a full orbit witness and reconstruct all its coefficients over F₂.
/// The complete Frobenius orbit establishes the minimal polynomial degree.
pub fn check_minimal_polynomial(
  field : @galois.Field,
  factor : MinimalPolynomial,
) -> Bool {
  if !@galois.characteristic(field).equal(@binary.double(@binary.one())) {
    return false
  }
  if !@core.all(factor.conjugates, fn(value) {
      @galois.field_of(value).equal(field)
    }) {
    return false
  }
  match factor.conjugates {
    Nil => false
    Cons(head, _) =>
      match (conjugates(field, head), orbit_product(field, factor.conjugates)) {
        (Ok(orbit), Ok(product)) =>
          match lower(field, product) {
            Ok(coefficients) =>
              orbit.equal(factor.conjugates) &&
              coefficients.equal(factor.coefficients)
            Err(_) => false
          }
        _ => false
      }
  }
}

///|
fn check_factors(
  field : @galois.Field,
  factors : @core.Chain[MinimalPolynomial],
  roots : @core.Chain[@galois.Element],
  seen : @core.Chain[@galois.Element],
) -> Bool {
  match factors {
    Nil => @core.all(roots, fn(root) { contains(seen, root) })
    Cons(factor, rest) =>
      check_minimal_polynomial(field, factor) &&
      @core.any(factor.conjugates, fn(root) { contains(roots, root) }) &&
      @core.all(factor.conjugates, fn(root) { !contains(seen, root) }) &&
      check_factors(field, rest, roots, @core.append(factor.conjugates, seen))
  }
}

///|
/// Recheck structural plan facts, the exact primitive order, all complete
/// conjugacy factors, descent to F₂, root coverage and g(x)|(x^n+1).
pub fn validate(plan : Plan) -> Validation {
  let binary_field = @galois.characteristic(plan.field).equal(
    @binary.double(@binary.one()),
  )
  let root_field = @galois.field_of(plan.root).equal(plan.field)
  let primitive_length = !@core.is_zero(plan.length) &&
    @binary.successor(@binary.from_nat(plan.length)).equal(
      @galois.cardinality(plan.field),
    )
  let exact_root_order = match
    arithmetic(exact_order(plan.root, @galois.one(plan.field), plan.length)) {
    Ok(value) => value
    Err(_) => false
  }
  let designed_roots = match
    arithmetic(
      powers(plan.root, plan.root, @core.add(plan.errors, plan.errors)),
    ) {
    Ok(roots) => roots.equal(plan.roots)
    Err(_) => false
  }
  let inverse_points = match
    arithmetic(powers(plan.root, @galois.one(plan.field), plan.length)) {
    Err(_) => false
    Ok(points) =>
      match arithmetic(invert_all(points)) {
        Ok(inverses) => inverses.equal(plan.inverse_points)
        Err(_) => false
      }
  }
  let minimal_factors = check_factors(plan.field, plan.factors, plan.roots, Nil)
  let generator_product = factor_product(plan.factors).equal(plan.generator)
  let monic = match @core.last(plan.generator) {
    Some(true) => true
    _ => false
  }
  let cyclic_divisor = if !monic {
    false
  } else {
    match plan.length {
      Zero => false
      Succ(rest) =>
        match
          bit_remainder(
            Cons(
              true,
              @core.append(@core.replicate(rest, false), Cons(true, Nil)),
            ),
            plan.generator,
          ) {
          Nil => true
          _ => false
        }
    }
  }
  let dimensions = monic &&
    @core.length(plan.generator).equal(Succ(plan.parity)) &&
    @core.compare(plan.parity, plan.length) is Less &&
    @core.add(plan.message_size, plan.parity).equal(plan.length) &&
    @core.compare(@core.add(plan.errors, plan.errors), plan.length) is Less
  {
    binary_field,
    root_field,
    primitive_length,
    exact_root_order,
    designed_roots,
    inverse_points,
    minimal_factors,
    generator_product,
    cyclic_divisor,
    dimensions,
  }
}
