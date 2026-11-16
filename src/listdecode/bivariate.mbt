///|
fn compare_monomial(a : Monomial, b : Monomial) -> @core.Ordering {
  match @core.compare(a.x, b.x) {
    Equal => @core.compare(a.y, b.y)
    order => order
  }
}

///|
fn insert(
  field : @primefield.Field,
  term : Term,
  terms : @core.Chain[Term],
) -> @core.Chain[Term] {
  if @binary.is_zero(term.coefficient) {
    return terms
  }
  match terms {
    Nil => Cons(term, Nil)
    Cons(head, rest) =>
      match compare_monomial(term.monomial, head.monomial) {
        Less => Cons(term, terms)
        Greater => Cons(head, insert(field, term, rest))
        Equal => {
          let coefficient = @modular.add(
            @primefield.modulus(field),
            term.coefficient,
            head.coefficient,
          )
          if @binary.is_zero(coefficient) {
            rest
          } else {
            Cons({ ..head, coefficient, }, rest)
          }
        }
      }
  }
}

///|
fn canonical_terms(
  field : @primefield.Field,
  terms : @core.Chain[Term],
) -> @core.Chain[Term] {
  @core.fold_left(terms, Nil, fn(accumulator, term) {
    insert(field, term, accumulator)
  })
}

///|
fn binomial(
  field : @primefield.Field,
  n : @core.Nat,
  k : @core.Nat,
) -> @binary.Binary {
  fn next(row : @core.Chain[@binary.Binary]) -> @core.Chain[@binary.Binary] {
    fn add_rows(
      a : @core.Chain[@binary.Binary],
      b : @core.Chain[@binary.Binary],
    ) -> @core.Chain[@binary.Binary] {
      match (a, b) {
        (Nil, _) => b
        (_, Nil) => a
        (Cons(x, xs), Cons(y, ys)) =>
          Cons(@modular.add(@primefield.modulus(field), x, y), add_rows(xs, ys))
      }
    }
    add_rows(row, Cons(@binary.zero(), row))
  }
  fn row(n : @core.Nat) -> @core.Chain[@binary.Binary] {
    match n {
      Zero => Cons(@binary.one(), Nil)
      Succ(rest) => next(row(rest))
    }
  }
  match @core.nth(row(n), k) {
    Some(value) => value
    None => @binary.zero()
  }
}

///|
fn fp_power(
  field : @primefield.Field,
  value : @binary.Binary,
  exponent : @core.Nat,
) -> @binary.Binary {
  @modular.power(@primefield.modulus(field), value, @binary.from_nat(exponent))
}

///|
fn hasse_term(
  field : @primefield.Field,
  monomial : Monomial,
  derivative : Monomial,
  x : @binary.Binary,
  y : @binary.Binary,
) -> @binary.Binary {
  if @core.compare(monomial.x, derivative.x) is Less ||
    @core.compare(monomial.y, derivative.y) is Less {
    return @binary.zero()
  }
  let arithmetic = @primefield.arithmetic(field)
  (arithmetic.multiply)(
    (arithmetic.multiply)(
      binomial(field, monomial.x, derivative.x),
      binomial(field, monomial.y, derivative.y),
    ),
    (arithmetic.multiply)(
      fp_power(field, x, @core.subtract(monomial.x, derivative.x)),
      fp_power(field, y, @core.subtract(monomial.y, derivative.y)),
    ),
  )
}

///|
fn hasse(
  field : @primefield.Field,
  polynomial : Interpolation,
  derivative : Monomial,
  x : @binary.Binary,
  y : @binary.Binary,
) -> @binary.Binary {
  let arithmetic = @primefield.arithmetic(field)
  @core.fold_left(polynomial.terms, arithmetic.zero, fn(sum, term) {
    (arithmetic.add)(
      sum,
      (arithmetic.multiply)(
        term.coefficient,
        hasse_term(field, term.monomial, derivative, x, y),
      ),
    )
  })
}

///|
fn normalize(polynomial : Interpolation) -> Interpolation {
  match polynomial.terms {
    Nil => polynomial
    Cons(first, _) => {
      let minimum = @core.fold_left(polynomial.terms, first.monomial.x, fn(
        minimum,
        term,
      ) {
        @core.minimum(minimum, term.monomial.x)
      })
      {
        terms: @core.map(polynomial.terms, fn(term) {
          {
            ..term,
            monomial: {
              ..term.monomial,
              x: @core.subtract(term.monomial.x, minimum),
            },
          }
        }),
      }
    }
  }
}

///|
/// Q(x, gamma+x*y), with all common powers of x removed afterward.
fn substitute(
  field : @primefield.Field,
  polynomial : Interpolation,
  gamma : @binary.Binary,
) -> Interpolation {
  let arithmetic = @primefield.arithmetic(field)
  let expanded = @core.fold_left(polynomial.terms, @core.Nil, fn(
    accumulator,
    term,
  ) {
    @core.fold_left(@core.indices(Succ(term.monomial.y)), accumulator, fn(
      accumulator,
      j,
    ) {
      let coefficient = (arithmetic.multiply)(
        term.coefficient,
        (arithmetic.multiply)(
          binomial(field, term.monomial.y, j),
          fp_power(field, gamma, @core.subtract(term.monomial.y, j)),
        ),
      )
      insert(
        field,
        { coefficient, monomial: { x: @core.add(term.monomial.x, j), y: j, }, },
        accumulator,
      )
    })
  })
  normalize({ terms: expanded, })
}

///|
fn[A] polynomial_result(
  result : Result[A, @fppoly.PolyError],
) -> Result[A, DecodeError] {
  match result {
    Ok(value) => Ok(value)
    Err(error) => Err(Polynomial(error))
  }
}

///|
fn polynomial_power(
  value : @fppoly.Polynomial,
  exponent : @core.Nat,
) -> Result[@fppoly.Polynomial, DecodeError] {
  match exponent {
    Zero => Ok(@fppoly.one(@fppoly.field_of(value)))
    Succ(rest) =>
      match polynomial_power(value, rest) {
        Err(error) => Err(error)
        Ok(power) => polynomial_result(@fppoly.multiply(value, power))
      }
  }
}

///|
/// Exact Q(x,f(x)) in Fp[x], independent of the RR transformations.
fn compose(
  field : @primefield.Field,
  polynomial : Interpolation,
  message : @core.Chain[@binary.Binary],
) -> Result[@fppoly.Polynomial, DecodeError] {
  let f = @fppoly.polynomial(field, message)
  fn add_terms(
    terms : @core.Chain[Term],
  ) -> Result[@fppoly.Polynomial, DecodeError] {
    match terms {
      Nil => Ok(@fppoly.zero(field))
      Cons(term, rest) =>
        match (polynomial_power(f, term.monomial.y), add_terms(rest)) {
          (Ok(power), Ok(tail)) => {
            let shifted = @fppoly.polynomial(
              field,
              @core.append(
                @core.replicate(term.monomial.x, @binary.zero()),
                @fppoly.coefficients(@fppoly.scale(power, term.coefficient)),
              ),
            )
            polynomial_result(@fppoly.add(shifted, tail))
          }
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  add_terms(polynomial.terms)
}
