///|
let trial_wide_four : @core.Nat = Succ(Succ(Succ(Succ(Zero))))

///|
let trial_wide_sixteen : @core.Nat = @core.add(
  trial_wide_four,
  @core.add(trial_wide_four, @core.add(trial_wide_four, trial_wide_four)),
)

///|
let trial_wide_sixty_four : @core.Nat = @core.add(
  trial_wide_sixteen,
  @core.add(
    trial_wide_sixteen,
    @core.add(trial_wide_sixteen, trial_wide_sixteen),
  ),
)

///|
let trial_wide_budget : @core.Nat = @core.add(
  trial_wide_sixty_four,
  @core.add(
    trial_wide_sixty_four,
    @core.add(trial_wide_sixty_four, trial_wide_sixty_four),
  ),
)

///|
fn bounded_remainder_bits(xs : @core.Chain[Bool], divisor : Binary) -> Binary {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : Binary,
    fuel : @core.Nat,
  ) -> Binary {
    match fuel {
      Zero => reversed_remainder_bits(xs, divisor)
      Succ(fuel) =>
        match xs {
          Nil => zero()
          Cons(bit, rest) => {
            let upper = walk(rest, divisor, fuel)
            let next = Binary::{ bits: low_bit(bit, upper.bits), }
            match compare(next, divisor) {
              Less => next
              Equal => zero()
              Greater =>
                from_bits(subtract_bits(next.bits, divisor.bits, false))
            }
          }
        }
    }
  }
  walk(xs, divisor, trial_wide_budget)
}

///|
fn bounded_divide_bits(
  xs : @core.Chain[Bool],
  divisor : Binary,
) -> (Binary, Binary) {
  fn walk(
    xs : @core.Chain[Bool],
    divisor : Binary,
    fuel : @core.Nat,
  ) -> (Binary, Binary) {
    match fuel {
      Zero => reversed_divide_bits(xs, divisor)
      Succ(fuel) =>
        match xs {
          Nil => (zero(), zero())
          Cons(bit, rest) => {
            let (q, r) = walk(rest, divisor, fuel)
            let next = Binary::{ bits: low_bit(bit, r.bits), }
            match compare(next, divisor) {
              Less => (double(q), next)
              _ =>
                (
                  { bits: Cons(true, q.bits), },
                  from_bits(subtract_bits(next.bits, divisor.bits, false)),
                )
            }
          }
        }
    }
  }
  walk(xs, divisor, trial_wide_budget)
}

///|
test "bounded recursive prefix matches arithmetic and permits a long tail" {
  assert_eq(@oracle.int_of_nat(trial_wide_budget), 256)
  for a in 0..<256 {
    for b in 1..<128 {
      let xs = @oracle.binary(a).bits
      let divisor = @oracle.binary(b)
      assert_eq(bounded_remainder_bits(xs, divisor), @oracle.binary(a % b))
      assert_eq(
        bounded_divide_bits(xs, divisor),
        (@oracle.binary(a / b), @oracle.binary(a % b)),
      )
    }
  }
  let word = pair(@oracle.nat(20000), zero())
  let three = @oracle.binary(3)
  assert_eq(bounded_remainder_bits(word.bits, three), one())
  let (q, r) = bounded_divide_bits(word.bits, three)
  assert_eq(r, one())
  assert_true(odd(q))
}

///|
test "bounded prefix versus recursive wide division" (b : @bench.T) {
  for (width, denominator) in [(128, 3), (512, 31), (4096, 3)] {
    let word = pair(@oracle.nat(width), @oracle.binary(5))
    let divisor = @oracle.binary(denominator)
    b.bench(name="recursive remainder \{width}", fn() {
      b.keep(remainder_bits(word.bits, divisor))
    })
    b.bench(name="bounded remainder \{width}", fn() {
      b.keep(bounded_remainder_bits(word.bits, divisor))
    })
    b.bench(name="recursive quotient \{width}", fn() {
      b.keep(divide_bits(word.bits, divisor))
    })
    b.bench(name="bounded quotient \{width}", fn() {
      b.keep(bounded_divide_bits(word.bits, divisor))
    })
  }
}
