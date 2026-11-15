///|
#derive(Eq, Debug)
enum Tree[K, V] {
  Empty
  Branch(@core.Nat, @binary.Binary, Tree[K, V], K, V, Tree[K, V])
}

///|
pub extend Tree with Eq::{equal, not_equal}

///|
pub extend Tree with Debug::{to_repr}

///|
/// A persistent AVL ordered map. Use one fixed strict total order for every operation.
/// Eq observes the tree representation, not extensional equality of different shapes.
#derive(Eq, Debug)
pub struct OrderedMap[K, V] {
  tree : Tree[K, V]
}

///|
pub extend OrderedMap with Eq::{equal, not_equal}

///|
pub extend OrderedMap with Debug::{to_repr}

///|
fn[K, V] height(tree : Tree[K, V]) -> @core.Nat {
  match tree {
    Empty => Zero
    Branch(height, _, _, _, _, _) => height
  }
}

///|
fn[K, V] count(tree : Tree[K, V]) -> @binary.Binary {
  match tree {
    Empty => @binary.zero()
    Branch(_, count, _, _, _, _) => count
  }
}

///|
fn[K, V] node(
  left : Tree[K, V],
  key : K,
  value : V,
  right : Tree[K, V],
) -> Tree[K, V] {
  let maximum = match @core.compare(height(left), height(right)) {
    Greater => height(left)
    _ => height(right)
  }
  Branch(
    Succ(maximum),
    @binary.successor(@binary.add(count(left), count(right))),
    left,
    key,
    value,
    right,
  )
}

///|
/// Single and double rotations, rebuilding only the affected path.
fn[K, V] balance(
  left : Tree[K, V],
  key : K,
  value : V,
  right : Tree[K, V],
) -> Tree[K, V] {
  match
    (
      @core.compare(height(left), Succ(height(right))),
      @core.compare(height(right), Succ(height(left))),
    ) {
    (Greater, _) =>
      match left {
        Empty => node(left, key, value, right)
        Branch(_, _, ll, lk, lv, lr) =>
          match @core.compare(height(ll), height(lr)) {
            Less =>
              match lr {
                Empty => node(left, key, value, right)
                Branch(_, _, lrl, lrk, lrv, lrr) =>
                  node(
                    node(ll, lk, lv, lrl),
                    lrk,
                    lrv,
                    node(lrr, key, value, right),
                  )
              }
            _ => node(ll, lk, lv, node(lr, key, value, right))
          }
      }
    (_, Greater) =>
      match right {
        Empty => node(left, key, value, right)
        Branch(_, _, rl, rk, rv, rr) =>
          match @core.compare(height(rr), height(rl)) {
            Less =>
              match rl {
                Empty => node(left, key, value, right)
                Branch(_, _, rll, rlk, rlv, rlr) =>
                  node(
                    node(left, key, value, rll),
                    rlk,
                    rlv,
                    node(rlr, rk, rv, rr),
                  )
              }
            _ => node(node(left, key, value, rl), rk, rv, rr)
          }
      }
    _ => node(left, key, value, right)
  }
}

///|
pub fn[K, V] empty() -> OrderedMap[K, V] {
  { tree: Empty, }
}

///|
pub fn[K, V] size(map : OrderedMap[K, V]) -> @binary.Binary {
  count(map.tree)
}

///|
pub fn[K, V] lookup(
  map : OrderedMap[K, V],
  key : K,
  compare : (K, K) -> @core.Ordering,
) -> V? {
  fn search(tree : Tree[K, V]) -> V? {
    match tree {
      Empty => None
      Branch(_, _, left, found, value, right) =>
        match compare(key, found) {
          Less => search(left)
          Equal => Some(value)
          Greater => search(right)
        }
    }
  }
  search(map.tree)
}

///|
pub fn[K, V] put(
  map : OrderedMap[K, V],
  key : K,
  value : V,
  compare : (K, K) -> @core.Ordering,
) -> OrderedMap[K, V] {
  fn insert(tree : Tree[K, V]) -> Tree[K, V] {
    match tree {
      Empty => node(Empty, key, value, Empty)
      Branch(h, n, left, found, old, right) =>
        match compare(key, found) {
          Less => balance(insert(left), found, old, right)
          Greater => balance(left, found, old, insert(right))
          Equal => Branch(h, n, left, found, value, right)
        }
    }
  }
  { tree: insert(map.tree), }
}

