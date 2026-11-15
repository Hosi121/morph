///|
/// Finite-prefix recurrence s_n + c_1*s_(n-1) + ... + c_L*s_(n-L) = zero
/// for n>=L. The connection list has exactly L+1 entries and starts with one.
/// Trailing zero coefficients are meaningful when the finite-prefix length L
/// exceeds the actual degree of the connection polynomial.
#derive(Eq, Debug)
pub(all) struct Recurrence[A] {
  length : @core.Nat
  connection : @core.Chain[A]
}

///|
pub extend Recurrence with Eq::{equal, not_equal}

///|
pub extend Recurrence with Debug::{to_repr}

///|
fn[A] polynomial_subtract(
  field : @rowreduce.Field[A],
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> @core.Chain[A] {
  match (a, b) {
    (Nil, _) => @core.map(b, field.negate)
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      Cons((field.subtract)(x, y), polynomial_subtract(field, xs, ys))
  }
}

///|
fn[A] discrepancy(
  field : @rowreduce.Field[A],
  connection : @core.Chain[A],
  history : @core.Chain[A],
  current : A,
) -> A? {
  match (connection, history) {
    (Nil, _) => Some(current)
    (Cons(coefficient, rest), Cons(previous, tail)) =>
      discrepancy(
        field,
        rest,
        tail,
        (field.add)(current, (field.multiply)(coefficient, previous)),
      )
    _ => None
  }
}

///|
fn[A] run(
  field : @rowreduce.Field[A],
  input : @core.Chain[A],
  history : @core.Chain[A],
  index : @core.Nat,
  connection : @core.Chain[A],
  backup : @core.Chain[A],
  length : @core.Nat,
  shift : @core.Nat,
  inverse_previous : A,
) -> Recurrence[A]? {
  match input {
    Nil => Some({ length, connection, })
    Cons(current, rest) =>
      match connection {
        Nil => None
        Cons(_, tail) =>
          match discrepancy(field, tail, history, current) {
            None => None
            Some(difference) =>
              match (field.inverse)(difference) {
                None =>
                  run(
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
                Some(inverse_difference) => {
                  let scalar = (field.multiply)(difference, inverse_previous)
                  let correction = @core.append(
                    @core.replicate(shift, field.zero),
                    @core.map(backup, fn(coefficient) {
                      (field.multiply)(scalar, coefficient)
                    }),
                  )
                  let changed = polynomial_subtract(
                    field, connection, correction,
                  )
                  match @core.compare(@core.add(length, length), index) {
                    Less | Equal => {
                      let next_length = @core.subtract(Succ(index), length)
                      let changed = @core.take(
                        Succ(next_length),
                        @core.append(
                          changed,
                          @core.replicate(Succ(next_length), field.zero),
                        ),
                      )
                      run(
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
                      run(
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

///|
/// Berlekamp-Massey over a field operation dictionary. As with rowreduce, field
/// laws and inverse(None) iff zero are preconditions, not checked proof objects.
pub fn[A] berlekamp_massey(
  field : @rowreduce.Field[A],
  input : @core.Chain[A],
) -> Recurrence[A]? {
  match (field.inverse)(field.one) {
    None => None
    Some(inverse_one) =>
      run(
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
fn[A] valid_shape(
  field : @rowreduce.Field[A],
  recurrence : Recurrence[A],
) -> Bool {
  match
    (
      @core.compare(
        @core.length(recurrence.connection),
        Succ(recurrence.length),
      ),
      recurrence.connection,
    ) {
    (Equal, Cons(constant, _)) =>
      match (field.inverse)((field.subtract)(constant, field.one)) {
        None => true
        Some(_) => false
      }
    _ => false
  }
}

///|
fn[A] dot(
  field : @rowreduce.Field[A],
  a : @core.Chain[A],
  b : @core.Chain[A],
  accumulator : A,
) -> A? {
  match (a, b) {
    (Nil, Nil) => Some(accumulator)
    (Cons(x, xs), Cons(y, ys)) =>
      dot(field, xs, ys, (field.add)(accumulator, (field.multiply)(x, y)))
    _ => None
  }
}

///|
/// Independently substitute into forward fixed-length windows. This verifies
/// the recurrence equations and shape, not the minimality of the length.
pub fn[A] check(
  field : @rowreduce.Field[A],
  input : @core.Chain[A],
  recurrence : Recurrence[A],
) -> Bool {
  fn windows(input : @core.Chain[A], reversed : @core.Chain[A]) -> Bool {
    match @core.split_exact(Succ(recurrence.length), input) {
      None => true
      Some((window, _)) =>
        match (dot(field, reversed, window, field.zero), input) {
          (Some(value), Cons(_, tail)) =>
            match (field.inverse)(value) {
              None => windows(tail, reversed)
              Some(_) => false
            }
          _ => false
        }
    }
  }
  valid_shape(field, recurrence) &&
  !(@core.compare(recurrence.length, @core.length(input)) is Greater) &&
  windows(input, @core.reverse(recurrence.connection))
}

///|
/// Predict from exactly L previous samples in oldest-to-newest order.
pub fn[A] predict(
  field : @rowreduce.Field[A],
  recurrence : Recurrence[A],
  history : @core.Chain[A],
) -> A? {
  match
    valid_shape(field, recurrence) &&
    @core.compare(@core.length(history), recurrence.length) is Equal {
    false => None
    true =>
      match recurrence.connection {
        Nil => None
        Cons(_, tail) =>
          match dot(field, @core.reverse(tail), history, field.zero) {
            None => None
            Some(value) => Some((field.negate)(value))
          }
      }
  }
}
