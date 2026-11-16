///|
fn[T, U] map_result(
  values : @core.Chain[T],
  transform : (T) -> Result[U, CadError],
) -> Result[@core.Chain[U], CadError] {
  match values {
    Nil => Ok(Nil)
    Cons(x, rest) =>
      match transform(x) {
        Err(error) => Err(error)
        Ok(value) =>
          match map_result(rest, transform) {
            Ok(tail) => Ok(Cons(value, tail))
            Err(error) => Err(error)
          }
      }
  }
}

///|
fn contains(
  polynomials : @core.Chain[@ordered.Polynomial],
  value : @ordered.Polynomial,
) -> Bool {
  match polynomials {
    Nil => false
    Cons(p, rest) => @ordered.equal(p, value) || contains(rest, value)
  }
}

///|
pub fn prepare(
  field : @numberfield.Field,
  formula : Formula,
) -> Result[Problem, CadError] {
  fn gather(
    expression : Formula,
    found : @core.Chain[@ordered.Polynomial],
  ) -> Result[@core.Chain[@ordered.Polynomial], CadError] {
    match expression {
      Truth(_) => Ok(found)
      Atom(p, _) =>
        if !@numberfield.same_field(field, @ordered.field_of(p)) {
          Err(DifferentField)
        } else if contains(found, p) {
          Ok(found)
        } else {
          Ok(Cons(p, found))
        }
      Negation(child) => gather(child, found)
      Conjunction(left, right) | Disjunction(left, right) =>
        match gather(left, found) {
          Ok(next) => gather(right, next)
          Err(error) => Err(error)
        }
    }
  }
  fn product(
    polynomials : @core.Chain[@ordered.Polynomial],
    accumulated : @ordered.Polynomial,
  ) -> Result[@ordered.Polynomial, CadError] {
    match polynomials {
      Nil => Ok(accumulated)
      Cons(p, rest) =>
        if @ordered.is_zero(p) {
          product(rest, accumulated)
        } else {
          match @ordered.multiply(accumulated, p) {
            Ok(next) => product(rest, next)
            Err(error) => Err(OrderedFailure(error))
          }
        }
    }
  }
  match gather(formula, Nil) {
    Err(error) => Err(error)
    Ok(polynomials) =>
      match product(polynomials, @ordered.one(field)) {
        Err(error) => Err(error)
        Ok(root_poly) =>
          match @ordered.system(root_poly) {
            Err(error) => Err(OrderedFailure(error))
            Ok(system) =>
              match
                map_result(polynomials, fn(p) {
                  if @ordered.is_zero(p) {
                    Ok(AtomInfo::{ polynomial: p, system: None, })
                  } else {
                    match @ordered.system(p) {
                      Ok(s) => Ok(AtomInfo::{ polynomial: p, system: Some(s), })
                      Err(error) => Err(OrderedFailure(error))
                    }
                  }
                }) {
                Err(error) => Err(error)
                Ok(atoms) =>
                  Ok({ field, formula, atoms, product: root_poly, system, })
              }
          }
      }
  }
}

///|
pub fn polynomials(problem : Problem) -> @core.Chain[@ordered.Polynomial] {
  @core.map(problem.atoms, fn(atom) { atom.polynomial })
}

///|
pub fn root_polynomial(problem : Problem) -> @ordered.Polynomial {
  problem.product
}

///|
pub fn field_of(problem : Problem) -> @numberfield.Field {
  problem.field
}

///|
pub fn formula(problem : Problem) -> Formula {
  problem.formula
}
