///|
fn test_poly(cs : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<cs.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(cs[i], 1),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn test_p(terms : Array[(Int32, Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(2),
    @oracle.chain(
      terms.map(fn(term) {
        @poly.Term::{
          coefficient: @oracle.rational(term.0, 1),
          exponents: @oracle.chain([@oracle.nat(term.1), @oracle.nat(term.2)]),
        }
      }),
    ),
  ).unwrap()
}

///|
fn test_interval(root : Int32) -> @sturm.Interval {
  { lower: @oracle.rational(root - 1, 1), upper: @oracle.rational(root, 1), }
}

///|
fn test_bound(polynomial : @poly.Polynomial, index : Int32) -> Bound {
  if index == -9 {
    NegativeInfinity
  } else if index == 9 {
    PositiveInfinity
  } else {
    Finite({ polynomial, interval: test_interval(index), })
  }
}

///|
fn test_pattern(
  roots : Array[Int32],
  cs : Array[Int32],
  truth : Array[Bool],
  expected : Array[(Int32, Int32, Bool, Bool)],
) -> Unit raise {
  let p = test_poly(cs)
  let values = assemble(
    p,
    @oracle.chain(roots.map(test_interval)),
    @oracle.chain(truth),
  ).unwrap()
  let components = expected.map(fn(c) {
    Interval::{
      lower: test_bound(p, c.0),
      upper: test_bound(p, c.1),
      lower_closed: c.2,
      upper_closed: c.3,
    }
  })
  assert_eq(values, @oracle.chain(components))
  let samples : Array[@exact.Rational] = []
  if roots.length() == 0 {
    samples.push(@oracle.rational(0, 1))
  } else {
    samples.push(@oracle.rational(roots[0] - 1, 1))
    for i in 0..<roots.length() {
      samples.push(@oracle.rational(roots[i], 1))
      if i + 1 < roots.length() {
        samples.push(@oracle.rational(roots[i] + roots[i + 1], 2))
      }
    }
    samples.push(@oracle.rational(roots[roots.length() - 1] + 1, 1))
  }
  assert_eq(samples.length(), truth.length())
  for i in 0..<samples.length() {
    assert_eq(
      membership(values, @real.rational(samples[i]).unwrap(), @oracle.nat(32)).unwrap(),
      Some(truth[i]),
    )
  }
}

///|
fn test_solved(formula : @base.Formula) -> @cad2.Decomposition {
  let problem = @cad2.prepare(formula).unwrap()
  let budget : @cad2.Budget = {
    primes: @oracle.chain([2, 3, 5, 7, 11, 13, 17, 19].map(@oracle.binary)),
    lifting: @oracle.nat(40),
    subsets: @oracle.nat(1024),
    verification: @oracle.nat(4096),
  }
  match @cad2.run(@cad2.start(problem, budget), @oracle.nat(8192)).unwrap() {
    @cad2.Complete(value) => value
    _ => abort("known CAD fixture did not complete")
  }
}

///|
fn test_circle(
  closed : Bool,
  samples : Array[(Int32, Int32, Bool)],
) -> Unit raise {
  let p = test_p([(1, 2, 0), (1, 0, 2), (-2, 0, 0)])
  let relation : @base.Relation = if closed { EqualZero } else { LessZero }
  let cad = test_solved(@base.Atom(p, relation))
  let set = from_cad2(cad, @cad2.Exists).unwrap()
  let proof = certificate(set)
  assert_true(
    check_result(
      @cad2.problem_of(cad),
      @cad2.Exists,
      set,
      proof,
      @oracle.nat(4096),
    ),
  )
  match intervals(set) {
    Cons(interval, Nil) => {
      assert_eq(interval.lower_closed, closed)
      assert_eq(interval.upper_closed, closed)
      match (interval.lower, interval.upper) {
        (Finite(left), Finite(right)) => {
          let q = test_poly([-2, 0, 1])
          let negative = @real.number({
            polynomial: q,
            interval: {
              lower: @oracle.rational(-2, 1),
              upper: @oracle.rational(-1, 1),
            },
          }).unwrap()
          let positive = @real.number({
            polynomial: q,
            interval: {
              lower: @oracle.rational(1, 1),
              upper: @oracle.rational(2, 1),
            },
          }).unwrap()
          assert_eq(
            contains(set, negative, @oracle.nat(64)).unwrap(),
            Some(closed),
          )
          assert_eq(
            contains(set, positive, @oracle.nat(64)).unwrap(),
            Some(closed),
          )
          assert_true(@real.check_root(left))
          assert_true(@real.check_root(right))
        }
        _ => fail("circle finite endpoints")
      }
    }
    _ => fail("one circle component")
  }
  for sample in samples {
    assert_eq(
      contains(
        set,
        @real.rational(@oracle.rational(sample.0, sample.1)).unwrap(),
        @oracle.nat(64),
      ).unwrap(),
      Some(sample.2),
    )
  }
  assert_eq(
    contains(
      set,
      @real.rational(@oracle.rational(3, 2)).unwrap(),
      @oracle.nat(0),
    ).unwrap(),
    None,
  )
  let universal = from_cad2(cad, @cad2.Forall).unwrap()
  assert_eq(intervals(universal), Nil)
  assert_eq(
    contains(
      universal,
      @real.rational(@oracle.rational(0, 1)).unwrap(),
      @oracle.nat(0),
    ).unwrap(),
    Some(false),
  )
}

///|
test "rational singleton punctures whole line empty and infinity closures" {
  let xy = test_p([(1, 1, 1)])
  let y = test_p([(1, 0, 1)])
  let cad = test_solved(
    @base.Conjunction(@base.Atom(xy, EqualZero), @base.Atom(y, GreaterZero)),
  )
  let singleton = from_cad2(cad, @cad2.Exists).unwrap()
  assert_true(
    check_result(
      @cad2.problem_of(cad),
      @cad2.Exists,
      singleton,
      certificate(singleton),
      @oracle.nat(4096),
    ),
  )
  match intervals(singleton) {
    Cons(interval, Nil) => {
      assert_eq(interval.lower, interval.upper)
      assert_true(interval.lower_closed && interval.upper_closed)
    }
    _ => fail("singleton")
  }
  for (n, want) in [(-1, false), (0, true), (1, false)] {
    assert_eq(
      contains(
        singleton,
        @real.rational(@oracle.rational(n, 1)).unwrap(),
        @oracle.nat(64),
      ).unwrap(),
      Some(want),
    )
  }
  let punctured = test_solved(
    @base.Atom(test_p([(1, 2, 0), (-1, 0, 0)]), NotZero),
  )
  let punctures = from_cad2(punctured, @cad2.Exists).unwrap()
  let punctures_forall = from_cad2(punctured, @cad2.Forall).unwrap()
  assert_eq(intervals(punctures_forall), intervals(punctures))
  assert_true(
    check_result(
      @cad2.problem_of(punctured),
      @cad2.Forall,
      punctures_forall,
      certificate(punctures_forall),
      @oracle.nat(4096),
    ),
  )
  assert_eq(@core.length(intervals(punctures)), @oracle.nat(3))
  assert_true(
    @core.all(intervals(punctures), fn(i) { !i.lower_closed && !i.upper_closed }),
  )
  for (n, want) in [(-2, true), (-1, false), (0, true), (1, false), (2, true)] {
    assert_eq(
      contains(
        punctures,
        @real.rational(@oracle.rational(n, 1)).unwrap(),
        @oracle.nat(64),
      ).unwrap(),
      Some(want),
    )
  }
  for truth in [false, true] {
    let c = test_solved(@base.Truth(truth))
    let set = from_cad2(c, @cad2.Exists).unwrap()
    assert_true(
      check_result(
        @cad2.problem_of(c),
        @cad2.Exists,
        set,
        certificate(set),
        @oracle.nat(4096),
      ),
    )
    assert_eq(
      contains(
        set,
        @real.rational(@oracle.rational(17, 3)).unwrap(),
        @oracle.nat(0),
      ).unwrap(),
      Some(truth),
    )
    match intervals(set) {
      Nil => assert_false(truth)
      Cons(interval, Nil) => {
        assert_true(truth)
        assert_eq(interval.lower, NegativeInfinity)
        assert_eq(interval.upper, PositiveInfinity)
        assert_false(interval.lower_closed || interval.upper_closed)
        assert_true(
          check(
            @cad2.problem_of(c),
            @cad2.Exists,
            {
              ..certificate(set),
              intervals: Cons({ ..interval, lower_closed: true, }, Nil),
            },
            @oracle.nat(4096),
          )
          is None,
        )
      }
      _ => fail("constant shape")
    }
  }
}

///|
test "interval closure missing roots alternate contexts source and quantifier bindings" {
  let p = test_p([(1, 2, 0), (1, 0, 2), (-2, 0, 0)])
  let cad = test_solved(@base.Atom(p, EqualZero))
  let problem = @cad2.problem_of(cad)
  let set = from_cad2(cad, @cad2.Exists).unwrap()
  let proof = certificate(set)
  let interval = match intervals(set) {
    Cons(i, Nil) => i
    _ => abort("one component")
  }
  assert_true(
    check(
      problem,
      @cad2.Exists,
      { ..proof, intervals: Nil, },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      @cad2.Exists,
      { ..proof, intervals: Cons({ ..interval, lower_closed: false, }, Nil), },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      @cad2.Exists,
      { ..proof, intervals: Cons({ ..interval, lower: interval.upper, }, Nil), },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(check(problem, @cad2.Forall, proof, @oracle.nat(4096)) is None)
  assert_true(
    check(
      problem,
      @cad2.Forall,
      { ..proof, quantifier: @cad2.Forall, },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      @cad2.Exists,
      { ..proof, truth: @core.map(proof.truth, fn(b) { !b }), },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(
    check(
      problem,
      @cad2.Exists,
      {
        ..proof,
        cad: { ..proof.cad, base: { ..proof.cad.base, roots: Nil, }, },
      },
      @oracle.nat(4096),
    )
    is None,
  )
  assert_true(check(problem, @cad2.Exists, proof, @oracle.nat(0)) is None)
  let other_problem = @cad2.prepare(@base.Atom(p, LessZero)).unwrap()
  assert_true(
    check(other_problem, @cad2.Exists, proof, @oracle.nat(4096)) is None,
  )
  let universal = from_cad2(cad, @cad2.Forall).unwrap()
  assert_false(
    check_result(problem, @cad2.Exists, universal, proof, @oracle.nat(4096)),
  )
  match interval.lower {
    Finite(root) => {
      let same_value = @real.refine(@real.number(root).unwrap(), @oracle.nat(1)).unwrap()
      let replacement = {
        ..interval,
        lower: Finite(@real.root_certificate(same_value)),
      }
      assert_true(
        check(
          problem,
          @cad2.Exists,
          { ..proof, intervals: Cons(replacement, Nil), },
          @oracle.nat(4096),
        )
        is None,
      )
      let other_definition = @poly.multiply(root.polynomial, test_poly([-3, 1])).unwrap()
      let equivalent : @real.RootCertificate = {
        ..root,
        polynomial: other_definition,
      }
      assert_true(@real.check_root(equivalent))
      assert_eq(
        contains(set, @real.number(equivalent).unwrap(), @oracle.nat(0)).unwrap(),
        Some(true),
      )
      assert_true(
        check(
          problem,
          @cad2.Exists,
          {
            ..proof,
            intervals: Cons({ ..interval, lower: Finite(equivalent), }, Nil),
          },
          @oracle.nat(4096),
        )
        is None,
      )
    }
    _ => fail("finite lower")
  }
  assert_true(assemble(test_poly([1]), Nil, Nil) is Err(MalformedCells))
  assert_true(
    assemble(
      test_poly([0, 1]),
      Cons(
        { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
        Nil,
      ),
      @oracle.chain([true, true, true]),
    )
    is Err(InvalidEndpoint),
  )
}
