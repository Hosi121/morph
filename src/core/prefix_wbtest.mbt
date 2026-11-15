///|
test "constant prefix shares its semantic tail and permits long unary counts" {
  let suffix : Chain[Bool] = Cons(true, Cons(false, Cons(true, Nil)))
  for count in 0..<=128 {
    let mut n = Zero
    for _ in 0..<count {
      n = Succ(n)
    }
    assert_eq(
      replicate_onto(n, false, suffix),
      append(replicate(n, false), suffix),
    )
    assert_eq(drop(n, replicate_onto(n, false, suffix)), suffix)
  }
  let mut n = Zero
  for _ in 0..<100000 {
    n = Succ(n)
  }
  let expected = add(n, Succ(Succ(Succ(Zero))))
  assert_eq(compare(length(replicate_onto(n, false, suffix)), expected), Equal)
}
