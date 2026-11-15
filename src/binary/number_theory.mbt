///|
/// Stein's binary GCD: remove powers of two and subtract odd parts.
pub fn stein_gcd(a : Binary, b : Binary) -> Binary {
  match (a.bits, b.bits) {
    (Nil, _) => b
    (_, Nil) => a
    _ =>
      match (odd(a), odd(b)) {
        (false, false) => double(stein_gcd(half(a), half(b)))
        (false, true) => stein_gcd(half(a), b)
        (true, false) => stein_gcd(a, half(b))
        (true, true) =>
          match compare(a, b) {
            Equal => a
            Greater =>
              stein_gcd(
                half(from_bits(subtract_bits(a.bits, b.bits, false))),
                b,
              )
            Less =>
              stein_gcd(
                a,
                half(from_bits(subtract_bits(b.bits, a.bits, false))),
              )
          }
      }
  }
}

///|
/// Recursive base-four square root. If s=floor(sqrt(n/4)), the answer is
/// either twice s or its successor, chosen by an exact square comparison.
pub fn sqrt_rem(n : Binary) -> (Binary, Binary) {
  fn root(n : Binary) -> Binary {
    match n.bits {
      Nil => zero()
      _ => {
        let even = double(root(half(half(n))))
        let odd = successor(even)
        match compare(karatsuba(odd, odd), n) {
          Greater => even
          _ => odd
        }
      }
    }
  }
  let root = root(n)
  let square = karatsuba(root, root)
  // The branch above establishes square <= n.
  (root, from_bits(subtract_bits(n.bits, square.bits, false)))
}

///|
/// Fast doubling: returns (F_n,F_(n+1)), consuming the binary exponent spine.
pub fn fibonacci_pair(n : Binary) -> (Binary, Binary) {
  match n.bits {
    Nil => (zero(), one())
    Cons(bit, rest) => {
      let (a, b) = fibonacci_pair({ bits: rest, })
      let twice_b = double(b)
      // F_(k+1) >= F_k ensures this exact difference is nonnegative.
      let factor = from_bits(subtract_bits(twice_b.bits, a.bits, false))
      let even = karatsuba(a, factor)
      let next = add(karatsuba(a, a), karatsuba(b, b))
      match bit {
        false => (even, next)
        true => (next, add(even, next))
      }
    }
  }
}
