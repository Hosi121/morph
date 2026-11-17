///|
fn input(
  simplices : Array[Array[Int32]],
  grades : Array[(Int32, Int32)],
) -> Filtration {
  validate(@oracle.chain(simplices.mapi(fn(i, simplex) {
    let (numerator, denominator) = grades[i]
    Entry::{
      simplex: @oracle.chain(simplex.map(@oracle.nat)),
      grade: @oracle.rational(numerator, denominator),
    }
  }))).unwrap()
}

///|
fn completed(source : Filtration) -> Certificate {
  match run(start(source), @oracle.nat(500), @oracle.nat(100)) {
    Done(witness) => witness
    _ => abort("finite fixture must finish with a checked certificate")
  }
}

///|
fn triangle() -> Filtration {
  input([[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]], [
    (0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1),
  ])
}

///|
fn index_intervals(witness : Certificate) -> Array[(Int32, Int32, Int32)] {
  let intervals = []
  let source = @oracle.array(entries(witness.source))
  for birth, column in @oracle.array(witness.reduced) {
    if column is Nil {
      let death = match death_of(witness.pairings, @oracle.nat(birth)) {
        None => -1
        Some(index) => @oracle.int_of_nat(index)
      }
      intervals.push((@oracle.int_of_nat(dimension(source[birth])), birth, death))
    }
  }
  intervals
}

///|
test "empty filtration and triangle births deaths are exact and certified" {
  let empty = validate(@core.Nil).unwrap()
  let result = completed(empty)
  assert_eq(barcode(result), @core.Nil)
  assert_true(check_result(empty, @core.Nil, result))
  assert_true(run(start(empty), @core.Zero, @core.Zero) is Done(_))
  let source = triangle()
  let witness = completed(source)
  assert_eq(index_intervals(witness), [(0, 0, -1), (0, 1, 3), (0, 2, 4), (1, 5, 6)])
  assert_true(check_result(source, barcode(witness), witness))
  assert_eq(@oracle.array(barcode(witness)).length(), 4)
}

///|
test "operation and column budgets suspend and resume without an answer" {
  let source = triangle()
  let initial = start(source)
  assert_eq(run(initial, @core.Zero, @oracle.nat(2)), Paused(initial))
  assert_eq(run(initial, @oracle.nat(2), @core.Zero), Paused(initial))
  let mut state = initial
  let mut pauses = 0
  let mut result = None
  while result is None && pauses < 100 {
    match run(state, @oracle.nat(1), @oracle.nat(1)) {
      Done(witness) => result = Some(witness)
      Paused(next) => {
        state = next
        pauses += 1
      }
      InvalidWitness => abort("resumption must preserve the reduction invariant")
    }
  }
  assert_eq(result, Some(completed(source)))
  assert_true(pauses > 14)
  let mut by_column = initial
  for _ in 0..<6 {
    match run(by_column, @oracle.nat(100), @oracle.nat(1)) {
      Paused(next) => by_column = next
      _ => abort("one column budget must suspend before the seventh column")
    }
  }
  assert_eq(run(by_column, @oracle.nat(100), @oracle.nat(1)), Done(completed(source)))
}
