///|
test "cokernel classification reports finite torsion and free summands" {
  let finite = cokernel(completed(imat(2, [[4, 0], [0, 6]])))
  assert_eq(free_rank(finite), @oracle.nat(0))
  assert_eq(
    @oracle.array(@core.map(torsion_factors(finite), @oracle.int_of_binary)),
    [2, 12],
  )
  assert_eq(finite_order(finite), Some(@oracle.binary(24)))
  let infinite = cokernel(completed(imat(2, [[2, 0], [0, 6], [0, 0]])))
  assert_eq(free_rank(infinite), @oracle.nat(1))
  assert_eq(
    @oracle.array(@core.map(torsion_factors(infinite), @oracle.int_of_binary)),
    [2, 6],
  )
  assert_eq(finite_order(infinite), None)
  assert_eq(
    class_coordinates(infinite, ivec([-1, -7, 4])),
    Some(ivec([1, 5, 4])),
  )
  assert_true(equivalent(infinite, ivec([1, 5, 4]), ivec([-1, -7, 4])))
  assert_false(equivalent(infinite, ivec([1, 5, 4]), ivec([1, 5, 5])))
  assert_eq(
    finite_order(cokernel(completed(imat(3, [])))),
    Some(@oracle.binary(1)),
  )
  assert_eq(
    free_rank(cokernel(completed(imat(0, [[], [], []])))),
    @oracle.nat(3),
  )
}

///|
test "Smith coordinates identify exactly the presented relation subgroup" {
  let form = completed(imat(2, [[4, 0], [0, 6]]))
  let group = cokernel(form)
  assert_true(equivalent(group, ivec([4, 0]), ivec([0, 0])))
  assert_true(equivalent(group, ivec([0, 6]), ivec([0, 0])))
  assert_false(equivalent(group, ivec([2, 0]), ivec([0, 0])))
  for a in -6..<7 {
    for b in -6..<7 {
      assert_eq(
        equivalent(group, ivec([a, b]), ivec([0, 0])),
        a % 4 == 0 && b % 6 == 0,
      )
      match verify_answer(form, ivec([a, b])) {
        Solved(_) => assert_true(equivalent(group, ivec([a, b]), ivec([0, 0])))
        Impossible(_) =>
          assert_false(equivalent(group, ivec([a, b]), ivec([0, 0])))
      }
    }
  }
  assert_eq(class_coordinates(group, ivec([0])), None)
  assert_false(equivalent(group, ivec([0]), ivec([0])))
}
