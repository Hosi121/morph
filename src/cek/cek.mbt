///|
/// Lexical closures capture immutable environments, rather than substituting ASTs.
#derive(Eq, Debug)
pub(all) enum Value {
  BoolValue(Bool)
  PairValue(Value, Value)
  Closure(@core.Nat, @infer.Expr, @core.Chain[(@core.Nat, Value)])
}

///|
pub extend Value with Eq::{equal, not_equal}

///|
pub extend Value with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub enum Frame {
  Argument(@infer.Expr, @core.Chain[(@core.Nat, Value)])
  Function(Value)
  Binding(@core.Nat, @infer.Expr, @core.Chain[(@core.Nat, Value)])
  PairLeft(@infer.Expr, @core.Chain[(@core.Nat, Value)])
  PairRight(Value)
  Project(Bool)
  Branch(@infer.Expr, @infer.Expr, @core.Chain[(@core.Nat, Value)])
}

///|
pub extend Frame with Eq::{equal, not_equal}

///|
pub extend Frame with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub enum Control {
  Evaluate(@infer.Expr, @core.Chain[(@core.Nat, Value)])
  Return(Value)
}

///|
pub extend Control with Eq::{equal, not_equal}

///|
pub extend Control with Debug::{to_repr}

///|
/// A resumable CEK machine: control, environment (inside control), continuation.
#derive(Eq, Debug)
pub struct Machine {
  control : Control
  continuation : @core.Chain[Frame]
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum RuntimeError {
  Unbound(@core.Nat)
  NotFunction
  NotPair
  NotBoolean
}

///|
pub extend RuntimeError with Eq::{equal, not_equal}

///|
pub extend RuntimeError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Done(Value)
  Suspended(Machine)
  Fault(RuntimeError)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
pub fn start(expression : @infer.Expr) -> Machine {
  { control: Evaluate(expression, Nil), continuation: Nil, }
}

///|
/// Exactly one transition, including recognizing a terminal return.
pub fn step(machine : Machine) -> Status {
  let continuation = machine.continuation
  fn next(control : Control, continuation : @core.Chain[Frame]) -> Status {
    Suspended({ control, continuation, })
  }
  match machine.control {
    Evaluate(expression, environment) =>
      match expression {
        Boolean(value) => next(Return(BoolValue(value)), continuation)
        Lambda(parameter, body) =>
          next(Return(Closure(parameter, body, environment)), continuation)
        Reference(name) => {
          fn lookup(entries : @core.Chain[(@core.Nat, Value)]) -> Value? {
            match entries {
              Nil => None
              Cons((other, value), rest) =>
                match @core.compare(name, other) {
                  Equal => Some(value)
                  _ => lookup(rest)
                }
            }
          }
          match lookup(environment) {
            Some(value) => next(Return(value), continuation)
            None => Fault(Unbound(name))
          }
        }
        Apply(function, argument) =>
          next(
            Evaluate(function, environment),
            Cons(Argument(argument, environment), continuation),
          )
        Let(name, value, body) =>
          next(
            Evaluate(value, environment),
            Cons(Binding(name, body, environment), continuation),
          )
        Tuple(left, right) =>
          next(
            Evaluate(left, environment),
            Cons(PairLeft(right, environment), continuation),
          )
        First(expression) =>
          next(
            Evaluate(expression, environment),
            Cons(Project(true), continuation),
          )
        Second(expression) =>
          next(
            Evaluate(expression, environment),
            Cons(Project(false), continuation),
          )
        Conditional(condition, yes, no) =>
          next(
            Evaluate(condition, environment),
            Cons(Branch(yes, no, environment), continuation),
          )
      }
    Return(value) =>
      match continuation {
        Nil => Done(value)
        Cons(frame, rest) =>
          match frame {
            Argument(expression, environment) =>
              next(
                Evaluate(expression, environment),
                Cons(Function(value), rest),
              )
            Function(function) =>
              match function {
                Closure(parameter, body, captured) =>
                  next(Evaluate(body, Cons((parameter, value), captured)), rest)
                _ => Fault(NotFunction)
              }
            Binding(name, expression, environment) =>
              next(Evaluate(expression, Cons((name, value), environment)), rest)
            PairLeft(expression, environment) =>
              next(
                Evaluate(expression, environment),
                Cons(PairRight(value), rest),
              )
            PairRight(left) => next(Return(PairValue(left, value)), rest)
            Project(first) =>
              match value {
                PairValue(left, right) =>
                  next(
                    Return(
                      match first {
                        true => left
                        false => right
                      },
                    ),
                    rest,
                  )
                _ => Fault(NotPair)
              }
            Branch(yes, no, environment) =>
              match value {
                BoolValue(condition) =>
                  next(
                    Evaluate(
                      match condition {
                        true => yes
                        false => no
                      },
                      environment,
                    ),
                    rest,
                  )
                _ => Fault(NotBoolean)
              }
          }
      }
  }
}

///|
/// Fuel bounds the total transition count; suspension retains the exact state.
pub fn run(machine : Machine, fuel : @core.Nat) -> Status {
  match fuel {
    Zero => Suspended(machine)
    Succ(rest) =>
      match step(machine) {
        Suspended(next) => run(next, rest)
        result => result
      }
  }
}

///|
pub fn evaluate(expression : @infer.Expr, fuel : @core.Nat) -> Status {
  run(start(expression), fuel)
}
