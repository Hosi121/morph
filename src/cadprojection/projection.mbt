///|
fn validate(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
) -> Result[Unit, ProjectionError] {
  if @core.all(atoms, fn(p) {
      @core.compare(@poly.variables(p), arity) is Equal
    }) {
    Ok(())
  } else {
    Err(WrongArity)
  }
}

///|
fn validate_variable(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[Unit, ProjectionError] {
  if @core.compare(selected, @poly.variables(p)) is Less {
    Ok(())
  } else {
    Err(InvalidVariable)
  }
}

///|
fn input(
  p : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@eliminate.Input, ProjectionError] {
  match @eliminate.input(p, selected) {
    Ok(value) => Ok(value)
    Err(_) => Err(ArithmeticFailure)
  }
}

///|
fn coefficient_rows(
  atoms : @core.Chain[@poly.Polynomial],
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match atoms {
    Nil => Ok(Nil)
    Cons(p, rest) =>
      match input(p, selected) {
        Err(e) => Err(e)
        Ok(value) =>
          match
            (
              @eliminate.coefficient_polynomials(value),
              coefficient_rows(rest, selected),
            ) {
            (Ok(values), Ok(tail)) => Ok(@core.append(values, tail))
            _ => Err(ArithmeticFailure)
          }
      }
  }
}

///|
fn principal_pair(
  f : @poly.Polynomial,
  g : @poly.Polynomial,
  selected : @core.Nat,
) -> Result[@core.Chain[@poly.Polynomial], ProjectionError] {
  match (input(f, selected), input(g, selected)) {
    (Ok(left), Ok(right)) =>
      match @eliminate.principal_coefficients_variable(left, right) {
        Ok(values) => Ok(values)
        Err(_) => Err(ArithmeticFailure)
      }
    _ => Err(ArithmeticFailure)
  }
}

///|
/// This operation does not close derivatives or prune: it exposes Definition 2
/// in full for an arbitrary arity, with the last variable eliminated.
pub fn full_collins(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
) -> Result[ProjectionCertificate, ProjectionError] {
  match validate(arity, atoms) {
    Err(e) => Err(e)
    Ok(_) =>
      match arity {
        Zero => Err(InvalidVariable)
        Succ(selected) =>
          match
            (
              coefficient_rows(atoms, selected),
              reductum_blocks(atoms, selected),
            ) {
            (Ok(coefficients), Ok(reducta)) =>
              match all_principals(reducta, selected) {
                Ok(principal) =>
                  Ok({ arity, atoms, coefficients, reducta, principal, })
                Err(e) => Err(e)
              }
            _ => Err(ArithmeticFailure)
          }
      }
  }
}

///|
pub fn check_projection(
  arity : @core.Nat,
  atoms : @core.Chain[@poly.Polynomial],
  proof : ProjectionCertificate,
) -> Bool {
  match full_collins(arity, atoms) {
    Ok(expected) => expected.equal(proof)
    Err(_) => false
  }
}
