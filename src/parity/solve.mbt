///|
fn attract(
  game : Game,
  active : @core.Chain[@core.Nat],
  player : Player,
  target : @core.Chain[@core.Nat],
) -> Attraction {
  fn eligible(
    todo : @core.Chain[@core.Nat],
    current : @core.Chain[@core.Nat],
  ) -> (@core.Nat, Move?)? {
    match todo {
      Nil => None
      Cons(id, rest) =>
        if contains(current, id) {
          eligible(rest, current)
        } else {
          match lookup(game, id) {
            None => None
            Some(position) =>
              if position.owner.equal(player) {
                match first_member(position.successors, current) {
                  None => eligible(rest, current)
                  Some(target) => Some((id, Some({ source: id, target, })))
                }
              } else {
                let edges = active_edges(position, active)
                match edges {
                  Nil => eligible(rest, current)
                  _ =>
                    if @core.all(edges, fn(next) { contains(current, next) }) {
                      Some((id, None))
                    } else {
                      eligible(rest, current)
                    }
                }
              }
          }
        }
    }
  }
  fn expand(
    current : @core.Chain[@core.Nat],
    moves : @core.Chain[Move],
  ) -> Attraction {
    match eligible(active, current) {
      None => { vertices: current, strategy: moves, }
      Some((id, None)) => expand(Cons(id, current), moves)
      Some((id, Some(choice))) => expand(Cons(id, current), Cons(choice, moves))
    }
  }
  expand(target, Nil)
}

///|
fn maximum_priority(game : Game, active : @core.Chain[@core.Nat]) -> @core.Nat {
  @core.fold_left(active, Zero, fn(best, id) {
    match lookup(game, id) {
      None => best
      Some(position) =>
        match @core.compare(position.priority, best) {
          Greater => position.priority
          _ => best
        }
    }
  })
}

///|
fn top_choices(
  game : Game,
  active : @core.Chain[@core.Nat],
  targets : @core.Chain[@core.Nat],
  player : Player,
) -> @core.Chain[Move]? {
  match targets {
    Nil => Some(Nil)
    Cons(id, rest) =>
      match (lookup(game, id), top_choices(game, active, rest, player)) {
        (Some(position), Some(tail)) =>
          if position.owner.equal(player) {
            match active_edges(position, active) {
              Nil => None
              Cons(target, _) => Some(Cons({ source: id, target, }, tail))
            }
          } else {
            Some(tail)
          }
        _ => None
      }
  }
}

///|
fn first_combine(
  first : Certificate,
  player : Player,
  attraction : Attraction,
  choices : @core.Chain[Move],
) -> Certificate {
  let winning = @core.append(attraction.vertices, region(first, player))
  let moves = @core.append(
    attraction.strategy,
    @core.append(choices, strategy(first, player)),
  )
  match player {
    EvenPlayer =>
      {
        even_region: winning,
        odd_region: Nil,
        even_strategy: moves,
        odd_strategy: Nil,
      }
    OddPlayer =>
      {
        even_region: Nil,
        odd_region: winning,
        even_strategy: Nil,
        odd_strategy: moves,
      }
  }
}

///|
fn second_combine(
  second : Certificate,
  player : Player,
  attraction : Attraction,
  target_strategy : @core.Chain[Move],
) -> Certificate {
  let winning = @core.append(attraction.vertices, region(second, player))
  let moves = @core.append(
    attraction.strategy,
    @core.append(target_strategy, strategy(second, player)),
  )
  match player {
    EvenPlayer => { ..second, even_region: winning, even_strategy: moves, }
    OddPlayer => { ..second, odd_region: winning, odd_strategy: moves, }
  }
}

///|
pub fn start(game : Game) -> Machine {
  { game, frames: Cons(Enter(identifiers(game)), Nil), returned: None, }
}

///|
/// Explicit Zielonka call frames. A step may construct an entire attractor;
/// the fuel therefore does not bound arithmetic, graph scans, or wall time.
pub fn step(state : Machine) -> Progress {
  match state.frames {
    Nil =>
      match state.returned {
        None => Fault
        Some(certificate) =>
          match checked(state.game, certificate) {
            None => Fault
            Some(solution) => Complete(solution)
          }
      }
    Cons(frame, rest) =>
      match frame {
        Enter(Nil) =>
          Paused({ ..state, frames: rest, returned: Some(empty_certificate()), })
        Enter(active) => {
          let maximum = maximum_priority(state.game, active)
          let player = priority_player(maximum)
          let targets = @core.filter(active, fn(id) {
            match lookup(state.game, id) {
              None => false
              Some(position) => same(position.priority, maximum)
            }
          })
          let attraction = attract(state.game, active, player, targets)
          Paused({
            ..state,
            frames: Cons(
              Enter(without(active, attraction.vertices)),
              Cons(AfterFirst(active, player, targets, attraction), rest),
            ),
            returned: None,
          })
        }
        AfterFirst(active, player, targets, attraction) =>
          match state.returned {
            None => Fault
            Some(first) =>
              match region(first, opposite(player)) {
                Nil =>
                  match top_choices(state.game, active, targets, player) {
                    None => Fault
                    Some(choices) =>
                      Paused({
                        ..state,
                        frames: rest,
                        returned: Some(
                          first_combine(first, player, attraction, choices),
                        ),
                      })
                  }
                opponents => {
                  let other = opposite(player)
                  let back = attract(state.game, active, other, opponents)
                  Paused({
                    ..state,
                    frames: Cons(
                      Enter(without(active, back.vertices)),
                      Cons(
                        AfterSecond(other, back, strategy(first, other)),
                        rest,
                      ),
                    ),
                    returned: None,
                  })
                }
              }
          }
        AfterSecond(player, attraction, target_strategy) =>
          match state.returned {
            None => Fault
            Some(second) =>
              Paused({
                ..state,
                frames: rest,
                returned: Some(
                  second_combine(second, player, attraction, target_strategy),
                ),
              })
          }
      }
  }
}

///|
pub fn run(state : Machine, fuel : @core.Nat) -> Progress {
  match fuel {
    Zero => Paused(state)
    Succ(rest) =>
      match step(state) {
        Paused(next) => run(next, rest)
        result => result
      }
  }
}
