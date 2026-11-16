///|
fn same(a : @core.Nat, b : @core.Nat) -> Bool {
  @core.compare(a, b).equal(Equal)
}

///|
fn contains(xs : @core.Chain[@core.Nat], x : @core.Nat) -> Bool {
  @core.any(xs, fn(y) { same(x, y) })
}

///|
fn unique(xs : @core.Chain[@core.Nat]) -> Bool {
  match xs {
    Nil => true
    Cons(x, rest) => !contains(rest, x) && unique(rest)
  }
}

///|
fn lookup(game : Game, id : @core.Nat) -> Position? {
  fn seek(xs : @core.Chain[Position]) -> Position? {
    match xs {
      Nil => None
      Cons(position, rest) =>
        if same(position.id, id) {
          Some(position)
        } else {
          seek(rest)
        }
    }
  }
  seek(game.positions)
}

///|
fn identifiers(game : Game) -> @core.Chain[@core.Nat] {
  @core.map(game.positions, fn(position) { position.id })
}

///|
/// Reject duplicate labels, dead ends, duplicate edges and undefined targets.
pub fn game(positions : @core.Chain[Position]) -> Game? {
  let ids = @core.map(positions, fn(position) { position.id })
  match
    unique(ids) &&
    @core.all(positions, fn(position) {
      match position.successors {
        Nil => false
        _ =>
          unique(position.successors) &&
          @core.all(position.successors, fn(id) { contains(ids, id) })
      }
    }) {
    true => Some({ positions, })
    false => None
  }
}

///|
pub fn positions(game : Game) -> @core.Chain[Position] {
  game.positions
}

///|
fn opposite(player : Player) -> Player {
  match player {
    EvenPlayer => OddPlayer
    OddPlayer => EvenPlayer
  }
}

///|
fn priority_player(priority : @core.Nat) -> Player {
  let (_, odd) = @core.halve_nat(priority)
  if odd {
    OddPlayer
  } else {
    EvenPlayer
  }
}

///|
fn active_edges(
  position : Position,
  active : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  @core.filter(position.successors, fn(id) { contains(active, id) })
}

///|
fn without(
  active : @core.Chain[@core.Nat],
  removed : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  @core.filter(active, fn(id) { !contains(removed, id) })
}

///|
fn first_member(
  xs : @core.Chain[@core.Nat],
  wanted : @core.Chain[@core.Nat],
) -> @core.Nat? {
  match xs {
    Nil => None
    Cons(x, rest) =>
      if contains(wanted, x) {
        Some(x)
      } else {
        first_member(rest, wanted)
      }
  }
}

///|
fn empty_certificate() -> Certificate {
  { even_region: Nil, odd_region: Nil, even_strategy: Nil, odd_strategy: Nil, }
}

///|
fn region(certificate : Certificate, player : Player) -> @core.Chain[@core.Nat] {
  match player {
    EvenPlayer => certificate.even_region
    OddPlayer => certificate.odd_region
  }
}

///|
fn strategy(certificate : Certificate, player : Player) -> @core.Chain[Move] {
  match player {
    EvenPlayer => certificate.even_strategy
    OddPlayer => certificate.odd_strategy
  }
}

///|
fn move_at(moves : @core.Chain[Move], id : @core.Nat) -> @core.Nat? {
  match moves {
    Nil => None
    Cons(choice, rest) =>
      if same(choice.source, id) {
        Some(choice.target)
      } else {
        move_at(rest, id)
      }
  }
}
