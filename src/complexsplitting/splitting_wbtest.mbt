///|
fn split_poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn split_budget() -> Budget {
  {
    algebra: {
      attempts: @oracle.nat(12),
      work: @oracle.nat(3000),
      coordinate: @oracle.nat(1000),
      comparison: @oracle.nat(1000),
      primes: @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      lift: @oracle.nat(100),
      subset: @oracle.nat(500),
      verification: @oracle.nat(500),
      realization: @oracle.nat(1000),
    },
    primitive: @oracle.nat(12),
  }
}

///|
fn split_finish(state : Search, remaining : Int32) -> Splitting {
  if remaining == 0 {
    abort("finite splitting fixture did not complete")
  }
  match advance(state, split_budget()).unwrap() {
    Ready(value, proof) => {
      assert_true(check_result(source(value), ambient(value), value, proof)) catch {
        _ => abort("bad splitting result")
      }
      value
    }
    Paused(next, _) => split_finish(next, remaining - 1)
  }
}

///|
fn split_real_field(
  coefficients : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @cf.Field {
  let budget = split_budget().algebra
  match
    @minimal.normalize_root(
      {
        polynomial: split_poly(coefficients),
        interval: {
          lower: @oracle.rational(lower, 1),
          upper: @oracle.rational(upper, 1),
        },
      },
      budget.primes,
      budget.lift,
      budget.subset,
      budget.verification,
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, budget.verification).unwrap())
    _ => abort("finite real field must normalize")
  }
}

///|
fn split_quartic_roots(field : @cf.Field) -> @core.Chain[Root] {
  let k = @cf.real_field(field)
  let a = @cf.element(field, @nf.generator(k).unwrap(), @nf.zero(k)).unwrap()
  let ia = @cf.multiply(@cf.imaginary_unit(field), a).unwrap()
  @oracle.chain(
    [a, @cf.negate(a), ia, @cf.negate(ia)].map(fn(value) {
      Root::{ value, multiplicity: @oracle.nat(1), }
    }),
  )
}

///|
test "automatic splitting of Gaussian rational roots keeps the minimal field" {
  for
    fixture in [([1, 0, 1], 2), ([1, 0, 2, 0, 1], 2), ([-1, 0, 1], 1), ([7], 1)] {
    let (coefficients, expected) = fixture
    let p = split_poly(coefficients)
    let value = split_finish(start(p).unwrap(), 12)
    assert_eq(@oracle.int_of_nat(degree(value)), expected)
    assert_true(check_result(p, ambient(value), value, certificate(value)))
    for root in @oracle.array(root_images(value)) {
      assert_true(
        @core.compare(
          polynomial_degree(root.polynomial).unwrap_or(Zero),
          degree(value),
        ).equal(Less),
      )
    }
  }
}

///|
test "automatic cubic unity roots shrink ambient quartic to quadratic" {
  let p = split_poly([-1, 0, 0, 1])
  let value = split_finish(start(p).unwrap(), 12)
  assert_eq(@oracle.int_of_nat(degree(value)), 2)
  assert_eq(@oracle.int_of_nat(@core.length(roots(value))), 3)
  assert_true(check_result(p, ambient(value), value, certificate(value)))
}

///|
test "supplied quartic splitting retains exact degree eight and monic quotient" {
  let field = split_real_field([-2, 0, 0, 0, 1], 1, 2)
  let p = split_poly([-2, 0, 0, 0, 1])
  let values = split_quartic_roots(field)
  let value = split_finish(start_from_roots(p, field, values).unwrap(), 12)
  assert_eq(@oracle.int_of_nat(degree(value)), 8)
  assert_true(
    @cf.check_minimal_polynomial(
      @sub.primitive_element(representation(value)),
      modulus(value),
    ),
  )
  assert_true(
    check_result(
      p,
      field,
      from_certificate(p, field, certificate(value)).unwrap(),
      certificate(value),
    ),
  )
  let images = @oracle.array(root_images(value))
  let originals = @oracle.array(values)
  for index in 0..<images.length() {
    assert_true(
      @cf.equal(
        @sub.from_polynomial(representation(value), images[index].polynomial).unwrap(),
        originals[index].value,
      ),
    )
  }
}