///|
fn[K, V] take_min(tree : Tree[K, V]) -> (K, V, Tree[K, V])? {
  match tree {
    Empty => None
    Branch(_, _, Empty, key, value, right) => Some((key, value, right))
    Branch(_, _, left, key, value, right) =>
      match take_min(left) {
        None => None
        Some((minimum, value_min, remainder)) =>
          Some((minimum, value_min, balance(remainder, key, value, right)))
      }
  }
}

///|
pub fn[K, V] remove(
  map : OrderedMap[K, V],
  key : K,
  compare : (K, K) -> @core.Ordering,
) -> OrderedMap[K, V] {
  fn erase(tree : Tree[K, V]) -> (Tree[K, V], Bool) {
    match tree {
      Empty => (tree, false)
      Branch(_, _, left, found, value, right) =>
        match compare(key, found) {
          Less => {
            let (next, changed) = erase(left)
            (
              match changed {
                true => balance(next, found, value, right)
                false => tree
              },
              changed,
            )
          }
          Greater => {
            let (next, changed) = erase(right)
            (
              match changed {
                true => balance(left, found, value, next)
                false => tree
              },
              changed,
            )
          }
          Equal =>
            match take_min(right) {
              None => (left, true)
              Some((key, value, remainder)) =>
                (balance(left, key, value, remainder), true)
            }
        }
    }
  }
  let (tree, _) = erase(map.tree)
  { tree, }
}

///|
/// Zero-based order statistic, with an arbitrary-precision binary rank.
pub fn[K, V] select(map : OrderedMap[K, V], rank : @binary.Binary) -> (K, V)? {
  fn search(tree : Tree[K, V], rank : @binary.Binary) -> (K, V)? {
    match tree {
      Empty => None
      Branch(_, _, left, key, value, right) =>
        match @binary.compare(rank, count(left)) {
          Less => search(left, rank)
          Equal => Some((key, value))
          Greater =>
            match @binary.subtract(rank, @binary.successor(count(left))) {
              None => None
              Some(rank) => search(right, rank)
            }
        }
    }
  }
  search(map.tree, rank)
}

///|
/// Number of stored keys strictly smaller than key, even if key is absent.
pub fn[K, V] rank(
  map : OrderedMap[K, V],
  key : K,
  compare : (K, K) -> @core.Ordering,
) -> @binary.Binary {
  fn search(tree : Tree[K, V]) -> @binary.Binary {
    match tree {
      Empty => @binary.zero()
      Branch(_, _, left, found, _, right) =>
        match compare(key, found) {
          Less => search(left)
          Equal => count(left)
          Greater => @binary.add(@binary.successor(count(left)), search(right))
        }
    }
  }
  search(map.tree)
}

///|
pub fn[K, V] entries(map : OrderedMap[K, V]) -> @core.Chain[(K, V)] {
  fn walk(
    tree : Tree[K, V],
    tail : @core.Chain[(K, V)],
  ) -> @core.Chain[(K, V)] {
    match tree {
      Empty => tail
      Branch(_, _, left, key, value, right) =>
        walk(left, Cons((key, value), walk(right, tail)))
    }
  }
  walk(map.tree, Nil)
}

///|
/// Ordered half-open key range [lower,upper), pruning branches outside the range.
pub fn[K, V] between(
  map : OrderedMap[K, V],
  lower : K,
  upper : K,
  compare : (K, K) -> @core.Ordering,
) -> @core.Chain[(K, V)] {
  fn walk(
    tree : Tree[K, V],
    tail : @core.Chain[(K, V)],
  ) -> @core.Chain[(K, V)] {
    match tree {
      Empty => tail
      Branch(_, _, left, key, value, right) =>
        match (compare(key, lower), compare(key, upper)) {
          (Less, _) => walk(right, tail)
          (_, Equal) | (_, Greater) => walk(left, tail)
          _ => walk(left, Cons((key, value), walk(right, tail)))
        }
    }
  }
  match compare(lower, upper) {
    Less => walk(map.tree, Nil)
    _ => Nil
  }
}
