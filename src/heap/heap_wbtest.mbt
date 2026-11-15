///|
fn compare(a : Int32, b : Int32) -> @core.Ordering {
  if a < b {
    Less
  } else if a > b {
    Greater
  } else {
    Equal
  }
}

///|
fn valid(h : Heap[Int32]) -> Bool {
  fn above(x : Int32, child : Heap[Int32]) -> Bool {
    match child {
      Empty => true
      Node(_, y, _, _) => x <= y
    }
  }
  match h {
    Empty => true
    Node(r, x, left, right) =>
      @oracle.int_of_nat(rank(left)) >= @oracle.int_of_nat(rank(right)) &&
      @oracle.int_of_nat(r) == @oracle.int_of_nat(rank(right)) + 1 &&
      above(x, left) &&
      above(x, right) &&
      valid(left) &&
      valid(right)
  }
}

///|
test "leftist ranks, heap order and persistence after every insertion and pop" {
  let original : Heap[Int32] = empty()
  let mut heap = original
  for i in 0..<200 {
    heap = insert(heap, (i * 73 + 19) % 101, compare)
    assert_true(valid(heap))
  }
  assert_eq(pop(original, compare), None)
  let mut previous = -1
  for _ in 0..<200 {
    match pop(heap, compare) {
      None => fail("early empty")
      Some((value, rest)) => {
        assert_true(previous <= value)
        previous = value
        heap = rest
        assert_true(valid(heap))
      }
    }
  }
  assert_eq(pop(heap, compare), None)
}

///|
test "bottom up heap sort against independent array sorting" {
  for n in 0..<60 {
    let xs = [ for i in 0..<n => (i * 17 + n * 3) % 23 ]
    let expected = xs.copy()
    expected.sort()
    let heap = from_chain(@oracle.chain(xs), compare)
    assert_true(valid(heap))
    assert_eq(@oracle.array(drain(heap, compare)), expected)
  }
}
