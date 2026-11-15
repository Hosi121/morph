///|
/// A previous dictionary phrase followed by one new bit. None is a final
/// dictionary reference for a nonempty suffix already present in the dictionary.
#derive(Eq, Debug)
pub(all) struct Token {
  prefix : @binary.Binary
  literal : Bool?
}

///|
pub extend Token with Eq::{equal, not_equal}

///|
pub extend Token with Debug::{to_repr}

///|
/// LZ78 phrases. Index zero denotes the empty word; all other IDs are Binary.
pub fn compress(word : @core.Chain[Bool]) -> @core.Chain[Token] {
  fn phrases(
    word : @core.Chain[Bool],
    dictionary : @trie.Trie[@binary.Binary],
    next_id : @binary.Binary,
    reversed : @core.Chain[Token],
  ) -> @core.Chain[Token] {
    match word {
      Nil => @core.reverse(reversed)
      Cons(_, _) =>
        match @trie.longest_prefix(dictionary, word) {
          None => @core.reverse(reversed)
          Some((width, prefix)) =>
            match @core.split_exact(width, word) {
              None => @core.reverse(reversed)
              Some((_, Nil)) =>
                @core.reverse(Cons({ prefix, literal: None, }, reversed))
              Some((phrase, Cons(bit, rest))) => {
                let phrase = @core.append(phrase, Cons(bit, Nil))
                phrases(
                  rest,
                  @trie.put(dictionary, phrase, next_id),
                  @binary.successor(next_id),
                  Cons({ prefix, literal: Some(bit), }, reversed),
                )
              }
            }
        }
    }
  }
  let dictionary = @trie.put(@trie.empty(), Nil, @binary.zero())
  phrases(word, dictionary, @binary.one(), Nil)
}

///|
/// Reject forward/unknown references, an empty terminal reference and a terminal
/// reference before the end. Alternate valid tokenizations need not be canonical.
pub fn decompress(tokens : @core.Chain[Token]) -> @core.Chain[Bool]? {
  fn expand(
    tokens : @core.Chain[Token],
    dictionary : @trie.Trie[@core.Chain[Bool]],
    next_id : @binary.Binary,
    reversed : @core.Chain[Bool],
  ) -> @core.Chain[Bool]? {
    match tokens {
      Nil => Some(@core.reverse(reversed))
      Cons(token, rest) =>
        match @trie.lookup(dictionary, @binary.bits(token.prefix)) {
          None => None
          Some(prefix) =>
            match (token.literal, rest) {
              (None, Nil) =>
                match @binary.is_zero(token.prefix) {
                  true => None
                  false =>
                    Some(@core.reverse(@core.reverse_onto(prefix, reversed)))
                }
              (None, Cons(_, _)) => None
              (Some(bit), _) => {
                let phrase = @core.append(prefix, Cons(bit, Nil))
                expand(
                  rest,
                  @trie.put(dictionary, @binary.bits(next_id), phrase),
                  @binary.successor(next_id),
                  @core.reverse_onto(phrase, reversed),
                )
              }
            }
        }
    }
  }
  expand(tokens, @trie.put(@trie.empty(), Nil, Nil), @binary.one(), Nil)
}

///|
/// Wire format: gamma(prefix+one), then false for a final reference, or true+bit.
/// The positive gamma field is self-delimiting; token boundaries need no integers.
pub fn pack(tokens : @core.Chain[Token]) -> @core.Chain[Bool] {
  fn encode(
    tokens : @core.Chain[Token],
    reversed : @core.Chain[Bool],
  ) -> @core.Chain[Bool] {
    match tokens {
      Nil => @core.reverse(reversed)
      Cons(token, rest) =>
        match @bitcodec.gamma_encode(@binary.successor(token.prefix)) {
          None => @core.reverse(reversed)
          Some(prefix) => {
            let reversed = @core.reverse_onto(prefix, reversed)
            let reversed : @core.Chain[Bool] = match token.literal {
              None => Cons(false, reversed)
              Some(bit) => Cons(bit, Cons(true, reversed))
            }
            encode(rest, reversed)
          }
        }
    }
  }
  encode(tokens, Nil)
}

///|
pub fn unpack(bits : @core.Chain[Bool]) -> @core.Chain[Token]? {
  fn read(
    bits : @core.Chain[Bool],
    reversed : @core.Chain[Token],
  ) -> @core.Chain[Token]? {
    match bits {
      Nil => Some(@core.reverse(reversed))
      Cons(_, _) =>
        match @bitcodec.gamma_read(bits) {
          None => None
          Some((number, tail)) =>
            match (@binary.subtract(number, @binary.one()), tail) {
              (Some(prefix), Cons(false, Nil)) =>
                Some(@core.reverse(Cons({ prefix, literal: None, }, reversed)))
              (Some(prefix), Cons(true, Cons(bit, rest))) =>
                read(rest, Cons({ prefix, literal: Some(bit), }, reversed))
              _ => None
            }
        }
    }
  }
  read(bits, Nil)
}

///|
pub fn encode(word : @core.Chain[Bool]) -> @core.Chain[Bool] {
  pack(compress(word))
}

///|
pub fn decode(bits : @core.Chain[Bool]) -> @core.Chain[Bool]? {
  match unpack(bits) {
    None => None
    Some(tokens) => decompress(tokens)
  }
}
