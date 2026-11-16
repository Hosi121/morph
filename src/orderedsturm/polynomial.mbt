///|
/// Ascending coefficients in one fixed checked Q(alpha), including its selected
/// real embedding. This type does not construct Q(alpha,beta).
#derive(Debug)
pub struct Polynomial {
  field : @nf.Field
  coefficients : @core.Chain[@nf.Element]
}

///|
pub extend Polynomial with Debug::{to_repr}

///|
fn trim(values : @core.Chain[@nf.Element]) -> @core.Chain[@nf.Element] {
  match values {
    Nil => Nil
    Cons(head, rest) => {
      let tail = trim(rest)
      match tail {
        Nil => if @nf.is_zero(head) { Nil } else { Cons(head, Nil) }
        _ => Cons(head, tail)
      }
    }
  }
}

///|
pub fn polynomial(
  field : @nf.Field,
  coefficients : @core.Chain[@nf.Element],
) -> Result[Polynomial, OrderedError] {
  if @core.all(coefficients, fn(c) { @nf.same_field(field, @nf.parent(c)) }) {
    Ok({ field, coefficients: trim(coefficients), })
  } else {
    Err(DifferentField)
  }
}

///|
pub fn field_of(value : Polynomial) -> @nf.Field {
  value.field
}

///|
pub fn coefficients(value : Polynomial) -> @core.Chain[@nf.Element] {
  value.coefficients
}

///|
pub fn representatives(value : Polynomial) -> @core.Chain[@poly.Polynomial] {
  @core.map(value.coefficients, @nf.representative)
}

///|
pub fn zero(field : @nf.Field) -> Polynomial {
  { field, coefficients: Nil, }
}

///|
pub fn one(field : @nf.Field) -> Polynomial {
  { field, coefficients: Cons(@nf.one(field), Nil), }
}

///|
pub fn is_zero(value : Polynomial) -> Bool {
  match value.coefficients {
    Nil => true
    _ => false
  }
}

///|
pub fn degree(value : Polynomial) -> @core.Nat? {
  match @core.length(value.coefficients) {
    Zero => None
    Succ(n) => Some(n)
  }
}

///|
fn leading(value : Polynomial) -> @nf.Element? {
  @core.last(value.coefficients)
}

///|
pub fn equal(left : Polynomial, right : Polynomial) -> Bool {
  fn walk(a : @core.Chain[@nf.Element], b : @core.Chain[@nf.Element]) -> Bool {
    match (a, b) {
      (Nil, Nil) => true
      (Cons(a, as_), Cons(b, bs)) => @nf.equal(a, b) && walk(as_, bs)
      _ => false
    }
  }
  @nf.same_field(left.field, right.field) &&
  walk(left.coefficients, right.coefficients)
}

///|
pub fn add(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, OrderedError] {
  fn walk(
    a : @core.Chain[@nf.Element],
    b : @core.Chain[@nf.Element],
  ) -> Result[@core.Chain[@nf.Element], OrderedError] {
    match (a, b) {
      (Nil, _) => Ok(b)
      (_, Nil) => Ok(a)
      (Cons(a, as_), Cons(b, bs)) =>
        match (@nf.add(a, b), walk(as_, bs)) {
          (Ok(c), Ok(tail)) => Ok(Cons(c, tail))
          (Err(e), _) => Err(FieldFailure(e))
          (_, Err(e)) => Err(e)
        }
    }
  }
  if !@nf.same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    match walk(left.coefficients, right.coefficients) {
      Ok(coefficients) => polynomial(left.field, coefficients)
      Err(e) => Err(e)
    }
  }
}

///|
pub fn negate(value : Polynomial) -> Polynomial {
  {
    field: value.field,
    coefficients: @core.map(value.coefficients, @nf.negate),
  }
}

///|
pub fn subtract(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, OrderedError] {
  add(left, negate(right))
}

///|
pub fn scale(
  value : Polynomial,
  scalar : @nf.Element,
) -> Result[Polynomial, OrderedError] {
  fn walk(
    values : @core.Chain[@nf.Element],
  ) -> Result[@core.Chain[@nf.Element], OrderedError] {
    match values {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match (@nf.multiply(head, scalar), walk(rest)) {
          (Ok(c), Ok(cs)) => Ok(Cons(c, cs))
          (Err(e), _) => Err(FieldFailure(e))
          (_, Err(e)) => Err(e)
        }
    }
  }
  if !@nf.same_field(value.field, @nf.parent(scalar)) {
    Err(DifferentField)
  } else {
    match walk(value.coefficients) {
      Ok(coefficients) => polynomial(value.field, coefficients)
      Err(e) => Err(e)
    }
  }
}

///|
fn shift(value : Polynomial, amount : @core.Nat) -> Polynomial {
  if is_zero(value) {
    value
  } else {
    {
      field: value.field,
      coefficients: @core.replicate_onto(
        amount,
        @nf.zero(value.field),
        value.coefficients,
      ),
    }
  }
}

///|
pub fn multiply(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, OrderedError] {
  fn walk(
    values : @core.Chain[@nf.Element],
  ) -> Result[Polynomial, OrderedError] {
    match values {
      Nil => Ok(zero(left.field))
      Cons(head, rest) =>
        match (scale(right, head), walk(rest)) {
          (Ok(a), Ok(b)) => add(a, shift(b, Succ(Zero)))
          (Err(e), _) | (_, Err(e)) => Err(e)
        }
    }
  }
  if !@nf.same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    walk(left.coefficients)
  }
}

