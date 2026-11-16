///|
#derive(Eq, Debug)
pub(all) struct Validation {
  alphabet_complete : Bool
  support_distinct : Bool
  dimensions : Bool
  multiplicity_indices : Bool
  weighted_monomials : Bool
  nonzero_kernel_guaranteed : Bool
  factorization_bound : Bool
}

///|
pub extend Validation with Eq::{equal, not_equal}

///|
pub extend Validation with Debug::{to_repr}

///|
pub fn valid(validation : Validation) -> Bool {
  validation.alphabet_complete &&
  validation.support_distinct &&
  validation.dimensions &&
  validation.multiplicity_indices &&
  validation.weighted_monomials &&
  validation.nonzero_kernel_guaranteed &&
  validation.factorization_bound
}

///|
pub fn validate(plan : Plan) -> Validation {
  let alphabet_complete = @binary.from_nat(@core.length(plan.alphabet)).equal(
      @modular.value(@primefield.modulus(plan.field)),
    ) &&
    @core.all(plan.alphabet, fn(value) { canonical(plan.field, value) }) &&
    distinct(plan.alphabet)
  let support_distinct = @core.all(plan.points, fn(value) {
      canonical(plan.field, value)
    }) &&
    distinct(plan.points)
  let dimensions = @core.compare(plan.dimension, Succ(Zero)) is Greater &&
    !(@core.compare(plan.dimension, @core.length(plan.points)) is Greater) &&
    !@core.is_zero(plan.agreements) &&
    !(@core.compare(plan.agreements, @core.length(plan.points)) is Greater) &&
    !@core.is_zero(plan.multiplicity)
  let multiplicity_indices = derivative_indices(plan.multiplicity).equal(
    plan.derivatives,
  )
  let weighted_monomials = if @core.compare(plan.dimension, Succ(Zero))
    is Greater {
    weighted_monomials(
      @core.subtract(plan.dimension, Succ(Zero)),
      plan.degree_bound,
    ).equal(plan.monomials)
  } else {
    false
  }
  let nonzero_kernel_guaranteed = @core.compare(
      @core.length(plan.monomials),
      constraint_count(plan),
    )
    is Greater
  let factorization_bound = @core.compare(
      plan.degree_bound,
      @core.multiply(plan.multiplicity, plan.agreements),
    )
    is Less
  {
    alphabet_complete,
    support_distinct,
    dimensions,
    multiplicity_indices,
    weighted_monomials,
    nonzero_kernel_guaranteed,
    factorization_bound,
  }
}