///|
test "wrong multiplicity omitted roots source and primitive payloads are rejected" {
  let field = split_real_field([0, 1], -1, 0)
  let i = @cf.imaginary_unit(field)
  let p = split_poly([1, 0, 1])
  let good = @oracle.chain([
    Root::{ value: i, multiplicity: @oracle.nat(1), },
    Root::{ value: @cf.negate(i), multiplicity: @oracle.nat(1), },
  ])
  let value = split_finish(start_from_roots(p, field, good).unwrap(), 12)
  let proof = certificate(value)
  assert_true(
    start_from_roots(
      p,
      field,
      @oracle.chain([Root::{ value: i, multiplicity: @oracle.nat(2), }]),
    )
    is Err(InvalidRoots),
  )
  assert_true(
    start_from_roots(
      p,
      field,
      @oracle.chain([Root::{ value: i, multiplicity: @oracle.nat(1), }]),
    )
    is Err(InvalidRoots),
  )
  assert_true(
    start_from_roots(
      p,
      field,
      @oracle.chain([
        Root::{ value: i, multiplicity: @oracle.nat(1), },
        Root::{ value: i, multiplicity: @oracle.nat(1), },
      ]),
    )
    is Err(InvalidRoots),
  )
  assert_false(check(split_poly([2, 0, 2]), field, proof))
  assert_false(check(p, field, { ..proof, source: split_poly([-1, 0, 1]), }))
  assert_false(check(p, field, { ..proof, roots: Nil, }))
  assert_false(check(p, field, { ..proof, images: Nil, }))
  assert_false(
    check(p, field, {
      ..proof,
      generated: { ..proof.generated, degree: @oracle.nat(1), },
    }),
  )
  assert_false(
    check(p, field, {
      ..proof,
      primitive: { ..proof.primitive, modulus: split_poly([1, 0, 2, 0, 1]), },
    }),
  )
  let images = @oracle.array(proof.images)
  assert_false(
    check(p, field, {
      ..proof,
      images: @oracle.chain([
        { ..images[0], polynomial: split_poly([0]), },
        images[1],
      ]),
    }),
  )
  assert_false(
    check(p, field, {
      ..proof,
      images: @oracle.chain([
        { ..images[0], multiplicity: @oracle.nat(2), },
        images[1],
      ]),
    }),
  )
  let foreign = split_real_field([-2, 0, 1], 1, 2)
  assert_false(check_result(p, foreign, value, proof))
  let other = split_finish(
    start_from_roots(
      split_poly([-1, 0, 1]),
      field,
      @oracle.chain([
        Root::{ value: @cf.one(field), multiplicity: @oracle.nat(1), },
        Root::{
          value: @cf.negate(@cf.one(field)),
          multiplicity: @oracle.nat(1),
        },
      ]),
    ).unwrap(),
    12,
  )
  assert_false(check_result(p, field, other, proof))
  assert_false(
    check_result(
      p,
      field,
      { ..value, representation: representation(other), },
      proof,
    ),
  )
  assert_true(start(@poly.zero(@oracle.nat(1))) is Err(ZeroPolynomial))
  assert_true(start(@poly.zero(@oracle.nat(2))) is Err(NotUnivariate))
}

///|
test "root work and primitive trials pause with explicit resumable states" {
  let budget = split_budget()
  let p = split_poly([1, 0, 1])
  let initial = start(p).unwrap()
  let paused = match
    advance(initial, { ..budget, algebra: { ..budget.algebra, primes: Nil, }, }).unwrap() {
    Paused(state, FactorizationBudget(_)) => state
    _ => abort("zero-prime factorization should pause")
  }
  assert_eq(@oracle.int_of_nat(degree(split_finish(paused, 12))), 2)
  let field = split_real_field([0, 1], -1, 0)
  let i = @cf.imaginary_unit(field)
  let state = start_from_roots(
    p,
    field,
    @oracle.chain([
      Root::{ value: i, multiplicity: @oracle.nat(1), },
      Root::{ value: @cf.negate(i), multiplicity: @oracle.nat(1), },
    ]),
  ).unwrap()
  let state = match advance(state, { ..budget, primitive: Zero, }).unwrap() {
    Paused(state, PrimitiveTrials) => state
    _ => abort("zero primitive trial budget should pause")
  }
  assert_eq(@oracle.int_of_nat(degree(split_finish(state, 12))), 2)
}
