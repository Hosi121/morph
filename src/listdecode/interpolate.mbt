///|
/// Verify nonzero canonical terms, the weighted-degree bound, and every Hasse
/// derivative of total order below the prescribed multiplicity at each point.
pub fn check_interpolation(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
  polynomial : Interpolation,
) -> Bool {
  match check_word(plan, received, @core.length(plan.points)) {
    Some(_) => return false
    None => ()
  }
  match polynomial.terms {
    Nil => return false
    _ => ()
  }
  if !@core.all(polynomial.terms, fn(term) {
      canonical(plan.field, term.coefficient) &&
      !@binary.is_zero(term.coefficient)
    }) {
    return false
  }
  if !canonical_terms(plan.field, polynomial.terms).equal(polynomial.terms) {
    return false
  }
  let weight = @core.subtract(plan.dimension, Succ(Zero))
  if !@core.all(polynomial.terms, fn(term) {
      !(@core.compare(
        @core.add(term.monomial.x, @core.multiply(weight, term.monomial.y)),
        plan.degree_bound,
      )
      is Greater)
    }) {
    return false
  }
  match @core.zip(plan.points, received) {
    None => false
    Some(pairs) =>
      @core.all(pairs, fn(pair) {
        let (x, y) = pair
        @core.all(plan.derivatives, fn(derivative) {
          @binary.is_zero(hasse(plan.field, polynomial, derivative, x, y))
        })
      })
  }
}

///|
/// Construct one nonzero homogeneous nullspace vector. No coefficient-vector or
/// message enumeration occurs: rowreduce.solve supplies a nullspace basis.
pub fn interpolate(
  plan : Plan,
  received : @core.Chain[@binary.Binary],
) -> Result[Interpolation, DecodeError] {
  match check_word(plan, received, @core.length(plan.points)) {
    Some(error) => return Err(error)
    None => ()
  }
  let pairs = match @core.zip(plan.points, received) {
    Some(value) => value
    None => return Err(LengthMismatch)
  }
  let rows = @core.fold_left(pairs, @core.Nil, fn(rows, pair) {
    let (x, y) = pair
    @core.append(
      rows,
      @core.map(plan.derivatives, fn(derivative) {
        @core.map(plan.monomials, fn(monomial) {
          hasse_term(plan.field, monomial, derivative, x, y)
        })
      }),
    )
  })
  let matrix = match @matrix.matrix(@core.length(plan.monomials), rows) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let rhs = @core.replicate(@core.length(rows), @binary.zero())
  let vector = match
    @rowreduce.solve(@primefield.arithmetic(plan.field), matrix, rhs) {
    Some(Affine(_, Cons(basis, _))) => basis
    _ => return Err(InterpolationFailure)
  }
  let pairs = match @core.zip(plan.monomials, vector) {
    Some(value) => value
    None => return Err(InternalInvariant)
  }
  let polynomial = {
    terms: canonical_terms(
      plan.field,
      @core.map(pairs, fn(pair) {
        let (monomial, coefficient) = pair
        { monomial, coefficient, }
      }),
    ),
  }
  if check_interpolation(plan, received, polynomial) {
    Ok(polynomial)
  } else {
    Err(InterpolationFailure)
  }
}
