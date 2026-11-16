///|
fn raw_finish(bits : @core.Chain[Bool]) -> Binary {
  match bits {
    Nil => zero()
    Cons(true, Nil) => one()
    _ => { bits, }
  }
}

///|
fn raw_wide_remainder(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : @core.Chain[Bool],
    r : @core.Chain[Bool],
  ) -> @core.Chain[Bool] {
    match xs {
      Nil => r
      Cons(bit, tail) => {
        let next = low_bit(bit, r)
        match compare_bits(next, divisor) {
          Less => walk(tail, divisor, next)
          Equal => walk(tail, divisor, Nil)
          Greater =>
            walk(tail, divisor, trim(subtract_bits(next, divisor, false)))
        }
      }
    }
  }
  raw_finish(walk(@core.reverse(xs), divisor.bits, Nil))
}

///|
fn raw_wide_divide(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : @core.Chain[Bool],
    q : @core.Chain[Bool],
    r : @core.Chain[Bool],
  ) -> (@core.Chain[Bool], @core.Chain[Bool]) {
    match xs {
      Nil => (q, r)
      Cons(bit, tail) => {
        let next = low_bit(bit, r)
        match compare_bits(next, divisor) {
          Less => walk(tail, divisor, low_bit(false, q), next)
          _ =>
            walk(
              tail,
              divisor,
              low_bit(true, q),
              trim(subtract_bits(next, divisor, false)),
            )
        }
      }
    }
  }
  let (q, r) = walk(@core.reverse(xs), divisor.bits, Nil, Nil)
  (raw_finish(q), raw_finish(r))
}

///|
test "unboxed wide state agrees with byte arithmetic and long word digits" {
  for a in 0..<256 {
    for b in 1..<128 {
      let xs = @oracle.binary(a).bits
      let divisor = @oracle.binary(b)
      assert_eq(raw_wide_remainder(xs, divisor), @oracle.binary(a % b))
      assert_eq(
        raw_wide_divide(xs, divisor),
        (@oracle.binary(a / b), @oracle.binary(a % b)),
      )
    }
  }
  let word = pair(@oracle.nat(20000), zero())
  let three = @oracle.binary(3)
  assert_eq(raw_wide_remainder(word.bits, three), one())
  let (q, r) = raw_wide_divide(word.bits, three)
  assert_eq(r, one())
  for rest = q.bits, i = 0 {
    match rest {
      Nil => {
        assert_eq(i, 19999)
        break
      }
      Cons(bit, tail) => {
        assert_eq(bit, i % 2 == 0)
        continue tail, i + 1
      }
    }
  }
}

///|
test "raw bit state versus recursive boxed state" (b : @bench.T) {
  for (width, denominator) in [(128, 3), (512, 31), (4096, 3)] {
    let word = pair(@oracle.nat(width), @oracle.binary(5))
    let divisor = @oracle.binary(denominator)
    b.bench(name="old remainder \{width}", fn() {
      b.keep(remainder_bits(word.bits, divisor))
    })
    b.bench(name="raw remainder \{width}", fn() {
      b.keep(raw_wide_remainder(word.bits, divisor))
    })
    b.bench(name="old quotient \{width}", fn() {
      b.keep(divide_bits(word.bits, divisor))
    })
    b.bench(name="raw quotient \{width}", fn() {
      b.keep(raw_wide_divide(word.bits, divisor))
    })
  }
}
