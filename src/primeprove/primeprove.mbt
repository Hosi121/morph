///|
/// Finite strategy inputs, with no prime certificate bank. Trial candidates are
/// inclusive up to trial_limit; strong bases and rho seed pairs are explicit.
#derive(Eq, Debug)
pub(all) struct Config {
  trial_limit : @binary.Binary
  bases : @core.Chain[@binary.Binary]
  seeds : @core.Chain[(@binary.Binary, @binary.Binary)]
}

///|
pub extend Config with Eq::{equal, not_equal}

///|
pub extend Config with Debug::{to_repr}

///|
pub fn defaults() -> Config {
  let one = @binary.one()
  let two = @binary.double(one)
  let three = @binary.successor(two)
  let five = @binary.successor(@binary.double(two))
  let seven = @binary.successor(@binary.double(three))
  {
    trial_limit: @binary.double(@binary.double(@binary.double(two))),
    bases: Cons(two, Cons(three, Cons(five, Cons(seven, Nil)))),
    seeds: Cons((two, one), Cons((two, two), Cons((two, three), Nil))),
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Uncertainty {
  NoFactor(@binary.Binary)
  NoWitness(@binary.Binary)
  Invariant
}

///|
pub extend Uncertainty with Eq::{equal, not_equal}

///|
pub extend Uncertainty with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub enum Control {
  Prove(@binary.Binary)
  Screen(@binary.Binary, @core.Chain[@binary.Binary])
  Factor(@binary.Binary)
  Trial(@binary.Binary, @binary.Binary)
  StartRho(@binary.Binary)
  Rho(@factor.Machine, @core.Chain[(@binary.Binary, @binary.Binary)])
  Witness(@binary.Binary, @core.Chain[@primality.Certificate], @binary.Binary)
  PrimeValue(@primality.Certificate)
  CompositeValue(@primality.CompositeProof)
  FactorsValue(@core.Chain[@primality.Certificate])
  Unknown(Uncertainty)
}

///|
pub extend Control with Eq::{equal, not_equal}

///|
pub extend Control with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub enum Frame {
  Predecessor(@binary.Binary)
  FactorCandidate(@binary.Binary)
  RightPart(@binary.Binary)
  Join(@core.Chain[@primality.Certificate])
}

///|
pub extend Frame with Eq::{equal, not_equal}

///|
pub extend Frame with Debug::{to_repr}

///|
/// All recursion, partial factor certificates, witness cursors and rho states
/// are explicit immutable data, so fuel suspension preserves exact progress.
#derive(Eq, Debug)
pub struct Machine {
  number : @binary.Binary
  config : Config
  control : Control
  continuation : @core.Chain[Frame]
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
/// Generated evidence, rechecked against the original number before returning.
#derive(Eq, Debug)
pub struct Proof {
  certificate : @primality.Certificate
  prime : @primality.Prime
}

///|
pub extend Proof with Eq::{equal, not_equal}

///|
pub extend Proof with Debug::{to_repr}

///|
pub fn certificate(proof : Proof) -> @primality.Certificate {
  proof.certificate
}

///|
pub fn prime(proof : Proof) -> @primality.Prime {
  proof.prime
}

///|
pub fn subject(machine : Machine) -> @binary.Binary {
  machine.number
}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Proven(Proof)
  Composite(@primality.CompositeProof)
  Suspended(Machine)
  Inconclusive(Uncertainty, Machine)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
pub fn start(number : @binary.Binary, config : Config) -> Machine? {
  match @binary.compare(number, @binary.one()) {
    Greater =>
      Some({ number, config, control: Prove(number), continuation: Nil, })
    _ => None
  }
}

///|
/// Changing the strategy is explicit and restarts the original subject. Fuel
/// continuation instead uses run on a Suspended machine without restarting.
pub fn restart(machine : Machine, config : Config) -> Machine {
  {
    number: machine.number,
    config,
    control: Prove(machine.number),
    continuation: Nil,
  }
}

///|
/// One explicit transition. A transition may include exact arithmetic, one
/// strong-base check, a rho iteration, or one complete Lucas witness check.
pub fn step(machine : Machine) -> Status {
  let continuation = machine.continuation
  let two = @binary.double(@binary.one())
  fn next(control : Control, continuation : @core.Chain[Frame]) -> Status {
    Suspended({ ..machine, control, continuation, })
  }
  fn split(number : @binary.Binary, divisor : @binary.Binary) -> Status {
    match @factor.check_factor(number, divisor) {
      Some(split) =>
        next(
          Factor(@factor.divisor(split)),
          Cons(RightPart(@factor.cofactor(split)), continuation),
        )
      None => next(Unknown(Invariant), continuation)
    }
  }
  match machine.control {
    Prove(number) =>
      match @binary.compare(number, two) {
        Equal => next(PrimeValue(@primality.Two), continuation)
        Greater =>
          match @primality.check_composite(number, @primality.Divisor(two)) {
            Some(proof) => next(CompositeValue(proof), continuation)
            None => next(Screen(number, machine.config.bases), continuation)
          }
        Less => next(Unknown(Invariant), continuation)
      }
    Screen(number, bases) =>
      match bases {
        Cons(base, rest) =>
          match @primality.check_composite(number, @primality.Strong(base)) {
            Some(proof) => next(CompositeValue(proof), continuation)
            None => next(Screen(number, rest), continuation)
          }
        Nil =>
          match @binary.subtract(number, @binary.one()) {
            Some(predecessor) =>
              next(Factor(predecessor), Cons(Predecessor(number), continuation))
            None => next(Unknown(Invariant), continuation)
          }
      }
    Factor(number) =>
      match @binary.compare(number, @binary.one()) {
        Equal => next(FactorsValue(Nil), continuation)
        Greater =>
          match @binary.compare(number, two) {
            Equal => next(FactorsValue(Cons(@primality.Two, Nil)), continuation)
            _ => next(Trial(number, two), continuation)
          }
        Less => next(Unknown(Invariant), continuation)
      }
    Trial(number, divisor) => {
      let stop = @binary.compare(@binary.multiply(divisor, divisor), number)
        is Greater ||
        @binary.compare(divisor, machine.config.trial_limit) is Greater
      match stop {
        true => next(Prove(number), Cons(FactorCandidate(number), continuation))
        false =>
          match @factor.check_factor(number, divisor) {
            Some(_) => split(number, divisor)
            None =>
              next(Trial(number, @binary.successor(divisor)), continuation)
          }
      }
    }
    StartRho(number) =>
      match machine.config.seeds {
        Nil => next(Unknown(NoFactor(number)), continuation)
        Cons((seed, constant), rest) =>
          match @factor.start(number, seed, constant) {
            Some(rho) => next(Rho(rho, rest), continuation)
            None => next(Unknown(Invariant), continuation)
          }
      }
    Rho(rho, seeds) =>
      match @factor.step(rho) {
        Found(found) => split(@factor.number(found), @factor.divisor(found))
        Suspended(next_rho) => next(Rho(next_rho, seeds), continuation)
        Failed(failed) =>
          match seeds {
            Nil => next(Unknown(NoFactor(@factor.target(failed))), continuation)
            Cons((seed, constant), rest) =>
              match @factor.start(@factor.target(failed), seed, constant) {
                Some(next_rho) => next(Rho(next_rho, rest), continuation)
                None => next(Unknown(Invariant), continuation)
              }
          }
      }
    Witness(number, factors, witness) =>
      match @binary.compare(witness, number) {
        Less => {
          let certificate = @primality.Lucas(number, witness, factors)
          match @primality.check(certificate) {
            Some(_) => next(PrimeValue(certificate), continuation)
            None =>
              next(
                Witness(number, factors, @binary.successor(witness)),
                continuation,
              )
          }
        }
        _ => next(Unknown(NoWitness(number)), continuation)
      }
    PrimeValue(certificate) =>
      match @primality.check(certificate) {
        None => next(Unknown(Invariant), continuation)
        Some(prime) =>
          match continuation {
            Nil =>
              match @binary.compare(@primality.value(prime), machine.number) {
                Equal => Proven({ certificate, prime, })
                _ => next(Unknown(Invariant), Nil)
              }
            Cons(FactorCandidate(number), rest) =>
              match @binary.compare(@primality.value(prime), number) {
                Equal => next(FactorsValue(Cons(certificate, Nil)), rest)
                _ => next(Unknown(Invariant), rest)
              }
            Cons(_, rest) => next(Unknown(Invariant), rest)
          }
      }
    CompositeValue(proof) =>
      match continuation {
        Nil =>
          match
            @primality.check_composite(
              machine.number,
              @primality.composite_witness(proof),
            ) {
            Some(proof) => Composite(proof)
            None => next(Unknown(Invariant), Nil)
          }
        Cons(FactorCandidate(number), rest) =>
          match @binary.compare(@primality.composite_value(proof), number) {
            Equal =>
              match @primality.composite_witness(proof) {
                Divisor(divisor) =>
                  match @factor.check_factor(number, divisor) {
                    Some(found) =>
                      next(
                        Factor(@factor.divisor(found)),
                        Cons(RightPart(@factor.cofactor(found)), rest),
                      )
                    None => next(Unknown(Invariant), rest)
                  }
                Strong(_) => next(StartRho(number), rest)
              }
            _ => next(Unknown(Invariant), rest)
          }
        Cons(_, rest) => next(Unknown(Invariant), rest)
      }
    FactorsValue(factors) =>
      match continuation {
        Cons(Predecessor(number), rest) =>
          next(Witness(number, factors, two), rest)
        Cons(RightPart(right), rest) =>
          next(Factor(right), Cons(Join(factors), rest))
        Cons(Join(left), rest) =>
          next(FactorsValue(@core.append(left, factors)), rest)
        _ => next(Unknown(Invariant), continuation)
      }
    Unknown(reason) =>
      match continuation {
        Nil => Inconclusive(reason, machine)
        Cons(FactorCandidate(number), rest) => next(StartRho(number), rest)
        Cons(_, rest) => next(Unknown(reason), rest)
      }
  }
}

///|
/// Fuel bounds transitions, not bit operations, allocation, or wall-clock time.
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
