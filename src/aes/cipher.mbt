///|
#derive(Eq, Debug)
pub(all) enum KeySize {
  Aes128
  Aes192
  Aes256
}

///|
pub extend KeySize with Eq::{equal, not_equal}

///|
pub extend KeySize with Debug::{to_repr}

///|
/// Immutable expanded keys and shared generated substitution tries.
#derive(Eq, Debug)
pub struct Cipher {
  tables : Tables
  size : KeySize
  round_keys : @core.Chain[Block]
}

///|
pub extend Cipher with Eq::{equal, not_equal}

///|
pub extend Cipher with Debug::{to_repr}

///|
pub fn key_size(cipher : Cipher) -> KeySize {
  cipher.size
}

///|
pub fn round_keys(cipher : Cipher) -> @core.Chain[Block] {
  cipher.round_keys
}

///|
pub fn rounds(cipher : Cipher) -> @core.Nat {
  @core.subtract(@core.length(cipher.round_keys), Succ(Zero))
}

///|
fn block_width() -> @core.Nat {
  @core.length(four({ a: (), b: (), c: (), d: (), }))
}

///|
fn key_words(values : @core.Chain[Octet]) -> @core.Chain[Word]? {
  match values {
    Nil => Some(Nil)
    _ =>
      match take_four(values) {
        None => None
        Some((word, rest)) =>
          match key_words(rest) {
            None => None
            Some(tail) => Some(Cons(word, tail))
          }
      }
  }
}

///|
fn classify(words : @core.Chain[Word]) -> KeySize? {
  match words {
    Cons(_, Cons(_, Cons(_, Cons(_, rest)))) =>
      match rest {
        Nil => Some(Aes128)
        Cons(_, Cons(_, Nil)) => Some(Aes192)
        Cons(_, Cons(_, Cons(_, Cons(_, Nil)))) => Some(Aes256)
        _ => None
      }
    _ => None
  }
}

///|
fn rot_word(word : Word) -> Word {
  { a: word.b, b: word.c, c: word.d, d: word.a, }
}

///|
fn sub_word(tables : Tables, word : Word) -> Result[Word, AesError] {
  checked_map_four(word, fn(value) { sbox(tables, value) })
}

///|
fn expand_words(
  tables : Tables,
  size : KeySize,
  queue : @core.Chain[Word],
  previous : Word,
  position : @core.Nat,
  rcon : Octet,
  remaining : @core.Nat,
  reversed : @core.Chain[Word],
) -> Result[@core.Chain[Word], AesError] {
  match remaining {
    Zero => Ok(@core.reverse(reversed))
    Succ(rest) => {
      let special = match position {
        Zero =>
          match sub_word(tables, rot_word(previous)) {
            Err(error) => Err(error)
            Ok(word) =>
              Ok(
                (
                  xor_word(word, { a: rcon, b: zero(), c: zero(), d: zero(), }),
                  xtime(rcon),
                ),
              )
          }
        _ =>
          match
            size is Aes256 && @core.compare(position, block_width()) is Equal {
            false => Ok((previous, rcon))
            true =>
              match sub_word(tables, previous) {
                Err(error) => Err(error)
                Ok(word) => Ok((word, rcon))
              }
          }
      }
      match (special, queue) {
        (Err(error), _) => Err(error)
        (_, Nil) => Err(InternalInvariant)
        (Ok((temporary, rcon)), Cons(old, tail)) => {
          let word = xor_word(old, temporary)
          let next_position : @core.Nat = match
            @core.compare(Succ(position), @core.length(queue)) {
            Equal => Zero
            _ => Succ(position)
          }
          expand_words(
            tables,
            size,
            @core.append(tail, Cons(word, Nil)),
            word,
            next_position,
            rcon,
            rest,
            Cons(word, reversed),
          )
        }
      }
    }
  }
}

///|
fn group_keys(
  words : @core.Chain[Word],
) -> Result[@core.Chain[Block], AesError] {
  match words {
    Nil => Ok(Nil)
    _ =>
      match take_four(words) {
        None => Err(InternalInvariant)
        Some((columns, rest)) =>
          match group_keys(rest) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons({ columns, }, tail))
          }
      }
  }
}

///|
/// Expand exactly sixteen, twenty-four or thirty-two input octets.
pub fn cipher(
  tables : Tables,
  key : @core.Chain[Octet],
) -> Result[Cipher, AesError] {
  match key_words(key) {
    None => Err(InvalidKeyLength)
    Some(words) =>
      match (classify(words), @core.last(words)) {
        (Some(size), Some(previous)) => {
          let nk = @core.length(words)
          let two : @core.Nat = Succ(Succ(Zero))
          let six = @core.add(block_width(), two)
          let nr = @core.add(nk, six)
          let total = @core.multiply(block_width(), Succ(nr))
          match
            expand_words(
              tables,
              size,
              words,
              previous,
              Zero,
              one(),
              @core.subtract(total, nk),
              @core.reverse(words),
            ) {
            Err(error) => Err(error)
            Ok(expanded) =>
              match group_keys(expanded) {
                Err(error) => Err(error)
                Ok(round_keys) => Ok({ tables, size, round_keys, })
              }
          }
        }
        _ => Err(InvalidKeyLength)
      }
  }
}

///|
fn encrypt_rounds(
  tables : Tables,
  state : Block,
  keys : @core.Chain[Block],
) -> Result[Block, AesError] {
  match keys {
    Nil => Err(InternalInvariant)
    Cons(key, rest) =>
      match sub_bytes(tables, state) {
        Err(error) => Err(error)
        Ok(substituted) => {
          let shifted = shift_rows(substituted)
          match rest {
            Nil => Ok(add_round_key(shifted, key))
            _ =>
              encrypt_rounds(
                tables,
                add_round_key(mix_columns(shifted), key),
                rest,
              )
          }
        }
      }
  }
}

///|
pub fn encrypt(cipher : Cipher, input : Block) -> Result[Block, AesError] {
  match cipher.round_keys {
    Nil => Err(InternalInvariant)
    Cons(initial, rest) =>
      encrypt_rounds(cipher.tables, add_round_key(input, initial), rest)
  }
}

///|
fn decrypt_rounds(
  tables : Tables,
  state : Block,
  keys : @core.Chain[Block],
) -> Result[Block, AesError] {
  match keys {
    Nil => Err(InternalInvariant)
    Cons(key, rest) =>
      match inverse_sub_bytes(tables, inverse_shift_rows(state)) {
        Err(error) => Err(error)
        Ok(substituted) => {
          let added = add_round_key(substituted, key)
          match rest {
            Nil => Ok(added)
            _ => decrypt_rounds(tables, inverse_mix_columns(added), rest)
          }
        }
      }
  }
}

///|
pub fn decrypt(cipher : Cipher, input : Block) -> Result[Block, AesError] {
  match @core.reverse(cipher.round_keys) {
    Nil => Err(InternalInvariant)
    Cons(initial, rest) =>
      decrypt_rounds(cipher.tables, add_round_key(input, initial), rest)
  }
}
