///|
#derive(Eq, Debug)
pub(all) enum AlgebraError {
  InvalidDefinition
  InvalidInterval
  ZeroDivisor
  InternalInvariant
}

///|
pub extend AlgebraError with Eq::{equal, not_equal}

///|
pub extend AlgebraError with Debug::{to_repr}

///|
fn qzero(value : @exact.Rational) -> Bool {
  @exact.rational_compare(value, @exact.rational_zero()).equal(Equal)
}

///|
fn trim(values : @core.Chain[@exact.Rational]) -> @core.Chain[@exact.Rational] {
  match values {
    Nil => Nil
    Cons(head, rest) => {
      let tail = trim(rest)
      match tail {
        Nil => if qzero(head) { Nil } else { Cons(head, Nil) }
        _ => Cons(head, tail)
      }
    }
  }
}

///|
fn dense_add(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      trim(Cons(@exact.rational_add(x, y), dense_add(xs, ys)))
  }
}

///|
fn dense_scale(
  a : @core.Chain[@exact.Rational],
  c : @exact.Rational,
) -> @core.Chain[@exact.Rational] {
  trim(@core.map(a, fn(x) { @exact.rational_multiply(x, c) }))
}

///|
fn dense_multiply(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  match a {
    Nil => Nil
    Cons(x, xs) =>
      dense_add(
        dense_scale(b, x),
        Cons(@exact.rational_zero(), dense_multiply(xs, b)),
      )
  }
}

///|
fn dense_evaluate(
  a : @core.Chain[@exact.Rational],
  x : @exact.Rational,
) -> @exact.Rational {
  match a {
    Nil => @exact.rational_zero()
    Cons(head, rest) =>
      @exact.rational_add(
        head,
        @exact.rational_multiply(x, dense_evaluate(rest, x)),
      )
  }
}

///|
fn dense(value : @poly.Polynomial) -> @core.Chain[@exact.Rational]? {
  fn walk(terms : @core.Chain[@poly.Term]) -> @core.Chain[@exact.Rational]? {
    match terms {
      Nil => Some(Nil)
      Cons(term, rest) =>
        match (term.exponents, walk(rest)) {
          (Cons(n, Nil), Some(tail)) =>
            Some(
              dense_add(
                @core.replicate_onto(
                  n,
                  @exact.rational_zero(),
                  Cons(term.coefficient, Nil),
                ),
                tail,
              ),
            )
          _ => None
        }
    }
  }
  if @poly.variables(value).equal(Succ(Zero)) {
    walk(@poly.terms(value))
  } else {
    None
  }
}

///|
fn sparse(values : @core.Chain[@exact.Rational]) -> @poly.Polynomial? {
  fn terms(
    values : @core.Chain[@exact.Rational],
    n : @core.Nat,
  ) -> @core.Chain[@poly.Term] {
    match values {
      Nil => Nil
      Cons(coefficient, rest) =>
        Cons({ coefficient, exponents: Cons(n, Nil), }, terms(rest, Succ(n)))
    }
  }
  match @poly.polynomial(Succ(Zero), terms(values, Zero)) {
    Ok(p) => Some(p)
    Err(_) => None
  }
}

///|
fn dense_degree(values : @core.Chain[@exact.Rational]) -> @core.Nat? {
  match @core.length(trim(values)) {
    Zero => None
    Succ(n) => Some(n)
  }
}

///|
fn positive_dense(
  value : @poly.Polynomial,
) -> (@core.Nat, @core.Chain[@exact.Rational])? {
  match dense(@poly.monic(value)) {
    Some(values) =>
      match dense_degree(values) {
        Some(Succ(_) as n) => Some((n, values))
        _ => None
      }
    None => None
  }
}

///|
fn rnat(value : @core.Nat) -> @exact.Rational {
  @exact.whole(@exact.positive(@binary.from_nat(value)))
}
