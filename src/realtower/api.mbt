///|
pub fn rational_field() -> Field { { context: Rationals } }

///|
pub fn same_field(a : Field, b : Field) -> Bool { a.equal(b) }

///|
fn raw_rational(field : Field, q : @exact.Rational) -> Representation {
  match field.context {
    Rationals => Base(q)
    Extension(parent, _, _) => Fraction(Cons(raw_rational(parent, q), Nil), Cons(raw_rational(parent, @exact.rational_one()), Nil))
  }
}

///|
pub fn rational(field : Field, q : @exact.Rational) -> Scalar { { field, value: raw_rational(field, q) } }

///|
pub fn scalar_field(value : Scalar) -> Field { value.field }

///|
pub fn representative(value : Scalar) -> Representation { value.value }

///|
pub fn scalar_zero(field : Field) -> Scalar { rational(field, @exact.rational_zero()) }

///|
pub fn scalar_one(field : Field) -> Scalar { rational(field, @exact.rational_one()) }

///|
fn raw_negate(value : Representation) -> Representation {
  match value {
    Base(q) => Base(@exact.rational_negate(q))
    Fraction(n, d) => Fraction(@core.map(n, raw_negate), d)
  }
}

///|
pub fn scalar_negate(value : Scalar) -> Scalar { { field: value.field, value: raw_negate(value.value) } }

///|
pub fn polynomial_field(value : Polynomial) -> Field { value.field }

///|
pub fn coefficients(value : Polynomial) -> @core.Chain[Scalar] { @core.map(value.values, fn(raw) { Scalar::{ field: value.field, value: raw } }) }

///|
pub fn zero(field : Field) -> Polynomial { { field, values: Nil } }

///|
pub fn one(field : Field) -> Polynomial { { field, values: Cons(raw_rational(field, @exact.rational_one()), Nil) } }

///|
pub fn is_zero(value : Polynomial) -> Bool { match value.values { Nil => true; _ => false } }

///|
pub fn degree(value : Polynomial) -> @core.Nat? { match @core.length(value.values) { Zero => None; Succ(n) => Some(n) } }

///|
pub fn negate(value : Polynomial) -> Polynomial { { field: value.field, values: @core.map(value.values, raw_negate) } }

///|
pub fn squarefree(value : System) -> Polynomial { value.squarefree }

///|
pub fn system_certificate(value : System) -> SystemCertificate { value.certificate }

///|
pub fn root_certificate(value : Root) -> RootCertificate { value.certificate }

///|
pub fn root_interval(value : Root) -> @sturm.Interval { value.certificate.count.interval }

///|
pub fn root_polynomial(value : Root) -> Polynomial { value.system.polynomial }

///|
pub fn root_field(value : Root) -> Field { value.system.polynomial.field }

///|
pub fn roots(value : SolutionSet) -> @core.Chain[Root] { value.roots }

///|
pub fn solution_certificate(value : SolutionSet) -> SolutionCertificate { value.certificate }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn embed(target : Field, value : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_add(left : Scalar, right : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_subtract(left : Scalar, right : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_multiply(left : Scalar, right : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_inverse(value : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_divide(left : Scalar, right : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_sign(value : Scalar) -> Result[ScalarSign, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_equal(left : Scalar, right : Scalar) -> Result[Bool, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scalar_compare(left : Scalar, right : Scalar) -> Result[@core.Ordering, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn polynomial(field : Field, coefficients : @core.Chain[Scalar]) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn add(left : Polynomial, right : Polynomial) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn subtract(left : Polynomial, right : Polynomial) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn multiply(left : Polynomial, right : Polynomial) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn scale(value : Polynomial, scalar : Scalar) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn divide(value : Polynomial, divisor : Polynomial) -> Result[Division, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn monic(value : Polynomial) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn derivative(value : Polynomial) -> Result[Polynomial, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn evaluate(value : Polynomial, point : Scalar) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn evaluate_rational(value : Polynomial, point : @exact.Rational) -> Result[Scalar, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn polynomial_equal(left : Polynomial, right : Polynomial) -> Result[Bool, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn system(value : Polynomial) -> Result[System, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn system_from_certificate(value : Polynomial, proof : SystemCertificate) -> Result[System, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn count_between(value : System, interval : @sturm.Interval) -> Result[CountCertificate, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn root_from_certificate(value : Polynomial, proof : RootCertificate) -> Result[Root, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn root_in_interval(value : System, interval : @sturm.Interval) -> Result[Root, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn isolate(value : System) -> Result[State, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn start(value : Polynomial) -> Result[State, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn advance(value : State, fuel : @core.Nat) -> Result[Progress, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn refine(value : Root, steps : @core.Nat) -> Result[Root, TowerError] { Err(PendingImplementation) }

///|
/// API contract scaffold; this operation explicitly reports unfinished work.
pub fn adjoin(value : Root) -> Result[Extension, TowerError] { Err(PendingImplementation) }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_scalar(value : Scalar, sign : @core.Ordering, proof : ScalarCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_system(value : Polynomial, proof : SystemCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_count(value : System, interval : @sturm.Interval, count : @core.Nat, proof : CountCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_root(value : Polynomial, proof : RootCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_root_result(value : Polynomial, root : Root, proof : RootCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_bound(value : System, proof : BoundCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_isolation(value : Polynomial, proof : SolutionCertificate) -> Bool { false }

///|
/// No certificates are accepted before the checker implementation lands.
pub fn check_isolation_result(value : Polynomial, result : SolutionSet, proof : SolutionCertificate) -> Bool { false }
