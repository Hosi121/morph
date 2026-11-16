///|
/// Sparse reducta: remove successive nonzero leading y terms. Zero reducta are
/// omitted, but constants, content and all multiplicities remain intact.
pub fn reducta(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match validate_variable(p, selected) {
    Err(error) => Err(error)
    Ok(_) =>
      match input(p, selected) {
        Err(error) => Err(error)
        Ok(original) => {
          fn go(
            levels : @core.Chain[@core.Nat],
          ) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
            match levels {
              Nil => Ok(Nil)
              Cons(level, rest) => {
                let terms = @core.filter(@poly.terms(p), fn(term) {
                  match @core.nth(term.exponents, selected) {
                    None => false
                    Some(power) => !(@core.compare(power, level) is Greater)
                  }
                })
                match (@poly.polynomial(@poly.variables(p), terms), go(rest)) {
                  (Ok(reduced), Ok(tail)) =>
                    if @poly.is_zero(reduced) {
                      Ok(tail)
                    } else {
                      match input(reduced, selected) {
                        Ok(checked) =>
                          if @core.compare(
                              @eliminate.input_degree(checked),
                              level,
                            )
                            is Equal {
                            Ok(Cons(reduced, tail))
                          } else {
                            Ok(tail)
                          }
                        Err(error) => Err(error)
                      }
                    }
                  _ => Err(ArithmeticFailure)
                }
              }
            }
          }
          go(
            @core.reverse(
              @core.indices(@core.Succ(@eliminate.input_degree(original))),
            ),
          )
        }
      }
  }
}

///|
fn reductum_blocks(
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[@core.Chain[@poly.Polynomial]], ProjectionError] {
  match atoms {
    Nil => Ok(Nil)
    Cons(p, rest) =>
      match (reducta(p, selected), reductum_blocks(rest, selected)) {
        (Ok(block), Ok(tail)) => Ok(Cons(block, tail))
        _ => Err(ArithmeticFailure)
      }
  }
}

///|
/// The full Collins source uses terminal PSC_min=1, independently of degree
/// gap. Generic elimination keeps its fixed-determinant terminal convention.
fn collins_terminal(
  values : @core.Chain[@poly.Polynomial],
  remaining : @core.Nat,
) -> @core.Chain[@poly.Polynomial] {
  match values {
    Nil => Nil
    Cons(_, Nil) => Cons(@poly.constant(remaining, @exact.rational_one()), Nil)
    Cons(head, rest) => Cons(head, collins_terminal(rest, remaining))
  }
}

///|
fn collins_pair(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match principal_pair(f, g, selected) {
    Err(error) => Err(error)
    Ok(values) =>
      match @poly.variables(f) {
        Zero => Err(InvalidVariable)
        Succ(remaining) =>
          Ok(
            Cons(
              {
                left: f,
                right: g,
                values: collins_terminal(values, remaining),
              },
              Nil,
            ),
          )
      }
  }
}

///|
fn collins_derivative(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match @poly.derivative(p, selected) {
    None => Err(ArithmeticFailure)
    Some(derivative) => collins_pair(p, derivative, selected)
  }
}

///|
fn self_principals(
  block : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match block {
    Nil => Ok(Nil)
    Cons(p, rest) =>
      match (collins_derivative(p, selected), self_principals(rest, selected)) {
        (Ok(values), Ok(tail)) => Ok(@core.append(values, tail))
        _ => Err(ArithmeticFailure)
      }
  }
}

///|
fn cross_one(
  p : @poly.Polynomial,
  block : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match block {
    Nil => Ok(Nil)
    Cons(q, rest) =>
      match (collins_pair(p, q, selected), cross_one(p, rest, selected)) {
        (Ok(values), Ok(tail)) => Ok(@core.append(values, tail))
        _ => Err(ArithmeticFailure)
      }
  }
}

///|
fn cross_blocks(
  left : @core.Chain[@poly.Polynomial],
  right : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match left {
    Nil => Ok(Nil)
    Cons(p, rest) =>
      match
        (cross_one(p, right, selected), cross_blocks(rest, right, selected)) {
        (Ok(values), Ok(tail)) => Ok(@core.append(values, tail))
        _ => Err(ArithmeticFailure)
      }
  }
}

///|
fn cross_later(
  left : @core.Chain[@poly.Polynomial],
  blocks : @core.Chain[@core.Chain[@poly.Polynomial]],
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match blocks {
    Nil => Ok(Nil)
    Cons(right, rest) =>
      match
        (cross_blocks(left, right, selected), cross_later(left, rest, selected)) {
        (Ok(values), Ok(tail)) => Ok(@core.append(values, tail))
        _ => Err(ArithmeticFailure)
      }
  }
}

///|
fn all_principals(
  blocks : @core.Chain[@core.Chain[@poly.Polynomial]],
  selected : @core.Nat,
) -> Result[@core.Chain[PrincipalRow], ProjectionError] {
  match blocks {
    Nil => Ok(Nil)
    Cons(block, rest) =>
      match
        (
          self_principals(block, selected),
          cross_later(block, rest, selected),
          all_principals(rest, selected),
        ) {
        (Ok(own), Ok(cross), Ok(tail)) =>
          Ok(@core.append(own, @core.append(cross, tail)))
        _ => Err(ArithmeticFailure)
      }
  }
}
