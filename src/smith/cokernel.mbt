///|
/// Z^m / image(A): checked Smith coordinates identify its free and torsion parts.
#derive(Eq, Debug)
pub struct Cokernel {
  form : Decomposition
  free : @core.Nat
  torsion : @core.Chain[@binary.Binary]
}

///|
pub extend Cokernel with Eq::{equal, not_equal}

///|
pub extend Cokernel with Debug::{to_repr}

///|
pub fn cokernel(form : Decomposition) -> Cokernel {
  {
    form,
    free: @core.subtract(@matrix.height(original(form)), rank(form)),
    torsion: @core.filter(invariant_factors(form), fn(value) {
      @binary.compare(value, @binary.one()) is Greater
    }),
  }
}

///|
pub fn free_rank(group : Cokernel) -> @core.Nat {
  group.free
}

///|
pub fn torsion_factors(group : Cokernel) -> @core.Chain[@binary.Binary] {
  group.torsion
}

///|
pub fn finite_order(group : Cokernel) -> @binary.Binary? {
  match group.free {
    Zero =>
      Some(@core.fold_left(group.torsion, @binary.one(), @binary.multiply))
    Succ(_) => None
  }
}

///|
fn positive_remainder(
  value : @exact.Integer,
  divisor : @binary.Binary,
) -> @exact.Integer? {
  match @binary.divmod(@exact.magnitude(value), divisor) {
    None => None
    Some((_, remainder)) =>
      match @exact.negative(value) && !@binary.is_zero(remainder) {
        false => Some(@exact.positive(remainder))
        true =>
          match @binary.subtract(divisor, remainder) {
            Some(value) => Some(@exact.positive(value))
            None => None
          }
      }
  }
}

///|
/// Canonical Smith-coordinate vector: positive residues on nonzero diagonal
/// positions, signed integers on free positions. These are coordinates after U.
pub fn class_coordinates(
  group : Cokernel,
  value : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  fn normalize(
    values : @core.Chain[@exact.Integer],
    index : @core.Nat,
  ) -> @core.Chain[@exact.Integer]? {
    match values {
      Nil => Some(Nil)
      Cons(value, rest) => {
        let divisor = match cell(diagonal(group.form), index, index) {
          Some(value) => @exact.magnitude(value)
          None => @binary.zero()
        }
        let value = match @binary.is_zero(divisor) {
          true => Some(value)
          false => positive_remainder(value, divisor)
        }
        match (value, normalize(rest, Succ(index))) {
          (Some(value), Some(rest)) => Some(Cons(value, rest))
          _ => None
        }
      }
    }
  }
  match apply(left(group.form), value) {
    Some(values) => normalize(values, Zero)
    None => None
  }
}

///|
/// False also rejects malformed vector dimensions. For valid vectors this is
/// equality in the presented abelian group, not equality of raw coordinates.
pub fn equivalent(
  group : Cokernel,
  a : @core.Chain[@exact.Integer],
  b : @core.Chain[@exact.Integer],
) -> Bool {
  match (class_coordinates(group, a), class_coordinates(group, b)) {
    (Some(a), Some(b)) => a.equal(b)
    _ => false
  }
}
