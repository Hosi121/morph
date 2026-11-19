///|
/// Reduce arbitrary Binary coefficients by their low bit, sharing zero and one.
fn char_two_trim(
  coefficients : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
  one : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match coefficients {
    Nil => Nil
    Cons(head, rest) => {
      let tail = char_two_trim(rest, zero, one)
      match (@binary.odd(head), tail) {
        (false, Nil) => Nil
        (false, _) => Cons(zero, tail)
        (true, _) => Cons(one, tail)
      }
    }
  }
}

///|
/// Add low-first coefficient chains over F2, trimming high zero coefficients.
/// Inputs must be canonical (only Binary zero/one, no high zero); zero must be
/// Binary zero. Checked F2 polynomial/extension boundaries ensure this contract.
/// Reuse immutable coefficients and tails; this does not reduce arbitrary inputs.
pub fn add_f2_coefficients(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => {
      let tail = add_f2_coefficients(xs, ys, zero)
      let head = match (@binary.is_zero(x), @binary.is_zero(y)) {
        (true, _) => y
        (_, true) => x
        _ => zero
      }
      match (@binary.is_zero(head), tail) {
        (true, Nil) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
fn char_two_multiply(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, _) | (_, Nil) => Nil
    (Cons(head, rest), _) => {
      let shifted : @core.Chain[@binary.Binary] = match
        char_two_multiply(rest, b, zero) {
        Nil => Nil
        tail => Cons(zero, tail)
      }
      match @binary.is_zero(head) {
        true => shifted
        false => add_f2_coefficients(b, shifted, zero)
      }
    }
  }
}

///|
/// Over the prime base F2, cross terms cancel and each coefficient squares to
/// itself (not over every characteristic-two field). Insert one zero between
/// coefficients, sharing the final constant chain to avoid a high zero.
fn char_two_square(
  coefficients : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match coefficients {
    Nil => Nil
    Cons(_, Nil) => coefficients
    Cons(head, rest) => Cons(head, Cons(zero, char_two_square(rest, zero)))
  }
}
