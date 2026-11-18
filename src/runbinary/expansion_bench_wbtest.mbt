///|
// Frozen expansion path from 1931625, before fusing a homogeneous prefix.
fn expansion_reference(
  value : Number,
  maximum_bits : @binary.Binary,
) -> @binary.Binary? {
  match @binary.compare(width(value), maximum_bits) {
    Greater => None
    _ => {
      let reversed : @core.Chain[Bool] = @core.fold_left(
        value.runs,
        @core.Nil,
        fn(reversed, run) {
          @core.reverse_onto(
            @core.replicate(@binary.to_nat(run.length), run.bit),
            reversed,
          )
        },
      )
      Some(@binary.from_bits(@core.reverse(reversed)))
    }
  }
}

///|
test "bounded expansion before and after prefix fusion" (b : @bench.T) {
  let homogeneous = from_runs(
    @core.Cons({ bit: true, length: @oracle.binary(4096), }, Nil),
  )
  let mixed = from_runs(
    @oracle.chain([
      Run::{ bit: false, length: @oracle.binary(1023), },
      { bit: true, length: @oracle.binary(1025), },
      { bit: false, length: @oracle.binary(1025), },
      { bit: true, length: @oracle.binary(1023), },
    ]),
  )
  let alternating = from_binary(
    @binary.from_bits(@oracle.chain(Array::makei(2048, fn(i) { i % 2 == 1 }))),
  )
  for
    (name, value) in [
      ("homogeneous4096", homogeneous),
      ("mixed4096", mixed),
      ("alternating2048", alternating),
    ] {
    let maximum = width(value)
    let expected = expansion_reference(value, maximum)
    assert_eq(expand(value, maximum), expected)
    assert_eq(from_binary(expected.unwrap()), value)
    for block in 0..<5 {
      for candidate in [false, true, true, false] {
        if candidate {
          b.bench(
            name="\{name}/block\{block}/candidate",
            fn() { b.keep(expand(value, maximum)) },
            count=5,
          )
        } else {
          b.bench(
            name="\{name}/block\{block}/reference",
            fn() { b.keep(expansion_reference(value, maximum)) },
            count=5,
          )
        }
      }
    }
  }
  println(b.dump_summaries())
}
