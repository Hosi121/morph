///|
/// The checked characteristic is canonical Binary; this is exactly prime two.
fn characteristic_two(field : @primefield.Field) -> Bool {
  match @binary.bits(@modular.value(@primefield.modulus(field))) {
    Cons(false, Cons(true, Nil)) => true
    _ => false
  }
}

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
/// Canonical inputs already contain only zero and one. Reuse their immutable
/// coefficients; an equal pair cancels without integer addition or remainder.
fn char_two_add(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => {
      let tail = char_two_add(xs, ys, zero)
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
        false => char_two_add(b, shifted, zero)
      }
    }
  }
}

///|
/// In characteristic two, cross terms cancel and each canonical coefficient
/// squares to itself. Insert one zero between coefficients, sharing the final
/// constant chain so the result has no trailing zero.
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
