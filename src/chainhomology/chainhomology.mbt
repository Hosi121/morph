///|
/// Integer homology of two composable boundary matrices, with A B = zero.
#derive(Eq, Debug)
pub(all) struct ResultGroup {
  free_rank : @core.Nat
  torsion : @core.Chain[@binary.Binary]
}

///|
pub extend ResultGroup with Eq::{equal, not_equal}

///|
pub extend ResultGroup with Debug::{to_repr}

///|
/// Source/result-bound, search-free certificate for ker(A)/im(B).
#derive(Eq, Debug)
pub(all) struct Certificate {
  boundary : @matrix.Matrix[@exact.Integer]
  next_boundary : @matrix.Matrix[@exact.Integer]
  result : ResultGroup
  boundary_form : @smith.Decomposition
  right_inverse : @matrix.Matrix[@exact.Integer]
  coordinates : @matrix.Matrix[@exact.Integer]
  image_form : @smith.Decomposition
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Computation {
  Computed(Certificate)
  BudgetExhausted
  InvalidWitness
}

///|
pub extend Computation with Eq::{equal, not_equal}

///|
pub extend Computation with Debug::{to_repr}

///|
pub fn integers() -> @algebra.Semiring[@exact.Integer] {
  {
    zero: @exact.positive(@binary.zero()),
    one: @exact.positive(@binary.one()),
    plus: @exact.add,
    times: @exact.multiply,
  }
}

///|
fn zero(value : @exact.Integer) -> Bool {
  @binary.is_zero(@exact.magnitude(value))
}

///|
pub fn leading_zero(
  matrix : @matrix.Matrix[@exact.Integer],
  rank : @core.Nat,
) -> Bool {
  @core.all(@core.take(rank, @matrix.rows(matrix)), fn(row) {
    @core.all(row, zero)
  })
}

///|
pub fn chain_identity(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
) -> Bool {
  match @matrix.multiply(a, b, integers()) {
    None => false
    Some(product) =>
      @core.all(@matrix.rows(product), fn(row) { @core.all(row, zero) })
  }
}

///|
fn result_of(form : @smith.Decomposition) -> ResultGroup {
  let quotient = @smith.cokernel(form)
  {
    free_rank: @smith.free_rank(quotient),
    torsion: @smith.torsion_factors(quotient),
  }
}

///|
fn recheck(form : @smith.Decomposition) -> Bool {
  @smith.check(
    @smith.original(form),
    @smith.left(form),
    @smith.diagonal(form),
    @smith.right(form),
  )
  is Some(_)
}

///|
pub fn inverse_pair(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
) -> Bool {
  let identity = @matrix.identity(@matrix.width(a), integers())
  @core.compare(@matrix.height(a), @matrix.width(a)) is Equal &&
  @matrix.multiply(a, b, integers()).equal(Some(identity)) &&
  @matrix.multiply(b, a, integers()).equal(Some(identity))
}

///|
pub fn bottom(
  coordinates : @matrix.Matrix[@exact.Integer],
  rank : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(
    @matrix.width(coordinates),
    @core.drop(rank, @matrix.rows(coordinates)),
  )
}

///|
pub fn integer_inverse(
  input : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn integral_row(
    row : @core.Chain[@exact.Rational],
  ) -> @core.Chain[@exact.Integer]? {
    match row {
      Nil => Some(Nil)
      Cons(value, rest) =>
        match
          (
            @binary.compare(@exact.denominator(value), @binary.one()),
            integral_row(rest),
          ) {
          (Equal, Some(rest)) => Some(Cons(@exact.numerator(value), rest))
          _ => None
        }
    }
  }
  fn integral_rows(
    rows : @core.Chain[@core.Chain[@exact.Rational]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match (integral_row(row), integral_rows(rest)) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
    }
  }
  let rationals = @matrix.matrix(
    @matrix.width(input),
    @core.map(@matrix.rows(input), fn(row) { @core.map(row, @exact.whole) }),
  )
  match rationals {
    None => None
    Some(rationals) =>
      match @linear.inverse(rationals) {
        None => None
        Some(inverse) =>
          match integral_rows(@matrix.rows(inverse)) {
            None => None
            Some(rows) =>
              match @matrix.matrix(@matrix.width(inverse), rows) {
                Some(candidate) =>
                  match inverse_pair(input, candidate) {
                    true => Some(candidate)
                    false => None
                  }
                None => None
              }
          }
      }
  }
}

///|
/// Reconstruct no search: verifies shapes, both Smith forms, inverses, A B = zero,
/// kernel coordinates, image presentation and the actual returned group.
pub fn check_result(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
  actual : ResultGroup,
  witness : Certificate,
) -> Bool {
  let form = witness.boundary_form
  let r = @smith.rank(form)
  witness.boundary.equal(a) &&
  witness.next_boundary.equal(b) &&
  witness.result.equal(actual) &&
  @smith.original(form).equal(a) &&
  recheck(form) &&
  chain_identity(a, b) &&
  inverse_pair(@smith.right(form), witness.right_inverse) &&
  @matrix.multiply(witness.right_inverse, b, integers()).equal(
    Some(witness.coordinates),
  ) &&
  leading_zero(witness.coordinates, r) &&
  bottom(witness.coordinates, r).equal(
    Some(@smith.original(witness.image_form)),
  ) &&
  recheck(witness.image_form) &&
  result_of(witness.image_form).equal(actual)
}

///|
pub fn cycle_basis(
  witness : Certificate,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  @core.drop(
    @smith.rank(witness.boundary_form),
    @matrix.rows(@matrix.transpose(@smith.right(witness.boundary_form))),
  )
}

///|
/// Each Smith search consumes at most fuel transitions.
pub fn compute(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
  fuel : @core.Nat,
) -> Computation {
  match chain_identity(a, b) {
    true =>
      match @smith.run(@smith.start(a), fuel) {
        Paused(_) => BudgetExhausted
        Fault(_) => InvalidWitness
        Done(form) =>
          match integer_inverse(@smith.right(form)) {
            None => InvalidWitness
            Some(inverse) =>
              match @matrix.multiply(inverse, b, integers()) {
                None => InvalidWitness
                Some(coordinates) =>
                  match bottom(coordinates, @smith.rank(form)) {
                    None => InvalidWitness
                    Some(image) =>
                      match @smith.run(@smith.start(image), fuel) {
                        Paused(_) => BudgetExhausted
                        Fault(_) => InvalidWitness
                        Done(image_form) => {
                          let actual = result_of(image_form)
                          let witness = Certificate::{
                            boundary: a,
                            next_boundary: b,
                            result: actual,
                            boundary_form: form,
                            right_inverse: inverse,
                            coordinates,
                            image_form,
                          }
                          match check_result(a, b, actual, witness) {
                            true => Computed(witness)
                            false => InvalidWitness
                          }
                        }
                      }
                  }
              }
          }
      }
    false => InvalidWitness
  }
}

///|
pub fn apply_matrix(
  matrix : @matrix.Matrix[@exact.Integer],
  vector : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  match @matrix.matrix(Succ(Zero), @core.map(vector, fn(x) { Cons(x, Nil) })) {
    None => None
    Some(column) =>
      match @matrix.multiply(matrix, column, integers()) {
        None => None
        Some(product) => @matrix.column(product, Zero)
      }
  }
}

///|
/// Map full source Smith coordinates through U_source inverse, then reduce
/// each target column using U_target and its diagonal residues.
pub fn canonical_columns(
  target_image : @smith.Decomposition,
  cycle_map : @matrix.Matrix[@exact.Integer],
  source_left_inverse : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn normalize(
    form : @smith.Decomposition,
    columns : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match columns {
      Nil => Some(Nil)
      Cons(column, rest) =>
        match
          (
            @smith.class_coordinates(@smith.cokernel(form), column),
            normalize(form, rest),
          ) {
          (Some(column), Some(rest)) => Some(Cons(column, rest))
          _ => None
        }
    }
  }
  match @matrix.multiply(cycle_map, source_left_inverse, integers()) {
    None => None
    Some(lift) =>
      match normalize(target_image, @matrix.rows(@matrix.transpose(lift))) {
        None => None
        Some(columns) =>
          match @matrix.matrix(@matrix.height(lift), columns) {
            None => None
            Some(rows) => Some(@matrix.transpose(rows))
          }
      }
  }
}
