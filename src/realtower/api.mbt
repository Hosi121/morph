///|
pub fn rational_field() -> Field {
  { context: Rationals, }
}

///|
pub fn same_field(a : Field, b : Field) -> Bool {
  a.equal(b)
}

///|
fn raw_rational(field : Field, q : @exact.Rational) -> Representation {
  match field.context {
    Rationals => Base(q)
    Extension(parent, _, _) =>
      Fraction(
        Cons(raw_rational(parent, q), Nil),
        Cons(raw_rational(parent, @exact.rational_one()), Nil),
      )
  }
}

///|
pub fn rational(field : Field, q : @exact.Rational) -> Scalar {
  { field, value: raw_rational(field, q), }
}

///|
pub fn scalar_field(value : Scalar) -> Field {
  value.field
}

///|
pub fn representative(value : Scalar) -> Representation {
  value.value
}

///|
pub fn scalar_zero(field : Field) -> Scalar {
  rational(field, @exact.rational_zero())
}

///|
pub fn scalar_one(field : Field) -> Scalar {
  rational(field, @exact.rational_one())
}

///|
fn raw_negate(value : Representation) -> Representation {
  match value {
    Base(q) => Base(@exact.rational_negate(q))
    Fraction(n, d) => Fraction(@core.map(n, raw_negate), d)
  }
}

///|
pub fn scalar_negate(value : Scalar) -> Scalar {
  { field: value.field, value: raw_negate(value.value), }
}

///|
pub fn polynomial_field(value : Polynomial) -> Field {
  value.field
}

///|
pub fn coefficients(value : Polynomial) -> @core.Chain[Scalar] {
  @core.map(value.values, fn(raw) {
    Scalar::{ field: value.field, value: raw, }
  })
}

///|
pub fn zero(field : Field) -> Polynomial {
  { field, values: Nil, }
}

///|
pub fn one(field : Field) -> Polynomial {
  { field, values: Cons(raw_rational(field, @exact.rational_one()), Nil), }
}

///|
pub fn is_zero(value : Polynomial) -> Bool {
  match value.values {
    Nil => true
    _ => false
  }
}

///|
pub fn degree(value : Polynomial) -> @core.Nat? {
  match @core.length(value.values) {
    Zero => None
    Succ(n) => Some(n)
  }
}

///|
pub fn negate(value : Polynomial) -> Polynomial {
  { field: value.field, values: @core.map(value.values, raw_negate), }
}

///|
pub fn squarefree(value : System) -> Polynomial {
  value.squarefree
}

///|
pub fn system_certificate(value : System) -> SystemCertificate {
  value.certificate
}

///|
pub fn root_certificate(value : Root) -> RootCertificate {
  value.certificate
}

///|
pub fn root_interval(value : Root) -> @sturm.Interval {
  value.certificate.count.interval
}

///|
pub fn root_polynomial(value : Root) -> Polynomial {
  value.system.polynomial
}

///|
pub fn root_field(value : Root) -> Field {
  value.system.polynomial.field
}

///|
pub fn roots(value : SolutionSet) -> @core.Chain[Root] {
  value.roots
}

///|
pub fn solution_certificate(value : SolutionSet) -> SolutionCertificate {
  value.certificate
}
