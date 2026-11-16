///|
/// An exact complex algebraic number, represented by its real coordinates.
#derive(Debug)
pub struct Number {
  real : @realalgebraic.Number
  imaginary : @realalgebraic.Number
}

///|
pub extend Number with Debug::{to_repr}

///|
pub fn number(
  real : @realalgebraic.Number,
  imaginary : @realalgebraic.Number,
) -> Number {
  { real, imaginary }
}

///|
pub fn real_part(value : Number) -> @realalgebraic.Number {
  value.real
}

///|
pub fn imaginary_part(value : Number) -> @realalgebraic.Number {
  value.imaginary
}
