///|
/// A value plus its directional derivative, the algebra of dual numbers.
#derive(Eq, Debug)
pub(all) struct Dual {
  value : @exact.Rational
  tangent : @exact.Rational
}

///|
pub extend Dual with Eq::{equal, not_equal}

///|
pub extend Dual with Debug::{to_repr}

///|
pub fn forward(
  expression : Expr,
  environment : @core.Chain[(@core.Nat, @exact.Rational)],
  variable : @core.Nat,
) -> Dual? {
  let zero = @exact.rational_zero()
  let one = @exact.rational_one()
  let lift = fn(value : @exact.Rational) { Dual::{ value, tangent: zero, } }
  let ops : @algebra.Semiring[Dual] = {
    zero: lift(zero),
    one: lift(one),
    plus: fn(a, b) {
      {
        value: @exact.rational_add(a.value, b.value),
        tangent: @exact.rational_add(a.tangent, b.tangent),
      }
    },
    times: fn(a, b) {
      {
        value: @exact.rational_multiply(a.value, b.value),
        tangent: @exact.rational_add(
          @exact.rational_multiply(a.tangent, b.value),
          @exact.rational_multiply(a.value, b.tangent),
        ),
      }
    },
  }
  let values = @core.map(environment, fn(entry) {
    let (name, value) = entry
    let tangent = match @core.compare(name, variable) {
      Equal => one
      _ => zero
    }
    (name, Dual::{ value, tangent, })
  })
  evaluate_in(expression, values, ops, lift, fn(a) {
    {
      value: @exact.rational_negate(a.value),
      tangent: @exact.rational_negate(a.tangent),
    }
  })
}

///|
pub type Contributions = @core.Chain[(@core.Nat, @exact.Rational)]

///|
/// The tail parameter is a difference-list accumulator; each contribution is
/// allocated once, instead of repeatedly appending growing gradient lists.
type Pullback = (@exact.Rational, Contributions) -> Contributions

///|
priv struct Node {
  value : @exact.Rational
  pullback : Pullback
}

///|
#derive(Eq, Debug)
pub(all) struct Gradient {
  value : @exact.Rational
  partials : Contributions
}

///|
pub extend Gradient with Eq::{equal, not_equal}

///|
pub extend Gradient with Debug::{to_repr}

///|
fn accumulate(
  terms : Contributions,
  name : @core.Nat,
  value : @exact.Rational,
) -> Contributions {
  match @exact.nonzero(value) {
    None => terms
    Some(_) =>
      match terms {
        Nil => Cons((name, value), Nil)
        Cons((other, previous), rest) =>
          match @core.compare(name, other) {
            Less => Cons((name, value), terms)
            Greater => Cons((other, previous), accumulate(rest, name, value))
            Equal => {
              let sum = @exact.rational_add(previous, value)
              match @exact.nonzero(sum) {
                None => rest
                Some(_) => Cons((name, sum), rest)
              }
            }
          }
      }
  }
}

///|
/// Reverse-mode AD through pure pullback closures, one backward seed for all variables.
pub fn reverse(
  expression : Expr,
  environment : @core.Chain[(@core.Nat, @exact.Rational)],
) -> Gradient? {
  fn constant(value : @exact.Rational) -> Node {
    { value, pullback: fn(_, tail) { tail }, }
  }
  fn build(expression : Expr) -> Node? {
    match expression {
      Constant(value) => Some(constant(value))
      Variable(name) =>
        match lookup(environment, name) {
          None => None
          Some(value) =>
            Some({
              value,
              pullback: fn(seed, tail) { Cons((name, seed), tail) },
            })
        }
      Sum(a, b) =>
        match (build(a), build(b)) {
          (Some(left), Some(right)) =>
            Some({
              value: @exact.rational_add(left.value, right.value),
              pullback: fn(seed, tail) {
                (left.pullback)(seed, (right.pullback)(seed, tail))
              },
            })
          _ => None
        }
      Product(a, b) =>
        match (build(a), build(b)) {
          (Some(left), Some(right)) =>
            Some({
              value: @exact.rational_multiply(left.value, right.value),
              pullback: fn(seed, tail) {
                (left.pullback)(
                  @exact.rational_multiply(seed, right.value),
                  (right.pullback)(
                    @exact.rational_multiply(seed, left.value),
                    tail,
                  ),
                )
              },
            })
          _ => None
        }
      Negative(a) =>
        match build(a) {
          None => None
          Some(child) =>
            Some({
              value: @exact.rational_negate(child.value),
              pullback: fn(seed, tail) {
                (child.pullback)(@exact.rational_negate(seed), tail)
              },
            })
        }
      Power(_, Zero) => Some(constant(@exact.rational_one()))
      Power(a, Succ(rest) as n) =>
        match build(a) {
          None => None
          Some(child) => {
            let ops = @algebra.rationals()
            let value = algebra_power(
              child.value,
              @binary.bits(@binary.from_nat(n)),
              ops,
            )
            let coefficient = @exact.whole(@exact.positive(@binary.from_nat(n)))
            let slope = @exact.rational_multiply(
              coefficient,
              algebra_power(
                child.value,
                @binary.bits(@binary.from_nat(rest)),
                ops,
              ),
            )
            Some({
              value,
              pullback: fn(seed, tail) {
                (child.pullback)(@exact.rational_multiply(seed, slope), tail)
              },
            })
          }
        }
    }
  }
  match build(expression) {
    None => None
    Some(root) => {
      let raw = (root.pullback)(@exact.rational_one(), Nil)
      let partials : Contributions = @core.fold_left(raw, @core.Nil, fn(
        found,
        term,
      ) {
        let (name, value) = term
        accumulate(found, name, value)
      })
      Some({ value: root.value, partials, })
    }
  }
}

///|
/// Missing (including unused or cancelled) partials are exact zero.
pub fn partial(gradient : Gradient, variable : @core.Nat) -> @exact.Rational {
  match lookup(gradient.partials, variable) {
    Some(value) => value
    None => @exact.rational_zero()
  }
}
