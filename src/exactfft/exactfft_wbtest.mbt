///|
fn[A] required(result : Result[A, TransformError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("exact FFT test operation")
  }
}

///|
fn[A] algebra_required(result : Result[A, @cyclotomic.CyclotomicError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("exact FFT test algebra")
  }
}

///|
fn test_field(n : Int32) -> @cyclotomic.Field {
  match @cyclotomic.field(@oracle.nat(n)) {
    Some(value) => value
    None => abort("exact FFT test field")
  }
}

///|
fn test_plan(field : @cyclotomic.Field, n : Int32) -> Plan {
  match plan(field, @oracle.nat(n)) {
    Some(value) => value
    None => abort("exact FFT test plan")
  }
}

///|
fn rationals(
  field : @cyclotomic.Field,
  values : Array[Int32],
) -> @core.Chain[@cyclotomic.Element] {
  @oracle.chain(
    values.map(fn(value) {
      @cyclotomic.rational(field, @oracle.rational(value, 1))
    }),
  )
}

///|
fn polynomial_element(
  field : @cyclotomic.Field,
  coefficients : Array[(Int32, Int32)],
) -> @cyclotomic.Element {
  let terms = [
    for exponent in 0..<coefficients.length() => {
      let (numerator, denominator) = coefficients[exponent]
      @polynomial.Term::{
        coefficient: @oracle.rational(numerator, denominator),
        exponents: @core.Cons(@oracle.nat(exponent), Nil),
      }
    }
  ]
  let polynomial = match
    @polynomial.polynomial(@oracle.nat(1), @oracle.chain(terms)) {
    Ok(value) => value
    Err(_) => abort("exact FFT test polynomial")
  }
  algebra_required(@cyclotomic.element(field, polynomial))
}

///|
fn assert_dft_fixture(
  field_order : Int32,
  n : Int32,
  input : Array[Array[(Int32, Int32)]],
  expected : Array[Array[(Int32, Int32)]],
) -> Unit raise {
  let field = test_field(field_order)
  let plan = test_plan(field, n)
  let input = @oracle.chain(
    input.map(fn(values) { polynomial_element(field, values) }),
  )
  let expected = @oracle.chain(
    expected.map(fn(values) { polynomial_element(field, values) }),
  )
  assert_eq(transform(plan, input), Ok(expected))
  assert_eq(dft(plan, input), Ok(expected))
  assert_eq(inverse(plan, expected), Ok(input))
}

///|
test "plan rejects bad sizes and chooses the principal root in an extension field" {
  let field = test_field(16)
  for n in 0..<20 {
    let valid = n > 0 && n <= 16 && (n & (n - 1)) == 0
    assert_eq(plan(field, @oracle.nat(n)) is Some(_), valid)
    if valid {
      let plan = test_plan(field, n)
      assert_eq(size(plan), @oracle.nat(n))
      assert_eq(field_of(plan), field)
      assert_eq(
        root(plan),
        algebra_required(
          @cyclotomic.power(
            @cyclotomic.generator(field),
            @oracle.binary(16 / n),
          ),
        ),
      )
      assert_eq(
        algebra_required(@cyclotomic.power(root(plan), @oracle.binary(n))),
        @cyclotomic.one(field),
      )
    }
  }
}

///|
test "positive exponent convention has an explicit Gaussian rational DFT" {
  let field = test_field(4)
  let plan = test_plan(field, 4)
  let expected = @oracle.chain([
    polynomial_element(field, [(10, 1)]),
    polynomial_element(field, [(-2, 1), (-2, 1)]),
    polynomial_element(field, [(-2, 1)]),
    polynomial_element(field, [(-2, 1), (2, 1)]),
  ])
  let input = rationals(field, [1, 2, 3, 4])
  assert_eq(transform(plan, input), Ok(expected))
  assert_eq(dft(plan, input), Ok(expected))
  assert_eq(inverse(plan, expected), Ok(input))
}

///|
test "radix-two FFT equals the quadratic DFT and both exact round trips hold" {
  for n in [1, 2, 4, 8, 16] {
    let field = test_field(n)
    let plan = test_plan(field, n)
    for family in 0..<6 {
      let input = @oracle.chain(
        [
          for j in 0..<n => {
            let phase = algebra_required(
              @cyclotomic.power(
                @cyclotomic.generator(field),
                @oracle.binary((j * j + family) % n),
              ),
            )
            algebra_required(
              @cyclotomic.add(
                phase,
                @cyclotomic.rational(
                  field,
                  @oracle.rational(j - family, family + 1),
                ),
              ),
            )
          }
        ],
      )
      let transformed = required(transform(plan, input))
      assert_eq(dft(plan, input), Ok(transformed))
      assert_eq(inverse(plan, transformed), Ok(input))
      assert_eq(transform(plan, required(inverse(plan, input))), Ok(input))
    }
  }
}

