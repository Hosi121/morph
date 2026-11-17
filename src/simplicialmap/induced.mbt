///|
/// Witness for the induced integral homology homomorphism in full Smith
/// coordinates. Unit diagonal slots remain present and have canonical value
/// zero. Torsion slots contain positive residues; free slots are signed.
/// The fields are public for independently generated, checkable witnesses.
#derive(Eq, Debug)
pub(all) struct HomologyMap {
  map : SimplicialMap
  degree : @core.Nat
  source_homology : @homology.Certificate
  target_homology : @homology.Certificate
  cycle_map : @matrix.Matrix[@exact.Integer]
  source_left_inverse : @matrix.Matrix[@exact.Integer]
  classes : @matrix.Matrix[@exact.Integer]
}

///|
pub extend HomologyMap with Eq::{equal, not_equal}

///|
pub extend HomologyMap with Debug::{to_repr}

///|
fn cycle_coordinates(
  map : SimplicialMap,
  degree : @core.Nat,
  source_homology : @homology.Certificate,
  target_homology : @homology.Certificate,
) -> @matrix.Matrix[@exact.Integer]? {
  match chain_map(map, degree) {
    None => None
    Some(f) =>
      match
        @matrix.matrix(@matrix.width(f), @homology.cycle_basis(source_homology)) {
        None => None
        Some(basis_rows) =>
          match @matrix.multiply(f, @matrix.transpose(basis_rows), integers()) {
            None => None
            Some(images) =>
              @matrix.multiply(
                target_homology.right_inverse,
                images,
                integers(),
              )
          }
      }
  }
}

///|
fn canonical_columns(
  target_homology : @homology.Certificate,
  cycle_map : @matrix.Matrix[@exact.Integer],
  source_left_inverse : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  fn normalize(
    group : @smith.Cokernel,
    columns : @core.Chain[@core.Chain[@exact.Integer]],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match columns {
      Nil => Some(Nil)
      Cons(column, rest) =>
        match
          (@smith.class_coordinates(group, column), normalize(group, rest)) {
          (Some(column), Some(rest)) => Some(Cons(column, rest))
          _ => None
        }
    }
  }
  match @matrix.multiply(cycle_map, source_left_inverse, integers()) {
    None => None
    Some(lift) => {
      let columns = @matrix.rows(@matrix.transpose(lift))
      // Empty products retain the old path without preparing a cokernel.
      let normalized : @core.Chain[@core.Chain[@exact.Integer]]? = match
        columns {
        Nil => Some(Nil)
        Cons(_, _) =>
          normalize(@smith.cokernel(target_homology.image_form), columns)
      }
      match normalized {
        None => None
        Some(columns) =>
          match @matrix.matrix(@matrix.height(lift), columns) {
            None => None
            Some(rows) => Some(@matrix.transpose(rows))
          }
      }
    }
  }
}

///|
fn boundary_descent(witness : HomologyMap) -> Bool {
  let s = witness.source_homology
  let t = witness.target_homology
  match
    (
      bottom(s.coordinates, @smith.rank(s.boundary_form)),
      bottom(t.coordinates, @smith.rank(t.boundary_form)),
      chain_map(witness.map, Succ(witness.degree)),
    ) {
    (Some(cs), Some(ct), Some(next)) =>
      match
        (
          @matrix.multiply(witness.cycle_map, cs, integers()),
          @matrix.multiply(ct, next, integers()),
        ) {
        (Some(left), Some(right)) => left.equal(right)
        _ => false
      }
    _ => false
  }
}

///|
/// Binds the witness to the requested simplicial map, degree and returned
/// canonical matrix. Rechecks both homology certificates, both source Smith
/// inverse identities, cycle images, boundary descent and target reduction.
/// This checker runs no Smith search or matrix inversion.
pub fn check_induced(
  map : SimplicialMap,
  degree : @core.Nat,
  actual : @matrix.Matrix[@exact.Integer],
  witness : HomologyMap,
) -> Bool {
  let s = witness.source_homology
  let t = witness.target_homology
  let bound = witness.map.equal(map) &&
    witness.degree.equal(degree) &&
    witness.classes.equal(actual) &&
    @homology.check_result(source(map), degree, s.result, s) &&
    @homology.check_result(target(map), degree, t.result, t)
  match bound {
    false => false
    true =>
      match cycle_coordinates(map, degree, s, t) {
        None => false
        Some(coordinates) => {
          let rank = @smith.rank(t.boundary_form)
          inverse_pair(@smith.left(s.image_form), witness.source_left_inverse) &&
          chain_identity(map, degree) &&
          chain_identity(map, Succ(degree)) &&
          leading_zero(coordinates, rank) &&
          bottom(coordinates, rank).equal(Some(witness.cycle_map)) &&
          boundary_descent(witness) &&
          canonical_columns(t, witness.cycle_map, witness.source_left_inverse).equal(
            Some(actual),
          )
        }
      }
  }
}

///|
/// Induced map using existing checked homology certificates. If Z_s denotes
/// the source cycle basis, M is bottom(V_t^-1 F_k Z_s). Input Smith classes
/// q_s are lifted by U_s^-1, mapped by M, then reduced after target U_t.
/// Rational inversion only produces a candidate U_s^-1; two integer inverse
/// identities and all source/result bindings are checked before returning.
pub fn induce(
  map : SimplicialMap,
  degree : @core.Nat,
  source_homology : @homology.Certificate,
  target_homology : @homology.Certificate,
) -> HomologyMap? {
  let valid = @homology.check_result(
      source(map),
      degree,
      source_homology.result,
      source_homology,
    ) &&
    @homology.check_result(
      target(map),
      degree,
      target_homology.result,
      target_homology,
    )
  match valid {
    false => None
    true =>
      match
        (
          cycle_coordinates(map, degree, source_homology, target_homology),
          integer_inverse(@smith.left(source_homology.image_form)),
        ) {
        (Some(coordinates), Some(source_left_inverse)) =>
          match
            bottom(coordinates, @smith.rank(target_homology.boundary_form)) {
            None => None
            Some(cycle_map) =>
              match
                canonical_columns(
                  target_homology, cycle_map, source_left_inverse,
                ) {
                None => None
                Some(classes) => {
                  let witness = HomologyMap::{
                    map,
                    degree,
                    source_homology,
                    target_homology,
                    cycle_map,
                    source_left_inverse,
                    classes,
                  }
                  match check_induced(map, degree, classes, witness) {
                    true => Some(witness)
                    false => None
                  }
                }
              }
          }
        _ => None
      }
  }
}

///|
/// Apply to a full source Smith-coordinate vector. Any representative is
/// accepted, including negative torsion representatives; output is canonical.
/// Rechecks the public witness, rejecting invalid fields or vector dimensions.
pub fn apply(
  witness : HomologyMap,
  smith_coordinates : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  match check_induced(witness.map, witness.degree, witness.classes, witness) {
    false => None
    true =>
      match apply_matrix(witness.source_left_inverse, smith_coordinates) {
        None => None
        Some(cycle_coordinates) =>
          match apply_matrix(witness.cycle_map, cycle_coordinates) {
            None => None
            Some(image) =>
              @smith.class_coordinates(
                @smith.cokernel(witness.target_homology.image_form),
                image,
              )
          }
      }
  }
}
