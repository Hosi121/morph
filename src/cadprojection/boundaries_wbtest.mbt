///|
fn test_poly(
  arity : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  elimination_poly(arity, terms.map(fn(t) { (@oracle.rational(t.0, 1), t.1) }))
}

///|
fn test_atoms() -> @core.Chain[@poly.Polynomial] {
  @oracle.chain([
    test_poly(2, [(1, [0, 2]), (-1, [1, 0])]),
    test_poly(2, [(1, [0, 1]), (-1, [0, 0])]),
  ])
}

///|
fn change_top(proof : Certificate, alter : (Level) -> Level) -> Certificate {
  {
    ..proof,
    levels: @core.map(proof.levels, fn(entry) {
      if entry.arity == proof.arity {
        alter(entry)
      } else {
        entry
      }
    }),
  }
}

///|
test "hierarchy source arity order and detached payload are bound" {
  let atoms = test_atoms()
  let n = @oracle.nat(2)
  let plan = prepare(n, atoms).unwrap()
  let proof = certificate(plan)
  assert_true(check(n, atoms, proof))
  assert_true(checked(n, atoms, proof) is Some(_))
  assert_false(check(@oracle.nat(1), atoms, proof))
  assert_false(check(n, @core.reverse(atoms), proof))
  assert_false(check(n, @core.Cons(@poly.zero(n), atoms), proof))
  assert_false(check(n, atoms, { ..proof, arity: @oracle.nat(3), }))
  assert_false(check(n, atoms, { ..proof, atoms: @core.Nil, }))
  assert_false(
    check(n, atoms, { ..proof, levels: @core.reverse(proof.levels), }),
  )
  assert_false(
    check(n, atoms, {
      ..proof,
      levels: @core.drop(@oracle.nat(1), proof.levels),
    }),
  )
  let foreign = prepare(n, @core.Nil).unwrap()
  assert_false(check_result(n, atoms, foreign, proof))
  assert_true(checked(n, atoms, certificate(foreign)) is None)
  assert_false(
    check(n, atoms, change_top(proof, fn(t) { { ..t, source: @core.Nil, } })),
  )
  assert_false(
    check(
      n,
      atoms,
      change_top(proof, fn(t) { { ..t, arity: @oracle.nat(1), } }),
    ),
  )
}

///|
test "certificate rejects missing derivative bindings closure and PSC rows" {
  let atoms = test_atoms()
  let n = @oracle.nat(2)
  let plan = prepare(n, atoms).unwrap()
  let proof = certificate(plan)
  assert_false(
    check(n, atoms, change_top(proof, fn(t) { { ..t, family: t.source, } })),
  )
  assert_false(
    check(
      n,
      atoms,
      change_top(proof, fn(t) { { ..t, derivatives: @core.Nil, } }),
    ),
  )
  assert_false(
    check(n, atoms, change_top(proof, fn(t) { { ..t, bindings: @core.Nil, } })),
  )
  assert_false(
    check(n, atoms, change_top(proof, fn(t) { { ..t, projection: None, } })),
  )
  let top = level(plan, n).unwrap()
  let projection = top.projection.unwrap()
  for
    bad in [
      ProjectionCertificate::{ ..projection, coefficients: @core.Nil, },
      ProjectionCertificate::{ ..projection, reducta: @core.Nil, },
      ProjectionCertificate::{ ..projection, principal: @core.Nil, },
      ProjectionCertificate::{ ..projection, arity: @oracle.nat(3), },
      ProjectionCertificate::{ ..projection, atoms: @core.Nil, },
    ] {
    assert_false(check_projection(n, top.family, bad))
    assert_false(
      check(
        n,
        atoms,
        change_top(proof, fn(t) { { ..t, projection: Some(bad), } }),
      ),
    )
  }
  let rows = @oracle.array(projection.principal)
  let row = rows[0]
  let false_value = @poly.zero(@oracle.nat(1))
  assert_false(
    check_projection(n, top.family, {
      ..projection,
      principal: @core.Cons(
        { ..row, values: @core.Cons(false_value, @core.Nil), },
        @core.Nil,
      ),
    }),
  )
  assert_false(
    check(n, atoms, {
      ..proof,
      levels: @core.map(proof.levels, fn(t) {
        if t.arity == @oracle.nat(1) {
          { ..t, source: @core.Nil, }
        } else {
          t
        }
      }),
    }),
  )
}

