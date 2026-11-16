///|
fn[A] required(result : Result[A, DecodeError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("listdecode operation")
  }
}

///|
fn native(values : @core.Chain[@binary.Binary]) -> Array[Int32] {
  @oracle.array(values).map(@oracle.int_of_binary)
}

///|
fn word(values : Array[Int32]) -> @core.Chain[@binary.Binary] {
  @oracle.chain(values.map(@oracle.binary))
}

///|
fn test_plan(
  p : Int32,
  xs : Array[Int32],
  k : Int32,
  a : Int32,
  s : Int32,
  d : Int32,
) -> Plan {
  let field = match @primefield.field(@oracle.binary(p)) {
    Some(field) => field
    None => abort("listdecode prime")
  }
  required(
    plan(
      field,
      word([ for i in 0..<p => i ]),
      word(xs),
      @oracle.nat(k),
      @oracle.nat(a),
      @oracle.nat(s),
      @oracle.nat(d),
    ),
  )
}

///|
fn complete(plan : Plan, received : Array[Int32]) -> Decoded {
  match required(decode(plan, word(received), @oracle.nat(1000))) {
    Complete(result) => result
    Suspended(_) => abort("listdecode unexpected budget exhaustion")
  }
}

///|
fn native_evaluate(p : Int32, coefficients : Array[Int32], x : Int32) -> Int32 {
  for i = coefficients.length() - 1, value = 0; i >= 0; {
    continue i - 1, (value * x + coefficients[i]) % p
  } nobreak {
    value
  }
}

///|
fn digits(value : Int32, p : Int32, k : Int32) -> Array[Int32] {
  let mut rest = value
  [
    for _ in 0..<k => {
      let digit = rest % p
      rest /= p
      digit
    }
  ]
}

///|
fn native_codeword(
  p : Int32,
  xs : Array[Int32],
  message : Array[Int32],
) -> Array[Int32] {
  xs.map(fn(x) { native_evaluate(p, message, x) })
}

///|
fn native_count(a : Array[Int32], b : Array[Int32]) -> Int32 {
  for i = 0, count = 0; i < a.length(); {
    continue i + 1, count + (if a[i] == b[i] { 1 } else { 0 })
  } nobreak {
    count
  }
}

///|
fn message_id(p : Int32, message : Array[Int32]) -> Int32 {
  for i = message.length() - 1, result = 0; i >= 0; {
    continue i - 1, result * p + message[i]
  } nobreak {
    result
  }
}

///|
fn assert_oracle(
  plan : Plan,
  p : Int32,
  received : Array[Int32],
) -> Decoded raise {
  let xs = native(points(plan))
  let k = @oracle.int_of_nat(message_size(plan))
  let a = @oracle.int_of_nat(minimum_agreements(plan))
  let size = for i = 0, size = 1; i < k; {
    continue i + 1, size * p
  } nobreak {
    size
  }
  // The only full message enumeration is this independent numeric test oracle.
  let expected = [
    for code in 0..<size if native_count(
      native_codeword(p, xs, digits(code, p, k)),
      received,
    ) >=
    a => code
  ]
  let decoded = complete(plan, received)
  let actual = @oracle.array(decoded.candidates).map(fn(candidate) {
    message_id(p, native(candidate.message))
  })
  actual.sort()
  assert_eq(actual, expected)
  assert_true(check_interpolation(plan, word(received), decoded.interpolation))
  assert_true(check_witnesses(plan, word(received), decoded))
  for candidate in @oracle.array(decoded.candidates) {
    assert_true(check_candidate(plan, word(received), candidate))
  }
  decoded
}

///|
test "Sudan multiplicity one exhausts all received words over F5 length four" {
  let plan = test_plan(5, [0, 1, 2, 3], 2, 3, 1, 2)
  for received in 0..<625 {
    ignore(assert_oracle(plan, 5, digits(received, 5, 4)))
  }
}

