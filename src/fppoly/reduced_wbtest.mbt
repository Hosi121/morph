///|
test "canonical arithmetic keeps huge scalar residues and cancellation exact" {
  let huge = @binary.power(@oracle.binary(2), @oracle.binary(1000))
  for p in [3, 5, 7] {
    let field = test_field(p)
    let residue = for i = 0, value = 1; i < 1000; {
      continue i + 1, value * 2 % p
    } nobreak {
      value
    }
    let value = polynomial(field, @oracle.chain([huge, @binary.zero(), huge]))
    assert_eq(native(value), [residue, 0, residue])
    assert_eq(native(scale(value, huge)), [
      residue * residue % p,
      0,
      residue * residue % p,
    ])
    assert_eq(required(add(value, negate(value))), zero(field))
    assert_eq(required(multiply(value, zero(field))), zero(field))
    assert_eq(required(multiply(zero(field), value)), zero(field))
    assert_eq(scale(value, @oracle.binary(p)), zero(field))
    let shifted = test_polynomial(p, [0, 0, residue, 0, residue])
    let divisor = test_polynomial(p, [0, 0, 1])
    let division = required(divide(shifted, divisor))
    assert_eq(division.quotient, value)
    assert_eq(division.remainder, zero(field))
  }
}
