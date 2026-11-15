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
test "all three stable sorts exhaust ternary lists through length seven" {
  for length in 0..<=7 {
    let mut cases = 1
    for _ in 0..<length {
      cases *= 3
    }
    for code in 0..<cases {
      let mut digits = code
      let input = Array::make(length, 0).map(fn(_) {
        let next = digits % 3
        digits /= 3
        next
      })
      let expected = input.copy()
      expected.sort()
      let xs = @oracle.chain(input)
      assert_eq(@oracle.array(merge_sort(xs, compare)), expected)
      assert_eq(@oracle.array(insertion_sort(xs, compare)), expected)
      assert_eq(@oracle.array(quick_sort(xs, compare)), expected)
      let (a, b) = split(xs)
      assert_eq(@core.append(a, b), xs)
    }
  }
}

///|
test "stability records original order inside each equal-key group" {
  let xs = @oracle.chain([(2, 0), (1, 1), (2, 2), (1, 3), (2, 4), (1, 5)])
  let by_key = fn(a : (Int32, Int32), b : (Int32, Int32)) { compare(a.0, b.0) }
  let expected = @oracle.chain([(1, 1), (1, 3), (1, 5), (2, 0), (2, 2), (2, 4)])
  assert_eq(merge_sort(xs, by_key), expected)
  assert_eq(insertion_sort(xs, by_key), expected)
  assert_eq(quick_sort(xs, by_key), expected)
}
