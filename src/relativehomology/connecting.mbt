///|
/// Connecting homomorphism H_k(K,A) -> H_(k-1)(A), for positive k.
/// Matrices use full Smith coordinates, retaining unit slots as canonical zero.
/// Explicit lifts and descent witnesses make representative independence checkable.
#derive(Eq, Debug)
pub(all) struct ConnectingMap {
  source : Pair
  degree : @core.Nat
  source_homology : Certificate
  target_homology : @homology.Certificate
  lifted_cycles : @matrix.Matrix[@exact.Integer]
  boundary_cycles : @matrix.Matrix[@exact.Integer]
  cycle_map : @matrix.Matrix[@exact.Integer]
  source_left_inverse : @matrix.Matrix[@exact.Integer]
  boundary_descent : @matrix.Matrix[@exact.Integer]
  classes : @matrix.Matrix[@exact.Integer]
}

///|
pub extend ConnectingMap with Eq::{equal, not_equal}

///|
pub extend ConnectingMap with Debug::{to_repr}

///|
fn cycle_lift(
  source : Pair,
  degree : @core.Nat,
  source_homology : Certificate,
) -> @matrix.Matrix[@exact.Integer]? {
  match lift(source, degree) {
    None => None
    Some(l) =>
      match @matrix.matrix(@matrix.width(l), cycle_basis(source_homology)) {
        None => None
        Some(rows) =>
          @matrix.multiply(
            l,
            @matrix.transpose(rows),
            @chainhomology.integers(),
          )
      }
  }
}

///|
fn cycle_boundary(
  source : Pair,
  degree : @core.Nat,
  lifted : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  match degree {
    Zero => None
    Succ(previous) =>
      match
        (
          @homology.boundary(source.ambient, degree),
          inclusion(source, previous),
        ) {
        (Some(d), Some(i)) =>
          match @matrix.multiply(d, lifted, @chainhomology.integers()) {
            None => None
            Some(ambient_boundary) =>
              match
                @matrix.multiply(
                  @matrix.transpose(i),
                  ambient_boundary,
                  @chainhomology.integers(),
                ) {
                None => None
                Some(in_a) =>
                  match
                    @matrix.multiply(i, in_a, @chainhomology.integers()).equal(
                      Some(ambient_boundary),
                    ) {
                    true => Some(in_a)
                    false => None
                  }
              }
          }
        _ => None
      }
  }
}

///|
fn target_cycle_coordinates(
  target : @homology.Certificate,
  boundary_cycles : @matrix.Matrix[@exact.Integer],
) -> @matrix.Matrix[@exact.Integer]? {
  match
    @matrix.multiply(
      target.right_inverse,
      boundary_cycles,
      @chainhomology.integers(),
    ) {
    None => None
    Some(coordinates) => {
      let rank = @smith.rank(target.boundary_form)
      match @chainhomology.leading_zero(coordinates, rank) {
        false => None
        true => @chainhomology.bottom(coordinates, rank)
      }
    }
  }
}

///|
/// Negative A component of d_K applied to the next relative chain lift.
/// Its A boundary equals the connecting image of a relative boundary.
fn descent(
  source : Pair,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  match
    (
      inclusion(source, degree),
      @homology.boundary(source.ambient, Succ(degree)),
      lift(source, Succ(degree)),
    ) {
    (Some(i), Some(d), Some(l)) =>
      match @matrix.multiply(d, l, @chainhomology.integers()) {
        None => None
        Some(boundaries) =>
          match
            @matrix.multiply(
              @matrix.transpose(i),
              boundaries,
              @chainhomology.integers(),
            ) {
            None => None
            Some(in_a) =>
              @matrix.matrix(
                @matrix.width(in_a),
                @core.map(@matrix.rows(in_a), fn(row) {
                  @core.map(row, @exact.negate)
                }),
              )
          }
      }
    _ => None
  }
}

///|
fn checks_descent(witness : ConnectingMap) -> Bool {
  let s = witness.source_homology.chain
  let t = witness.target_homology
  match
    (
      @chainhomology.bottom(s.coordinates, @smith.rank(s.boundary_form)),
      @chainhomology.bottom(t.coordinates, @smith.rank(t.boundary_form)),
      @homology.boundary(witness.source.subcomplex, witness.degree),
    ) {
    (Some(cs), Some(ct), Some(da)) =>
      match
        (
          @matrix.multiply(
            witness.boundary_cycles,
            cs,
            @chainhomology.integers(),
          ),
          @matrix.multiply(
            da,
            witness.boundary_descent,
            @chainhomology.integers(),
          ),
          @matrix.multiply(witness.cycle_map, cs, @chainhomology.integers()),
          @matrix.multiply(
            ct,
            witness.boundary_descent,
            @chainhomology.integers(),
          ),
        ) {
        (
          Some(chain_left),
          Some(chain_right),
          Some(cycle_left),
          Some(cycle_right),
        ) =>
          descent(witness.source, witness.degree).equal(
            Some(witness.boundary_descent),
          ) &&
          chain_left.equal(chain_right) &&
          cycle_left.equal(cycle_right)
        _ => false
      }
    _ => false
  }
}