///|
test "original signs preserve duplicates constants zero and sign orientation" {
  let n = @oracle.nat(1)
  let p = test_poly(1, [(1, [2]), (-2, [1]), (1, [0])])
  let original = @oracle.chain([
    p,
    @poly.negate(p),
    p,
    @poly.zero(n),
    @poly.constant(n, @oracle.rational(-3, 2)),
    @poly.constant(n, @oracle.rational(7, 1)),
  ])
  let plan = prepare(n, original).unwrap()
  let top = level(plan, n).unwrap()
  assert_eq(@oracle.array(top.family).length(), 4)
  for point in [-2, 0, 1, 3] {
    let args = @oracle.chain([@oracle.rational(point, 1)])
    let sign = fn(poly : @poly.Polynomial) {
      @exact.rational_compare(
        @poly.evaluate(poly, args).unwrap(),
        @exact.rational_zero(),
      )
    }
    let signs = @core.map(top.family, sign)
    assert_eq(source_signs(top, signs), Some(@core.map(original, sign)))
    assert_true(source_signs(top, @core.Cons(@core.Equal, signs)) is None)
    assert_true(source_signs(top, @core.Nil) is None)
  }
  assert_eq(
    top.bindings,
    @oracle.chain([
      Member(@oracle.nat(0)),
      Member(@oracle.nat(1)),
      Member(@oracle.nat(0)),
      Constant(@core.Equal),
      Constant(@core.Less),
      Constant(@core.Greater),
    ]),
  )
}

///|
test "empty arbitrary arity hierarchy keeps every explicit level" {
  for count in [0, 1, 2, 3, 4, 7] {
    let n = @oracle.nat(count)
    let plan = prepare(n, @core.Nil).unwrap()
    assert_eq(@core.length(levels(plan)), @oracle.nat(count + 1))
    assert_true(
      @core.all(levels(plan), fn(t) {
        t.family == @core.Nil &&
        t.source == @core.Nil &&
        t.bindings == @core.Nil &&
        t.derivatives == @core.Nil
      }),
    )
    assert_true(check(n, @core.Nil, certificate(plan)))
    assert_false(check(@oracle.nat(count + 1), @core.Nil, certificate(plan)))
  }
  assert_true(
    prepare(@oracle.nat(3), @core.Cons(@poly.zero(@oracle.nat(2)), @core.Nil))
    is Err(WrongArity),
  )
  assert_true(full_collins(@oracle.nat(0), @core.Nil) is Err(InvalidVariable))
  assert_true(
    reducta(@poly.zero(@oracle.nat(3)), @oracle.nat(3)) is Err(InvalidVariable),
  )
}

///|
test "terminal PSC uses correct output arity and Collins normalization" {
  for count in [1, 2, 3, 4] {
    let n = @oracle.nat(count)
    let exponents = Array::make(count, 0)
    exponents[count - 1] = 3
    let p = test_poly(count, [(2, exponents), (3, Array::make(count, 0))])
    let projection = full_collins(n, @core.Cons(p, @core.Nil)).unwrap()
    assert_true(
      @core.all(projection.principal, fn(row) {
        @core.last(row.values) ==
        Some(@poly.constant(@oracle.nat(count - 1), @exact.rational_one()))
      }),
    )
    assert_true(
      @core.all(projection_polynomials(projection), fn(q) {
        @poly.variables(q) == @oracle.nat(count - 1)
      }),
    )
  }
}

