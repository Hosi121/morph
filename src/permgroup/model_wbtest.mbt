///|
// Deliberately independent machine-array model, confined to the test boundary.
fn model_equal(left : Array[Int], right : Array[Int]) -> Bool {
  if left.length() != right.length() { return false }
  for index in 0..<left.length() {
    if left[index] != right[index] { return false }
  }
  true
}

///|
fn model_contains(elements : Array[Array[Int]], value : Array[Int]) -> Bool {
  for element in elements {
    if model_equal(element, value) { return true }
  }
  false
}

///|
fn model_same(left : Array[Array[Int]], right : Array[Array[Int]]) -> Bool {
  left.length() == right.length() && left.all(x => model_contains(right, x))
}

///|
fn model_compose(left : Array[Int], right : Array[Int]) -> Array[Int] {
  [for point in right => left[point]]
}

///|
fn model_inverse(value : Array[Int]) -> Array[Int] {
  let result = Array::make(value.length(), 0)
  for point, image in value { result[image] = point }
  result
}

///|
fn model_commutator(left : Array[Int], right : Array[Int]) -> Array[Int] {
  model_compose(
    model_compose(model_inverse(left), model_inverse(right)),
    model_compose(left, right),
  )
}

///|
fn model_closure(n : Int, generators : Array[Array[Int]]) -> Array[Array[Int]] {
  let elements = [[for point in 0..<n => point]]
  for cursor = 0; cursor < elements.length(); cursor = cursor + 1 {
    for generator in generators {
      let product = model_compose(elements[cursor], generator)
      if !model_contains(elements, product) { elements.push(product) }
    }
  }
  elements
}

///|
fn model_derived(elements : Array[Array[Int]]) -> Array[Array[Int]] {
  let generators = []
  for left in elements {
    for right in elements {
      let commutator = model_commutator(left, right)
      if !model_contains(generators, commutator) {
        generators.push(commutator)
      }
    }
  }
  model_closure(elements[0].length(), generators)
}

///|
fn model_series(elements : Array[Array[Int]]) -> Array[Array[Array[Int]]] {
  let result = [elements]
  for current = elements; current.length() > 1; {
    let next = model_derived(current)
    if model_same(current, next) { break }
    result.push(next)
    continue next
  }
  result
}

///|
fn test_permutation(value : Array[Int]) -> Permutation {
  checked_permutation(
    @oracle.nat(value.length()),
    @oracle.chain(value.map(@oracle.nat)),
  ).unwrap()
}

///|
fn model_images(value : Permutation) -> Array[Int] {
  @oracle.array(images(value)).map(@oracle.int_of_nat)
}

///|
fn model_elements(group : FiniteGroup) -> Array[Array[Int]] {
  @oracle.array(group_elements(group)).map(model_images)
}

///|
fn test_group(n : Int, generators : Array[Array[Int]], fuel? : Int = 100) -> FiniteGroup {
  match generate(
    @oracle.nat(n),
    @oracle.chain(generators.map(test_permutation)),
    @oracle.nat(fuel),
  ) {
    Complete(group) => group
    _ => abort("test fixture did not complete")
  }
}

///|
fn assert_model_group(
  n : Int,
  generators : Array[Array[Int]],
  expected_order : Int,
  expected_series : Array[Int],
  solvable : Bool,
) -> Unit raise {
  let group = test_group(n, generators, fuel=expected_order)
  let proof = analyze(group)
  let independent = model_closure(n, generators)
  assert_eq(independent.length(), expected_order)
  assert_eq(@oracle.int_of_nat(order(group)), expected_order)
  assert_true(model_same(model_elements(group), independent))
  let expected = model_series(independent)
  let actual = @oracle.array(proof.derived_series)
  assert_eq(actual.length(), expected.length())
  assert_eq(actual.length(), expected_series.length())
  for index in 0..<actual.length() {
    let stage = @oracle.array(actual[index]).map(model_images)
    assert_true(model_same(stage, expected[index]))
    assert_eq(stage.length(), expected_series[index])
  }
  assert_eq(is_solvable(proof), solvable)
  assert_true(verify_certificate(@oracle.nat(n), group_generators(group), proof))
  assert_true(check_result(group, proof))
  let reversed = [for index in 0..<generators.length() =>
    generators[generators.length() - index - 1]]
  let reordered = test_group(n, reversed, fuel=expected_order)
  assert_eq(analyze(reordered), proof)
  assert_true(verify_certificate(
    @oracle.nat(n),
    @oracle.chain(reversed.map(test_permutation)),
    proof,
  ))
}

