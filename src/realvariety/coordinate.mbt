///|
fn univariate_degree(value : @poly.Polynomial) -> @core.Nat? {
  match @poly.terms(value) {
    Cons({ exponents: Cons(n, Nil), .. }, _) => Some(n)
    _ => None
  }
}

///|
fn coefficient(
  value : @poly.Polynomial,
  exponent : @core.Nat,
) -> @exact.Rational {
  @core.fold_left(@poly.terms(value), @exact.rational_zero(), fn(
    previous,
    term,
  ) {
    if term.exponents.equal(Cons(exponent, Nil)) {
      term.coefficient
    } else {
      previous
    }
  })
}

///|
/// Matrix of multiplication by h in Q[t]/(g), in basis 1,t,...,t^(d-1).
fn coordinate_matrix(
  g : @poly.Polynomial,
  h : @poly.Polynomial,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Rational]? {
  fn columns(
    exponent : @core.Nat,
    count : @core.Nat,
  ) -> @core.Chain[@poly.Polynomial]? {
    match count {
      Zero => Some(Nil)
      Succ(rest) =>
        match
          (
            @poly.polynomial(
              Succ(Zero),
              Cons(
                {
                  coefficient: @exact.rational_one(),
                  exponents: Cons(exponent, Nil),
                },
                Nil,
              ),
            ),
            columns(Succ(exponent), rest),
          ) {
          (Ok(term), Some(tail)) =>
            match product_mod(h, term, g) {
              Some(p) => Some(Cons(p, tail))
              None => None
            }
          _ => None
        }
    }
  }
  match columns(Zero, degree) {
    None => None
    Some(columns) =>
      @matrix.matrix(
        degree,
        @core.map(@core.indices(degree), fn(row) {
          @core.map(columns, fn(p) { coefficient(p, row) })
        }),
      )
  }
}

///|
fn eigen_sample(
  matrix : @matrix.Matrix[@exact.Rational],
  point : @exact.Rational,
) -> @exact.Rational? {
  fn rows(
    values : @core.Chain[@core.Chain[@exact.Rational]],
    row : @core.Nat,
  ) -> @core.Chain[@core.Chain[@exact.Rational]] {
    fn cells(
      values : @core.Chain[@exact.Rational],
      column : @core.Nat,
    ) -> @core.Chain[@exact.Rational] {
      match values {
        Nil => Nil
        Cons(head, rest) =>
          Cons(
            if row.equal(column) {
              @exact.rational_subtract(point, head)
            } else {
              @exact.rational_negate(head)
            },
            cells(rest, Succ(column)),
          )
      }
    }
    match values {
      Nil => Nil
      Cons(head, rest) => Cons(cells(head, Zero), rows(rest, Succ(row)))
    }
  }
  match
    @matrix.matrix(@matrix.width(matrix), rows(@matrix.rows(matrix), Zero)) {
    Some(matrix) => @linear.determinant(matrix)
    None => None
  }
}

///|
fn rational_nat(value : @core.Nat) -> @exact.Rational {
  @exact.whole(@exact.positive(@binary.from_nat(value)))
}

///|
fn qmin(a : @exact.Rational, b : @exact.Rational) -> @exact.Rational {
  if @exact.rational_compare(a, b).equal(Greater) {
    b
  } else {
    a
  }
}

///|
fn qmax(a : @exact.Rational, b : @exact.Rational) -> @exact.Rational {
  if @exact.rational_compare(a, b).equal(Less) {
    b
  } else {
    a
  }
}

///|
fn closed_product(a : @sturm.Interval, b : @sturm.Interval) -> @sturm.Interval {
  let ll = @exact.rational_multiply(a.lower, b.lower)
  let lu = @exact.rational_multiply(a.lower, b.upper)
  let ul = @exact.rational_multiply(a.upper, b.lower)
  let uu = @exact.rational_multiply(a.upper, b.upper)
  {
    lower: qmin(qmin(ll, lu), qmin(ul, uu)),
    upper: qmax(qmax(ll, lu), qmax(ul, uu)),
  }
}

///|
/// Closed Horner range padded by the positive source width at both endpoints.
fn coordinate_interval(
  h : @poly.Polynomial,
  source : @sturm.Interval,
) -> @sturm.Interval {
  fn horner(remaining : @core.Nat, exponent : @core.Nat) -> @sturm.Interval {
    match remaining {
      Zero => { lower: @exact.rational_zero(), upper: @exact.rational_zero(), }
      Succ(rest) => {
        let tail = closed_product(source, horner(rest, Succ(exponent)))
        let c = coefficient(h, exponent)
        {
          lower: @exact.rational_add(c, tail.lower),
          upper: @exact.rational_add(c, tail.upper),
        }
      }
    }
  }
  let count : @core.Nat = match univariate_degree(h) {
    Some(degree) => Succ(degree)
    None => Zero
  }
  let range = horner(count, Zero)
  let padding = @exact.rational_subtract(source.upper, source.lower)
  {
    lower: @exact.rational_subtract(range.lower, padding),
    upper: @exact.rational_add(range.upper, padding),
  }
}

