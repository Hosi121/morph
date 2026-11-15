///|
fn assoc_lookup(
  entries : @core.Chain[(@binary.Binary, @binary.Binary)],
  key : @binary.Binary,
) -> @binary.Binary? {
  match entries {
    Nil => None
    Cons((found, value), rest) =>
      match @binary.compare(found, key) {
        Equal => Some(value)
        _ => assoc_lookup(rest, key)
      }
  }
}

///|
test "five fixed lookups on a 1024-entry association list" (b : @bench.T) {
  let entries = @oracle.chain(
    [
      for i in 0..<1024 => (@oracle.binary(i), @oracle.binary(i * i))
    ],
  )
  let queries = @oracle.chain([0, 127, 511, 1023, 1024].map(@oracle.binary))
  b.bench(fn() {
    b.keep(@core.map(queries, fn(key) { assoc_lookup(entries, key) }))
  })
}

///|
test "same five lookups on a persistent AVL with binary keys" (b : @bench.T) {
  let entries = @oracle.chain(
    [
      for i in 0..<1024 => (@oracle.binary(i), @oracle.binary(i * i))
    ],
  )
  let map = @core.fold_left(entries, @avl.empty(), fn(map, pair) {
    let (key, value) = pair
    @avl.put(map, key, value, @binary.compare)
  })
  let queries = @oracle.chain([0, 127, 511, 1023, 1024].map(@oracle.binary))
  b.bench(fn() {
    b.keep(
      @core.map(queries, fn(key) { @avl.lookup(map, key, @binary.compare) }),
    )
  })
}
