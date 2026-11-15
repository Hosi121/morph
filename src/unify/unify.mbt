///|
/// Finite first-order terms, parameterized by the constructor alphabet.
#derive(Eq, Debug)
pub(all) enum Term[S] {
  Variable(@core.Nat)
  Node(S, @core.Chain[Term[S]])
}

///|
pub extend Term with Eq::{equal, not_equal}

///|
pub extend Term with Debug::{to_repr}

///|
/// Opaque, acyclic, idempotent substitution maintained by the unifier.
#derive(Eq, Debug)
pub struct Substitution[S] {
  bindings : @core.Chain[(@core.Nat, Term[S])]
}

///|
pub extend Substitution with Eq::{equal, not_equal}

///|
pub extend Substitution with Debug::{to_repr}

///|
pub fn[S] empty() -> Substitution[S] {
  { bindings: Nil, }
}

///|
pub fn[S] bindings(
  substitution : Substitution[S],
) -> @core.Chain[(@core.Nat, Term[S])] {
  substitution.bindings
}

///|
pub fn[S] apply(substitution : Substitution[S], term : Term[S]) -> Term[S] {
  fn lookup(
    xs : @core.Chain[(@core.Nat, Term[S])],
    variable : @core.Nat,
  ) -> Term[S]? {
    match xs {
      Nil => None
      Cons((name, value), rest) =>
        match @core.compare(name, variable) {
          Equal => Some(value)
          _ => lookup(rest, variable)
        }
    }
  }
  match term {
    Variable(variable) =>
      match lookup(substitution.bindings, variable) {
        None => term
        Some(value) => apply(substitution, value)
      }
    Node(symbol, children) =>
      Node(
        symbol,
        @core.map(children, fn(child) { apply(substitution, child) }),
      )
  }
}

///|
pub fn[S] occurs(variable : @core.Nat, term : Term[S]) -> Bool {
  match term {
    Variable(other) =>
      match @core.compare(variable, other) {
        Equal => true
        _ => false
      }
    Node(_, children) =>
      @core.any(children, fn(child) { occurs(variable, child) })
  }
}

///|
fn[S] replace(variable : @core.Nat, value : Term[S], term : Term[S]) -> Term[S] {
  match term {
    Variable(other) =>
      match @core.compare(variable, other) {
        Equal => value
        _ => term
      }
    Node(symbol, children) =>
      Node(
        symbol,
        @core.map(children, fn(child) { replace(variable, value, child) }),
      )
  }
}

///|
fn[S] bind(
  substitution : Substitution[S],
  variable : @core.Nat,
  value : Term[S],
) -> Substitution[S] {
  let updated = @core.map(substitution.bindings, fn(binding) {
    let (name, old) = binding
    (name, replace(variable, value, old))
  })
  { bindings: Cons((variable, value), updated), }
}

///|
#derive(Eq, Debug)
pub(all) enum UnifyError[S] {
  OccursCheck(@core.Nat, Term[S])
  SymbolMismatch(S, S)
  ArityMismatch
}

///|
pub extend UnifyError with Eq::{equal, not_equal}

///|
pub extend UnifyError with Debug::{to_repr}

///|
/// Extend a solved substitution. Constructor equality must be an equivalence.
pub fn[S] unify_into(
  substitution : Substitution[S],
  equations : @core.Chain[(Term[S], Term[S])],
  same_symbol : (S, S) -> Bool,
) -> Result[Substitution[S], UnifyError[S]] {
  match equations {
    Nil => Ok(substitution)
    Cons((left, right), rest) => {
      let a = apply(substitution, left)
      let b = apply(substitution, right)
      match (a, b) {
        (Variable(x), Variable(y)) =>
          match @core.compare(x, y) {
            Equal => unify_into(substitution, rest, same_symbol)
            _ => unify_into(bind(substitution, x, b), rest, same_symbol)
          }
        (Variable(x), _) =>
          match occurs(x, b) {
            true => Err(OccursCheck(x, b))
            false => unify_into(bind(substitution, x, b), rest, same_symbol)
          }
        (_, Variable(y)) =>
          match occurs(y, a) {
            true => Err(OccursCheck(y, a))
            false => unify_into(bind(substitution, y, a), rest, same_symbol)
          }
        (Node(x, xs), Node(y, ys)) =>
          match same_symbol(x, y) {
            false => Err(SymbolMismatch(x, y))
            true =>
              match @core.zip(xs, ys) {
                None => Err(ArityMismatch)
                Some(children) =>
                  unify_into(
                    substitution,
                    @core.append(children, rest),
                    same_symbol,
                  )
              }
          }
      }
    }
  }
}

///|
/// First-order unification with an occurs check, producing a most general unifier.
pub fn[S] unify(
  equations : @core.Chain[(Term[S], Term[S])],
  same_symbol : (S, S) -> Bool,
) -> Result[Substitution[S], UnifyError[S]] {
  unify_into(empty(), equations, same_symbol)
}

///|
pub fn[S] free_variables(term : Term[S]) -> @core.Chain[@core.Nat] {
  fn visit(
    term : Term[S],
    found : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Nat] {
    match term {
      Variable(variable) =>
        match
          @core.any(found, fn(other) {
            match @core.compare(variable, other) {
              Equal => true
              _ => false
            }
          }) {
          true => found
          false => Cons(variable, found)
        }
      Node(_, children) =>
        @core.fold_left(children, found, fn(state, child) {
          visit(child, state)
        })
    }
  }
  @core.reverse(visit(term, Nil))
}
