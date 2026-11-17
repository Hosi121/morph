///|
/// Retained original generic arithmetic as a second, non-optimized oracle.
fn night_legacy_evaluate(
  value : Polynomial,
  point : @binary.Binary,
) -> @binary.Binary {
  fn go(cs : @core.Chain[@binary.Binary]) -> @binary.Binary {
    match cs {
      Nil => @binary.zero()
      Cons(c, rest) =>
        @modular.add(
          @primefield.modulus(value.field),
          c,
          @modular.multiply(@primefield.modulus(value.field), point, go(rest)),
        )
    }
  }
  go(value.coefficients)
}

///|
fn night_host_evaluate(cs : Array[Int32], point : Int32, p : Int32) -> Int32 {
  for i = cs.length() - 1, result = 0; i >= 0; {
    continue i - 1,
      canonical_mod(result.to_int64() * point.to_int64() + cs[i].to_int64(), p)
  } nobreak {
    result
  }
}

///|
test "night Horner exhausts small polynomial coefficients and unreduced points" {
  for p in [2, 3, 5] {
    let field = canonical_field(p)
    for a in 0..<p {
      for b in 0..<p {
        for c in 0..<p {
          let raw = [p + a, p * 2 + b, p * 3 + c]
          let value = canonical_polynomial(field, raw)
          for x in 0..<(p * 3 + 2) {
            let point = @oracle.binary(x)
            let actual = evaluate(value, point)
            assert_eq(
              @oracle.int_of_binary(actual),
              night_host_evaluate(raw, x, p),
            )
            assert_eq(actual, night_legacy_evaluate(value, point))
          }
        }
      }
    }
  }
}

///|
test "night Horner handles empty constant huge even odd and prime-boundary points" {
  let huge = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(511)),
    @oracle.binary(19),
  )
  let even_huge = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(511)),
    @oracle.binary(18),
  )
  for p in [2, 3, 17, 257, 65537] {
    let field = canonical_field(p)
    let huge_residue = for i = 0, n = 1; i < 511; {
      continue i + 1, n * 2 % p
    } nobreak {
      (n + 19) % p
    }
    let even_residue = (huge_residue + p - 1) % p
    for
      raw in [
        [],
        [p * 3],
        [p * 2 + 1],
        [p - 1],
        [0, 1, p - 1, 2, 0, p + 1],
        Array::makei(35, fn(i) { (i * 1973 + p) % (p * 2) }),
      ] {
      let value = canonical_polynomial(field, raw)
      for
        pair in [
          (huge, huge_residue),
          (even_huge, even_residue),
          (@oracle.binary(0), 0),
          (@oracle.binary(1), 1),
          (@oracle.binary(p), 0),
          (@oracle.binary(p + 1), 1),
          (@oracle.binary(p * 3 + 7), 7 % p),
        ] {
        let actual = evaluate(value, pair.0)
        assert_eq(
          @oracle.int_of_binary(actual),
          night_host_evaluate(raw, pair.1, p),
        )
        assert_eq(actual, night_legacy_evaluate(value, pair.0))
        assert_true(@binary.compare(actual, @oracle.binary(p)) is Less)
      }
    }
  }
}
