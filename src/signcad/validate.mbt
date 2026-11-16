///|
fn validate_levels(
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  dimension : @core.Nat,
) -> Bool {
  match levels {
    Nil => true
    Cons(family, rest) =>
      @core.all(family, fn(p) { @poly.variables(p).equal(dimension) }) &&
      validate_levels(rest, Succ(dimension))
  }
}

///|
fn unique_signs(children : @core.Chain[Child]) -> Bool {
  match children {
    Nil => true
    Cons(head, rest) =>
      !@core.any(rest, fn(child) { child.signs.equal(head.signs) }) &&
      unique_signs(rest)
  }
}

///|
fn validate_tree(
  levels : @core.Chain[@core.Chain[@poly.Polynomial]],
  tree : Tree,
) -> Result[Unit, EncodingError] {
  match (levels, tree) {
    (Nil, Leaf(_)) => Ok(())
    (Cons(family, rest), Branch(Cons(_, _) as children)) => {
      fn walk(children : @core.Chain[Child]) -> Result[Unit, EncodingError] {
        match children {
          Nil => Ok(())
          Cons(head, tail) =>
            if !@core.length(family).equal(@core.length(head.signs)) {
              Err(DimensionMismatch)
            } else {
              match validate_tree(rest, head.subtree) {
                Err(error) => Err(error)
                Ok(_) => walk(tail)
              }
            }
        }
      }
      if unique_signs(children) {
        walk(children)
      } else {
        Err(AmbiguousSigns)
      }
    }
    _ => Err(InvalidTree)
  }
}
