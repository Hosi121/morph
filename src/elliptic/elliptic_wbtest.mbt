///|
fn residue(n : Int32, p : Int32) -> Int32 {
  (n % p + p) % p
}

///|
fn native(point : Point) -> (Int32, Int32)? {
  match coordinates(point) {
    Infinity => None
    Affine(x, y) => Some((@oracle.int_of_binary(x), @oracle.int_of_binary(y)))
  }
}

///|
fn native_add(
  a : (Int32, Int32)?,
  b : (Int32, Int32)?,
  coefficient : Int32,
  p : Int32,
) -> (Int32, Int32)? {
  match (a, b) {
    (None, _) => b
    (_, None) => a
    (Some((x, y)), Some((u, v))) => {
      if x == u && (y + v) % p == 0 {
        return None
      }
      let (top, bottom) = if x == u {
        (3 * x * x + coefficient, 2 * y)
      } else {
        (v - y, u - x)
      }
      let mut inverse = 0
      for candidate in 1..<p {
        if residue(candidate * bottom, p) == 1 {
          inverse = candidate
        }
      }
      let slope = residue(top * inverse, p)
      let next_x = residue(slope * slope - x - u, p)
      Some((next_x, residue(slope * (x - next_x) - y, p)))
    }
  }
}

///|
test "every pair on every nonsingular curve over primes five seven eleven thirteen" {
  for prime in [5, 7, 11, 13] {
    let field = @finitefield.field(@oracle.binary(prime)).unwrap()
    for a in 0..<prime {
      for b in 0..<prime {
        let candidate = curve(field, @oracle.binary(a), @oracle.binary(b))
        if (4 * a * a * a + 27 * b * b) % prime == 0 {
          assert_eq(candidate, None)
          continue
        }
        let context = candidate.unwrap()
        let points = [infinity(context)]
        for x in 0..<prime {
          for y in 0..<prime {
            let expected = (y * y - x * x * x - a * x - b) % prime == 0
            match point(context, @oracle.binary(x), @oracle.binary(y)) {
              None => assert_false(expected)
              Some(p) => {
                assert_true(expected)
                points.push(p)
                assert_eq(decompress(context, compress(p)), Some(p))
              }
            }
          }
        }
        for p in points {
          assert_eq(add(p, negate(p)), Some(infinity(context)))
          for q in points {
            let actual = add(p, q).unwrap()
            assert_eq(
              native(actual),
              native_add(native(p), native(q), a, prime),
            )
            assert_eq(add(q, p), Some(actual))
          }
        }
        for x in 0..<prime {
          for odd in [false, true] {
            match decompress(context, XParity(@oracle.binary(x), odd)) {
              None =>
                assert_false(
                  points.any(fn(p) {
                    match coordinates(p) {
                      Affine(px, py) =>
                        @oracle.int_of_binary(px) == x && @binary.odd(py) == odd
                      Infinity => false
                    }
                  }),
                )
              Some(p) => assert_eq(compress(p), XParity(@oracle.binary(x), odd))
            }
          }
        }
      }
    }
  }
}

///|
test "associativity, scalar multiplication, 200-bit scalar and educational shared point" {
  let field = @finitefield.field(@oracle.binary(17)).unwrap()
  let context = curve(field, @oracle.binary(2), @oracle.binary(2)).unwrap()
  let generator = point(context, @oracle.binary(5), @oracle.binary(1)).unwrap()
  let points = [
    for k in 0..<19 => scale(generator, @oracle.binary(k)).unwrap()
  ]
  assert_eq(scale(generator, @oracle.binary(19)), Some(infinity(context)))
  for p in points {
    for q in points {
      for r in points {
        assert_eq(add(add(p, q).unwrap(), r), add(p, add(q, r).unwrap()))
      }
    }
  }
  let mut expected : (Int32, Int32)? = None
  for scalar in 0..<38 {
    assert_eq(
      native(scale(generator, @oracle.binary(scalar)).unwrap()),
      expected,
    )
    expected = native_add(expected, Some((5, 1)), 2, 17)
  }
  let huge = @binary.add(
    @binary.power(@oracle.binary(2), @oracle.binary(200)),
    @oracle.binary(17),
  )
  let (_, remainder) = @binary.divmod(huge, @oracle.binary(19)).unwrap()
  assert_eq(scale(generator, huge), scale(generator, remainder))
  let public_a = scale(generator, @oracle.binary(5)).unwrap()
  let public_b = scale(generator, @oracle.binary(7)).unwrap()
  let shared_a = scale(public_b, @oracle.binary(5)).unwrap()
  let shared_b = scale(public_a, @oracle.binary(7)).unwrap()
  assert_eq(shared_a, shared_b)
  assert_eq(native(shared_a), Some((10, 11)))
  let other = curve(field, @oracle.binary(1), @oracle.binary(1)).unwrap()
  assert_eq(add(generator, infinity(other)), None)
  assert_eq(point(context, @oracle.binary(17), @oracle.binary(1)), None)
  assert_eq(decompress(context, XParity(@oracle.binary(17), true)), None)
  assert_eq(
    curve(
      @finitefield.field(@oracle.binary(3)).unwrap(),
      @oracle.binary(1),
      @oracle.binary(1),
    ),
    None,
  )
}
