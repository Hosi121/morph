///|
fn structural_legacy_collision(
  reduced : @core.Chain[@core.Chain[@core.Nat]],
  change : @core.Chain[@core.Chain[@core.Nat]],
  pivot : @core.Nat,
) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat])? {
  match (reduced, change) {
    (Cons(r, rs), Cons(v, vs)) =>
      match @core.last(r).equal(Some(pivot)) {
        true => Some((r, v))
        false => structural_legacy_collision(rs, vs, pivot)
      }
    _ => None
  }
}

///|
/// Standard sparse left-to-right GF(2) column reduction with R = D V.
/// Each initialization, whole-column XOR, or column commit consumes one
/// operation. Each commit additionally consumes one column. Either exhausted
/// budget returns Paused, and budgets are fresh on resumption. Sparse-list
/// traversal, initial boundary construction and final checking are not fueled;
/// this is an algebraic work budget, not a runtime or allocation limit.
fn structural_legacy_run(
  state : State,
  operation_fuel : @core.Nat,
  column_fuel : @core.Nat,
) -> Computation {
  match (state.active, state.remaining) {
    (None, Nil) => finish(state)
    _ =>
      match (operation_fuel, column_fuel) {
        (Succ(operations), Succ(columns)) =>
          match state.active {
            None =>
              match state.remaining {
                Nil => finish(state)
                Cons(column, rest) =>
                  structural_legacy_run(
                    {
                      ..state,
                      remaining: rest,
                      active: Some((column, Cons(state.index, Nil))),
                    },
                    operations,
                    column_fuel,
                  )
              }
            Some((r, v)) => {
              let previous = match @core.last(r) {
                None => None
                Some(pivot) =>
                  structural_legacy_collision(
                    state.reduced_rev,
                    state.change_rev,
                    pivot,
                  )
              }
              match previous {
                Some((old_r, old_v)) =>
                  structural_legacy_run(
                    { ..state, active: Some((xor(r, old_r), xor(v, old_v))), },
                    operations,
                    column_fuel,
                  )
                None =>
                  structural_legacy_run(
                    {
                      ..state,
                      reduced_rev: Cons(r, state.reduced_rev),
                      change_rev: Cons(v, state.change_rev),
                      index: Succ(state.index),
                      active: None,
                    },
                    operations,
                    columns,
                  )
              }
            }
          }
        _ => Paused(state)
      }
  }
}

///|
fn structural_same_progress(actual : State, legacy : State) -> Bool {
  actual.source == legacy.source &&
  actual.remaining == legacy.remaining &&
  actual.reduced_rev == legacy.reduced_rev &&
  actual.change_rev == legacy.change_rev &&
  actual.index == legacy.index &&
  actual.active == legacy.active
}

///|
test "structural reduction retains every frozen legacy algebraic pause and certificate" {
  for fixture in persistence_fixtures() {
    let (simplices, grades, _, _, _) = fixture
    let source = input(simplices, grades)
    let mut actual = start(source)
    let mut legacy = start(source)
    for count in 0..<1000 {
      assert_true(structural_same_progress(actual, legacy))
      let operation_fuel = @oracle.nat(if count % 5 == 0 { 3 } else { 1 })
      let column_fuel = @oracle.nat(if count % 3 == 0 { 2 } else { 1 })
      match
        (
          run(actual, operation_fuel, column_fuel),
          structural_legacy_run(legacy, operation_fuel, column_fuel),
        ) {
        (Paused(next), Paused(old)) => {
          actual = next
          legacy = old
        }
        (Done(witness), Done(old)) => {
          assert_eq(witness, old)
          break
        }
        _ =>
          abort("reduction changed the frozen legacy algebraic step schedule")
      }
      if count == 999 {
        abort("finite pivot trace did not complete")
      }
    }
  }
}

///|
test "structural malformed suspended states still require the independent checker" {
  let empty = start(validate(@core.Nil).unwrap())
  let extra_column = {
    ..empty,
    reduced_rev: Cons(@core.Nil, @core.Nil),
    change_rev: Cons(@core.Nil, @core.Nil),
  }
  assert_eq(run(extra_column, @core.Zero, @core.Zero), InvalidWitness)
  // Inconsistent already-committed columns cannot be accepted merely because
  // the active and remaining work queues are empty.
  let wrong_source = { ..start(triangle()), remaining: @core.Nil, }
  assert_eq(run(wrong_source, @core.Zero, @core.Zero), InvalidWitness)
}
