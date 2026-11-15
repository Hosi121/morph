///|
fn smith_form(input : @matrix.Matrix[@exact.Integer]) -> @smith.Decomposition {
  match @smith.run(@smith.start(input), @oracle.nat(2000)) {
    Done(form) => form
    _ => abort("small Smith preprocessing must finish")
  }
}

///|
fn arbitrary(input : @matrix.Matrix[@exact.Integer]) -> LatticeReduction {
  let prepared = from_smith(smith_form(input)).unwrap()
  combine(prepared, completed(independent_basis(prepared))).unwrap()
}

///|
test "Smith preprocessing preserves the integer lattice rather than picking rationally independent rows" {
  let input = imat(2, [[2, 0], [3, 0]])
  assert_eq(start(input), None)
  let result = arbitrary(input)
  assert_eq(lattice_original(result), input)
  assert_eq(lattice_basis(result), imat(2, [[1, 0]]))
  assert_eq(
    check_lattice(input, lattice_transform(result), lattice_basis(result)),
    Some(result),
  )
  assert_eq(
    check_lattice(
      input,
      @matrix.identity(@oracle.nat(2), integers()),
      imat(2, [[2, 0]]),
    ),
    None,
  )
  let prepared = from_smith(smith_form(input)).unwrap()
  assert_eq(@smith.original(smith_certificate(prepared)), input)
  assert_eq(combine(prepared, completed(imat(2, [[1, 1]]))), None)
}

///|
test "dependent rectangular and zero rank presentations get checked independent bases" {
  for
    (width, rows) in [
      (3, [[2, 4, 6], [4, 8, 12], [6, 12, 18]]),
      (2, [[0, 0], [0, 0], [0, 0]]),
      (3, []),
      (0, [[], [], []]),
      (4, [[1, 1, 1, 1], [1, 0, 2, 3]]),
      (4, [[2, 0, 0, 2], [0, 3, 3, 0], [2, 3, 3, 2]]),
    ] {
    let input = imat(width, rows)
    let result = arbitrary(input)
    assert_eq(@matrix.width(lattice_basis(result)), @matrix.width(input))
    assert_eq(@matrix.height(lattice_transform(result)), @matrix.height(input))
    assert_eq(
      check_lattice(input, lattice_transform(result), lattice_basis(result)),
      Some(result),
    )
    assert_true(check_gram(lattice_basis(result), lattice_gram(result)))
  }
}

///|
fn gcd_int(a : Int32, b : Int32) -> Int32 {
  let mut x = a.abs()
  let mut y = b.abs()
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
test "all small dependent two square presentations preserve content and checked lattice equivalence" {
  for a in -2..<3 {
    for b in -2..<3 {
      for c in -2..<3 {
        for d in -2..<3 {
          if a * d - b * c == 0 {
            let input = imat(2, [[a, b], [c, d]])
            let result = arbitrary(input)
            let source_content = gcd_int(gcd_int(a, b), gcd_int(c, d))
            let rows = @oracle.array(@matrix.rows(lattice_basis(result)))
            if source_content == 0 {
              assert_eq(rows.length(), 0)
            } else {
              assert_eq(rows.length(), 1)
              let row = @oracle.array(rows[0]).map(@oracle.int_of_integer)
              assert_eq(gcd_int(row[0], row[1]), source_content)
            }
            assert_eq(
              check_lattice(
                input,
                lattice_transform(result),
                lattice_basis(result),
              ),
              Some(result),
            )
          }
        }
      }
    }
  }
}
