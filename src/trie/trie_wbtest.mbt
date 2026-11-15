///|
fn words() -> Array[@core.Chain[Bool]] {
  let result = []
  for length in 0..<=5 {
    for code in 0..<(1 << length) {
      result.push(
        @oracle.chain([ for i in 0..<length => (code & (1 << i)) != 0 ]),
      )
    }
  }
  result
}

///|
fn lex_less(a : @core.Chain[Bool], b : @core.Chain[Bool]) -> Bool {
  let x = @oracle.array(a)
  let y = @oracle.array(b)
  for i in 0..<Int32::min(x.length(), y.length()) {
    if x[i] != y[i] {
      return !x[i] && y[i]
    }
  }
  x.length() < y.length()
}

///|
test "persistent trie lookup, update, deletion, pruning and sorted traversal on all short words" {
  let keys = words()
  let mut trie : Trie[Int32] = empty()
  for i, key in keys {
    let old = trie
    trie = put(trie, key, i)
    assert_eq(lookup(old, key), None)
    for j, candidate in keys {
      assert_eq(lookup(trie, candidate), if j <= i { Some(j) } else { None })
    }
  }
  let full = trie
  for i, key in keys {
    if i % 3 == 0 {
      trie = remove(trie, key)
    }
  }
  for i, key in keys {
    assert_eq(lookup(trie, key), if i % 3 == 0 { None } else { Some(i) })
    assert_eq(lookup(full, key), Some(i))
  }
  assert_eq(@oracle.int_of_nat(size(trie)), 42)
  let listed = @oracle.array(entries(trie))
  for i in 1..<listed.length() {
    assert_true(lex_less(listed[i - 1].0, listed[i].0))
  }
  for (key, value) in listed {
    assert_eq(lookup(trie, key), Some(value))
  }
  for key in keys {
    trie = remove(trie, key)
  }
  assert_eq(trie, Empty)
}

///|
test "prefix lookup, subtries, collision union and functor map" {
  let root : Trie[Int32] = put(empty(), Nil, 10)
  let a = put(
    put(root, @oracle.chain([false]), 20),
    @oracle.chain([false, true]),
    30,
  )
  let b = put(a, @oracle.chain([false, true, false]), 40)
  assert_eq(
    longest_prefix(b, @oracle.chain([false, true, false, true])),
    Some((@oracle.nat(3), 40)),
  )
  assert_eq(
    longest_prefix(a, @oracle.chain([false, true, false, true])),
    Some((@oracle.nat(2), 30)),
  )
  assert_eq(
    longest_prefix(a, @oracle.chain([true])),
    Some((@oracle.nat(0), 10)),
  )
  assert_eq(
    lookup(below(b, @oracle.chain([false, true])), @oracle.chain([false])),
    Some(40),
  )
  let combined = union(a, b, fn(x, y) { x + y })
  assert_eq(lookup(combined, Nil), Some(20))
  assert_eq(lookup(combined, @oracle.chain([false, true, false])), Some(40))
  assert_eq(lookup(a, Nil), Some(10))
  assert_eq(map(a, fn(x) { x }), a)
  assert_eq(
    map(map(a, fn(x) { x + 1 }), fn(x) { x * 2 }),
    map(a, fn(x) { (x + 1) * 2 }),
  )
}
