///|
/// A proper divisor or an odd-candidate strong Miller-Rabin witness.
/// Passing a strong test is deliberately absent from the proof language.
#derive(Eq, Debug)
pub(all) enum CompositeWitness {
  Divisor(@binary.Binary)
  Strong(@binary.Binary)
}

///|
pub extend CompositeWitness with Eq::{equal, not_equal}

///|
pub extend CompositeWitness with Debug::{to_repr}

///|
/// A compositeness claim accepted by a search-free checker.
#derive(Eq, Debug)
pub struct CompositeProof {
  number : @binary.Binary
  witness : CompositeWitness
}

///|
pub extend CompositeProof with Eq::{equal, not_equal}

///|
pub extend CompositeProof with Debug::{to_repr}

///|
pub fn composite_value(proof : CompositeProof) -> @binary.Binary {
  proof.number
}

///|
pub fn composite_witness(proof : CompositeProof) -> CompositeWitness {
  proof.witness
}

///|
fn strong_witness(n : @binary.Binary, base : @binary.Binary) -> Bool {
  let two = @binary.double(@binary.one())
  match
    (
      @binary.compare(n, two),
      @binary.odd(n),
      @binary.compare(base, @binary.one()),
      @binary.compare(base, n),
    ) {
    (Greater, true, Equal | Greater, Less) =>
      match (@modular.modulus(n), @binary.subtract(n, @binary.one())) {
        (Some(modulus), Some(minus_one)) => {
          fn decompose(
            odd_part : @binary.Binary,
            twos : @core.Nat,
          ) -> (@binary.Binary, @core.Nat) {
            match @binary.odd(odd_part) {
              true => (odd_part, twos)
              false => decompose(@binary.half(odd_part), Succ(twos))
            }
          }
          let (odd_part, twos) = decompose(minus_one, Zero)
          let initial = @modular.power(modulus, base, odd_part)
          fn reaches_minus_one(
            residue : @binary.Binary,
            remaining : @core.Nat,
          ) -> Bool {
            match remaining {
              Zero => false
              Succ(rest) =>
                match @binary.compare(residue, minus_one) {
                  Equal => true
                  _ =>
                    reaches_minus_one(
                      @modular.multiply(modulus, residue, residue),
                      rest,
                    )
                }
            }
          }
          !(@binary.compare(initial, @binary.one()) is Equal) &&
          !reaches_minus_one(initial, twos)
        }
        _ => false
      }
    _ => false
  }
}

///|
/// None means that this witness failed; it is never a prime verdict.
/// Strong witnesses require odd n greater than two and a base in [one,n).
pub fn check_composite(
  number : @binary.Binary,
  witness : CompositeWitness,
) -> CompositeProof? {
  let valid = match witness {
    Divisor(divisor) =>
      match
        (
          @binary.compare(divisor, @binary.one()),
          @binary.compare(divisor, number),
          @binary.divmod(number, divisor),
        ) {
        (Greater, Less, Some((_, remainder))) => @binary.is_zero(remainder)
        _ => false
      }
    Strong(base) => strong_witness(number, base)
  }
  match valid {
    true => Some({ number, witness, })
    false => None
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Screening {
  Composite(CompositeProof)
  Inconclusive
}

///|
pub extend Screening with Eq::{equal, not_equal}

///|
pub extend Screening with Debug::{to_repr}

///|
/// Check an even divisor, then each supplied strong base in order.
/// Out-of-range bases supply no evidence. No passing case is promoted to Prime.
pub fn screen(
  number : @binary.Binary,
  bases : @core.Chain[@binary.Binary],
) -> Screening {
  match check_composite(number, Divisor(@binary.double(@binary.one()))) {
    Some(proof) => Composite(proof)
    None => {
      fn try_bases(bases : @core.Chain[@binary.Binary]) -> Screening {
        match bases {
          Nil => Inconclusive
          Cons(base, rest) =>
            match check_composite(number, Strong(base)) {
              Some(proof) => Composite(proof)
              None => try_bases(rest)
            }
        }
      }
      try_bases(bases)
    }
  }
}
