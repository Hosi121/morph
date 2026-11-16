///|
pub fn polynomial(
  field : Field,
  coefficients : @core.Chain[Scalar],
) -> Result[Polynomial, TowerError] {
  if !@core.all(coefficients, fn(c) { same_field(field, c.field) }) {
    Err(DifferentField)
  } else {
    next(rp_trim(field, @core.map(coefficients, fn(c) { c.value })), fn(
      values,
    ) {
      Ok({ field, values, })
    })
  }
}

///|
pub fn add(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(rp_add(left.field, left.values, right.values), fn(values) {
      Ok({ field: left.field, values, })
    })
  }
}

///|
pub fn subtract(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, TowerError] {
  add(left, negate(right))
}

///|
pub fn multiply(
  left : Polynomial,
  right : Polynomial,
) -> Result[Polynomial, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(rp_multiply(left.field, left.values, right.values), fn(values) {
      Ok({ field: left.field, values, })
    })
  }
}

///|
pub fn scale(
  value : Polynomial,
  scalar : Scalar,
) -> Result[Polynomial, TowerError] {
  if !same_field(value.field, scalar.field) {
    Err(DifferentField)
  } else {
    next(rp_scale(value.field, value.values, scalar.value), fn(values) {
      Ok({ field: value.field, values, })
    })
  }
}

///|
pub fn divide(
  value : Polynomial,
  divisor : Polynomial,
) -> Result[Division, TowerError] {
  if !same_field(value.field, divisor.field) {
    Err(DifferentField)
  } else {
    next(rp_divide(value.field, value.values, divisor.values), fn(pair) {
      let (quotient, remainder) = pair
      Ok({
        quotient: { field: value.field, values: quotient, },
        remainder: { field: value.field, values: remainder, },
      })
    })
  }
}

///|
pub fn monic(value : Polynomial) -> Result[Polynomial, TowerError] {
  next(rp_monic(value.field, value.values), fn(values) {
    Ok({ field: value.field, values, })
  })
}

///|
pub fn derivative(value : Polynomial) -> Result[Polynomial, TowerError] {
  next(rp_derivative(value.field, value.values), fn(values) {
    Ok({ field: value.field, values, })
  })
}

///|
pub fn evaluate(
  value : Polynomial,
  point : Scalar,
) -> Result[Scalar, TowerError] {
  if !same_field(value.field, point.field) {
    Err(DifferentField)
  } else {
    next(rp_evaluate(value.field, value.values, point.value), fn(raw) {
      Ok({ field: value.field, value: raw, })
    })
  }
}

///|
pub fn evaluate_rational(
  value : Polynomial,
  point : @exact.Rational,
) -> Result[Scalar, TowerError] {
  evaluate(value, rational(value.field, point))
}

///|
pub fn polynomial_equal(
  left : Polynomial,
  right : Polynomial,
) -> Result[Bool, TowerError] {
  next(subtract(left, right), fn(delta) { Ok(is_zero(delta)) })
}
