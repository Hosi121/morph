///|
/// An arrow's list length is its formal phase; no numeric angle is stored.
pub type Arrow = @core.Chain[Unit]

///|
/// A formal sum of unit arrows. Nil is the additive zero.
pub type Number = @core.Chain[Arrow]

///|
/// A signal is a list of formal sums.
pub type Signal = @core.Chain[Number]

///|
/// Equation 1/2: addition is list concatenation.
pub fn add(a : Number, b : Number) -> Number {
  @core.append(a, b)
}

///|
/// Equation 3/4: rotate each arrow by z, then append the accumulator.
pub fn rotate_add(z : Arrow, arrows : Number, tail : Number) -> Number {
  match arrows {
    Nil => tail
    Cons(r, rest) => Cons(@core.append(z, r), rotate_add(z, rest, tail))
  }
}

///|
/// Equation 5, polymorphic because it also doubles steps and subtransforms.
fn[A] doubled(xs : @core.Chain[A]) -> @core.Chain[A] {
  @core.append(xs, xs)
}

///|
/// Equation 6/7.
fn[A] evens(xs : @core.Chain[A]) -> @core.Chain[A] {
  match xs {
    Cons(x, Cons(_, rest)) => Cons(x, evens(rest))
    _ => xs
  }
}

///|
/// Equation 8/9. The checked entry point guarantees equal list lengths.
fn mix(w : Arrow, z : Arrow, es : Signal, os : Signal) -> Signal {
  match (es, os) {
    (Cons(e, et), Cons(o, ot)) =>
      Cons(rotate_add(z, o, e), mix(w, @core.append(w, z), et, ot))
    _ => Nil
  }
}

///|
/// Equation 10: repeat the half transform instead of using subtraction.
fn sub(w : Arrow, xs : Signal) -> Signal {
  doubled(fft_raw(doubled(w), evens(xs)))
}

///|
/// Equation 11/12, with an unreachable empty case to make MoonBit total.
fn fft_raw(w : Arrow, xs : Signal) -> Signal {
  match xs {
    Nil | Cons(_, Nil) => xs
    Cons(_, rest) => mix(w, Nil, sub(w, xs), sub(w, rest))
  }
}

///|
/// Halve a list only when its length is even.
fn[A] halve_shape(xs : @core.Chain[A]) -> @core.Chain[Unit]? {
  match xs {
    Nil => Some(Nil)
    Cons(_, Nil) => None
    Cons(_, Cons(_, rest)) =>
      match halve_shape(rest) {
        None => None
        Some(tail) => Some(Cons((), tail))
      }
  }
}

///|
/// Structural power-of-two check, without an integer length or bit trick.
pub fn[A] valid_length(xs : @core.Chain[A]) -> Bool {
  match xs {
    Nil => false
    Cons(_, Nil) => true
    _ =>
      match halve_shape(xs) {
        None => false
        Some(half) => valid_length(half)
      }
  }
}

///|
/// Exact symbolic radix-two FFT. Empty and non-power-of-two signals are rejected.
/// For length N, the intended interpretation makes N*w a full rotation.
pub fn fft(w : Arrow, xs : Signal) -> Signal? {
  match valid_length(xs) {
    false => None
    true => Some(fft_raw(w, xs))
  }
}

///|
/// One direct DFT bin: sum_j rotate(j*step, xs[j]).
fn direct_bin(step : Arrow, phase : Arrow, xs : Signal) -> Number {
  match xs {
    Nil => Nil
    Cons(x, rest) =>
      rotate_add(phase, x, direct_bin(step, @core.append(step, phase), rest))
  }
}

///|
/// Independent quadratic specification, using the input spine as a bin counter.
pub fn dft(w : Arrow, xs : Signal) -> Signal {
  fn bins(todo : Signal, step : Arrow) -> Signal {
    match todo {
      Nil => Nil
      Cons(_, rest) =>
        Cons(direct_bin(step, Nil, xs), bins(rest, @core.append(w, step)))
    }
  }
  bins(xs, Nil)
}
