///|
/// A temporary immutable axis index for one permutation. Leaves retain entries;
/// each branch indexes a single axis rather than the whole flat entry chain.
priv enum PermutationIndex[A] {
  PermutationLeaf(A)
  PermutationAxis(@core.Chain[PermutationIndex[A]])
}

///|
fn[A] permutation_index_rows(
  count : @core.Nat,
  dimensions : @core.Chain[@core.Nat],
  values : @core.Chain[A],
) -> Result[(@core.Chain[PermutationIndex[A]], @core.Chain[A]), TensorError] {
  match count {
    Zero => Ok((Nil, values))
    Succ(remaining) =>
      match permutation_index(dimensions, values) {
        Err(error) => Err(error)
        Ok((head, tail)) =>
          match permutation_index_rows(remaining, dimensions, tail) {
            Err(error) => Err(error)
            Ok((rest, unconsumed)) => Ok((Cons(head, rest), unconsumed))
          }
      }
  }
}

///|
/// Consume the flat input once in row-major order; keep its entries unchanged.
fn[A] permutation_index(
  dimensions : @core.Chain[@core.Nat],
  values : @core.Chain[A],
) -> Result[(PermutationIndex[A], @core.Chain[A]), TensorError] {
  match dimensions {
    Nil =>
      match values {
        Nil => Err(InternalShape)
        Cons(head, tail) => Ok((PermutationLeaf(head), tail))
      }
    Cons(size, rest) =>
      match permutation_index_rows(size, rest, values) {
        Err(error) => Err(error)
        Ok((children, tail)) => Ok((PermutationAxis(children), tail))
      }
  }
}

///|
fn[A] permutation_lookup(
  indexed : PermutationIndex[A],
  indices : @core.Chain[@core.Nat],
) -> Result[A, TensorError] {
  match (indexed, indices) {
    (PermutationLeaf(value), Nil) => Ok(value)
    (PermutationAxis(children), Cons(head, tail)) =>
      match @core.nth(children, head) {
        None => Err(InternalShape)
        Some(child) => permutation_lookup(child, tail)
      }
    _ => Err(InternalShape)
  }
}
