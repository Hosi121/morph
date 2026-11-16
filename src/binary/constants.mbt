///|
// Binary values are immutable; all callers may share these canonical leaves.
let canonical_zero_value : Binary = { bits: Nil, }

///|
let canonical_one_value : Binary = { bits: Cons(true, Nil), }

///|
fn canonical_zero() -> Binary {
  canonical_zero_value
}

///|
fn canonical_one() -> Binary {
  canonical_one_value
}
