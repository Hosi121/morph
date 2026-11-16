///|
fn unique_sources(moves : @core.Chain[Move]) -> Bool {
  unique(@core.map(moves, fn(choice) { choice.source }))
}

///|
fn reduced_edges(
  position : Position,
  player : Player,
  moves : @core.Chain[Move],
) -> @core.Chain[@core.Nat] {
  if position.owner.equal(player) {
    match move_at(moves, position.id) {
      None => Nil
      Some(target) => Cons(target, Nil)
    }
  } else {
    position.successors
  }
}

///|
/// Search for a cycle through start while retaining only priorities <= limit.
/// This is deliberately unrelated to Zielonka's attractor recursion.
fn bad_cycle(
  game : Game,
  player : Player,
  moves : @core.Chain[Move],
  start : Position,
) -> Bool {
  fn reach(
    todo : @core.Chain[@core.Nat],
    visited : @core.Chain[@core.Nat],
  ) -> Bool {
    match todo {
      Nil => false
      Cons(id, rest) =>
        match lookup(game, id) {
          None => false
          Some(position) =>
            match @core.compare(position.priority, start.priority) {
              Greater => reach(rest, visited)
              _ =>
                if same(id, start.id) {
                  true
                } else if contains(visited, id) {
                  reach(rest, visited)
                } else {
                  reach(
                    @core.append(reduced_edges(position, player, moves), rest),
                    Cons(id, visited),
                  )
                }
            }
        }
    }
  }
  reach(reduced_edges(start, player, moves), Nil)
}

///|
fn check_region(
  game : Game,
  player : Player,
  winning : @core.Chain[@core.Nat],
  moves : @core.Chain[Move],
) -> Bool {
  let sources_valid = unique_sources(moves) &&
    @core.all(moves, fn(choice) {
      match lookup(game, choice.source) {
        None => false
        Some(position) =>
          contains(winning, choice.source) &&
          position.owner.equal(player) &&
          contains(position.successors, choice.target) &&
          contains(winning, choice.target)
      }
    })
  sources_valid &&
  @core.all(winning, fn(id) {
    match lookup(game, id) {
      None => false
      Some(position) => {
        let closed = if position.owner.equal(player) {
          move_at(moves, id) is Some(_)
        } else {
          @core.all(position.successors, fn(target) {
            contains(winning, target)
          })
        }
        closed &&
        (
          priority_player(position.priority).equal(player) ||
          !bad_cycle(game, player, moves, position)
        )
      }
    }
  })
}

///|
/// Verify a partition, legal positional choices, closure under opposing moves,
/// and the absence of every wrong-parity maximum-priority cycle. No solving.
pub fn check(game : Game, certificate : Certificate) -> Bool {
  let all = @core.append(certificate.even_region, certificate.odd_region)
  unique(all) &&
  @core.length(all).equal(@core.length(game.positions)) &&
  @core.all(identifiers(game), fn(id) { contains(all, id) }) &&
  check_region(
    game,
    EvenPlayer,
    certificate.even_region,
    certificate.even_strategy,
  ) &&
  check_region(
    game,
    OddPlayer,
    certificate.odd_region,
    certificate.odd_strategy,
  )
}

///|
pub fn checked(game : Game, certificate : Certificate) -> Solution? {
  if check(game, certificate) {
    Some({ certificate, })
  } else {
    None
  }
}

///|
pub fn certificate(solution : Solution) -> Certificate {
  solution.certificate
}

///|
pub fn winner(solution : Solution, id : @core.Nat) -> Player? {
  if contains(solution.certificate.even_region, id) {
    Some(EvenPlayer)
  } else if contains(solution.certificate.odd_region, id) {
    Some(OddPlayer)
  } else {
    None
  }
}
