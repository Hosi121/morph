///|
#derive(Eq, Debug)
pub(all) enum Expr {
  Constant(Bool)
  Variable(@core.Nat)
  Negation(Expr)
  Conjunction(Expr, Expr)
  Disjunction(Expr, Expr)
  Exclusive(Expr, Expr)
  Select(Expr, Expr, Expr)
}

///|
pub extend Expr with Eq::{equal, not_equal}

///|
pub extend Expr with Debug::{to_repr}

///|
fn same_bool(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, true) | (false, false) => true
    _ => false
  }
}

///|
fn same(a : Expr, b : Expr) -> Bool {
  match (a, b) {
    (Constant(a), Constant(b)) => same_bool(a, b)
    (Variable(a), Variable(b)) =>
      match @core.compare(a, b) {
        Equal => true
        _ => false
      }
    (Negation(a), Negation(b)) => same(a, b)
    (Conjunction(a, b), Conjunction(c, d))
    | (Disjunction(a, b), Disjunction(c, d))
    | (Exclusive(a, b), Exclusive(c, d)) => same(a, c) && same(b, d)
    (Select(a, b, c), Select(d, e, f)) => same(a, d) && same(b, e) && same(c, f)
    _ => false
  }
}

///|
pub fn negate(a : Expr) -> Expr {
  match a {
    Constant(a) => Constant(!a)
    Negation(a) => a
    _ => Negation(a)
  }
}

///|
pub fn conjunction(a : Expr, b : Expr) -> Expr {
  match (a, b) {
    (Constant(false), _) | (_, Constant(false)) => Constant(false)
    (Constant(true), _) => b
    (_, Constant(true)) => a
    _ =>
      match same(a, b) {
        true => a
        false => Conjunction(a, b)
      }
  }
}

///|
pub fn disjunction(a : Expr, b : Expr) -> Expr {
  match (a, b) {
    (Constant(true), _) | (_, Constant(true)) => Constant(true)
    (Constant(false), _) => b
    (_, Constant(false)) => a
    _ =>
      match same(a, b) {
        true => a
        false => Disjunction(a, b)
      }
  }
}

///|
pub fn exclusive(a : Expr, b : Expr) -> Expr {
  match (a, b) {
    (Constant(false), _) => b
    (_, Constant(false)) => a
    (Constant(true), _) => negate(b)
    (_, Constant(true)) => negate(a)
    _ =>
      match same(a, b) {
        true => Constant(false)
        false => Exclusive(a, b)
      }
  }
}

///|
pub fn select(c : Expr, a : Expr, b : Expr) -> Expr {
  match c {
    Constant(true) => a
    Constant(false) => b
    _ =>
      match same(a, b) {
        true => a
        false => Select(c, a, b)
      }
  }
}

///|
pub fn algebra() -> @boolean.Algebra[Expr] {
  {
    zero: Constant(false),
    one: Constant(true),
    negate,
    conjunction,
    disjunction,
    exclusive,
    select,
  }
}

///|
fn assigned(model : @sat.Model, variable : @core.Nat) -> Bool? {
  match model {
    Nil => None
    Cons(value, rest) =>
      match @core.compare(variable, value.variable) {
        Equal => Some(value.positive)
        _ => assigned(rest, variable)
      }
  }
}

///|
fn evaluate_raw(expr : Expr, model : @sat.Model) -> Bool? {
  match expr {
    Constant(value) => Some(value)
    Variable(variable) => assigned(model, variable)
    Negation(a) =>
      match evaluate_raw(a, model) {
        None => None
        Some(a) => Some(!a)
      }
    Conjunction(a, b) =>
      match evaluate_raw(a, model) {
        Some(false) => Some(false)
        Some(true) => evaluate_raw(b, model)
        None => None
      }
    Disjunction(a, b) =>
      match evaluate_raw(a, model) {
        Some(true) => Some(true)
        Some(false) => evaluate_raw(b, model)
        None => None
      }
    Exclusive(a, b) =>
      match (evaluate_raw(a, model), evaluate_raw(b, model)) {
        (Some(a), Some(b)) => Some(@boolean.exclusive(a, b))
        _ => None
      }
    Select(c, a, b) =>
      match evaluate_raw(c, model) {
        Some(true) => evaluate_raw(a, model)
        Some(false) => evaluate_raw(b, model)
        None => None
      }
  }
}

