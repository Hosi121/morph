///|
fn structural_legacy_swap(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  match row_swap(@matrix.transpose(input), a, b) {
    Some(value) => Some(@matrix.transpose(value))
    None => None
  }
}

///|
fn structural_legacy_add(
  input : @matrix.Matrix[@exact.Integer],
  a : @core.Nat,
  b : @core.Nat,
  factor : @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  match row_add(@matrix.transpose(input), a, b, factor) {
    Some(value) => Some(@matrix.transpose(value))
    None => None
  }
}

///|
/// One Euclidean reduction or pivot move. Completion calls the independent
/// checker; fuel does not bound scans, bit operations or determinant work.
fn structural_legacy_step(machine : Machine) -> Status {
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
                  structural_legacy_swap(machine.right, k, j),
                ) {
                (Some(a), Some(u), Some(v)) =>
                  match structural_legacy_swap(a, k, j) {
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
                                      structural_legacy_add(
                                        a,
                                        j,
                                        k,
                                        @exact.negate(q),
                                      ),
                                      structural_legacy_add(
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
                                                  structural_legacy_swap(
                                                    a, j, k,
                                                  ),
                                                  structural_legacy_swap(
                                                    v, j, k,
                                                  ),
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
test "structural direct column operations preserve legacy index and alias semantics" {
  for height in 0..<=4 {
    for width in 0..<=5 {
      let rows = Array::makei(height, fn(i) {
        Array::makei(width, fn(j) { (i * 7 + j * 3) % 11 - 5 })
      })
      let source = imat(width, rows)
      for a in 0..<=width {
        for b in 0..<=width {
          let a = @oracle.nat(a)
          let b = @oracle.nat(b)
          assert_eq(
            column_swap(source, a, b),
            structural_legacy_swap(source, a, b),
          )
          for factor in [-2, 0, 3] {
            let factor = @oracle.integer(factor)
            assert_eq(
              column_add(source, a, b, factor),
              structural_legacy_add(source, a, b, factor),
            )
          }
        }
      }
    }
  }
}

///|
test "structural Smith step trace retains exact U D V and faults" {
  let sources = [
    imat(3, []),
    imat(0, [[], []]),
    imat(4, [[0, 0, 6, 9], [2, 4, 8, 10]]),
    imat(2, [[0, 3], [4, 6], [8, -2]]),
    imat(3, [[12, 6, 4], [3, 9, 6], [2, 16, 14]]),
  ]
  for source in sources {
    let mut machine = start(source)
    for _ in 0..<100 {
      let actual = step(machine)
      assert_eq(actual, structural_legacy_step(machine))
      match actual {
        Paused(next) => machine = next
        Done(_) => break
        Fault(_) => abort("valid Smith trace faulted")
      }
    }
  }
  let malformed = { ..start(imat(2, [[1, 1], [0, 1]])), left: imat(0, []), }
  assert_eq(step(malformed), structural_legacy_step(malformed))
}
