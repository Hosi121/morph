///|
fn polynomial(values : Array[Int32]) -> @poly.Polynomial {
  rational_polynomial(
    @oracle.chain(values.map(fn(x) { @oracle.rational(x, 1) })),
  ).unwrap()
}

///|
fn real_fixture(
  values : Array[Int32],
  lower : @exact.Rational,
  upper : @exact.Rational,
) -> @nf.Field {
  let root : @real.RootCertificate = {
    polynomial: polynomial(values),
    interval: { lower, upper, },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("unresolved fixture")
  }
}

///|
fn finite_fixture(p : Int32, values : Array[Int32]) -> @galois.Field {
  let base = @primefield.field(@oracle.binary(p)).unwrap()
  let f = @fppoly.polynomial(base, @oracle.chain(values.map(@oracle.binary)))
  @galois.extension(f, @fppoly.irreducibility(f).unwrap().unwrap()).unwrap()
}

///|
test "real quotient bridge preserves selected root identity and independent exact products" {
  let fixtures = [
    (
      real_fixture([0, 1], @oracle.rational(-1, 1), @oracle.rational(0, 1)),
      [0, 1],
    ),
    (
      real_fixture([-2, 0, 1], @oracle.rational(1, 1), @oracle.rational(2, 1)),
      [-2, 0, 1],
    ),
    (
      real_fixture(
        [1, 0, -10, 0, 1],
        @oracle.rational(3, 1),
        @oracle.rational(4, 1),
      ),
      [1, 0, -10, 0, 1],
    ),
  ]
  let inputs = [[], [1], [0, 1], [1, -2, 2], [-1, 1, 0, 2]]
  for (source, modulus) in fixtures {
    let extension = real_extension(source).unwrap()
    assert_eq(@nf.embedding(real_source(extension)), @nf.embedding(source))
    for aa in inputs {
      for bb in inputs {
        let a = @nf.element(source, polynomial(aa)).unwrap()
        let b = @nf.element(source, polynomial(bb)).unwrap()
        let qa = enter_real(extension, a).unwrap()
        let qb = enter_real(extension, b).unwrap()
        let product = @q.multiply(qa, qb).unwrap()
        assert_true(
          @nf.equal(
            leave_real(extension, product).unwrap(),
            @nf.multiply(a, b).unwrap(),
          ),
        )
        assert_true(
          @nf.equal(
            leave_real(extension, @q.add(qa, qb).unwrap()).unwrap(),
            @nf.add(a, b).unwrap(),
          ),
        )
        let dense = Array::make(aa.length() + bb.length() + modulus.length(), 0)
        for i in 0..<aa.length() {
          for j in 0..<bb.length() {
            dense[i + j] += aa[i] * bb[j]
          }
        }
        let d = modulus.length() - 1
        for k = dense.length() - 1; k >= d; k = k - 1 {
          let c = dense[k]
          dense[k] = 0
          for j in 0..<d {
            dense[k - d + j] -= c * modulus[j]
          }
        }
        assert_eq(
          @nf.representative(leave_real(extension, product).unwrap()),
          polynomial(Array::makei(d, fn(i) { dense[i] })),
        )
      }
      let a = @nf.element(source, polynomial(aa)).unwrap()
      let qa = enter_real(extension, a).unwrap()
      match (real_inverse(extension, qa).unwrap(), @nf.inverse(a).unwrap()) {
        (None, None) => ()
        (Some(x), Some(y)) =>
          assert_true(@nf.equal(leave_real(extension, x).unwrap(), y))
        _ => fail("inverse differs")
      }
    }
  }
  let positive = real_fixture(
    [-2, 0, 1],
    @oracle.rational(1, 1),
    @oracle.rational(2, 1),
  )
  let ext = real_extension(positive).unwrap()
  let generator = enter_real(ext, @nf.generator(positive).unwrap()).unwrap()
  for
    other in [
      real_fixture([-2, 0, 1], @oracle.rational(-2, 1), @oracle.rational(-1, 1)),
      real_fixture([-2, 0, 1], @oracle.rational(7, 5), @oracle.rational(3, 2)),
    ] {
    let other_ext = real_extension(other).unwrap()
    let other_generator = enter_real(other_ext, @nf.generator(other).unwrap()).unwrap()
    assert_true(!@q.same_context(real_context(ext), real_context(other_ext)))
    assert_true(@q.add(generator, other_generator) is Err(@q.DifferentContext))
    assert_true(
      enter_real(ext, @nf.generator(other).unwrap()) is Err(@q.DifferentContext),
    )
    assert_true(leave_real(ext, other_generator) is Err(@q.DifferentContext))
    assert_true(real_inverse(ext, other_generator) is Err(@q.DifferentContext))
  }
}

