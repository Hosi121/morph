///|
fn[A] natural_scale(value : A, n : @core.Nat, ring : @berkowitz.Ring[A]) -> A {
  match n {
    Zero => ring.semiring.zero
    Succ(rest) => (ring.semiring.plus)(value, natural_scale(value, rest, ring))
  }
}

///|
fn[A] derivative_coefficients(
  coefficients : @core.Chain[A],
  degree : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> @core.Chain[A] {
  match (degree, coefficients) {
    (Succ(previous), Cons(c, rest)) =>
      Cons(
        natural_scale(c, degree, ring),
        derivative_coefficients(rest, previous, ring),
      )
    _ => Nil
  }
}

///|
pub fn[A] derivative(f : Fixed[A], ring : @berkowitz.Ring[A]) -> Fixed[A] {
  match f.degree {
    Zero => dense(Nil, ring)
    Succ(previous) =>
      {
        degree: previous,
        coefficients: derivative_coefficients(f.coefficients, f.degree, ring),
      }
  }
}

///|
fn[A] subtract_row(
  a : @core.Chain[A],
  b : @core.Chain[A],
  scalar : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> @core.Chain[A]? {
  match (a, b) {
    (Nil, Nil) => Some(Nil)
    (Cons(x, xs), Cons(y, ys)) =>
      match subtract_row(xs, ys, scalar, ring) {
        None => None
        Some(rest) =>
          Some(
            Cons(
              (ring.semiring.plus)(
                x,
                (ring.negate)(natural_scale(y, scalar, ring)),
              ),
              rest,
            ),
          )
      }
    _ => None
  }
}

///|
fn[A] modify_derivative_row(
  rows : @core.Chain[@core.Chain[A]],
  index : @core.Nat,
  first : @core.Chain[A],
  degree : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> @core.Chain[@core.Chain[A]]? {
  match (rows, index) {
    (Cons(row, rest), Zero) =>
      match subtract_row(row, first, degree, ring) {
        None => None
        Some(changed) => Some(Cons(changed, rest))
      }
    (Cons(row, rest), Succ(previous)) =>
      match modify_derivative_row(rest, previous, first, degree, ring) {
        None => None
        Some(changed) => Some(Cons(row, changed))
      }
    _ => None
  }
}

///|
fn[A] remove_first_column(
  rows : @core.Chain[@core.Chain[A]],
) -> @core.Chain[@core.Chain[A]]? {
  match rows {
    Nil => Some(Nil)
    Cons(Cons(_, tail), rest) =>
      match remove_first_column(rest) {
        None => None
        Some(rows) => Some(Cons(tail, rows))
      }
    _ => None
  }
}

///|
/// Universal fixed-degree discriminant. Degree zero and one use convention one.
/// For d>=2 remove the known leading-coefficient factor from the Sylvester
/// determinant by a row operation and minor, without division. This preserves
/// nominal degree when the leading coefficient specializes to zero.
pub fn[A] discriminant(f : Fixed[A], ring : @berkowitz.Ring[A]) -> A? {
  match f.degree {
    Zero | Succ(Zero) => Some(ring.semiring.one)
    Succ(previous) =>
      match sylvester(f, derivative(f, ring), ring) {
        None => None
        Some(columns) =>
          match @matrix.rows(@matrix.transpose(columns)) {
            Nil => None
            Cons(first, _) as rows =>
              match
                modify_derivative_row(rows, previous, first, f.degree, ring) {
                Some(Cons(_, rest)) =>
                  match remove_first_column(rest) {
                    None => None
                    Some(minor_rows) =>
                      match
                        @matrix.matrix(
                          @core.add(previous, previous),
                          minor_rows,
                        ) {
                        None => None
                        Some(minor) =>
                          match @berkowitz.determinant(minor, ring) {
                            None => None
                            Some(value) =>
                              Some(
                                signed(
                                  value,
                                  @core.half_nat(
                                    @core.multiply(f.degree, previous),
                                  ),
                                  ring,
                                ),
                              )
                          }
                      }
                  }
                _ => None
              }
          }
      }
  }
}

///|
pub fn[A] check_discriminant(
  f : Fixed[A],
  value : A,
  ring : @berkowitz.Ring[A],
  equal : (A, A) -> Bool,
) -> Bool {
  match discriminant(f, ring) {
    None => false
    Some(expected) => equal(value, expected)
  }
}
