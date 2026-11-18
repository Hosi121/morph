///|
fn xor(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, false) | (false, true) => true
    _ => false
  }
}

///|
fn xor_coefficients(
  a : @core.Chain[Bool],
  b : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => {
      let head = xor(x, y)
      let tail = xor_coefficients(xs, ys)
      match (head, tail) {
        (false, Nil) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
/// Multiply by X and immediately cancel a possible degree-d term with f.
fn bool_shift(
  coefficients : @core.Chain[Bool],
  modulus : @core.Chain[Bool],
  degree : @core.Nat,
) -> @core.Chain[Bool] {
  match coefficients {
    Nil => Nil
    _ => {
      let shifted = @core.Cons(false, coefficients)
      match @core.compare(@core.length(coefficients), degree) {
        Equal => xor_coefficients(shifted, modulus)
        _ => shifted
      }
    }
  }
}

///|
/// Keep every partial product below degree d, without a full convolution.
fn bool_product(
  a : @core.Chain[Bool],
  b : @core.Chain[Bool],
  modulus : @core.Chain[Bool],
  degree : @core.Nat,
) -> @core.Chain[Bool] {
  fn walk(
    left : @core.Chain[Bool],
    right : @core.Chain[Bool],
    accumulated : @core.Chain[Bool],
  ) -> @core.Chain[Bool] {
    match right {
      Nil => accumulated
      Cons(bit, rest) => {
        let next = if bit {
          xor_coefficients(accumulated, left)
        } else {
          accumulated
        }
        match rest {
          Nil => next
          _ => walk(bool_shift(left, modulus, degree), rest, next)
        }
      }
    }
  }
  match (a, b) {
    (Nil, _) | (_, Nil) => Nil
    (Cons(true, Nil), _) => b
    (_, Cons(true, Nil)) => a
    _ => walk(a, b, Nil)
  }
}

///|
/// Bool coefficients enforce the base field F2 statically. Characteristic two
/// alone would not justify treating coefficients of an arbitrary field as bits.
/// Policy is an execution choice; it is not part of quotient identity.
pub fn[K] gf2_context(
  key : K,
  modulus : @core.Chain[Bool],
  policy : Policy,
) -> Result[Context[Bool, K], QuotientError] {
  match context(@gf2.field(), key, fn(a) { !a }, fn(_) { true }, modulus) {
    Err(error) => Err(error)
    Ok(context) => {
      let modulus = context.modulus
      let degree = context.degree
      let product = match policy {
        Generic => context.product
        Carryless => fn(a, b) { bool_product(a, b, modulus, degree) }
      }
      Ok({ ..context, product, policy, })
    }
  }
}
