///|
/// H_k = Z^free_rank plus the cyclic groups of the torsion invariant factors.
/// Unit factors are omitted; torsion factors are positive and divide successors.
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
/// Search-free witness for one actual complex, degree, and result. The first
/// Smith form U*d_k*V=D determines a full integer cycle basis. Coordinates
/// V^-1*d_(k+1) have zero leading rank(d_k) rows. The second Smith form is of
/// the remaining rows, presenting boundaries inside the cycle lattice.
/// Fields are public so independently produced witnesses can be checked.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : Complex
  degree : @core.Nat
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
fn inverse_pair(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
) -> Bool {
  let identity = @matrix.identity(@matrix.width(a), integers())
  @core.compare(@matrix.height(a), @matrix.width(a)) is Equal &&
  @matrix.multiply(a, b, integers()).equal(Some(identity)) &&
  @matrix.multiply(b, a, integers()).equal(Some(identity))
}

///|
fn bottom(
  coordinates : @matrix.Matrix[@exact.Integer],
  rank : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(
    @matrix.width(coordinates),
    @core.drop(rank, @matrix.rows(coordinates)),
  )
}

///|
/// Binds the certificate to the actual requested source, degree, and returned
/// group. Reconstructs boundaries and verifies both Smith witnesses, the full
/// integer coordinate change, chain identity, leading zeros and group result.
/// It never calls Smith search, rational inversion, or homology computation.
pub fn check_result(
  complex : Complex,
  degree : @core.Nat,
  actual : ResultGroup,
  witness : Certificate,
) -> Bool {
  let bound = witness.source.equal(complex) &&
    witness.degree.equal(degree) &&
    witness.result.equal(actual) &&
    validate(complex.faces).equal(Some(complex))
  match bound {
    false => false
    true =>
      match (boundary(complex, degree), boundary(complex, Succ(degree))) {
        (Some(a), Some(b)) => {
          let form = witness.boundary_form
          let r = @smith.rank(form)
          let valid_coordinates = @matrix.multiply(
            witness.right_inverse,
            b,
            integers(),
          ).equal(Some(witness.coordinates))
          let leading_zero = @core.all(
            @core.take(r, @matrix.rows(witness.coordinates)),
            fn(row) { @core.all(row, zero) },
          )
          @smith.original(form).equal(a) &&
          recheck(form) &&
          boundary_squared_zero(complex, degree) &&
          inverse_pair(@smith.right(form), witness.right_inverse) &&
          valid_coordinates &&
          leading_zero &&
          bottom(witness.coordinates, r).equal(
            Some(@smith.original(witness.image_form)),
          ) &&
          recheck(witness.image_form) &&
          result_of(witness.image_form).equal(actual)
        }
        _ => false
      }
  }
}

///|
/// Access the witnessed result; use check_result with the actual return value
/// when accepting a certificate from an untrusted producer.
pub fn result(witness : Certificate) -> ResultGroup {
  witness.result
}

///|
/// Full Z-basis of cycles in the original lexicographic simplex coordinates.
/// These are generators of ker(d_k), before quotienting by boundaries.
pub fn cycle_basis(
  witness : Certificate,
) -> @core.Chain[@core.Chain[@exact.Integer]] {
  @core.drop(
    @smith.rank(witness.boundary_form),
    @matrix.rows(@matrix.transpose(@smith.right(witness.boundary_form))),
  )
}

///|
fn integer_inverse(
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
/// Run the existing Smith machine twice, each with at most fuel transitions.
/// A paused search is reported explicitly and never returned as a homology
/// result. Rational inversion is reused only to obtain the integral V^-1;
/// the checker verifies its two integer inverse identities independently.
pub fn compute(
  complex : Complex,
  degree : @core.Nat,
  fuel : @core.Nat,
) -> Computation {
  match (boundary(complex, degree), boundary(complex, Succ(degree))) {
    (Some(a), Some(b)) =>
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
                            source: complex,
                            degree,
                            result: actual,
                            boundary_form: form,
                            right_inverse: inverse,
                            coordinates,
                            image_form,
                          }
                          match check_result(complex, degree, actual, witness) {
                            true => Computed(witness)
                            false => InvalidWitness
                          }
                        }
                      }
                  }
              }
          }
      }
    _ => InvalidWitness
  }
}