///|
fn all_model_permutations(n : Int) -> Array[Array[Int]] {
  fn expand(prefix : Array[Int], n : Int) -> Array[Array[Int]] {
    if prefix.length() == n { return [prefix] }
    let result = []
    for point in 0..<n {
      if !prefix.contains(point) {
        let next = prefix.copy()
        next.push(point)
        for permutation in expand(next, n) { result.push(permutation) }
      }
    }
    result
  }
  expand([], n)
}

///|
test "checked permutations and composition against exhaustive array models" {
  for n in 0..<5 {
    let models = all_model_permutations(n)
    for left in models {
      let p = test_permutation(left)
      assert_eq(@oracle.int_of_nat(degree(p)), n)
      assert_true(model_equal(model_images(inverse(p)), model_inverse(left)))
      assert_eq(compose(p, inverse(p)), Some(identity(@oracle.nat(n))))
      assert_eq(compose(inverse(p), p), Some(identity(@oracle.nat(n))))
      assert_eq(apply(p, @oracle.nat(n)), None)
      for right in models {
        let q = test_permutation(right)
        assert_true(model_equal(
          model_images(compose(p, q).unwrap()),
          model_compose(left, right),
        ))
        assert_true(model_equal(
          model_images(commutator(p, q).unwrap()),
          model_commutator(left, right),
        ))
      }
    }
  }
  let three = @oracle.nat(3)
  assert_eq(checked_permutation(three, @oracle.chain([0, 1].map(@oracle.nat))), None)
  assert_eq(checked_permutation(three, @oracle.chain([0, 0, 2].map(@oracle.nat))), None)
  assert_eq(checked_permutation(three, @oracle.chain([0, 1, 3].map(@oracle.nat))), None)
  assert_eq(compose(identity(three), identity(@oracle.nat(2))), None)
  assert_eq(commutator(identity(three), identity(@oracle.nat(2))), None)
}

///|
test "composition associativity and canonical comparison on all S3 elements" {
  let values = all_model_permutations(3).map(test_permutation)
  for i in 0..<values.length() {
    for j in 0..<values.length() {
      assert_eq(compare(values[i], values[j]),
        if i < j { @core.Less } else if i == j { Equal } else { Greater })
      for k in 0..<values.length() {
        assert_eq(
          compose(compose(values[i], values[j]).unwrap(), values[k]),
          compose(values[i], compose(values[j], values[k]).unwrap()),
        )
      }
    }
  }
}

///|
test "fuel exhaustion is resumable and never a completed group" {
  let generators = @oracle.chain([[1, 0, 2], [1, 2, 0]].map(test_permutation))
  let degree = @oracle.nat(3)
  let state = match generate(degree, generators, Zero) {
    Pending(state) => state
    _ => abort("zero fuel should pause")
  }
  assert_eq(resume_generation(state, Zero), Pending(state))
  let state = match resume_generation(state, @oracle.nat(5)) {
    Pending(state) => state
    _ => abort("S3 requires six processed elements")
  }
  let group = match resume_generation(state, @oracle.nat(1)) {
    Complete(group) => group
    _ => abort("the sixth step completes S3")
  }
  assert_eq(order(group), @oracle.nat(6))
  assert_eq(generate(degree, Cons(identity(@oracle.nat(2)), Nil), @oracle.nat(20)), InvalidGenerators)
  // White-box adversary bypasses the private checked constructor.
  let invalid : Permutation = { degree, images: @oracle.chain([0, 0, 0].map(@oracle.nat)), }
  assert_eq(generate(degree, Cons(invalid, Nil), @oracle.nat(20)), InvalidGenerators)
}

