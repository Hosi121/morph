///|
fn perf_division(
  value : Result[@fppoly.Division, @fppoly.PolyError],
) -> @fppoly.Division {
  match value {
    Ok(value) => value
    Err(_) => abort("polynomial identity setup")
  }
}

///|
test "polynomial identities and huge scalar fixed workloads" (b : @bench.T) {
  let huge = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  let scalar_zero = @oracle.binary(0)
  let scalar_one = @oracle.binary(1)
  for p in [2, 3, 5] {
    let value = perf_polynomial(p, 64, 3)
    let divisor = perf_polynomial(p, 32, 7)
    let field = @fppoly.field_of(value)
    let zero = @fppoly.zero(field)
    let one = @fppoly.one(field)
    let division = perf_division(@fppoly.divide(value, one))
    assert_eq(division.quotient, value)
    assert_eq(division.remainder, zero)
    let division = perf_division(@fppoly.divide(zero, value))
    assert_eq(division.quotient, zero)
    assert_eq(division.remainder, zero)
    b.bench(name="poly-zero-div-p\{p}", count=5, fn() {
      b.keep(@fppoly.divide(zero, value))
    })
    b.bench(name="poly-unit-div-p\{p}", count=5, fn() {
      b.keep(@fppoly.divide(value, one))
    })
    b.bench(name="poly-general-div-p\{p}-control", count=5, fn() {
      b.keep(@fppoly.divide(value, divisor))
    })
    if p != 2 {
      let constant = @fppoly.constant(field, @oracle.binary(p - 1))
      let division = perf_division(@fppoly.divide(value, constant))
      let expected = @oracle.array(@fppoly.coefficients(value)).map(fn(
        coefficient,
      ) {
        @oracle.int_of_binary(coefficient) * (p - 1) % p
      })
      assert_eq(
        @oracle.array(@fppoly.coefficients(division.quotient)).map(
          @oracle.int_of_binary,
        ),
        expected,
      )
      assert_eq(division.remainder, zero)
      b.bench(name="poly-constant-div-p\{p}", count=5, fn() {
        b.keep(@fppoly.divide(value, constant))
      })
    }
    b.bench(name="poly-scale-unit-p\{p}-control", count=5, fn() {
      b.keep(@fppoly.scale(value, scalar_one))
    })
    b.bench(name="poly-scale-zero-p\{p}-control", count=5, fn() {
      b.keep(@fppoly.scale(value, scalar_zero))
    })
    b.bench(name="poly-scale-huge-p\{p}-control", count=5, fn() {
      b.keep(@fppoly.scale(value, huge))
    })
  }
  let value = perf_polynomial(7, 64, 3)
  b.bench(name="poly-scale-huge-p7-control", count=5, fn() {
    b.keep(@fppoly.scale(value, huge))
  })
}
