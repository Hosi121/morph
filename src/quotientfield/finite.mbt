///|
/// Irreducibility is inherited from an opaque, already checked galois.Field.
/// It is not asserted by an unchecked flag on a generic quotient.
pub struct PrimeExtension {
  source : @galois.Field
  algebra : @q.Context[@binary.Binary, @primefield.Field]
}

///|
pub fn prime_extension(
  source : @galois.Field,
) -> Result[PrimeExtension, @q.QuotientError] {
  let base = @galois.prime_field(source)
  let operations = @primefield.arithmetic(base)
  match
    @q.context(
      operations,
      base,
      @binary.is_zero,
      fn(x) { (operations.add)(x, operations.zero).equal(x) },
      @fppoly.coefficients(@galois.modulus(source)),
    ) {
    Ok(algebra) => Ok({ source, algebra, })
    Err(error) => Err(error)
  }
}

///|
pub fn prime_source(extension : PrimeExtension) -> @galois.Field {
  extension.source
}

///|
pub fn prime_context(
  extension : PrimeExtension,
) -> @q.Context[@binary.Binary, @primefield.Field] {
  extension.algebra
}

///|
pub fn enter_prime(
  extension : PrimeExtension,
  value : @galois.Element,
) -> Result[@q.Residue[@binary.Binary, @primefield.Field], @q.QuotientError] {
  if !extension.source.equal(@galois.field_of(value)) {
    return Err(@q.DifferentContext)
  }
  @q.normalize(
    extension.algebra,
    @fppoly.coefficients(@galois.representative(value)),
  )
}

///|
pub fn leave_prime(
  extension : PrimeExtension,
  value : @q.Residue[@binary.Binary, @primefield.Field],
) -> Result[@galois.Element, @q.QuotientError] {
  if !@q.same_context(extension.algebra, @q.parent(value)) {
    return Err(@q.DifferentContext)
  }
  match
    @galois.element(
      extension.source,
      @fppoly.polynomial(
        @galois.prime_field(extension.source),
        @q.coefficients(value),
      ),
    ) {
    Ok(value) => Ok(value)
    Err(_) => Err(@q.InternalInvariant)
  }
}

///|
pub fn prime_inverse(
  extension : PrimeExtension,
  value : @q.Residue[@binary.Binary, @primefield.Field],
) -> Result[@q.Residue[@binary.Binary, @primefield.Field]?, @q.QuotientError] {
  checked_inverse(extension.algebra, value)
}

///|
/// This representation capability requires the base to be F2, not merely an
/// extension field of characteristic two. Bool coefficients stay in this form
/// throughout arithmetic; no packing or unpacking occurs per multiplication.
pub struct BitExtension {
  source : @galois.Field
  algebra : @q.Context[Bool, Unit]
}

///|
fn to_bits(values : @core.Chain[@binary.Binary]) -> @core.Chain[Bool] {
  @core.map(values, fn(x) { !@binary.is_zero(x) })
}

///|
pub fn bit_extension(
  source : @galois.Field,
  policy : @q.Policy,
) -> Result[BitExtension, @q.QuotientError] {
  if !@primefield.is_f2(@galois.prime_field(source)) {
    return Err(@q.InvalidCoefficient)
  }
  match
    @q.gf2_context(
      (),
      to_bits(@fppoly.coefficients(@galois.modulus(source))),
      policy,
    ) {
    Ok(algebra) => Ok({ source, algebra, })
    Err(error) => Err(error)
  }
}

///|
pub fn bit_source(extension : BitExtension) -> @galois.Field {
  extension.source
}

///|
pub fn bit_context(extension : BitExtension) -> @q.Context[Bool, Unit] {
  extension.algebra
}

///|
pub fn enter_bits(
  extension : BitExtension,
  value : @galois.Element,
) -> Result[@q.Residue[Bool, Unit], @q.QuotientError] {
  if !extension.source.equal(@galois.field_of(value)) {
    return Err(@q.DifferentContext)
  }
  @q.normalize(
    extension.algebra,
    to_bits(@fppoly.coefficients(@galois.representative(value))),
  )
}

///|
pub fn leave_bits(
  extension : BitExtension,
  value : @q.Residue[Bool, Unit],
) -> Result[@galois.Element, @q.QuotientError] {
  if !@q.same_context(extension.algebra, @q.parent(value)) {
    return Err(@q.DifferentContext)
  }
  let coefficients = @core.map(@q.coefficients(value), fn(bit) {
    if bit {
      @binary.one()
    } else {
      @binary.zero()
    }
  })
  match
    @galois.element(
      extension.source,
      @fppoly.polynomial(@galois.prime_field(extension.source), coefficients),
    ) {
    Ok(value) => Ok(value)
    Err(_) => Err(@q.InternalInvariant)
  }
}

///|
pub fn bit_inverse(
  extension : BitExtension,
  value : @q.Residue[Bool, Unit],
) -> Result[@q.Residue[Bool, Unit]?, @q.QuotientError] {
  checked_inverse(extension.algebra, value)
}
