///|
/// Closed rational interval. Each axis must have lower < upper.
#derive(Eq, Debug)
pub(all) struct Axis {
  lower : @exact.Rational
  upper : @exact.Rational
}

///|
pub extend Axis with Eq::{equal, not_equal}

///|
pub extend Axis with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum BernsteinError {
  DimensionMismatch
  DegenerateBox
  InsufficientDegree
  InvalidCertificate
}

///|
pub extend BernsteinError with Eq::{equal, not_equal}

///|
pub extend BernsteinError with Debug::{to_repr}

///|
/// A dense tensor in Cartesian index order, first coordinate varying slowest.
/// Explicit indices make absent, reordered and duplicate entries rejectable.
#derive(Eq, Debug)
pub(all) struct Coefficient {
  index : @core.Chain[@core.Nat]
  value : @exact.Rational
}

///|
pub extend Coefficient with Eq::{equal, not_equal}

///|
pub extend Coefficient with Debug::{to_repr}

///|
/// Bounds are the minimum and maximum of the complete coefficient tensor.
#derive(Eq, Debug)
pub(all) struct BoundCertificate {
  source : @poly.Polynomial
  box : @core.Chain[Axis]
  degrees : @core.Chain[@core.Nat]
  coefficients : @core.Chain[Coefficient]
  lower : @exact.Rational
  upper : @exact.Rational
}

///|
pub extend BoundCertificate with Eq::{equal, not_equal}

///|
pub extend BoundCertificate with Debug::{to_repr}

///|
fn qnat(n : @core.Nat) -> @exact.Rational {
  @exact.whole(@exact.positive(@binary.from_nat(n)))
}

///|
fn power(x : @exact.Rational, n : @core.Nat) -> @exact.Rational {
  match n {
    Zero => @exact.rational_one()
    Succ(rest) => @exact.rational_multiply(x, power(x, rest))
  }
}

///|
/// Multiplicative binomial recurrence; division is by a positive natural.
fn choose(n : @core.Nat, k : @core.Nat) -> @exact.Rational {
  match (n, k) {
    (_, Zero) => @exact.rational_one()
    (Zero, Succ(_)) => @exact.rational_zero()
    (Succ(nrest), Succ(krest)) =>
      match @exact.rational_divide(qnat(n), qnat(k)) {
        Some(ratio) => @exact.rational_multiply(ratio, choose(nrest, krest))
        None => @exact.rational_zero()
      }
  }
}

///|
fn valid_box(box : @core.Chain[Axis]) -> Bool {
  @core.all(box, fn(axis) {
    @exact.rational_compare(axis.lower, axis.upper).equal(Less)
  })
}

///|
fn validate(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  degrees : @core.Chain[@core.Nat],
) -> Result[Unit, BernsteinError] {
  if !@core.length(box).equal(@poly.variables(p)) ||
    !@core.length(degrees).equal(@poly.variables(p)) {
    Err(DimensionMismatch)
  } else if !valid_box(box) {
    Err(DegenerateBox)
  } else if !@core.all(@poly.terms(p), fn(term) {
      @poly.divides(term.exponents, degrees)
    }) {
    Err(InsufficientDegree)
  } else {
    Ok(())
  }
}

///|
fn tensor_indices(
  degrees : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  match degrees {
    Nil => Cons(Nil, Nil)
    Cons(n, rest) => {
      let tails = tensor_indices(rest)
      @core.fold_left(@core.indices(Succ(n)), Nil, fn(found, i) {
        @core.append(found, @core.map(tails, fn(tail) { Cons(i, tail) }))
      })
    }
  }
}

///|
fn axis_power_coefficient(
  exponent : @core.Nat,
  index : @core.Nat,
  degree : @core.Nat,
  axis : Axis,
) -> @exact.Rational {
  let width = @exact.rational_subtract(axis.upper, axis.lower)
  @core.fold_left(
    @core.indices(Succ(@core.minimum(index, exponent))),
    @exact.rational_zero(),
    fn(sum, k) {
      let ratio = match
        @exact.rational_divide(choose(index, k), choose(degree, k)) {
        Some(value) => value
        None => @exact.rational_zero()
      }
      let affine = @exact.rational_multiply(
        choose(exponent, k),
        @exact.rational_multiply(
          power(axis.lower, @core.subtract(exponent, k)),
          power(width, k),
        ),
      )
      @exact.rational_add(sum, @exact.rational_multiply(affine, ratio))
    },
  )
}

///|
fn monomial_coefficient(
  exponents : @core.Chain[@core.Nat],
  index : @core.Chain[@core.Nat],
  degrees : @core.Chain[@core.Nat],
  box : @core.Chain[Axis],
) -> @exact.Rational {
  match (exponents, index, degrees, box) {
    (Nil, Nil, Nil, Nil) => @exact.rational_one()
    (Cons(e, et), Cons(i, it), Cons(n, nt), Cons(axis, axes)) =>
      @exact.rational_multiply(
        axis_power_coefficient(e, i, n, axis),
        monomial_coefficient(et, it, nt, axes),
      )
    _ => @exact.rational_zero()
  }
}

