///|
fn elimination_rat(
  negative : Bool,
  numerator : String,
  denominator : String,
) -> @exact.Rational {
  let n = @exact.positive(@oracle.binary_from_hex(numerator))
  @exact.ratio(
    if negative {
      @exact.negate(n)
    } else {
      n
    },
    @oracle.binary_from_hex(denominator),
  ).unwrap()
}

///|
fn elimination_fixture(
  f : @core.Chain[@exact.Rational],
  g : @core.Chain[@exact.Rational],
  expected : @exact.Rational,
  u : @core.Chain[@exact.Rational],
  v : @core.Chain[@exact.Rational],
) -> Unit raise {
  let ring = @berkowitz.rationals()
  let left = dense(f, ring)
  let right = dense(g, ring)
  assert_eq(resultant(left, right, ring), Some(expected))
  assert_true(check_resultant(left, right, expected, ring, fn(a, b) { a == b }))
  match bezout(left, right, ring) {
    None => {
      assert_true(@core.is_zero(nominal_degree(left)))
      assert_true(@core.is_zero(nominal_degree(right)))
    }
    Some(proof) => {
      assert_eq(proof.value, expected)
      assert_eq(proof.u, u)
      assert_eq(proof.v, v)
      assert_true(
        check_bezout_identity(left, right, expected, proof, ring, fn(a, b) {
          a == b
        }),
      )
      let wrong = @exact.rational_add(expected, @exact.rational_one())
      assert_false(
        check_bezout_identity(left, right, wrong, proof, ring, fn(a, b) {
          a == b
        }),
      )
      assert_false(
        check_bezout_identity(
          left,
          right,
          expected,
          { ..proof, u: @core.Cons(@exact.rational_one(), proof.u), },
          ring,
          fn(a, b) { a == b },
        ),
      )
    }
  }
}

///|
fn elimination_poly(
  variables : Int32,
  terms : Array[(@exact.Rational, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(entry) {
        @poly.Term::{
          coefficient: entry.0,
          exponents: @oracle.chain(entry.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn elimination_mod4_fixture(
  f : Array[Int32],
  g : Array[Int32],
  expected : Int32,
) -> Unit raise {
  let ring : @berkowitz.Ring[Int32] = {
    semiring: {
      zero: 0,
      one: 1,
      plus: fn(a, b) { (a + b) % 4 },
      times: fn(a, b) { a * b % 4 },
    },
    negate: fn(a) { (4 - a) % 4 },
  }
  let left = dense(@oracle.chain(f), ring)
  let right = dense(@oracle.chain(g), ring)
  assert_eq(resultant(left, right, ring), Some(expected))
  let proof = bezout(left, right, ring).unwrap()
  assert_true(
    check_bezout_identity(left, right, expected, proof, ring, fn(a, b) {
      a == b
    }),
  )
  assert_eq(discriminant(left, ring), Some(f[1] * f[1] % 4))
}

///|
fn elimination_projection_fixture(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : Int32,
  m : Int32,
  n : Int32,
  expected : @poly.Polynomial,
  disc : @poly.Polynomial,
) -> Unit raise {
  let left = fixed_input(f, @oracle.nat(selected), @oracle.nat(m)).unwrap()
  let right = fixed_input(g, @oracle.nat(selected), @oracle.nat(n)).unwrap()
  assert_eq(source(left), f)
  assert_eq(variable(left), @oracle.nat(selected))
  assert_eq(input_degree(left), @oracle.nat(m))
  assert_eq(eliminate(left, right), Ok(expected))
  assert_true(check_elimination(left, right, expected))
  assert_eq(discriminate(left), Ok(disc))
  assert_true(check_discrimination(left, disc))
  match projection_identity(left, right) {
    Err(ConstantPairIdentity) => assert_eq(m + n, 0)
    Ok(proof) => {
      assert_eq(proof.value, expected)
      assert_true(check_projection_identity(left, right, expected, proof))
      assert_true(check_projection_result(left, right, expected, proof))
      let wrong = @poly.add(
        expected,
        @poly.constant(@poly.variables(expected), @exact.rational_one()),
      ).unwrap()
      assert_false(check_projection_identity(left, right, wrong, proof))
      assert_false(check_projection_result(left, right, wrong, proof))
    }
    _ => fail("unexpected projection certificate error")
  }
}
