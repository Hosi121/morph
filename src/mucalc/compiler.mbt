///|
fn position_number(
  node_count : @core.Nat,
  state_ordinal : @core.Nat,
  node : @core.Nat,
) -> @core.Nat {
  @core.add(@core.multiply(node_count, state_ordinal), node)
}

///|
fn compile_positions(
  model : Model,
  nodes : @core.Chain[Node],
  node_count : @core.Nat,
) -> Result[@core.Chain[@parity.Position], CompileError] {
  let true_sink = @core.multiply(@core.length(model.states), node_count)
  let false_sink : @core.Nat = Succ(true_sink)
  fn at_state(
    state : State,
    state_ordinal : @core.Nat,
    pending : @core.Chain[Node],
  ) -> Result[@core.Chain[@parity.Position], CompileError] {
    match pending {
      Nil => Ok(Nil)
      Cons(node, rest) => {
        let id = position_number(node_count, state_ordinal, node.id)
        fn same(target : @core.Nat) -> @core.Nat {
          position_number(node_count, state_ordinal, target)
        }
        fn modal_targets(
          successors : @core.Chain[@core.Nat],
          target : @core.Nat,
        ) -> Result[@core.Chain[@core.Nat], CompileError] {
          match successors {
            Nil => Ok(Nil)
            Cons(successor, rest) =>
              match (ordinal(model, successor), modal_targets(rest, target)) {
                (Some(index), Ok(tail)) =>
                  Ok(Cons(position_number(node_count, index, target), tail))
                _ => Err(InternalInvariant)
              }
          }
        }
        let (owner, successors) : (@parity.Player, @core.Chain[@core.Nat]) = match
          node.kind {
          Constant(value) =>
            (
              @parity.EvenPlayer,
              Cons(if value { true_sink } else { false_sink }, Nil),
            )
          Literal(proposition, positive) => {
            let present = contains(state.propositions, proposition)
            let holds = if positive { present } else { !present }
            (
              @parity.EvenPlayer,
              Cons(if holds { true_sink } else { false_sink }, Nil),
            )
          }
          Conjunction(a, b) =>
            (@parity.OddPlayer, Cons(same(a), Cons(same(b), Nil)))
          Disjunction(a, b) =>
            (@parity.EvenPlayer, Cons(same(a), Cons(same(b), Nil)))
          Unfold(target) | Jump(target) =>
            (@parity.EvenPlayer, Cons(same(target), Nil))
          SomeNext(target) | EveryNext(target) => {
            let (owner, dead_end) = match node.kind {
              SomeNext(_) => (@parity.EvenPlayer, false_sink)
              _ => (@parity.OddPlayer, true_sink)
            }
            let targets = match modal_targets(state.successors, target) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            (
              owner,
              match targets {
                Nil => Cons(dead_end, Nil)
                _ => targets
              },
            )
          }
        }
        match at_state(state, state_ordinal, rest) {
          Err(error) => Err(error)
          Ok(tail) =>
            Ok(Cons({ id, owner, priority: node.priority, successors, }, tail))
        }
      }
    }
  }
  fn all_states(
    states : @core.Chain[State],
    index : @core.Nat,
  ) -> Result[@core.Chain[@parity.Position], CompileError] {
    match states {
      Nil =>
        Ok(
          Cons(
            {
              id: true_sink,
              owner: @parity.EvenPlayer,
              priority: Zero,
              successors: Cons(true_sink, Nil),
            },
            Cons(
              {
                id: false_sink,
                owner: @parity.OddPlayer,
                priority: Succ(Zero),
                successors: Cons(false_sink, Nil),
              },
              Nil,
            ),
          ),
        )
      Cons(state, rest) =>
        match (at_state(state, index, nodes), all_states(rest, Succ(index))) {
          (Ok(head), Ok(tail)) => Ok(@core.append(head, tail))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  all_states(model.states, Zero)
}

///|
/// Compile a closed NNF formula into |states|*|syntax occurrences|+2 positions.
/// Scope is checked even on an empty model. Compilation is not a fuel step.
pub fn compile(
  model : Model,
  formula : Formula,
) -> Result[Compilation, CompileError] {
  match flatten(formula, Zero, Nil, Zero, binder_count(formula)) {
    Err(error) => Err(error)
    Ok((nodes, node_count)) =>
      match compile_positions(model, nodes, node_count) {
        Err(error) => Err(error)
        Ok(positions) =>
          match @parity.game(positions) {
            None => Err(InternalInvariant)
            Some(game) =>
              Ok({ model, formula, nodes, node_count, positions, game, })
          }
      }
  }
}

///|
pub fn model_of(compilation : Compilation) -> Model {
  compilation.model
}

///|
pub fn formula_of(compilation : Compilation) -> Formula {
  compilation.formula
}

///|
pub fn nodes(compilation : Compilation) -> @core.Chain[Node] {
  compilation.nodes
}

///|
pub fn positions(compilation : Compilation) -> @core.Chain[@parity.Position] {
  compilation.positions
}

///|
pub fn game(compilation : Compilation) -> @parity.Game {
  compilation.game
}

///|
pub fn position_id(
  compilation : Compilation,
  state_id : @core.Nat,
  node_id : @core.Nat,
) -> @core.Nat? {
  if !(@core.compare(node_id, compilation.node_count) is Less) {
    return None
  }
  match ordinal(compilation.model, state_id) {
    None => None
    Some(index) => Some(position_number(compilation.node_count, index, node_id))
  }
}