///|
pub fn evaluate(expr : Expr, model : @sat.Model) -> Bool? {
  match @sat.check_model(Nil, model) {
    false => None
    true => evaluate_raw(expr, model)
  }
}

///|
fn variables(
  expr : Expr,
  seen : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match expr {
    Constant(_) => seen
    Variable(variable) =>
      match
        @core.any(seen, fn(other) {
          match @core.compare(variable, other) {
            Equal => true
            _ => false
          }
        }) {
        true => seen
        false => Cons(variable, seen)
      }
    Negation(a) => variables(a, seen)
    Conjunction(a, b) | Disjunction(a, b) | Exclusive(a, b) =>
      variables(b, variables(a, seen))
    Select(c, a, b) => variables(b, variables(a, variables(c, seen)))
  }
}

///|
priv struct Context {
  next : @core.Nat
  reversed : @sat.Cnf
  memo : @core.Chain[(Expr, @sat.Literal)]
}

///|
fn memoized(
  memo : @core.Chain[(Expr, @sat.Literal)],
  expr : Expr,
) -> @sat.Literal? {
  match memo {
    Nil => None
    Cons((other, literal), rest) =>
      match same(expr, other) {
        true => Some(literal)
        false => memoized(rest, expr)
      }
  }
}

///|
fn two(a : @sat.Literal, b : @sat.Literal) -> @sat.Clause {
  Cons(a, Cons(b, Nil))
}

///|
fn three(a : @sat.Literal, b : @sat.Literal, c : @sat.Literal) -> @sat.Clause {
  Cons(a, Cons(b, Cons(c, Nil)))
}

///|
fn emit(context : Context, clauses : @sat.Cnf) -> Context {
  { ..context, reversed: @core.reverse_onto(clauses, context.reversed), }
}

///|
/// Memoization shares repeated structural expressions in the CNF DAG.
fn encode(expr : Expr, context : Context) -> (@sat.Literal, Context) {
  match memoized(context.memo, expr) {
    Some(literal) => (literal, context)
    None => {
      let (literal, context) = match expr {
        Variable(variable) =>
          (@sat.Literal::{ variable, positive: true, }, context)
        Negation(a) => {
          let (literal, context) = encode(a, context)
          (@sat.negate(literal), context)
        }
        _ => {
          let (arguments, context) = match expr {
            Constant(_) => (@core.Nil, context)
            Conjunction(a, b) | Disjunction(a, b) | Exclusive(a, b) => {
              let (a, context) = encode(a, context)
              let (b, context) = encode(b, context)
              (@core.Cons(a, Cons(b, Nil)), context)
            }
            Select(c, a, b) => {
              let (c, context) = encode(c, context)
              let (a, context) = encode(a, context)
              let (b, context) = encode(b, context)
              (@core.Cons(c, Cons(a, Cons(b, Nil))), context)
            }
            _ => (@core.Nil, context)
          }
          let output = @sat.Literal::{ variable: context.next, positive: true, }
          let neg_output = @sat.negate(output)
          let clauses : @sat.Cnf = match (expr, arguments) {
            (Constant(value), _) =>
              Cons(
                Cons(
                  match value {
                    true => output
                    false => neg_output
                  },
                  Nil,
                ),
                Nil,
              )
            (Conjunction(_, _), Cons(a, Cons(b, Nil))) =>
              Cons(
                three(@sat.negate(a), @sat.negate(b), output),
                Cons(two(a, neg_output), Cons(two(b, neg_output), Nil)),
              )
            (Disjunction(_, _), Cons(a, Cons(b, Nil))) =>
              Cons(
                three(a, b, neg_output),
                Cons(
                  two(@sat.negate(a), output),
                  Cons(two(@sat.negate(b), output), Nil),
                ),
              )
            (Exclusive(_, _), Cons(a, Cons(b, Nil))) =>
              Cons(
                three(@sat.negate(a), @sat.negate(b), neg_output),
                Cons(
                  three(a, b, neg_output),
                  Cons(
                    three(a, @sat.negate(b), output),
                    Cons(three(@sat.negate(a), b, output), Nil),
                  ),
                ),
              )
            (Select(_, _, _), Cons(c, Cons(a, Cons(b, Nil)))) =>
              Cons(
                three(@sat.negate(c), @sat.negate(a), output),
                Cons(
                  three(@sat.negate(c), a, neg_output),
                  Cons(
                    three(c, @sat.negate(b), output),
                    Cons(three(c, b, neg_output), Nil),
                  ),
                ),
              )
            _ => Nil
          }
          (output, emit({ ..context, next: Succ(context.next), }, clauses))
        }
      }
      (literal, { ..context, memo: Cons((expr, literal), context.memo), })
    }
  }
}

