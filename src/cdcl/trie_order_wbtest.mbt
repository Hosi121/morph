///|
fn[A] index_first_get(index : Index[A], key : @core.Chain[Bool]) -> A? {
  match (index, key) {
    (Empty, _) => None
    (Branch(value, _, _), Nil) => value
    (Branch(_, left, _), Cons(false, rest)) => index_first_get(left, rest)
    (Branch(_, _, right), Cons(true, rest)) => index_first_get(right, rest)
  }
}

///|
fn[A] key_first_get(index : Index[A], key : @core.Chain[Bool]) -> A? {
  match key {
    Nil =>
      match index {
        Empty => None
        Branch(value, _, _) => value
      }
    Cons(false, rest) =>
      match index {
        Empty => None
        Branch(_, left, _) => key_first_get(left, rest)
      }
    Cons(true, rest) =>
      match index {
        Empty => None
        Branch(_, _, right) => key_first_get(right, rest)
      }
  }
}

///|
fn fused_trie_value(
  values : Index[Assignment],
  key : @core.Chain[Bool],
  positive : Bool,
) -> Value {
  match key {
    Nil =>
      match values {
        Branch(Some(entry), _, _) =>
          match (entry.literal.positive, positive) {
            (true, true) | (false, false) => True
            _ => False
          }
        _ => Unassigned
      }
    Cons(false, rest) =>
      match values {
        Empty => Unassigned
        Branch(_, left, _) => fused_trie_value(left, rest, positive)
      }
    Cons(true, rest) =>
      match values {
        Empty => Unassigned
        Branch(_, _, right) => fused_trie_value(right, rest, positive)
      }
  }
}

///|
fn paired_trie_value(
  values : Index[Assignment],
  key : @core.Chain[Bool],
  positive : Bool,
) -> Value {
  match (key, values) {
    (Cons(false, Cons(false, rest)), Branch(_, Branch(_, next, _), _)) =>
      paired_trie_value(next, rest, positive)
    (Cons(false, Cons(true, rest)), Branch(_, Branch(_, _, next), _)) =>
      paired_trie_value(next, rest, positive)
    (Cons(true, Cons(false, rest)), Branch(_, _, Branch(_, next, _))) =>
      paired_trie_value(next, rest, positive)
    (Cons(true, Cons(true, rest)), Branch(_, _, Branch(_, _, next))) =>
      paired_trie_value(next, rest, positive)
    (Cons(_, Cons(_, _)), _) => Unassigned
    _ => fused_trie_value(values, key, positive)
  }
}

///|
fn paired_retry_value(
  values : Index[Assignment],
  key : @core.Chain[Bool],
  positive : Bool,
) -> Value {
  match (key, values) {
    (Cons(false, Cons(false, rest)), Branch(_, Branch(_, next, _), _)) =>
      paired_retry_value(next, rest, positive)
    (Cons(false, Cons(true, rest)), Branch(_, Branch(_, _, next), _)) =>
      paired_retry_value(next, rest, positive)
    (Cons(true, Cons(false, rest)), Branch(_, _, Branch(_, next, _))) =>
      paired_retry_value(next, rest, positive)
    (Cons(true, Cons(true, rest)), Branch(_, _, Branch(_, _, next))) =>
      paired_retry_value(next, rest, positive)
    _ => fused_trie_value(values, key, positive)
  }
}

///|
fn[A] rebuilding_get(index : Index[A], key : @core.Chain[Bool]) -> A? {
  match (key, index) {
    (Nil, Empty) => None
    (Nil, Branch(value, _, _)) => value
    (Cons(false, rest), Branch(_, left, _)) =>
      match rebuilding_get(left, rest) {
        None => None
        Some(value) => Some(value)
      }
    (Cons(true, rest), Branch(_, _, right)) =>
      match rebuilding_get(right, rest) {
        None => None
        Some(value) => Some(value)
      }
    _ => None
  }
}

///|
fn rebuilding_value(literal : Atom, values : Index[Assignment]) -> Value {
  match rebuilding_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match (entry.literal.positive, literal.positive) {
        (true, true) | (false, false) => True
        _ => False
      }
  }
}

///|
fn index_first_value(literal : Atom, values : Index[Assignment]) -> Value {
  match index_first_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match (entry.literal.positive, literal.positive) {
        (true, true) | (false, false) => True
        _ => False
      }
  }
}

///|
fn key_first_value(literal : Atom, values : Index[Assignment]) -> Value {
  match key_first_get(values, @binary.bits(literal.key)) {
    None => Unassigned
    Some(entry) =>
      match (entry.literal.positive, literal.positive) {
        (true, true) | (false, false) => True
        _ => False
      }
  }
}

