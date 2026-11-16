///|
/// Canonical ascending coefficients of a univariate integer polynomial.
#derive(Eq, Debug)
pub struct Polynomial {
  coefficients : @core.Chain[@exact.Integer]
}

///|
pub extend Polynomial with Eq::{equal, not_equal}

///|
pub extend Polynomial with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum AlgebraError {
  ZeroPolynomial
  InvalidLift
  InternalInvariant
}

///|
pub extend AlgebraError with Eq::{equal, not_equal}

///|
pub extend AlgebraError with Debug::{to_repr}

///|
fn izero() -> @exact.Integer {
  @exact.positive(@binary.zero())
}

///|
fn ione() -> @exact.Integer {
  @exact.positive(@binary.one())
}

///|
fn integer_zero(value : @exact.Integer) -> Bool {
  @binary.is_zero(@exact.magnitude(value))
}

///|
fn trim(values : @core.Chain[@exact.Integer]) -> @core.Chain[@exact.Integer] {
  match values {
    Nil => Nil
    Cons(head, tail) => {
      let rest = trim(tail)
      match rest {
        Nil => if integer_zero(head) { Nil } else { Cons(head, Nil) }
        _ => Cons(head, rest)
      }
    }
  }
}

///|
pub fn polynomial(coefficients : @core.Chain[@exact.Integer]) -> Polynomial {
  { coefficients: trim(coefficients), }
}

///|
pub fn coefficients(value : Polynomial) -> @core.Chain[@exact.Integer] {
  value.coefficients
}

///|
pub fn zero() -> Polynomial {
  polynomial(Nil)
}

