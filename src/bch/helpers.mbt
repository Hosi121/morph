///|
fn[A] arithmetic(
  result : Result[A, @galois.FieldError],
) -> Result[A, CodeError] {
  match result {
    Ok(value) => Ok(value)
    Err(error) => Err(Arithmetic(error))
  }
}

///|
fn polynomial_evaluate(
  field : @galois.Field,
  values : @core.Chain[@galois.Element],
  point : @galois.Element,
) -> Result[@galois.Element, @galois.FieldError] {
  match values {
    Nil => Ok(@galois.zero(field))
    Cons(value, rest) =>
      match polynomial_evaluate(field, rest, point) {
        Err(error) => Err(error)
        Ok(tail) =>
          match @galois.multiply(point, tail) {
            Err(error) => Err(error)
            Ok(product) => @galois.add(value, product)
          }
      }
  }
}

///|
fn powers(
  root : @galois.Element,
  current : @galois.Element,
  remaining : @core.Nat,
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match remaining {
    Zero => Ok(Nil)
    Succ(rest) =>
      match @galois.multiply(current, root) {
        Err(error) => Err(error)
        Ok(next) =>
          match powers(root, next, rest) {
            Err(error) => Err(error)
            Ok(tail) => Ok(Cons(current, tail))
          }
      }
  }
}

///|
fn exact_order(
  root : @galois.Element,
  current : @galois.Element,
  remaining : @core.Nat,
) -> Result[Bool, @galois.FieldError] {
  match remaining {
    Zero => Ok(false)
    Succ(rest) =>
      match @galois.multiply(current, root) {
        Err(error) => Err(error)
        Ok(next) =>
          match next.equal(@galois.one(@galois.field_of(root))) {
            true => Ok(@core.is_zero(rest))
            false => exact_order(root, next, rest)
          }
      }
  }
}

///|
fn invert_all(
  values : @core.Chain[@galois.Element],
) -> Result[@core.Chain[@galois.Element], @galois.FieldError] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match (@galois.inverse(value), invert_all(rest)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn bm_field(
  field : @galois.Field,
) -> @recurrence.CheckedField[@galois.Element, @galois.FieldError] {
  {
    zero: @galois.zero(field),
    one: @galois.one(field),
    add: @galois.add,
    subtract: @galois.subtract,
    multiply: @galois.multiply,
    negate: fn(value) { Ok(@galois.negate(value)) },
    inverse: fn(value) {
      match @galois.inverse(value) {
        Ok(inverse) => Ok(Some(inverse))
        Err(@galois.ZeroDivisor) => Ok(None)
        Err(error) => Err(error)
      }
    },
  }
}
