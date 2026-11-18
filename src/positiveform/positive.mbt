///|
/// A strictly positive rational with its already justified reciprocal.
#derive(Eq, Debug)
pub struct PositiveScalar {
  value : @exact.Rational
  reciprocal_value : @exact.Rational
}

///|
pub extend PositiveScalar with Eq::{equal, not_equal}

///|
pub extend PositiveScalar with Debug::{to_repr}

///|
pub fn positive_scalar(value : @exact.Rational) -> PositiveScalar? {
  if !(@exact.rational_compare(value, @exact.rational_zero()) is Greater) {
    return None
  }
  match @exact.nonzero(value) {
    None => None
    Some(proof) => Some({ value, reciprocal_value: @exact.reciprocal(proof), })
  }
}

///|
pub fn one() -> PositiveScalar {
  { value: @exact.rational_one(), reciprocal_value: @exact.rational_one(), }
}

///|
pub fn PositiveScalar::value(self : PositiveScalar) -> @exact.Rational {
  self.value
}

///|
pub fn PositiveScalar::inverse(self : PositiveScalar) -> PositiveScalar {
  { value: self.reciprocal_value, reciprocal_value: self.value, }
}

///|
pub fn PositiveScalar::multiply(
  self : PositiveScalar,
  other : PositiveScalar,
) -> PositiveScalar {
  {
    value: @exact.rational_multiply(self.value, other.value),
    reciprocal_value: @exact.rational_multiply(
      self.reciprocal_value,
      other.reciprocal_value,
    ),
  }
}

