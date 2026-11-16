///|
#derive(Eq, Debug)
pub(all) enum MinimalError {
  InvalidInput
  FactorizationFailure(@zass.AlgebraError)
  InternalInvariant
}

///|
pub extend MinimalError with Eq::{equal, not_equal}

///|
pub extend MinimalError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StopReason {
  NoGoodPrime
  LiftBudget
  SubsetBudget
  VerificationBudget
}

///|
pub extend StopReason with Eq::{equal, not_equal}

///|
pub extend StopReason with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Normalized(@real.Number, Certificate)
  Unresolved(StopReason)
}

///|
pub extend Progress with Debug::{to_repr}

///|
fn stop_reason(value : @zass.StopReason) -> StopReason {
  match value {
    @zass.NoGoodPrime => NoGoodPrime
    @zass.LiftBudget => LiftBudget
    @zass.RecombinationBudget => SubsetBudget
  }
}

///|
/// Producer selection is separate from the checker's indexed root-count test.
fn choose(
  factors : @core.Chain[@zass.Factor],
  interval : @sturm.Interval,
) -> (@core.Nat, @poly.Polynomial)? {
  fn matches(
    todo : @core.Chain[@zass.Factor],
    index : @core.Nat,
  ) -> @core.Chain[(@core.Nat, @poly.Polynomial)]? {
    match todo {
      Nil => Some(Nil)
      Cons(factor, rest) =>
        match
          (integer_polynomial(factor.polynomial), matches(rest, Succ(index))) {
          (Some(polynomial), Some(tail)) =>
            match @sturm.system(polynomial) {
              Err(_) => None
              Ok(system) =>
                match
                  @sturm.count_between(system, interval.lower, interval.upper) {
                  Some(Zero) => Some(tail)
                  Some(Succ(Zero)) => Some(Cons((index, polynomial), tail))
                  _ => None
                }
            }
          _ => None
        }
    }
  }
  match matches(factors, Zero) {
    Some(Cons(selected, Nil)) => Some(selected)
    _ => None
  }
}

///|
/// Explicit normalization from a root certificate, preserving its half-open
/// interval. Repeated and nonmonic raw definitions can be factored directly.
pub fn normalize_root(
  input : @real.RootCertificate,
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
  verification_fuel : @core.Nat,
) -> Result[Progress, MinimalError] {
  if !@real.check_root(input) {
    return Err(InvalidInput)
  }
  match coefficients(input.polynomial) {
    None => Err(InvalidInput)
    Some(values) =>
      match @zass.factor_rational(values, primes, lift_fuel, subset_fuel) {
        Err(error) => Err(FactorizationFailure(error))
        Ok(@zass.RationalIncomplete(reason)) =>
          Ok(Unresolved(stop_reason(reason)))
        Ok(@zass.RationalComplete(factorization)) =>
          match
            @zass.check_rational_factorization(
              values, factorization, verification_fuel,
            ) {
            @zass.Refuted => Err(InternalInvariant)
            @zass.Undecided => Ok(Unresolved(VerificationBudget))
            @zass.Proven =>
              match choose(factorization.factors, input.interval) {
                None => Err(InternalInvariant)
                Some((selected, polynomial)) => {
                  let result : @real.RootCertificate = {
                    polynomial,
                    interval: input.interval,
                  }
                  let proof : Certificate = {
                    input,
                    factorization,
                    selected,
                    result,
                  }
                  if !selection_valid(proof) {
                    return Err(InternalInvariant)
                  }
                  match @real.number(result) {
                    Err(_) => Err(InternalInvariant)
                    Ok(value) => Ok(Normalized(value, proof))
                  }
                }
              }
          }
      }
  }
}

///|
/// Factor the current Number definition, prove irreducibility, and explicitly
/// replace it by the unique monic minimal factor for the same selected root.
/// Existing realalgebraic arithmetic is never changed automatically.
pub fn normalize(
  input : @real.Number,
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
  verification_fuel : @core.Nat,
) -> Result[Progress, MinimalError] {
  normalize_root(
    @real.root_certificate(input),
    primes,
    lift_fuel,
    subset_fuel,
    verification_fuel,
  )
}
