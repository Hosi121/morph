///|
fn perf_polynomial(
  p : Int32,
  width : Int32,
  salt : Int32,
) -> @fppoly.Polynomial {
  @fppoly.polynomial(
    test_prime(p),
    @oracle.chain(
      [
        for i in 0..<width => {
          @oracle.binary(
            if i == width - 1 {
              1
            } else {
              (i * salt + i / 3 + salt) % p
            },
          )
        }
      ],
    ),
  )
}

///|
fn perf_symbol(field : Field, value : Int32) -> Element {
  test_element(field, [ for i in 0..<8 => (value >> i) & 1 ])
}

///|
fn[A] perf_code(result : Result[A, @cyclicrs.CodeError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("performance RS setup")
  }
}

///|
test "finite field fixed nonzero primitive workloads" (b : @bench.T) {
  let a = perf_polynomial(2, 64, 3)
  let divisor = perf_polynomial(2, 32, 7)
  let product = match @fppoly.multiply(a, divisor) {
    Ok(value) => value
    Err(_) => abort("performance polynomial product")
  }
  let ea = perf_polynomial(2, 16, 5)
  let eb = perf_polynomial(2, 14, 7)
  let odd_a = perf_polynomial(5, 64, 3)
  let odd_b = perf_polynomial(5, 32, 7)
  let field = test_field(2, [1, 1, 0, 1, 1, 0, 0, 0, 1])
  let x = perf_symbol(field, 83)
  let y = perf_symbol(field, 202)
  let odd_field = test_field(3, [1, 0, 1])
  let ox = test_element(odd_field, [1, 1])
  let oy = test_element(odd_field, [1, 2])
  b.bench(name="fp2-multiply-64x32", count=5, fn() {
    b.keep(@fppoly.multiply(a, divisor))
  })
  b.bench(name="fp2-divide-95by32", count=5, fn() {
    b.keep(@fppoly.divide(product, divisor))
  })
  b.bench(name="fp2-bezout-16x14", count=5, fn() {
    b.keep(@fppoly.extended_gcd(ea, eb))
  })
  b.bench(name="fp5-multiply-64x32-control", count=5, fn() {
    b.keep(@fppoly.multiply(odd_a, odd_b))
  })
  b.bench(name="gf256-multiply-83x202", count=5, fn() { b.keep(multiply(x, y)) })
  b.bench(name="gf256-inverse-83", count=5, fn() { b.keep(inverse(x)) })
  b.bench(name="gf9-multiply-control", count=5, fn() {
    b.keep(multiply(ox, oy))
  })
}

///|
test "cyclic RS fixed two-error public workloads" (b : @bench.T) {
  for
    (n, modulus) in [(15, [1, 1, 0, 0, 1]), (255, [1, 0, 1, 1, 1, 0, 0, 0, 1])] {
    let field = test_field(2, modulus)
    let root = required(generator(field))
    let plan = perf_code(
      @cyclicrs.plan(
        field,
        root,
        @oracle.nat(n),
        @oracle.nat(n),
        @oracle.nat(2),
      ),
    )
    let q = @oracle.int_of_binary(cardinality(field))
    let message = @oracle.chain(
      [
        for i in 0..<(n - 4) => perf_symbol(field, (i * 29 + i * i + 7) % q)
      ],
    )
    let encoded = perf_code(@cyclicrs.encode(plan, message))
    let values = @oracle.array(encoded)
    values[0] = required(add(values[0], one(field)))
    values[n - 1] = required(add(values[n - 1], perf_symbol(field, q - 1)))
    let received = @oracle.chain(values)
    let decoded = perf_code(@cyclicrs.decode(plan, received))
    assert_eq(decoded.corrected, encoded)
    assert_true(@cyclicrs.check(plan, received, decoded))
    b.bench(name="rs-length-\{n}-t2-decode", count=5, fn() {
      b.keep(@cyclicrs.decode(plan, received))
    })
  }
}
