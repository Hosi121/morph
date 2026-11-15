///|
test "one full-adder program in three Boolean forms matches integer arithmetic" {
  for a in [false, true] {
    for b in [false, true] {
      for c in [false, true] {
        let n = (if a { 1 } else { 0 }) +
          (if b { 1 } else { 0 }) +
          (if c { 1 } else { 0 })
        let expected = (n % 2 != 0, n >= 2)
        assert_eq(full_adder_minterms(algebra(), a, b, c), expected)
        assert_eq(full_adder_propagate(algebra(), a, b, c), expected)
        assert_eq(full_adder_mux(algebra(), a, b, c), expected)
      }
    }
  }
}

///|
test "fixed width ripple words preserve carry and reject unequal widths" {
  for width in 0..<=6 {
    for a in 0..<(1 << width) {
      for b in 0..<(1 << width) {
        for carry in [false, true] {
          let left = @oracle.chain(
            [
              for bit in 0..<width => (a & (1 << bit)) != 0
            ],
          )
          let right = @oracle.chain(
            [
              for bit in 0..<width => (b & (1 << bit)) != 0
            ],
          )
          let (sum, high) = add_words(
            fn(x, y, c) { full_adder_mux(algebra(), x, y, c) },
            left,
            right,
            carry,
          ).unwrap()
          let mut actual = if high { 1 << width } else { 0 }
          for i, bit in @oracle.array(sum) {
            if bit {
              actual += 1 << i
            }
          }
          assert_eq(actual, a + b + (if carry { 1 } else { 0 }))
        }
      }
    }
  }
  assert_eq(
    add_words(
      fn(a, b, c) { full_adder_mux(algebra(), a, b, c) },
      Nil,
      @core.Cons(true, Nil),
      false,
    ),
    None,
  )
}
