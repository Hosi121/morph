///|
/// Use the shared structural conversion; the original private prototype is
/// retained only in white-box tests and conversion benchmarks.
fn binary_key(value : @core.Nat) -> @binary.Binary {
  @binary.from_nat(value)
}
