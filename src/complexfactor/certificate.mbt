///|
/// Ordered exhaustive covers of the primitive integer factors. The rational
/// unit is part of the reconstruction proof, even though it has no roots.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @poly.Polynomial
  factorization : @zassenhaus.RationalFactorization
  covers : @core.Chain[@complexroots.Certificate]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// A selected position in a complete bare RootSet. Selection retrieves the
/// actual checked payload from that RootSet. The fallback only makes the
/// accessor total on private malformed values; certified indices never use it.
#derive(Debug)
pub struct Root {
  group : @complexroots.RootSet
  index : @core.Nat
  fallback : @complexroots.Root
  weight : @core.Nat
}

///|
pub extend Root with Debug::{to_repr}

///|
pub fn root(value : Root) -> @complexroots.Root {
  match @core.nth(@complexroots.roots(value.group), value.index) {
    Some(selected) => selected
    None => value.fallback
  }
}

///|
pub fn multiplicity(value : Root) -> @core.Nat {
  value.weight
}

///|
#derive(Debug)
pub struct RootFamily {
  source : @poly.Polynomial
  proof : Certificate
  roots : @core.Chain[Root]
}

///|
pub extend RootFamily with Debug::{to_repr}

///|
pub fn roots(value : RootFamily) -> @core.Chain[Root] {
  value.roots
}

///|
pub fn source(value : RootFamily) -> @poly.Polynomial {
  value.source
}

///|
pub fn certificate(value : RootFamily) -> Certificate {
  value.proof
}

///|
fn valid_covers(
  factors : @core.Chain[@zassenhaus.Factor],
  covers : @core.Chain[@complexroots.Certificate],
) -> Bool {
  match (factors, covers) {
    (Nil, Nil) => true
    (Cons(factor, rest), Cons(cover, tail)) =>
      @complexroots.check(factor_polynomial(factor), cover) &&
      valid_covers(rest, tail)
    _ => false
  }
}

///|
fn factor_degree(factors : @core.Chain[@zassenhaus.Factor]) -> @core.Nat {
  @core.fold_left(factors, Zero, fn(total, factor) {
    @core.add(
      total,
      @core.multiply(degree(factor_polynomial(factor)), factor.multiplicity),
    )
  })
}

///|
/// A bounded irreducibility check can return Undecided. Exact root cover,
/// source, reconstruction, positive weight, coprimality and degree checks are
/// mandatory independently of that budget.
pub fn check(
  source : @poly.Polynomial,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zassenhaus.Verdict {
  if !@poly.variables(source).equal(Succ(Zero)) ||
    @poly.is_zero(source) ||
    !proof.source.equal(source) ||
    !coprime_factors(proof.factorization.factors) ||
    !factor_degree(proof.factorization.factors).equal(degree(source)) ||
    !valid_covers(proof.factorization.factors, proof.covers) {
    Refuted
  } else {
    @zassenhaus.check_rational_factorization(
      coefficients(source),
      proof.factorization,
      verification_fuel,
    )
  }
}

///|
fn bound_roots(
  factors : @core.Chain[@zassenhaus.Factor],
  covers : @core.Chain[@complexroots.Certificate],
  values : @core.Chain[Root],
  total : @core.Nat,
) -> @core.Nat? {
  match (factors, covers) {
    (Nil, Nil) => if values is Nil { Some(total) } else { None }
    (Cons(factor, rest), Cons(cover, tail)) => {
      let factor_source = factor_polynomial(factor)
      fn group(
        index : @core.Nat,
        remaining : @core.Nat,
        values : @core.Chain[Root],
        total : @core.Nat,
      ) -> @core.Nat? {
        match remaining {
          Zero => bound_roots(rest, tail, values, total)
          Succ(left) =>
            match values {
              Nil => None
              Cons(value, pending) =>
                if !value.index.equal(index) ||
                  !@complexroots.certificate(value.group).equal(cover) ||
                  !@complexroots.check_result(factor_source, value.group, cover) {
                  None
                } else {
                  match @core.nth(@complexroots.roots(value.group), index) {
                    None => None
                    Some(selected) => {
                      let weight = @core.multiply(
                        factor.multiplicity,
                        @complexroots.multiplicity(selected),
                      )
                      if weight is Zero || !value.weight.equal(weight) {
                        None
                      } else {
                        group(
                          Succ(index),
                          left,
                          pending,
                          @core.add(total, weight),
                        )
                      }
                    }
                  }
                }
            }
        }
      }
      group(Zero, degree(factor_source), values, total)
    }
    _ => None
  }
}

///|
/// Bind every returned payload and its list position to the corresponding
/// source-bound exhaustive factor cover; factor multiplicities multiply the
/// checked bare multiplicities. Completed families have original degree mass.
pub fn check_result(
  source : @poly.Polynomial,
  value : RootFamily,
  proof : Certificate,
  verification_fuel : @core.Nat,
) -> @zassenhaus.Verdict {
  if !value.source.equal(source) ||
    !value.proof.equal(proof) ||
    !bound_roots(proof.factorization.factors, proof.covers, value.roots, Zero).equal(
      Some(degree(source)),
    ) {
    Refuted
  } else {
    check(source, proof, verification_fuel)
  }
}

///|
fn assemble(
  problem : Problem,
  groups : @core.Chain[@complexroots.RootSet],
) -> RootFamily? {
  fn flatten(
    factors : @core.Chain[@zassenhaus.Factor],
    groups : @core.Chain[@complexroots.RootSet],
  ) -> @core.Chain[Root]? {
    match (factors, groups) {
      (Nil, Nil) => Some(Nil)
      (Cons(factor, rest), Cons(group, tail)) => {
        fn members(
          values : @core.Chain[@complexroots.Root],
          index : @core.Nat,
        ) -> @core.Chain[Root] {
          match values {
            Nil => Nil
            Cons(value, rest) =>
              Cons(
                {
                  group,
                  index,
                  fallback: value,
                  weight: @core.multiply(
                    factor.multiplicity,
                    @complexroots.multiplicity(value),
                  ),
                },
                members(rest, Succ(index)),
              )
          }
        }
        match flatten(rest, tail) {
          None => None
          Some(pending) =>
            Some(
              @core.append(members(@complexroots.roots(group), Zero), pending),
            )
        }
      }
      _ => None
    }
  }
  match flatten(problem.factorization.factors, groups) {
    None => None
    Some(roots) =>
      Some({
        source: problem.source,
        proof: {
          source: problem.source,
          factorization: problem.factorization,
          covers: @core.map(groups, @complexroots.certificate),
        },
        roots,
      })
  }
}
