///|
/// Fixed-width big-endian bit word; constructors stay inside this package.
priv struct Word {
  bits : @core.Chain[Bool]
}

///|
priv enum Nibble {
  N(Bool, Bool, Bool, Bool)
}

///|
/// Pure immutable unary constants, shared across all rounds.
let n_one : @core.Nat = Succ(Zero)

///|
let n_two : @core.Nat = @core.Succ(n_one)

///|
let n_three : @core.Nat = @core.Succ(n_two)

///|
let n_six : @core.Nat = @core.add(n_three, n_three)

///|
let n_seven : @core.Nat = @core.Succ(n_six)

///|
let n_eight : @core.Nat = @core.Succ(n_seven)

///|
let n_ten : @core.Nat = @core.add(n_eight, n_two)

///|
let n_eleven : @core.Nat = @core.Succ(n_ten)

///|
let n_thirteen : @core.Nat = @core.add(n_eleven, n_two)

///|
let n_fourteen : @core.Nat = @core.Succ(n_thirteen)

///|
let n_fifteen : @core.Nat = @core.Succ(n_fourteen)

///|
let n_sixteen : @core.Nat = @core.Succ(n_fifteen)

///|
let n_seventeen : @core.Nat = @core.Succ(n_sixteen)

///|
let n_eighteen : @core.Nat = @core.Succ(n_seventeen)

///|
let n_nineteen : @core.Nat = @core.Succ(n_eighteen)

///|
let n_twentytwo : @core.Nat = @core.add(n_nineteen, n_three)

///|
let n_twentyfive : @core.Nat = @core.add(n_twentytwo, n_three)

///|
let n_thirtytwo : @core.Nat = @core.add(n_sixteen, n_sixteen)

///|
let n_sixtyfour : @core.Nat = @core.add(n_thirtytwo, n_thirtytwo)

///|
let n_fivehundredtwelve : @core.Nat = @core.multiply(n_sixtyfour, n_eight)

///|
fn nibble_bits(nibble : Nibble) -> @core.Chain[Bool] {
  let N(a, b, c, d) = nibble
  Cons(a, Cons(b, Cons(c, Cons(d, Nil))))
}

///|
fn word(
  a : Nibble,
  b : Nibble,
  c : Nibble,
  d : Nibble,
  e : Nibble,
  f : Nibble,
  g : Nibble,
  h : Nibble,
) -> Word {
  {
    bits: @core.append(
      nibble_bits(a),
      @core.append(
        nibble_bits(b),
        @core.append(
          nibble_bits(c),
          @core.append(
            nibble_bits(d),
            @core.append(
              nibble_bits(e),
              @core.append(
                nibble_bits(f),
                @core.append(nibble_bits(g), nibble_bits(h)),
              ),
            ),
          ),
        ),
      ),
    ),
  }
}

///|
fn words_eight(
  a : Word,
  b : Word,
  c : Word,
  d : Word,
  e : Word,
  f : Word,
  g : Word,
  h : Word,
) -> @core.Chain[Word] {
  Cons(a, Cons(b, Cons(c, Cons(d, Cons(e, Cons(f, Cons(g, Cons(h, Nil))))))))
}

///|
fn bit_xor(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, false) | (false, true) => true
    _ => false
  }
}

///|
fn map_three(
  a : Word,
  b : Word,
  c : Word,
  f : (Bool, Bool, Bool) -> Bool,
) -> Word {
  fn go(
    a : @core.Chain[Bool],
    b : @core.Chain[Bool],
    c : @core.Chain[Bool],
  ) -> @core.Chain[Bool] {
    match (a, b, c) {
      (Cons(x, xt), Cons(y, yt), Cons(z, zt)) =>
        Cons(f(x, y, z), go(xt, yt, zt))
      _ => Nil
    }
  }
  { bits: go(a.bits, b.bits, c.bits), }
}

///|
fn xor_three(a : Word, b : Word, c : Word) -> Word {
  map_three(a, b, c, fn(x, y, z) { bit_xor(bit_xor(x, y), z) })
}

///|
fn choose(a : Word, b : Word, c : Word) -> Word {
  map_three(a, b, c, fn(x, y, z) {
    match x {
      true => y
      false => z
    }
  })
}

///|
fn majority(a : Word, b : Word, c : Word) -> Word {
  map_three(a, b, c, fn(x, y, z) {
    match (x, y, z) {
      (true, true, _) | (true, _, true) | (_, true, true) => true
      _ => false
    }
  })
}

///|
/// Full-adder recursion discards the final carry, implementing fixed-width wrap.
fn word_add(a : Word, b : Word) -> Word {
  fn go(
    xs : @core.Chain[Bool],
    ys : @core.Chain[Bool],
    carry : Bool,
  ) -> @core.Chain[Bool] {
    match (xs, ys) {
      (Cons(x, xt), Cons(y, yt)) => {
        let (sum, next) = @binary.full_adder(x, y, carry)
        Cons(sum, go(xt, yt, next))
      }
      _ => Nil
    }
  }
  {
    bits: @core.reverse(go(@core.reverse(a.bits), @core.reverse(b.bits), false)),
  }
}

///|
fn rotate_right(w : Word, n : @core.Nat) -> Word {
  let prefix = @core.subtract(n_thirtytwo, n)
  {
    bits: @core.append(@core.drop(prefix, w.bits), @core.take(prefix, w.bits)),
  }
}

///|
fn shift_right(w : Word, n : @core.Nat) -> Word {
  {
    bits: @core.append(
      @core.replicate(n, false),
      @core.take(@core.subtract(n_thirtytwo, n), w.bits),
    ),
  }
}

///|
fn small_sigma_first(w : Word) -> Word {
  xor_three(
    rotate_right(w, n_seven),
    rotate_right(w, n_eighteen),
    shift_right(w, n_three),
  )
}

///|
fn small_sigma_second(w : Word) -> Word {
  xor_three(
    rotate_right(w, n_seventeen),
    rotate_right(w, n_nineteen),
    shift_right(w, n_ten),
  )
}

///|
fn big_sigma_first(w : Word) -> Word {
  xor_three(
    rotate_right(w, n_two),
    rotate_right(w, n_thirteen),
    rotate_right(w, n_twentytwo),
  )
}

///|
fn big_sigma_second(w : Word) -> Word {
  xor_three(
    rotate_right(w, n_six),
    rotate_right(w, n_eleven),
    rotate_right(w, n_twentyfive),
  )
}
