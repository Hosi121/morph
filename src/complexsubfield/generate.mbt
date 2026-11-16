///|
fn increment(
  exponents : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match (exponents, index) {
    (Cons(exponent, rest), Zero) => Some(Cons(Succ(exponent), rest))
    (Cons(exponent, rest), Succ(i)) =>
      match increment(rest, i) {
        Some(tail) => Some(Cons(exponent, tail))
        None => None
      }
    _ => None
  }
}

///|
/// Breadth-first saturation adds only independent generator monomials. Every
/// addition raises rank, so the ambient dimension bounds all additions.
pub fn generate(
  source : @cf.Field,
  values : @core.Chain[@cf.Element],
) -> Result[Field, SubfieldError] {
  if !@core.all(values, fn(value) { @cf.same_field(source, @cf.parent(value)) }) {
    return Err(DifferentField)
  }
  fn visit(
    generators : @core.Chain[@cf.Element],
    index : @core.Nat,
    witness : (@cf.Element, @core.Chain[@core.Nat]),
    known : @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
    todo : @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
  ) -> (
    @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
    @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
  )? {
    match generators {
      Nil => Some((known, todo))
      Cons(generator, rest) => {
        let (value, exponents) = witness
        let product = match @cf.multiply(value, generator) {
          Ok(value) => value
          Err(_) => return None
        }
        match
          span_coordinates(
            source,
            @core.map(known, fn(pair) {
              let (value, _) = pair
              value
            }),
            product,
          ) {
          Some(_) => visit(rest, Succ(index), witness, known, todo)
          None => {
            if !@core.compare(@core.length(known), @cf.degree(source)).equal(
                Less,
              ) {
              return None
            }
            match increment(exponents, index) {
              Some(exponents) => {
                let next = (product, exponents)
                visit(
                  rest,
                  Succ(index),
                  witness,
                  @core.append(known, Cons(next, Nil)),
                  @core.append(todo, Cons(next, Nil)),
                )
              }
              None => None
            }
          }
        }
      }
    }
  }
  fn saturate(
    known : @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
    todo : @core.Chain[(@cf.Element, @core.Chain[@core.Nat])],
  ) -> @core.Chain[(@cf.Element, @core.Chain[@core.Nat])]? {
    match todo {
      Nil => Some(known)
      Cons(witness, rest) =>
        match visit(values, Zero, witness, known, rest) {
          Some((next, pending)) => saturate(next, pending)
          None => None
        }
    }
  }
  let initial : @core.Chain[(@cf.Element, @core.Chain[@core.Nat])] = Cons(
    (@cf.one(source), @core.replicate(@core.length(values), Zero)),
    Nil,
  )
  match saturate(initial, initial) {
    Some(witnesses) => {
      let proof : Certificate = {
        source,
        generators: values,
        degree: @core.length(witnesses),
        basis: @core.map(witnesses, fn(pair) {
          let (value, _) = pair
          value
        }),
        monomials: @core.map(witnesses, fn(pair) {
          let (_, exponents) = pair
          exponents
        }),
      }
      if check(source, values, proof) {
        Ok({ proof, })
      } else {
        Err(InternalInvariant)
      }
    }
    None => Err(InternalInvariant)
  }
}
