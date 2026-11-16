///|
struct OracleGaloisFixture {
  mode : Int32
  real_root_sign : Int32
  real_minimum : Array[@exact.Rational]
  lower : @exact.Rational
  upper : @exact.Rational
  polynomial : Array[@exact.Rational]
  roots : Array[Array[@exact.Rational]]
  degree : Int32
  permutations : Array[Array[Int32]]
  table : Array[Array[Int32]]
  identity : Int32
  inverses : Array[Int32]
  actions : Array[Array[Array[@exact.Rational]]]
  samples : Array[Array[@exact.Rational]]
  images : Array[Array[Array[@exact.Rational]]]
  excluded : Array[Array[@exact.Rational]]
}

///|
fn oracle_poly(coefficients : Array[@exact.Rational]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{ coefficient, exponents: Cons(@oracle.nat(index), Nil), }
        }
      ],
    ),
  ).unwrap()
}

///|
fn oracle_split_budget() -> @split.Budget {
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
fn oracle_split_finish(
  progress : @split.Progress,
  rounds : Int32,
) -> @split.Splitting {
  match progress {
    @split.Ready(value, _) => value
    @split.Paused(next, _) => {
      if rounds <= 0 {
        abort("finite oracle splitting search exceeded its bound")
      }
      oracle_split_finish(
        @split.advance(next, oracle_split_budget()).unwrap(),
        rounds - 1,
      )
    }
  }
}

///|
fn oracle_context(fixture : OracleGaloisFixture) -> @cf.Field {
  let budget = oracle_split_budget().algebra
  match
    @minimal.normalize_root(
      {
        polynomial: oracle_poly(fixture.real_minimum),
        interval: { lower: fixture.lower, upper: fixture.upper, },
      },
      budget.primes,
      budget.lift,
      budget.subset,
      budget.verification,
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, budget.verification).unwrap())
    _ => abort("independent Galois source did not normalize")
  }
}

///|
fn oracle_basis(alpha : @nf.Element) -> Array[@cf.Element] {
  let real_field = @nf.parent(alpha)
  let ambient = @cf.field(real_field)
  let a = @cf.element(ambient, alpha, @nf.zero(real_field)).unwrap()
  let real = [@cf.one(ambient)]
  for _ in 1..<@oracle.int_of_nat(@nf.degree(real_field)) {
    real.push(@cf.multiply(real[real.length() - 1], a).unwrap())
  }
  let result = real.copy()
  for value in real {
    result.push(@cf.multiply(@cf.imaginary_unit(ambient), value).unwrap())
  }
  result
}

///|
fn oracle_value(
  basis : Array[@cf.Element],
  coefficients : Array[@exact.Rational],
) -> @cf.Element {
  let ambient = @cf.parent(basis[0])
  let mut value = @cf.zero(ambient)
  for index, coefficient in coefficients {
    value = @cf.add(
      value,
      @cf.multiply(@cf.rational(ambient, coefficient), basis[index]).unwrap(),
    ).unwrap()
  }
  value
}

///|
fn oracle_sign(input : @nf.Element) -> Int32 {
  match @nf.realize(input, @oracle.nat(1000)).unwrap() {
    @nf.RealReady(value, proof) => {
      if !@nf.check_realization_result(input, value, proof) {
        abort("invalid sign realization")
      }
      let zero = @real.rational(@exact.rational_zero()).unwrap()
      match @real.compare(value, zero, @oracle.nat(1000)).unwrap() {
        @real.Compared(order, comparison) => {
          if !@real.check_comparison_result(order, comparison) {
            abort("invalid sign comparison")
          }
          match order {
            Less => -1
            Equal => 0
            Greater => 1
          }
        }
        _ => abort("finite exact sign comparison paused")
      }
    }
    _ => abort("finite exact sign realization paused")
  }
}

///|
fn oracle_alpha(
  split : @split.Splitting,
  fixture : OracleGaloisFixture,
) -> @nf.Element {
  let real_field = @cf.real_field(@split.ambient(split))
  match fixture.mode {
    0 => @nf.generator(real_field).unwrap()
    1 => @nf.zero(real_field)
    2 => {
      let mut selected : @nf.Element? = None
      for root in @oracle.array(@split.roots(split)) {
        if @nf.is_zero(@cf.imaginary_part(root.value)) &&
          oracle_sign(@cf.real_part(root.value)) == 1 {
          selected = Some(@cf.real_part(root.value))
        }
      }
      selected.unwrap()
    }
    3 => {
      let mut real : @nf.Element? = None
      let mut positive_imaginary : @nf.Element? = None
      for root in @oracle.array(@split.roots(split)) {
        let imaginary = @cf.imaginary_part(root.value)
        if @nf.is_zero(imaginary) {
          real = Some(@cf.real_part(root.value))
        } else if oracle_sign(imaginary) == 1 {
          positive_imaginary = Some(imaginary)
        }
      }
      let cube = if fixture.real_root_sign == 1 {
        real.unwrap()
      } else {
        @nf.negate(real.unwrap())
      }
      let imaginary = positive_imaginary.unwrap()
      let sqrt3 = @nf.divide(@nf.add(imaginary, imaginary).unwrap(), cube)
        .unwrap()
        .unwrap()
      if oracle_sign(cube) != 1 || oracle_sign(sqrt3) != 1 {
        abort("cubic source selected wrong signs")
      }
      @nf.add(cube, sqrt3).unwrap()
    }
    _ => abort("unknown independent source mode")
  }
}

