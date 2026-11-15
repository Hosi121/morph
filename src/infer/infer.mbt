///|
#derive(Eq, Debug)
pub(all) enum Head {
  BoolType
  FunctionType
  ProductType
}

///|
pub extend Head with Eq::{equal, not_equal}

///|
pub extend Head with Debug::{to_repr}

///|
pub type Type = @unify.Term[Head]

///|
#derive(Eq, Debug)
pub(all) enum Expr {
  Reference(@core.Nat)
  Lambda(@core.Nat, Expr)
  Apply(Expr, Expr)
  Let(@core.Nat, Expr, Expr)
  Boolean(Bool)
  Tuple(Expr, Expr)
  First(Expr)
  Second(Expr)
  Conditional(Expr, Expr, Expr)
}

///|
pub extend Expr with Eq::{equal, not_equal}

///|
pub extend Expr with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Scheme {
  quantified : @core.Chain[@core.Nat]
  body : Type
}

///|
pub extend Scheme with Eq::{equal, not_equal}

///|
pub extend Scheme with Debug::{to_repr}

///|
pub fn body(scheme : Scheme) -> Type {
  scheme.body
}

///|
pub fn quantified(scheme : Scheme) -> @core.Chain[@core.Nat] {
  scheme.quantified
}

///|
pub fn boolean_type() -> Type {
  Node(BoolType, Nil)
}

///|
pub fn arrow(a : Type, b : Type) -> Type {
  Node(FunctionType, Cons(a, Cons(b, Nil)))
}

///|
pub fn product(a : Type, b : Type) -> Type {
  Node(ProductType, Cons(a, Cons(b, Nil)))
}

///|
#derive(Eq, Debug)
pub(all) enum TypeError {
  UnboundVariable(@core.Nat)
  Unification(@unify.UnifyError[Head])
}

///|
pub extend TypeError with Eq::{equal, not_equal}

///|
pub extend TypeError with Debug::{to_repr}

///|
priv struct State {
  substitution : @unify.Substitution[Head]
  next : @core.Nat
}

///|
type Environment = @core.Chain[(@core.Nat, Scheme)]

///|
fn contains(names : @core.Chain[@core.Nat], name : @core.Nat) -> Bool {
  @core.any(names, fn(other) {
    match @core.compare(name, other) {
      Equal => true
      _ => false
    }
  })
}

///|
fn same_head(a : Head, b : Head) -> Bool {
  match (a, b) {
    (BoolType, BoolType)
    | (FunctionType, FunctionType)
    | (ProductType, ProductType) => true
    _ => false
  }
}

///|
fn[A, B] bind(
  result : Result[A, TypeError],
  next : (A) -> Result[B, TypeError],
) -> Result[B, TypeError] {
  match result {
    Ok(value) => next(value)
    Err(error) => Err(error)
  }
}

///|
fn fresh(state : State) -> (Type, State) {
  (
    Variable(state.next),
    { substitution: state.substitution, next: Succ(state.next), },
  )
}

///|
fn constrain(
  state : State,
  left : Type,
  right : Type,
) -> Result[State, TypeError] {
  match
    @unify.unify_into(state.substitution, Cons((left, right), Nil), same_head) {
    Err(error) => Err(Unification(error))
    Ok(substitution) => Ok({ substitution, next: state.next, })
  }
}

///|
fn rename(typ : Type, names : @core.Chain[(@core.Nat, @core.Nat)]) -> Type {
  fn lookup(
    entries : @core.Chain[(@core.Nat, @core.Nat)],
    name : @core.Nat,
  ) -> @core.Nat {
    match entries {
      Nil => name
      Cons((old, fresh), rest) =>
        match @core.compare(old, name) {
          Equal => fresh
          _ => lookup(rest, name)
        }
    }
  }
  match typ {
    Variable(name) => Variable(lookup(names, name))
    Node(head, children) =>
      Node(head, @core.map(children, fn(child) { rename(child, names) }))
  }
}

///|
fn allocate(
  names : @core.Chain[@core.Nat],
  next : @core.Nat,
) -> (@core.Chain[(@core.Nat, @core.Nat)], @core.Nat) {
  match names {
    Nil => (Nil, next)
    Cons(name, rest) => {
      let (tail, after) = allocate(rest, Succ(next))
      (Cons((name, next), tail), after)
    }
  }
}

///|
fn instantiate(scheme : Scheme, state : State) -> (Type, State) {
  let (renaming, next) = allocate(scheme.quantified, state.next)
  (rename(scheme.body, renaming), { substitution: state.substitution, next, })
}

