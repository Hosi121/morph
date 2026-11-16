///|
/// The production kernel is nested; the fixture oracle uses one flat modulus.
fn flat_context(depth : Int32) -> (Field, Scalar) {
  if depth == 0 {
    (rational_field(), s(rational_field(), 2))
  } else {
    let (parent, generator) = flat_context(depth - 1)
    let input = polynomial(
      parent,
      @oracle.chain([
        scalar_negate(generator),
        scalar_zero(parent),
        scalar_one(parent),
      ]),
    ).unwrap()
    let result = adjoin(
      root_in_interval(system(input).unwrap(), interval(1, 2)).unwrap(),
    ).unwrap()
    (result.field, result.generator)
  }
}

///|
fn flat_scalar(
  field : Field,
  generator : Scalar,
  coefficients : Array[(Int32, Int32)],
) -> Scalar {
  coefficients
  .rev()
  .fold(init=scalar_zero(field), fn(acc, coefficient) {
    scalar_add(
      rational(field, q(coefficient.0, coefficient.1)),
      scalar_multiply(generator, acc).unwrap(),
    ).unwrap()
  })
}

///|
fn flat_polynomial(
  field : Field,
  generator : Scalar,
  coefficients : Array[Array[(Int32, Int32)]],
) -> Polynomial {
  polynomial(
    field,
    @oracle.chain(coefficients.map(fn(c) { flat_scalar(field, generator, c) })),
  ).unwrap()
}
