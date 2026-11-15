///|
/// Eight coefficients, least-significant bit first, of an AES field element.
#derive(Eq, Debug)
pub struct Octet {
  a : Bool
  b : Bool
  c : Bool
  d : Bool
  e : Bool
  f : Bool
  g : Bool
  h : Bool
}

///|
pub extend Octet with Eq::{equal, not_equal}

///|
pub extend Octet with Debug::{to_repr}

///|
pub fn octet(bits : @core.Chain[Bool]) -> Octet? {
  match bits {
    Cons(a, Cons(b, Cons(c, Cons(d, Cons(e, Cons(f, Cons(g, Cons(h, Nil)))))))) =>
      Some({ a, b, c, d, e, f, g, h, })
    _ => None
  }
}

///|
pub fn bits(value : Octet) -> @core.Chain[Bool] {
  Cons(
    value.a,
    Cons(
      value.b,
      Cons(
        value.c,
        Cons(
          value.d,
          Cons(value.e, Cons(value.f, Cons(value.g, Cons(value.h, Nil)))),
        ),
      ),
    ),
  )
}

///|
pub fn zero() -> Octet {
  {
    a: false,
    b: false,
    c: false,
    d: false,
    e: false,
    f: false,
    g: false,
    h: false,
  }
}

///|
pub fn one() -> Octet {
  { ..zero(), a: true, }
}

///|
pub fn from_binary(value : @binary.Binary) -> Octet? {
  let width = @core.length(bits(zero()))
  match @core.compare(@core.length(@binary.bits(value)), width) {
    Greater => None
    _ =>
      octet(@core.take(width, @core.append(@binary.bits(value), bits(zero()))))
  }
}

///|
pub fn binary(value : Octet) -> @binary.Binary {
  @binary.from_bits(bits(value))
}

///|
fn xor_bit(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, false) | (false, true) => true
    _ => false
  }
}

///|
pub fn xor(a : Octet, b : Octet) -> Octet {
  {
    a: xor_bit(a.a, b.a),
    b: xor_bit(a.b, b.b),
    c: xor_bit(a.c, b.c),
    d: xor_bit(a.d, b.d),
    e: xor_bit(a.e, b.e),
    f: xor_bit(a.f, b.f),
    g: xor_bit(a.g, b.g),
    h: xor_bit(a.h, b.h),
  }
}

///|
/// Multiply by x modulo x^8+x^4+x^3+x+1.
pub fn xtime(value : Octet) -> Octet {
  {
    a: value.h,
    b: xor_bit(value.a, value.h),
    c: value.b,
    d: xor_bit(value.c, value.h),
    e: xor_bit(value.d, value.h),
    f: value.e,
    g: value.f,
    h: value.g,
  }
}

///|
/// Carryless multiplication with a fixed eight-step structural recursion.
pub fn multiply(a : Octet, b : Octet) -> Octet {
  fn walk(todo : @core.Chain[Bool], current : Octet, result : Octet) -> Octet {
    match todo {
      Nil => result
      Cons(bit, rest) =>
        walk(
          rest,
          xtime(current),
          match bit {
            true => xor(result, current)
            false => result
          },
        )
    }
  }
  walk(bits(b), a, zero())
}

///|
fn rotate_left(value : Octet) -> Octet {
  {
    a: value.h,
    b: value.a,
    c: value.b,
    d: value.c,
    e: value.d,
    f: value.e,
    g: value.f,
    h: value.g,
  }
}

///|
fn affine(value : Octet) -> Octet {
  let first = rotate_left(value)
  let second = rotate_left(first)
  let third = rotate_left(second)
  let fourth = rotate_left(third)
  let constant : Octet = {
    a: true,
    b: true,
    c: false,
    d: false,
    e: false,
    f: true,
    g: true,
    h: false,
  }
  xor(xor(xor(value, first), xor(second, third)), xor(fourth, constant))
}
