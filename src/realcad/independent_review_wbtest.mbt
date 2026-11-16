///|
fn review_ratio(
  negative : Bool,
  numerator_hex : String,
  denominator_hex : String,
) -> @exact.Rational {
  let magnitude = @exact.positive(@oracle.binary_from_hex(numerator_hex))
  @exact.ratio(
    if negative {
      @exact.negate(magnitude)
    } else {
      magnitude
    },
    @oracle.binary_from_hex(denominator_hex),
  ).unwrap()
}

///|
fn review_polynomial(
  coefficients : Array[@exact.Rational],
) -> @polynomial.Polynomial {
  @polynomial.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<coefficients.length() => {
          @polynomial.Term::{
            coefficient: coefficients[i],
            exponents: @core.Cons(@oracle.nat(i), @core.Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
// Sign of a+b*sqrt(d), using only exact rational signs and squared magnitudes.
// It is independent of Sturm counts, interval refinement and polynomial gcd.
fn review_surd_sign(
  a : @exact.Rational,
  b : @exact.Rational,
  d : Int32,
) -> @core.Ordering {
  let sa = @exact.rational_compare(a, @exact.rational_zero())
  let sb = @exact.rational_compare(b, @exact.rational_zero())
  if sa is Equal {
    return sb
  }
  if sb is Equal {
    return sa
  }
  if sa.equal(sb) {
    return sa
  }
  let left = @exact.rational_multiply(a, a)
  let right = @exact.rational_multiply(
    @oracle.rational(d, 1),
    @exact.rational_multiply(b, b),
  )
  match @exact.rational_compare(left, right) {
    Equal => Equal
    Greater => sa
    Less => sb
  }
}

///|
fn review_root_compare(
  root : (@exact.Rational, @exact.Rational, Int32),
  point : @exact.Rational,
) -> @core.Ordering {
  let (a, b, d) = root
  review_surd_sign(@exact.rational_subtract(a, point), b, d)
}

///|
fn review_ordering(sign : Int32) -> @core.Ordering {
  if sign < 0 {
    Less
  } else if sign > 0 {
    Greater
  } else {
    Equal
  }
}

///|
fn review_assert_fixture(
  formula : Formula,
  expected_roots : Array[(@exact.Rational, @exact.Rational, Int32)],
  expected_signs : Array[Array[Int32]],
  expected_truth : Array[Bool],
) -> Unit raise {
  let problem = prepare(formula).unwrap()
  let result = match run(start(problem), @oracle.nat(16384)) {
    Complete(result) => result
    Paused(_) => abort("review case exhausted explicit 16384-step bound")
    Fault => abort("review case produced Fault")
  }
  let intervals = @oracle.array(roots(result))
  assert_eq(intervals.length(), expected_roots.length())
  // Independently identify each isolated root by its exact quadratic-field value.
  for i in 0..<intervals.length() {
    assert_eq(
      review_root_compare(expected_roots[i], intervals[i].lower),
      Greater,
    )
    assert_false(
      review_root_compare(expected_roots[i], intervals[i].upper) is Greater,
    )
    let mut count = 0
    for root in expected_roots {
      if review_root_compare(root, intervals[i].lower) is Greater &&
        !(review_root_compare(root, intervals[i].upper) is Greater) {
        count += 1
      }
    }
    assert_eq(count, 1)
  }
  let actual = @oracle.array(cells(result))
  assert_eq(actual.length(), expected_truth.length())
  assert_eq(actual.length(), 2 * expected_roots.length() + 1)
  for i in 0..<actual.length() {
    assert_eq(actual[i].holds, expected_truth[i])
    assert_eq(
      @oracle.array(actual[i].signs),
      expected_signs[i].map(review_ordering),
    )
    if i % 2 == 0 {
      match actual[i].sample {
        RationalPoint(point) => {
          let before = i / 2
          if before > 0 {
            assert_eq(
              review_root_compare(expected_roots[before - 1], point),
              Less,
            )
          }
          if before < expected_roots.length() {
            assert_eq(
              review_root_compare(expected_roots[before], point),
              Greater,
            )
          }
        }
        _ => fail("review expected rational open-cell sample")
      }
    } else {
      assert_eq(actual[i].sample, AlgebraicPoint(intervals[i / 2]))
    }
  }
  assert_eq(universally_true(result), expected_truth.all(fn(value) { value }))
  assert_eq(witness(result) is Some(_), expected_truth.any(fn(value) { value }))
  assert_eq(
    counterexample(result) is Some(_),
    expected_truth.any(fn(value) { !value }),
  )
  assert_eq(
    @oracle.array(satisfying_cells(result)).length(),
    expected_truth.filter(fn(value) { value }).length(),
  )
  assert_true(check(problem, certificate(result)) is Some(_))
}
