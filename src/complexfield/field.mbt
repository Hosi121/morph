///|
#derive(Eq, Debug)
pub(all) enum FieldError {
  DifferentField
  DimensionMismatch
  InternalInvariant
}

///|
pub extend FieldError with Eq::{equal, not_equal}

///|
pub extend FieldError with Debug::{to_repr}

///|
/// K(i) for a checked real number field K with a selected real embedding.
/// Its Q dimension is twice that of K, even for elements in smaller subfields.
#derive(Debug)
pub struct Field {
  priv real : @nf.Field
}

///|
pub extend Field with Debug::{to_repr}

///|
/// Canonical a+i*b in the fixed basis [1,t,...,t^(d-1),i,i*t,...,i*t^(d-1)].
#derive(Debug)
pub struct Element {
  priv field : Field
  priv real : @nf.Element
  priv imaginary : @nf.Element
}

///|
pub extend Element with Debug::{to_repr}

///|
pub fn field(real : @nf.Field) -> Field {
  { real, }
}

///|
pub fn real_field(field : Field) -> @nf.Field {
  field.real
}

///|
pub fn same_field(a : Field, b : Field) -> Bool {
  @nf.same_field(a.real, b.real)
}

///|
pub fn degree(field : Field) -> @core.Nat {
  @core.add(@nf.degree(field.real), @nf.degree(field.real))
}

///|
pub fn element(
  field : Field,
  real : @nf.Element,
  imaginary : @nf.Element,
) -> Result[Element, FieldError] {
  if !@nf.same_field(field.real, @nf.parent(real)) ||
    !@nf.same_field(field.real, @nf.parent(imaginary)) {
    Err(DifferentField)
  } else {
    Ok({ field, real, imaginary, })
  }
}

///|
fn valid(value : Element) -> Bool {
  @nf.same_field(value.field.real, @nf.parent(value.real)) &&
  @nf.same_field(value.field.real, @nf.parent(value.imaginary))
}

///|
fn same_context(a : Element, b : Element) -> Bool {
  valid(a) && valid(b) && same_field(a.field, b.field)
}

///|
pub fn parent(value : Element) -> Field {
  value.field
}

///|
pub fn real_part(value : Element) -> @nf.Element {
  value.real
}

///|
pub fn imaginary_part(value : Element) -> @nf.Element {
  value.imaginary
}

///|
pub fn equal(a : Element, b : Element) -> Bool {
  same_context(a, b) &&
  @nf.equal(a.real, b.real) &&
  @nf.equal(a.imaginary, b.imaginary)
}

///|
pub fn is_zero(value : Element) -> Bool {
  valid(value) && @nf.is_zero(value.real) && @nf.is_zero(value.imaginary)
}

///|
pub fn rational(field : Field, value : @exact.Rational) -> Element {
  {
    field,
    real: @nf.rational(field.real, value),
    imaginary: @nf.zero(field.real),
  }
}

///|
pub fn zero(field : Field) -> Element {
  rational(field, @exact.rational_zero())
}

///|
pub fn one(field : Field) -> Element {
  rational(field, @exact.rational_one())
}

///|
pub fn imaginary_unit(field : Field) -> Element {
  { field, real: @nf.zero(field.real), imaginary: @nf.one(field.real), }
}

///|
pub fn negate(value : Element) -> Element {
  {
    field: value.field,
    real: @nf.negate(value.real),
    imaginary: @nf.negate(value.imaginary),
  }
}

///|
pub fn conjugate(value : Element) -> Element {
  {
    field: value.field,
    real: value.real,
    imaginary: @nf.negate(value.imaginary),
  }
}

///|
fn[T] lift(result : Result[T, @nf.FieldError]) -> Result[T, FieldError] {
  match result {
    Ok(value) => Ok(value)
    Err(@nf.DifferentField) => Err(DifferentField)
    Err(_) => Err(InternalInvariant)
  }
}

///|
fn combine(
  a : Element,
  b : Element,
  operation : (@nf.Element, @nf.Element) -> Result[@nf.Element, @nf.FieldError],
) -> Result[Element, FieldError] {
  if !same_context(a, b) {
    return Err(DifferentField)
  }
  match
    (lift(operation(a.real, b.real)), lift(operation(a.imaginary, b.imaginary))) {
    (Ok(real), Ok(imaginary)) => element(a.field, real, imaginary)
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
pub fn add(a : Element, b : Element) -> Result[Element, FieldError] {
  combine(a, b, @nf.add)
}

///|
pub fn subtract(a : Element, b : Element) -> Result[Element, FieldError] {
  combine(a, b, @nf.subtract)
}

///|
pub fn multiply(a : Element, b : Element) -> Result[Element, FieldError] {
  if !same_context(a, b) {
    return Err(DifferentField)
  }
  let ac = match lift(@nf.multiply(a.real, b.real)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bd = match lift(@nf.multiply(a.imaginary, b.imaginary)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ad = match lift(@nf.multiply(a.real, b.imaginary)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let bc = match lift(@nf.multiply(a.imaginary, b.real)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match (lift(@nf.subtract(ac, bd)), lift(@nf.add(ad, bc))) {
    (Ok(real), Ok(imaginary)) => element(a.field, real, imaginary)
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
/// Relative trace from K(i) to K.
pub fn relative_trace(value : Element) -> Result[@nf.Element, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  lift(@nf.add(value.real, value.real))
}

///|
/// Relative norm a^2+b^2 is nonzero for nonzero a+i*b since K embeds in R.
pub fn relative_norm(value : Element) -> Result[@nf.Element, FieldError] {
  if !valid(value) {
    return Err(DifferentField)
  }
  match
    (
      @nf.multiply(value.real, value.real),
      @nf.multiply(value.imaginary, value.imaginary),
    ) {
    (Ok(aa), Ok(bb)) => lift(@nf.add(aa, bb))
    _ => Err(InternalInvariant)
  }
}
