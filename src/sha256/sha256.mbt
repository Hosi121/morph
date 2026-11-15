///|
priv struct State {
  a : Word
  b : Word
  c : Word
  d : Word
  e : Word
  f : Word
  g : Word
  h : Word
}

///|
/// Split by consuming constructors, with an explicit short-input result.
fn[A] split_exact(
  n : @core.Nat,
  xs : @core.Chain[A],
) -> (@core.Chain[A], @core.Chain[A])? {
  match (n, xs) {
    (Zero, _) => Some((Nil, xs))
    (Succ(_), Nil) => None
    (Succ(rest), Cons(x, xt)) =>
      match split_exact(rest, xt) {
        None => None
        Some((prefix, suffix)) => Some((Cons(x, prefix), suffix))
      }
  }
}

///|
fn pad(message : @core.Chain[Bool]) -> @core.Chain[Bool]? {
  let length = @core.fold_left(message, @binary.zero(), fn(length, _) {
    @binary.successor(length)
  })
  let width = @core.length(@binary.bits(length))
  match @core.compare(width, n_sixtyfour) {
    Greater => None
    _ => {
      let block = @binary.from_nat(n_fivehundredtwelve)
      let target = @binary.from_nat(
        @core.subtract(n_fivehundredtwelve, n_sixtyfour),
      )
      match @binary.divmod(@binary.successor(length), block) {
        None => None
        Some((_, remainder)) =>
          match @binary.subtract(@binary.add(target, block), remainder) {
            None => None
            Some(distance) =>
              match @binary.divmod(distance, block) {
                None => None
                Some((_, zeros)) => {
                  let encoded_length = @core.reverse(
                    @core.append(
                      @binary.bits(length),
                      @core.replicate(@core.subtract(n_sixtyfour, width), false),
                    ),
                  )
                  Some(
                    @core.append(
                      message,
                      Cons(
                        true,
                        @core.append(
                          @core.replicate(@binary.to_nat(zeros), false),
                          encoded_length,
                        ),
                      ),
                    ),
                  )
                }
              }
          }
      }
    }
  }
}

///|
fn block_words(bits : @core.Chain[Bool]) -> @core.Chain[Word]? {
  fn go(todo : @core.Nat, bits : @core.Chain[Bool]) -> @core.Chain[Word]? {
    match (todo, bits) {
      (Zero, Nil) => Some(Nil)
      (Zero, _) => None
      (Succ(rest), _) =>
        match split_exact(n_thirtytwo, bits) {
          None => None
          Some((bits, tail)) =>
            match go(rest, tail) {
              None => None
              Some(words) => Some(Cons(Word::{ bits, }, words))
            }
        }
    }
  }
  go(n_sixteen, bits)
}

///|
/// Keep the schedule backwards, so all four dependencies are nearby list cursors.
fn schedule(initial : @core.Chain[Word]) -> @core.Chain[Word]? {
  fn grow_history(
    todo : @core.Chain[Word],
    history : @core.Chain[Word],
  ) -> @core.Chain[Word]? {
    match todo {
      Nil => Some(@core.reverse(history))
      Cons(_, rest) =>
        match
          (
            @core.nth(history, n_one),
            @core.nth(history, n_six),
            @core.nth(history, n_fourteen),
            @core.nth(history, n_fifteen),
          ) {
          (Some(recent), Some(seven_back), Some(older), Some(sixteen_back)) => {
            let next = word_add(
              word_add(small_sigma_second(recent), seven_back),
              word_add(small_sigma_first(older), sixteen_back),
            )
            grow_history(rest, Cons(next, history))
          }
          _ => None
        }
    }
  }
  grow_history(@core.drop(n_sixteen, round_constants), @core.reverse(initial))
}

///|
fn round(state : State, w : Word, k : Word) -> State {
  let first = word_add(
    word_add(
      word_add(state.h, big_sigma_second(state.e)),
      choose(state.e, state.f, state.g),
    ),
    word_add(k, w),
  )
  let second = word_add(
    big_sigma_first(state.a),
    majority(state.a, state.b, state.c),
  )
  {
    a: word_add(first, second),
    b: state.a,
    c: state.b,
    d: state.c,
    e: word_add(state.d, first),
    f: state.e,
    g: state.f,
    h: state.g,
  }
}

///|
fn rounds(
  state : State,
  words : @core.Chain[Word],
  constants : @core.Chain[Word],
) -> State? {
  match (words, constants) {
    (Nil, Nil) => Some(state)
    (Cons(w, wt), Cons(k, kt)) => rounds(round(state, w, k), wt, kt)
    _ => None
  }
}

///|
fn feed_forward(old : State, current : State) -> State {
  {
    a: word_add(old.a, current.a),
    b: word_add(old.b, current.b),
    c: word_add(old.c, current.c),
    d: word_add(old.d, current.d),
    e: word_add(old.e, current.e),
    f: word_add(old.f, current.f),
    g: word_add(old.g, current.g),
    h: word_add(old.h, current.h),
  }
}

///|
/// SHA-256 on a big-endian list of message bits. None rejects a length that
/// needs more than the standard length field (or an internal shape failure).
/// No machine words, numeric literals, bitwise builtins, arrays or mutation.
pub fn hash(message : @core.Chain[Bool]) -> @core.Chain[Bool]? {
  fn blocks(state : State, bits : @core.Chain[Bool]) -> State? {
    match bits {
      Nil => Some(state)
      _ =>
        match split_exact(n_fivehundredtwelve, bits) {
          None => None
          Some((block, rest)) =>
            match block_words(block) {
              None => None
              Some(initial) =>
                match schedule(initial) {
                  None => None
                  Some(words) =>
                    match rounds(state, words, round_constants) {
                      None => None
                      Some(current) =>
                        blocks(feed_forward(state, current), rest)
                    }
                }
            }
        }
    }
  }
  match pad(message) {
    None => None
    Some(padded) =>
      match blocks(initial_state(), padded) {
        None => None
        Some(s) =>
          Some(
            @core.append(
              s.a.bits,
              @core.append(
                s.b.bits,
                @core.append(
                  s.c.bits,
                  @core.append(
                    s.d.bits,
                    @core.append(
                      s.e.bits,
                      @core.append(s.f.bits, @core.append(s.g.bits, s.h.bits)),
                    ),
                  ),
                ),
              ),
            ),
          )
      }
  }
}
