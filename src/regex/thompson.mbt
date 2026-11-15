///|
pub enum Transition[A] {
  Silent(@core.Nat, @core.Nat)
  Consume(@core.Nat, A, @core.Nat)
}

///|
pub struct Nfa[A] {
  start : @core.Nat
  accept : @core.Nat
  transitions : @core.Chain[Transition[A]]
}

///|
priv struct Fragment[A] {
  start : @core.Nat
  accept : @core.Nat
  transitions : @core.Chain[Transition[A]]
  next : @core.Nat
}

///|
/// Independent Thompson construction; state names are fresh unary naturals.
pub fn[A] compile(expression : Regex[A]) -> Nfa[A] {
  fn build(expression : Regex[A], next : @core.Nat) -> Fragment[A] {
    match expression {
      Empty =>
        {
          start: next,
          accept: Succ(next),
          transitions: Nil,
          next: Succ(Succ(next)),
        }
      Epsilon =>
        {
          start: next,
          accept: Succ(next),
          transitions: Cons(Silent(next, Succ(next)), Nil),
          next: Succ(Succ(next)),
        }
      Atom(symbol) =>
        {
          start: next,
          accept: Succ(next),
          transitions: Cons(Consume(next, symbol, Succ(next)), Nil),
          next: Succ(Succ(next)),
        }
      Sequence(a, b) => {
        let left = build(a, next)
        let right = build(b, left.next)
        {
          start: left.start,
          accept: right.accept,
          next: right.next,
          transitions: Cons(
            Silent(left.accept, right.start),
            @core.append(left.transitions, right.transitions),
          ),
        }
      }
      Choice(a, b) => {
        let left = build(a, next)
        let right = build(b, left.next)
        let start = right.next
        let accept = @core.Succ(start)
        {
          start,
          accept,
          next: Succ(accept),
          transitions: Cons(
            Silent(start, left.start),
            Cons(
              Silent(start, right.start),
              Cons(
                Silent(left.accept, accept),
                Cons(
                  Silent(right.accept, accept),
                  @core.append(left.transitions, right.transitions),
                ),
              ),
            ),
          ),
        }
      }
      Repeat(body) => {
        let child = build(body, next)
        let start = child.next
        let accept = @core.Succ(start)
        {
          start,
          accept,
          next: Succ(accept),
          transitions: Cons(
            Silent(start, accept),
            Cons(
              Silent(start, child.start),
              Cons(
                Silent(child.accept, child.start),
                Cons(Silent(child.accept, accept), child.transitions),
              ),
            ),
          ),
        }
      }
    }
  }
  let fragment = build(expression, Zero)
  {
    start: fragment.start,
    accept: fragment.accept,
    transitions: fragment.transitions,
  }
}

///|
fn contains(states : @core.Chain[@core.Nat], state : @core.Nat) -> Bool {
  @core.any(states, fn(other) {
    match @core.compare(state, other) {
      Equal => true
      _ => false
    }
  })
}

///|
/// Visited states stop epsilon cycles, including star of nullable expressions.
fn[A] closure(
  nfa : Nfa[A],
  seeds : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  fn walk(
    todo : @core.Chain[@core.Nat],
    seen : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Nat] {
    match todo {
      Nil => seen
      Cons(state, rest) =>
        match contains(seen, state) {
          true => walk(rest, seen)
          false => {
            let pending = @core.fold_left(nfa.transitions, rest, fn(
              pending,
              edge,
            ) {
              match edge {
                Silent(from, to) =>
                  match @core.compare(from, state) {
                    Equal => Cons(to, pending)
                    _ => pending
                  }
                Consume(_, _, _) => pending
              }
            })
            walk(pending, Cons(state, seen))
          }
        }
    }
  }
  walk(seeds, Nil)
}

///|
/// Whole-word NFA simulation, with no derivative code shared with matches.
pub fn[A] nfa_matches(
  nfa : Nfa[A],
  word : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> Bool {
  let final_states = @core.fold_left(word, closure(nfa, Cons(nfa.start, Nil)), fn(
    states,
    symbol,
  ) {
    let seeds = @core.fold_left(nfa.transitions, @core.Nil, fn(found, edge) {
      match edge {
        Silent(_, _) => found
        Consume(from, value, to) =>
          match (contains(states, from), equal(value, symbol)) {
            (true, true) => @core.Cons(to, found)
            _ => found
          }
      }
    })
    closure(nfa, seeds)
  })
  contains(final_states, nfa.accept)
}
