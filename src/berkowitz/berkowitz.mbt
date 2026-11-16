///|
/// Operations of a commutative ring with identity. The algebraic laws are a
/// caller obligation; they cannot be checked for arbitrary functions.
pub(all) struct Ring[A] {
  semiring : @algebra.Semiring[A]
  negate : (A) -> A
}

///|
pub fn integers() -> Ring[@exact.Integer] {
  {
    semiring: {
      zero: @exact.positive(@binary.zero()),
      one: @exact.positive(@binary.one()),
      plus: @exact.add,
      times: @exact.multiply,
    },
    negate: @exact.negate,
  }
}

///|
pub fn rationals() -> Ring[@exact.Rational] {
  { semiring: @algebra.rationals(), negate: @exact.rational_negate, }
}

///|
fn[A] dot(
  row : @core.Chain[A],
  column : @core.Chain[A],
  ops : @algebra.Semiring[A],
) -> A {
  match (row, column) {
    (Cons(x, xs), Cons(y, ys)) =>
      (ops.plus)((ops.times)(x, y), dot(xs, ys, ops))
    _ => ops.zero
  }
}

///|
fn[A] split_column(
  rows : @core.Chain[@core.Chain[A]],
) -> (@core.Chain[A], @core.Chain[@core.Chain[A]])? {
  match rows {
    Nil => Some((Nil, Nil))
    Cons(Cons(x, xs), rest) =>
      match split_column(rest) {
        Some((column, minor)) => Some((Cons(x, column), Cons(xs, minor)))
        None => None
      }
    _ => None
  }
}

///|
fn[A] krylov(
  todo : @core.Nat,
  row : @core.Chain[A],
  vector : @core.Chain[A],
  minor : @core.Chain[@core.Chain[A]],
  ring : Ring[A],
) -> @core.Chain[A] {
  match todo {
    Zero => Nil
    Succ(rest) => {
      let coefficient = (ring.negate)(dot(row, vector, ring.semiring))
      match rest {
        Zero => Cons(coefficient, Nil)
        _ => {
          let next = @core.map(minor, fn(r) { dot(r, vector, ring.semiring) })
          Cons(coefficient, krylov(rest, row, next, minor, ring))
        }
      }
    }
  }
}

///|
/// The k-th output is sum(q[k-j] * p[j]). Keeping the growing prefix
/// reversed avoids building a dense Toeplitz matrix or indexing a linked list.
fn[A] toeplitz(
  q : @core.Chain[A],
  p : @core.Chain[A],
  ops : @algebra.Semiring[A],
) -> @core.Chain[A] {
  fn go(rest : @core.Chain[A], prefix : @core.Chain[A]) -> @core.Chain[A] {
    match rest {
      Nil => Nil
      Cons(x, xs) => {
        let next : @core.Chain[A] = Cons(x, prefix)
        Cons(dot(next, p, ops), go(xs, next))
      }
    }
  }
  go(q, Nil)
}

///|
fn[A] characteristic_rows(
  rows : @core.Chain[@core.Chain[A]],
  ring : Ring[A],
) -> @core.Chain[A]? {
  match rows {
    Nil => Some(Cons(ring.semiring.one, Nil))
    Cons(Cons(corner, row), rest) =>
      match split_column(rest) {
        Some((column, minor)) =>
          match characteristic_rows(minor, ring) {
            Some(p) => {
              let q : @core.Chain[A] = Cons(
                ring.semiring.one,
                Cons(
                  (ring.negate)(corner),
                  krylov(@core.length(rest), row, column, minor, ring),
                ),
              )
              Some(toeplitz(q, p, ring.semiring))
            }
            None => None
          }
        None => None
      }
    _ => None
  }
}

///|
/// Coefficients of det(t I - A), in descending degree, including the leading
/// one. Samuelson--Berkowitz uses no division, pivots, or equality tests, so
/// coefficients may have zero divisors or positive characteristic.
pub fn[A] characteristic(
  matrix : @matrix.Matrix[A],
  ring : Ring[A],
) -> @core.Chain[A]? {
  match @core.compare(@matrix.width(matrix), @matrix.height(matrix)) {
    Equal => characteristic_rows(@matrix.rows(matrix), ring)
    _ => None
  }
}

///|
fn[A] last(values : @core.Chain[A]) -> A? {
  match values {
    Nil => None
    Cons(x, Nil) => Some(x)
    Cons(_, rest) => last(rest)
  }
}

///|
fn[A] signed(value : A, parity : @core.Nat, ring : Ring[A]) -> A {
  match parity {
    Zero => value
    Succ(Zero) => (ring.negate)(value)
    Succ(Succ(rest)) => signed(value, rest, ring)
  }
}

///|
pub fn[A] determinant(matrix : @matrix.Matrix[A], ring : Ring[A]) -> A? {
  match characteristic(matrix, ring) {
    Some(coefficients) =>
      match last(coefficients) {
        Some(constant) => Some(signed(constant, @matrix.height(matrix), ring))
        None => None
      }
    None => None
  }
}
