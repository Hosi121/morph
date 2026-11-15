///|
fn permutations(values : Array[Int32]) -> Array[Array[Int32]] {
  if values.is_empty() {
    return [[]]
  }
  let found = []
  for i in 0..<values.length() {
    let rest = values[:i].to_owned() + values[i + 1:].to_owned()
    for permutation in permutations(rest) {
      found.push([values[i], ..permutation])
    }
  }
  found
}

///|
/// Independent integer recursion checks cached height/count, order and balance.
fn validate(
  tree : Tree[@binary.Binary, Int32],
  lower : Int32,
  upper : Int32,
) -> (Int32, Int32) raise {
  match tree {
    Empty => (0, 0)
    Branch(h, n, left, key, _, right) => {
      let key = @oracle.int_of_binary(key)
      assert_true(lower < key && key < upper)
      let (lh, ln) = validate(left, lower, key)
      let (rh, rn) = validate(right, key, upper)
      assert_true((lh - rh).abs() <= 1)
      let height = 1 + (if lh > rh { lh } else { rh })
      assert_eq(@oracle.int_of_nat(h), height)
      assert_eq(@oracle.int_of_binary(n), 1 + ln + rn)
      (height, 1 + ln + rn)
    }
  }
}

///|
test "all 5040 insertion permutations and reverse deletions preserve AVL invariants" {
  for permutation in permutations([0, 1, 2, 3, 4, 5, 6]) {
    let mut map : OrderedMap[@binary.Binary, Int32] = empty()
    for key in permutation {
      map = put(map, @oracle.binary(key), key * key, @binary.compare)
      ignore(validate(map.tree, -1, 7))
    }
    assert_eq(@oracle.int_of_binary(size(map)), 7)
    for i in 0..<7 {
      assert_eq(
        select(map, @oracle.binary(i)),
        Some((@oracle.binary(i), i * i)),
      )
      assert_eq(
        @oracle.int_of_binary(rank(map, @oracle.binary(i), @binary.compare)),
        i,
      )
      assert_eq(lookup(map, @oracle.binary(i), @binary.compare), Some(i * i))
    }
    assert_eq(select(map, @oracle.binary(7)), None)
    for key in permutation.rev() {
      map = remove(map, @oracle.binary(key), @binary.compare)
      assert_eq(lookup(map, @oracle.binary(key), @binary.compare), None)
      ignore(validate(map.tree, -1, 7))
    }
    assert_eq(@oracle.int_of_binary(size(map)), 0)
  }
}

///|
test "ascending and mixed updates, persistence, replacement, rank and range" {
  let mut map : OrderedMap[@binary.Binary, Int32] = empty()
  let mut retained = map
  for i in 0..<2048 {
    if i == 100 {
      retained = map
    }
    map = put(map, @oracle.binary(i), i, @binary.compare)
  }
  let (height, count) = validate(map.tree, -1, 2048)
  assert_true(height <= 16)
  assert_eq(count, 2048)
  assert_eq(lookup(retained, @oracle.binary(100), @binary.compare), None)
  assert_eq(@oracle.int_of_binary(size(retained)), 100)
  let old = map
  map = put(map, @oracle.binary(123), -1, @binary.compare)
  assert_eq(lookup(map, @oracle.binary(123), @binary.compare), Some(-1))
  assert_eq(lookup(old, @oracle.binary(123), @binary.compare), Some(123))
  assert_eq(size(map), size(old))
  assert_eq(remove(map, @oracle.binary(9999), @binary.compare), map)
  let interval = @oracle.array(
    between(map, @oracle.binary(20), @oracle.binary(25), @binary.compare),
  )
  assert_eq(interval.map(fn(pair) { @oracle.int_of_binary(pair.0) }), [
    20, 21, 22, 23, 24,
  ])
  let mut oracle = [ for i in 0..<2048 => i ]
  for i in 0..<1024 {
    let key = i * 53 % 2048
    map = remove(map, @oracle.binary(key), @binary.compare)
    oracle = oracle.filter(fn(other) { other != key })
  }
  ignore(validate(map.tree, -1, 2048))
  assert_eq(
    @oracle.array(entries(map)).map(fn(pair) { @oracle.int_of_binary(pair.0) }),
    oracle,
  )
  for i in 0..<2048 {
    assert_eq(
      @oracle.int_of_binary(rank(map, @oracle.binary(i), @binary.compare)),
      oracle.filter(fn(key) { key < i }).length(),
    )
  }
  for i, key in oracle {
    assert_eq(
      select(map, @oracle.binary(i)).map(fn(pair) {
        @oracle.int_of_binary(pair.0)
      }),
      Some(key),
    )
  }
}