///|
#derive(Debug)
pub(all) struct Division {
  quotient : Polynomial
  remainder : Polynomial
}

///|
pub extend Division with Debug::{to_repr}

///|
pub fn divide(
  value : Polynomial,
  divisor : Polynomial,
) -> Result[Division, OrderedError] {
  fn walk(
    remainder : Polynomial,
    quotient : Polynomial,
    inv : @nf.Element,
    divisor_degree : @core.Nat,
  ) -> Result[Division, OrderedError] {
    match (degree(remainder), leading(remainder)) {
      (None, _) => Ok({ quotient, remainder, })
      (Some(n), Some(lc)) =>
        if @core.compare(n, divisor_degree).equal(Less) {
          Ok({ quotient, remainder, })
        } else {
          match @nf.multiply(lc, inv) {
            Err(e) => Err(FieldFailure(e))
            Ok(c) => {
              let term = shift(
                { field: value.field, coefficients: Cons(c, Nil), },
                @core.subtract(n, divisor_degree),
              )
              match multiply(term, divisor) {
                Err(e) => Err(e)
                Ok(product) =>
                  match (subtract(remainder, product), add(quotient, term)) {
                    (Ok(next), Ok(quotient)) =>
                      if is_zero(next) ||
                        (match degree(next) {
                          Some(d) => @core.compare(d, n).equal(Less)
                          None => true
                        }) {
                        walk(next, quotient, inv, divisor_degree)
                      } else {
                        Err(InternalInvariant)
                      }
                    (Err(e), _) | (_, Err(e)) => Err(e)
                  }
              }
            }
          }
        }
      _ => Err(InternalInvariant)
    }
  }
  if !@nf.same_field(value.field, divisor.field) {
    Err(DifferentField)
  } else {
    match (degree(divisor), leading(divisor)) {
      (Some(n), Some(lc)) =>
        match @nf.inverse(lc) {
          Ok(Some(inv)) => walk(value, zero(value.field), inv, n)
          Ok(None) => Err(ZeroDivisor)
          Err(e) => Err(FieldFailure(e))
        }
      _ => Err(ZeroDivisor)
    }
  }
}

///|
pub fn derivative(value : Polynomial) -> Result[Polynomial, OrderedError] {
  fn walk(
    values : @core.Chain[@nf.Element],
    n : @core.Nat,
  ) -> Result[@core.Chain[@nf.Element], OrderedError] {
    match values {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match
          (
            @nf.multiply(
              head,
              @nf.rational(
                value.field,
                @exact.whole(@exact.positive(@binary.from_nat(n))),
              ),
            ),
            walk(rest, Succ(n)),
          ) {
          (Ok(c), Ok(cs)) => Ok(Cons(c, cs))
          (Err(e), _) => Err(FieldFailure(e))
          (_, Err(e)) => Err(e)
        }
    }
  }
  match value.coefficients {
    Nil => Ok(value)
    Cons(_, rest) =>
      match walk(rest, Succ(Zero)) {
        Ok(coefficients) => polynomial(value.field, coefficients)
        Err(e) => Err(e)
      }
  }
}

///|
pub fn monic(value : Polynomial) -> Result[Polynomial, OrderedError] {
  match leading(value) {
    None => Ok(value)
    Some(lc) =>
      match @nf.inverse(lc) {
        Ok(Some(inv)) => scale(value, inv)
        Ok(None) => Err(InternalInvariant)
        Err(e) => Err(FieldFailure(e))
      }
  }
}

///|
pub fn evaluate(
  value : Polynomial,
  point : @exact.Rational,
) -> Result[@nf.Element, OrderedError] {
  let x = @nf.rational(value.field, point)
  fn walk(
    values : @core.Chain[@nf.Element],
  ) -> Result[@nf.Element, OrderedError] {
    match values {
      Nil => Ok(@nf.zero(value.field))
      Cons(head, rest) =>
        match walk(rest) {
          Err(e) => Err(e)
          Ok(tail) =>
            match @nf.multiply(x, tail) {
              Err(e) => Err(FieldFailure(e))
              Ok(p) =>
                match @nf.add(head, p) {
                  Ok(c) => Ok(c)
                  Err(e) => Err(FieldFailure(e))
                }
            }
        }
    }
  }
  walk(value.coefficients)
}

///|
fn decode(
  field : @nf.Field,
  raw : @core.Chain[@poly.Polynomial],
) -> Result[Polynomial, OrderedError] {
  fn walk(
    values : @core.Chain[@poly.Polynomial],
  ) -> Result[@core.Chain[@nf.Element], OrderedError] {
    match values {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match (@nf.element(field, head), walk(rest)) {
          (Ok(c), Ok(cs)) =>
            if @nf.representative(c).equal(head) {
              Ok(Cons(c, cs))
            } else {
              Err(InvalidCertificate)
            }
          (Err(_), _) => Err(InvalidCertificate)
          (_, Err(e)) => Err(e)
        }
    }
  }
  match walk(raw) {
    Ok(cs) =>
      match polynomial(field, cs) {
        Ok(p) =>
          if representatives(p).equal(raw) {
            Ok(p)
          } else {
            Err(InvalidCertificate)
          }
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}
