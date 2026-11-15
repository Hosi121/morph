///|
#derive(Eq, Debug)
struct Frame {
  primary : @core.Chain[@binary.Binary]
  rows : @core.Chain[(@core.Nat, @core.Chain[@binary.Binary])]
  selected : @core.Chain[@core.Nat]
}

///|
pub extend Frame with Eq::{equal, not_equal}

///|
pub extend Frame with Debug::{to_repr}

///|
/// Persistent DFS stack. Copying a state permits deterministic replay.
#derive(Eq, Debug)
pub struct Search {
  pending : @core.Chain[Frame]
}

///|
pub extend Search with Eq::{equal, not_equal}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Found(@core.Chain[@core.Nat], Search)
  Pending(Search)
  Exhausted
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn enumerate(problem : Problem) -> Search {
  {
    pending: Cons(
      {
        primary: problem.indexed_primary,
        rows: problem.indexed_rows,
        selected: Nil,
      },
      Nil,
    ),
  }
}

///|
/// Spend at most fuel DFS-node expansions; return one solution and its continuation.
/// After primary coverage, include/exclude optional rows too, including empty rows.
/// Fuel bounds node expansions, not time or memory spent expanding one node.
pub fn advance(search : Search, fuel : @core.Nat) -> Progress {
  match search.pending {
    Nil => Exhausted
    Cons(frame, rest) =>
      match fuel {
        Zero => Pending(search)
        Succ(fuel) =>
          match frame.primary {
            Nil =>
              match frame.rows {
                Nil => Found(@core.reverse(frame.selected), { pending: rest, })
                Cons((label, covered), tail) => {
                  let exclude : Frame = {
                    primary: Nil,
                    rows: tail,
                    selected: frame.selected,
                  }
                  let accepted : Frame = {
                    primary: Nil,
                    rows: compatible_rows(tail, covered),
                    selected: Cons(label, frame.selected),
                  }
                  advance(
                    { pending: Cons(exclude, Cons(accepted, rest)), },
                    fuel,
                  )
                }
              }
            Cons(_, _) => {
              let children = @core.map(
                candidate_rows(frame.primary, frame.rows),
                fn(row) {
                  let (label, covered) = row
                  Frame::{
                    primary: remove_columns(frame.primary, covered),
                    rows: compatible_rows(frame.rows, covered),
                    selected: Cons(label, frame.selected),
                  }
                },
              )
              advance({ pending: @core.append(children, rest), }, fuel)
            }
          }
      }
  }
}
