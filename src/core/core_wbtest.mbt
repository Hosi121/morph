///|
test "unary arithmetic against machine arithmetic" {
  for a in 0..<25 {
    for b in 0..<25 {
      assert_eq(@oracle.int_of_nat(add(@oracle.nat(a), @oracle.nat(b))), a + b)
      assert_eq(
        @oracle.int_of_nat(multiply(@oracle.nat(a), @oracle.nat(b))),
        a * b,
      )
      assert_eq(
        @oracle.int_of_nat(subtract(@oracle.nat(a), @oracle.nat(b))),
        if a < b {
          0
        } else {
          a - b
        },
      )
      match divmod(@oracle.nat(a), @oracle.nat(b)) {
        None => assert_eq(b, 0)
        Some((q, r)) => {
          assert_eq(@oracle.int_of_nat(q), a / b)
          assert_eq(@oracle.int_of_nat(r), a % b)
        }
      }
    }
  }
  assert_eq(@oracle.int_of_nat(gcd(@oracle.nat(48), @oracle.nat(18))), 6)
}

///|
test "list structural laws and edge cases" {
  let xs = Cons(Zero, Cons(Succ(Zero), Cons(Succ(Succ(Zero)), Nil)))
  assert_eq(reverse(reverse(xs)), xs)
  assert_eq(length(xs), @oracle.nat(3))
  assert_eq(append(take(@oracle.nat(2), xs), drop(@oracle.nat(2), xs)), xs)
  let (evens, odds) = alternating(xs)
  assert_eq(interleave(evens, odds), xs)
  assert_eq(nth(xs, @oracle.nat(3)), None)
  let short : Chain[Nat] = Nil
  assert_eq(zip(xs, short), None)
  let empty : Chain[(Nat, Nat)]? = zip(Nil, Nil)
  assert_eq(empty, Some(Nil))
}