///|
test "cyclic groups C1 through C8 and degree-zero trivial group" {
  assert_model_group(0, [], 1, [1], true)
  for n in 1..<9 {
    assert_model_group(n, [[for i in 0..<n => (i + 1) % n]], n,
      if n == 1 { [1] } else { [n, 1] }, true)
  }
}

///|
test "V4 exact derived series" {
  assert_model_group(4, [[1, 0, 3, 2], [2, 3, 0, 1]], 4, [4, 1], true)
}

///|
test "S3 exact derived series" {
  assert_model_group(3, [[1, 0, 2], [1, 2, 0]], 6, [6, 3, 1], true)
}

///|
test "D4 square symmetries exact derived series" {
  assert_model_group(4, [[1, 2, 3, 0], [0, 3, 2, 1]], 8, [8, 2, 1], true)
}

///|
test "A4 exact derived series" {
  assert_model_group(4, [[1, 2, 0, 3], [1, 0, 3, 2]], 12, [12, 4, 1], true)
}

///|
test "A5 completes and is nontrivial perfect by independent all-commutator closure" {
  assert_model_group(5, [[1, 2, 0, 3, 4], [1, 2, 3, 4, 0]], 60, [60], false)
}

///|
test "S4 and S5 distinguish eventual triviality from a proper perfect terminal group" {
  assert_model_group(4, [[1, 0, 2, 3], [1, 2, 3, 0]], 24, [24, 12, 4, 1], true)
  assert_model_group(5, [[1, 0, 2, 3, 4], [1, 2, 3, 4, 0]], 120, [120, 60], false)
}

///|
test "subgroups normality and commutativity use concrete membership" {
  let s3 = test_group(3, [[1, 0, 2], [1, 2, 0]])
  let a3 = test_group(3, [[1, 2, 0]])
  let c2 = test_group(3, [[1, 0, 2]])
  assert_true(is_subgroup(a3, s3))
  assert_true(is_subgroup(c2, s3))
  assert_true(is_normal(a3, s3))
  assert_false(is_normal(c2, s3))
  assert_false(is_subgroup(s3, a3))
  assert_false(is_subgroup(test_group(2, []), s3))
  assert_true(is_abelian(a3))
  assert_false(is_abelian(s3))
  assert_true(same_group(derived_subgroup(s3), a3))
  assert_true(contains(s3, test_permutation([2, 1, 0])))
  assert_false(contains(a3, test_permutation([2, 1, 0])))
  assert_false(contains(s3, identity(@oracle.nat(2))))
}

///|
test "certificates reject context results series conclusion and element tampering" {
  let group = test_group(3, [[1, 0, 2], [1, 2, 0]])
  let proof = analyze(group)
  let degree = group_degree(group)
  let generators = group_generators(group)
  let altered : Array[Certificate] = [
    { ..proof, degree: @oracle.nat(2), },
    { ..proof, generators: Nil, },
    { ..proof, elements: Nil, },
    { ..proof, elements: Cons(identity(degree), proof.elements), },
    { ..proof, elements: @core.reverse(proof.elements), },
    { ..proof, derived_series: Nil, },
    { ..proof, derived_series: Cons(proof.elements, Nil), },
    { ..proof, derived_series: @core.reverse(proof.derived_series), },
    { ..proof, conclusion: NonSolvable, },
  ]
  for bad in altered {
    assert_false(verify_certificate(degree, generators, bad))
    assert_false(check_result(group, bad))
  }
  let a3 = test_group(3, [[1, 2, 0]])
  assert_false(check_result(a3, proof))
  assert_false(check_result(group, analyze(a3)))
  assert_false(verify_certificate(@oracle.nat(4), generators, proof))
  assert_false(verify_certificate(degree, group_generators(a3), proof))
  let wrong_result : FiniteGroup = { ..group, members: a3.members, }
  assert_false(check_result(wrong_result, proof))
  let duplicates = @core.append(generators, generators)
  assert_true(verify_certificate(degree, duplicates, proof))
  let fake : Permutation = { degree, images: @oracle.chain([0, 0, 0].map(@oracle.nat)), }
  assert_false(verify_certificate(degree, Cons(fake, Nil), proof))
  assert_false(verify_certificate(degree, generators, { ..proof, elements: Cons(fake, proof.elements), }))
}
