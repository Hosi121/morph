///|
#derive(Eq, Debug)
pub(all) struct Item {
  weight : @core.Nat
  value : @binary.Binary
}

///|
pub extend Item with Eq::{equal, not_equal}

///|
pub extend Item with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Selection {
  value : @binary.Binary
  chosen : @core.Chain[@core.Nat]
}

///|
pub extend Selection with Eq::{equal, not_equal}

///|
pub extend Selection with Debug::{to_repr}

///|
/// Exact 0/1 knapsack. Chosen indices are returned in original input order.
/// Two aligned cursors replace repeated random lookup at capacity-weight.
pub fn knapsack(items : @core.Chain[Item], capacity : @core.Nat) -> Selection {
  let empty : Selection = { value: @binary.zero(), chosen: Nil, }
  fn update(
    item : Item,
    index : @core.Nat,
    previous : @core.Chain[Selection],
  ) -> @core.Chain[Selection] {
    fn eligible(
      old : @core.Chain[Selection],
      shifted : @core.Chain[Selection],
    ) -> @core.Chain[Selection] {
      match (old, shifted) {
        (Cons(current, ct), Cons(smaller, st)) => {
          let candidate : Selection = {
            value: @binary.add(item.value, smaller.value),
            chosen: Cons(index, smaller.chosen),
          }
          let best = match @binary.compare(candidate.value, current.value) {
            Greater => candidate
            _ => current
          }
          Cons(best, eligible(ct, st))
        }
        _ => Nil
      }
    }
    fn prefix(
      weight : @core.Nat,
      cursor : @core.Chain[Selection],
    ) -> @core.Chain[Selection] {
      match (weight, cursor) {
        (Zero, _) => eligible(cursor, previous)
        (Succ(rest), Cons(value, tail)) => Cons(value, prefix(rest, tail))
        (_, Nil) => Nil
      }
    }
    prefix(item.weight, previous)
  }
  let initial : (@core.Nat, @core.Chain[Selection]) = (
    Zero,
    @core.replicate(Succ(capacity), empty),
  )
  let (_, final_row) = @core.fold_left(items, initial, fn(state, item) {
    let (index, previous) = state
    (Succ(index), update(item, index, previous))
  })
  match @core.last(final_row) {
    None => empty
    Some(result) =>
      { value: result.value, chosen: @core.reverse(result.chosen), }
  }
}
