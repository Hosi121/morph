// Generated with SymPy 1.14.0, reduced lex Groebner bases over QQ.

///|
test "SymPy QQ lex Groebner fixture 0" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(-1, 1, [1, 0]), (1, 1, [0, 2])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
    make_poly(2, [(1, 1, [0, 3]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 1" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 2]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 2, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 2" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
    make_poly(2, [(1, 1, [0, 3]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 3" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [1, 1])]),
    make_poly(2, [(1, 1, [0, 2])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 1])]),
    make_poly(2, [(1, 1, [0, 2])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 4" {
  let generators = @oracle.chain([
    make_poly(2, [(2, 1, [1, 0]), (3, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(3, 1, [1, 0]), (-1, 1, [0, 1]), (2, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (5, 11, [0, 0])]),
    make_poly(2, [(1, 1, [0, 1]), (-7, 11, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 5" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 6" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0])]),
    make_poly(2, [(1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 7" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 2]), (1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 8" {
  let generators = @oracle.chain([
    make_poly(3, [
      (1, 1, [1, 0, 0]),
      (1, 1, [0, 1, 0]),
      (1, 1, [0, 0, 1]),
      (-1, 1, [0, 0, 0]),
    ]),
    make_poly(3, [(1, 1, [1, 0, 0]), (-1, 1, [0, 1, 0])]),
    make_poly(3, [(1, 1, [0, 1, 0]), (-1, 1, [0, 0, 1])]),
  ])
  let basis = complete(3, generators)
  let expected = @oracle.chain([
    make_poly(3, [(1, 1, [1, 0, 0]), (-1, 3, [0, 0, 0])]),
    make_poly(3, [(1, 1, [0, 1, 0]), (-1, 3, [0, 0, 0])]),
    make_poly(3, [(1, 1, [0, 0, 1]), (-1, 3, [0, 0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 9" {
  let generators = @oracle.chain([
    make_poly(3, [(1, 1, [1, 1, 0]), (-1, 1, [0, 0, 1])]),
    make_poly(3, [(-1, 1, [1, 0, 0]), (1, 1, [0, 1, 1])]),
    make_poly(3, [(1, 1, [1, 0, 1]), (-1, 1, [0, 1, 0])]),
  ])
  let basis = complete(3, generators)
  let expected = @oracle.chain([
    make_poly(3, [(1, 1, [1, 0, 0]), (-1, 1, [0, 1, 1])]),
    make_poly(3, [(1, 1, [0, 2, 0]), (-1, 1, [0, 0, 2])]),
    make_poly(3, [(1, 1, [0, 1, 2]), (-1, 1, [0, 1, 0])]),
    make_poly(3, [(1, 1, [0, 0, 3]), (-1, 1, [0, 0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 10" {
  let generators = @oracle.chain([
    make_poly(3, [(1, 1, [1, 0, 0]), (1, 1, [0, 1, 0]), (1, 1, [0, 0, 1])]),
    make_poly(3, [(1, 1, [1, 1, 0]), (1, 1, [1, 0, 1]), (1, 1, [0, 1, 1])]),
    make_poly(3, [(1, 1, [1, 1, 1]), (-1, 1, [0, 0, 0])]),
  ])
  let basis = complete(3, generators)
  let expected = @oracle.chain([
    make_poly(3, [(1, 1, [1, 0, 0]), (1, 1, [0, 1, 0]), (1, 1, [0, 0, 1])]),
    make_poly(3, [(1, 1, [0, 2, 0]), (1, 1, [0, 1, 1]), (1, 1, [0, 0, 2])]),
    make_poly(3, [(1, 1, [0, 0, 3]), (-1, 1, [0, 0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 11" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0])]),
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([make_poly(2, [(1, 1, [0, 0])])])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 12" {
  let generators = @oracle.chain([])
  let basis = complete(2, generators)
  let expected = @oracle.chain([])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 13" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 2]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 3]), (2, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 14" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
    make_poly(2, [(1, 1, [0, 2]), (1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 15" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 16" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 2]), (-1, 1, [0, 1])]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (-2, 1, [0, 2]),
      (1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 17" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
    make_poly(2, [(1, 1, [0, 3]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 18" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (2, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 19" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (1, 1, [0, 2]),
      (2, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (3, 1, [0, 2]),
      (3, 1, [0, 1]),
      (2, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 20" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (-1, 1, [1, 0]),
      (1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (-1, 1, [1, 0]),
      (1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
    make_poly(2, [(1, 1, [0, 2]), (-3, 1, [0, 1]), (2, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 21" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (-2, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 22" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (1, 1, [1, 0]),
      (1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (1, 2, [0, 2]),
      (1, 2, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
    make_poly(2, [(1, 1, [0, 3]), (2, 1, [0, 2]), (-3, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 23" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (-1, 1, [0, 2]),
      (1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (-2, 1, [0, 2]),
      (-1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 24" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (2, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 1, [0, 1]), (1, 2, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 25" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 2]), (1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 26" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (-1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 2])]),
    make_poly(2, [(1, 1, [0, 3]), (1, 1, [0, 2]), (1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 27" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 1]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 28" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 29" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1])]),
    make_poly(2, [(1, 1, [0, 2]), (-1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 30" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 31" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0]), (1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (-1, 1, [0, 2]),
      (1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (-2, 1, [0, 2]),
      (3, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 32" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 2])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 33" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 34" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (1, 1, [0, 1])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 2]), (2, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 3]), (3, 1, [0, 2]), (1, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 35" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (-1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (-1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
    make_poly(2, [(1, 1, [0, 2]), (-2, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 36" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 1]), (-1, 2, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 37" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (-1, 1, [0, 2]),
      (-2, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (2, 1, [0, 2]),
      (-2, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 38" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (1, 1, [0, 0])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (1, 1, [1, 0]),
      (-1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (1, 2, [0, 2]), (-1, 2, [0, 1])]),
    make_poly(2, [(1, 1, [0, 3]), (1, 1, [0, 1]), (-2, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 39" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (-1, 1, [1, 0]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([make_poly(2, [(1, 1, [0, 0])])])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 40" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 2]), (1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [0, 3]), (-1, 1, [0, 2]), (1, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 41" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (1, 1, [0, 2]),
      (2, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
    make_poly(2, [(1, 1, [0, 3]), (3, 1, [0, 2]), (3, 1, [0, 1])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 42" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [1, 0]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 1, [0, 1]), (-1, 1, [0, 0])]),
    make_poly(2, [(1, 1, [0, 2]), (2, 1, [0, 1]), (2, 1, [0, 0])]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 43" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (1, 1, [0, 1])]),
    make_poly(2, [
      (1, 1, [1, 1]),
      (-1, 1, [1, 0]),
      (1, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [(1, 1, [1, 0]), (-1, 2, [0, 2]), (-1, 2, [0, 0])]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (-1, 1, [0, 2]),
      (3, 1, [0, 1]),
      (1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}

///|
test "SymPy QQ lex Groebner fixture 44" {
  let generators = @oracle.chain([
    make_poly(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
    make_poly(2, [(1, 1, [1, 1]), (1, 1, [0, 1]), (1, 1, [0, 0])]),
  ])
  let basis = complete(2, generators)
  let expected = @oracle.chain([
    make_poly(2, [
      (1, 1, [1, 0]),
      (1, 1, [0, 2]),
      (-1, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
    make_poly(2, [
      (1, 1, [0, 3]),
      (-1, 1, [0, 2]),
      (-2, 1, [0, 1]),
      (-1, 1, [0, 0]),
    ]),
  ])
  assert_eq(polynomials(basis), expected)
  assert_eq(verify(basis), Ok(true))
  for generator in @oracle.array(generators) {
    assert_true(@poly.is_zero(required(normal_form(basis, generator))))
  }
}
