///|
fn[A] diagonal_add(
  matrix : @matrix.Matrix[A],
  scalar : A,
  ops : @algebra.Semiring[A],
) -> @matrix.Matrix[A]? {
  fn row_add(row : @core.Chain[A], index : @core.Nat) -> @core.Chain[A] {
    match (row, index) {
      (Cons(x, rest), Zero) => Cons((ops.plus)(x, scalar), rest)
      (Cons(x, rest), Succ(previous)) => Cons(x, row_add(rest, previous))
      _ => row
    }
  }
  fn rows_add(
    rows : @core.Chain[@core.Chain[A]],
    index : @core.Nat,
  ) -> @core.Chain[@core.Chain[A]] {
    match rows {
      Nil => Nil
      Cons(row, rest) => Cons(row_add(row, index), rows_add(rest, Succ(index)))
    }
  }
  @matrix.matrix(@matrix.width(matrix), rows_add(@matrix.rows(matrix), Zero))
}

///|
/// Evaluate descending scalar coefficients at a square matrix using Horner.
/// An empty coefficient list represents the zero polynomial.
pub fn[A] evaluate_matrix(
  coefficients : @core.Chain[A],
  matrix : @matrix.Matrix[A],
  ops : @algebra.Semiring[A],
) -> @matrix.Matrix[A]? {
  let dimension = @matrix.height(matrix)
  fn go(
    rest : @core.Chain[A],
    accumulated : @matrix.Matrix[A],
  ) -> @matrix.Matrix[A]? {
    match rest {
      Nil => Some(accumulated)
      Cons(c, tail) =>
        match @matrix.multiply(accumulated, matrix, ops) {
          Some(product) =>
            match diagonal_add(product, c, ops) {
              Some(next) => go(tail, next)
              None => None
            }
          None => None
        }
    }
  }
  match @core.compare(dimension, @matrix.width(matrix)) {
    Equal =>
      match
        @matrix.matrix(
          dimension,
          @core.replicate(dimension, @core.replicate(dimension, ops.zero)),
        ) {
        Some(zero) => go(coefficients, zero)
        None => None
      }
    _ => None
  }
}

///|
fn[A] without_last(values : @core.Chain[A]) -> @core.Chain[A] {
  match values {
    Nil | Cons(_, Nil) => Nil
    Cons(x, rest) => Cons(x, without_last(rest))
  }
}

///|
/// adj(A) = (-1)^(n+1) q(A), where det(tI-A)=t q(t)+c.
/// The identity A adj(A)=det(A)I also holds for singular matrices and rings
/// with zero divisors. This is an adjugate, not a field inverse.
pub fn[A] adjugate(
  matrix : @matrix.Matrix[A],
  ring : Ring[A],
) -> @matrix.Matrix[A]? {
  match characteristic(matrix, ring) {
    Some(coefficients) =>
      match evaluate_matrix(without_last(coefficients), matrix, ring.semiring) {
        Some(value) =>
          @matrix.matrix(
            @matrix.width(value),
            @core.map(@matrix.rows(value), fn(row) {
              @core.map(row, fn(x) {
                signed(x, Succ(@matrix.height(matrix)), ring)
              })
            }),
          )
        None => None
      }
    None => None
  }
}
