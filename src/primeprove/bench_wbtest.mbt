///|
fn completed(machine : Machine, fuel : @core.Nat) -> Proof {
  match run(machine, fuel) {
    Proven(proof) => proof
    _ => abort("benchmark proof must complete")
  }
}

///|
test "generate Lucas proof 65537 without a certificate bank" (b : @bench.T) {
  let machine = begun(65537, defaults())
  let fuel = @oracle.nat(20000)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}

///|
test "recheck generated Lucas proof 65537" (b : @bench.T) {
  let proof = completed(begun(65537, defaults()), @oracle.nat(20000))
  let certificate = certificate(proof)
  b.bench(fn() { b.keep(@primality.check(certificate)) })
}

///|
test "generate Lucas proof 998244353 without a certificate bank" (b : @bench.T) {
  let machine = begun(998244353, defaults())
  let fuel = @oracle.nat(20000)
  b.bench(fn() { b.keep(run(machine, fuel)) })
}

///|
test "recheck generated Lucas proof 998244353" (b : @bench.T) {
  let proof = completed(begun(998244353, defaults()), @oracle.nat(20000))
  let certificate = certificate(proof)
  b.bench(fn() { b.keep(@primality.check(certificate)) })
}