///|
test "all binary signals up to length four have exact Fourier round trips" {
  for n in [1, 2, 4] {
    let field = test_field(n)
    let plan = test_plan(field, n)
    for code in 0..<(1 << n) {
      let input = rationals(field, [ for j in 0..<n => (code >> j) & 1 ])
      let transformed = required(transform(plan, input))
      assert_eq(dft(plan, input), Ok(transformed))
      assert_eq(inverse(plan, transformed), Ok(input))
    }
  }
}

///|
test "transforms reject wrong lengths and foreign fields before arithmetic" {
  let field = test_field(4)
  let other = test_field(8)
  let plan = test_plan(field, 4)
  for n in [0, 1, 2, 3, 5, 8] {
    let values = @core.replicate(@oracle.nat(n), @cyclotomic.zero(field))
    assert_eq(transform(plan, values), Err(LengthMismatch))
    assert_eq(inverse(plan, values), Err(LengthMismatch))
    assert_eq(dft(plan, values), Err(LengthMismatch))
  }
  let mixed = @oracle.chain([
    @cyclotomic.zero(field),
    @cyclotomic.one(field),
    @cyclotomic.zero(other),
    @cyclotomic.one(field),
  ])
  assert_eq(transform(plan, mixed), Err(FieldMismatch))
  assert_eq(inverse(plan, mixed), Err(FieldMismatch))
  assert_eq(dft(plan, mixed), Err(FieldMismatch))
  let single = test_plan(field, 1)
  assert_eq(
    transform(single, @core.Cons(@cyclotomic.one(other), Nil)),
    Err(FieldMismatch),
  )
}

///|
test "the original twelve arrow equations commute with cyclotomic interpretation" {
  for (m, n) in [(1, 1), (2, 1), (2, 2), (4, 4), (8, 4), (8, 8), (16, 8)] {
    let field = test_field(m)
    let plan = test_plan(field, n)
    let step = @core.replicate(@oracle.nat(m / n), ())
    for family in 0..<4 {
      let signal : @fft.Signal = @oracle.chain(
        [
          for j in 0..<n => {
            if (j + family) % 3 == 0 {
              @core.Nil
            } else {
              @oracle.chain([
                @core.replicate(@oracle.nat((j + family) % m), ()),
                @core.replicate(@oracle.nat((j * j + family + 1) % m), ()),
              ])
            }
          }
        ],
      )
      let interpreted = algebra_required(interpret_signal(field, signal))
      let arrow_fft = match @fft.fft(step, signal) {
        Some(value) => value
        None => abort("valid original arrow FFT")
      }
      assert_eq(
        transform(plan, interpreted),
        Ok(algebra_required(interpret_signal(field, arrow_fft))),
      )
      assert_eq(
        dft(plan, interpreted),
        Ok(algebra_required(interpret_signal(field, @fft.dft(step, signal)))),
      )
      assert_eq(
        inverse(plan, required(transform(plan, interpreted))),
        Ok(interpreted),
      )
    }
  }
}

///|
test "arrow addition and rotation preserve their exact algebraic meaning" {
  let field = test_field(8)
  let a : @fft.Number = @oracle.chain([
    @core.Nil,
    @core.replicate(@oracle.nat(4), ()),
  ])
  assert_eq(interpret_number(field, a), Ok(@cyclotomic.zero(field)))
  let b : @fft.Number = @oracle.chain([
    @core.replicate(@oracle.nat(2), ()),
    @core.replicate(@oracle.nat(9), ()),
  ])
  let rotation = @core.replicate(@oracle.nat(3), ())
  let av = algebra_required(interpret_number(field, a))
  let bv = algebra_required(interpret_number(field, b))
  assert_eq(interpret_number(field, @fft.add(a, b)), @cyclotomic.add(av, bv))
  assert_eq(
    interpret_number(field, @fft.rotate_add(rotation, b, a)),
    @cyclotomic.add(
      av,
      algebra_required(
        @cyclotomic.multiply(
          algebra_required(interpret_arrow(field, rotation)),
          bv,
        ),
      ),
    ),
  )
}
