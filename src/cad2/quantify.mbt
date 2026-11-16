///|
fn fibre_truth(stack : StackCertificate, quantifier : Quantifier) -> Bool {
  fn fold(cells : @core.Chain[@relative.Cell]) -> Bool {
    match (quantifier, cells) {
      (Exists, Nil) => false
      (Forall, Nil) => true
      (Exists, Cons(cell, rest)) => cell.holds || fold(rest)
      (Forall, Cons(cell, rest)) => cell.holds && fold(rest)
    }
  }
  fold(stack.fibre.cells)
}

///|
/// One truth value per x cell, with y quantified over the whole fibre.
pub fn eliminate_y(
  value : Decomposition,
  quantifier : Quantifier,
) -> @core.Chain[Bool] {
  @core.map(value.certificate.stacks, fn(stack) {
    fibre_truth(stack, quantifier)
  })
}

///|
/// Decide outer x, inner y quantifiers. Each complete fibre is aggregated
/// before aggregating x cells; flattening cells would lose alternation.
pub fn sentence(
  value : Decomposition,
  outer : Quantifier,
  inner : Quantifier,
) -> Bool {
  fn fold(values : @core.Chain[Bool]) -> Bool {
    match (outer, values) {
      (Exists, Nil) => false
      (Forall, Nil) => true
      (Exists, Cons(value, rest)) => value || fold(rest)
      (Forall, Cons(value, rest)) => value && fold(rest)
    }
  }
  fold(eliminate_y(value, inner))
}
