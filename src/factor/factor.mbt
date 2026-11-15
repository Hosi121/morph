///|
/// A checked proper factorization n = divisor * cofactor, with both factors > one.
/// Neither factor is claimed prime.
#derive(Eq, Debug)
pub struct Split {
  number : @binary.Binary
  divisor : @binary.Binary
  cofactor : @binary.Binary
}

///|
pub extend Split with Eq::{equal, not_equal}

///|
pub extend Split with Debug::{to_repr}

///|
pub fn number(split : Split) -> @binary.Binary {
  split.number
}

///|
pub fn divisor(split : Split) -> @binary.Binary {
  split.divisor
}

///|
pub fn cofactor(split : Split) -> @binary.Binary {
  split.cofactor
}

///|
/// A search-free checker for a nontrivial divisor. Invalid claims return None.
pub fn check_factor(
  number : @binary.Binary,
  divisor : @binary.Binary,
) -> Split? {
  match
    (@binary.compare(divisor, @binary.one()), @binary.compare(divisor, number)) {
    (Greater, Less) =>
      match @binary.divmod(number, divisor) {
        Some((cofactor, remainder)) =>
          match @binary.is_zero(remainder) {
            true => Some({ number, divisor, cofactor, })
            false => None
          }
        None => None
      }
    _ => None
  }
}

///|
/// One deterministic Floyd rho trajectory for f(x) = x*x + constant modulo n.
/// Immutable state retains the exact transition boundary for resumption.
#derive(Eq, Debug)
pub struct Machine {
  modulus : @modular.Modulus
  constant : @binary.Binary
  slow : @binary.Binary
  fast : @binary.Binary
  iterations : @core.Nat
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Found(Split)
  Suspended(Machine)
  Failed(Machine)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
/// No random seed, implicit retry, trial primality test, or external oracle.
pub fn start(
  number : @binary.Binary,
  seed : @binary.Binary,
  constant : @binary.Binary,
) -> Machine? {
  match @modular.modulus(number) {
    None => None
    Some(modulus) => {
      let point = @modular.reduce(modulus, seed)
      Some({
        modulus,
        constant: @modular.reduce(modulus, constant),
        slow: point,
        fast: point,
        iterations: Zero,
      })
    }
  }
}

///|
pub fn target(machine : Machine) -> @binary.Binary {
  @modular.value(machine.modulus)
}

///|
pub fn iterations(machine : Machine) -> @core.Nat {
  machine.iterations
}

///|
/// One Floyd iteration: three polynomial evaluations and a GCD. Even targets
/// yield their proper factor two directly. GCD equal to n ends this trajectory.
pub fn step(machine : Machine) -> Status {
  let n = target(machine)
  let two = @binary.double(@binary.one())
  match (@binary.odd(n), check_factor(n, two)) {
    (false, Some(split)) => Found(split)
    _ => {
      fn advance(point : @binary.Binary) -> @binary.Binary {
        @modular.add(
          machine.modulus,
          @modular.multiply(machine.modulus, point, point),
          machine.constant,
        )
      }
      let slow = advance(machine.slow)
      let fast = advance(advance(machine.fast))
      let next = {
        modulus: machine.modulus,
        constant: machine.constant,
        slow,
        fast,
        iterations: Succ(machine.iterations),
      }
      let difference = @modular.subtract(machine.modulus, slow, fast)
      let divisor = @binary.gcd(difference, n)
      match @binary.compare(divisor, @binary.one()) {
        Equal => Suspended(next)
        _ =>
          match check_factor(n, divisor) {
            Some(split) => Found(split)
            None => Failed(next)
          }
      }
    }
  }
}

///|
/// Fuel counts Floyd iterations, rather than bit operations or wall-clock time.
/// Zero fuel preserves the exact state. Failed means only this seed collided.
pub fn run(machine : Machine, fuel : @core.Nat) -> Status {
  match fuel {
    Zero => Suspended(machine)
    Succ(rest) =>
      match step(machine) {
        Suspended(next) => run(next, rest)
        result => result
      }
  }
}
