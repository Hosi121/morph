///|
/// A canonical congruence class with period greater than one.
#derive(Eq, Debug)
pub struct Congruence {
  modulus : Modulus
  residue : @binary.Binary
}

///|
pub extend Congruence with Eq::{equal, not_equal}

///|
pub extend Congruence with Debug::{to_repr}

///|
pub fn congruence(modulus : Modulus, residue : @binary.Binary) -> Congruence {
  { modulus, residue: reduce(modulus, residue), }
}

///|
pub fn period(class : Congruence) -> Modulus {
  class.modulus
}

///|
pub fn residue(class : Congruence) -> @binary.Binary {
  class.residue
}

///|
/// Generalized Chinese remainder theorem, including non-coprime periods.
/// None means inconsistent congruences. The result period is their LCM.
pub fn chinese_remainder(a : Congruence, b : Congruence) -> Congruence? {
  let m = a.modulus.value
  let n = b.modulus.value
  let (g, x, _) = extended_gcd(m, n)
  let difference = @exact.subtract(
    @exact.positive(b.residue),
    @exact.positive(a.residue),
  )
  match
    (@binary.divmod(@exact.magnitude(difference), g), @binary.divmod(n, g)) {
    (Some((quotient, remainder)), Some((reduced_period, _))) =>
      match @binary.is_zero(remainder) {
        false => None
        true => {
          let magnitude = @exact.positive(quotient)
          let delta = match @exact.negative(difference) {
            true => @exact.negate(magnitude)
            false => magnitude
          }
          let coefficient = @exact.multiply(delta, x)
          let k = match modulus(reduced_period) {
            Some(modulus) => signed_reduce(modulus, coefficient)
            None => @binary.zero()
          }
          match modulus(@binary.multiply(m, reduced_period)) {
            None => None
            Some(period) =>
              Some(
                congruence(
                  period,
                  @binary.add(a.residue, @binary.multiply(m, k)),
                ),
              )
          }
        }
      }
    _ => None
  }
}

///|
/// Nonempty lists only: the unconstrained period-one class is outside Modulus.
pub fn chinese_remainders(classes : @core.Chain[Congruence]) -> Congruence? {
  match classes {
    Nil => None
    Cons(first, rest) =>
      @core.fold_left(rest, Some(first), fn(current, next) {
        match current {
          None => None
          Some(current) => chinese_remainder(current, next)
        }
      })
  }
}
