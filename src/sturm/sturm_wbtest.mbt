///|
fn poly(coefficients : Array[Int32]) -> @polynomial.Polynomial {
  @polynomial.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<coefficients.length() => {
          @polynomial.Term::{
            coefficient: @oracle.rational(coefficients[i], 1),
            exponents: @core.Cons(@oracle.nat(i), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn finish(system : System) -> @core.Chain[Interval] {
  let mut state = isolate(system)
  for _ in 0..<1024 {
    match advance(state, @oracle.nat(3)) {
      Isolated(intervals) => return intervals
      Paused(rest) => state = rest
    }
  }
  abort("small polynomial isolation exceeded test node bound")
}

///|
test "all 624 nonzero cubic-or-lower integer polynomials versus discriminants" {
  for code in 0..<625 {
    let coefficients = [ for i in 0..<4 => code / [1, 5, 25, 125][i] % 5 - 2 ]
    let d = coefficients[0]
    let c = coefficients[1]
    let b = coefficients[2]
    let a = coefficients[3]
    if a == 0 && b == 0 && c == 0 && d == 0 {
      continue
    }
    let expected = if a != 0 {
      let discriminant = 18 * a * b * c * d -
        4 * b * b * b * d +
        b * b * c * c -
        4 * a * c * c * c -
        27 * a * a * d * d
      if discriminant > 0 {
        3
      } else if discriminant < 0 {
        1
      } else if b * b == 3 * a * c {
        1
      } else {
        2
      }
    } else if b != 0 {
      let discriminant = c * c - 4 * b * d
      if discriminant > 0 {
        2
      } else if discriminant == 0 {
        1
      } else {
        0
      }
    } else if c != 0 {
      1
    } else {
      0
    }
    let context = system(poly(coefficients)).unwrap()
    assert_eq(@oracle.int_of_nat(count_all(context)), expected)
    let intervals = finish(context)
    assert_eq(@oracle.int_of_nat(@core.length(intervals)), expected)
    assert_true(check_isolation(context, intervals))
    assert_eq(advance(isolate(context), @oracle.nat(2048)), Isolated(intervals))
  }
}

///|
test "repeated rational roots, exact half-open endpoints and close roots" {
  for mask in 0..<32 {
    let roots = [
      for i in 0..<5 if (mask & (1 << i)) != 0 => @oracle.rational(i - 2, 1)
    ]
    let mut p = poly([1])
    for i in 0..<roots.length() {
      let factor = @polynomial.polynomial(
        @oracle.nat(1),
        @oracle.chain([
          @polynomial.Term::{
            coefficient: @exact.rational_negate(roots[i]),
            exponents: @core.Cons(Zero, Nil),
          },
          @polynomial.Term::{
            coefficient: @exact.rational_one(),
            exponents: @core.Cons(@oracle.nat(1), Nil),
          },
        ]),
      ).unwrap()
      for _ in 0..<=(i % 3) {
        p = @polynomial.multiply(p, factor).unwrap()
      }
    }
    let context = system(p).unwrap()
    assert_eq(@oracle.int_of_nat(count_all(context)), roots.length())
    assert_true(check_isolation(context, finish(context)))
    for lower in -3..<3 {
      for upper in (lower + 1)..<=3 {
        let expected = roots
          .filter(fn(root) {
            @exact.rational_compare(@oracle.rational(lower, 1), root) == Less &&
            @exact.rational_compare(root, @oracle.rational(upper, 1)) != Greater
          })
          .length()
        assert_eq(
          @oracle.int_of_nat(
            count_between(
              context,
              @oracle.rational(lower, 1),
              @oracle.rational(upper, 1),
            ).unwrap(),
          ),
          expected,
        )
      }
    }
  }
  let close = @polynomial.polynomial(
    @oracle.nat(1),
    @oracle.chain([
      @polynomial.Term::{
        coefficient: @oracle.rational(1, 1),
        exponents: @core.Cons(@oracle.nat(2), Nil),
      },
      @polynomial.Term::{
        coefficient: @oracle.rational(-1, 1048576),
        exponents: @core.Cons(@oracle.nat(1), Nil),
      },
    ]),
  ).unwrap()
  let context = system(close).unwrap()
  let initial = isolate(context)
  assert_eq(advance(initial, Zero), Paused(initial))
  match advance(initial, @oracle.nat(1)) {
    Paused(_) => ()
    _ => fail("close roots require further splits")
  }
  let intervals = finish(context)
  assert_true(check_isolation(context, intervals))
  assert_eq(@oracle.int_of_nat(@core.length(intervals)), 2)
}

///|
test "sqrt two is isolated and refined without square root or floats" {
  let context = system(poly([-2, 0, 1])).unwrap()
  let intervals = @oracle.array(finish(context))
  let positive = intervals[1]
  let refined = refine(context, positive, @oracle.nat(24)).unwrap()
  let two = @oracle.rational(2, 1)
  assert_eq(
    @exact.rational_compare(
      @exact.rational_multiply(refined.lower, refined.lower),
      two,
    ),
    Less,
  )
  assert_eq(
    @exact.rational_compare(
      @exact.rational_multiply(refined.upper, refined.upper),
      two,
    ),
    Greater,
  )
  assert_eq(
    @exact.rational_subtract(refined.upper, refined.lower),
    @oracle.rational(3, 16777216),
  )
  assert_eq(
    refine(
      context,
      refine(context, positive, @oracle.nat(12)).unwrap(),
      @oracle.nat(12),
    ),
    Some(refined),
  )
  assert_eq(
    refine(
      context,
      { lower: @oracle.rational(-3, 1), upper: @oracle.rational(3, 1), },
      @oracle.nat(1),
    ),
    None,
  )
  assert_eq(count_between(context, two, two), None)
  assert_false(check_isolation(context, @oracle.chain([positive, positive])))
  assert_false(check_isolation(context, @oracle.chain([positive])))
  assert_eq(system(poly([0])), Err(ZeroPolynomial))
  assert_eq(
    system(@polynomial.constant(@oracle.nat(2), two)),
    Err(NotUnivariate),
  )
}