///|
pub fn one() -> Polynomial {
  polynomial(Cons(ione(), Nil))
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
pub fn leading(value : Polynomial) -> @exact.Integer? {
  @core.last(value.coefficients)
}

///|
pub fn add(left : Polynomial, right : Polynomial) -> Polynomial {
  fn plus(
    a : @core.Chain[@exact.Integer],
    b : @core.Chain[@exact.Integer],
  ) -> @core.Chain[@exact.Integer] {
    match (a, b) {
      (Nil, _) => b
      (_, Nil) => a
      (Cons(x, xs), Cons(y, ys)) => Cons(@exact.add(x, y), plus(xs, ys))
    }
  }
  polynomial(plus(left.coefficients, right.coefficients))
}

///|
pub fn negate(value : Polynomial) -> Polynomial {
  polynomial(@core.map(value.coefficients, @exact.negate))
}

///|
pub fn subtract(left : Polynomial, right : Polynomial) -> Polynomial {
  add(left, negate(right))
}

///|
pub fn scale(value : Polynomial, scalar : @exact.Integer) -> Polynomial {
  polynomial(
    @core.map(value.coefficients, fn(x) { @exact.multiply(x, scalar) }),
  )
}

///|
fn shift(value : Polynomial, amount : @core.Nat) -> Polynomial {
  polynomial(@core.replicate_onto(amount, izero(), value.coefficients))
}

///|
pub fn multiply(left : Polynomial, right : Polynomial) -> Polynomial {
  fn times(values : @core.Chain[@exact.Integer]) -> Polynomial {
    match values {
      Nil => zero()
      Cons(head, rest) =>
        add(scale(right, head), shift(times(rest), Succ(Zero)))
    }
  }
  times(left.coefficients)
}

///|
fn power(value : Polynomial, exponent : @core.Nat) -> Polynomial {
  match exponent {
    Zero => one()
    Succ(rest) => multiply(value, power(value, rest))
  }
}

///|
fn divide_integer(
  value : @exact.Integer,
  divisor : @exact.Integer,
) -> @exact.Integer? {
  match @binary.divmod(@exact.magnitude(value), @exact.magnitude(divisor)) {
    Some((quotient, remainder)) =>
      if @binary.is_zero(remainder) {
        let positive = @exact.positive(quotient)
        Some(
          if @exact.negative(value).equal(@exact.negative(divisor)) {
            positive
          } else {
            @exact.negate(positive)
          },
        )
      } else {
        None
      }
    None => None
  }
}

///|
fn divide_coefficients(
  value : Polynomial,
  divisor : @exact.Integer,
) -> Polynomial? {
  fn walk(
    values : @core.Chain[@exact.Integer],
  ) -> @core.Chain[@exact.Integer]? {
    match values {
      Nil => Some(Nil)
      Cons(head, rest) =>
        match (divide_integer(head, divisor), walk(rest)) {
          (Some(q), Some(qs)) => Some(Cons(q, qs))
          _ => None
        }
    }
  }
  match walk(value.coefficients) {
    Some(values) => Some(polynomial(values))
    None => None
  }
}

///|
/// Exact division in Z[x]; returns None for a zero divisor or nondivisibility.
pub fn exact_divide(value : Polynomial, divisor : Polynomial) -> Polynomial? {
  fn divide(remainder : Polynomial, quotient : Polynomial) -> Polynomial? {
    match
      (degree(remainder), degree(divisor), leading(remainder), leading(divisor)) {
      (None, Some(_), _, _) => Some(quotient)
      (Some(a), Some(b), Some(x), Some(y)) =>
        match @core.compare(a, b) {
          Less => None
          _ =>
            match divide_integer(x, y) {
              None => None
              Some(c) => {
                let term = shift(polynomial(Cons(c, Nil)), @core.subtract(a, b))
                divide(
                  subtract(remainder, multiply(term, divisor)),
                  add(quotient, term),
                )
              }
            }
        }
      _ => None
    }
  }
  divide(value, zero())
}

///|
/// Signed content and primitive part with positive leading coefficient.
pub fn primitive(value : Polynomial) -> (@exact.Integer, Polynomial) {
  let content = @core.fold_left(value.coefficients, @binary.zero(), fn(g, c) {
    @binary.gcd(g, @exact.magnitude(c))
  })
  let signed = match leading(value) {
    Some(c) =>
      if @exact.negative(c) {
        @exact.negate(@exact.positive(content))
      } else {
        @exact.positive(content)
      }
    None => izero()
  }
  match divide_coefficients(value, signed) {
    Some(part) => (signed, part)
    None => (signed, zero())
  }
}

///|
pub fn derivative(value : Polynomial) -> Polynomial {
  fn walk(
    values : @core.Chain[@exact.Integer],
    exponent : @core.Nat,
  ) -> @core.Chain[@exact.Integer] {
    match values {
      Nil => Nil
      Cons(head, rest) =>
        Cons(
          @exact.multiply(head, @exact.positive(@binary.from_nat(exponent))),
          walk(rest, Succ(exponent)),
        )
    }
  }
  match value.coefficients {
    Nil => zero()
    Cons(_, rest) => polynomial(walk(rest, Succ(Zero)))
  }
}

///|
fn to_sparse(value : Polynomial) -> @sparse.Polynomial? {
  fn terms(
    values : @core.Chain[@exact.Integer],
    exponent : @core.Nat,
  ) -> @core.Chain[@sparse.Term] {
    match values {
      Nil => Nil
      Cons(head, rest) =>
        Cons(
          { coefficient: @exact.whole(head), exponents: Cons(exponent, Nil), },
          terms(rest, Succ(exponent)),
        )
    }
  }
  match @sparse.polynomial(Succ(Zero), terms(value.coefficients, Zero)) {
    Ok(p) => Some(p)
    Err(_) => None
  }
}

///|
fn lcm(left : @binary.Binary, right : @binary.Binary) -> @binary.Binary {
  match @binary.divmod(left, @binary.gcd(left, right)) {
    Some((quotient, _)) => @binary.multiply(quotient, right)
    None => @binary.zero()
  }
}

///|
fn clear_denominators(
  values : @core.Chain[@exact.Rational],
) -> (@binary.Binary, Polynomial) {
  let denominator = @core.fold_left(values, @binary.one(), fn(d, c) {
    lcm(d, @exact.denominator(c))
  })
  let coefficients = @core.map(values, fn(c) {
    match @binary.divmod(denominator, @exact.denominator(c)) {
      Some((q, _)) => @exact.multiply(@exact.numerator(c), @exact.positive(q))
      None => izero()
    }
  })
  (denominator, polynomial(coefficients))
}

///|
fn from_sparse(value : @sparse.Polynomial) -> Polynomial? {
  let terms = @sparse.terms(value)
  let denominator = @core.fold_left(terms, @binary.one(), fn(d, t) {
    lcm(d, @exact.denominator(t.coefficient))
  })
  fn walk(terms : @core.Chain[@sparse.Term]) -> Polynomial? {
    match terms {
      Nil => Some(zero())
      Cons(term, rest) =>
        match
          (
            term.exponents,
            walk(rest),
            @binary.divmod(denominator, @exact.denominator(term.coefficient)),
          ) {
          (Cons(exponent, Nil), Some(tail), Some((q, _))) =>
            Some(
              add(
                shift(
                  polynomial(
                    Cons(
                      @exact.multiply(
                        @exact.numerator(term.coefficient),
                        @exact.positive(q),
                      ),
                      Nil,
                    ),
                  ),
                  exponent,
                ),
                tail,
              ),
            )
          _ => None
        }
    }
  }
  match walk(terms) {
    Some(p) => {
      let (_, part) = primitive(p)
      Some(part)
    }
    None => None
  }
}

///|
fn gcd(left : Polynomial, right : Polynomial) -> Polynomial? {
  match (to_sparse(left), to_sparse(right)) {
    (Some(a), Some(b)) =>
      match @sparse.univariate_gcd(a, b) {
        Ok(p) => from_sparse(p)
        Err(_) => None
      }
    _ => None
  }
}

///|
fn reduce(value : Polynomial, field : @primefield.Field) -> @fppoly.Polynomial {
  let modulus = @primefield.modulus(field)
  @fppoly.polynomial(
    field,
    @core.map(value.coefficients, fn(c) { @modular.signed_reduce(modulus, c) }),
  )
}

///|
fn lift_representative(value : @fppoly.Polynomial) -> Polynomial {
  polynomial(@core.map(@fppoly.coefficients(value), @exact.positive))
}

///|
fn modulo(value : Polynomial, modulus : @modular.Modulus) -> Polynomial {
  polynomial(
    @core.map(value.coefficients, fn(c) {
      @exact.positive(@modular.signed_reduce(modulus, c))
    }),
  )
}

///|
fn centered(value : Polynomial, modulus : @modular.Modulus) -> Polynomial {
  let m = @modular.value(modulus)
  polynomial(
    @core.map(value.coefficients, fn(c) {
      let r = @modular.signed_reduce(modulus, c)
      match @binary.compare(@binary.double(r), m) {
        Greater =>
          match @binary.subtract(m, r) {
            Some(difference) => @exact.negate(@exact.positive(difference))
            None => izero()
          }
        _ => @exact.positive(r)
      }
    }),
  )
}

///|
fn product(values : @core.Chain[Polynomial]) -> Polynomial {
  @core.fold_left(values, one(), multiply)
}
