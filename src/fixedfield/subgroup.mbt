///|
fn has_member(values : @core.Chain[@core.Nat], value : @core.Nat) -> Bool {
  @core.any(values, fn(x) { x.equal(value) })
}

///|
/// Order and repetition are presentation details; invalid indices are errors.
fn normalize(
  group : @aut.Group,
  values : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  if @core.is_zero(@core.length(values)) ||
    !@core.all(values, fn(i) { @core.compare(i, @aut.order(group)).equal(Less) }) {
    None
  } else {
    Some(
      @core.filter(@core.indices(@aut.order(group)), fn(i) {
        has_member(values, i)
      }),
    )
  }
}

///|
fn subgroup(group : @aut.Group, values : @core.Chain[@core.Nat]) -> Bool {
  let proof = @aut.certificate(group)
  has_member(values, proof.identity) &&
  @core.all(values, fn(a) {
    match @core.nth(proof.inverses, a) {
      Some(inverse) => has_member(values, inverse)
      None => false
    }
  }) &&
  @core.all(values, fn(a) {
    @core.all(values, fn(b) {
      match @core.nth(proof.table, a) {
        Some(row) =>
          match @core.nth(row, b) {
            Some(product) => has_member(values, product)
            None => false
          }
        None => false
      }
    })
  })
}

///|
fn fixed_by(
  group : @aut.Group,
  members : @core.Chain[@core.Nat],
  input : @cf.Element,
) -> Bool {
  let maps = @aut.automorphisms(group)
  @core.all(members, fn(index) {
    match @core.nth(maps, index) {
      Some(map) =>
        match @aut.apply(map, input) {
          Ok(value) => @cf.equal(input, value)
          Err(_) => false
        }
      None => false
    }
  })
}

///|
fn action(
  map : @aut.Automorphism,
  basis : @core.Chain[@cf.Element],
  dimension : @core.Nat,
) -> @matrix.Matrix[@exact.Rational]? {
  fn go(
    todo : @core.Chain[@cf.Element],
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match todo {
      Nil => Some(Nil)
      Cons(value, rest) =>
        match (@aut.apply(map, value), go(rest)) {
          (Ok(image), Some(tail)) => Some(Cons(@cf.coordinates(image), tail))
          _ => None
        }
    }
  }
  match go(basis) {
    Some(columns) =>
      match @matrix.matrix(dimension, columns) {
        Some(matrix) => Some(@matrix.transpose(matrix))
        None => None
      }
    None => None
  }
}

///|
fn actions(
  group : @aut.Group,
  members : @core.Chain[@core.Nat],
) -> @core.Chain[@matrix.Matrix[@exact.Rational]]? {
  let field = @aut.source(group)
  let maps = @aut.automorphisms(group)
  let basis = match ambient_basis(field) {
    Some(value) => value
    None => return None
  }
  fn go(
    todo : @core.Chain[@core.Nat],
  ) -> @core.Chain[@matrix.Matrix[@exact.Rational]]? {
    match todo {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match @core.nth(maps, index) {
          Some(map) =>
            match (action(map, basis, @cf.degree(field)), go(rest)) {
              (Some(matrix), Some(tail)) => Some(Cons(matrix, tail))
              _ => None
            }
          None => None
        }
    }
  }
  go(members)
}

///|
fn constraints(
  dimension : @core.Nat,
  actions : @core.Chain[@matrix.Matrix[@exact.Rational]],
) -> @matrix.Matrix[@exact.Rational]? {
  fn subtract_identity(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
    index : @core.Nat,
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match
          (
            @core.zip(@core.indices(dimension), row),
            subtract_identity(rest, Succ(index)),
          ) {
          (Some(entries), Some(tail)) =>
            Some(
              Cons(
                @core.map(entries, fn(entry) {
                  let (j, value) = entry
                  if j.equal(index) {
                    @exact.rational_subtract(value, @exact.rational_one())
                  } else {
                    value
                  }
                }),
                tail,
              ),
            )
          _ => None
        }
    }
  }
  fn go(
    todo : @core.Chain[@matrix.Matrix[@exact.Rational]],
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match todo {
      Nil => Some(Nil)
      Cons(matrix, rest) =>
        match (subtract_identity(@matrix.rows(matrix), Zero), go(rest)) {
          (Some(rows), Some(tail)) => Some(@core.append(rows, tail))
          _ => None
        }
    }
  }
  match go(actions) {
    Some(rows) => @matrix.matrix(dimension, rows)
    None => None
  }
}