///|
test "checked finite quotient adapters match existing carryless and odd prime arithmetic" {
  for
    source in [
      finite_fixture(2, [1, 1, 0, 1]),
      finite_fixture(3, [1, 0, 1]),
      finite_fixture(5, [2, 0, 1]),
    ] {
    let extension = prime_extension(source).unwrap()
    assert_eq(prime_source(extension), source)
    let p = @oracle.int_of_binary(@galois.characteristic(source))
    let d = @oracle.int_of_nat(@galois.degree(source))
    let size = @oracle.int_of_binary(@galois.cardinality(source))
    let elements = Array::makei(size, fn(n) {
      let mut m = n
      let coefficients = Array::makei(d, fn(_) {
        let c = m % p
        m /= p
        @oracle.binary(c)
      })
      @galois.element(
        source,
        @fppoly.polynomial(
          @galois.prime_field(source),
          @oracle.chain(coefficients),
        ),
      ).unwrap()
    })
    for a in elements {
      let qa = enter_prime(extension, a).unwrap()
      match prime_inverse(extension, qa).unwrap() {
        None => assert_true(@galois.is_zero(a))
        Some(x) =>
          assert_eq(
            leave_prime(extension, x).unwrap(),
            @galois.inverse(a).unwrap(),
          )
      }
      for b in elements {
        let qb = enter_prime(extension, b).unwrap()
        assert_eq(
          leave_prime(extension, @q.multiply(qa, qb).unwrap()).unwrap(),
          @galois.multiply(a, b).unwrap(),
        )
        assert_eq(
          leave_prime(extension, @q.add(qa, qb).unwrap()).unwrap(),
          @galois.add(a, b).unwrap(),
        )
      }
    }
    if p == 2 {
      for policy in [@q.Generic, @q.Carryless] {
        let bits = bit_extension(source, policy).unwrap()
        assert_eq(bit_source(bits), source)
        for a in elements {
          let ba = enter_bits(bits, a).unwrap()
          assert_true(@q.same_context(@q.parent(ba), bit_context(bits)))
          for b in elements {
            assert_eq(
              leave_bits(
                bits,
                @q.multiply(ba, enter_bits(bits, b).unwrap()).unwrap(),
              ).unwrap(),
              @galois.multiply(a, b).unwrap(),
            )
          }
          match bit_inverse(bits, ba).unwrap() {
            None => assert_true(@galois.is_zero(a))
            Some(x) =>
              assert_eq(
                leave_bits(bits, x).unwrap(),
                @galois.inverse(a).unwrap(),
              )
          }
        }
      }
    } else {
      assert_true(
        bit_extension(source, @q.Carryless) is Err(@q.InvalidCoefficient),
      )
    }
  }
}

///|
test "field structure forgets to its exact semiring without choosing Bool OR" {
  let field = rational_field()
  let ring = semiring(field)
  let half = @oracle.rational(1, 2)
  assert_eq((ring.plus)(half, half), field.one)
  assert_eq((ring.times)(half, @oracle.rational(2, 1)), ring.one)
}