///|
pub fn PositiveScalar::power(
  self : PositiveScalar,
  exponent : @core.Nat,
) -> PositiveScalar {
  match exponent {
    Zero => one()
    Succ(Zero) => self
    _ => {
      let (half, odd) = @core.halve_nat(exponent)
      let value = self.power(half)
      let square = value.multiply(value)
      if odd {
        square.multiply(self)
      } else {
        square
      }
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) enum FormError {
  NotSquare
  NotSymmetric
  NotPositiveDefinite
  InternalShape
}

///|
pub extend FormError with Eq::{equal, not_equal}

///|
pub extend FormError with Debug::{to_repr}

///|
// A = L diag(pivot, Schur) L^T, with L = [[one,zero],[below,I]].
// Every pivot is positive; each tail is the decomposition of the Schur complement.
#derive(Eq, Debug)
enum Factors {
  Empty
  Pivot(PositiveScalar, @core.Chain[@exact.Rational], Factors)
}

///|
pub extend Factors with Eq::{equal, not_equal}

///|
pub extend Factors with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Structure {
  Dense(@matrix.Matrix[@exact.Rational], Factors)
  Inverse(PositiveDefinite)
  Scaled(PositiveScalar, PositiveDefinite)
  Blocks(@core.Chain[PositiveDefinite])
}

///|
pub extend Structure with Eq::{equal, not_equal}

///|
pub extend Structure with Debug::{to_repr}

///|
/// A positive definite rational form, preserving the construction that proves it.
/// Inverses, positive rescalings and direct sums do not repeat an SPD test or LDL.
/// Dense matrix expansion is an explicit boundary operation.
/// Eq compares prepared constructions; equivalent compares the linear maps.
#derive(Eq, Debug)
pub struct PositiveDefinite {
  dimension : @core.Nat
  determinant_value : PositiveScalar
  structure : Structure
}

///|
pub extend PositiveDefinite with Eq::{equal, not_equal}

///|
pub extend PositiveDefinite with Debug::{to_repr}

///|
fn[A, B] traverse(values : @core.Chain[A], f : (A) -> B?) -> @core.Chain[B]? {
  match values {
    Nil => Some(Nil)
    Cons(value, rest) =>
      match (f(value), traverse(rest, f)) {
        (Some(value), Some(rest)) => Some(Cons(value, rest))
        _ => None
      }
  }
}

///|
fn dot(
  left : @core.Chain[@exact.Rational],
  right : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match (left, right) {
    (Nil, Nil) => Some(@exact.rational_zero())
    (Cons(a, left), Cons(b, right)) =>
      match dot(left, right) {
        None => None
        Some(rest) =>
          Some(@exact.rational_add(@exact.rational_multiply(a, b), rest))
      }
    _ => None
  }
}

///|
fn subtract_scaled(
  left : @core.Chain[@exact.Rational],
  scale : @exact.Rational,
  right : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match (left, right) {
    (Nil, Nil) => Some(Nil)
    (Cons(a, left), Cons(b, right)) =>
      match subtract_scaled(left, scale, right) {
        None => None
        Some(rest) =>
          Some(
            Cons(
              @exact.rational_subtract(a, @exact.rational_multiply(scale, b)),
              rest,
            ),
          )
      }
    _ => None
  }
}

///|
fn decompose(
  rows : @core.Chain[@core.Chain[@exact.Rational]],
) -> Result[(Factors, PositiveScalar), FormError] {
  match rows {
    Nil => Ok((Empty, one()))
    Cons(Cons(pivot, first), rest) => {
      let pivot = match positive_scalar(pivot) {
        None => return Err(NotPositiveDefinite)
        Some(value) => value
      }
      let reduced = traverse(rest, fn(row) {
        match row {
          Nil => None
          Cons(head, tail) => {
            let multiplier = @exact.rational_multiply(
              head,
              pivot.reciprocal_value,
            )
            match subtract_scaled(tail, multiplier, first) {
              None => None
              Some(row) => Some((multiplier, row))
            }
          }
        }
      })
      let reduced = match reduced {
        None => return Err(InternalShape)
        Some(value) => value
      }
      let below = @core.map(reduced, fn(pair) {
        let (value, _) = pair
        value
      })
      let rows = @core.map(reduced, fn(pair) {
        let (_, row) = pair
        row
      })
      match decompose(rows) {
        Err(error) => Err(error)
        Ok((tail, determinant)) =>
          Ok((Pivot(pivot, below, tail), pivot.multiply(determinant)))
      }
    }
    _ => Err(InternalShape)
  }
}

///|
/// Exact square/symmetry checks followed by one positive-pivot LDL decomposition.
/// The empty form is positive definite vacuously and has determinant one.
pub fn positive_definite(
  value : @matrix.Matrix[@exact.Rational],
) -> Result[PositiveDefinite, FormError] {
  let dimension = @matrix.width(value)
  if !@matrix.height(value).equal(dimension) {
    return Err(NotSquare)
  }
  if !value.equal(@matrix.transpose(value)) {
    return Err(NotSymmetric)
  }
  match decompose(@matrix.rows(value)) {
    Err(error) => Err(error)
    Ok((factors, determinant_value)) =>
      Ok({ dimension, determinant_value, structure: Dense(value, factors), })
  }
}

///|
pub fn PositiveDefinite::dimension(self : PositiveDefinite) -> @core.Nat {
  self.dimension
}

///|
/// Strict positivity is retained in the result type.
pub fn PositiveDefinite::determinant(self : PositiveDefinite) -> PositiveScalar {
  self.determinant_value
}

///|
fn solve_factors(
  factors : Factors,
  rhs : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match (factors, rhs) {
    (Empty, Nil) => Some(Nil)
    (Pivot(pivot, below, tail), Cons(first, rest)) => {
      let rest = match subtract_scaled(rest, first, below) {
        None => return None
        Some(value) => value
      }
      match solve_factors(tail, rest) {
        None => None
        Some(solution) =>
          match dot(below, solution) {
            None => None
            Some(correction) =>
              Some(
                Cons(
                  @exact.rational_subtract(
                    @exact.rational_multiply(first, pivot.reciprocal_value),
                    correction,
                  ),
                  solution,
                ),
              )
          }
      }
    }
    _ => None
  }
}

///|
fn block_action(
  blocks : @core.Chain[PositiveDefinite],
  rhs : @core.Chain[@exact.Rational],
  solve : Bool,
) -> @core.Chain[@exact.Rational]? {
  match blocks {
    Nil => if @core.length(rhs).equal(Zero) { Some(Nil) } else { None }
    Cons(block, rest) =>
      match @core.split_exact(block.dimension, rhs) {
        None => None
        Some((first, tail)) =>
          match (block.action(first, solve), block_action(rest, tail, solve)) {
            (Some(first), Some(tail)) => Some(@core.append(first, tail))
            _ => None
          }
      }
  }
}

///|
fn PositiveDefinite::action(
  self : PositiveDefinite,
  rhs : @core.Chain[@exact.Rational],
  solve : Bool,
) -> @core.Chain[@exact.Rational]? {
  match self.structure {
    Dense(value, factors) =>
      if solve {
        solve_factors(factors, rhs)
      } else {
        traverse(@matrix.rows(value), fn(row) { dot(row, rhs) })
      }
    Inverse(source) => source.action(rhs, !solve)
    Scaled(factor, source) =>
      match source.action(rhs, solve) {
        None => None
        Some(value) => {
          let factor = if solve {
            factor.reciprocal_value
          } else {
            factor.value
          }
          Some(@core.map(value, fn(x) { @exact.rational_multiply(factor, x) }))
        }
      }
    Blocks(blocks) => block_action(blocks, rhs, solve)
  }
}

///|
pub fn PositiveDefinite::solve(
  self : PositiveDefinite,
  rhs : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  if !@core.length(rhs).equal(self.dimension) {
    return None
  }
  self.action(rhs, true)
}

///|
pub fn PositiveDefinite::apply(
  self : PositiveDefinite,
  rhs : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  if !@core.length(rhs).equal(self.dimension) {
    return None
  }
  self.action(rhs, false)
}

///|
/// Equality of basis images establishes equality of these linear operators.
pub fn PositiveDefinite::equivalent(
  self : PositiveDefinite,
  other : PositiveDefinite,
) -> Bool {
  if !self.dimension.equal(other.dimension) {
    return false
  }
  let indices = @core.indices(self.dimension)
  @core.all(indices, fn(i) {
    let basis = @core.map(indices, fn(j) {
      if i.equal(j) {
        @exact.rational_one()
      } else {
        @exact.rational_zero()
      }
    })
    match (self.apply(basis), other.apply(basis)) {
      (Some(a), Some(b)) => a.equal(b)
      _ => false
    }
  })
}

///|
pub fn PositiveDefinite::scale(
  self : PositiveDefinite,
  factor : PositiveScalar,
) -> PositiveDefinite {
  if factor.value.equal(@exact.rational_one()) || self.dimension.equal(Zero) {
    return self
  }
  match self.structure {
    Scaled(previous, source) => source.scale(previous.multiply(factor))
    _ =>
      {
        dimension: self.dimension,
        determinant_value: self.determinant_value.multiply(
          factor.power(self.dimension),
        ),
        structure: Scaled(factor, self),
      }
  }
}

///|
fn blocks(value : PositiveDefinite) -> @core.Chain[PositiveDefinite] {
  match value.structure {
    Blocks(values) => values
    _ => Cons(value, Nil)
  }
}

///|
/// Block structure is preserved, including in subsequent solves and inverses.
pub fn PositiveDefinite::direct_sum(
  self : PositiveDefinite,
  other : PositiveDefinite,
) -> PositiveDefinite {
  if self.dimension.equal(Zero) {
    return other
  }
  if other.dimension.equal(Zero) {
    return self
  }
  {
    dimension: @core.add(self.dimension, other.dimension),
    determinant_value: self.determinant_value.multiply(other.determinant_value),
    structure: Blocks(@core.append(blocks(self), blocks(other))),
  }
}

///|
/// A structural inverse: no matrix expansion, repeated factorization or SPD test.
pub fn PositiveDefinite::inverse(self : PositiveDefinite) -> PositiveDefinite {
  if self.dimension.equal(Zero) {
    return self
  }
  match self.structure {
    Inverse(source) => source
    Scaled(factor, source) => source.inverse().scale(factor.inverse())
    Blocks(values) =>
      {
        dimension: self.dimension,
        determinant_value: self.determinant_value.inverse(),
        structure: Blocks(@core.map(values, fn(block) { block.inverse() })),
      }
    Dense(_, _) =>
      {
        dimension: self.dimension,
        determinant_value: self.determinant_value.inverse(),
        structure: Inverse(self),
      }
  }
}

///|
fn block_rows(
  values : @core.Chain[PositiveDefinite],
  prefix : @core.Nat,
  dimension : @core.Nat,
) -> @core.Chain[@core.Chain[@exact.Rational]]? {
  match values {
    Nil => Some(Nil)
    Cons(value, rest) => {
      let matrix = match value.matrix() {
        Ok(value) => value
        Err(_) => return None
      }
      let next = @core.add(prefix, value.dimension)
      let suffix = @core.subtract(dimension, next)
      let rows = @core.map(@matrix.rows(matrix), fn(row) {
        @core.append(
          @core.replicate(prefix, @exact.rational_zero()),
          @core.append(row, @core.replicate(suffix, @exact.rational_zero())),
        )
      })
      match block_rows(rest, next, dimension) {
        None => None
        Some(tail) => Some(@core.append(rows, tail))
      }
    }
  }
}

///|
/// Explicit materialization. All structural operations above can avoid this.
pub fn PositiveDefinite::matrix(
  self : PositiveDefinite,
) -> Result[@matrix.Matrix[@exact.Rational], FormError] {
  let rows = match self.structure {
    Dense(value, _) => return Ok(value)
    Scaled(factor, source) => {
      let matrix = match source.matrix() {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      Some(
        @core.map(@matrix.rows(matrix), fn(row) {
          @core.map(row, fn(value) {
            @exact.rational_multiply(factor.value, value)
          })
        }),
      )
    }
    Blocks(values) => block_rows(values, Zero, self.dimension)
    Inverse(source) => {
      let indices = @core.indices(self.dimension)
      let columns = traverse(indices, fn(i) {
        source.solve(
          @core.map(indices, fn(j) {
            if i.equal(j) {
              @exact.rational_one()
            } else {
              @exact.rational_zero()
            }
          }),
        )
      })
      match columns {
        None => None
        Some(columns) =>
          match @matrix.matrix(self.dimension, columns) {
            None => None
            Some(value) => return Ok(@matrix.transpose(value))
          }
      }
    }
  }
  match rows {
    None => Err(InternalShape)
    Some(rows) =>
      match @matrix.matrix(self.dimension, rows) {
        None => Err(InternalShape)
        Some(value) => Ok(value)
      }
  }
}
