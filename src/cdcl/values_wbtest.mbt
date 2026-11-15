///|
fn candidate_index_value(literal : Atom, values : Index[Assignment]) -> Value {
  match index_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match (entry.literal.positive, literal.positive) {
        (true, true) | (false, false) => True
        _ => False
      }
  }
}

///|
fn review_assignment_index() -> (Index[Assignment], Lits) {
  let entries = @oracle.chain(
    [
      for variable in 0..<128 => {
        Assignment::{
          literal: atom(lit(variable, true)),
          level: @core.Zero,
          reason: None,
        }
      }
    ],
  )
  let values = @core.fold_left(entries, Empty, fn(values, entry) {
    index_put(values, @binary.bits(entry.literal.key), entry)
  })
  let positive = @core.map(entries, fn(entry) { entry.literal })
  (values, @core.append(positive, @core.map(positive, opposite)))
}

///|
fn numeric_value(value : Value) -> Int32 {
  match value {
    True => 1
    False => 0
    Unassigned => 2
  }
}

///|
test "polarity-only indexed lookup agrees with assignment semantics" {
  let (values, queries) = review_assignment_index()
  for literal in @oracle.array(queries) {
    assert_eq(
      numeric_value(candidate_index_value(literal, values)),
      numeric_value(index_value(literal, values)),
    )
    assert_eq(
      numeric_value(candidate_index_value(literal, values)),
      if literal.positive {
        1
      } else {
        0
      },
    )
  }
  let absent = atom(lit(128, true))
  assert_eq(numeric_value(candidate_index_value(absent, values)), 2)
  assert_eq(numeric_value(candidate_index_value(absent, Empty)), 2)
  let negative = opposite(atom(lit(0, true)))
  let values = index_put(Empty, @binary.bits(negative.key), Assignment::{
    literal: negative,
    level: @core.Zero,
    reason: None,
  })
  assert_eq(numeric_value(candidate_index_value(negative, values)), 1)
  assert_eq(numeric_value(candidate_index_value(opposite(negative), values)), 0)
}

///|
test "baseline indexed assignment lookup over 256 assigned queries" (
  b : @bench.T,
) {
  let (values, queries) = review_assignment_index()
  b.bench(fn() {
    b.keep(
      @core.fold_left(queries, false, fn(parity, literal) {
        match index_value(literal, values) {
          True => !parity
          _ => parity
        }
      }),
    )
  })
}

///|
test "candidate polarity-only indexed assignment lookup over 256 queries" (
  b : @bench.T,
) {
  let (values, queries) = review_assignment_index()
  b.bench(fn() {
    b.keep(
      @core.fold_left(queries, false, fn(parity, literal) {
        match candidate_index_value(literal, values) {
          True => !parity
          _ => parity
        }
      }),
    )
  })
}
