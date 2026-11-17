///|
fn test_polynomial(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_budget() -> @split.Budget {
  {
    algebra: {
      attempts: @oracle.nat(12),
      work: @oracle.nat(3000),
      coordinate: @oracle.nat(1000),
      comparison: @oracle.nat(1000),
      primes: @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      lift: @oracle.nat(100),
      subset: @oracle.nat(500),
      verification: @oracle.nat(500),
      realization: @oracle.nat(1000),
    },
    primitive: @oracle.nat(12),
  }
}

///|
fn test_group(coefficients : Array[Int32]) -> @gal.Group {
  let splitting = match
    @split.solve(test_polynomial(coefficients), test_budget()).unwrap() {
    @split.Ready(value, _) => value
    _ => abort("small exact splitting fixture did not complete")
  }
  match @gal.advance(@gal.start(splitting).unwrap(), @oracle.nat(50)).unwrap() {
    @gal.Ready(group, _) => group
    _ => abort("small exact Galois fixture did not complete")
  }
}

///|
fn test_analysis(group : @gal.Group, fuel : Int32) -> Analysis raise {
  fn finish(search : Search, fuel : Int32, attempts : Int32) -> Analysis raise {
    if attempts == 0 {
      abort("finite permutation closure did not complete")
    }
    match advance(search, @oracle.nat(fuel)).unwrap() {
      Ready(value, proof) => {
        assert_true(check_result(group, value, proof))
        value
      }
      Paused(next) => finish(next, fuel, attempts - 1)
    }
  }
  finish(start(group).unwrap(), fuel, 300)
}

///|
test "Galois root actions connect to radical solvability including empty roots" {
  for fixture in [([2], [1]), ([1, 0, 1], [2, 1]), ([-2, 0, 0, 1], [6, 3, 1])] {
    let (coefficients, expected) = fixture
    let group = test_group(coefficients)
    let value = test_analysis(group, 100)
    assert_true(is_solvable_by_radicals(value))
    assert_eq(derived_orders(value), @oracle.chain(expected.map(@oracle.nat)))
    assert_eq(@pg.order(permutation_group(value)), @gal.order(group))
    assert_true(check(group, certificate(value)))
  }
}

///|
test "zero fuel and split closure retain the same certified root action" {
  let group = test_group([1, 0, 1])
  let initial = start(group).unwrap()
  let paused = match advance(initial, Zero).unwrap() {
    Paused(value) => value
    _ => abort("zero closure fuel must pause for nontrivial roots")
  }
  match advance(paused, @oracle.nat(100)).unwrap() {
    Ready(value, proof) => {
      let small = test_analysis(group, 1)
      assert_eq(proof.group, certificate(small).group)
      assert_true(check_result(group, small, proof))
      assert_eq(derived_orders(value), derived_orders(small))
    }
    _ => abort("bounded C2 closure must finish")
  }
}

///|
test "solvability certificates bind source conclusion series and actual result" {
  let group = test_group([1, 0, 1])
  let value = test_analysis(group, 100)
  let proof = certificate(value)
  assert_false(
    check(group, {
      ..proof,
      group: { ..proof.group, conclusion: @pg.NonSolvable, },
    }),
  )
  assert_false(
    check(group, { ..proof, group: { ..proof.group, derived_series: Nil, }, }),
  )
  let other_group = test_group([-1, 0, 1])
  let other = test_analysis(other_group, 100)
  assert_false(check(other_group, proof))
  assert_false(check_result(group, other, proof))
  let wrong_cached_group = Analysis::{ ..value, group: other.group, }
  assert_false(check_result(group, wrong_cached_group, proof))
  let wrong_cached_proof = Analysis::{
    ..value,
    proof: { ..proof, galois: certificate(other).galois, },
  }
  assert_false(check_result(group, wrong_cached_proof, proof))
  assert_false(
    check(group, {
      ..proof,
      galois: { ..proof.galois, identity: @oracle.nat(17), },
    }),
  )
}
