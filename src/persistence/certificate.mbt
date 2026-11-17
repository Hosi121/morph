///|
/// A simplex-index interval [birth, death), including equal-grade pairs.
#derive(Eq, Debug)
pub(all) struct Pairing {
  birth : @core.Nat
  death : @core.Nat
}

///|
pub extend Pairing with Eq::{equal, not_equal}

///|
pub extend Pairing with Debug::{to_repr}

///|
/// A nonempty grade interval [birth, death), or [birth, infinity) when death
/// is None. Simplex indices preserve the chosen order within grade ties.
#derive(Eq, Debug)
pub(all) struct Bar {
  dimension : @core.Nat
  birth : @exact.Rational
  death : @exact.Rational?
  birth_simplex : @core.Nat
  death_simplex : @core.Nat?
}

///|
pub extend Bar with Eq::{equal, not_equal}

///|
pub extend Bar with Debug::{to_repr}

///|
/// Public, independently checkable sparse reduction witness R = D V. Columns
/// use increasing nonzero row indices; V is unit upper triangular and preserves
/// simplex dimension. The source and returned barcode are bound explicitly.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : Filtration
  reduced : @core.Chain[@core.Chain[@core.Nat]]
  change : @core.Chain[@core.Chain[@core.Nat]]
  pairings : @core.Chain[Pairing]
  bars : @core.Chain[Bar]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
fn pairings_of(
  columns : @core.Chain[@core.Chain[@core.Nat]],
  index : @core.Nat,
) -> @core.Chain[Pairing] {
  match columns {
    Nil => Nil
    Cons(column, rest) => {
      let tail = pairings_of(rest, Succ(index))
      match @core.last(column) {
        None => tail
        Some(birth) => Cons({ birth, death: index }, tail)
      }
    }
  }
}

///|
fn death_of(pairings : @core.Chain[Pairing], birth : @core.Nat) -> @core.Nat? {
  match pairings {
    Nil => None
    Cons(pair, rest) =>
      match pair.birth.equal(birth) {
        true => Some(pair.death)
        false => death_of(rest, birth)
      }
  }
}

///|
fn bars_of(
  source : Filtration,
  columns : @core.Chain[@core.Chain[@core.Nat]],
  pairings : @core.Chain[Pairing],
) -> @core.Chain[Bar]? {
  fn walk(
    todo : @core.Chain[Entry],
    reduced : @core.Chain[@core.Chain[@core.Nat]],
    index : @core.Nat,
  ) -> @core.Chain[Bar]? {
    match (todo, reduced) {
      (Nil, Nil) => Some(Nil)
      (Cons(entry, tail), Cons(column, rest)) =>
        match walk(tail, rest, Succ(index)) {
          None => None
          Some(bars) =>
            match column {
              Cons(_, _) => Some(bars)
              Nil =>
                match death_of(pairings, index) {
                  None =>
                    Some(Cons({
                      dimension: dimension(entry),
                      birth: entry.grade,
                      death: None,
                      birth_simplex: index,
                      death_simplex: None,
                    }, bars))
                  Some(death_index) =>
                    match @core.nth(source.entries, death_index) {
                      None => None
                      Some(death) =>
                        match @exact.rational_compare(entry.grade, death.grade) {
                          Equal => Some(bars)
                          Greater => None
                          Less =>
                            Some(Cons({
                              dimension: dimension(entry),
                              birth: entry.grade,
                              death: Some(death.grade),
                              birth_simplex: index,
                              death_simplex: Some(death_index),
                            }, bars))
                        }
                    }
                }
            }
        }
      _ => None
    }
  }
  walk(source.entries, columns, Zero)
}

///|
fn triangular(
  source : Filtration,
  columns : @core.Chain[@core.Chain[@core.Nat]],
) -> Bool {
  fn walk(
    todo : @core.Chain[Entry],
    change : @core.Chain[@core.Chain[@core.Nat]],
    index : @core.Nat,
  ) -> Bool {
    match (todo, change) {
      (Nil, Nil) => true
      (Cons(entry, tail), Cons(column, rest)) =>
        sparse_canonical(column, Succ(index)) &&
        @core.last(column).equal(Some(index)) &&
        @core.all(column, fn(row) {
          match @core.nth(source.entries, row) {
            None => false
            Some(candidate) => dimension(candidate).equal(dimension(entry))
          }
        }) &&
        walk(tail, rest, Succ(index))
      _ => false
    }
  }
  walk(source.entries, columns, Zero)
}

///|
/// Search-free checker. Reconstructs the boundary of the requested filtration,
/// checks canonical shapes, R = D V, triangular homogeneous V, distinct lows,
/// simplex pair dimensions and zero birth columns, and exact returned barcode.
/// It never invokes start, run, or another reduction algorithm.
pub fn check_result(
  source : Filtration,
  actual : @core.Chain[Bar],
  witness : Certificate,
) -> Bool {
  let size = @core.length(source.entries)
  let bound = witness.source.equal(source) &&
    validate(source.entries).equal(Some(source)) &&
    witness.bars.equal(actual) &&
    @core.length(witness.reduced).equal(size) &&
    @core.all(witness.reduced, fn(column) { sparse_canonical(column, size) }) &&
    triangular(source, witness.change) &&
    unique_pivots(witness.reduced)
  match bound {
    false => false
    true => {
      let boundary = boundary_columns(source)
      let identity = match @core.zip(witness.reduced, witness.change) {
        None => false
        Some(columns) =>
          @core.all(columns, fn(pair) {
            let (r, v) = pair
            linear_combination(boundary, v).equal(Some(r))
          })
      }
      let pairings = pairings_of(witness.reduced, Zero)
      let valid_pairs = @core.all(pairings, fn(pair) {
        match
          (
            @core.nth(source.entries, pair.birth),
            @core.nth(source.entries, pair.death),
            @core.nth(witness.reduced, pair.birth),
          ) {
          (Some(birth), Some(death), Some(Nil)) =>
            @core.compare(pair.birth, pair.death) is Less &&
            dimension(death).equal(Succ(dimension(birth)))
          _ => false
        }
      })
      identity && valid_pairs && witness.pairings.equal(pairings) &&
      bars_of(source, witness.reduced, pairings).equal(Some(actual))
    }
  }
}

///|
pub fn barcode(witness : Certificate) -> @core.Chain[Bar] {
  witness.bars
}

///|
pub fn pairs(witness : Certificate) -> @core.Chain[Pairing] {
  witness.pairings
}