///|
fn contained(inner : @sturm.Interval, outer : @sturm.Interval) -> Bool {
  !@exact.rational_compare(inner.lower, outer.lower).equal(Less) &&
  !@exact.rational_compare(inner.upper, outer.upper).equal(Greater)
}

///|
#derive(Eq, Debug)
pub(all) struct CoordinateCertificate {
  point : PointCertificate
  index : @core.Nat
  polynomial : @poly.Polynomial
  samples : @core.Chain[@exact.Rational]
  refined : @sturm.Interval
  result : @real.RootCertificate
}

///|
pub extend CoordinateCertificate with Eq::{equal, not_equal}

///|
pub extend CoordinateCertificate with Debug::{to_repr}

///|
/// Validate a multiplication-matrix characteristic polynomial independently of
/// interpolation, then validate the padded enclosure selecting h_i(alpha).
pub fn check_coordinate(proof : CoordinateCertificate) -> Bool {
  match point_from_certificate(proof.point) {
    Err(_) => false
    Ok(point) =>
      match
        (
          @core.nth(coordinate_expressions(point), proof.index),
          univariate_degree(point.shape.certificate.eliminant),
          univariate_degree(proof.polynomial),
        ) {
        (Some(h), Some(degree), Some(claimed_degree)) =>
          if !@poly.variables(proof.polynomial).equal(Succ(Zero)) ||
            @core.compare(claimed_degree, degree).equal(Greater) ||
            !contained(proof.refined, @real.interval(point.parameter)) {
            false
          } else {
            match
              coordinate_matrix(point.shape.certificate.eliminant, h, degree) {
              None => false
              Some(matrix) => {
                fn samples(
                  values : @core.Chain[@exact.Rational],
                  remaining : @core.Nat,
                  point : @core.Nat,
                ) -> Bool {
                  match (values, remaining) {
                    (Nil, Zero) => true
                    (Cons(head, tail), Succ(rest)) => {
                      let x = rational_nat(point)
                      match
                        (
                          eigen_sample(matrix, x),
                          @poly.evaluate(proof.polynomial, Cons(x, Nil)),
                        ) {
                        (Some(expected), Some(actual)) =>
                          expected.equal(head) &&
                          actual.equal(head) &&
                          samples(tail, rest, Succ(point))
                        _ => false
                      }
                    }
                    _ => false
                  }
                }
                match
                  (
                    @sturm.count_between(
                      point.shape.system,
                      proof.refined.lower,
                      proof.refined.upper,
                    ),
                    @sturm.system(proof.polynomial),
                  ) {
                  (Some(Succ(Zero)), Ok(output)) =>
                    samples(proof.samples, Succ(degree), Zero) &&
                    proof.result.polynomial.equal(@sturm.squarefree(output)) &&
                    proof.result.interval.equal(
                      coordinate_interval(h, proof.refined),
                    ) &&
                    @real.check_root(proof.result)
                  _ => false
                }
              }
            }
          }
        _ => false
      }
  }
}

///|
/// Bind the Number payload to the exact normalized polynomial and interval in
/// proof.result, in addition to checking the coordinate relation itself.
pub fn check_coordinate_result(
  value : @real.Number,
  proof : CoordinateCertificate,
) -> Bool {
  @real.root_certificate(value).equal(proof.result) && check_coordinate(proof)
}

///|
#derive(Debug)
pub struct CoordinateEvaluation {
  original : PointCertificate
  current : Point
  index : @core.Nat
  h : @poly.Polynomial
  matrix : @matrix.Matrix[@exact.Rational]
  degree : @core.Nat
  remaining : @core.Nat
  point : @core.Nat
  coefficients : @poly.Polynomial
  basis : @poly.Polynomial
  samples : @core.Chain[@exact.Rational]
  output : @sturm.System?
}

///|
pub extend CoordinateEvaluation with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum CoordinateProgress {
  CoordinateReady(@real.Number, CoordinateCertificate)
  CoordinatePaused(CoordinateEvaluation)
}

///|
pub extend CoordinateProgress with Debug::{to_repr}

