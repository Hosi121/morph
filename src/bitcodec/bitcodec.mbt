///|
/// Elias gamma code: unary zero prefix for bit-width minus one, then big-endian bits.
fn encode_positive(bits : @core.Chain[Bool]) -> @core.Chain[Bool] {
  match bits {
    Nil => Nil
    Cons(_, rest) =>
      @core.append(
        @core.replicate(@core.length(rest), false),
        @core.reverse(bits),
      )
  }
}

///|
/// Positive numbers only. Zero is deliberately not assigned an empty codeword.
pub fn gamma_encode(n : @binary.Binary) -> @core.Chain[Bool]? {
  match @binary.is_zero(n) {
    true => None
    false => Some(encode_positive(@binary.bits(n)))
  }
}

///|
/// Decode exactly one prefix-free codeword, returning the unconsumed suffix.
pub fn gamma_read(
  stream : @core.Chain[Bool],
) -> (@binary.Binary, @core.Chain[Bool])? {
  fn prefix(
    stream : @core.Chain[Bool],
    width : @core.Nat,
  ) -> (@binary.Binary, @core.Chain[Bool])? {
    match stream {
      Nil => None
      Cons(false, rest) => prefix(rest, Succ(width))
      Cons(true, rest) =>
        match @core.split_exact(width, rest) {
          None => None
          Some((payload, tail)) =>
            Some((@binary.from_bits(@core.reverse(Cons(true, payload))), tail))
        }
    }
  }
  prefix(stream, Zero)
}

///|
/// A compact pair of arbitrary binary naturals, including zero. No coordinate
/// is expanded to a unary value: only its bit-width gets a unary prefix.
pub fn pair_word(a : @binary.Binary, b : @binary.Binary) -> @core.Chain[Bool] {
  @core.append(
    encode_positive(@binary.bits(@binary.successor(a))),
    encode_positive(@binary.bits(@binary.successor(b))),
  )
}

///|
pub fn read_pair(
  stream : @core.Chain[Bool],
) -> ((@binary.Binary, @binary.Binary), @core.Chain[Bool])? {
  match gamma_read(stream) {
    None => None
    Some((a, rest)) =>
      match gamma_read(rest) {
        None => None
        Some((b, rest)) =>
          match
            (
              @binary.subtract(a, @binary.one()),
              @binary.subtract(b, @binary.one()),
            ) {
            (Some(a), Some(b)) => Some(((a, b), rest))
            _ => None
          }
      }
  }
}

///|
/// Require the whole input to contain exactly one pair.
pub fn decode_pair(
  word : @core.Chain[Bool],
) -> (@binary.Binary, @binary.Binary)? {
  match read_pair(word) {
    Some((pair, Nil)) => Some(pair)
    _ => None
  }
}
