///|
#derive(Eq, Debug)
pub struct Machine {
  input : @matrix.Matrix[@exact.Integer]
  current : @matrix.Matrix[@exact.Integer]
  left : @matrix.Matrix[@exact.Integer]
  right : @matrix.Matrix[@exact.Integer]
  pivot : @core.Nat
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Status {
  Done(Decomposition)
  Paused(Machine)
  Fault(Machine)
}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with Debug::{to_repr}

///|
pub fn start(input : @matrix.Matrix[@exact.Integer]) -> Machine {
  {
    input,
    current: input,
    left: @matrix.identity(@matrix.height(input), integers()),
    right: @matrix.identity(@matrix.width(input), integers()),
    pivot: Zero,
  }
}

///|
fn first_nonzero(
  values : @core.Chain[@exact.Integer],
  index : @core.Nat,
) -> @core.Nat? {
  match values {
    Nil => None
    Cons(value, rest) =>
      match zero(value) {
        true => first_nonzero(rest, Succ(index))
        false => Some(index)
      }
  }
}

///|
fn trailing_nonzero(
  input : @matrix.Matrix[@exact.Integer],
  pivot : @core.Nat,
) -> (@core.Nat, @core.Nat)? {
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    i : @core.Nat,
  ) -> (@core.Nat, @core.Nat)? {
    match rows {
      Nil => None
      Cons(row, rest) =>
        match first_nonzero(@core.drop(pivot, row), pivot) {
          Some(j) => Some((i, j))
          None => walk(rest, Succ(i))
        }
    }
  }
  walk(@core.drop(pivot, @matrix.rows(input)), pivot)
}

///|
fn trailing_bad(
  input : @matrix.Matrix[@exact.Integer],
  pivot : @core.Nat,
  divisor : @binary.Binary,
) -> @core.Nat? {
  fn row_bad(row : @core.Chain[@exact.Integer]) -> Bool {
    match row {
      Nil => false
      Cons(value, rest) =>
        !divides(divisor, @exact.magnitude(value)) || row_bad(rest)
    }
  }
  fn walk(
    rows : @core.Chain[@core.Chain[@exact.Integer]],
    i : @core.Nat,
  ) -> @core.Nat? {
    match rows {
      Nil => None
      Cons(row, rest) =>
        match row_bad(@core.drop(Succ(pivot), row)) {
          true => Some(i)
          false => walk(rest, Succ(i))
        }
    }
  }
  walk(@core.drop(Succ(pivot), @matrix.rows(input)), Succ(pivot))
}

///|
/// One Euclidean reduction or pivot move. Completion calls the independent
/// checker; fuel does not bound scans, bit operations or determinant work.
pub fn step(machine : Machine) -> Status {
  let k = machine.pivot
  let a = machine.current
  fn done() -> Status {
    match check(machine.input, machine.left, a, machine.right) {
      Some(form) => Done(form)
      None => Fault(machine)
    }
  }
  fn next(
    a : @matrix.Matrix[@exact.Integer],
    u : @matrix.Matrix[@exact.Integer],
    v : @matrix.Matrix[@exact.Integer],
    pivot : @core.Nat,
  ) -> Status {
    Paused({ ..machine, current: a, left: u, right: v, pivot, })
  }
  match cell(a, k, k) {
    None => done()
    Some(pivot) =>
      match zero(pivot) {
        true =>
          match trailing_nonzero(a, k) {
            None => done()
            Some((i, j)) =>
              match
                (
                  row_swap(a, k, i),
                  row_swap(machine.left, k, i),
                  column_swap(machine.right, k, j),
                ) {
                (Some(a), Some(u), Some(v)) =>
                  match column_swap(a, k, j) {
                    Some(a) => next(a, u, v, k)
                    None => Fault(machine)
                  }
                _ => Fault(machine)
              }
          }
        false =>
          match @matrix.column(a, k) {
            None => Fault(machine)
            Some(column) =>
              match first_nonzero(@core.drop(Succ(k), column), Succ(k)) {
                Some(i) =>
                  match cell(a, i, k) {
                    None => Fault(machine)
                    Some(value) =>
                      match quotient(value, pivot) {
                        None => Fault(machine)
                        Some(q) =>
                          match
                            (
                              row_add(a, i, k, @exact.negate(q)),
                              row_add(machine.left, i, k, @exact.negate(q)),
                            ) {
                            (Some(a), Some(u)) =>
                              match cell(a, i, k) {
                                Some(remainder) =>
                                  match zero(remainder) {
                                    true => next(a, u, machine.right, k)
                                    false =>
                                      match
                                        (row_swap(a, i, k), row_swap(u, i, k)) {
                                        (Some(a), Some(u)) =>
                                          next(a, u, machine.right, k)
                                        _ => Fault(machine)
                                      }
                                  }
                                None => Fault(machine)
                              }
                            _ => Fault(machine)
                          }
                      }
                  }
                None =>
                  match @core.nth(@matrix.rows(a), k) {
                    None => Fault(machine)
                    Some(row) =>
                      match first_nonzero(@core.drop(Succ(k), row), Succ(k)) {
                        Some(j) =>
                          match cell(a, k, j) {
                            None => Fault(machine)
                            Some(value) =>
                              match quotient(value, pivot) {
                                None => Fault(machine)
                                Some(q) =>
                                  match
                                    (
                                      column_add(a, j, k, @exact.negate(q)),
                                      column_add(
                                        machine.right,
                                        j,
                                        k,
                                        @exact.negate(q),
                                      ),
                                    ) {
                                    (Some(a), Some(v)) =>
                                      match cell(a, k, j) {
                                        Some(remainder) =>
                                          match zero(remainder) {
                                            true => next(a, machine.left, v, k)
                                            false =>
                                              match
                                                (
                                                  column_swap(a, j, k),
                                                  column_swap(v, j, k),
                                                ) {
                                                (Some(a), Some(v)) =>
                                                  next(a, machine.left, v, k)
                                                _ => Fault(machine)
                                              }
                                          }
                                        None => Fault(machine)
                                      }
                                    _ => Fault(machine)
                                  }
                              }
                          }
                        None =>
                          match trailing_bad(a, k, @exact.magnitude(pivot)) {
                            Some(i) =>
                              match
                                (
                                  row_add(
                                    a,
                                    k,
                                    i,
                                    @exact.positive(@binary.one()),
                                  ),
                                  row_add(
                                    machine.left,
                                    k,
                                    i,
                                    @exact.positive(@binary.one()),
                                  ),
                                ) {
                                (Some(a), Some(u)) =>
                                  next(a, u, machine.right, k)
                                _ => Fault(machine)
                              }
                            None =>
                              match @exact.negative(pivot) {
                                false =>
                                  next(a, machine.left, machine.right, Succ(k))
                                true =>
                                  match
                                    (
                                      row_negate(a, k),
                                      row_negate(machine.left, k),
                                    ) {
                                    (Some(a), Some(u)) =>
                                      next(a, u, machine.right, Succ(k))
                                    _ => Fault(machine)
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
pub fn run(machine : Machine, fuel : @core.Nat) -> Status {
  match fuel {
    Zero => Paused(machine)
    Succ(rest) =>
      match step(machine) {
        Paused(next) => run(next, rest)
        result => result
      }
  }
}
