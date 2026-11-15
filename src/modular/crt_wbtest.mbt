///|
test "generalized CRT exhausts small coprime and non-coprime congruences" {
  for m in 2..<=12 {
    for n in 2..<=12 {
      let mut lcm = m * n
      for candidate in 1..<=(m * n) {
        if candidate % m == 0 && candidate % n == 0 {
          lcm = candidate
          break
        }
      }
      for a in 0..<m {
        for b in 0..<n {
          let mut first = -1
          for candidate in 0..<(m * n) {
            if candidate % m == a && candidate % n == b {
              first = candidate
              break
            }
          }
          let left = congruence(mod(m), @oracle.binary(a))
          let right = congruence(mod(n), @oracle.binary(b))
          match chinese_remainder(left, right) {
            None => assert_eq(first, -1)
            Some(result) => {
              assert_eq(@oracle.int_of_binary(residue(result)), first)
              assert_eq(@oracle.int_of_binary(value(period(result))), lcm)
              assert_eq(chinese_remainder(right, left), Some(result))
            }
          }
        }
      }
    }
  }
  let classes = @oracle.chain([
    congruence(mod(3), @oracle.binary(2)),
    congruence(mod(5), @oracle.binary(3)),
    congruence(mod(7), @oracle.binary(2)),
  ])
  assert_eq(
    chinese_remainders(classes).map(fn(c) { @oracle.int_of_binary(residue(c)) }),
    Some(23),
  )
  assert_eq(chinese_remainders(Nil), None)
}
