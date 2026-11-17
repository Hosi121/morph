///|
fn input(
  simplices : Array[Array[Int32]],
  grades : Array[(Int32, Int32)],
) -> Filtration {
  validate(
    @oracle.chain(
      simplices.mapi(fn(i, simplex) {
        let (numerator, denominator) = grades[i]
        Entry::{
          simplex: @oracle.chain(simplex.map(@oracle.nat)),
          grade: @oracle.rational(numerator, denominator),
        }
      }),
    ),
  ).unwrap()
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
    (0, 1),
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 1),
    (5, 1),
    (6, 1),
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
      intervals.push(
        (@oracle.int_of_nat(dimension(source[birth])), birth, death),
      )
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
  assert_eq(index_intervals(witness), [
    (0, 0, -1),
    (0, 1, 3),
    (0, 2, 4),
    (1, 5, 6),
  ])
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
      InvalidWitness =>
        abort("resumption must preserve the reduction invariant")
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
  assert_eq(
    run(by_column, @oracle.nat(100), @oracle.nat(1)),
    Done(completed(source)),
  )
}

///|
test "filtration validation rejects each malformed simplex order and grade condition" {
  fn rejected(
    simplices : Array[Array[Int32]],
    grades : Array[(Int32, Int32)],
  ) -> Bool {
    validate(
      @oracle.chain(
        simplices.mapi(fn(i, simplex) {
          let (n, d) = grades[i]
          Entry::{
            simplex: @oracle.chain(simplex.map(@oracle.nat)),
            grade: @oracle.rational(n, d),
          }
        }),
      ),
    )
    is None
  }
  assert_true(rejected([[]], [(0, 1)]))
  assert_true(rejected([[0, 0]], [(0, 1)]))
  assert_true(rejected([[1, 0]], [(0, 1)]))
  assert_true(rejected([[0], [0]], [(0, 1), (1, 1)]))
  assert_true(rejected([[0], [1], [0, 1]], [(0, 1), (1, 1), (1, 2)]))
  assert_true(rejected([[0], [0, 1]], [(0, 1), (1, 1)]))
  assert_true(rejected([[0], [0, 1], [1]], [(0, 1), (0, 1), (0, 1)]))
  let valid = input([[0], [1], [0, 1]], [(-1, 3), (-1, 3), (1, 2)])
  assert_eq(@oracle.array(entries(valid)).length(), 3)
  assert_true(check_result(valid, barcode(completed(valid)), completed(valid)))
}

///|
test "equal grades retain ephemeral simplex pairs and omit zero grade bars" {
  let simplices = [[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]]
  let source = input(simplices, Array::make(7, (1, 2)))
  let witness = completed(source)
  assert_eq(index_intervals(witness), [
    (0, 0, -1),
    (0, 1, 3),
    (0, 2, 4),
    (1, 5, 6),
  ])
  assert_eq(@oracle.array(pairs(witness)).length(), 3)
  let bars = @oracle.array(barcode(witness))
  assert_eq(bars.length(), 1)
  assert_eq(bars[0].birth, @oracle.rational(1, 2))
  assert_eq(bars[0].death, None)
  assert_eq(bars[0].dimension, @oracle.nat(0))
}

///|
test "grade barcode multiplicities survive all dimensionwise triangle tie orders" {
  let permutations = [
    [0, 1, 2],
    [0, 2, 1],
    [1, 0, 2],
    [1, 2, 0],
    [2, 0, 1],
    [2, 1, 0],
  ]
  let vertices = [[0], [1], [2]]
  let edges = [[0, 1], [0, 2], [1, 2]]
  let grades = [(0, 1), (0, 1), (0, 1), (1, 2), (1, 2), (1, 2), (1, 1)]
  let reference = @oracle.array(
    barcode(
      completed(
        input([[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]], grades),
      ),
    ),
  ).map(fn(bar) { (bar.dimension, bar.birth, bar.death) })
  for vertex_order in permutations {
    for edge_order in permutations {
      let simplices = vertex_order.map(fn(i) { vertices[i] })
      for index in edge_order {
        simplices.push(edges[index])
      }
      simplices.push([0, 1, 2])
      let actual = @oracle.array(barcode(completed(input(simplices, grades)))).map(fn(
          bar,
        ) {
          (bar.dimension, bar.birth, bar.death)
        },
      )
      assert_eq(actual.length(), reference.length())
      for bar in reference {
        assert_eq(
          actual.filter(fn(x) { x.equal(bar) }).length(),
          reference.filter(fn(x) { x.equal(bar) }).length(),
        )
      }
    }
  }
}