///|
test "finite adapters reject different prime and different modulus before zero arithmetic" {
  let a = finite_fixture(3, [1, 0, 1])
  let b = finite_fixture(5, [2, 0, 1])
  let qa = prime_extension(a).unwrap()
  let qb = prime_extension(b).unwrap()
  let zero_b = enter_prime(qb, @galois.zero(b)).unwrap()
  assert_true(enter_prime(qa, @galois.zero(b)) is Err(@q.DifferentContext))
  assert_true(leave_prime(qa, zero_b) is Err(@q.DifferentContext))
  assert_true(prime_inverse(qa, zero_b) is Err(@q.DifferentContext))
  assert_true(
    @q.multiply(@q.zero(prime_context(qa)), zero_b) is Err(@q.DifferentContext),
  )
  let c = finite_fixture(2, [1, 1, 0, 1])
  let d = finite_fixture(2, [1, 0, 1, 1])
  let qc = bit_extension(c, @q.Generic).unwrap()
  let qd = bit_extension(d, @q.Carryless).unwrap()
  let zero_d = enter_bits(qd, @galois.zero(d)).unwrap()
  assert_true(enter_bits(qc, @galois.zero(d)) is Err(@q.DifferentContext))
  assert_true(leave_bits(qc, zero_d) is Err(@q.DifferentContext))
  assert_true(bit_inverse(qc, zero_d) is Err(@q.DifferentContext))
  assert_true(
    @q.add(@q.zero(bit_context(qc)), zero_d) is Err(@q.DifferentContext),
  )
}

///|
test "a nonprime characteristic-two coefficient field retains its actual multiplication" {
  let base = finite_fixture(2, [1, 1, 1])
  let z = @galois.zero(base)
  let o = @galois.one(base)
  let w = @galois.generator(base).unwrap()
  let scalars = [z, o, w, @galois.add(o, w).unwrap()]
  let arithmetic : @rowreduce.Field[@galois.Element] = {
    zero: z,
    one: o,
    add: fn(a, b) { @galois.add(a, b).unwrap() },
    subtract: fn(a, b) { @galois.subtract(a, b).unwrap() },
    negate: @galois.negate,
    multiply: fn(a, b) { @galois.multiply(a, b).unwrap() },
    inverse: fn(a) {
      if @galois.is_zero(a) {
        None
      } else {
        Some(@galois.inverse(a).unwrap())
      }
    },
  }
  // T^2 + T + w is irreducible over F4. Generic coefficient arithmetic must
  // keep w^2=w+1, rather than incorrectly using the F2 identity a^2=a.
  let context = @q.context(
    arithmetic,
    base,
    @galois.is_zero,
    fn(a) { base.equal(@galois.field_of(a)) },
    @oracle.chain([w, o, o]),
  ).unwrap()
  let values = Array::makei(16, fn(i) {
    @q.normalize(context, @oracle.chain([scalars[i % 4], scalars[i / 4]])).unwrap()
  })
  fn mul4(a : Int32, b : Int32) -> Int32 {
    let product = (if (a & 1) != 0 { b } else { 0 }) ^
      (if (a & 2) != 0 { b << 1 } else { 0 })
    if (product & 4) != 0 {
      product ^ 7
    } else {
      product
    }
  }
  for i, a in values {
    let inverse = @q.unit_inverse(a).unwrap()
    if i == 0 {
      assert_true(inverse is None)
    } else {
      assert_true(
        @q.equivalent(
          @q.multiply(a, inverse.unwrap()).unwrap(),
          @q.one(context),
        ),
      )
    }
    for j, b in values {
      let c0 = mul4(i % 4, j % 4)
      let c1 = mul4(i % 4, j / 4) ^ mul4(i / 4, j % 4)
      let c2 = mul4(i / 4, j / 4)
      let expected = (c0 ^ mul4(c2, 2)) + 4 * (c1 ^ c2)
      assert_true(@q.equivalent(@q.multiply(a, b).unwrap(), values[expected]))
    }
  }
  let coefficient_w = @q.normalize(context, Cons(w, Nil)).unwrap()
  assert_true(
    !@q.equivalent(
      @q.multiply(coefficient_w, coefficient_w).unwrap(),
      coefficient_w,
    ),
  )
}
