///|
fn remove_shear_source(
  indices : @core.Chain[@core.Nat],
  source : @core.Nat,
) -> (@core.Chain[@core.Nat], Bool)? {
  match indices {
    Nil => None
    Cons(head, tail) =>
      match @core.compare(head, source) {
        Greater => None
        Equal => Some((tail, false))
        Less =>
          match remove_shear_source(tail, source) {
            None => None
            Some((rest, negative)) => Some((Cons(head, rest), !negative))
          }
      }
  }
}

///|
/// Exterior action of I+t E_target,source. Checked canonical bases make the
/// action a local replacement; it does not construct an exterior-power matrix.
pub fn shear(
  value : Form,
  target : @core.Nat,
  source : @core.Nat,
  factor : @exact.Rational,
) -> Result[Form, FormError] {
  if !(@core.compare(target, value.variables) is Less) ||
    !(@core.compare(source, value.variables) is Less) {
    return Err(IndexOutOfRange)
  }
  if target.equal(source) {
    return Err(InvalidShear)
  }
  if factor.equal(@exact.rational_zero()) {
    return Ok(value)
  }
  let exponents = @core.replicate(value.variables, @core.Nat::Zero)
  fn walk(
    originals : @core.Chain[Term],
    accumulator : @core.Chain[Term],
  ) -> Result[@core.Chain[Term], FormError] {
    match originals {
      Nil => Ok(accumulator)
      Cons(original, tail) => {
        let (remaining, first_sign) = match
          remove_shear_source(original.indices, source) {
          None => return walk(tail, accumulator)
          Some(value) => value
        }
        let (indices, second_sign) = match insert_index(target, remaining) {
          None => return walk(tail, accumulator)
          Some(value) => value
        }
        let signed = if first_sign.equal(second_sign) {
          factor
        } else {
          @exact.rational_negate(factor)
        }
        let coefficient = match
          @poly.scale(original.coefficient, { coefficient: signed, exponents, }) {
          Ok(value) => value
          Err(_) => return Err(InternalInvariant)
        }
        match insert_term({ coefficient, indices, }, accumulator) {
          Err(error) => Err(error)
          Ok(updated) => walk(tail, updated)
        }
      }
    }
  }
  match walk(value.terms, value.terms) {
    Ok(terms) => Ok({ ..value, terms, })
    Err(error) => Err(error)
  }
}

///|
/// Exterior action of a diagonal map, including singular maps.
pub fn scale_axes(
  value : Form,
  factors : @core.Chain[@exact.Rational],
) -> Result[Form, FormError] {
  if !@core.length(factors).equal(value.variables) {
    return Err(DimensionMismatch)
  }
  fn weight(indices : @core.Chain[@core.Nat]) -> @exact.Rational? {
    match indices {
      Nil => Some(@exact.rational_one())
      Cons(i, tail) =>
        match (@core.nth(factors, i), weight(tail)) {
          (Some(a), Some(b)) => Some(@exact.rational_multiply(a, b))
          _ => None
        }
    }
  }
  let exponents = @core.replicate(value.variables, @core.Nat::Zero)
  fn walk(terms : @core.Chain[Term]) -> Result[@core.Chain[Term], FormError] {
    match terms {
      Nil => Ok(Nil)
      Cons(original, tail) => {
        let factor = match weight(original.indices) {
          Some(value) => value
          None => return Err(InternalInvariant)
        }
        let rest = match walk(tail) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        if factor.equal(@exact.rational_zero()) {
          return Ok(rest)
        }
        let coefficient = match
          @poly.scale(original.coefficient, { coefficient: factor, exponents, }) {
          Ok(value) => value
          Err(_) => return Err(InternalInvariant)
        }
        Ok(Cons({ coefficient, indices: original.indices, }, rest))
      }
    }
  }
  match walk(value.terms) {
    Ok(terms) => Ok({ ..value, terms, })
    Err(error) => Err(error)
  }
}

///|
fn exterior_parity(value : @core.Nat) -> Bool {
  match value {
    Zero => false
    Succ(Zero) => true
    Succ(Succ(rest)) => exterior_parity(rest)
  }
}

///|
fn complement_basis(
  indices : @core.Chain[@core.Nat],
  all : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  match (indices, all) {
    (_, Nil) => Nil
    (Nil, _) => all
    (Cons(i, tail), Cons(j, rest)) =>
      if i.equal(j) {
        complement_basis(tail, rest)
      } else {
        Cons(j, complement_basis(indices, rest))
      }
  }
}

///|
fn complement_sign(indices : @core.Chain[@core.Nat], rank : @core.Nat) -> Bool {
  match indices {
    Nil => false
    Cons(i, tail) => {
      let remaining = complement_sign(tail, Succ(rank))
      if exterior_parity(@core.subtract(i, rank)) {
        !remaining
      } else {
        remaining
      }
    }
  }
}

///|
/// Euclidean Hodge complement of canonical sparse terms. Complement reverses
/// lexicographic order among fixed-size bases, so no sorting is required.
pub fn euclidean_star(value : Form) -> Result[Form, FormError] {
  if @core.compare(value.degree, value.variables) is Greater {
    return Err(DegreeOutOfRange)
  }
  let all = @core.indices(value.variables)
  let reversed = @core.map(value.terms, fn(term) {
    {
      coefficient: if complement_sign(term.indices, Zero) {
        @poly.negate(term.coefficient)
      } else {
        term.coefficient
      },
      indices: complement_basis(term.indices, all),
    }
  })
  Ok({
    variables: value.variables,
    degree: @core.subtract(value.variables, value.degree),
    terms: @core.reverse(reversed),
  })
}
