///|
#derive(Eq, Debug)
pub(all) enum CodeTree[A] {
  Leaf(A)
  Fork(CodeTree[A], CodeTree[A])
}

///|
pub extend CodeTree with Eq::{equal, not_equal}

///|
pub extend CodeTree with Debug::{to_repr}

///|
/// Unique leaves, built from positive frequencies.
#derive(Eq, Debug)
pub struct Code[A] {
  tree : CodeTree[A]
}

///|
pub extend Code with Eq::{equal, not_equal}

///|
pub extend Code with Debug::{to_repr}

///|
priv struct Weighted[A] {
  weight : @binary.Binary
  tree : CodeTree[A]
}

///|
pub fn[A] tree(code : Code[A]) -> CodeTree[A] {
  code.tree
}

///|
/// Build the optimal prefix tree by repeatedly merging the two lightest trees.
/// Empty input has no alphabet. A singleton alphabet receives the code [false].
pub fn[A] build(word : @core.Chain[A], equal : (A, A) -> Bool) -> Code[A]? {
  fn increment(
    counts : @core.Chain[(A, @binary.Binary)],
    symbol : A,
  ) -> @core.Chain[(A, @binary.Binary)] {
    match counts {
      Nil => Cons((symbol, @binary.one()), Nil)
      Cons((value, count), rest) =>
        match equal(symbol, value) {
          true => Cons((value, @binary.successor(count)), rest)
          false => Cons((value, count), increment(rest, symbol))
        }
    }
  }
  let frequencies = @core.fold_left(word, @core.Nil, increment)
  let compare = fn(a : Weighted[A], b : Weighted[A]) {
    @binary.compare(a.weight, b.weight)
  }
  let heap = @heap.from_chain(
    @core.map(frequencies, fn(entry) {
      let (symbol, weight) = entry
      Weighted::{ weight, tree: Leaf(symbol), }
    }),
    compare,
  )
  fn merge(heap : @heap.Heap[Weighted[A]]) -> Code[A]? {
    match @heap.pop(heap, compare) {
      None => None
      Some((left, rest)) =>
        match @heap.pop(rest, compare) {
          None => Some({ tree: left.tree, })
          Some((right, rest)) =>
            merge(
              @heap.insert(
                rest,
                {
                  weight: @binary.add(left.weight, right.weight),
                  tree: Fork(left.tree, right.tree),
                },
                compare,
              ),
            )
        }
    }
  }
  merge(heap)
}

///|
pub fn[A] codeword(
  code : Code[A],
  symbol : A,
  equal : (A, A) -> Bool,
) -> @core.Chain[Bool]? {
  fn find(
    tree : CodeTree[A],
    prefix : @core.Chain[Bool],
  ) -> @core.Chain[Bool]? {
    match tree {
      Leaf(value) =>
        match equal(value, symbol) {
          false => None
          true =>
            Some(
              match prefix {
                Nil => Cons(false, Nil)
                _ => @core.reverse(prefix)
              },
            )
        }
      Fork(left, right) =>
        match find(left, Cons(false, prefix)) {
          Some(bits) => Some(bits)
          None => find(right, Cons(true, prefix))
        }
    }
  }
  find(code.tree, Nil)
}

///|
pub fn[A] encode(
  code : Code[A],
  word : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> @core.Chain[Bool]? {
  fn walk(
    word : @core.Chain[A],
    reversed : @core.Chain[Bool],
  ) -> @core.Chain[Bool]? {
    match word {
      Nil => Some(@core.reverse(reversed))
      Cons(symbol, rest) =>
        match codeword(code, symbol, equal) {
          None => None
          Some(bits) => walk(rest, @core.reverse_onto(bits, reversed))
        }
    }
  }
  walk(word, Nil)
}

///|
/// Reject incomplete final codewords; all complete paths in a full tree are valid.
pub fn[A] decode(code : Code[A], bits : @core.Chain[Bool]) -> @core.Chain[A]? {
  fn single(symbol : A, bits : @core.Chain[Bool]) -> @core.Chain[A]? {
    match bits {
      Nil => Some(Nil)
      Cons(true, _) => None
      Cons(false, rest) =>
        match single(symbol, rest) {
          None => None
          Some(tail) => Some(Cons(symbol, tail))
        }
    }
  }
  fn one(
    tree : CodeTree[A],
    bits : @core.Chain[Bool],
  ) -> (A, @core.Chain[Bool])? {
    match (tree, bits) {
      (Leaf(symbol), _) => Some((symbol, bits))
      (Fork(_, _), Nil) => None
      (Fork(left, right), Cons(bit, rest)) =>
        one(
          match bit {
            true => right
            false => left
          },
          rest,
        )
    }
  }
  fn many(bits : @core.Chain[Bool]) -> @core.Chain[A]? {
    match bits {
      Nil => Some(Nil)
      _ =>
        match one(code.tree, bits) {
          None => None
          Some((symbol, rest)) =>
            match many(rest) {
              None => None
              Some(tail) => Some(Cons(symbol, tail))
            }
        }
    }
  }
  match code.tree {
    Leaf(symbol) => single(symbol, bits)
    Fork(_, _) => many(bits)
  }
}
