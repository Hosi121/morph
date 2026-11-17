///|
// Test-only signed encoding: i denotes generator i-1, and -i its inverse.
fn test_word(values : Array[Int32]) -> @core.Chain[Letter] {
  @oracle.chain(
    values.map(fn(value) {
      { generator: @oracle.nat(value.abs() - 1), inverse: value < 0, }
    }),
  )
}

///|
fn test_source(n : Int32, words : Array[Array[Int32]]) -> Presentation {
  checked_presentation(@oracle.nat(n), @oracle.chain(words.map(test_word))).unwrap()
}

///|
fn test_complete(source : Presentation) -> (Abelianization, Certificate) {
  match run(start(source), @oracle.nat(500)) {
    Done(result, proof) => (result, proof)
    _ => abort("small presentation Smith calculation did not finish")
  }
}

///|
fn test_matrix(
  width : Int32,
  rows : Array[Array[Int32]],
) -> @matrix.Matrix[@exact.Integer] {
  @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(fn(row) { @oracle.chain(row.map(@oracle.integer)) })),
  ).unwrap()
}

///|
fn model_matrix(n : Int32, words : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let result = [ for _ in 0..<n => Array::make(words.length(), 0) ]
  for column, word in words {
    for letter in word {
      result[letter.abs() - 1][column] += if letter < 0 { -1 } else { 1 }
    }
  }
  result
}

///|
fn model_combinations(n : Int32, k : Int32) -> Array[Array[Int32]] {
  fn choose(
    start : Int32,
    k : Int32,
    prefix : Array[Int32],
  ) -> Array[Array[Int32]] {
    if k == 0 {
      return [prefix]
    }
    let result = []
    for index in start..<n {
      let next = prefix.copy()
      next.push(index)
      for selected in choose(index + 1, k - 1, next) {
        result.push(selected)
      }
    }
    result
  }
  choose(0, k, [])
}

///|
fn model_determinant(square : Array[Array[Int32]]) -> Int32 {
  if square.length() == 0 {
    return 1
  }
  let mut sum = 0
  for column in 0..<square.length() {
    let minor = [
      for row in 1..<square.length() => {
        [
          for j in 0..<square.length() if j != column => square[row][j]
        ]
      }
    ]
    let term = square[0][column] * model_determinant(minor)
    sum += if column % 2 == 0 { term } else { -term }
  }
  sum
}

///|
fn model_gcd(a : Int32, b : Int32) -> Int32 {
  for a = a.abs(), b = b.abs(); b != 0; {
    continue b, a % b
  } nobreak {
    a
  }
}

///|
// Independent determinantal divisors; never calls Smith or exact arithmetic.
fn model_invariants(
  rows : Array[Array[Int32]],
  width : Int32,
) -> (Int32, Array[Int32]) {
  let mut previous = 1
  let mut rank = 0
  let torsion = []
  for size in 1..<=rows.length().min(width) {
    let mut divisor = 0
    for selected_rows in model_combinations(rows.length(), size) {
      for selected_columns in model_combinations(width, size) {
        let minor = [
          for i in selected_rows => [ for j in selected_columns => rows[i][j] ]
        ]
        divisor = model_gcd(divisor, model_determinant(minor))
      }
    }
    if divisor == 0 {
      break
    }
    let factor = divisor / previous
    if factor > 1 {
      torsion.push(factor)
    }
    previous = divisor
    rank = size
  }
  (rows.length() - rank, torsion)
}

///|
fn assert_model(
  n : Int32,
  words : Array[Array[Int32]],
  expected_free : Int32,
  expected_torsion : Array[Int32],
) -> Unit raise {
  let context = test_source(n, words)
  let rows = model_matrix(n, words)
  assert_eq(@matrix.height(relation_matrix(context)), @oracle.nat(n))
  assert_eq(
    @matrix.width(relation_matrix(context)),
    @oracle.nat(words.length()),
  )
  assert_eq(relation_matrix(context), test_matrix(words.length(), rows))
  let (model_free, model_torsion) = model_invariants(rows, words.length())
  assert_eq(model_free, expected_free)
  assert_eq(model_torsion, expected_torsion)
  let (result, proof) = test_complete(context)
  assert_eq(@oracle.int_of_nat(free_rank(result)), expected_free)
  assert_eq(
    @oracle.array(torsion_factors(result)).map(@oracle.int_of_binary),
    expected_torsion,
  )
  assert_eq(certificate(result), proof)
  assert_eq(source(result), context)
  assert_true(check(context, proof))
  assert_true(check_result(context, result, proof))
  assert_true(
    check_result(context, from_certificate(context, proof).unwrap(), proof),
  )
  let expected_order = if expected_free == 0 {
    let mut product = 1
    for factor in expected_torsion {
      product *= factor
    }
    Some(@oracle.binary(product))
  } else {
    None
  }
  assert_eq(finite_order(result), expected_order)
}

