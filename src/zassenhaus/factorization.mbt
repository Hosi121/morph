///|
#derive(Eq, Debug)
pub(all) struct SquareFreeFactor {
  polynomial : Polynomial
  multiplicity : @core.Nat
}

///|
pub extend SquareFreeFactor with Eq::{equal, not_equal}

///|
pub extend SquareFreeFactor with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct SquareFreeDecomposition {
  content : @exact.Integer
  components : @core.Chain[SquareFreeFactor]
}

///|
pub extend SquareFreeDecomposition with Eq::{equal, not_equal}

///|
pub extend SquareFreeDecomposition with Debug::{to_repr}

///|
/// Yun's characteristic-zero square-free decomposition, over primitive Z[x].
pub fn square_free(
  value : Polynomial,
) -> Result[SquareFreeDecomposition, AlgebraError] {
  fn walk(
    w : Polynomial,
    c : Polynomial,
    multiplicity : @core.Nat,
  ) -> @core.Chain[SquareFreeFactor]? {
    if w.equal(one()) {
      Some(Nil)
    } else {
      match gcd(w, c) {
        None => None
        Some(y) =>
          match (exact_divide(w, y), exact_divide(c, y)) {
            (Some(z), Some(next_c)) =>
              match walk(y, next_c, Succ(multiplicity)) {
                None => None
                Some(tail) =>
                  if z.equal(one()) {
                    Some(tail)
                  } else {
                    Some(Cons({ polynomial: z, multiplicity, }, tail))
                  }
              }
            _ => None
          }
      }
    }
  }
  if is_zero(value) {
    Err(ZeroPolynomial)
  } else {
    let (content, part) = primitive(value)
    match gcd(part, derivative(part)) {
      None => Err(InternalInvariant)
      Some(c) =>
        match exact_divide(part, c) {
          None => Err(InternalInvariant)
          Some(w) =>
            match walk(w, c, Succ(Zero)) {
              Some(components) => Ok({ content, components, })
              None => Err(InternalInvariant)
            }
        }
    }
  }
}

///|
/// A conservative Landau-Mignotte bound: 2^degree(f) * sum(abs(coeff(f))).
/// This bounds every coefficient of every primitive integer divisor of f.
pub fn coefficient_bound(value : Polynomial) -> @binary.Binary {
  fn times_two(value : @binary.Binary, count : @core.Nat) -> @binary.Binary {
    match count {
      Zero => value
      Succ(rest) => times_two(@binary.double(value), rest)
    }
  }
  let norm = @core.fold_left(value.coefficients, @binary.zero(), fn(a, c) {
    @binary.add(a, @exact.magnitude(c))
  })
  match degree(value) {
    None => @binary.zero()
    Some(n) => times_two(norm, n)
  }
}

///|
/// Precision threshold 2*abs(lc(f))*B; recovery requires strictly greater m.
pub fn recombination_threshold(value : Polynomial) -> @binary.Binary {
  match leading(value) {
    None => @binary.zero()
    Some(lc) =>
      @binary.double(
        @binary.multiply(@exact.magnitude(lc), coefficient_bound(value)),
      )
  }
}

///|
/// A complete modular factorization and prime-power lift of a primitive,
/// positive-leading square-free polynomial. The target can be a larger
/// polynomial divisible by the value whose irreducibility is being checked.
#derive(Eq, Debug)
pub(all) struct IrreducibilityCertificate {
  lift : LiftCertificate
  finite_certificates : @core.Chain[@fppoly.IrreducibilityCertificate]
}

///|
pub extend IrreducibilityCertificate with Eq::{equal, not_equal}

///|
pub extend IrreducibilityCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Factor {
  polynomial : Polynomial
  multiplicity : @core.Nat
  certificate : IrreducibilityCertificate
}

///|
pub extend Factor with Eq::{equal, not_equal}

///|
pub extend Factor with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Factorization {
  content : @exact.Integer
  factors : @core.Chain[Factor]
}

///|
pub extend Factorization with Eq::{equal, not_equal}

///|
pub extend Factorization with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Verdict {
  Proven
  Refuted
  Undecided
}

///|
pub extend Verdict with Eq::{equal, not_equal}

///|
pub extend Verdict with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StopReason {
  NoGoodPrime
  LiftBudget
  RecombinationBudget
}

///|
pub extend StopReason with Eq::{equal, not_equal}

