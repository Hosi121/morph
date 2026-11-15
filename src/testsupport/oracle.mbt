///|
/// Test adapters deliberately use machine integers and arrays.
pub fn nat(n : Int32) -> @core.Nat {
  if n < 0 {
    abort("negative test natural")
  }
  if n == 0 {
    Zero
  } else {
    Succ(nat(n - 1))
  }
}

///|
pub fn int_of_nat(n : @core.Nat) -> Int32 {
  match n {
    Zero => 0
    Succ(rest) => 1 + int_of_nat(rest)
  }
}

///|
pub fn binary(n : Int32) -> @binary.Binary {
  if n < 0 {
    abort("negative test binary")
  }
  fn go(n : Int32) -> @core.Chain[Bool] {
    if n == 0 {
      Nil
    } else {
      Cons(n % 2 == 1, go(n / 2))
    }
  }
  @binary.from_bits(go(n))
}

///|
pub fn int_of_binary(n : @binary.Binary) -> Int32 {
  fn go(xs : @core.Chain[Bool]) -> Int32 {
    match xs {
      Nil => 0
      Cons(b, rest) => (if b { 1 } else { 0 }) + 2 * go(rest)
    }
  }
  go(@binary.bits(n))
}

///|
pub fn integer(n : Int32) -> @exact.Integer {
  if n < 0 {
    @exact.negate(@exact.positive(binary(-n)))
  } else {
    @exact.positive(binary(n))
  }
}

///|
pub fn int_of_integer(n : @exact.Integer) -> Int32 {
  let abs = int_of_binary(@exact.magnitude(n))
  if @exact.negative(n) {
    -abs
  } else {
    abs
  }
}

///|
pub fn rational(n : Int32, d : Int32) -> @exact.Rational {
  match @exact.ratio(integer(n), binary(d)) {
    Some(value) => value
    None => abort("zero test denominator")
  }
}

///|
pub fn[A] chain(xs : Array[A]) -> @core.Chain[A] {
  for i = xs.length() - 1, result = @core.Nil; i >= 0; {
    continue i - 1, @core.Cons(xs[i], result)
  } nobreak {
    result
  }
}

///|
pub fn[A] array(xs : @core.Chain[A]) -> Array[A] {
  let result = []
  fn visit(xs : @core.Chain[A]) -> Unit {
    match xs {
      Nil => ()
      Cons(x, rest) => {
        result.push(x)
        visit(rest)
      }
    }
  }
  visit(xs)
  result
}
