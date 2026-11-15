///|
/// Test adapters deliberately use machine integers and arrays.
pub fn nat(n : Int32) -> @core.Nat {
  if n < 0 {
    abort("negative test natural")
  }
  for remaining = n, found = @core.Zero; remaining > 0; {
    continue remaining - 1, @core.Succ(found)
  } nobreak {
    found
  }
}

///|
pub fn int_of_nat(n : @core.Nat) -> Int32 {
  for remaining = n, found = 0 {
    match remaining {
      Zero => break found
      Succ(rest) => continue rest, found + 1
    }
  }
}

///|
pub fn binary(n : Int32) -> @binary.Binary {
  if n < 0 {
    abort("negative test binary")
  }
  fn go(n : Int32) -> @core.Chain[Bool] {
    if n == 0 {
      Nil
    } else {
      Cons(n % 2 == 1, go(n / 2))
    }
  }
  @binary.from_bits(go(n))
}

///|
pub fn int_of_binary(n : @binary.Binary) -> Int32 {
  fn go(xs : @core.Chain[Bool]) -> Int32 {
    match xs {
      Nil => 0
      Cons(b, rest) => (if b { 1 } else { 0 }) + 2 * go(rest)
    }
  }
  go(@binary.bits(n))
}

///|
pub fn integer(n : Int32) -> @exact.Integer {
  if n < 0 {
    @exact.negate(@exact.positive(binary(-n)))
  } else {
    @exact.positive(binary(n))
  }
}

///|
pub fn int_of_integer(n : @exact.Integer) -> Int32 {
  let abs = int_of_binary(@exact.magnitude(n))
  if @exact.negative(n) {
    -abs
  } else {
    abs
  }
}

///|
pub fn rational(n : Int32, d : Int32) -> @exact.Rational {
  match @exact.ratio(integer(n), binary(d)) {
    Some(value) => value
    None => abort("zero test denominator")
  }
}

///|
pub fn[A] chain(xs : Array[A]) -> @core.Chain[A] {
  for i = xs.length() - 1, result = @core.Nil; i >= 0; {
    continue i - 1, @core.Cons(xs[i], result)
  } nobreak {
    result
  }
}

///|
pub fn[A] array(xs : @core.Chain[A]) -> Array[A] {
  let result = []
  fn visit(xs : @core.Chain[A]) -> Unit {
    match xs {
      Nil => ()
      Cons(x, rest) => {
        result.push(x)
        visit(rest)
      }
    }
  }
  visit(xs)
  result
}

///|
/// Arbitrary-size numeric oracle fixtures, without truncating through Int32.
pub fn binary_from_hex(text : String) -> @binary.Binary {
  let bits = []
  for character in text {
    let digit = match character {
      '0' => 0
      '1' => 1
      '2' => 2
      '3' => 3
      '4' => 4
      '5' => 5
      '6' => 6
      '7' => 7
      '8' => 8
      '9' => 9
      'a' | 'A' => 10
      'b' | 'B' => 11
      'c' | 'C' => 12
      'd' | 'D' => 13
      'e' | 'E' => 14
      'f' | 'F' => 15
      _ => abort("bad oracle hex")
    }
    for bit in 0..<4 {
      bits.push((digit & (1 << (3 - bit))) != 0)
    }
  }
  @binary.from_bits(@core.reverse(chain(bits)))
}

///|
pub fn bits_from_bytes(data : Bytes) -> @core.Chain[Bool] {
  let bits = []
  for byte in data {
    for bit in 0..<8 {
      bits.push((byte.to_int() & (1 << (7 - bit))) != 0)
    }
  }
  chain(bits)
}

///|
pub fn hex_bits(bits : @core.Chain[Bool]) -> String {
  let data = array(bits)
  let alphabet = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  let result = StringBuilder()
  for i in 0..<(data.length() / 4) {
    let mut digit = 0
    for j in 0..<4 {
      digit = digit * 2 + (if data[i * 4 + j] { 1 } else { 0 })
    }
    result.write_char(alphabet[digit])
  }
  result.to_string()
}