///|
pub extend StopReason with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Outcome {
  Complete(Factorization)
  Incomplete(StopReason)
}

///|
pub extend Outcome with Eq::{equal, not_equal}

///|
pub extend Outcome with Debug::{to_repr}

///|
priv enum Scan[S] {
  Finished(S, @core.Nat)
  Stopped
  Exhausted
}

///|
/// Streaming depth-first traversal: no exponential subset list is allocated.
/// One unit of fuel is consumed per leaf, including empty and full subsets.
fn[S] scan_subsets(
  lifts : @core.Chain[Polynomial],
  current : Polynomial,
  modulus : @modular.Modulus,
  fuel : @core.Nat,
  state : S,
  visit : (Polynomial, S) -> (S, Bool),
) -> Scan[S] {
  match lifts {
    Nil =>
      match fuel {
        Zero => Exhausted
        Succ(rest) => {
          let (next, stop) = visit(current, state)
          if stop {
            Stopped
          } else {
            Finished(next, rest)
          }
        }
      }
    Cons(head, tail) =>
      match scan_subsets(tail, current, modulus, fuel, state, visit) {
        Finished(next, rest) =>
          scan_subsets(
            tail,
            modulo(multiply(current, head), modulus),
            modulus,
            rest,
            next,
            visit,
          )
        other => other
      }
  }
}

///|
fn proper_degree(divisor : Polynomial, value : Polynomial) -> Bool {
  match (degree(divisor), degree(value)) {
    (Some(Succ(_) as a), Some(b)) => @core.compare(a, b).equal(Less)
    _ => false
  }
}

///|
fn recovered(
  subset : Polynomial,
  target : Polynomial,
  modulus : @modular.Modulus,
) -> Polynomial {
  match leading(target) {
    Some(lc) => {
      let (_, part) = primitive(centered(scale(subset, lc), modulus))
      part
    }
    None => zero()
  }
}

///|
fn primitive_positive(value : Polynomial) -> Bool {
  let (content, part) = primitive(value)
  content.equal(ione()) && part.equal(value)
}

///|
fn valid_irreducibility_data(certificate : IrreducibilityCertificate) -> Bool {
  fn finite(
    factors : @core.Chain[@fppoly.Polynomial],
    certificates : @core.Chain[@fppoly.IrreducibilityCertificate],
  ) -> Bool {
    match (factors, certificates) {
      (Nil, Nil) => true
      (Cons(f, fs), Cons(c, cs)) =>
        @fppoly.check_irreducible(f, c) && finite(fs, cs)
      _ => false
    }
  }
  let data = certificate.lift
  primitive_positive(data.target) &&
  check_lift(data) &&
  @binary.compare(
    prime_power(data.prime, data.exponent),
    recombination_threshold(data.target),
  ).equal(Greater) &&
  finite(data.factors, certificate.finite_certificates)
}

///|
/// Certificate validation plus exhaustive bounded subset recombination.
/// Proven means irreducible over Q (equivalently a primitive irreducible in Z[x]).
/// Fuel exhaustion is Undecided; it never certifies irreducibility.
pub fn check_irreducible(
  value : Polynomial,
  certificate : IrreducibilityCertificate,
  fuel : @core.Nat,
) -> Verdict {
  if !primitive_positive(value) ||
    !(degree(value) is Some(Succ(_))) ||
    !valid_irreducibility_data(certificate) ||
    !(exact_divide(certificate.lift.target, value) is Some(_)) {
    Refuted
  } else {
    match
      @modular.modulus(
        prime_power(certificate.lift.prime, certificate.lift.exponent),
      ) {
      None => Refuted
      Some(modulus) =>
        match
          scan_subsets(certificate.lift.lifts, one(), modulus, fuel, (), fn(
            subset,
            _,
          ) {
            let candidate = recovered(subset, certificate.lift.target, modulus)
            (
              (),
              proper_degree(candidate, value) &&
              exact_divide(value, candidate) is Some(_),
            )
          }) {
          Finished(_, _) => Proven
          Stopped => Refuted
          Exhausted => Undecided
        }
    }
  }
}

///|
/// Only reconstructs the input. This deliberately makes no irreducibility claim.
pub fn check_product(value : Polynomial, result : Factorization) -> Bool {
  let reconstructed = @core.fold_left(
    result.factors,
    polynomial(Cons(result.content, Nil)),
    fn(acc, factor) {
      multiply(acc, power(factor.polynomial, factor.multiplicity))
    },
  )
  reconstructed.equal(value)
}

