///|
/// A simplex and its exact filtration grade. Vertices must be nonempty,
/// distinct and increasing; validate never silently sorts or closes input.
#derive(Eq, Debug)
pub(all) struct Entry {
  simplex : @core.Chain[@core.Nat]
  grade : @exact.Rational
}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Entry with Debug::{to_repr}

///|
/// A finite filtration, including the empty one. Each nonempty face occurs
/// before its coface; grades are nondecreasing and may be negative or equal.
/// Homology is unreduced over GF(2) in nonnegative dimensions.
#derive(Eq, Debug)
pub struct Filtration {
  entries : @core.Chain[Entry]
}

///|
pub extend Filtration with Eq::{equal, not_equal}

///|
pub extend Filtration with Debug::{to_repr}

///|
fn canonical(xs : @core.Chain[@core.Nat]) -> Bool {
  fn ascending(rest : @core.Chain[@core.Nat], previous : @core.Nat) -> Bool {
    match rest {
      Nil => true
      Cons(x, tail) => @core.compare(previous, x) is Less && ascending(tail, x)
    }
  }
  match xs {
    Nil => false
    Cons(x, rest) => ascending(rest, x)
  }
}

///|
fn faces(xs : @core.Chain[@core.Nat]) -> @core.Chain[@core.Chain[@core.Nat]] {
  fn walk(
    prefix : @core.Chain[@core.Nat],
    rest : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@core.Nat]] {
    match rest {
      Nil => Nil
      Cons(x, tail) =>
        Cons(@core.reverse_onto(prefix, tail), walk(Cons(x, prefix), tail))
    }
  }
  walk(Nil, xs)
}

///|
pub fn validate(input : @core.Chain[Entry]) -> Filtration? {
  fn walk(todo : @core.Chain[Entry], previous : @core.Chain[Entry]) -> Bool {
    match todo {
      Nil => true
      Cons(entry, rest) => {
        let unique = !@core.any(previous, fn(old) {
          old.simplex.equal(entry.simplex)
        })
        let ordered = match previous {
          Nil => true
          Cons(old, _) =>
            !(@exact.rational_compare(old.grade, entry.grade) is Greater)
        }
        let closed = @core.all(faces(entry.simplex), fn(face) {
          match face {
            Nil => true
            _ => @core.any(previous, fn(old) { old.simplex.equal(face) })
          }
        })
        canonical(entry.simplex) &&
        unique &&
        ordered &&
        closed &&
        walk(rest, Cons(entry, previous))
      }
    }
  }
  match walk(input, Nil) {
    true => Some({ entries: input, })
    false => None
  }
}

///|
pub fn entries(source : Filtration) -> @core.Chain[Entry] {
  source.entries
}

///|
fn dimension(entry : Entry) -> @core.Nat {
  match entry.simplex {
    Nil => Zero
    Cons(_, rest) => @core.length(rest)
  }
}

///|
/// Sparse columns of the actual simplicial boundary, in filtration coordinates.
/// Each column is the increasing list of its nonzero GF(2) row indices.
/// Vertex columns are empty (unreduced homology).
pub fn boundary_columns(
  source : Filtration,
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.map(source.entries, fn(entry) {
    let boundary = faces(entry.simplex)
    fn walk(
      todo : @core.Chain[Entry],
      index : @core.Nat,
    ) -> @core.Chain[@core.Nat] {
      match todo {
        Nil => Nil
        Cons(candidate, rest) => {
          let tail = walk(rest, Succ(index))
          match
            @core.any(boundary, fn(face) { face.equal(candidate.simplex) }) {
            true => Cons(index, tail)
            false => tail
          }
        }
      }
    }
    walk(source.entries, Zero)
  })
}
