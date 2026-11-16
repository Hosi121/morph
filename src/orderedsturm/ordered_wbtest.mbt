///|
fn test_r(n : Int32) -> @exact.Rational {
  @oracle.rational(n, 1)
}

///|
fn test_poly(values : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: test_r(values[i]),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_q(n : Int32, d : Int32) -> @exact.Rational {
  @exact.ratio(@oracle.integer(n), @oracle.binary(d)).unwrap()
}

///|
fn test_field(d : Int32, negative : Bool) -> @nf.Field {
  let interval : @sturm.Interval = if negative {
    { lower: test_r(-3), upper: test_r(-1), }
  } else {
    { lower: test_r(1), upper: test_r(3), }
  }
  let input = @real.number({ polynomial: test_poly([-d, 0, 1]), interval, }).unwrap()
  match
    @minimal.normalize(
      input,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("field fixture unresolved")
  }
}

///|
fn test_relative(
  field : @nf.Field,
  values : Array[(Int32, Int32)],
) -> Polynomial {
  polynomial(
    field,
    @oracle.chain(
      values.map(fn(c) { @nf.element(field, test_poly([c.0, c.1])).unwrap() }),
    ),
  ).unwrap()
}

///|
fn test_solution(p : Polynomial, fuel : Int32) -> SolutionSet {
  match
    advance(isolate(system(p).unwrap()).unwrap(), @oracle.nat(fuel)).unwrap() {
    Isolated(value) => value
    Paused(_) => abort("isolation fixture paused")
  }
}

///|
fn test_fixture(
  d : Int32,
  negative : Bool,
  cs : Array[(Int32, Int32)],
  queries : Array[(Int32, Int32, Int32)],
  total : Int32,
  norm : Array[Int32],
  expected_sequence : Array[Array[(Int32, Int32, Int32, Int32)]],
) -> Unit raise {
  let f = test_field(d, negative)
  let p = test_relative(f, cs)
  let before = @nf.embedding(f)
  let s = system(p).unwrap()
  assert_true(check_system(p, system_certificate(s)))
  let expected = @oracle.chain(
    expected_sequence.map(fn(row) {
      @oracle.chain(
        row.map(fn(c) {
          @poly.polynomial(
            @oracle.nat(1),
            @oracle.chain([
              @poly.Term::{
                coefficient: test_q(c.0, c.1),
                exponents: @oracle.chain([@oracle.nat(0)]),
              },
              @poly.Term::{
                coefficient: test_q(c.2, c.3),
                exponents: @oracle.chain([@oracle.nat(1)]),
              },
            ]),
          ).unwrap()
        }),
      )
    }),
  )
  assert_eq(system_certificate(s).sequence, expected)
  for query in queries {
    let interval : @sturm.Interval = {
      lower: test_r(query.0),
      upper: test_r(query.1),
    }
    let count = count_between(s, interval).unwrap()
    assert_eq(count.count, @oracle.nat(query.2))
    assert_true(check_count(s, interval, @oracle.nat(query.2), count))
    assert_false(check_count(s, interval, @oracle.nat(query.2 + 1), count))
  }
  let solution = test_solution(p, 128)
  let proof = solution_certificate(solution)
  assert_eq(@core.length(roots(solution)), @oracle.nat(total))
  assert_true(check_isolation_result(p, solution, proof))
  assert_eq(@nf.embedding(f), before)
  let absolute_system = @sturm.system(test_poly(norm)).unwrap()
  fn walk(rs : @core.Chain[Root]) -> Unit raise {
    match rs {
      Nil => ()
      Cons(root, rest) => {
        let proof = root_certificate(root)
        assert_true(check_root_result(p, root, proof))
        let narrower = refine(root, @oracle.nat(3)).unwrap()
        let a = root_interval(narrower)
        let b = root_interval(root)
        assert_false(@exact.rational_compare(a.lower, b.lower) == Less)
        assert_false(@exact.rational_compare(a.upper, b.upper) == Greater)
        assert_true(check_root_result(p, narrower, root_certificate(narrower)))
        // Every relative root is an absolute norm root; an interval can contain
        // other conjugate roots, so only require a positive absolute count.
        assert_false(
          @sturm.count_between(absolute_system, a.lower, a.upper).unwrap() ==
          @oracle.nat(0),
        )
        walk(rest)
      }
    }
  }
  walk(roots(solution))
  match proof.roots {
    Nil => ()
    Cons(_, rest) => assert_false(check_isolation(p, { ..proof, roots: rest, }))
  }
}

///|
test "selected embeddings exact signs and mismatched context rejected" {
  let f = test_field(2, false)
  let g = test_field(2, true)
  let a = @nf.generator(f).unwrap()
  let b = @nf.generator(g).unwrap()
  let sign = scalar_sign(a).unwrap()
  assert_eq(sign.sign, Greater)
  assert_eq(scalar_sign(b).unwrap().sign, Less)
  assert_true(check_scalar(a, Greater, sign.certificate))
  assert_false(check_scalar(b, Greater, sign.certificate))
  assert_false(check_scalar(a, Less, sign.certificate))
  assert_false(check_scalar(a, Equal, { ..sign.certificate, sign: Equal, }))
  assert_eq(scalar_sign(@nf.zero(f)).unwrap().sign, Equal)
  assert_true(polynomial(f, @oracle.chain([b])) is Err(DifferentField))
  assert_true(add(one(f), one(g)) is Err(DifferentField))
  assert_true(divide(one(f), zero(f)) is Err(ZeroDivisor))
  assert_true(system(zero(f)) is Err(ZeroPolynomial))
}

///|
test "half open rational endpoints repeated roots zero constants" {
  let f = test_field(2, false)
  let p = test_relative(f, [(-1, 0), (3, 0), (-3, 0), (1, 0)])
  let s = system(p).unwrap()
  assert_eq(degree(squarefree(s)), Some(@oracle.nat(1)))
  let left : @sturm.Interval = { lower: test_r(0), upper: test_r(1), }
  let right : @sturm.Interval = { lower: test_r(1), upper: test_r(2), }
  assert_eq(count_between(s, left).unwrap().count, @oracle.nat(1))
  assert_eq(count_between(s, right).unwrap().count, @oracle.nat(0))
  assert_true(
    count_between(s, { lower: left.upper, upper: left.upper, })
    is Err(InvalidInterval),
  )
  let constant = one(f)
  let answer = test_solution(constant, 16)
  assert_eq(@core.length(roots(answer)), @oracle.nat(0))
  assert_true(
    check_isolation_result(constant, answer, solution_certificate(answer)),
  )
}

///|
test "pause resume cover and malformed witnesses" {
  let f = test_field(2, false)
  let p = test_relative(f, [(0, -1), (0, 0), (1, 0)])
  let s = system(p).unwrap()
  let initial = isolate(s).unwrap()
  assert_true(advance(initial, @oracle.nat(0)).unwrap() is Paused(_))
  let after = match advance(initial, @oracle.nat(2)).unwrap() {
    Paused(state) => state
    _ => abort("must pause before bound")
  }
  let answer = match advance(after, @oracle.nat(64)).unwrap() {
    Isolated(value) => value
    _ => abort("resume")
  }
  assert_eq(@core.length(roots(answer)), @oracle.nat(2))
  let proof = solution_certificate(answer)
  assert_true(check_isolation_result(p, answer, proof))
  let other = test_relative(f, [(0, 1), (0, 0), (1, 0)])
  assert_false(check_isolation_result(other, answer, proof))
  assert_false(
    check_isolation(p, {
      ..proof,
      whole: { ..proof.whole, count: @oracle.nat(1), },
    }),
  )
  assert_false(
    check_isolation(p, { ..proof, bound: { ..proof.bound, bound: test_r(1), }, }),
  )
  let raw = system_certificate(s)
  assert_false(check_system(p, { ..raw, sequence: Nil, }))
  assert_false(check_system(p, { ..raw, gcd_quotients: Nil, }))
  assert_false(
    check_system(p, { ..raw, squarefree: @oracle.chain([test_poly([1])]), }),
  )
  match proof.roots {
    Cons(root, Cons(second, _)) => {
      assert_false(
        check_isolation(p, { ..proof, roots: @oracle.chain([second, root]), }),
      )
      let r = root_from_certificate(p, root).unwrap()
      assert_false(check_root_result(p, r, second))
      let fake = { ..root, count: { ..root.count, count: @oracle.nat(2), }, }
      assert_false(check_root(p, fake))
    }
    _ => abort("two roots")
  }
}

///|
test "rational close roots keep endpoint ownership and resumable bisection" {
  let f = test_field(2, false)
  let a = polynomial(
    f,
    @oracle.chain([@nf.rational(f, test_q(-1025, 1024)), @nf.one(f)]),
  ).unwrap()
  let b = test_relative(f, [(-1, 0), (1, 0)])
  let p = multiply(a, b).unwrap()
  let answer = test_solution(p, 128)
  assert_true(check_isolation_result(p, answer, solution_certificate(answer)))
  assert_eq(@core.length(roots(answer)), @oracle.nat(2))
  let s = system(p).unwrap()
  let proof = count_between(s, { lower: test_r(1), upper: test_q(1025, 1024), }).unwrap()
  assert_eq(proof.count, @oracle.nat(1))
}

///|
test "every finite isolation fuel boundary stays explicit" {
  let f = test_field(2, false)
  let p = test_relative(f, [(0, -1), (0, 0), (1, 0)])
  let state = isolate(system(p).unwrap()).unwrap()
  for fuel in 0..<9 {
    match advance(state, @oracle.nat(fuel)).unwrap() {
      Paused(s) => {
        assert_true(fuel < 6)
        match advance(s, @oracle.nat(8)).unwrap() {
          Isolated(answer) =>
            assert_true(
              check_isolation_result(p, answer, solution_certificate(answer)),
            )
          _ => abort("resume boundary")
        }
      }
      Isolated(answer) => {
        assert_true(fuel >= 6)
        assert_true(
          check_isolation_result(p, answer, solution_certificate(answer)),
        )
      }
    }
  }
}

///|
test "degree one and cubic coefficient fields use the same checked entrance" {
  for definition in [[-3, 1], [-2, 0, 0, 1]] {
    let interval : @sturm.Interval = if definition.length() == 2 {
      { lower: test_r(2), upper: test_r(3), }
    } else {
      { lower: test_r(1), upper: test_r(2), }
    }
    let number = @real.number({ polynomial: test_poly(definition), interval, }).unwrap()
    let f = match
      @minimal.normalize(
        number,
        @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
        @oracle.nat(40),
        @oracle.nat(256),
        @oracle.nat(256),
      ).unwrap() {
      @minimal.Normalized(n, proof) =>
        @nf.field_result(n, proof, @oracle.nat(256)).unwrap()
      _ => abort("generic field normalization")
    }
    let p = test_relative(f, [(0, -1), (0, 0), (1, 0)])
    let answer = test_solution(p, 64)
    assert_eq(@core.length(roots(answer)), @oracle.nat(2))
    assert_true(check_isolation_result(p, answer, solution_certificate(answer)))
  }
}
