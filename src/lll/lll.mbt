///|
#derive(Eq, Debug)
pub enum Phase {
  Reducing(@core.Nat, @core.Nat)
  Testing(@core.Nat)
}

///|
pub extend Phase with Eq::{equal, not_equal}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Machine {
  input : @matrix.Matrix[@exact.Integer]
  basis : @matrix.Matrix[@exact.Integer]
  transform : @matrix.Matrix[@exact.Integer]
  phase : Phase
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Done(Reduction)
  Paused(Machine)
  Fault(Machine)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
/// Reject dependent rows exactly. Empty row bases are valid in any dimension.
pub fn start(input : @matrix.Matrix[@exact.Integer]) -> Machine? {
  match gram_schmidt(input) {
    None => None
    Some(gram) =>
      match check_gram(input, gram) {
        false => None
        true =>
          Some({
            input,
            basis: input,
            transform: @matrix.identity(@matrix.height(input), integers()),
            phase: Reducing(Succ(Zero), Succ(Zero)),
          })
      }
  }
}

///|
/// One size-reduction candidate, phase move, Lovasz test/swap or final checker.
/// The Gram-Schmidt arithmetic inside one transition is not a constant cost.
pub fn step(machine : Machine) -> Status {
  fn done() -> Status {
    match check(machine.input, machine.transform, machine.basis) {
      Some(reduction) => Done(reduction)
      None => Fault(machine)
    }
  }
  match machine.phase {
    Reducing(current, remaining) =>
      match @core.compare(current, @matrix.height(machine.basis)) {
        Less =>
          match remaining {
            Zero => Paused({ ..machine, phase: Testing(current), })
            Succ(previous) =>
              match gram_schmidt(machine.basis) {
                None => Fault(machine)
                Some(gram) =>
                  match coefficient(gram, current, previous) {
                    None => Fault(machine)
                    Some(value) =>
                      match size_bounded(value) {
                        true =>
                          Paused({
                            ..machine,
                            phase: Reducing(current, previous),
                          })
                        false => {
                          let q = nearest(value)
                          match
                            (
                              row_reduce(machine.basis, current, previous, q),
                              row_reduce(
                                machine.transform,
                                current,
                                previous,
                                q,
                              ),
                            ) {
                            (Some(basis), Some(transform)) =>
                              Paused({
                                ..machine,
                                basis,
                                transform,
                                phase: Reducing(current, previous),
                              })
                            _ => Fault(machine)
                          }
                        }
                      }
                  }
              }
          }
        _ => done()
      }
    Testing(current) =>
      match current {
        Zero => Fault(machine)
        Succ(previous) =>
          match gram_schmidt(machine.basis) {
            None => Fault(machine)
            Some(gram) =>
              match lovasz(gram, current, previous) {
                true =>
                  Paused({
                    ..machine,
                    phase: Reducing(Succ(current), Succ(current)),
                  })
                false =>
                  match
                    (
                      row_swap(machine.basis, current, previous),
                      row_swap(machine.transform, current, previous),
                    ) {
                    (Some(basis), Some(transform)) => {
                      let current : @core.Nat = match previous {
                        Zero => Succ(Zero)
                        Succ(_) => previous
                      }
                      Paused({
                        ..machine,
                        basis,
                        transform,
                        phase: Reducing(current, current),
                      })
                    }
                    _ => Fault(machine)
                  }
              }
          }
      }
  }
}

///|
pub fn run(machine : Machine, fuel : @core.Nat) -> Status {
  match fuel {
    Zero => Paused(machine)
    Succ(rest) =>
      match step(machine) {
        Paused(next) => run(next, rest)
        result => result
      }
  }
}
