///|
fn ambient_element(
  field : @cf.Field,
  values : @core.Chain[@exact.Rational],
) -> @cf.Element? {
  match @cf.from_coordinates(field, values) {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
fn ambient_basis(field : @cf.Field) -> @core.Chain[@cf.Element]? {
  fn go(indices : @core.Chain[@core.Nat]) -> @core.Chain[@cf.Element]? {
    match indices {
      Nil => Some(Nil)
      Cons(index, rest) => {
        let vector = @core.map(@core.indices(@cf.degree(field)), fn(i) {
          if i.equal(index) {
            @exact.rational_one()
          } else {
            @exact.rational_zero()
          }
        })
        match (ambient_element(field, vector), go(rest)) {
          (Some(value), Some(tail)) => Some(Cons(value, tail))
          _ => None
        }
      }
    }
  }
  go(@core.indices(@cf.degree(field)))
}

///|
fn basis_matrix(
  field : @cf.Field,
  values : @core.Chain[@cf.Element],
) -> @matrix.Matrix[@exact.Rational]? {
  match @matrix.matrix(@cf.degree(field), @core.map(values, @cf.coordinates)) {
    Some(rows) => Some(@matrix.transpose(rows))
    None => None
  }
}

///|
fn elements(
  field : @cf.Field,
  vectors : @core.Chain[@core.Chain[@exact.Rational]],
) -> @core.Chain[@cf.Element]? {
  match vectors {
    Nil => Some(Nil)
    Cons(vector, rest) =>
      match (ambient_element(field, vector), elements(field, rest)) {
        (Some(value), Some(tail)) => Some(Cons(value, tail))
        _ => None
      }
  }
}

///|
/// Direct substitution decides membership in the checked subgroup's invariants.
pub fn contains(field : Field, input : @cf.Element) -> Bool {
  if !@cf.same_field(field.proof.source, @cf.parent(input)) {
    return false
  }
  fixed_by(field.group, field.proof.members, input)
}

///|
/// The independent basis guarantees that a fixed input has unique coordinates.
pub fn coordinates(
  field : Field,
  input : @cf.Element,
) -> Result[@core.Chain[@exact.Rational], FixedError] {
  if !@cf.same_field(field.proof.source, @cf.parent(input)) {
    return Err(DifferentField)
  }
  if !contains(field, input) {
    return Err(NotFixed)
  }
  match basis_matrix(field.proof.source, basis(field)) {
    Some(matrix) =>
      match @linear.solve(matrix, @cf.coordinates(input)) {
        Some(@linear.Unique(values)) => Ok(values)
        _ => Err(InternalInvariant)
      }
    None => Err(InternalInvariant)
  }
}

///|
pub fn from_coordinates(
  field : Field,
  values : @core.Chain[@exact.Rational],
) -> Result[@cf.Element, FixedError] {
  fn go(
    todo : @core.Chain[(@cf.Element, @exact.Rational)],
    sum : @cf.Element,
  ) -> @cf.Element? {
    match todo {
      Nil => Some(sum)
      Cons((value, coefficient), rest) =>
        match
          @cf.multiply(value, @cf.rational(field.proof.source, coefficient)) {
          Ok(product) =>
            match @cf.add(sum, product) {
              Ok(next) => go(rest, next)
              Err(_) => None
            }
          Err(_) => None
        }
    }
  }
  match @core.zip(basis(field), values) {
    Some(todo) =>
      match go(todo, @cf.zero(field.proof.source)) {
        Some(result) => Ok(result)
        None => Err(InternalInvariant)
      }
    None => Err(DimensionMismatch)
  }
}
