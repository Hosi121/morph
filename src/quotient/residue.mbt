///|
/// Check the opaque invariant at the internal result boundary as well.
fn[A, K] canonical_result(
  context : Context[A, K],
  coefficients : @core.Chain[A],
) -> Result[Residue[A, K], QuotientError] {
  if !@core.all(coefficients, context.coefficient_valid) {
    return Err(InternalInvariant)
  }
  match @core.compare(@core.length(coefficients), Succ(context.degree)) {
    Less => Ok({ context, coefficients, })
    _ => Err(InternalInvariant)
  }
}

///|
pub fn[A, K] normalize(
  context : Context[A, K],
  coefficients : @core.Chain[A],
) -> Result[Residue[A, K], QuotientError] {
  if !@core.all(coefficients, context.coefficient_valid) {
    return Err(InvalidCoefficient)
  }
  canonical_result(
    context,
    monic_remainder(
      context.arithmetic,
      context.coefficient_is_zero,
      context.modulus,
      context.degree,
      trim(context.coefficient_is_zero, coefficients),
    ),
  )
}

///|
pub fn[A, K] zero(context : Context[A, K]) -> Residue[A, K] {
  { context, coefficients: Nil, }
}

///|
pub fn[A, K] one(context : Context[A, K]) -> Residue[A, K] {
  { context, coefficients: Cons(context.arithmetic.one, Nil), }
}

///|
pub fn[A, K] generator(
  context : Context[A, K],
) -> Result[Residue[A, K], QuotientError] {
  normalize(
    context,
    Cons(context.arithmetic.zero, Cons(context.arithmetic.one, Nil)),
  )
}

///|
pub fn[A, K] is_zero(value : Residue[A, K]) -> Bool {
  match value.coefficients {
    Nil => true
    _ => false
  }
}

///|
pub fn[A, K : Eq] equivalent(a : Residue[A, K], b : Residue[A, K]) -> Bool {
  same_context(a.context, b.context) &&
  coefficient_lists_equal(
    a.context.arithmetic,
    a.context.coefficient_is_zero,
    a.coefficients,
    b.coefficients,
  )
}

///|
pub fn[A, K] negate(
  value : Residue[A, K],
) -> Result[Residue[A, K], QuotientError] {
  canonical_result(
    value.context,
    negate_coefficients(
      value.context.arithmetic,
      value.context.coefficient_is_zero,
      value.coefficients,
    ),
  )
}

///|
pub fn[A, K : Eq] add(
  a : Residue[A, K],
  b : Residue[A, K],
) -> Result[Residue[A, K], QuotientError] {
  if !same_context(a.context, b.context) {
    return Err(DifferentContext)
  }
  canonical_result(
    a.context,
    add_coefficients(
      a.context.arithmetic,
      a.context.coefficient_is_zero,
      a.coefficients,
      b.coefficients,
    ),
  )
}

///|
pub fn[A, K : Eq] subtract(
  a : Residue[A, K],
  b : Residue[A, K],
) -> Result[Residue[A, K], QuotientError] {
  if !same_context(a.context, b.context) {
    return Err(DifferentContext)
  }
  canonical_result(
    a.context,
    subtract_coefficients(
      a.context.arithmetic,
      a.context.coefficient_is_zero,
      a.coefficients,
      b.coefficients,
    ),
  )
}

///|
pub fn[A, K : Eq] multiply(
  a : Residue[A, K],
  b : Residue[A, K],
) -> Result[Residue[A, K], QuotientError] {
  if !same_context(a.context, b.context) {
    return Err(DifferentContext)
  }
  canonical_result(
    a.context,
    (a.context.product)(a.coefficients, b.coefficients),
  )
}