///|
fn oracle_splitting(fixture : OracleGaloisFixture) -> @split.Splitting {
  let polynomial = oracle_poly(fixture.polynomial)
  if fixture.mode != 0 {
    return oracle_split_finish(
      @split.solve(polynomial, oracle_split_budget()).unwrap(),
      12,
    )
  }
  let ambient = oracle_context(fixture)
  let basis = oracle_basis(@nf.generator(@cf.real_field(ambient)).unwrap())
  let roots = fixture.roots.map(fn(vector) {
    @split.Root::{
      value: oracle_value(basis, vector),
      multiplicity: @oracle.nat(1),
    }
  })
  oracle_split_finish(
    @split.solve_from_roots(
      polynomial,
      ambient,
      @oracle.chain(roots),
      oracle_split_budget(),
    ).unwrap(),
    12,
  )
}

///|
fn oracle_index(values : Array[@cf.Element], input : @cf.Element) -> Int32 {
  for index, value in values {
    if @cf.equal(value, input) {
      return index
    }
  }
  abort("returned root not in independent complete list")
}

///|
fn oracle_canonical_permutation(
  mapping : Automorphism,
  actual_roots : Array[@cf.Element],
  canonical_roots : Array[@cf.Element],
) -> Array[Int32] {
  let actual = @oracle.array(permutation(mapping)).map(@oracle.int_of_nat)
  let result = Array::make(canonical_roots.length(), -1)
  for index, root in actual_roots {
    result[oracle_index(canonical_roots, root)] = oracle_index(
      canonical_roots,
      actual_roots[actual[index]],
    )
  }
  result
}

///|
fn oracle_permutation_index(
  expected : Array[Array[Int32]],
  actual : Array[Int32],
) -> Int32 {
  for index, permutation in expected {
    if permutation == actual {
      return index
    }
  }
  abort("producer accepted a permutation outside independent group")
}

///|
fn oracle_ambient_coordinates(
  basis : Array[@cf.Element],
  input : @cf.Element,
) -> Array[@exact.Rational] {
  let columns = basis.map(fn(value) { @oracle.array(@cf.coordinates(value)) })
  let rows = [
    for row in 0..<basis.length() => {
      @oracle.chain([ for column in columns => column[row] ])
    }
  ]
  let matrix = @matrix.matrix(@oracle.nat(basis.length()), @oracle.chain(rows)).unwrap()
  match @linear.solve(matrix, @cf.coordinates(input)).unwrap() {
    @linear.Unique(coefficients) => @oracle.array(coefficients)
    _ => abort("independent ambient basis did not span uniquely")
  }
}

///|
fn oracle_action(
  matrix : Array[Array[@exact.Rational]],
  input : Array[@exact.Rational],
) -> Array[@exact.Rational] {
  matrix.map(fn(row) {
    let mut value = @exact.rational_zero()
    for index, coefficient in row {
      value = @exact.rational_add(
        value,
        @exact.rational_multiply(coefficient, input[index]),
      )
    }
    value
  })
}