///|
test "key-first traversal preserves present absent prefix and boxed optional values" {
  let labels = [0, 1, 2, 3, 255, 256, 257, 65535]
  let atoms = labels.map(fn(label) { atom(lit(label, label % 2 == 0)) })
  for mask in 0..<256 {
    let mut assignments = Empty
    let mut bools = Empty
    let mut lists = Empty
    for index in 0..<labels.length() {
      if mask / (1 << index) % 2 == 1 {
        let literal = atoms[index]
        let key = @binary.bits(literal.key)
        assignments = index_put(assignments, key, {
          literal,
          level: Zero,
          reason: None,
        })
        bools = index_put(bools, key, literal.positive)
        lists = index_put(
          lists,
          key,
          if index % 2 == 0 {
            @core.Nil
          } else {
            @core.Cons(literal.key, Nil)
          },
        )
      }
    }
    for literal in atoms {
      let key = @binary.bits(literal.key)
      assert_eq(
        index_first_get(assignments, key),
        key_first_get(assignments, key),
      )
      assert_eq(index_first_get(bools, key), key_first_get(bools, key))
      assert_eq(index_first_get(lists, key), key_first_get(lists, key))
      assert_eq(
        index_first_get(assignments, key),
        rebuilding_get(assignments, key),
      )
      assert_eq(index_first_get(bools, key), rebuilding_get(bools, key))
      assert_eq(index_first_get(lists, key), rebuilding_get(lists, key))
      assert_eq(index_get(assignments, key), key_first_get(assignments, key))
      for positive in [false, true] {
        let query = { ..literal, positive, }
        match
          (
            index_first_value(query, assignments),
            index_value(query, assignments),
          ) {
          (True, True) | (False, False) | (Unassigned, Unassigned) => ()
          _ =>
            fail("fused value lookup must preserve all polarities and absence")
        }
        match
          (
            index_first_value(query, assignments),
            paired_trie_value(assignments, key, positive),
          ) {
          (True, True) | (False, False) | (Unassigned, Unassigned) => ()
          _ =>
            fail("paired value lookup must preserve all polarities and absence")
        }
        match
          (
            index_first_value(query, assignments),
            paired_retry_value(assignments, key, positive),
          ) {
          (True, True) | (False, False) | (Unassigned, Unassigned) => ()
          _ =>
            fail("paired retry lookup must preserve all polarities and absence")
        }
      }
    }
    let missing = @binary.bits(@oracle.binary(65534))
    assert_eq(
      index_first_get(assignments, missing),
      key_first_get(assignments, missing),
    )
    assert_eq(index_first_get(bools, missing), key_first_get(bools, missing))
    assert_eq(index_first_get(lists, missing), key_first_get(lists, missing))
  }
}

///|
fn trie_order_queries(
  values : Index[Assignment],
  keys : Array[@core.Chain[Bool]],
  key_first : Bool,
) -> Int32 {
  let mut sum = 0
  for key in keys {
    let result = if key_first {
      key_first_get(values, key)
    } else {
      index_first_get(values, key)
    }
    match result {
      None => ()
      Some(entry) => sum += if entry.literal.positive { 1 } else { 2 }
    }
  }
  sum
}

///|
test "same executable trie traversal order ABBA lookup comparison" (
  b : @bench.T,
) {
  let mut values = Empty
  let mut source = @core.Zero
  for variable in 0..<512 {
    let literal = Atom::{
      key: @oracle.binary(variable),
      source,
      positive: variable % 2 == 0,
    }
    values = index_put(values, @binary.bits(literal.key), {
      literal,
      level: Zero,
      reason: None,
    })
    source = @core.Succ(source)
  }
  let keys = [
    for variable in 0..<1024 => @binary.bits(@oracle.binary(variable))
  ]
  assert_eq(
    trie_order_queries(values, keys, false),
    trie_order_queries(values, keys, true),
  )
  b.bench(
    fn() { b.keep(trie_order_queries(values, keys, false)) },
    name="index-first trie lookup first control",
  )
  b.bench(
    fn() { b.keep(trie_order_queries(values, keys, true)) },
    name="key-first trie lookup",
  )
  b.bench(
    fn() { b.keep(trie_order_queries(values, keys, true)) },
    name="key-first trie lookup repeated control",
  )
  b.bench(
    fn() { b.keep(trie_order_queries(values, keys, false)) },
    name="index-first trie lookup repeated control",
  )
}

