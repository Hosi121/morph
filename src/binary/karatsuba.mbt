///|
/// A structural cutoff, kept separate from the multiplication identity.
let karatsuba_cutoff : @core.Nat = @core.multiply(
  Succ(Succ(Succ(Succ(Succ(Succ(Succ(Succ(Zero)))))))),
  Succ(Succ(Succ(Succ(Succ(Succ(Succ(Succ(Zero)))))))),
)

///|
fn short_bits(bits : @core.Chain[Bool], fuel : @core.Nat) -> Bool {
  match (bits, fuel) {
    (Nil, _) => true
    (_, Zero) => false
    (Cons(_, rest), Succ(fuel)) => short_bits(rest, fuel)
  }
}

///|
fn half_length(bits : @core.Chain[Bool]) -> @core.Nat {
  match bits {
    Cons(_, Cons(_, rest)) => Succ(half_length(rest))
    _ => Zero
  }
}

///|
fn shift_by(n : @core.Nat, value : Binary) -> Binary {
  match value.bits {
    Nil => value
    _ => { bits: @core.append(@core.replicate(n, false), value.bits), }
  }
}

///|
/// Three half-size multiplications replace four. Small/unbalanced operands
/// use school multiplication. Both paths are exact and preserve canonical bits.
pub fn karatsuba(a : Binary, b : Binary) -> Binary {
  match
    (short_bits(a.bits, karatsuba_cutoff), short_bits(b.bits, karatsuba_cutoff)) {
    (true, _) | (_, true) => multiply(a, b)
    (false, false) => {
      let largest = match compare(a, b) {
        Less => b.bits
        _ => a.bits
      }
      let middle = half_length(largest)
      let al = from_bits(@core.take(middle, a.bits))
      let ah : Binary = { bits: @core.drop(middle, a.bits), }
      let bl = from_bits(@core.take(middle, b.bits))
      let bh : Binary = { bits: @core.drop(middle, b.bits), }
      let low = karatsuba(al, bl)
      let high = karatsuba(ah, bh)
      let joined = karatsuba(add(al, ah), add(bl, bh))
      // joined = low + high + both cross-products, so subtraction is exact.
      match subtract(joined, add(low, high)) {
        Some(cross) =>
          add(
            low,
            add(
              shift_by(middle, cross),
              shift_by(@core.add(middle, middle), high),
            ),
          )
        // A correctness-preserving fallback if the invariant is ever violated.
        None => multiply(a, b)
      }
    }
  }
}
