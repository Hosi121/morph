///|
fn prefix_four_remainder(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  fn step(bit : Bool, divisor : Binary, r : Binary) -> Binary {
    let next = Binary::{ bits: low_bit(bit, r.bits), }
    match compare(next, divisor) {
      Less => next
      Equal => zero()
      Greater => from_bits(subtract_bits(next.bits, divisor.bits, false))
    }
  }
  fn walk(
    xs : @core.Chain[Bool],
    divisor : Binary,
    fuel : @core.Nat,
  ) -> Binary {
    match fuel {
      Zero => reversed_remainder_bits(xs, divisor)
      Succ(fuel) =>
        match xs {
          Cons(a, Cons(b, Cons(c, Cons(d, rest)))) => {
            let r = walk(rest, divisor, fuel)
            step(
              a,
              divisor,
              step(b, divisor, step(c, divisor, step(d, divisor, r))),
            )
          }
          _ => remainder_bits(xs, divisor)
        }
    }
  }
  walk(xs, divisor, trial_wide_sixty_four)
}

///|
fn prefix_four_divide(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : Binary,
    fuel : @core.Nat,
  ) -> (@core.Chain[Bool], Binary) {
    match fuel {
      Zero => {
        let (q, r) = reversed_divide_bits(xs, divisor)
        (q.bits, r)
      }
      Succ(fuel) =>
        match xs {
          Cons(b0, Cons(b1, Cons(b2, Cons(b3, rest)))) => {
            let (q, r) = walk(rest, divisor, fuel)
            let next3 = Binary::{ bits: low_bit(b3, r.bits), }
            let order3 = compare(next3, divisor)
            let r3 = match order3 {
              Less => next3
              _ => from_bits(subtract_bits(next3.bits, divisor.bits, false))
            }
            let q3 = low_bit(
              match order3 {
                Less => false
                _ => true
              },
              q,
            )
            let next2 = Binary::{ bits: low_bit(b2, r3.bits), }
            let order2 = compare(next2, divisor)
            let r2 = match order2 {
              Less => next2
              _ => from_bits(subtract_bits(next2.bits, divisor.bits, false))
            }
            let q2 = low_bit(
              match order2 {
                Less => false
                _ => true
              },
              q3,
            )
            let next1 = Binary::{ bits: low_bit(b1, r2.bits), }
            let order1 = compare(next1, divisor)
            let r1 = match order1 {
              Less => next1
              _ => from_bits(subtract_bits(next1.bits, divisor.bits, false))
            }
            let q1 = low_bit(
              match order1 {
                Less => false
                _ => true
              },
              q2,
            )
            let next0 = Binary::{ bits: low_bit(b0, r1.bits), }
            let order0 = compare(next0, divisor)
            let r0 = match order0 {
              Less => next0
              _ => from_bits(subtract_bits(next0.bits, divisor.bits, false))
            }
            let q0 = low_bit(
              match order0 {
                Less => false
                _ => true
              },
              q1,
            )
            (q0, r0)
          }
          _ => {
            let (q, r) = divide_bits(xs, divisor)
            (q.bits, r)
          }
        }
    }
  }
  let (q, r) = walk(xs, divisor, trial_wide_sixty_four)
  ({ bits: q, }, r)
}

///|
test "bounded four-bit right fold matches independent arithmetic and long words" {
  for a in 0..<256 {
    for b in 1..<128 {
      let xs = @oracle.binary(a).bits
      let divisor = @oracle.binary(b)
      assert_eq(prefix_four_remainder(xs, divisor), @oracle.binary(a % b))
      assert_eq(
        prefix_four_divide(xs, divisor),
        (@oracle.binary(a / b), @oracle.binary(a % b)),
      )
    }
  }
  let word = pair(@oracle.nat(20000), zero())
  let three = @oracle.binary(3)
  assert_eq(prefix_four_remainder(word.bits, three), one())
  let (q, r) = prefix_four_divide(word.bits, three)
  assert_eq(r, one())
  assert_true(odd(q))
}

///|
test "fixed four-bit recursive prefix and reverse tail controls" (b : @bench.T) {
  for (width, denominator) in [(128, 3), (512, 31), (4096, 3)] {
    let word = pair(@oracle.nat(width), @oracle.binary(5))
    let divisor = @oracle.binary(denominator)
    b.bench(name="old rem \{width}", fn() {
      b.keep(remainder_bits(word.bits, divisor))
    })
    b.bench(name="prefix4 rem \{width}", fn() {
      b.keep(prefix_four_remainder(word.bits, divisor))
    })
    b.bench(name="old div \{width}", fn() {
      b.keep(divide_bits(word.bits, divisor))
    })
    b.bench(name="prefix4 div \{width}", fn() {
      b.keep(prefix_four_divide(word.bits, divisor))
    })
  }
}