///|
/// Binds to the actual pair, positive degree, source/target groups and result.
/// Rechecks chain lifts, boundaries in A, descent of relative boundaries, both
/// source Smith inverse identities, and canonical target Smith coordinates.
/// No Smith search or rational inversion runs in this checker.
pub fn check_connecting(
  source : Pair,
  degree : @core.Nat,
  actual : @matrix.Matrix[@exact.Integer],
  witness : ConnectingMap,
) -> Bool {
  match degree {
    Zero => false
    Succ(previous) => {
      let s = witness.source_homology
      let t = witness.target_homology
      witness.source.equal(source) &&
      witness.degree.equal(degree) &&
      witness.classes.equal(actual) &&
      check_result(source, degree, s.result, s) &&
      @homology.check_result(source.subcomplex, previous, t.result, t) &&
      cycle_lift(source, degree, s).equal(Some(witness.lifted_cycles)) &&
      cycle_boundary(source, degree, witness.lifted_cycles).equal(
        Some(witness.boundary_cycles),
      ) &&
      target_cycle_coordinates(t, witness.boundary_cycles).equal(
        Some(witness.cycle_map),
      ) &&
      @chainhomology.inverse_pair(
        @smith.left(s.chain.image_form),
        witness.source_left_inverse,
      ) &&
      checks_descent(witness) &&
      @chainhomology.canonical_columns(
        t.image_form,
        witness.cycle_map,
        witness.source_left_inverse,
      ).equal(Some(actual))
    }
  }
}

///|
/// Lift each relative cycle with zero A coefficients and take its boundary in A.
/// Convert using V_target inverse, then U_source inverse and U_target. Each
/// source Smith generator therefore denotes the correct integral class.
/// The unreduced sequence ends at H_0(K,A); degree zero returns None.
pub fn connect(
  source : Pair,
  degree : @core.Nat,
  source_homology : Certificate,
  target_homology : @homology.Certificate,
) -> ConnectingMap? {
  match degree {
    Zero => None
    Succ(previous) => {
      let valid = check_result(
          source,
          degree,
          source_homology.result,
          source_homology,
        ) &&
        @homology.check_result(
          source.subcomplex,
          previous,
          target_homology.result,
          target_homology,
        )
      match valid {
        false => None
        true =>
          match
            (
              cycle_lift(source, degree, source_homology),
              @chainhomology.integer_inverse(
                @smith.left(source_homology.chain.image_form),
              ),
              descent(source, degree),
            ) {
            (
              Some(lifted_cycles),
              Some(source_left_inverse),
              Some(boundary_descent),
            ) =>
              match cycle_boundary(source, degree, lifted_cycles) {
                None => None
                Some(boundary_cycles) =>
                  match
                    target_cycle_coordinates(target_homology, boundary_cycles) {
                    None => None
                    Some(cycle_map) =>
                      match
                        @chainhomology.canonical_columns(
                          target_homology.image_form,
                          cycle_map,
                          source_left_inverse,
                        ) {
                        None => None
                        Some(classes) => {
                          let witness = ConnectingMap::{
                            source,
                            degree,
                            source_homology,
                            target_homology,
                            lifted_cycles,
                            boundary_cycles,
                            cycle_map,
                            source_left_inverse,
                            boundary_descent,
                            classes,
                          }
                          match
                            check_connecting(source, degree, classes, witness) {
                            true => Some(witness)
                            false => None
                          }
                        }
                      }
                  }
              }
            _ => None
          }
      }
    }
  }
}

///|
/// Apply a checked connecting map to full source Smith coordinates. Negative
/// torsion representatives are accepted; target coordinates are canonical.
pub fn apply_connecting(
  witness : ConnectingMap,
  coordinates : @core.Chain[@exact.Integer],
) -> @core.Chain[@exact.Integer]? {
  match
    check_connecting(witness.source, witness.degree, witness.classes, witness) {
    false => None
    true =>
      match
        @chainhomology.apply_matrix(witness.source_left_inverse, coordinates) {
        None => None
        Some(cycles) =>
          match @chainhomology.apply_matrix(witness.cycle_map, cycles) {
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
