///|
#derive(Eq, Debug)
pub(all) struct Four[A] {
  a : A
  b : A
  c : A
  d : A
}

///|
pub extend Four with Eq::{equal, not_equal}

///|
pub extend Four with Debug::{to_repr}

///|
pub type Word = Four[Octet]

///|
/// FIPS column-major state: each word contains rows zero through three.
#derive(Eq, Debug)
pub struct Block {
  columns : Four[Word]
}

///|
pub extend Block with Eq::{equal, not_equal}

///|
pub extend Block with Debug::{to_repr}

///|
fn[A] four(values : Four[A]) -> @core.Chain[A] {
  Cons(values.a, Cons(values.b, Cons(values.c, Cons(values.d, Nil))))
}

///|
fn[A] take_four(values : @core.Chain[A]) -> (Four[A], @core.Chain[A])? {
  match values {
    Cons(a, Cons(b, Cons(c, Cons(d, rest)))) => Some(({ a, b, c, d, }, rest))
    _ => None
  }
}

///|
pub fn block(values : @core.Chain[Octet]) -> Block? {
  match take_four(values) {
    None => None
    Some((a, rest)) =>
      match take_four(rest) {
        None => None
        Some((b, rest)) =>
          match take_four(rest) {
            None => None
            Some((c, rest)) =>
              match take_four(rest) {
                Some((d, Nil)) => Some({ columns: { a, b, c, d, }, })
                _ => None
              }
          }
      }
  }
}

///|
pub fn octets(value : Block) -> @core.Chain[Octet] {
  @core.append(
    four(value.columns.a),
    @core.append(
      four(value.columns.b),
      @core.append(four(value.columns.c), four(value.columns.d)),
    ),
  )
}

///|
fn[A, B] map_four(value : Four[A], f : (A) -> B) -> Four[B] {
  { a: f(value.a), b: f(value.b), c: f(value.c), d: f(value.d), }
}

///|
fn xor_word(a : Word, b : Word) -> Word {
  { a: xor(a.a, b.a), b: xor(a.b, b.b), c: xor(a.c, b.c), d: xor(a.d, b.d), }
}

///|
pub fn add_round_key(state : Block, key : Block) -> Block {
  {
    columns: {
      a: xor_word(state.columns.a, key.columns.a),
      b: xor_word(state.columns.b, key.columns.b),
      c: xor_word(state.columns.c, key.columns.c),
      d: xor_word(state.columns.d, key.columns.d),
    },
  }
}

///|
pub fn shift_rows(state : Block) -> Block {
  let { a, b, c, d, } = state.columns
  {
    columns: {
      a: { a: a.a, b: b.b, c: c.c, d: d.d, },
      b: { a: b.a, b: c.b, c: d.c, d: a.d, },
      c: { a: c.a, b: d.b, c: a.c, d: b.d, },
      d: { a: d.a, b: a.b, c: b.c, d: c.d, },
    },
  }
}

///|
pub fn inverse_shift_rows(state : Block) -> Block {
  shift_rows(shift_rows(shift_rows(state)))
}

///|
fn xor_four(a : Octet, b : Octet, c : Octet, d : Octet) -> Octet {
  xor(xor(a, b), xor(c, d))
}

///|
fn mix_word(word : Word) -> Word {
  let aa = xtime(word.a)
  let bb = xtime(word.b)
  let cc = xtime(word.c)
  let dd = xtime(word.d)
  {
    a: xor_four(aa, xor(bb, word.b), word.c, word.d),
    b: xor_four(word.a, bb, xor(cc, word.c), word.d),
    c: xor_four(word.a, word.b, cc, xor(dd, word.d)),
    d: xor_four(xor(aa, word.a), word.b, word.c, dd),
  }
}

///|
pub fn mix_columns(state : Block) -> Block {
  { columns: map_four(state.columns, mix_word), }
}

///|
fn inverse_mix_word(word : Word) -> Word {
  // Precondition with x^2*(a+c) and x^2*(b+d), then the forward matrix.
  let ac = xtime(xtime(xor(word.a, word.c)))
  let bd = xtime(xtime(xor(word.b, word.d)))
  mix_word({
    a: xor(word.a, ac),
    b: xor(word.b, bd),
    c: xor(word.c, ac),
    d: xor(word.d, bd),
  })
}

///|
pub fn inverse_mix_columns(state : Block) -> Block {
  { columns: map_four(state.columns, inverse_mix_word), }
}
