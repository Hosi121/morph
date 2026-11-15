///|
fn ivec(values : Array[Int32]) -> @core.Chain[@exact.Integer] {
  @oracle.chain(values.map(@oracle.integer))
}

///|
fn verify_answer(
  form : Decomposition,
  rhs : @core.Chain[@exact.Integer],
) -> SolveResult {
  match solve(form, rhs) {
    Some(result) => result
    None => abort("well-shaped integer system must resolve")
  }
}

///|
test "integer affine solutions carry a complete unimodular kernel basis" {
  for
    (width, rows, rhs) in [
      (2, [[2, 0], [0, 6]], [4, 12]),
      (2, [[2, 4], [1, 2]], [6, 3]),
      (3, [[2, 4, 0], [0, 0, 3]], [6, 6]),
      (2, [[0, 0], [0, 0]], [0, 0]),
    ] {
    let form = completed(imat(width, rows))
    let rhs = ivec(rhs)
    match verify_answer(form, rhs) {
      Solved(solution) => {
        assert_eq(solution_form(solution), form)
        assert_eq(solution_rhs(solution), rhs)
        assert_eq(
          check_solution(
            form,
            rhs,
            particular(solution),
            kernel_basis(solution),
          ),
          Some(solution),
        )
        assert_eq(apply(original(form), particular(solution)), Some(rhs))
        assert_eq(
          @oracle.int_of_nat(@core.length(kernel_basis(solution))),
          width - @oracle.int_of_nat(rank(form)),
        )
      }
      Impossible(_) =>
        abort("fixed feasible system must have an integer solution")
    }
  }
  let form = completed(imat(2, [[0, 0]]))
  assert_eq(
    check_solution(
      form,
      ivec([0]),
      ivec([0, 0]),
      @oracle.chain([ivec([2, 0]), ivec([0, 1])]),
    ),
    None,
  )
  assert_eq(
    check_solution(form, ivec([0]), ivec([0]), canonical_kernel(form)),
    None,
  )
}

///|
test "integral obstructions distinguish congruences from rational inconsistency" {
  let parity = completed(imat(1, [[2]]))
  match verify_answer(parity, ivec([1])) {
    Impossible(obstruction) => {
      assert_true(check_obstruction(original(parity), ivec([1]), obstruction))
      assert_true(obstruction is Congruence(_, _))
    }
    Solved(_) => abort("twice an integer cannot be one")
  }
  let deficient = completed(imat(2, [[1, 0], [0, 0]]))
  match verify_answer(deficient, ivec([0, 1])) {
    Impossible(obstruction) => {
      assert_true(
        check_obstruction(original(deficient), ivec([0, 1]), obstruction),
      )
      assert_true(obstruction is Annihilator(_))
    }
    Solved(_) => abort("zero row cannot equal one")
  }
  assert_false(
    check_obstruction(
      imat(1, [[2]]),
      ivec([1]),
      Congruence(ivec([1]), @oracle.binary(1)),
    ),
  )
  assert_false(
    check_obstruction(
      imat(1, [[2]]),
      ivec([1]),
      Congruence(ivec([1]), @oracle.binary(3)),
    ),
  )
  assert_false(
    check_obstruction(
      imat(1, [[2]]),
      ivec([2]),
      Congruence(ivec([1]), @oracle.binary(2)),
    ),
  )
  assert_false(
    check_obstruction(imat(1, [[2]]), ivec([1]), Annihilator(ivec([0]))),
  )
  assert_false(
    check_obstruction(imat(1, [[2]]), ivec([1]), Annihilator(ivec([]))),
  )
}

///|
test "empty and rectangular integer systems preserve the correct solution dimensions" {
  let no_rows = completed(imat(3, []))
  match verify_answer(no_rows, Nil) {
    Solved(solution) => {
      assert_eq(particular(solution), ivec([0, 0, 0]))
      assert_eq(@oracle.int_of_nat(@core.length(kernel_basis(solution))), 3)
    }
    _ => abort("empty constraints allow all integer triples")
  }
  let no_cols = completed(imat(0, [[], []]))
  match verify_answer(no_cols, ivec([0, 0])) {
    Solved(solution) => {
      assert_eq(particular(solution), Nil)
      assert_eq(kernel_basis(solution), Nil)
    }
    _ => abort("zero-dimensional zero equation is solvable")
  }
  match verify_answer(no_cols, ivec([0, 1])) {
    Impossible(obstruction) =>
      assert_true(
        check_obstruction(original(no_cols), ivec([0, 1]), obstruction),
      )
    _ => abort("zero variables cannot produce a nonzero result")
  }
  assert_eq(solve(no_rows, ivec([0])), None)
  assert_eq(solve(no_cols, ivec([0])), None)
}

///|
test "all small scalar integer systems agree with integer divisibility" {
  for a in -4..<5 {
    let form = completed(imat(1, [[a]]))
    for b in -4..<5 {
      let expected = if a == 0 { b == 0 } else { b % a == 0 }
      match verify_answer(form, ivec([b])) {
        Solved(solution) => {
          assert_true(expected)
          let x = @oracle.int_of_integer(@oracle.array(particular(solution))[0])
          assert_eq(a * x, b)
        }
        Impossible(obstruction) => {
          assert_false(expected)
          assert_true(check_obstruction(original(form), ivec([b]), obstruction))
        }
      }
    }
  }
}

///|
test "small two square systems verify solutions and refute every bounded integer witness" {
  for a in -1..<2 {
    for b in -1..<2 {
      for c in -1..<2 {
        for d in -1..<2 {
          let form = completed(imat(2, [[a, b], [c, d]]))
          for e in -2..<3 {
            for f in -2..<3 {
              match verify_answer(form, ivec([e, f])) {
                Solved(solution) => {
                  let x = @oracle.array(particular(solution)).map(
                    @oracle.int_of_integer,
                  )
                  assert_eq(a * x[0] + b * x[1], e)
                  assert_eq(c * x[0] + d * x[1], f)
                }
                Impossible(obstruction) => {
                  assert_true(
                    check_obstruction(original(form), ivec([e, f]), obstruction),
                  )
                  for x in -4..<5 {
                    for y in -4..<5 {
                      assert_false(a * x + b * y == e && c * x + d * y == f)
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
}