///|
pub fn coordinate_start(
  point : Point,
  index : @core.Nat,
) -> Result[CoordinateEvaluation, VarietyError] {
  match
    (
      @core.nth(coordinate_expressions(point), index),
      univariate_degree(point.shape.certificate.eliminant),
    ) {
    (Some(h), Some(degree)) =>
      match coordinate_matrix(point.shape.certificate.eliminant, h, degree) {
        Some(matrix) =>
          Ok({
            original: point_certificate(point),
            current: point,
            index,
            h,
            matrix,
            degree,
            remaining: Succ(degree),
            point: Zero,
            coefficients: univariate_zero(),
            basis: univariate_one(),
            samples: Nil,
            output: None,
          })
        None => Err(InternalInvariant)
      }
    _ => Err(InvalidCoordinate)
  }
}

///|
/// One unit of fuel evaluates/interpolates one characteristic-polynomial sample
/// or bisects the shared source root once. The polynomial degree is at most
/// degree(g), regardless of the degree of the coordinate expression h.
pub fn coordinate_advance(
  state : CoordinateEvaluation,
  fuel : @core.Nat,
) -> Result[CoordinateProgress, VarietyError] {
  match state.remaining {
    Succ(remaining) =>
      match fuel {
        Zero => Ok(CoordinatePaused(state))
        Succ(rest) => {
          let x = rational_nat(state.point)
          match
            (
              eigen_sample(state.matrix, x),
              @poly.evaluate(state.coefficients, Cons(x, Nil)),
              @poly.evaluate(state.basis, Cons(x, Nil)),
            ) {
            (Some(sample), Some(current), Some(base)) =>
              match
                @exact.rational_divide(
                  @exact.rational_subtract(sample, current),
                  base,
                ) {
                None => Err(InternalInvariant)
                Some(c) =>
                  match
                    (
                      @poly.scale(state.basis, {
                        coefficient: c,
                        exponents: Cons(Zero, Nil),
                      }),
                      @poly.polynomial(
                        Succ(Zero),
                        Cons(
                          {
                            coefficient: @exact.rational_one(),
                            exponents: Cons(Succ(Zero), Nil),
                          },
                          Cons(
                            {
                              coefficient: @exact.rational_negate(x),
                              exponents: Cons(Zero, Nil),
                            },
                            Nil,
                          ),
                        ),
                      ),
                    ) {
                    (Ok(scaled), Ok(linear)) =>
                      match
                        (
                          @poly.add(state.coefficients, scaled),
                          @poly.multiply(state.basis, linear),
                        ) {
                        (Ok(coefficients), Ok(basis)) =>
                          coordinate_advance(
                            {
                              ..state,
                              coefficients,
                              basis,
                              samples: Cons(sample, state.samples),
                              point: Succ(state.point),
                              remaining,
                            },
                            rest,
                          )
                        _ => Err(InternalInvariant)
                      }
                    _ => Err(InternalInvariant)
                  }
              }
            _ => Err(InternalInvariant)
          }
        }
      }
    Zero =>
      match state.output {
        None =>
          match @sturm.system(state.coefficients) {
            Ok(output) =>
              coordinate_advance({ ..state, output: Some(output), }, fuel)
            Err(_) => Err(InternalInvariant)
          }
        Some(output) => {
          let enclosure = coordinate_interval(
            state.h,
            @real.interval(state.current.parameter),
          )
          match @sturm.count_between(output, enclosure.lower, enclosure.upper) {
            Some(Succ(Zero)) =>
              match
                @real.number({
                  polynomial: @sturm.squarefree(output),
                  interval: enclosure,
                }) {
                Ok(value) =>
                  Ok(
                    CoordinateReady(value, {
                      point: state.original,
                      index: state.index,
                      polynomial: state.coefficients,
                      samples: @core.reverse(state.samples),
                      refined: @real.interval(state.current.parameter),
                      result: @real.root_certificate(value),
                    }),
                  )
                Err(_) => Err(InternalInvariant)
              }
            Some(Succ(Succ(_))) =>
              match fuel {
                Zero => Ok(CoordinatePaused(state))
                Succ(rest) =>
                  match @real.refine(state.current.parameter, Succ(Zero)) {
                    Ok(parameter) =>
                      coordinate_advance(
                        { ..state, current: { ..state.current, parameter, }, },
                        rest,
                      )
                    Err(_) => Err(InternalInvariant)
                  }
              }
            _ => Err(InternalInvariant)
          }
        }
      }
  }
}

///|
pub fn evaluate_coordinate(
  point : Point,
  index : @core.Nat,
  fuel : @core.Nat,
) -> Result[CoordinateProgress, VarietyError] {
  match coordinate_start(point, index) {
    Ok(state) => coordinate_advance(state, fuel)
    Err(error) => Err(error)
  }
}
