///|
/// The characteristic is checked and canonical, so this recognizes prime two.
fn is_binary_field(field : Field) -> Bool {
  match @binary.bits(characteristic(field)) {
    Cons(false, Cons(true, Nil)) => true
    _ => false
  }
}

///|
/// Canonical coefficients are zero or one. Reuse their immutable values and
/// normalize only the high zero coefficients after XOR cancellation.
fn xor_field_coefficients(
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => {
      let tail = xor_field_coefficients(xs, ys, zero)
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
/// Compare coefficient spans directly; constructing intermediate Nat lengths
/// is unnecessary. Each element has width at most the checked field degree.
fn full_coefficient_width(
  coefficients : @core.Chain[@binary.Binary],
  span : @core.Chain[@binary.Binary],
) -> Bool {
  match (coefficients, span) {
    (Nil, Nil) => true
    (Cons(_, rest), Cons(_, tail)) => full_coefficient_width(rest, tail)
    _ => false
  }
}

///|
/// Multiplication by x. A short value needs only a shared low-zero prefix;
/// the full-width case cancels its carry against the monic modulus directly.
fn binary_field_shift(
  coefficients : @core.Chain[@binary.Binary],
  modulus : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
) -> @core.Chain[@binary.Binary] {
  match (coefficients, modulus) {
    (Nil, _) => Nil
    (_, Cons(_, span)) => {
      let shifted : @core.Chain[@binary.Binary] = Cons(zero, coefficients)
      match full_coefficient_width(coefficients, span) {
        true => xor_field_coefficients(shifted, modulus, zero)
        false => shifted
      }
    }
    _ => coefficients
  }
}

///|
fn binary_product_loop(
  left : @core.Chain[@binary.Binary],
  right : @core.Chain[@binary.Binary],
  modulus : @core.Chain[@binary.Binary],
  zero : @binary.Binary,
  accumulator : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  match right {
    Nil => accumulator
    Cons(head, rest) => {
      let next = match @binary.odd(head) {
        true => xor_field_coefficients(accumulator, left, zero)
        false => accumulator
      }
      match rest {
        Nil => next
        _ =>
          binary_product_loop(
            binary_field_shift(left, modulus, zero),
            rest,
            modulus,
            zero,
            next,
          )
      }
    }
  }
}

///|
/// Keep the degree bound at every shift, without a full product or polynomial
/// long division. Variable-width canonical coefficients avoid fixed-width
/// conversion overhead on sparse products and share short shifted tails.
fn binary_field_product(a : Element, b : Element) -> Element {
  let left = @fppoly.coefficients(a.representative)
  let right = @fppoly.coefficients(b.representative)
  match (left, right) {
    (Nil, _) => return a
    (_, Nil) => return b
    (Cons(_, Nil), _) => return b
    (_, Cons(_, Nil)) => return a
    _ => ()
  }
  let field = a.field
  {
    field,
    representative: @fppoly.polynomial(
      prime_field(field),
      binary_product_loop(
        left,
        right,
        @fppoly.coefficients(field.modulus),
        @binary.zero(),
        Nil,
      ),
    ),
  }
}