///|
test "Guruswami Sudan multiplicity two exhausts all received words over F3 length three" {
  let plan = test_plan(3, [0, 1, 2], 2, 2, 2, 3)
  assert_eq(@oracle.int_of_nat(@core.length(monomials(plan))), 10)
  assert_eq(@oracle.int_of_nat(constraint_count(plan)), 9)
  let mut multiple = 0
  for received in 0..<27 {
    let decoded = assert_oracle(plan, 3, digits(received, 3, 3))
    if @oracle.int_of_nat(@core.length(decoded.candidates)) > 1 {
      multiple += 1
    }
  }
  assert_true(multiple > 0)
}

///|
test "F11 length nine dimension three multiplicity two decodes radius four" {
  let plan = test_plan(11, [0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 5, 2, 9)
  assert_eq(@oracle.int_of_nat(@core.length(monomials(plan))), 30)
  assert_eq(@oracle.int_of_nat(constraint_count(plan)), 27)
  let sent = native_codeword(11, native(points(plan)), [3, 2, 4])
  let received = sent.copy()
  for position in [0, 2, 5, 8] {
    received[position] = (received[position] + position + 1) % 11
  }
  let decoded = assert_oracle(plan, 11, received)
  assert_true(
    @oracle.array(decoded.candidates).any(fn(candidate) {
      native(candidate.message) == [3, 2, 4]
    }),
  )
  assert_eq(native_count(sent, received), 5)
  assert_true(4 > (9 - 3) / 2)
}

///|
fn native_choose(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  for i = 1, value = 1; i <= k; {
    continue i + 1, value * (n - i + 1) / i
  } nobreak {
    value
  }
}

///|
fn native_power(p : Int32, value : Int32, exponent : Int32) -> Int32 {
  for i = 0, result = 1; i < exponent; {
    continue i + 1, result * value % p
  } nobreak {
    result
  }
}

///|
// Expand each monomial after the full translation x->x+a,y->y+b using integer
// binomial coefficients. This independently checks the kernel Hasse matrix.
fn assert_native_interpolation(
  plan : Plan,
  received : Array[Int32],
  polynomial : Interpolation,
) -> Unit raise {
  let p = @oracle.int_of_binary(@modular.value(@primefield.modulus(plan.field)))
  let s = @oracle.int_of_nat(plan.multiplicity)
  let bound = @oracle.int_of_nat(plan.degree_bound)
  let weight = @oracle.int_of_nat(plan.dimension) - 1
  let xs = native(plan.points)
  let terms = @oracle.array(polynomial.terms)
  assert_true(terms.length() > 0)
  for term in terms {
    let a = @oracle.int_of_nat(term.monomial.x)
    let b = @oracle.int_of_nat(term.monomial.y)
    assert_true(a + weight * b <= bound)
    assert_true(@oracle.int_of_binary(term.coefficient) > 0)
    assert_true(@oracle.int_of_binary(term.coefficient) < p)
  }
  for i in 0..<xs.length() {
    for u in 0..<s {
      for v in 0..<(s - u) {
        let mut coefficient = 0
        for term in terms {
          let a = @oracle.int_of_nat(term.monomial.x)
          let b = @oracle.int_of_nat(term.monomial.y)
          if a >= u && b >= v {
            coefficient = (
                coefficient +
                @oracle.int_of_binary(term.coefficient) *
                native_choose(a, u) *
                native_choose(b, v) *
                native_power(p, xs[i], a - u) *
                native_power(p, received[i], b - v)
              ) %
              p
          }
        }
        assert_eq(coefficient, 0)
      }
    }
  }
}

///|
test "multiplicity two produces a genuine ambiguous F11 list beyond unique decoding" {
  let plan = test_plan(11, [0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 5, 2, 9)
  // x(x-1) and zero agree at two support points. Mix their remaining values.
  let other = native_codeword(11, native(points(plan)), [0, 10, 1])
  let received = [0, 0, 3, 0, 0, 0, 8, 9, 1]
  let decoded = assert_oracle(plan, 11, received)
  let ids = @oracle.array(decoded.candidates).map(fn(candidate) {
    message_id(11, native(candidate.message))
  })
  assert_true(ids.contains(0))
  assert_true(ids.contains(message_id(11, [0, 10, 1])))
  assert_true(ids.length() >= 2)
  assert_eq(native_count([0, 0, 0, 0, 0, 0, 0, 0, 0], received), 5)
  assert_eq(native_count(other, received), 5)
  assert_native_interpolation(plan, received, decoded.interpolation)
  assert_true(@oracle.int_of_nat(decoded.nodes) < 100)
}

///|
test "fuel exhaustion stays suspended and resumed candidate sets equal uninterrupted search" {
  let plan = test_plan(3, [0, 1, 2], 2, 2, 2, 3)
  let received = [0, 0, 1]
  let initial = required(start(plan, word(received)))
  assert_eq(@oracle.int_of_nat(nodes_visited(initial)), 0)
  match required(advance(initial, @oracle.nat(0))) {
    Suspended(search) => {
      assert_eq(@oracle.int_of_nat(nodes_visited(search)), 0)
      assert_eq(@oracle.int_of_nat(@core.length(partial_candidates(search))), 0)
    }
    Complete(_) => fail("zero fuel must not claim complete before search")
  }
  let uninterrupted = complete(plan, received)
  let mut search = initial
  let mut completed = false
  let mut partial_seen = false
  for _ in 0..<100 {
    if !completed {
      let visited = @oracle.int_of_nat(nodes_visited(search))
      match required(advance(search, @oracle.nat(1))) {
        Suspended(next) => {
          assert_eq(@oracle.int_of_nat(nodes_visited(next)), visited + 1)
          let partial = @oracle.array(partial_candidates(next))
          for candidate in partial {
            assert_true(check_candidate(plan, word(received), candidate))
          }
          if partial.length() > 0 {
            partial_seen = true
          }
          search = next
        }
        Complete(decoded) => {
          assert_eq(decoded, uninterrupted)
          completed = true
        }
      }
    }
  }
  assert_true(completed)
  assert_true(partial_seen)
  // An opaque continuation carries its own word/plan; replay is deterministic.
  match required(advance(initial, @oracle.nat(100))) {
    Complete(decoded) => assert_eq(decoded, uninterrupted)
    _ => fail("continuation replay")
  }
}

///|
test "Hasse derivatives remain correct when factorials vanish in small characteristic" {
  let field = match @primefield.field(@oracle.binary(2)) {
    Some(field) => field
    None => abort("Hasse field")
  }
  let square = {
    terms: @oracle.chain([
      {
        coefficient: @oracle.binary(1),
        monomial: { x: @oracle.nat(2), y: @oracle.nat(0), },
      },
    ]),
  }
  assert_eq(
    @oracle.int_of_binary(
      hasse(
        field,
        square,
        { x: @oracle.nat(1), y: @oracle.nat(0), },
        @oracle.binary(1),
        @oracle.binary(0),
      ),
    ),
    0,
  )
  assert_eq(
    @oracle.int_of_binary(
      hasse(
        field,
        square,
        { x: @oracle.nat(2), y: @oracle.nat(0), },
        @oracle.binary(1),
        @oracle.binary(0),
      ),
    ),
    1,
  )
  for fixture in [(2, 2, 3, 5), (3, 2, 3, 5), (3, 2, 4, 7)] {
    let (p, a, s, d) = fixture
    let n = p
    let plan = test_plan(p, [ for x in 0..<n => x ], 2, a, s, d)
    let words = for i = 0, count = 1; i < n; {
      continue i + 1, count * p
    } nobreak {
      count
    }
    for received in 0..<words {
      let values = digits(received, p, n)
      let decoded = assert_oracle(plan, p, values)
      assert_native_interpolation(plan, values, decoded.interpolation)
    }
  }
}

///|
test "empty complete lists and errors outside the requested radius have explicit meaning" {
  let plan = test_plan(5, [0, 1, 2, 3], 2, 3, 1, 2)
  let mut empty = 0
  for received in 0..<625 {
    let decoded = complete(plan, digits(received, 5, 4))
    if @core.is_zero(@core.length(decoded.candidates)) {
      empty += 1
    }
  }
  assert_eq(empty, 200)
  let large = test_plan(11, [0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 5, 2, 9)
  let received = [1, 1, 1, 1, 1, 0, 0, 0, 0]
  let decoded = assert_oracle(large, 11, received)
  assert_false(
    @oracle.array(decoded.candidates).any(fn(candidate) {
      native(candidate.message) == [0, 0, 0]
    }),
  )
  assert_native_interpolation(large, received, decoded.interpolation)
}

///|
test "strict bounds and canonical complete alphabets reject invalid plans and symbols" {
  let field = match @primefield.field(@oracle.binary(5)) {
    Some(field) => field
    None => abort("test prime")
  }
  let alpha = word([0, 1, 2, 3, 4])
  let xs = word([0, 1, 2, 3])
  for
    alphabet in [
      word([0, 1, 2, 3]),
      word([0, 1, 2, 3, 3]),
      word([0, 1, 2, 3, 5]),
      word([0, 1, 2, 3, 4, 4]),
    ] {
    assert_eq(
      plan(
        field,
        alphabet,
        xs,
        @oracle.nat(2),
        @oracle.nat(3),
        @oracle.nat(1),
        @oracle.nat(2),
      ),
      Err(InvalidAlphabet),
    )
  }
  assert_eq(
    plan(
      field,
      alpha,
      word([0, 1, 1, 3]),
      @oracle.nat(2),
      @oracle.nat(3),
      @oracle.nat(1),
      @oracle.nat(2),
    ),
    Err(DuplicatePoint),
  )
  assert_eq(
    plan(
      field,
      alpha,
      word([0, 1, 2, 5]),
      @oracle.nat(2),
      @oracle.nat(3),
      @oracle.nat(1),
      @oracle.nat(2),
    ),
    Err(NoncanonicalSymbol),
  )
  for
    fixture in [
      (0, 3, 1, 2),
      (1, 3, 1, 2),
      (5, 3, 1, 2),
      (2, 0, 1, 2),
      (2, 5, 1, 2),
      (2, 3, 0, 2),
      (2, 3, 1, 3),
      (2, 3, 1, 1),
    ] {
    let (k, a, s, d) = fixture
    assert_eq(
      plan(
        field,
        alpha,
        xs,
        @oracle.nat(k),
        @oracle.nat(a),
        @oracle.nat(s),
        @oracle.nat(d),
      ),
      Err(InvalidPlan),
    )
  }
  let plan = test_plan(5, [0, 1, 2, 3], 2, 3, 1, 2)
  for values in [[], [0], [0, 0, 0], [0, 0, 0, 0, 0]] {
    assert_eq(interpolate(plan, word(values)), Err(LengthMismatch))
    match start(plan, word(values)) {
      Err(LengthMismatch) => ()
      _ => fail("invalid start length")
    }
  }
  assert_eq(interpolate(plan, word([0, 0, 0, 5])), Err(NoncanonicalSymbol))
  assert_eq(encode(plan, word([0, 5])), Err(NoncanonicalSymbol))
  assert_eq(encode(plan, word([0])), Err(LengthMismatch))
}

///|
test "witness checkers reject malformed interpolation and candidates without claiming completeness" {
  let plan = test_plan(5, [0, 1, 2, 3], 2, 3, 1, 2)
  let received = [0, 1, 2, 3]
  let decoded = complete(plan, received)
  let candidate = match decoded.candidates {
    Cons(value, _) => value
    _ => abort("candidate")
  }
  assert_true(check_witnesses(plan, word(received), decoded))
  assert_false(
    check_candidate(plan, word(received), {
      ..candidate,
      agreements: @oracle.nat(3),
    }),
  )
  assert_false(
    check_candidate(plan, word(received), {
      ..candidate,
      message: word([0, 0]),
    }),
  )
  assert_false(
    check_candidate(plan, word(received), {
      ..candidate,
      message: word([0, 1, 0]),
    }),
  )
  assert_false(
    check_candidate(plan, word(received), {
      ..candidate,
      codeword: word([0, 0, 0, 0]),
    }),
  )
  assert_false(
    check_witnesses(plan, word(received), {
      ..decoded,
      candidates: @core.append(decoded.candidates, decoded.candidates),
    }),
  )
  // This checker promises soundness only; completeness comes from exhausted RR.
  assert_true(
    check_witnesses(plan, word(received), { ..decoded, candidates: @core.Nil, }),
  )
  assert_false(check_interpolation(plan, word(received), { terms: @core.Nil, }))
  let first = match decoded.interpolation.terms {
    Cons(first, _) => first
    _ => abort("Q term")
  }
  assert_false(
    check_interpolation(plan, word(received), {
      terms: @core.append(
        decoded.interpolation.terms,
        @core.Cons(first, @core.Nil),
      ),
    }),
  )
  assert_false(
    check_interpolation(plan, word(received), {
      terms: @core.Cons({ ..first, coefficient: @oracle.binary(5), }, @core.Nil),
    }),
  )
  assert_false(
    check_interpolation(plan, word(received), {
      terms: @core.Cons(
        {
          coefficient: @oracle.binary(1),
          monomial: { x: @oracle.nat(3), y: @oracle.nat(0), },
        },
        @core.Nil,
      ),
    }),
  )
}

///|
fn assert_fixture(
  p : Int32,
  xs : Array[Int32],
  k : Int32,
  a : Int32,
  s : Int32,
  d : Int32,
  received : Array[Int32],
  expected : Array[Array[Int32]],
) -> Unit raise {
  let plan = test_plan(p, xs, k, a, s, d)
  assert_true(valid(validate(plan)))
  let decoded = complete(plan, received)
  let actual = @oracle.array(decoded.candidates).map(fn(candidate) {
    message_id(p, native(candidate.message))
  })
  let expected = expected.map(fn(message) { message_id(p, message) })
  actual.sort()
  expected.sort()
  assert_eq(actual, expected)
  assert_true(check_witnesses(plan, word(received), decoded))
  assert_native_interpolation(plan, received, decoded.interpolation)
}

///|
test "RR repeated constant roots split into distinct slopes and preserve the zero coefficient" {
  let plan = test_plan(3, [0, 1, 2], 2, 2, 2, 3)
  let received = word([0, 1, 1])
  // Q=(y-x)(y-2x)(y-1)=y^3+2y^2+2x^2y+x^2 over F3.
  // Q(0,y) has a repeated root0; its next coefficient splits into1 and2.
  let polynomial = {
    terms: @oracle.chain([
      {
        coefficient: @oracle.binary(2),
        monomial: { x: @oracle.nat(0), y: @oracle.nat(2), },
      },
      {
        coefficient: @oracle.binary(1),
        monomial: { x: @oracle.nat(0), y: @oracle.nat(3), },
      },
      {
        coefficient: @oracle.binary(1),
        monomial: { x: @oracle.nat(2), y: @oracle.nat(0), },
      },
      {
        coefficient: @oracle.binary(2),
        monomial: { x: @oracle.nat(2), y: @oracle.nat(1), },
      },
    ]),
  }
  assert_true(check_interpolation(plan, received, polynomial))
  assert_native_interpolation(plan, [0, 1, 1], polynomial)
  let initial = required(start(plan, received))
  let search = {
    ..initial,
    interpolation: polynomial,
    pending: @core.Cons(
      {
        polynomial: normalize(polynomial),
        reversed_prefix: @core.Nil,
        remaining: plan.dimension,
      },
      @core.Nil,
    ),
  }
  let decoded = match required(advance(search, @oracle.nat(100))) {
    Complete(value) => value
    _ => abort("RR repeated root budget")
  }
  let ids = @oracle.array(decoded.candidates).map(fn(candidate) {
    message_id(3, native(candidate.message))
  })
  ids.sort()
  assert_eq(ids, [1, 3, 6])
  assert_true(check_witnesses(plan, received, decoded))
  let zero_child = substitute(plan.field, polynomial, @oracle.binary(0))
  // Removed the exact lowest x power; normalization leaves an x^0 term.
  assert_true(
    @oracle.array(zero_child.terms).any(fn(term) {
      @oracle.int_of_nat(term.monomial.x) == 0
    }),
  )
}

///|
test "RR rejects a finite prefix that cannot extend to an exact polynomial root" {
  let plan = test_plan(3, [0, 1, 2], 2, 2, 2, 3)
  // y-x^2 has constant and linear coefficients0 but degree2 is outside k2.
  // The leaf prefix0 must be rejected by exact Q(x,0) composition.
  let polynomial = {
    terms: @oracle.chain([
      {
        coefficient: @oracle.binary(1),
        monomial: { x: @oracle.nat(0), y: @oracle.nat(1), },
      },
      {
        coefficient: @oracle.binary(2),
        monomial: { x: @oracle.nat(2), y: @oracle.nat(0), },
      },
    ]),
  }
  let initial = required(start(plan, word([0, 0, 0])))
  let search = {
    ..initial,
    interpolation: polynomial,
    pending: @core.Cons(
      {
        polynomial: normalize(polynomial),
        reversed_prefix: @core.Nil,
        remaining: plan.dimension,
      },
      @core.Nil,
    ),
  }
  match required(advance(search, @oracle.nat(100))) {
    Complete(decoded) =>
      assert_eq(@oracle.int_of_nat(@core.length(decoded.candidates)), 0)
    _ => fail("finite prefix search must terminate")
  }
}

///|
test "plan validation exposes every sufficient degree and enumeration condition" {
  let good = test_plan(11, [0, 1, 2, 3, 4, 5, 6, 7, 8], 3, 5, 2, 9)
  assert_true(valid(validate(good)))
  assert_false(valid(validate({ ..good, alphabet: word([0, 1]), })))
  assert_false(
    valid(validate({ ..good, points: word([0, 1, 1, 3, 4, 5, 6, 7, 8]), })),
  )
  assert_false(valid(validate({ ..good, dimension: @oracle.nat(1), })))
  assert_false(valid(validate({ ..good, agreements: @oracle.nat(4), })))
  assert_false(valid(validate({ ..good, multiplicity: @oracle.nat(0), })))
  assert_false(valid(validate({ ..good, degree_bound: @oracle.nat(10), })))
  assert_false(valid(validate({ ..good, monomials: @core.Nil, })))
  assert_false(valid(validate({ ..good, derivatives: @core.Nil, })))
  // Alphabet order affects traversal only; it does not reduce the root set.
  let reverse = required(
    plan(
      good.field,
      @core.reverse(good.alphabet),
      good.points,
      good.dimension,
      good.agreements,
      good.multiplicity,
      good.degree_bound,
    ),
  )
  let received = [0, 0, 0, 0, 0, 9, 8, 9, 1]
  let forward = complete(good, received)
  let backward = complete(reverse, received)
  let first = @oracle.array(forward.candidates).map(fn(candidate) {
    message_id(11, native(candidate.message))
  })
  let second = @oracle.array(backward.candidates).map(fn(candidate) {
    message_id(11, native(candidate.message))
  })
  first.sort()
  second.sort()
  assert_eq(first, second)
}
