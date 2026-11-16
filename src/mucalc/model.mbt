///|
fn contains(values : @core.Chain[@core.Nat], wanted : @core.Nat) -> Bool {
  @core.any(values, fn(value) { value.equal(wanted) })
}

///|
fn distinct(values : @core.Chain[@core.Nat]) -> Bool {
  match values {
    Nil => true
    Cons(head, rest) => !contains(rest, head) && distinct(rest)
  }
}

///|
/// Repeated successor edges are canonicalized as a relation. Repeated labels and
/// state IDs are rejected; all edge targets must be declared state IDs.
pub fn model(states : @core.Chain[State]) -> Result[Model, CompileError] {
  let ids = @core.map(states, fn(state) { state.id })
  if !distinct(ids) {
    return Err(DuplicateState)
  }
  if !@core.all(states, fn(state) { distinct(state.propositions) }) {
    return Err(DuplicateLabel)
  }
  if !@core.all(states, fn(state) {
      @core.all(state.successors, fn(id) { contains(ids, id) })
    }) {
    return Err(UnknownSuccessor)
  }
  Ok({
    states: @core.map(states, fn(state) {
      { ..state, successors: deduplicate(state.successors, Nil), }
    }),
  })
}

///|
pub fn states(model : Model) -> @core.Chain[State] {
  model.states
}

///|
fn ordinal(model : Model, state_id : @core.Nat) -> @core.Nat? {
  fn visit(states : @core.Chain[State], index : @core.Nat) -> @core.Nat? {
    match states {
      Nil => None
      Cons(state, rest) =>
        if state.id.equal(state_id) {
          Some(index)
        } else {
          visit(rest, Succ(index))
        }
    }
  }
  visit(model.states, Zero)
}

///|
fn deduplicate(
  values : @core.Chain[@core.Nat],
  seen : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match values {
    Nil => Nil
    Cons(value, rest) =>
      if contains(seen, value) {
        deduplicate(rest, seen)
      } else {
        Cons(value, deduplicate(rest, Cons(value, seen)))
      }
  }
}
