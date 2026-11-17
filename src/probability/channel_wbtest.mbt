///|
fn checked_channel(rows : Array[Array[(Int32, Int32)]]) -> Channel {
  match channel(@oracle.chain(rows.map(checked))) {
    Some(value) => value
    None => abort("channel")
  }
}

///|
test "all small binary channels agree with host probability and Bayes equations" {
  for a in 0..<=4 {
    for b in 0..<=4 {
      let c = checked_channel([[(a, 4), (4 - a, 4)], [(b, 4), (4 - b, 4)]])
      for prior in 0..<=4 {
        let p = checked([(prior, 4), (4 - prior, 4)])
        let numerator = prior * a + (4 - prior) * b
        let output = required(apply(c, p))
        assert_eq(
          masses(output),
          vector([(numerator, 16), (16 - numerator, 16)]),
        )
        if numerator == 0 || numerator == 16 {
          assert_eq(bayesian_inverse(c, p), None)
        } else {
          let inverse = match bayesian_inverse(c, p) {
            Some(value) => value
            None => abort("reverse")
          }
          assert_eq(
            channel_rows(inverse),
            @oracle.chain([
              checked([(prior * a, numerator), ((4 - prior) * b, numerator)]),
              checked([
                (prior * (4 - a), 16 - numerator),
                ((4 - prior) * (4 - b), 16 - numerator),
              ]),
            ]),
          )
          assert_eq(apply(inverse, output), Some(p))
        }
      }
    }
  }
}

///|
test "rectangular channels compose in time order and preserve distribution normalization" {
  let first = checked_channel([
    [(1, 2), (1, 2)],
    [(1, 1), (0, 1)],
    [(0, 1), (1, 1)],
  ])
  let second = checked_channel([
    [(1, 2), (1, 4), (1, 4)],
    [(0, 1), (1, 3), (2, 3)],
  ])
  let composed = match compose_channels(first, second) {
    Some(value) => value
    None => abort("compose")
  }
  assert_eq(input_size(composed), @oracle.nat(3))
  assert_eq(output_size(composed), @oracle.nat(3))
  let p = checked([(1, 2), (1, 3), (1, 6)])
  assert_eq(apply(composed, p), apply(second, required(apply(first, p))))
  assert_eq(
    channel_rows(composed),
    @oracle.chain([
      checked([(1, 4), (7, 24), (11, 24)]),
      checked([(1, 2), (1, 4), (1, 4)]),
      checked([(0, 1), (1, 3), (2, 3)]),
    ]),
  )
  assert_eq(posterior(first, p, @oracle.nat(2)), None)
  assert_eq(compose_channels(first, first), None)
  assert_eq(apply(first, checked([(1, 1)])), None)
  assert_eq(channel(@core.Nil), None)
  assert_eq(
    channel(@oracle.chain([checked([(1, 1)]), checked([(1, 2), (1, 2)])])),
    None,
  )
}
