///|
fn trial_split(number : @binary.Binary) -> Split? {
  fn search(divisor : @binary.Binary) -> Split? {
    match @binary.compare(@binary.multiply(divisor, divisor), number) {
      Greater => None
      _ =>
        match check_factor(number, divisor) {
          Some(split) => Some(split)
          None => search(@binary.successor(divisor))
        }
    }
  }
  search(@binary.double(@binary.one()))
}

///|
test "rho split 1022117 seed two c one fuel 256" (b : @bench.T) {
  let machine = trajectory(1022117, 2, 1)
  let fuel = @oracle.nat(256)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}

///|
test "trial split 1022117 excluding input construction" (b : @bench.T) {
  let number = @oracle.binary(1022117)
  b.bench(fn() { b.keep(trial_split(number)) })
}

///|
test "rho split 100160063 seed two c one fuel 256" (b : @bench.T) {
  let machine = trajectory(100160063, 2, 1)
  let fuel = @oracle.nat(256)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}

///|
test "trial split 100160063 excluding input construction" (b : @bench.T) {
  let number = @oracle.binary(100160063)
  b.bench(fn() { b.keep(trial_split(number)) })
}
