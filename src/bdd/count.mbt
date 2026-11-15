///|
fn free_choices(value : @binary.Binary, count : @core.Nat) -> @binary.Binary {
  match count {
    Zero => value
    Succ(rest) => free_choices(@binary.double(value), rest)
  }
}

///|
/// Exact model count over the entire declared order, including variables the
/// reduced diagram skips. The count is an arbitrary-size symbolic Binary.
pub fn model_count(diagram : Diagram) -> @binary.Binary? {
  let total = @core.length(diagram.manager.order)
  fn walk(
    edge : Edge,
    start : @core.Nat,
    memo : Trie[@binary.Binary],
  ) -> (@binary.Binary, Trie[@binary.Binary])? {
    match @core.compare(start, total) {
      Greater => None
      _ =>
        match edge {
          Terminal(false) => Some((@binary.zero(), memo))
          Terminal(true) =>
            Some(
              (free_choices(@binary.one(), @core.subtract(total, start)), memo),
            )
          Decision(id) => {
            let key = @binary.bits(id)
            match lookup(diagram.manager.nodes, key) {
              None => None
              Some(node) =>
                match
                  (
                    @core.compare(node.variable.rank, start),
                    @core.compare(node.variable.rank, total),
                  ) {
                  (Less, _) | (_, Equal) | (_, Greater) => None
                  _ => {
                    let skipped = @core.subtract(node.variable.rank, start)
                    match lookup(memo, key) {
                      Some(own_count) =>
                        Some((free_choices(own_count, skipped), memo))
                      None =>
                        match walk(node.low, Succ(node.variable.rank), memo) {
                          None => None
                          Some((low, memo)) =>
                            match
                              walk(node.high, Succ(node.variable.rank), memo) {
                              None => None
                              Some((high, memo)) => {
                                let own_count = @binary.add(low, high)
                                Some(
                                  (
                                    free_choices(own_count, skipped),
                                    insert(memo, key, own_count),
                                  ),
                                )
                              }
                            }
                        }
                    }
                  }
                }
            }
          }
        }
    }
  }
  match walk(diagram.root, Zero, Empty) {
    None => None
    Some((count, _)) => Some(count)
  }
}

///|
/// Quantification retains the declared order. The quantified variable becomes
/// irrelevant to the result and remains a free choice in model_count.
pub fn exists_variable(diagram : Diagram, variable : @core.Nat) -> Diagram? {
  match restrict(diagram, { variable, positive: false, }) {
    None => None
    Some(low) =>
      match restrict(diagram, { variable, positive: true, }) {
        None => None
        Some(high) => apply(Disjunction, low, high)
      }
  }
}

///|
pub fn forall_variable(diagram : Diagram, variable : @core.Nat) -> Diagram? {
  match restrict(diagram, { variable, positive: false, }) {
    None => None
    Some(low) =>
      match restrict(diagram, { variable, positive: true, }) {
        None => None
        Some(high) => apply(Conjunction, low, high)
      }
  }
}
