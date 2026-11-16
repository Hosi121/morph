///|
/// Untrusted minimal-polynomial normalization proof. Factorization is complete,
/// selected is an index in its factor list, and the result keeps the input interval.
#derive(Eq, Debug)
pub(all) struct Certificate {
  input : @real.RootCertificate
  factorization : @zass.RationalFactorization
  selected : @core.Nat
  result : @real.RootCertificate
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// Independently recheck every factor's root count in the original half-open
/// interval. Exactly the selected factor must have one root; all others have none.
fn selection_valid(proof : Certificate) -> Bool {
  fn check_factors(
    factors : @core.Chain[@zass.Factor],
    index : @core.Nat,
  ) -> Bool {
    match factors {
      Nil => true
      Cons(factor, rest) =>
        match integer_polynomial(factor.polynomial) {
          None => false
          Some(polynomial) =>
            match @sturm.system(polynomial) {
              Err(_) => false
              Ok(system) =>
                match
                  @sturm.count_between(
                    system,
                    proof.input.interval.lower,
                    proof.input.interval.upper,
                  ) {
                  Some(count) =>
                    @core.compare(
                      count,
                      if @core.compare(index, proof.selected).equal(Equal) {
                        Succ(Zero)
                      } else {
                        Zero
                      },
                    ).equal(Equal) &&
                    check_factors(rest, Succ(index))
                  None => false
                }
            }
        }
    }
  }
  match @core.nth(proof.factorization.factors, proof.selected) {
    None => false
    Some(factor) =>
      match integer_polynomial(factor.polynomial) {
        None => false
        Some(polynomial) =>
          proof.result.polynomial.equal(polynomial) &&
          proof.result.interval.equal(proof.input.interval) &&
          @real.check_root(proof.result) &&
          check_factors(proof.factorization.factors, Zero)
      }
  }
}

///|
/// Proven requires Zassenhaus's complete factorization/irreducibility checker,
/// plus exact selected-root binding. Verification fuel is per claimed factor;
/// exhaustion is Undecided and never a minimality claim.
pub fn check(
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  if !@real.check_root(proof.input) {
    return @zass.Refuted
  }
  match coefficients(proof.input.polynomial) {
    None => @zass.Refuted
    Some(values) =>
      match
        @zass.check_rational_factorization(
          values,
          proof.factorization,
          verification_fuel,
        ) {
        @zass.Proven =>
          if selection_valid(proof) {
            @zass.Proven
          } else {
            @zass.Refuted
          }
        other => other
      }
  }
}

///|
/// Bind a separate returned Number to the exact normalized definition and
/// interval in the proof. This binds a representation, not arbitrary equal roots.
pub fn check_result(
  value : @real.Number,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  if !@real.root_certificate(value).equal(proof.result) {
    @zass.Refuted
  } else {
    check(proof, verification_fuel)
  }
}

///|
/// Bind both the caller's original Number and the returned Number. Raw repeated
/// or nonmonic input certificates are canonicalized exactly as Number construction.
pub fn check_normalization(
  original : @real.Number,
  value : @real.Number,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zass.Verdict {
  match @real.number(proof.input) {
    Err(_) => @zass.Refuted
    Ok(input) =>
      if @real.root_certificate(original).equal(@real.root_certificate(input)) {
        check_result(value, proof, verification_fuel)
      } else {
        @zass.Refuted
      }
  }
}