///|
fn trie_complete_query(cnf : @sat.Cnf, budget : @core.Nat) -> Bool {
  match run(start(cnf), budget) {
    Satisfiable(model) => @sat.check_model(cnf, model)
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      match @ruplog.build_prepared(input, proof) {
        None => false
        Some(logged) => @ruplog.check_prepared(input, logged)
      }
    }
    _ => false
  }
}

///|
test "saved executable complete query and checker control" (b : @bench.T) {
  let cnf = @circuit.cnf(miter_formula(64))
  let budget = fuel(200000)
  let (outcome, stats) = run_measured(start(cnf), budget)
  let (input, logged) = match outcome {
    Unsatisfiable(proof) => {
      let input = @ruplog.prepare(cnf)
      let logged = @ruplog.build_prepared(input, proof).unwrap()
      assert_true(@ruplog.check_prepared(input, logged))
      (input, logged)
    }
    _ => fail("trie-order miter must be refuted")
  }
  println(
    "trie-query stats transitions=\{@oracle.int_of_nat(stats.transitions)} decisions=\{@oracle.int_of_nat(stats.decisions)} conflicts=\{@oracle.int_of_nat(stats.conflicts)} hints=\{@oracle.int_of_nat(@ruplog.hint_count(logged))}",
  )
  b.bench(
    fn() { b.keep(trie_complete_query(cnf, budget)) },
    name="complete sixty-four-bit hinted query",
  )
  b.bench(
    fn() { b.keep(@ruplog.check_prepared(input, logged)) },
    name="unchanged prepared hinted checker control",
  )
}

///|
fn trie_value_fixture() -> (Index[Assignment], Array[Atom]) {
  let mut values = Empty
  let mut source = @core.Zero
  let queries = []
  for variable in 0..<1024 {
    let literal = Atom::{
      key: @oracle.binary(variable),
      source,
      positive: variable % 2 == 0,
    }
    queries.push(literal)
    if variable < 512 {
      values = index_put(values, @binary.bits(literal.key), {
        literal,
        level: Zero,
        reason: None,
      })
    }
    source = @core.Succ(source)
  }
  (values, queries)
}

///|
fn trie_value_queries(
  values : Index[Assignment],
  queries : Array[Atom],
  mode : Int32,
) -> Int32 {
  let mut sum = 0
  for query in queries {
    let value = match mode {
      0 => index_first_value(query, values)
      1 => key_first_value(query, values)
      2 => fused_trie_value(values, @binary.bits(query.key), query.positive)
      3 => paired_trie_value(values, @binary.bits(query.key), query.positive)
      4 => rebuilding_value(query, values)
      _ => paired_retry_value(values, @binary.bits(query.key), query.positive)
    }
    sum += match value {
      Unassigned => 0
      True => 1
      False => 2
    }
  }
  sum
}

///|
test "trie value lookup compares generic and fused reads" (b : @bench.T) {
  let (values, queries) = trie_value_fixture()
  assert_eq(
    trie_value_queries(values, queries, 0),
    trie_value_queries(values, queries, 1),
  )
  assert_eq(
    trie_value_queries(values, queries, 0),
    trie_value_queries(values, queries, 2),
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 0)) },
    name="index-first generic value first control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 1)) },
    name="key-first generic value",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="key-first fused value",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="key-first fused value repeated control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 1)) },
    name="key-first generic value repeated control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 0)) },
    name="index-first generic value repeated control",
  )
}

///|
test "fused value lookup compares one-bit and two-bit steps" (b : @bench.T) {
  let (values, queries) = trie_value_fixture()
  assert_eq(
    trie_value_queries(values, queries, 2),
    trie_value_queries(values, queries, 3),
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="one-bit fused value first control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 3)) },
    name="two-bit fused value",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 3)) },
    name="two-bit fused value repeated control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="one-bit fused value repeated control",
  )
}

///|
test "borrowed descent candidate rebuilds the optional result" (b : @bench.T) {
  let (values, queries) = trie_value_fixture()
  assert_eq(
    trie_value_queries(values, queries, 0),
    trie_value_queries(values, queries, 4),
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="tail fused value first control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 4)) },
    name="rebuilding optional lookup",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 4)) },
    name="rebuilding optional lookup repeated control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="tail fused value repeated control",
  )
}

///|
test "borrow-preserving paired lookup retries missing paths" (b : @bench.T) {
  let (values, queries) = trie_value_fixture()
  assert_eq(
    trie_value_queries(values, queries, 0),
    trie_value_queries(values, queries, 5),
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="one-bit fused value first control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 5)) },
    name="paired borrowed-pattern value",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 5)) },
    name="paired borrowed-pattern repeated control",
  )
  b.bench(
    fn() { b.keep(trie_value_queries(values, queries, 2)) },
    name="one-bit fused value repeated control",
  )
}
