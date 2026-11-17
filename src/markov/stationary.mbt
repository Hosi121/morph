///|
/// All normalized stationary linear solutions are origin + sum(t_i direction_i).
/// This is an affine space, not a claim that every parameter denotes a
/// probability distribution. Coordinatewise nonnegativity is additionally
/// required and is checked by stationary_member. Origin itself may be signed.
/// The context is retained, so a family cannot be used with another kernel.
#derive(Eq, Debug)
pub struct StationaryFamily {
  context : Kernel
  origin : @core.Chain[@exact.Rational]
  directions : @core.Chain[@core.Chain[@exact.Rational]]
}

///|
pub extend StationaryFamily with Eq::{equal, not_equal}

///|
pub extend StationaryFamily with Debug::{to_repr}

///|
pub fn stationary_kernel(family : StationaryFamily) -> Kernel {
  family.context
}

///|
/// An affine origin, not an unchecked probability distribution.
pub fn stationary_origin(
  family : StationaryFamily,
) -> @core.Chain[@exact.Rational] {
  family.origin
}

///|
/// Independent signed directions. Each has total mass zero and satisfies v P=v.
pub fn stationary_directions(
  family : StationaryFamily,
) -> @core.Chain[@core.Chain[@exact.Rational]] {
  family.directions
}

///|
fn subtract_rows(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational]? {
  match @core.zip(a, b) {
    None => None
    Some(pairs) =>
      Some(
        @core.map(pairs, fn(pair) {
          let (x, y) = pair
          @exact.rational_subtract(x, y)
        }),
      )
  }
}

///|
/// Column unknowns pi solve (P^T-I) pi=0 together with sum(pi)=1.
fn stationary_system(value : Kernel) -> @matrix.Matrix[@exact.Rational]? {
  fn rows(
    a : @core.Chain[@core.Chain[@exact.Rational]],
    b : @core.Chain[@core.Chain[@exact.Rational]],
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match (a, b) {
      (Nil, Nil) =>
        Some(Cons(@core.replicate(states(value), @exact.rational_one()), Nil))
      (Cons(x, xs), Cons(y, ys)) =>
        match (subtract_rows(x, y), rows(xs, ys)) {
          (Some(row), Some(rest)) => Some(Cons(row, rest))
          _ => None
        }
      _ => None
    }
  }
  match
    rows(
      @matrix.rows(@matrix.transpose(value.transition)),
      @matrix.rows(@matrix.identity(states(value), arithmetic())),
    ) {
    None => None
    Some(equations) => @matrix.matrix(states(value), equations)
  }
}

///|
fn linear_stationary(
  value : Kernel,
  vector : @core.Chain[@exact.Rational],
  mass : @exact.Rational,
) -> Bool {
  @core.length(vector).equal(states(value)) &&
  sum(vector).equal(mass) &&
  @core.all(@core.indices(states(value)), fn(index) {
    coordinate_equal(value, vector, vector, index)
  })
}

///|
/// Checks the original scalar equations, normalization, independence, and full
/// nullity. Rank checks use the existing exact RREF, not the producer's solve
/// result. Core/exact/RREF remain shared dependencies, not an independent oracle.
pub fn check_stationary_family(
  value : Kernel,
  family : StationaryFamily,
) -> Bool {
  if !value.equal(family.context) ||
    !linear_stationary(value, family.origin, @exact.rational_one()) ||
    !@core.all(family.directions, fn(direction) {
      linear_stationary(value, direction, @exact.rational_zero())
    }) {
    false
  } else {
    match
      (
        stationary_system(value),
        @matrix.matrix(states(value), family.directions),
      ) {
      (Some(equations), Some(directions)) =>
        match (@linear.rref(equations), @linear.rref(directions)) {
          (Some(system), Some(basis)) => {
            let dimension = @core.length(basis.pivots)
            dimension.equal(@core.length(family.directions)) &&
            @core.add(@core.length(system.pivots), dimension).equal(
              states(value),
            )
          }
          _ => false
        }
      _ => false
    }
  }
}

///|
/// Complete normalized affine solution, with no irreducibility or aperiodicity
/// assumption. Nonnegative members, and only those, are stationary distributions.
pub fn stationary_affine(
  value : Kernel,
) -> Result[StationaryFamily, MarkovError] {
  match stationary_system(value) {
    None => Err(InternalInvariant)
    Some(equations) => {
      let rhs = @core.append(
        @core.replicate(states(value), @exact.rational_zero()),
        Cons(@exact.rational_one(), Nil),
      )
      let candidate = match @linear.solve(equations, rhs) {
        Some(Unique(origin)) =>
          Some(StationaryFamily::{ context: value, origin, directions: Nil, })
        Some(Affine(origin, directions)) =>
          Some(StationaryFamily::{ context: value, origin, directions, })
        _ => None
      }
      match candidate {
        Some(family) =>
          if check_stationary_family(value, family) {
            Ok(family)
          } else {
            Err(InternalInvariant)
          }
        None => Err(InternalInvariant)
      }
    }
  }
}

///|
pub fn check_stationary(
  value : Kernel,
  distribution : @core.Chain[@exact.Rational],
) -> Bool {
  check_evolution(value, distribution, distribution)
}

///|
/// Parameters are arbitrary rational numbers, not probabilities. The resulting
/// vector must satisfy coordinatewise nonnegativity; parameters outside that
/// polytope return NegativeProbability. No arbitrary affine member is selected.
pub fn stationary_member(
  family : StationaryFamily,
  parameters : @core.Chain[@exact.Rational],
) -> Result[@core.Chain[@exact.Rational], MarkovError] {
  fn combine(
    parameters : @core.Chain[@exact.Rational],
    directions : @core.Chain[@core.Chain[@exact.Rational]],
    current : @core.Chain[@exact.Rational],
  ) -> @core.Chain[@exact.Rational]? {
    match (parameters, directions) {
      (Nil, Nil) => Some(current)
      (Cons(parameter, tail), Cons(direction, rest)) =>
        match scaled_add(parameter, direction, current) {
          None => None
          Some(updated) => combine(tail, rest, updated)
        }
      _ => None
    }
  }
  if !@core.length(parameters).equal(@core.length(family.directions)) {
    Err(DimensionMismatch)
  } else {
    match combine(parameters, family.directions, family.origin) {
      None => Err(InternalInvariant)
      Some(distribution) =>
        match probability(states(family.context), distribution) {
          Err(error) => Err(error)
          Ok(_) =>
            if check_stationary(family.context, distribution) {
              Ok(distribution)
            } else {
              Err(InternalInvariant)
            }
        }
    }
  }
}

///|
/// Returns a checked unique distribution, or an explicit nonuniqueness result.
/// Uniqueness does not imply convergence of successive distributions.
pub fn unique_stationary(
  value : Kernel,
) -> Result[@core.Chain[@exact.Rational], MarkovError] {
  match stationary_affine(value) {
    Err(error) => Err(error)
    Ok(family) =>
      match family.directions {
        Nil => stationary_member(family, Nil)
        Cons(_, _) => Err(NonUniqueStationary)
      }
  }
}