///|
fn extrema(
  coefficients : @core.Chain[Coefficient],
) -> (@exact.Rational, @exact.Rational)? {
  match coefficients {
    Nil => None
    Cons(head, rest) =>
      Some(
        @core.fold_left(rest, (head.value, head.value), fn(bounds, c) {
          let (lower, upper) = bounds
          (
            if @exact.rational_compare(c.value, lower).equal(Less) {
              c.value
            } else {
              lower
            },
            if @exact.rational_compare(c.value, upper).equal(Greater) {
              c.value
            } else {
              upper
            },
          )
        }),
      )
  }
}

///|
/// Exact power-to-tensor-Bernstein conversion on an arbitrary rational box.
/// Degree elevation is allowed; every component must cover the source degree.
/// The empty box represents the single point of zero-dimensional space.
pub fn bound(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  degrees : @core.Chain[@core.Nat],
) -> Result[BoundCertificate, BernsteinError] {
  match validate(p, box, degrees) {
    Err(error) => Err(error)
    Ok(_) => {
      let coefficients = @core.map(tensor_indices(degrees), fn(index) {
        let value = @core.fold_left(@poly.terms(p), @exact.rational_zero(), fn(
          sum,
          term,
        ) {
          @exact.rational_add(
            sum,
            @exact.rational_multiply(
              term.coefficient,
              monomial_coefficient(term.exponents, index, degrees, box),
            ),
          )
        })
        Coefficient::{ index, value, }
      })
      match extrema(coefficients) {
        None => Err(InvalidCertificate)
        Some((lower, upper)) =>
          Ok({ source: p, box, degrees, coefficients, lower, upper, })
      }
    }
  }
}

///|
/// For the independent checker, expand C(n,i)(x-a)^i(b-x)^(n-i)/(b-a)^n.
/// This uses binomial expansion in original coordinates, never the producer's
/// affine power-to-Bernstein coefficient formula.
fn expanded_axis(
  axis : Axis,
  n : @core.Nat,
  i : @core.Nat,
) -> @core.Chain[(@core.Nat, @exact.Rational)] {
  let other = @core.subtract(n, i)
  let factor = match
    @exact.rational_divide(
      choose(n, i),
      power(@exact.rational_subtract(axis.upper, axis.lower), n),
    ) {
    Some(value) => value
    None => @exact.rational_zero()
  }
  @core.fold_left(@core.indices(Succ(i)), Nil, fn(found, r) {
    let left = @exact.rational_multiply(
      choose(i, r),
      power(@exact.rational_negate(axis.lower), @core.subtract(i, r)),
    )
    @core.append(
      found,
      @core.map(@core.indices(Succ(other)), fn(s) {
        let right = @exact.rational_multiply(
          choose(other, s),
          @exact.rational_multiply(
            power(axis.upper, @core.subtract(other, s)),
            power(@exact.rational_negate(@exact.rational_one()), s),
          ),
        )
        (
          @core.add(r, s),
          @exact.rational_multiply(
            factor,
            @exact.rational_multiply(left, right),
          ),
        )
      }),
    )
  })
}

///|
fn expanded_basis(
  box : @core.Chain[Axis],
  degrees : @core.Chain[@core.Nat],
  index : @core.Chain[@core.Nat],
) -> @core.Chain[@poly.Term] {
  match (box, degrees, index) {
    (Nil, Nil, Nil) =>
      Cons({ coefficient: @exact.rational_one(), exponents: Nil, }, Nil)
    (Cons(axis, axes), Cons(n, ns), Cons(i, indices)) => {
      let tails = expanded_basis(axes, ns, indices)
      @core.fold_left(expanded_axis(axis, n, i), Nil, fn(found, pair) {
        let (e, value) = pair
        @core.append(
          found,
          @core.map(tails, fn(term) {
            {
              coefficient: @exact.rational_multiply(value, term.coefficient),
              exponents: Cons(e, term.exponents),
            }
          }),
        )
      })
    }
    _ => Nil
  }
}

///|
/// Checks the actual source, box, full tensor, exact extrema and a polynomial
/// identity obtained by independently expanding the Bernstein basis.
pub fn check_bound(
  p : @poly.Polynomial,
  box : @core.Chain[Axis],
  certificate : BoundCertificate,
) -> Bool {
  if !certificate.source.equal(p) || !certificate.box.equal(box) {
    return false
  }
  match validate(p, box, certificate.degrees) {
    Err(_) => false
    Ok(_) => {
      if !@core.map(certificate.coefficients, fn(c) { c.index }).equal(
          tensor_indices(certificate.degrees),
        ) {
        return false
      }
      match extrema(certificate.coefficients) {
        None => false
        Some((lower, upper)) => {
          if !lower.equal(certificate.lower) || !upper.equal(certificate.upper) {
            return false
          }
          let terms : @core.Chain[@poly.Term] = @core.fold_left(
            certificate.coefficients,
            @core.Nil,
            fn(found, c) {
              @core.append(
                found,
                @core.map(expanded_basis(box, certificate.degrees, c.index), fn(
                  term,
                ) {
                  {
                    coefficient: @exact.rational_multiply(
                      c.value,
                      term.coefficient,
                    ),
                    exponents: term.exponents,
                  }
                }),
              )
            },
          )
          match @poly.polynomial(@poly.variables(p), terms) {
            Ok(expanded) => expanded.equal(p)
            Err(_) => false
          }
        }
      }
    }
  }
}