///|
fn words_for_matrix(
  rows : Array[Array[Int32]],
  width : Int32,
) -> Array[Array[Int32]] {
  [
    for column in 0..<width => {
      let word = []
      for generator in 0..<rows.length() {
        let exponent = rows[generator][column]
        for _ in 0..<exponent.abs() {
          word.push(if exponent < 0 { -(generator + 1) } else { generator + 1 })
        }
      }
      word
    }
  ]
}

///|
test "RP2 torus Klein bottle S3 and triangle presentations" {
  assert_model(1, [[1, 1]], 0, [2])
  assert_model(2, [[1, 2, -1, -2]], 2, [])
  assert_model(2, [[1, 2, -1, 2]], 1, [2])
  assert_model(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2]], 0, [2])
  assert_model(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2, 1, 2, 1, 2, 1, 2]], 0, [])
}

///|
test "empty generator and relator dimensions and empty words" {
  assert_model(0, [], 0, [])
  assert_model(0, [[], [], []], 0, [])
  assert_model(1, [], 1, [])
  assert_model(3, [], 3, [])
  assert_model(3, [[], [], [], []], 3, [])
}

///|
test "signed exponent matrices agree with determinantal divisors" {
  for a in -1..<2 {
    for b in -1..<2 {
      for c in -1..<2 {
        for d in -1..<2 {
          let rows = [[a, b], [c, d]]
          let words = words_for_matrix(rows, 2)
          let (free, torsion) = model_invariants(rows, 2)
          assert_model(2, words, free, torsion)
        }
      }
    }
  }
  let cases = [
    (3, [[4, 0, 0], [0, 6, 0], [0, 0, 0]]),
    (3, [[2, 4, -2], [0, 6, 3], [4, 2, 1]]),
    (3, [[-2, 0, 0], [0, 0, 0], [0, 0, 9]]),
    (2, [[4, 0], [0, 6], [2, 3]]),
    (3, [[4, 0, 2], [0, 6, 3]]),
    (4, [[2, 4, 6, 8]]),
    (1, [[2], [-4], [6], [-8]]),
  ]
  for (width, rows) in cases {
    let (free, torsion) = model_invariants(rows, width)
    assert_model(rows.length(), words_for_matrix(rows, width), free, torsion)
  }
}

///|
test "word inverse free cancellation relator order and signs preserve invariants" {
  let words = [[1, 2, -1, 2], [1, 1, 1, 1]]
  let base = test_source(2, words)
  let (result, _) = test_complete(base)
  let relators = relators(base)
  let variants = [
    @core.reverse(relators),
    @core.map(relators, inverse_word),
    @core.map(relators, fn(word) {
      @core.append(
        test_word([1, -1, 2, -2]),
        @core.append(word, test_word([-1, 1])),
      )
    }),
    @core.append(relators, relators),
  ]
  for relators in variants {
    let other = checked_presentation(@oracle.nat(2), relators).unwrap()
    let (other_result, proof) = test_complete(other)
    assert_eq(free_rank(other_result), free_rank(result))
    assert_eq(torsion_factors(other_result), torsion_factors(result))
    assert_true(check_result(other, other_result, proof))
  }
  for values in [[1, 2, -2, -1], [1, 2, -1, 2], [-1, 1], []] {
    let word = test_word(values)
    let inverse = inverse_word(word)
    assert_eq(inverse_word(inverse), word)
    assert_eq(reduce_word(@core.append(word, inverse)), Nil)
    assert_eq(reduce_word(@core.append(inverse, word)), Nil)
    assert_eq(exponent_sums(base, reduce_word(word)), exponent_sums(base, word))
    assert_eq(
      exponent_sums(base, inverse),
      Some(@core.map(exponent_sums(base, word).unwrap(), @exact.negate)),
    )
  }
  assert_eq(reduce_word(test_word([1, 2, -2, 3, -3, -1])), Nil)
  assert_eq(reduce_word(test_word([1, 2, -1, -2])), test_word([1, 2, -1, -2]))
}

///|
test "out of range generator IDs are rejected even inside cancellation pairs" {
  let invalid : Letter = { generator: @oracle.nat(2), inverse: false, }
  let inverse : Letter = { ..invalid, inverse: true, }
  assert_eq(
    checked_presentation(@oracle.nat(2), Cons(Cons(invalid, Nil), Nil)),
    None,
  )
  assert_eq(
    checked_presentation(
      @oracle.nat(2),
      Cons(Cons(invalid, Cons(inverse, Nil)), Nil),
    ),
    None,
  )
  assert_eq(checked_presentation(Zero, Cons(test_word([1]), Nil)), None)
  let source = test_source(2, [])
  assert_eq(exponent_sums(source, Cons(invalid, Nil)), None)
  assert_eq(
    exponent_sums(source, Nil),
    Some(@oracle.chain([0, 0].map(@oracle.integer))),
  )
}

