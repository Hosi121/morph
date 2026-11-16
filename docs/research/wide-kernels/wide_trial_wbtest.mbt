///|
fn reversed_remainder_bits(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  fn walk(xs : @core.Chain[Bool], divisor : Binary, rest : Binary) -> Binary {
    match xs {
      Nil => rest
      Cons(bit, tail) => {
        let next = Binary::{ bits: low_bit(bit, rest.bits), }
        match compare(next, divisor) {
          Less => walk(tail, divisor, next)
          Equal => walk(tail, divisor, zero())
          Greater =>
            walk(
              tail,
              divisor,
              from_bits(subtract_bits(next.bits, divisor.bits, false)),
            )
        }
      }
    }
  }
  walk(@core.reverse(xs), divisor, zero())
}

///|
fn reversed_divide_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : Binary,
    quotient : @core.Chain[Bool],
    rest : Binary,
  ) -> (Binary, Binary) {
    match xs {
      Nil => ({ bits: quotient, }, rest)
      Cons(bit, tail) => {
        let next = Binary::{ bits: low_bit(bit, rest.bits), }
        match compare(next, divisor) {
          Less => walk(tail, divisor, low_bit(false, quotient), next)
          Equal => walk(tail, divisor, low_bit(true, quotient), zero())
          Greater =>
            walk(
              tail,
              divisor,
              low_bit(true, quotient),
              from_bits(subtract_bits(next.bits, divisor.bits, false)),
            )
        }
      }
    }
  }
  walk(@core.reverse(xs), divisor, Nil, zero())
}

///|
test "reversed division agrees with independent small integer arithmetic" {
  for a in 0..<256 {
    for b in 1..<128 {
      let left = @oracle.binary(a)
      let divisor = @oracle.binary(b)
      assert_eq(
        reversed_remainder_bits(left.bits, divisor),
        @oracle.binary(a % b),
      )
      assert_eq(
        reversed_divide_bits(left.bits, divisor),
        (@oracle.binary(a / b), @oracle.binary(a % b)),
      )
    }
  }
}

///|
test "reversed symbolic powers avoid recursive call stack consumption" {
  let word = pair(@oracle.nat(20000), zero())
  let three = @oracle.binary(3)
  // Python pow(2, 20000, 3) = 1; the operands share no non-unit factor.
  assert_eq(reversed_remainder_bits(word.bits, three), one())
  let (q, r) = reversed_divide_bits(word.bits, three)
  assert_eq(r, one())
  assert_true(odd(q))
  assert_eq(@oracle.int_of_nat(@core.length(q.bits)), 19999)
}

///|
test "reversed traversal versus recursive wide division" (b : @bench.T) {
  for (width, denominator) in [(128, 3), (512, 31), (4096, 3)] {
    let word = pair(@oracle.nat(width), @oracle.binary(5))
    let divisor = @oracle.binary(denominator)
    b.bench(name="recursive quotient \{width}/\{denominator}", fn() {
      b.keep(divide_bits(word.bits, divisor))
    })
    b.bench(name="reversed quotient \{width}/\{denominator}", fn() {
      b.keep(reversed_divide_bits(word.bits, divisor))
    })
    b.bench(name="recursive remainder \{width}/\{denominator}", fn() {
      b.keep(remainder_bits(word.bits, divisor))
    })
    b.bench(name="reversed remainder \{width}/\{denominator}", fn() {
      b.keep(reversed_remainder_bits(word.bits, divisor))
    })
  }
}
