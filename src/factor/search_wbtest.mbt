///|
fn standard_bank() -> @core.Chain[@primality.Certificate] {
  @oracle.chain([2, 3, 5, 7].map(small_prime))
}

///|
fn schedule(
  constants : Array[Int32],
) -> @core.Chain[(@binary.Binary, @binary.Binary)] {
  @oracle.chain(constants.map(fn(c) { (@oracle.binary(2), @oracle.binary(c)) }))
}

///|
fn scheduled(n : Int32, constants : Array[Int32]) -> Search {
  factor_search(@oracle.binary(n), standard_bank(), schedule(constants)).unwrap()
}

///|
fn check_complete(complete : Factorization, n : Int32) -> Unit raise {
  assert_eq(factorization_value(complete), @oracle.binary(n))
  let factors = @core.map(prime_factors(complete), @primality.value)
  let product = @core.fold_left(factors, @binary.one(), @binary.multiply)
  assert_eq(product, @oracle.binary(n))
}

///|
test "finite seed schedule recursively factors with certified prime leaves" {
  for n in [1, 2, 4, 6, 9, 12, 15, 21, 25, 49, 120, 210, 840] {
    match search_run(scheduled(n, [1, 2, 3]), @oracle.nat(256)) {
      Complete(complete) => check_complete(complete, n)
      _ => abort("configured small factor search must finish: \{n}")
    }
  }
}

///|
test "scheduler fuel boundaries resume to exactly the same complete state" {
  let search = scheduled(840, [1, 2, 3])
  assert_eq(search_run(search, @oracle.nat(0)), Searching(search))
  for budget in 0..<64 {
    let once = search_run(search, @oracle.nat(budget))
    let mut chunked = Searching(search)
    for _ in 0..<budget {
      chunked = match chunked {
        Searching(next) => search_run(next, @oracle.nat(1))
        result => result
      }
    }
    assert_eq(chunked, once)
    match once {
      Searching(state) | Exhausted(state) => {
        let known = @core.map(proven_certificates(state), @primality.candidate)
        let terms = @core.append(known, unresolved(state))
        assert_eq(
          @core.fold_left(terms, @binary.one(), @binary.multiply),
          search_value(state),
        )
      }
      Complete(complete) => check_complete(complete, 840)
    }
  }
  match search_run(search, @oracle.nat(7)) {
    Searching(next) =>
      assert_eq(
        search_run(next, @oracle.nat(249)),
        search_run(search, @oracle.nat(256)),
      )
    _ => abort("this scheduler fixture must need more than seven actions")
  }
}

///|
test "exhausted schedule is stable and explicit retry can supply a new seed" {
  match search_run(scheduled(21, [1]), @oracle.nat(64)) {
    Exhausted(search) => {
      assert_eq(unresolved(search), Cons(@oracle.binary(21), Nil))
      assert_eq(search_value(search), @oracle.binary(21))
      assert_eq(search_run(search, @oracle.nat(1)), Exhausted(search))
      let retried = retry_search(search, Nil, schedule([2]))
      match search_run(retried, @oracle.nat(64)) {
        Complete(complete) => check_complete(complete, 21)
        _ => abort("replacement c two must finish")
      }
    }
    _ => abort("c one alone exhausts for this candidate")
  }
}

///|
test "missing or invalid prime evidence never becomes an unproved prime leaf" {
  let fake : @primality.Certificate = Lucas(
    @oracle.binary(11),
    @oracle.binary(0),
    Nil,
  )
  let initial = factor_search(
    @oracle.binary(22),
    Cons(fake, standard_bank()),
    schedule([1, 2]),
  ).unwrap()
  match search_run(initial, @oracle.nat(128)) {
    Exhausted(search) => {
      assert_eq(unresolved(search), Cons(@oracle.binary(11), Nil))
      assert_eq(proven_certificates(search), Cons(small_prime(2), Nil))
      let eleven : @primality.Certificate = Lucas(
        @oracle.binary(11),
        @oracle.binary(2),
        Cons(small_prime(2), Cons(small_prime(5), Nil)),
      )
      let retried = retry_search(search, Cons(eleven, Nil), schedule([1]))
      match search_run(retried, @oracle.nat(16)) {
        Complete(complete) => check_complete(complete, 22)
        _ => abort("new prime evidence must preserve earlier progress")
      }
    }
    _ => abort("an uncertified prime cannot be marked complete")
  }
  assert_eq(factor_search(@oracle.binary(0), Nil, Nil), None)
}

///|
test "active trajectory can be restarted explicitly without losing any factors" {
  let search = scheduled(21, [1])
  match search_run(search, @oracle.nat(1)) {
    Searching(active) => {
      assert_eq(unresolved(active), Cons(@oracle.binary(21), Nil))
      match
        search_run(retry_search(active, Nil, schedule([2])), @oracle.nat(64)) {
        Complete(complete) => check_complete(complete, 21)
        _ => abort("explicit active restart must finish")
      }
    }
    _ => abort("first action initializes the trajectory")
  }
}
