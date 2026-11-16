///|
/// Private homogeneous coefficient carrier. A ring factory is used only with
/// terms obtained from one checked arity. Neither this carrier nor its operation
/// dictionary is exposed, so coefficients from distinct factories cannot be
/// mixed through the public API. All operations below preserve vector length.
priv struct Coefficient {
  terms : @core.Chain[@poly.Term]
}

///|
fn coefficient_insert(
  term : @poly.Term,
  terms : @core.Chain[@poly.Term],
) -> @core.Chain[@poly.Term] {
  match @exact.nonzero(term.coefficient) {
    None => terms
    Some(_) =>
      match terms {
        Nil => Cons(term, Nil)
        Cons(head, rest) =>
          match @poly.compare_monomial(term.exponents, head.exponents) {
            Greater => Cons(term, terms)
            Less => Cons(head, coefficient_insert(term, rest))
            Equal => {
              let coefficient = @exact.rational_add(
                term.coefficient,
                head.coefficient,
              )
              match @exact.nonzero(coefficient) {
                None => rest
                Some(_) =>
                  Cons({ coefficient, exponents: head.exponents, }, rest)
              }
            }
          }
      }
  }
}

///|
fn coefficient_add(a : Coefficient, b : Coefficient) -> Coefficient {
  {
    terms: @core.fold_left(a.terms, b.terms, fn(found, term) {
      coefficient_insert(term, found)
    }),
  }
}

///|
/// Zero extension is total, and on checked homogeneous inputs both vectors end
/// together. Thus no zip failure or truncated dimension mismatch is hidden.
fn exponent_sum(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => Cons(@core.add(x, y), exponent_sum(xs, ys))
  }
}

///|
fn coefficient_multiply(a : Coefficient, b : Coefficient) -> Coefficient {
  {
    terms: @core.fold_left(a.terms, @core.Nil, fn(found, left) {
      @core.fold_left(b.terms, found, fn(found, right) {
        coefficient_insert(
          {
            coefficient: @exact.rational_multiply(
              left.coefficient,
              right.coefficient,
            ),
            exponents: exponent_sum(left.exponents, right.exponents),
          },
          found,
        )
      })
    }),
  }
}

///|
fn coefficient_negate(a : Coefficient) -> Coefficient {
  {
    terms: @core.map(a.terms, fn(term) {
      { ..term, coefficient: @exact.rational_negate(term.coefficient), }
    }),
  }
}

///|
fn coefficient_ring(variables : @core.Nat) -> @berkowitz.Ring[Coefficient] {
  {
    semiring: {
      zero: { terms: Nil, },
      one: {
        terms: Cons(
          {
            coefficient: @exact.rational_one(),
            exponents: @core.replicate(variables, Zero),
          },
          Nil,
        ),
      },
      plus: coefficient_add,
      times: coefficient_multiply,
    },
    negate: coefficient_negate,
  }
}

///|
fn coefficient_polynomial(
  value : Coefficient,
  variables : @core.Nat,
) -> Result[@poly.Polynomial, EliminationError] {
  match @poly.polynomial(variables, value.terms) {
    Ok(p) => Ok(p)
    Err(_) => Err(InternalDimension)
  }
}