///|
test "shared zero factor requires higher PSC to retain unique nonzero crossing" {
  let f = test_poly(2, [(1, [0, 2]), (-1, [1, 1]), (-1, [0, 1])])
  let g = test_poly(2, [(1, [0, 2]), (-2, [1, 1]), (-3, [0, 1])])
  let nonzero_atom = test_poly(2, [(1, [0, 1])])
  let projection = full_collins(
    @oracle.nat(2),
    @oracle.chain([f, g, nonzero_atom]),
  ).unwrap()
  let row = @oracle.array(projection.principal).filter(fn(row) {
      row.left == f && row.right == g
    })[0]
  assert_eq(
    row.values,
    @oracle.chain([
      @poly.zero(@oracle.nat(1)),
      test_poly(1, [(-1, [1]), (-2, [0])]),
      @poly.constant(@oracle.nat(1), @exact.rational_one()),
    ]),
  )
  let witness = @oracle.chain([@oracle.rational(-2, 1), @oracle.rational(-1, 1)])
  assert_eq(@poly.evaluate(f, witness), Some(@exact.rational_zero()))
  assert_eq(@poly.evaluate(g, witness), Some(@exact.rational_zero()))
  assert_eq(
    @poly.evaluate(nonzero_atom, witness),
    Some(@oracle.rational(-1, 1)),
  )
  // Exact identity: g-f=-(x+2)y. With y!=0, their simultaneous zeros force x=-2.
  assert_eq(
    @poly.subtract(g, f).unwrap(),
    test_poly(2, [(-1, [1, 1]), (-2, [0, 1])]),
  )
  assert_false(
    check_projection(@oracle.nat(2), projection.atoms, {
      ..projection,
      principal: @core.map(projection.principal, fn(r) {
        if r.left == f && r.right == g {
          { ..r, values: @core.take(@oracle.nat(1), r.values), }
        } else {
          r
        }
      }),
    }),
  )
}

///|
test "sparse reducta include every lower nonzero coefficient degree" {
  let p = test_poly(4, [(1, [1, 0, 0, 4]), (1, [0, 1, 0, 2]), (1, [0, 0, 1, 0])])
  let block = reducta(p, @oracle.nat(3)).unwrap()
  assert_eq(
    block,
    @oracle.chain([
      p,
      test_poly(4, [(1, [0, 1, 0, 2]), (1, [0, 0, 1, 0])]),
      test_poly(4, [(1, [0, 0, 1, 0])]),
    ]),
  )
  assert_eq(reducta(@poly.zero(@oracle.nat(4)), @oracle.nat(3)), Ok(@core.Nil))
  let projection = full_collins(@oracle.nat(4), @core.Cons(p, @core.Nil)).unwrap()
  assert_eq(projection.reducta, @core.Cons(block, @core.Nil))
  assert_eq(@core.length(projection.principal), @oracle.nat(3))
}

///|
test "nullification retains every original atom and derivative coefficient" {
  let f = test_poly(2, [(1, [1, 1]), (-1, [0, 1])])
  let g = test_poly(2, [(1, [0, 1]), (1, [0, 0])])
  let original = @oracle.chain([f, g])
  let plan = prepare(@oracle.nat(2), original).unwrap()
  let top = level(plan, @oracle.nat(2)).unwrap()
  let args = @oracle.chain([@oracle.rational(1, 1), @oracle.rational(0, 1)])
  let signs = @core.map(top.family, fn(p) {
    @exact.rational_compare(
      @poly.evaluate(p, args).unwrap(),
      @exact.rational_zero(),
    )
  })
  assert_eq(
    source_signs(top, signs),
    Some(@oracle.chain([@core.Equal, @core.Greater])),
  )
  assert_true(
    @core.any(top.family, fn(p) {
      p == test_poly(2, [(1, [1, 0]), (-1, [0, 0])])
    }),
  )
  assert_true(
    @core.any(level(plan, @oracle.nat(1)).unwrap().family, fn(p) {
      p == test_poly(1, [(1, [1]), (-1, [0])])
    }),
  )
}