///|
/// Validate normalization, distinctness, reconstruction, and each factor's
/// irreducibility. The subset budget is per claimed irreducible factor.
pub fn check_factorization(
  value : Polynomial,
  result : Factorization,
  fuel : @core.Nat,
) -> Verdict {
  fn factors(values : @core.Chain[Factor]) -> Verdict {
    match values {
      Nil => Proven
      Cons(head, tail) =>
        if head.multiplicity.equal(Zero) ||
          @core.any(tail, fn(f) { f.polynomial.equal(head.polynomial) }) {
          Refuted
        } else {
          match
            (
              check_irreducible(head.polynomial, head.certificate, fuel),
              factors(tail),
            ) {
            (Refuted, _) | (_, Refuted) => Refuted
            (Undecided, _) | (_, Undecided) => Undecided
            _ => Proven
          }
        }
    }
  }
  if is_zero(value) || !check_product(value, result) {
    Refuted
  } else {
    factors(result.factors)
  }
}

///|
fn finite_certificates(
  factors : @core.Chain[@fppoly.Polynomial],
) -> @core.Chain[@fppoly.IrreducibilityCertificate]? {
  match factors {
    Nil => Some(Nil)
    Cons(head, rest) =>
      match (@fppoly.irreducibility(head), finite_certificates(rest)) {
        (Ok(Some(certificate)), Some(tail)) => Some(Cons(certificate, tail))
        _ => None
      }
  }
}

///|
fn choose_prime(
  value : Polynomial,
  primes : @core.Chain[@binary.Binary],
) -> Result[Lift?, AlgebraError] {
  match primes {
    Nil => Ok(None)
    Cons(prime, rest) =>
      match @primefield.field(prime) {
        None => choose_prime(value, rest)
        Some(field) => {
          let reduction = reduce(value, field)
          if !degree(value).equal(@fppoly.degree(reduction)) {
            choose_prime(value, rest)
          } else {
            match @fppoly.gcd(reduction, @fppoly.derivative(reduction)) {
              Err(_) => Err(InternalInvariant)
              Ok(gcd) =>
                if !gcd.equal(@fppoly.one(field)) {
                  choose_prime(value, rest)
                } else {
                  match @fppoly.factor(reduction) {
                    Err(_) => Err(InternalInvariant)
                    Ok(factorization) => {
                      let factors = @core.map(factorization.factors, fn(f) {
                        f.polynomial
                      })
                      match start_lift(value, factors) {
                        Ok(lift) => Ok(Some(lift))
                        Err(error) => Err(error)
                      }
                    }
                  }
                }
            }
          }
        }
      }
  }
}

///|
fn split_candidates(
  value : Polynomial,
  candidates : @core.Chain[Polynomial],
) -> @core.Chain[Polynomial] {
  fn find(values : @core.Chain[Polynomial]) -> (Polynomial, Polynomial)? {
    match values {
      Nil => None
      Cons(head, rest) =>
        if proper_degree(head, value) {
          match exact_divide(value, head) {
            Some(q) => Some((head, q))
            None => find(rest)
          }
        } else {
          find(rest)
        }
    }
  }
  match find(candidates) {
    None => Cons(value, Nil)
    Some((a, b)) =>
      @core.append(
        split_candidates(a, candidates),
        split_candidates(b, candidates),
      )
  }
}

