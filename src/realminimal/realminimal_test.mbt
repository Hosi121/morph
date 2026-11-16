///|
test "public explicit minimal normalization binds original and returned Numbers" {
  let original = @real.rational(@oracle.rational(2, 3)).unwrap()
  let primes = @oracle.chain([2, 3, 5, 7].map(@oracle.binary))
  match
    @realminimal.normalize(
      original,
      primes,
      @oracle.nat(30),
      @oracle.nat(128),
      @oracle.nat(128),
    ).unwrap() {
    @realminimal.Normalized(value, proof) => {
      assert_eq(@realminimal.check(proof, @oracle.nat(128)), @zass.Proven)
      assert_eq(
        @realminimal.check_result(value, proof, @oracle.nat(128)),
        @zass.Proven,
      )
      assert_eq(
        @realminimal.check_normalization(
          original,
          value,
          proof,
          @oracle.nat(128),
        ),
        @zass.Proven,
      )
      let wrong = @real.rational(@oracle.rational(3, 2)).unwrap()
      assert_eq(
        @realminimal.check_result(wrong, proof, @oracle.nat(128)),
        @zass.Refuted,
      )
      match @real.compare(original, value, @core.Zero).unwrap() {
        @real.Compared(order, comparison) => {
          assert_eq(order, @core.Equal)
          assert_true(@real.check_comparison_result(order, comparison))
        }
        _ => fail("same selected root")
      }
    }
    _ => fail("public rational fixture unresolved")
  }
}