///|
test "source result pairings and all matrix certificate conditions are bound" {
  let source = triangle()
  let witness = completed(source)
  let actual = barcode(witness)
  assert_false(check_result(source, @core.Nil, witness))
  assert_false(check_result(source, actual, { ..witness, bars: @core.Nil, }))
  assert_false(
    check_result(source, actual, { ..witness, pairings: @core.Nil, }),
  )
  assert_false(
    check_result(source, actual, {
      ..witness,
      source: validate(@core.Nil).unwrap(),
    }),
  )
  let other = input([[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]], [
    (0, 1),
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 1),
    (5, 1),
    (7, 1),
  ])
  assert_false(check_result(other, actual, witness))
  assert_false(check_result(source, actual, { ..witness, reduced: @core.Nil, }))
  assert_false(check_result(source, actual, { ..witness, change: @core.Nil, }))
  let change = @oracle.array(witness.change)
  // A different valid triangular reduction is accepted: checking is not a
  // replay of the producer's column-operation schedule or witness equality.
  change[1] = @oracle.chain([@oracle.nat(0), @oracle.nat(1)])
  assert_true(
    check_result(source, actual, { ..witness, change: @oracle.chain(change), }),
  )
  change[1] = @core.nth(witness.change, @oracle.nat(1)).unwrap()
  // Removing V's unit diagonal can preserve D V on a zero boundary column.
  change[0] = @core.Nil
  assert_false(
    check_result(source, actual, { ..witness, change: @oracle.chain(change), }),
  )
  change[0] = @oracle.chain([@oracle.nat(0), @oracle.nat(1)])
  assert_false(
    check_result(source, actual, { ..witness, change: @oracle.chain(change), }),
  )
  change[0] = @oracle.chain([@oracle.nat(0), @oracle.nat(0)])
  assert_false(
    check_result(source, actual, { ..witness, change: @oracle.chain(change), }),
  )
  change[0] = @core.nth(witness.change, @oracle.nat(0)).unwrap()
  // Add a vertex to an edge chain: D V is unchanged, upper triangularity is
  // unchanged, but the dimension-preserving requirement must reject it.
  change[3] = xor(change[3], @oracle.chain([@oracle.nat(0)]))
  assert_false(
    check_result(source, actual, { ..witness, change: @oracle.chain(change), }),
  )
  change[3] = @core.nth(witness.change, @oracle.nat(3)).unwrap()
  let reduced = @oracle.array(witness.reduced)
  // Valid R=D V and triangular homogeneous V, but duplicate nonzero lows.
  reduced[5] = reduced[3]
  change[5] = xor(change[5], change[3])
  assert_false(
    check_result(source, actual, {
      ..witness,
      reduced: @oracle.chain(reduced),
      change: @oracle.chain(change),
    }),
  )
  // A changed boundary column without the corresponding basis operation.
  assert_false(
    check_result(source, actual, { ..witness, reduced: @oracle.chain(reduced), }),
  )
}

///|
test "230 filtrations match independent cycle intersection ranks for every prefix pair" {
  let mut comparisons = 0
  for fixture in persistence_fixtures() {
    let (simplices, grades, degrees, expected_ranks, expected_intervals) = fixture
    let source = input(simplices, grades)
    let witness = completed(source)
    let intervals = index_intervals(witness)
    assert_eq(intervals, expected_intervals)
    let mut offset = 0
    for k in 0..<degrees {
      for p in 0..<=simplices.length() {
        for q in p..<=simplices.length() {
          let actual_rank = intervals
            .filter(fn(span) {
              let (dimension, birth, death) = span
              dimension == k && birth < p && (death < 0 || q <= death)
            })
            .length()
          assert_eq(actual_rank, expected_ranks[offset])
          offset += 1
          comparisons += 1
        }
      }
    }
    assert_eq(offset, expected_ranks.length())
    let expected_bars = @oracle.chain(
      expected_intervals.filter_map(fn(span) {
        let (dimension, birth, death) = span
        let (birth_n, birth_d) = grades[birth]
        let birth_grade = @oracle.rational(birth_n, birth_d)
        let death_grade = if death < 0 {
          None
        } else {
          let (death_n, death_d) = grades[death]
          Some(@oracle.rational(death_n, death_d))
        }
        if death_grade.equal(Some(birth_grade)) {
          None
        } else {
          Some(Bar::{
            dimension: @oracle.nat(dimension),
            birth: birth_grade,
            death: death_grade,
            birth_simplex: @oracle.nat(birth),
            death_simplex: if death < 0 {
              None
            } else {
              Some(@oracle.nat(death))
            },
          })
        }
      }),
    )
    assert_eq(barcode(witness), expected_bars)
    assert_true(check_result(source, expected_bars, witness))
  }
  assert_eq(comparisons, 43718)
}
