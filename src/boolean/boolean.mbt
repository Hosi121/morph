///|
/// A Boolean algebra dictionary. Interpret one program as Bool or as a circuit.
pub(all) struct Algebra[A] {
  zero : A
  one : A
  negate : (A) -> A
  conjunction : (A, A) -> A
  disjunction : (A, A) -> A
  exclusive : (A, A) -> A
  select : (A, A, A) -> A
}

///|
pub fn exclusive(a : Bool, b : Bool) -> Bool {
  match (a, b) {
    (true, false) | (false, true) => true
    _ => false
  }
}

///|
pub fn algebra() -> Algebra[Bool] {
  {
    zero: false,
    one: true,
    negate: fn(a) { !a },
    conjunction: fn(a, b) { a && b },
    disjunction: fn(a, b) { a || b },
    exclusive,
    select: fn(c, a, b) {
      match c {
        true => a
        false => b
      }
    },
  }
}

///|
/// Reference sum of the four odd-parity minterms; carry is the majority function.
pub fn[A] full_adder_minterms(
  ops : Algebra[A],
  a : A,
  b : A,
  carry : A,
) -> (A, A) {
  let ab = (ops.conjunction)(a, b)
  let na = (ops.negate)(a)
  let nb = (ops.negate)(b)
  let nc = (ops.negate)(carry)
  let first = (ops.conjunction)((ops.conjunction)(na, nb), carry)
  let second = (ops.conjunction)((ops.conjunction)(na, b), nc)
  let third = (ops.conjunction)((ops.conjunction)(a, nb), nc)
  let fourth = (ops.conjunction)(ab, carry)
  let sum = (ops.disjunction)(
    (ops.disjunction)(first, second),
    (ops.disjunction)(third, fourth),
  )
  let next = (ops.disjunction)(
    ab,
    (ops.disjunction)((ops.conjunction)(a, carry), (ops.conjunction)(b, carry)),
  )
  (sum, next)
}

///|
pub fn[A] full_adder_propagate(
  ops : Algebra[A],
  a : A,
  b : A,
  carry : A,
) -> (A, A) {
  let propagate = (ops.exclusive)(a, b)
  (
    (ops.exclusive)(propagate, carry),
    (ops.disjunction)(
      (ops.conjunction)(a, b),
      (ops.conjunction)(propagate, carry),
    ),
  )
}

///|
pub fn[A] full_adder_mux(ops : Algebra[A], a : A, b : A, carry : A) -> (A, A) {
  let propagate = (ops.exclusive)(a, b)
  ((ops.exclusive)(propagate, carry), (ops.select)(propagate, carry, a))
}

///|
/// Fixed-width little-endian addition, retaining the final carry separately.
pub fn[A] add_words(
  adder : (A, A, A) -> (A, A),
  a : @core.Chain[A],
  b : @core.Chain[A],
  carry : A,
) -> (@core.Chain[A], A)? {
  match (a, b) {
    (Nil, Nil) => Some((Nil, carry))
    (Cons(x, xs), Cons(y, ys)) => {
      let (sum, next) = adder(x, y, carry)
      match add_words(adder, xs, ys, next) {
        None => None
        Some((rest, final_carry)) => Some((Cons(sum, rest), final_carry))
      }
    }
    _ => None
  }
}
