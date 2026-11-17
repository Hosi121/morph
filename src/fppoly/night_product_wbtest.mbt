///|
test "night canonical product residues exhaust small primes and larger boundaries" {
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    let alphabet = if p <= 17 {
      [
        for c in 0..<p => c
      ]
    } else {
      [0, 1, 2, p / 2, p - 2, p - 1]
    }
    for a in alphabet {
      for b in alphabet {
        let left = [p + a, 0, 1, p - 1, p * 2 + a]
        let right = [p * 2 + b, 1, 0, p - 1, p + b]
        canonical_assert(
          canonical_required(
            multiply(
              canonical_polynomial(field, left),
              canonical_polynomial(field, right),
            ),
          ),
          canonical_product(left, right, p),
          p,
        )
      }
    }
  }
}

///|
test "night arbitrary scalar normalization preserves zero units and huge residues" {
  let huge = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(511)),
    @oracle.binary(19),
  )
  for p in [2, 3, 5, 17, 257, 65537] {
    let field = canonical_field(p)
    let residue = for i = 0, n = 1; i < 511; {
      continue i + 1, n * 2 % p
    } nobreak {
      (n + 19) % p
    }
    for xs in [[], [p, 0, p * 2], [p + 1], [0, 1, p - 1, 2, 0, p + 1]] {
      let value = canonical_polynomial(field, xs)
      canonical_assert(
        scale(value, huge),
        canonical_trim(
          xs.map(fn(c) { canonical_mod(c.to_int64() * residue.to_int64(), p) }),
          p,
        ),
        p,
      )
      assert_eq(scale(value, @oracle.binary(p + 1)), value)
      assert_eq(scale(value, @oracle.binary(p * 3)), zero(field))
      assert_eq(scale(value, @oracle.binary(0)), zero(field))
      assert_eq(scale(value, @oracle.binary(1)), value)
      // Public points and derivative exponents may exceed p. Their generic
      // arithmetic is intentionally outside the canonical-product helper.
      let raw_point = p * 3 + 7
      let expected = for i = xs.length() - 1, acc = 0; i >= 0; {
        continue i - 1,
          canonical_mod(
            acc.to_int64() * raw_point.to_int64() + xs[i].to_int64(),
            p,
          )
      } nobreak {
        acc
      }
      assert_eq(
        @oracle.int_of_binary(evaluate(value, @oracle.binary(raw_point))),
        expected,
      )
    }
  }
  for p in [2, 3, 5] {
    let field = canonical_field(p)
    let xs = Array::makei(p * 3 + 2, fn(i) { p + i + 1 })
    let expected = canonical_trim(
      [
        for i in 1..<xs.length() => {
          canonical_mod(i.to_int64() * xs[i].to_int64(), p)
        }
      ],
      p,
    )
    canonical_assert(derivative(canonical_polynomial(field, xs)), expected, p)
  }
}