///|
fn oracle_assert_galois(fixture : OracleGaloisFixture) -> Unit raise {
  let splitting = oracle_splitting(fixture)
  let ambient = @split.ambient(splitting)
  assert_eq(@split.degree(splitting), @oracle.nat(fixture.degree))
  assert_true(
    @split.check_result(
      oracle_poly(fixture.polynomial),
      ambient,
      splitting,
      @split.certificate(splitting),
    ),
  )
  let alpha = oracle_alpha(splitting, fixture)
  assert_eq(
    @nf.minimal_polynomial(alpha).unwrap(),
    oracle_poly(fixture.real_minimum),
  )
  assert_eq(
    oracle_sign(
      @nf.subtract(alpha, @nf.rational(@nf.parent(alpha), fixture.lower)).unwrap(),
    ),
    1,
  )
  assert_true(
    oracle_sign(
      @nf.subtract(alpha, @nf.rational(@nf.parent(alpha), fixture.upper)).unwrap(),
    ) <=
    0,
  )
  let external_basis = oracle_basis(alpha)
  assert_eq(external_basis.length(), 2 * (fixture.real_minimum.length() - 1))
  assert_eq(@cf.degree(ambient), @oracle.nat(external_basis.length()))
  let canonical_roots = fixture.roots.map(fn(vector) {
    oracle_value(external_basis, vector)
  })
  let actual_roots = @oracle.array(@split.roots(splitting)).map(fn(root) {
    root.value
  })
  assert_eq(actual_roots.length(), canonical_roots.length())
  for root in canonical_roots {
    assert_true(actual_roots.any(fn(value) { @cf.equal(root, value) }))
  }
  let pending = match
    advance(start(splitting).unwrap(), @oracle.nat(0)).unwrap() {
    Paused(next) => next
    _ => abort("zero Galois permutation budget must pause")
  }
  let (group, proof) = match advance(pending, @oracle.nat(24)).unwrap() {
    Ready(group, proof) => (group, proof)
    _ => abort("finite Galois permutation fixture did not finish")
  }
  assert_eq(order(group), @oracle.nat(fixture.degree))
  assert_eq(@split.degree(source(group)), @oracle.nat(fixture.degree))
  assert_true(check_result(splitting, group, proof))
  let maps = @oracle.array(automorphisms(group))
  assert_eq(maps.length(), fixture.permutations.length())
  let canonical_indices = maps.map(fn(mapping) {
    oracle_permutation_index(
      fixture.permutations,
      oracle_canonical_permutation(mapping, actual_roots, canonical_roots),
    )
  })
  let producer_indices = Array::make(maps.length(), -1)
  for index, canonical in canonical_indices {
    assert_eq(producer_indices[canonical], -1)
    producer_indices[canonical] = index
  }
  for index in producer_indices {
    assert_true(index >= 0)
  }
  assert_true(equal(identity(group), maps[producer_indices[fixture.identity]]))
  let theta = @sub.primitive_element(@split.representation(splitting))
  let theta_coordinates = oracle_ambient_coordinates(external_basis, theta)
  let expected_images = fixture.actions.map(fn(matrix) {
    oracle_value(external_basis, oracle_action(matrix, theta_coordinates))
  })
  let expected_maps = fixture.permutations.map(fn(p) {
    let actual = actual_roots.map(fn(root) {
      @oracle.nat(
        oracle_index(
          actual_roots,
          canonical_roots[p[oracle_index(canonical_roots, root)]],
        ),
      )
    })
    let index = oracle_permutation_index(fixture.permutations, p)
    MapCertificate::{
      permutation: @oracle.chain(actual),
      image: expected_images[index],
    }
  })
  let expected : Certificate = {
    source: @split.certificate(splitting),
    maps: @oracle.chain(expected_maps),
    table: @oracle.chain(
      fixture.table.map(fn(row) { @oracle.chain(row.map(@oracle.nat)) }),
    ),
    identity: @oracle.nat(fixture.identity),
    inverses: @oracle.chain(fixture.inverses.map(@oracle.nat)),
  }
  assert_true(check(splitting, expected))
  let imported = from_certificate(splitting, expected).unwrap()
  assert_true(check_result(splitting, imported, expected))
  let actual_table = @oracle.array(composition_table(group)).map(@oracle.array)
  let samples = fixture.samples.map(fn(vector) {
    oracle_value(external_basis, vector)
  })
  let sum = @cf.add(samples[0], samples[1]).unwrap()
  let product = @cf.multiply(samples[0], samples[1]).unwrap()
  for index, mapping in maps {
    let canonical = canonical_indices[index]
    assert_true(@cf.equal(generator_image(mapping), expected_images[canonical]))
    assert_true(
      @cf.equal(apply(mapping, theta).unwrap(), expected_images[canonical]),
    )
    assert_true(
      equal(
        inverse(group, mapping).unwrap(),
        maps[producer_indices[fixture.inverses[canonical]]],
      ),
    )
    let action = fixture.permutations[canonical]
    for root_index, root in canonical_roots {
      assert_true(
        @cf.equal(
          apply(mapping, root).unwrap(),
          canonical_roots[action[root_index]],
        ),
      )
    }
    let images = fixture.images[canonical].map(fn(vector) {
      oracle_value(external_basis, vector)
    })
    let actual_left = apply(mapping, samples[0]).unwrap()
    let actual_right = apply(mapping, samples[1]).unwrap()
    assert_true(@cf.equal(actual_left, images[0]))
    assert_true(@cf.equal(actual_right, images[1]))
    assert_true(@cf.equal(apply(mapping, sum).unwrap(), images[2]))
    assert_true(
      @cf.equal(@cf.add(actual_left, actual_right).unwrap(), images[2]),
    )
    assert_true(@cf.equal(apply(mapping, product).unwrap(), images[3]))
    assert_true(
      @cf.equal(@cf.multiply(actual_left, actual_right).unwrap(), images[3]),
    )
    for excluded in fixture.excluded {
      let value = oracle_value(external_basis, excluded)
      assert_false(@sub.contains(@split.generated_field(splitting), value))
      assert_true(apply(mapping, value) is Err(NotInField))
    }
    for right_index, right in maps {
      let expected_index = fixture.table[canonical][canonical_indices[right_index]]
      assert_true(
        equal(
          compose(group, mapping, right).unwrap(),
          maps[producer_indices[expected_index]],
        ),
      )
      assert_eq(
        canonical_indices[@oracle.int_of_nat(actual_table[index][right_index])],
        expected_index,
      )
    }
  }
  let bad_source = {
    ..expected.source,
    source: oracle_poly([@oracle.rational(7, 1)]),
  }
  assert_false(check(splitting, { ..expected, source: bad_source, }))
  assert_false(check_result(splitting, group, { ..proof, maps: Nil, }))
}
