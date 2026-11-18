///|
/// A checked real extension retains its selected root, independently of the
/// quotient arithmetic. Only an existing checked numberfield.Field can upgrade.
pub struct RealExtension {
  source : @nf.Field
  algebra : @q.Context[@exact.Rational, @real.RootCertificate]
}

///|
pub fn rational_field() -> @rowreduce.Field[@exact.Rational] {
  {
    zero: @exact.rational_zero(),
    one: @exact.rational_one(),
    add: @exact.rational_add,
    subtract: @exact.rational_subtract,
    negate: @exact.rational_negate,
    multiply: @exact.rational_multiply,
    inverse: fn(x) {
      match @exact.nonzero(x) {
        None => None
        Some(p) => Some(@exact.reciprocal(p))
      }
    },
  }
}

///|
/// Ascending sparse terms are consumed once, filling only actual degree gaps.
fn dense_terms(
  terms : @core.Chain[@poly.Term],
  index : @core.Nat,
) -> @core.Chain[@exact.Rational] {
  match terms {
    Nil => Nil
    Cons(term, tail) =>
      match term.exponents {
        Cons(d, Nil) =>
          if d.equal(index) {
            Cons(term.coefficient, dense_terms(tail, Succ(index)))
          } else {
            Cons(@exact.rational_zero(), dense_terms(terms, Succ(index)))
          }
        _ => Nil
      }
  }
}

///|
/// Boundary conversion, never called by quotient add or multiply.
pub fn rational_coefficients(
  polynomial : @poly.Polynomial,
) -> @core.Chain[@exact.Rational]? {
  if !@poly.variables(polynomial).equal(Succ(Zero)) {
    return None
  }
  Some(dense_terms(@core.reverse(@poly.terms(polynomial)), Zero))
}

///|
pub fn rational_polynomial(
  coefficients : @core.Chain[@exact.Rational],
) -> @poly.Polynomial? {
  fn terms(
    values : @core.Chain[@exact.Rational],
    index : @core.Nat,
  ) -> @core.Chain[@poly.Term] {
    match values {
      Nil => Nil
      Cons(coefficient, tail) =>
        Cons(
          { coefficient, exponents: Cons(index, Nil), },
          terms(tail, Succ(index)),
        )
    }
  }
  match @poly.polynomial(Succ(Zero), terms(coefficients, Zero)) {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
pub fn real_extension(
  source : @nf.Field,
) -> Result[RealExtension, @q.QuotientError] {
  let coefficients = match
    rational_coefficients(@poly.monic(@nf.modulus(source))) {
    Some(values) => values
    None => return Err(@q.InternalInvariant)
  }
  match
    @q.context(
      rational_field(),
      @nf.embedding(source),
      fn(x) { x.equal(@exact.rational_zero()) },
      fn(_) { true },
      coefficients,
    ) {
    Ok(algebra) => Ok({ source, algebra, })
    Err(error) => Err(error)
  }
}

///|
pub fn real_source(extension : RealExtension) -> @nf.Field {
  extension.source
}

///|
pub fn real_context(
  extension : RealExtension,
) -> @q.Context[@exact.Rational, @real.RootCertificate] {
  extension.algebra
}

///|
pub fn enter_real(
  extension : RealExtension,
  value : @nf.Element,
) -> Result[
  @q.Residue[@exact.Rational, @real.RootCertificate],
  @q.QuotientError,
] {
  if !@nf.same_field(extension.source, @nf.parent(value)) {
    return Err(@q.DifferentContext)
  }
  // coordinates are already degree-bounded. Conversion occurs once on entry.
  @q.normalize(extension.algebra, @nf.coordinates(value))
}

///|
pub fn leave_real(
  extension : RealExtension,
  value : @q.Residue[@exact.Rational, @real.RootCertificate],
) -> Result[@nf.Element, @q.QuotientError] {
  if !@q.same_context(extension.algebra, @q.parent(value)) {
    return Err(@q.DifferentContext)
  }
  let polynomial = match rational_polynomial(@q.coefficients(value)) {
    Some(value) => value
    None => return Err(@q.InternalInvariant)
  }
  match @nf.element(extension.source, polynomial) {
    Ok(value) => Ok(value)
    Err(_) => Err(@q.InternalInvariant)
  }
}

///|
/// In a checked irreducible quotient every nonzero residue must be a unit.
/// A failed nonzero inverse is an invariant error, never a field claim for a
/// reducible modulus. Zero has the existing numberfield Option convention.
pub fn real_inverse(
  extension : RealExtension,
  value : @q.Residue[@exact.Rational, @real.RootCertificate],
) -> Result[
  @q.Residue[@exact.Rational, @real.RootCertificate]?,
  @q.QuotientError,
] {
  checked_inverse(extension.algebra, value)
}

///|
/// Shared upgrade rule, reachable only through checked extension wrappers.
fn[A, K : Eq] checked_inverse(
  context : @q.Context[A, K],
  value : @q.Residue[A, K],
) -> Result[@q.Residue[A, K]?, @q.QuotientError] {
  if !@q.same_context(context, @q.parent(value)) {
    return Err(@q.DifferentContext)
  }
  match @q.unit_inverse(value) {
    Ok(None) =>
      if @q.is_zero(value) {
        Ok(None)
      } else {
        Err(@q.InternalInvariant)
      }
    result => result
  }
}

///|
/// Forget the extra field operations; semiring laws follow from field laws.
/// This projection adds no independent arithmetic implementation.
pub fn[A] semiring(field : @rowreduce.Field[A]) -> @algebra.Semiring[A] {
  { zero: field.zero, one: field.one, plus: field.add, times: field.multiply, }
}
