///|
/// Only an ancestor field can be embedded into this exact selected context.
pub fn embed(target : Field, value : Scalar) -> Result[Scalar, TowerError] {
  if same_field(target, value.field) {
    Ok(value)
  } else {
    match target.context {
      Rationals => Err(DifferentField)
      Extension(parent, _, _) =>
        next(embed(parent, value), fn(embedded) {
          Ok({
            field: target,
            value: Fraction(
              Cons(embedded.value, Nil),
              Cons(raw_one(parent), Nil),
            ),
          })
        })
    }
  }
}

///|
pub fn scalar_add(left : Scalar, right : Scalar) -> Result[Scalar, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(raw_add(left.field, left.value, right.value), fn(value) {
      Ok({ field: left.field, value, })
    })
  }
}

///|
pub fn scalar_subtract(
  left : Scalar,
  right : Scalar,
) -> Result[Scalar, TowerError] {
  scalar_add(left, scalar_negate(right))
}

///|
pub fn scalar_multiply(
  left : Scalar,
  right : Scalar,
) -> Result[Scalar, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(raw_multiply(left.field, left.value, right.value), fn(value) {
      Ok({ field: left.field, value, })
    })
  }
}

///|
/// Nonzero is checked at the selected root, rather than in the quotient ring.
pub fn scalar_inverse(value : Scalar) -> Result[Scalar, TowerError] {
  next(raw_inverse(value.field, value.value), fn(raw) {
    Ok({ field: value.field, value: raw, })
  })
}

///|
pub fn scalar_divide(
  left : Scalar,
  right : Scalar,
) -> Result[Scalar, TowerError] {
  if !same_field(left.field, right.field) {
    Err(DifferentField)
  } else {
    next(scalar_inverse(right), fn(inv) { scalar_multiply(left, inv) })
  }
}

///|
pub fn scalar_sign(value : Scalar) -> Result[ScalarSign, TowerError] {
  next(raw_sign(value.field, value.value), fn(sign) {
    Ok({ sign, certificate: { field: value.field, value: value.value, sign, }, })
  })
}

///|
pub fn scalar_compare(
  left : Scalar,
  right : Scalar,
) -> Result[@core.Ordering, TowerError] {
  next(scalar_subtract(left, right), fn(delta) {
    raw_sign(delta.field, delta.value)
  })
}

///|
pub fn scalar_equal(left : Scalar, right : Scalar) -> Result[Bool, TowerError] {
  next(scalar_compare(left, right), fn(order) { Ok(order.equal(Equal)) })
}

///|
/// This checker re-evaluates exact recursive Sturm-Tarski computations.
pub fn check_scalar(
  value : Scalar,
  sign : @core.Ordering,
  proof : ScalarCertificate,
) -> Bool {
  same_field(value.field, proof.field) &&
  value.value.equal(proof.value) &&
  sign.equal(proof.sign) &&
  (match raw_sign(value.field, value.value) {
    Ok(s) => s.equal(sign)
    Err(_) => false
  })
}