///|
test "Smith pause and resume retains exact source and accumulated work" {
  let source = test_source(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2]])
  let initial = start(source)
  assert_eq(run(initial, Zero), Paused(initial))
  let paused = match run(initial, @oracle.nat(1)) {
    Paused(state) => state
    _ => abort("fixture requires more than one Smith step")
  }
  assert_eq(run(paused, Zero), Paused(paused))
  let (resumed, proof) = match run(paused, @oracle.nat(500)) {
    Done(result, proof) => (result, proof)
    _ => abort("resume should complete")
  }
  assert_eq((resumed, proof), test_complete(source))
  assert_true(check_result(source, resumed, proof))
}

///|
test "source witness invariants decomposition and cached result tampering is rejected" {
  let source = test_source(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2]])
  let (result, proof) = test_complete(source)
  let torus = test_source(2, [[1, 2, -1, -2]])
  let (torus_result, torus_proof) = test_complete(torus)
  let changed = [
    { ..proof, generators: @oracle.nat(3), },
    { ..proof, relators: relators(torus), },
    { ..proof, relations: relation_matrix(torus), },
    { ..proof, left: test_matrix(2, [[0, 0], [0, 0]]), },
    { ..proof, diagonal: test_matrix(3, [[1, 0, 0], [0, 1, 0]]), },
    { ..proof, right: test_matrix(3, [[0, 0, 0], [0, 0, 0], [0, 0, 0]]), },
    { ..proof, free: @oracle.nat(1), },
    { ..proof, torsion: Nil, },
  ]
  for bad in changed {
    assert_false(check(source, bad))
    assert_eq(from_certificate(source, bad), None)
    assert_false(check_result(source, result, bad))
  }
  assert_false(check(torus, proof))
  assert_false(check_result(torus, result, proof))
  assert_false(check_result(source, torus_result, proof))
  assert_false(check_result(source, result, torus_proof))
  // Different words with exactly the same exponent matrix remain distinct sources.
  let same_matrix = test_source(2, [[1, 1], [2, 2, 2], [2, 1, 2, 1]])
  assert_eq(relation_matrix(same_matrix), relation_matrix(source))
  assert_false(check(same_matrix, proof))
  let bad_source : Presentation = {
    ..source,
    relations: relation_matrix(torus),
  }
  assert_false(check(bad_source, proof))
  let bad_sources : Abelianization = { ..result, source: same_matrix, }
  let bad_form : Abelianization = {
    ..result,
    form: decomposition(torus_result),
  }
  let bad_group : Abelianization = { ..result, group: cokernel(torus_result), }
  let bad_proof : Abelianization = { ..result, proof: torus_proof, }
  for bad in [bad_sources, bad_form, bad_group, bad_proof] {
    assert_false(check_result(source, bad, proof))
  }
  let foreign_state : State = {
    source,
    machine: @smith.start(relation_matrix(torus)),
  }
  assert_true(run(foreign_state, @oracle.nat(500)) is Fault(_))
}

///|
test "zero triangle abelianization coexists with a nontrivial perfect permutation quotient" {
  let context = test_source(2, [
    [1, 1],
    [2, 2, 2],
    [1, 2, 1, 2, 1, 2, 1, 2, 1, 2],
  ])
  let (abelian, proof) = test_complete(context)
  assert_eq(free_rank(abelian), Zero)
  assert_eq(torsion_factors(abelian), Nil)
  assert_eq(finite_order(abelian), Some(@binary.one()))
  assert_true(check_result(context, abelian, proof))
  // a=(0 1)(2 3), b=(0 2 4); ab has order five.
  let generators = @oracle.chain(
    [[1, 0, 3, 2, 4], [2, 1, 4, 3, 0]].map(fn(row) {
      @perm.checked_permutation(
        @oracle.nat(5),
        @oracle.chain(row.map(@oracle.nat)),
      ).unwrap()
    }),
  )
  for word in @oracle.array(relators(context)) {
    let value = @core.fold_left(word, @perm.identity(@oracle.nat(5)), fn(
      product,
      letter,
    ) {
      let image = @core.nth(generators, letter.generator).unwrap()
      @perm.compose(
        product,
        if letter.inverse {
          @perm.inverse(image)
        } else {
          image
        },
      ).unwrap()
    })
    assert_eq(value, @perm.identity(@oracle.nat(5)))
  }
  let concrete = match
    @perm.generate(@oracle.nat(5), generators, @oracle.nat(60)) {
    Complete(group) => group
    _ => abort("explicit triangle quotient must complete at sixty elements")
  }
  assert_eq(@perm.order(concrete), @oracle.nat(60))
  let certificate = @perm.analyze(concrete)
  assert_eq(certificate.conclusion, @perm.NonSolvable)
  assert_true(@perm.same_group(@perm.derived_subgroup(concrete), concrete))
  assert_true(@perm.check_result(concrete, certificate))
}
