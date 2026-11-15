///|
/// Error-preserving operation dictionary for dynamically tagged field elements.
/// Inverse returns Ok(None) exactly for zero; Err is never treated as zero.
pub(all) struct CheckedField[A, E] {
  zero : A
  one : A
  add : (A, A) -> Result[A, E]
  subtract : (A, A) -> Result[A, E]
  negate : (A) -> Result[A, E]
  multiply : (A, A) -> Result[A, E]
  inverse : (A) -> Result[A?, E]
}

///|
#derive(Eq, Debug)
pub(all) enum CheckedError[E] {
  Arithmetic(E)
  InvalidField
  InternalInvariant
}

///|
pub extend CheckedError with Eq::{equal, not_equal}

///|
pub extend CheckedError with Debug::{to_repr}

///|
fn[A, E] lift(result : Result[A, E]) -> Result[A, CheckedError[E]] {
  match result {
    Ok(value) => Ok(value)
    Err(error) => Err(Arithmetic(error))
  }
}

///|
fn[A, E] checked_negate(
  field : CheckedField[A, E],
  values : @core.Chain[A],
) -> Result[@core.Chain[A], CheckedError[E]] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match (lift((field.negate)(value)), checked_negate(field, rest)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn[A, E] checked_polynomial_subtract(
  field : CheckedField[A, E],
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> Result[@core.Chain[A], CheckedError[E]] {
  match (a, b) {
    (Nil, _) => checked_negate(field, b)
    (_, Nil) => Ok(a)
    (Cons(x, xs), Cons(y, ys)) =>
      match
        (
          lift((field.subtract)(x, y)),
          checked_polynomial_subtract(field, xs, ys),
        ) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn[A, E] checked_scale(
  field : CheckedField[A, E],
  values : @core.Chain[A],
  scalar : A,
) -> Result[@core.Chain[A], CheckedError[E]] {
  match values {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match
        (
          lift((field.multiply)(value, scalar)),
          checked_scale(field, rest, scalar),
        ) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn[A, E] checked_discrepancy(
  field : CheckedField[A, E],
  connection : @core.Chain[A],
  history : @core.Chain[A],
  current : A,
) -> Result[A, CheckedError[E]] {
  match (connection, history) {
    (Nil, _) => Ok(current)
    (Cons(coefficient, rest), Cons(previous, tail)) =>
      match lift((field.multiply)(coefficient, previous)) {
        Err(error) => Err(error)
        Ok(product) =>
          match lift((field.add)(current, product)) {
            Err(error) => Err(error)
            Ok(next) => checked_discrepancy(field, rest, tail, next)
          }
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn[A, E] checked_run(
  field : CheckedField[A, E],
  input : @core.Chain[A],
  history : @core.Chain[A],
  index : @core.Nat,
  connection : @core.Chain[A],
  backup : @core.Chain[A],
  length : @core.Nat,
  shift : @core.Nat,
  inverse_previous : A,
) -> Result[Recurrence[A], CheckedError[E]] {
  match input {
    Nil => Ok({ length, connection, })
    Cons(current, rest) =>
      match connection {
        Nil => Err(InternalInvariant)
        Cons(_, tail) =>
          match checked_discrepancy(field, tail, history, current) {
            Err(error) => Err(error)
            Ok(difference) =>
              match lift((field.inverse)(difference)) {
                Err(error) => Err(error)
                Ok(None) =>
                  checked_run(
                    field,
                    rest,
                    Cons(current, history),
                    Succ(index),
                    connection,
                    backup,
                    length,
                    Succ(shift),
                    inverse_previous,
                  )
                Ok(Some(inverse_difference)) =>
                  match lift((field.multiply)(difference, inverse_previous)) {
                    Err(error) => Err(error)
                    Ok(scalar) =>
                      match checked_scale(field, backup, scalar) {
                        Err(error) => Err(error)
                        Ok(scaled) =>
                          match
                            checked_polynomial_subtract(
                              field,
                              connection,
                              @core.append(
                                @core.replicate(shift, field.zero),
                                scaled,
                              ),
                            ) {
                            Err(error) => Err(error)
                            Ok(changed) =>
                              match
                                @core.compare(@core.add(length, length), index) {
                                Less | Equal => {
                                  let next_length = @core.subtract(
                                    Succ(index),
                                    length,
                                  )
                                  let changed = @core.take(
                                    Succ(next_length),
                                    @core.append(
                                      changed,
                                      @core.replicate(
                                        Succ(next_length),
                                        field.zero,
                                      ),
                                    ),
                                  )
                                  checked_run(
                                    field,
                                    rest,
                                    Cons(current, history),
                                    Succ(index),
                                    changed,
                                    connection,
                                    next_length,
                                    Succ(Zero),
                                    inverse_difference,
                                  )
                                }
                                Greater => {
                                  let changed = @core.take(
                                    Succ(length),
                                    @core.append(
                                      changed,
                                      @core.replicate(Succ(length), field.zero),
                                    ),
                                  )
                                  checked_run(
                                    field,
                                    rest,
                                    Cons(current, history),
                                    Succ(index),
                                    changed,
                                    backup,
                                    length,
                                    Succ(shift),
                                    inverse_previous,
                                  )
                                }
                              }
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
pub fn[A, E] checked_berlekamp_massey(
  field : CheckedField[A, E],
  input : @core.Chain[A],
) -> Result[Recurrence[A], CheckedError[E]] {
  match lift((field.inverse)(field.one)) {
    Err(error) => Err(error)
    Ok(None) => Err(InvalidField)
    Ok(Some(inverse_one)) =>
      checked_run(
        field,
        input,
        Nil,
        Zero,
        Cons(field.one, Nil),
        Cons(field.one, Nil),
        Zero,
        Succ(Zero),
        inverse_one,
      )
  }
}

///|
fn[A, E] checked_dot(
  field : CheckedField[A, E],
  a : @core.Chain[A],
  b : @core.Chain[A],
  accumulator : A,
) -> Result[A, CheckedError[E]] {
  match (a, b) {
    (Nil, Nil) => Ok(accumulator)
    (Cons(x, xs), Cons(y, ys)) =>
      match lift((field.multiply)(x, y)) {
        Err(error) => Err(error)
        Ok(product) =>
          match lift((field.add)(accumulator, product)) {
            Err(error) => Err(error)
            Ok(next) => checked_dot(field, xs, ys, next)
          }
      }
    _ => Err(InternalInvariant)
  }
}

///|
/// Error-preserving version of the independent forward-window checker.
pub fn[A, E] checked_check(
  field : CheckedField[A, E],
  input : @core.Chain[A],
  recurrence : Recurrence[A],
) -> Result[Bool, CheckedError[E]] {
  fn windows(input : @core.Chain[A]) -> Result[Bool, CheckedError[E]] {
    match @core.split_exact(Succ(recurrence.length), input) {
      None => Ok(true)
      Some((window, _)) =>
        match
          checked_dot(
            field,
            @core.reverse(recurrence.connection),
            window,
            field.zero,
          ) {
          Err(error) => Err(error)
          Ok(value) =>
            match lift((field.inverse)(value)) {
              Err(error) => Err(error)
              Ok(Some(_)) => Ok(false)
              Ok(None) =>
                match input {
                  Nil => Ok(true)
                  Cons(_, rest) => windows(rest)
                }
            }
        }
    }
  }
  match
    (
      @core.compare(
        @core.length(recurrence.connection),
        Succ(recurrence.length),
      ),
      recurrence.connection,
      @core.compare(recurrence.length, @core.length(input)),
    ) {
    (Equal, Cons(constant, _), Less | Equal) =>
      match lift((field.subtract)(constant, field.one)) {
        Err(error) => Err(error)
        Ok(value) =>
          match lift((field.inverse)(value)) {
            Err(error) => Err(error)
            Ok(Some(_)) => Ok(false)
            Ok(None) => windows(input)
          }
      }
    _ => Ok(false)
  }
}
