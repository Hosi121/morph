///|
/// Merge adjacent sorted product rows, preserving canonical zero removal.
fn product_merge_round(
  rows : @core.Chain[@core.Chain[Term]],
) -> @core.Chain[@core.Chain[Term]] {
  match rows {
    Nil => Nil
    Cons(row, Nil) => Cons(row, Nil)
    Cons(left, Cons(right, rest)) =>
      Cons(merge_terms(left, right), product_merge_round(rest))
  }
}

///|
fn product_merge_all(
  rows : @core.Chain[@core.Chain[Term]],
) -> @core.Chain[Term] {
  match rows {
    Nil => Nil
    Cons(row, Nil) => row
    _ => product_merge_all(product_merge_round(rows))
  }
}

///|
/// Each term-times row is already sorted. Balance larger row merges; retain the
/// old sequential path for at most two left terms and avoid rows for empty input.
/// Exact rational sums may regroup; canonical numeric values are unchanged.
fn balanced_product_terms(
  left : @core.Chain[Term],
  right : @core.Chain[Term],
) -> @core.Chain[Term] {
  match (left, right) {
    (Nil, _) | (_, Nil) => Nil
    (Cons(_, Nil), _) | (Cons(_, Cons(_, Nil)), _) =>
      @core.fold_left(left, Nil, fn(found, term) {
        merge_terms(found, term_times(term, right))
      })
    _ =>
      product_merge_all(@core.map(left, fn(term) { term_times(term, right) }))
  }
}
