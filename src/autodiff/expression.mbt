///|
/// Polynomial expressions with exact rational constants.
#derive(Eq, Debug)
pub(all) enum Expr {
  Constant(@exact.Rational)
  Variable(@core.Nat)
  Sum(Expr, Expr)
  Product(Expr, Expr)
  Negative(Expr)
  Power(Expr, @core.Nat)
}

///|
pub extend Expr with Eq::{equal, not_equal}

///|
pub extend Expr with Debug::{to_repr}

///|
fn constant_zero(expression : Expr) -> Bool {
  match expression {
    Constant(value) =>
      match @exact.nonzero(value) {
        None => true
        _ => false
      }
    _ => false
  }
}

///|
fn constant_one(expression : Expr) -> Bool {
  match expression {
    Constant(value) =>
      match @exact.rational_compare(value, @exact.rational_one()) {
        Equal => true
        _ => false
      }
    _ => false
  }
}

///|
/// Smart constructors use polynomial identities over complete environments.
pub fn sum(a : Expr, b : Expr) -> Expr {
  match (a, b) {
    (Constant(x), Constant(y)) => Constant(@exact.rational_add(x, y))
    _ =>
      match (constant_zero(a), constant_zero(b)) {
        (true, _) => b
        (_, true) => a
        _ => Sum(a, b)
      }
  }
}

///|
pub fn product(a : Expr, b : Expr) -> Expr {
  match (a, b) {
    (Constant(x), Constant(y)) => Constant(@exact.rational_multiply(x, y))
    _ =>
      match
        (constant_zero(a), constant_zero(b), constant_one(a), constant_one(b)) {
        (true, _, _, _) | (_, true, _, _) => Constant(@exact.rational_zero())
        (_, _, true, _) => b
        (_, _, _, true) => a
        _ => Product(a, b)
      }
  }
}

///|
pub fn negative(a : Expr) -> Expr {
  match a {
    Constant(value) => Constant(@exact.rational_negate(value))
    Negative(body) => body
    _ => Negative(a)
  }
}

///|
pub fn power(a : Expr, n : @core.Nat) -> Expr {
  match n {
    Zero => Constant(@exact.rational_one())
    Succ(Zero) => a
    _ => Power(a, n)
  }
}

///|
fn[A] lookup(environment : @core.Chain[(@core.Nat, A)], name : @core.Nat) -> A? {
  match environment {
    Nil => None
    Cons((variable, value), rest) =>
      match @core.compare(variable, name) {
        Equal => Some(value)
        _ => lookup(rest, name)
      }
  }
}

///|
fn[A] algebra_power(
  base : A,
  bits : @core.Chain[Bool],
  ops : @algebra.Semiring[A],
) -> A {
  match bits {
    Nil => ops.one
    Cons(bit, rest) => {
      let half = algebra_power(base, rest, ops)
      let square = (ops.times)(half, half)
      match bit {
        false => square
        true => (ops.times)(base, square)
      }
    }
  }
}

///|
/// One evaluator interpreted in different algebras; missing variables are None.
pub fn[A] evaluate_in(
  expression : Expr,
  environment : @core.Chain[(@core.Nat, A)],
  ops : @algebra.Semiring[A],
  embed : (@exact.Rational) -> A,
  negate : (A) -> A,
) -> A? {
  match expression {
    Constant(value) => Some(embed(value))
    Variable(name) => lookup(environment, name)
    Sum(a, b) =>
      match
        (
          evaluate_in(a, environment, ops, embed, negate),
          evaluate_in(b, environment, ops, embed, negate),
        ) {
        (Some(x), Some(y)) => Some((ops.plus)(x, y))
        _ => None
      }
    Product(a, b) =>
      match
        (
          evaluate_in(a, environment, ops, embed, negate),
          evaluate_in(b, environment, ops, embed, negate),
        ) {
        (Some(x), Some(y)) => Some((ops.times)(x, y))
        _ => None
      }
    Negative(a) =>
      match evaluate_in(a, environment, ops, embed, negate) {
        None => None
        Some(value) => Some(negate(value))
      }
    Power(_, Zero) => Some(ops.one)
    Power(a, n) =>
      match evaluate_in(a, environment, ops, embed, negate) {
        None => None
        Some(value) =>
          Some(algebra_power(value, @binary.bits(@binary.from_nat(n)), ops))
      }
  }
}

///|
pub fn evaluate(
  expression : Expr,
  environment : @core.Chain[(@core.Nat, @exact.Rational)],
) -> @exact.Rational? {
  evaluate_in(
    expression,
    environment,
    @algebra.rationals(),
    fn(x) { x },
    @exact.rational_negate,
  )
}

///|
/// Formal symbolic derivative, using exact constants and local polynomial laws.
pub fn differentiate(expression : Expr, variable : @core.Nat) -> Expr {
  match expression {
    Constant(_) => Constant(@exact.rational_zero())
    Variable(name) =>
      Constant(
        match @core.compare(name, variable) {
          Equal => @exact.rational_one()
          _ => @exact.rational_zero()
        },
      )
    Sum(a, b) => sum(differentiate(a, variable), differentiate(b, variable))
    Product(a, b) =>
      sum(
        product(differentiate(a, variable), b),
        product(a, differentiate(b, variable)),
      )
    Negative(a) => negative(differentiate(a, variable))
    Power(_, Zero) => Constant(@exact.rational_zero())
    Power(a, Succ(rest) as n) =>
      product(
        product(
          Constant(@exact.whole(@exact.positive(@binary.from_nat(n)))),
          power(a, rest),
        ),
        differentiate(a, variable),
      )
  }
}
