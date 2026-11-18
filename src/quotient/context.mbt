///|
#derive(Eq, Debug)
pub(all) enum QuotientError {
  InvalidCoefficient
  InvalidArithmetic
  ZeroModulus
  ConstantModulus
  NonMonicModulus
  DifferentContext
  InternalInvariant
}

///|
pub extend QuotientError with Eq::{equal, not_equal}

///|
pub extend QuotientError with Debug::{to_repr}

///|
/// Both policies implement the same quotient. Carryless is available only from
/// the typed Bool coefficient factory, and uses a Bool Chain, not packed words.
#derive(Eq, Debug)
pub(all) enum Policy {
  Generic
  Carryless
}

///|
pub extend Policy with Eq::{equal, not_equal}

///|
pub extend Policy with Debug::{to_repr}

///|
/// A trusted coefficient field dictionary and a monic positive-degree modulus.
/// This is a quotient ring context; it makes no irreducibility claim.
/// The caller must give consistent field operations and coefficient equality
/// for every occurrence of the same base key. Functions are never compared.
pub struct Context[A, K] {
  priv arithmetic : @rowreduce.Field[A]
  priv key : K
  priv modulus : @core.Chain[A]
  priv degree : @core.Nat
  priv coefficient_is_zero : (A) -> Bool
  priv coefficient_valid : (A) -> Bool
  priv product : (@core.Chain[A], @core.Chain[A]) -> @core.Chain[A]
  priv policy : Policy
}

///|
/// Canonical ascending coefficients, with degree below the checked modulus.
pub struct Residue[A, K] {
  priv context : Context[A, K]
  priv coefficients : @core.Chain[A]
}

///|
/// Boundary validation checks coefficients and the zero/one observations.
/// It does not prove the field laws of an arbitrary supplied dictionary.
pub fn[A, K] context(
  arithmetic : @rowreduce.Field[A],
  key : K,
  is_zero : (A) -> Bool,
  valid : (A) -> Bool,
  modulus : @core.Chain[A],
) -> Result[Context[A, K], QuotientError] {
  if !valid(arithmetic.zero) || !valid(arithmetic.one) {
    return Err(InvalidCoefficient)
  }
  if !is_zero(arithmetic.zero) || is_zero(arithmetic.one) {
    return Err(InvalidArithmetic)
  }
  if !@core.all(modulus, valid) {
    return Err(InvalidCoefficient)
  }
  let modulus = trim(is_zero, modulus)
  let degree = match @core.length(modulus) {
    Zero => return Err(ZeroModulus)
    Succ(Zero) => return Err(ConstantModulus)
    Succ(degree) => degree
  }
  match @core.last(modulus) {
    Some(leading) =>
      if !is_zero((arithmetic.subtract)(leading, arithmetic.one)) {
        return Err(NonMonicModulus)
      }
    None => return Err(InternalInvariant)
  }
  let product = fn(left, right) {
    monic_remainder(
      arithmetic,
      is_zero,
      modulus,
      degree,
      convolution(arithmetic, is_zero, left, right),
    )
  }
  Ok({
    arithmetic,
    key,
    modulus,
    degree,
    coefficient_is_zero: is_zero,
    coefficient_valid: valid,
    product,
    policy: Generic,
  })
}

///|
pub fn[A, K] base_key(context : Context[A, K]) -> K {
  context.key
}

///|
pub fn[A, K] modulus(context : Context[A, K]) -> @core.Chain[A] {
  context.modulus
}

///|
pub fn[A, K] degree(context : Context[A, K]) -> @core.Nat {
  context.degree
}

///|
pub fn[A, K] policy(context : Context[A, K]) -> Policy {
  context.policy
}

///|
/// The base key and canonical modulus define identity. Preparation, callbacks
/// and execution policy are excluded. Equal keys assume consistent dictionaries.
pub fn[A, K : Eq] same_context(a : Context[A, K], b : Context[A, K]) -> Bool {
  a.key.equal(b.key) &&
  coefficient_lists_equal(
    a.arithmetic,
    a.coefficient_is_zero,
    a.modulus,
    b.modulus,
  )
}

///|
pub fn[A, K] parent(value : Residue[A, K]) -> Context[A, K] {
  value.context
}

///|
pub fn[A, K] coefficients(value : Residue[A, K]) -> @core.Chain[A] {
  value.coefficients
}
