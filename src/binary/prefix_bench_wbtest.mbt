///|
fn[A] legacy_replicate(n : @core.Nat, value : A) -> @core.Chain[A] {
  match n {
    Zero => Nil
    Succ(rest) => Cons(value, legacy_replicate(rest, value))
  }
}

///|
fn legacy_shift(amount : @core.Nat, value : Binary) -> Binary {
  match value.bits {
    Nil => value
    _ => { bits: @core.append(legacy_replicate(amount, false), value.bits), }
  }
}

///|
fn prefix_karatsuba(
  a : Binary,
  b : Binary,
  shift : (@core.Nat, Binary) -> Binary,
) -> Binary {
  match
    (short_bits(a.bits, karatsuba_cutoff), short_bits(b.bits, karatsuba_cutoff)) {
    (true, _) | (_, true) => multiply(a, b)
    _ => {
      let middle = half_length(
        match compare(a, b) {
          Less => b.bits
          _ => a.bits
        },
      )
      let al = from_bits(@core.take(middle, a.bits))
      let ah = Binary::{ bits: @core.drop(middle, a.bits), }
      let bl = from_bits(@core.take(middle, b.bits))
      let bh = Binary::{ bits: @core.drop(middle, b.bits), }
      let low = prefix_karatsuba(al, bl, shift)
      let high = prefix_karatsuba(ah, bh, shift)
      let joined = prefix_karatsuba(add(al, ah), add(bl, bh), shift)
      match subtract(joined, add(low, high)) {
        None => multiply(a, b)
        Some(cross) =>
          add(
            low,
            add(shift(middle, cross), shift(@core.add(middle, middle), high)),
          )
      }
    }
  }
}

///|
fn fused_shift(amount : @core.Nat, value : Binary) -> Binary {
  match value.bits {
    Nil => value
    _ => { bits: @core.replicate_onto(amount, false, value.bits), }
  }
}

///|
test "constant prefix composition and fused construction" (b : @bench.T) {
  let suffix = @oracle.chain([true, false, true])
  for count in [4, 256, 8192] {
    let n = @oracle.nat(count)
    b.bench(name="replicate then append \{count}", fn() {
      b.keep(@core.append(legacy_replicate(n, false), suffix))
    })
    b.bench(name="replicate onto \{count}", fn() {
      b.keep(@core.replicate_onto(n, false, suffix))
    })
  }
}

///|
test "direct Nat half versus a Binary roundtrip" (b : @bench.T) {
  for value in [64, 4096] {
    let n = @oracle.nat(value)
    b.bench(name="Binary roundtrip half \{value}", fn() {
      b.keep(to_nat(half(from_nat(n))))
    })
    b.bench(name="structural Nat half \{value}", fn() {
      b.keep(@core.half_nat(n))
    })
  }
}

///|
test "fused shift inside the same Karatsuba algorithm" (b : @bench.T) {
  for width in [128, 512, 2048] {
    let a = from_bits(
      @oracle.chain(
        Array::makei(width, fn(i) { i == width - 1 || (i * 17 + 3) % 11 < 6 }),
      ),
    )
    let other = from_bits(
      @oracle.chain(
        Array::makei(width, fn(i) { i == width - 1 || (i * 13 + 7) % 7 < 4 }),
      ),
    )
    b.bench(name="old shift \{width}", fn() {
      b.keep(prefix_karatsuba(a, other, legacy_shift))
    })
    b.bench(name="fused shift \{width}", fn() {
      b.keep(prefix_karatsuba(a, other, fused_shift))
    })
  }
}

///|
test "legacy and fused Karatsuba retain exactly equal products" {
  for width in [31, 64, 65, 128, 257, 512] {
    let a = from_bits(
      @oracle.chain(Array::makei(width, fn(i) { i == width - 1 || i % 7 < 3 })),
    )
    let b = from_bits(
      @oracle.chain(Array::makei(width, fn(i) { i == width - 1 || i % 5 < 3 })),
    )
    assert_eq(
      prefix_karatsuba(a, b, legacy_shift),
      prefix_karatsuba(a, b, fused_shift),
    )
    assert_eq(karatsuba(a, b), multiply(a, b))
  }
}
