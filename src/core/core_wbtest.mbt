///|
/// Machine integers appear only in this independent test adapter.
fn nat(n : Int32) -> Nat {
  if n <= 0 {
    Zero
  } else {
    Succ(nat(n - 1))
  }
}

///|
fn integer(n : Nat) -> Int32 {
  match n {
    Zero => 0
    Succ(rest) => 1 + integer(rest)
  }
}

///|
test "unary arithmetic against machine arithmetic" {
  for a in 0..<25 {
    for b in 0..<25 {
      assert_eq(integer(add(nat(a), nat(b))), a + b)
      assert_eq(integer(multiply(nat(a), nat(b))), a * b)
      assert_eq(
        integer(subtract(nat(a), nat(b))),
        if a < b {
          0
        } else {
          a - b
        },
      )
      match divmod(nat(a), nat(b)) {
        None => assert_eq(b, 0)
        Some((q, r)) => {
          assert_eq(integer(q), a / b)
          assert_eq(integer(r), a % b)
        }
      }
    }
  }
  assert_eq(integer(gcd(nat(48), nat(18))), 6)
}

///|
test "list structural laws and edge cases" {
  let xs = Cons(Zero, Cons(Succ(Zero), Cons(Succ(Succ(Zero)), Nil)))
  assert_eq(reverse(reverse(xs)), xs)
  assert_eq(length(xs), nat(3))
  assert_eq(append(take(nat(2), xs), drop(nat(2), xs)), xs)
  let (evens, odds) = alternating(xs)
  assert_eq(interleave(evens, odds), xs)
  assert_eq(nth(xs, nat(3)), None)
  let short : Chain[Nat] = Nil
  assert_eq(zip(xs, short), None)
  let empty : Chain[(Nat, Nat)]? = zip(Nil, Nil)
  assert_eq(empty, Some(Nil))
}
