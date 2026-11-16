///|
pub fn start(compilation : Compilation) -> Machine {
  { compilation, solver: @parity.start(compilation.game), }
}

///|
/// Fuel has exactly the parity solver's frame-step meaning. Its Complete path
/// already checks the positional certificate with the independent cycle checker.
pub fn run(machine : Machine, fuel : @core.Nat) -> Progress {
  match @parity.run(machine.solver, fuel) {
    Paused(solver) => Paused({ ..machine, solver, })
    Fault => Fault
    Complete(parity) => Complete({ compilation: machine.compilation, parity, })
  }
}

///|
pub fn step(machine : Machine) -> Progress {
  run(machine, Succ(Zero))
}

///|
pub fn certificate(solution : Solution) -> @parity.Certificate {
  @parity.certificate(solution.parity)
}

///|
/// Check the strategy certificate for the concrete compiled game. This checks
/// parity-game semantics; formula-to-game compilation remains a trust boundary.
pub fn checked(
  compilation : Compilation,
  certificate : @parity.Certificate,
) -> Solution? {
  match @parity.checked(compilation.game, certificate) {
    None => None
    Some(parity) => Some({ compilation, parity, })
  }
}

///|
pub fn holds(solution : Solution, state_id : @core.Nat) -> Bool? {
  match position_id(solution.compilation, state_id, Zero) {
    None => None
    Some(position) =>
      match @parity.winner(solution.parity, position) {
        Some(EvenPlayer) => Some(true)
        Some(OddPlayer) => Some(false)
        None => None
      }
  }
}

///|
pub fn satisfying_states(solution : Solution) -> @core.Chain[@core.Nat] {
  @core.map(
    @core.filter(solution.compilation.model.states, fn(state) {
      match holds(solution, state.id) {
        Some(true) => true
        _ => false
      }
    }),
    fn(state) { state.id },
  )
}
