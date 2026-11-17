///|
fn kernel_legacy_addsub(
  a : Element,
  b : Element,
  subtracting : Bool,
) -> Element {
  let result = if subtracting {
    @poly.subtract(representative(a), representative(b)).unwrap()
  } else {
    @poly.add(representative(a), representative(b)).unwrap()
  }
  element(parent(a), result).unwrap()
}

///|
test "canonical addsub finite rational oracle agrees with legacy reduction" {
  let fields = [
    test_field([(0, 1), (1, 1)], (-1, 1), (0, 1)),
    test_sqrt2(),
    test_field([(1, 1), (0, 1), (-10, 1), (0, 1), (1, 1)], (3, 1), (4, 1)),
  ]
  let fractions : Array[(Int64, Int64)] = [
    (-2, 3),
    (-1, 2),
    (0, 1),
    (1, 3),
    (2, 1),
  ]
  for f in fields {
    let d = @oracle.int_of_nat(degree(f))
    for ai in 0..<fractions.length() {
      for bi in 0..<fractions.length() {
        let aa = [ for i in 0..<d => fractions[(ai + i) % fractions.length()] ]
        let bb = [
          for i in 0..<d => fractions[(bi + d - i) % fractions.length()]
        ]
        let a = element(f, test_poly(aa)).unwrap()
        let b = element(f, test_poly(bb)).unwrap()
        for subtracting in [false, true] {
          let expected = [
            for i in 0..<d => {
              let (an, ad) = aa[i]
              let (bn, bd) = bb[i]
              (an * bd + (if subtracting { -bn } else { bn }) * ad, ad * bd)
            }
          ]
          let actual = if subtracting {
            subtract(a, b).unwrap()
          } else {
            add(a, b).unwrap()
          }
          assert_eq(representative(actual), test_poly(expected))
          assert_true(equal(actual, kernel_legacy_addsub(a, b, subtracting)))
          assert_true(
            @core.all(@poly.terms(representative(actual)), fn(term) {
              match term.exponents {
                Cons(exponent, Nil) =>
                  @core.compare(exponent, degree(f)) is Less
                _ => false
              }
            }),
          )
        }
        assert_true(equal(add(a, negate(a)).unwrap(), zero(f)))
        assert_true(equal(subtract(a, a).unwrap(), zero(f)))
        assert_true(equal(add(a, zero(f)).unwrap(), a))
      }
    }
  }
}

///|
test "canonical addsub binds the full root interval and multiplication still reduces" {
  let f = test_sqrt2()
  let conjugate = test_field([(-2, 1), (0, 1), (1, 1)], (-2, 1), (-1, 1))
  let refined = test_field([(-2, 1), (0, 1), (1, 1)], (7, 5), (3, 2))
  let a = generator(f).unwrap()
  for other in [conjugate, refined] {
    assert_eq(modulus(f), modulus(other))
    for
      result in [
        add(a, zero(other)),
        subtract(zero(f), generator(other).unwrap()),
      ] {
      match result {
        Err(DifferentField) => ()
        _ => fail("canonical addsub accepted a different embedding context")
      }
    }
  }
  assert_eq(representative(multiply(a, a).unwrap()), test_integer_poly([2]))
  let high = element(f, test_integer_poly([1, 0, 0, 0, 1])).unwrap()
  assert_eq(representative(add(high, one(f)).unwrap()), test_integer_poly([6]))
}