///|
#derive(Eq, Debug)
pub struct Encoding {
  cnf : @sat.Cnf
  assertions : @core.Chain[Expr]
  source_variables : @core.Chain[@core.Nat]
  gates : @core.Nat
}

///|
pub extend Encoding with Eq::{equal, not_equal}

///|
pub extend Encoding with Debug::{to_repr}

///|
pub fn compile(assertions : @core.Chain[Expr]) -> Encoding {
  let source_variables : @core.Chain[@core.Nat] = @core.fold_left(
    assertions,
    Nil,
    fn(seen, expr) { variables(expr, seen) },
  )
  let next = @core.fold_left(source_variables, @core.Zero, fn(next, variable) {
    match @core.compare(variable, next) {
      Less => next
      _ => Succ(variable)
    }
  })
  let initial = Context::{ next, reversed: Nil, memo: Nil, }
  let context = @core.fold_left(assertions, initial, fn(context, expr) {
    let (literal, context) = encode(expr, context)
    emit(context, Cons(Cons(literal, Nil), Nil))
  })
  {
    cnf: @core.reverse(context.reversed),
    assertions,
    source_variables,
    gates: @core.subtract(context.next, next),
  }
}

///|
pub fn cnf(encoding : Encoding) -> @sat.Cnf {
  encoding.cnf
}

///|
pub fn gates(encoding : Encoding) -> @core.Nat {
  encoding.gates
}

///|
/// Assert that at least one corresponding output differs. Unsat means equivalence.
pub fn miter(left : @core.Chain[Expr], right : @core.Chain[Expr]) -> Encoding? {
  match @core.zip(left, right) {
    None => None
    Some(pairs) => {
      let difference = @core.fold_left(pairs, Constant(false), fn(
        previous,
        pair,
      ) {
        let (a, b) = pair
        disjunction(previous, exclusive(a, b))
      })
      Some(compile(Cons(difference, Nil)))
    }
  }
}

///|
pub fn check_source_model(encoding : Encoding, model : @sat.Model) -> Bool {
  @sat.check_model(Nil, model) &&
  @core.all(encoding.assertions, fn(expr) {
    match evaluate_raw(expr, model) {
      Some(true) => true
      _ => false
    }
  })
}

///|
/// Complete missing source variables with false, then independently evaluate assertions.
pub fn source_model(encoding : Encoding, model : @sat.Model) -> @sat.Model? {
  match @sat.check_model(encoding.cnf, model) {
    false => None
    true => {
      let source = @core.map(encoding.source_variables, fn(variable) {
        let positive = match assigned(model, variable) {
          Some(value) => value
          None => false
        }
        @sat.Literal::{ variable, positive, }
      })
      match check_source_model(encoding, source) {
        true => Some(source)
        false => None
      }
    }
  }
}
