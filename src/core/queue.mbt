///|
/// Strict persistent FIFO. Amortized constant-time operations assume linear use;
/// replaying a retained old state can repeat the reversal of its back list.
#derive(Eq, Debug)
pub struct Queue[A] {
  front : Chain[A]
  back : Chain[A]
}

///|
pub extend Queue with Eq::{equal, not_equal}

///|
pub extend Queue with Debug::{to_repr}

///|
pub fn[A] queue() -> Queue[A] {
  { front: Nil, back: Nil, }
}

///|
pub fn[A] enqueue(queue : Queue[A], value : A) -> Queue[A] {
  { front: queue.front, back: Cons(value, queue.back), }
}

///|
pub fn[A] dequeue(queue : Queue[A]) -> (A, Queue[A])? {
  match (queue.front, queue.back) {
    (Nil, Nil) => None
    (Cons(value, rest), _) => Some((value, { front: rest, back: queue.back, }))
    (Nil, _) => dequeue({ front: reverse(queue.back), back: Nil, })
  }
}