///|
fn factor_component(
  component : SquareFreeFactor,
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
) -> Result[Result[@core.Chain[Factor], StopReason], AlgebraError] {
  let value = component.polynomial
  match choose_prime(value, primes) {
    Err(error) => Err(error)
    Ok(None) => Ok(Err(NoGoodPrime))
    Ok(Some(initial)) =>
      match lift_above(initial, recombination_threshold(value), lift_fuel) {
        Err(error) => Err(error)
        Ok(Suspended(_)) => Ok(Err(LiftBudget))
        Ok(Reached(lift)) => {
          let data = lift_certificate(lift)
          match finite_certificates(data.factors) {
            None => Err(InternalInvariant)
            Some(finite_certificates) => {
              let certificate : IrreducibilityCertificate = {
                lift: data,
                finite_certificates,
              }
              match
                scan_subsets(
                  data.lifts,
                  one(),
                  lift.modulus,
                  subset_fuel,
                  (@core.Nil : @core.Chain[Polynomial]),
                  fn(subset, candidates) {
                    let candidate = recovered(subset, value, lift.modulus)
                    if proper_degree(candidate, value) &&
                      exact_divide(value, candidate) is Some(_) &&
                      !@core.any(candidates, fn(p) { p.equal(candidate) }) {
                      (Cons(candidate, candidates), false)
                    } else {
                      (candidates, false)
                    }
                  },
                ) {
                Exhausted => Ok(Err(RecombinationBudget))
                Stopped => Err(InternalInvariant)
                Finished(candidates, _) => {
                  let factors = @core.map(split_candidates(value, candidates), fn(
                    polynomial,
                  ) {
                    {
                      polynomial,
                      multiplicity: component.multiplicity,
                      certificate,
                    }
                  })
                  Ok(Ok(factors))
                }
              }
            }
          }
        }
      }
  }
}

///|
/// Factor any nonzero univariate integer polynomial. Prime candidates are tried
/// in the supplied order; composite, degree-losing and nonsquarefree reductions
/// are skipped. Budgets apply separately to each square-free component.
pub fn factor(
  value : Polynomial,
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
) -> Result[Outcome, AlgebraError] {
  fn components(
    values : @core.Chain[SquareFreeFactor],
  ) -> Result[Result[@core.Chain[Factor], StopReason], AlgebraError] {
    match values {
      Nil => Ok(Ok(Nil))
      Cons(head, tail) =>
        match factor_component(head, primes, lift_fuel, subset_fuel) {
          Err(error) => Err(error)
          Ok(Err(reason)) => Ok(Err(reason))
          Ok(Ok(first)) =>
            match components(tail) {
              Ok(Ok(rest)) => Ok(Ok(@core.append(first, rest)))
              other => other
            }
        }
    }
  }
  match square_free(value) {
    Err(error) => Err(error)
    Ok(decomposition) =>
      match components(decomposition.components) {
        Err(error) => Err(error)
        Ok(Err(reason)) => Ok(Incomplete(reason))
        Ok(Ok(factors)) => {
          let result : Factorization = {
            content: decomposition.content,
            factors,
          }
          if check_product(value, result) {
            Ok(Complete(result))
          } else {
            Err(InternalInvariant)
          }
        }
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct RationalFactorization {
  unit : @exact.Rational
  factors : @core.Chain[Factor]
}

///|
pub extend RationalFactorization with Eq::{equal, not_equal}

///|
pub extend RationalFactorization with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum RationalOutcome {
  RationalComplete(RationalFactorization)
  RationalIncomplete(StopReason)
}

///|
pub extend RationalOutcome with Eq::{equal, not_equal}

///|
pub extend RationalOutcome with Debug::{to_repr}

///|
/// Clear denominators, factor over Z, and return primitive positive-leading
/// integer factors with a rational unit. Input coefficients are ascending.
pub fn factor_rational(
  values : @core.Chain[@exact.Rational],
  primes : @core.Chain[@binary.Binary],
  lift_fuel : @core.Nat,
  subset_fuel : @core.Nat,
) -> Result[RationalOutcome, AlgebraError] {
  let (denominator, value) = clear_denominators(values)
  match factor(value, primes, lift_fuel, subset_fuel) {
    Err(error) => Err(error)
    Ok(Incomplete(reason)) => Ok(RationalIncomplete(reason))
    Ok(Complete(result)) =>
      match @exact.ratio(result.content, denominator) {
        Some(unit) => Ok(RationalComplete({ unit, factors: result.factors, }))
        None => Err(InternalInvariant)
      }
  }
}

///|
pub fn check_rational_factorization(
  values : @core.Chain[@exact.Rational],
  result : RationalFactorization,
  fuel : @core.Nat,
) -> Verdict {
  let (denominator, value) = clear_denominators(values)
  let scaled_unit = @exact.rational_multiply(
    result.unit,
    @exact.whole(@exact.positive(denominator)),
  )
  if !@exact.denominator(scaled_unit).equal(@binary.one()) {
    Refuted
  } else {
    check_factorization(
      value,
      { content: @exact.numerator(scaled_unit), factors: result.factors, },
      fuel,
    )
  }
}
