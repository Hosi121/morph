///|
/// Odd prime field, with p-one = odd_part * two^two_power and a nonresidue.
/// Construction uses exact trial-division primality, intended for small fields.
#derive(Eq, Debug)
pub struct Field {
  modulus : @modular.Modulus
  odd_part : @binary.Binary
  two_power : @core.Nat
  euler_exponent : @binary.Binary
  nonresidue : @binary.Binary
}

///|
pub extend Field with Eq::{equal, not_equal}

///|
pub extend Field with Debug::{to_repr}

///|
pub fn field(p : @binary.Binary) -> Field? {
  fn factor(
    n : @binary.Binary,
    count : @core.Nat,
  ) -> (@binary.Binary, @core.Nat) {
    match @binary.odd(n) {
      true => (n, count)
      false => factor(@binary.half(n), Succ(count))
    }
  }
  match
    (
      @binary.compare(p, @binary.double(@binary.one())),
      @modular.is_prime(p),
      @modular.modulus(p),
    ) {
    (Greater, true, Some(modulus)) =>
      match @binary.subtract(p, @binary.one()) {
        None => None
        Some(previous) => {
          let exponent = @binary.half(previous)
          fn find(candidate : @binary.Binary) -> @binary.Binary? {
            match @binary.compare(candidate, p) {
              Less =>
                match
                  @binary.compare(
                    @modular.power(modulus, candidate, exponent),
                    previous,
                  ) {
                  Equal => Some(candidate)
                  _ => find(@binary.successor(candidate))
                }
              _ => None
            }
          }
          match find(@binary.double(@binary.one())) {
            None => None
            Some(nonresidue) => {
              let (odd_part, two_power) = factor(previous, Zero)
              Some({
                modulus,
                odd_part,
                two_power,
                euler_exponent: exponent,
                nonresidue,
              })
            }
          }
        }
      }
    _ => None
  }
}

///|
pub fn modulus(field : Field) -> @modular.Modulus {
  field.modulus
}

///|
#derive(Eq, Debug)
pub(all) enum Character {
  Zero
  Residue
  Nonresidue
}

///|
pub extend Character with Eq::{equal, not_equal}

///|
pub extend Character with Debug::{to_repr}

///|
pub fn character(field : Field, value : @binary.Binary) -> Character {
  match @binary.is_zero(@modular.reduce(field.modulus, value)) {
    true => Zero
    false =>
      match
        @binary.compare(
          @modular.power(field.modulus, value, field.euler_exponent),
          @binary.one(),
        ) {
        Equal => Residue
        _ => Nonresidue
      }
  }
}

///|
/// Tonelli-Shanks, returning the smaller of the two roots in the canonical range.
pub fn sqrt(field : Field, value : @binary.Binary) -> @binary.Binary? {
  let modulus = field.modulus
  let value = @modular.reduce(modulus, value)
  fn square_times(x : @binary.Binary, count : @core.Nat) -> @binary.Binary {
    match count {
      Zero => x
      Succ(rest) => square_times(@modular.multiply(modulus, x, x), rest)
    }
  }
  fn least_power(
    t : @binary.Binary,
    index : @core.Nat,
    remaining : @core.Nat,
  ) -> @core.Nat? {
    match @binary.compare(t, @binary.one()) {
      Equal => Some(index)
      _ =>
        match remaining {
          Zero => None
          Succ(rest) =>
            least_power(@modular.multiply(modulus, t, t), Succ(index), rest)
        }
    }
  }
  fn correct(
    c : @binary.Binary,
    x : @binary.Binary,
    t : @binary.Binary,
    m : @core.Nat,
  ) -> @binary.Binary? {
    match @binary.compare(t, @binary.one()) {
      Equal => Some(x)
      _ =>
        match least_power(t, Zero, m) {
          None => None
          Some(i) =>
            match @core.compare(i, m) {
              Less => {
                let b = square_times(c, @core.subtract(m, Succ(i)))
                let square = @modular.multiply(modulus, b, b)
                correct(
                  square,
                  @modular.multiply(modulus, x, b),
                  @modular.multiply(modulus, t, square),
                  i,
                )
              }
              _ => None
            }
        }
    }
  }
  match character(field, value) {
    Zero => Some(@binary.zero())
    Nonresidue => None
    Residue => {
      let c = @modular.power(modulus, field.nonresidue, field.odd_part)
      let t = @modular.power(modulus, value, field.odd_part)
      let x = @modular.power(
        modulus,
        value,
        @binary.half(@binary.successor(field.odd_part)),
      )
      match correct(c, x, t, field.two_power) {
        None => None
        Some(root) =>
          match @binary.compare(@modular.multiply(modulus, root, root), value) {
            Equal =>
              match @binary.subtract(@modular.value(modulus), root) {
                None => None
                Some(other) =>
                  Some(
                    match @binary.compare(root, other) {
                      Greater => other
                      _ => root
                    },
                  )
              }
            _ => None
          }
      }
    }
  }
}