///|
fn lookup(environment : Environment, name : @core.Nat) -> Scheme? {
  match environment {
    Nil => None
    Cons((other, scheme), rest) =>
      match @core.compare(name, other) {
        Equal => Some(scheme)
        _ => lookup(rest, name)
      }
  }
}

///|
/// Quantified variables are never subsequently unified: uses instantiate them
/// with globally fresh variables. Thus applying the accumulated substitution here
/// cannot capture a quantified variable created by this inference engine.
fn generalize(environment : Environment, typ : Type, state : State) -> Scheme {
  let env_free = @core.fold_left(environment, @core.Nil, fn(found, entry) {
    let (_, scheme) = entry
    let free = @core.filter(
      @unify.free_variables(@unify.apply(state.substitution, scheme.body)),
      fn(name) {
        match contains(scheme.quantified, name) {
          true => false
          false => true
        }
      },
    )
    @core.fold_left(free, found, fn(all, name) {
      match contains(all, name) {
        true => all
        false => @core.Cons(name, all)
      }
    })
  })
  let body = @unify.apply(state.substitution, typ)
  {
    body,
    quantified: @core.filter(@unify.free_variables(body), fn(name) {
      match contains(env_free, name) {
        true => false
        false => true
      }
    }),
  }
}

///|
fn project(
  expression : Expr,
  environment : Environment,
  state : State,
  first : Bool,
) -> Result[(Type, State), TypeError] {
  bind(infer_expression(expression, environment, state), fn(result) {
    let (typ, state) = result
    let (left, state) = fresh(state)
    let (right, state) = fresh(state)
    bind(constrain(state, typ, product(left, right)), fn(state) {
      Ok(
        (
          match first {
            true => left
            false => right
          },
          state,
        ),
      )
    })
  })
}

///|
/// A substitution-threaded Algorithm W variant over a pure AST.
fn infer_expression(
  expression : Expr,
  environment : Environment,
  state : State,
) -> Result[(Type, State), TypeError] {
  match expression {
    Boolean(_) => Ok((boolean_type(), state))
    Reference(name) =>
      match lookup(environment, name) {
        None => Err(UnboundVariable(name))
        Some(scheme) => Ok(instantiate(scheme, state))
      }
    Lambda(name, expression) => {
      let (parameter, state) = fresh(state)
      let scheme : Scheme = { quantified: Nil, body: parameter, }
      bind(
        infer_expression(expression, Cons((name, scheme), environment), state),
        fn(result) {
          let (body, state) = result
          Ok((arrow(parameter, body), state))
        },
      )
    }
    Apply(function, argument) =>
      bind(infer_expression(function, environment, state), fn(result) {
        let (function_type, state) = result
        bind(infer_expression(argument, environment, state), fn(result) {
          let (argument_type, state) = result
          let (result_type, state) = fresh(state)
          bind(
            constrain(state, function_type, arrow(argument_type, result_type)),
            fn(state) { Ok((result_type, state)) },
          )
        })
      })
    Let(name, value, expression) =>
      bind(infer_expression(value, environment, state), fn(result) {
        let (value_type, state) = result
        let scheme = generalize(environment, value_type, state)
        infer_expression(expression, Cons((name, scheme), environment), state)
      })
    Tuple(left, right) =>
      bind(infer_expression(left, environment, state), fn(result) {
        let (left_type, state) = result
        bind(infer_expression(right, environment, state), fn(result) {
          let (right_type, state) = result
          Ok((product(left_type, right_type), state))
        })
      })
    First(expression) => project(expression, environment, state, true)
    Second(expression) => project(expression, environment, state, false)
    Conditional(condition, yes, no) =>
      bind(infer_expression(condition, environment, state), fn(result) {
        let (condition_type, state) = result
        bind(constrain(state, condition_type, boolean_type()), fn(state) {
          bind(infer_expression(yes, environment, state), fn(result) {
            let (yes_type, state) = result
            bind(infer_expression(no, environment, state), fn(result) {
              let (no_type, state) = result
              bind(constrain(state, yes_type, no_type), fn(state) {
                Ok((yes_type, state))
              })
            })
          })
        })
      })
  }
}

///|
/// Infer the principal let-polymorphic scheme of a closed, nonrecursive expression.
pub fn infer(expression : Expr) -> Result[Scheme, TypeError] {
  let initial : State = { substitution: @unify.empty(), next: Zero, }
  bind(infer_expression(expression, Nil, initial), fn(result) {
    let (typ, state) = result
    Ok(generalize(Nil, typ, state))
  })
}

///|
/// Rename free type variables in order of first occurrence, for alpha comparison.
pub fn canonical(typ : Type) -> Type {
  let (renaming, _) = allocate(@unify.free_variables(typ), Zero)
  rename(typ, renaming)
}
