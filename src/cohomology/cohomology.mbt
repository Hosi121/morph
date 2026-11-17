///|
/// Explicit bases of B and representatives of a basis of H over GF(2).
#derive(Eq, Debug)
pub(all) struct Group {
  rank : @core.Nat
  coboundaries : @core.Chain[@core.Chain[Bool]]
  representatives : @core.Chain[@core.Chain[Bool]]
}

///|
pub extend Group with Eq::{equal, not_equal}

///|
pub extend Group with Debug::{to_repr}

///|
/// Columns of basis are B, H, and a complement of cocycles, in that order.
/// The inverse and incoming coordinates certify completeness without rerunning
/// row reduction. Both rank witnesses are checked by csscode.check_rank.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @homology.Complex
  degree : @core.Nat
  result : Group
  outgoing_rank : @csscode.RankWitness
  incoming_rank : @csscode.RankWitness
  basis : @matrix.Matrix[Bool]
  inverse_basis : @matrix.Matrix[Bool]
  incoming_coordinates : @matrix.Matrix[Bool]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// An immutable, checked cohomology space. Constructors remain private.
#derive(Eq, Debug)
pub struct Cohomology {
  witness : Certificate
}

///|
pub extend Cohomology with Eq::{equal, not_equal}

///|
pub extend Cohomology with Debug::{to_repr}

///|
pub fn certificate(space : Cohomology) -> Certificate {
  space.witness
}

///|
pub fn result(space : Cohomology) -> Group {
  space.witness.result
}

///|
fn zero_vector(vector : @core.Chain[Bool]) -> Bool {
  @core.all(vector, fn(value) { !value })
}

///|
fn zero_matrix(input : @matrix.Matrix[Bool]) -> Bool {
  @core.all(@matrix.rows(input), zero_vector)
}

///|
fn parity(input : @matrix.Matrix[@exact.Integer]) -> @matrix.Matrix[Bool]? {
  @matrix.matrix(
    @matrix.width(input),
    @core.map(@matrix.rows(input), fn(row) {
      @core.map(row, fn(value) { @binary.odd(@exact.magnitude(value)) })
    }),
  )
}

///|
/// Ordinary, unreduced simplicial coboundary delta_k = d_(k+1)^T mod two.
pub fn coboundary(
  source : @homology.Complex,
  degree : @core.Nat,
) -> @matrix.Matrix[Bool]? {
  match @homology.boundary(source, Succ(degree)) {
    None => None
    Some(boundary) =>
      match parity(boundary) {
        None => None
        Some(binary) => Some(@matrix.transpose(binary))
      }
  }
}

///|
fn incoming(
  source : @homology.Complex,
  degree : @core.Nat,
) -> @matrix.Matrix[Bool]? {
  match @homology.boundary(source, degree) {
    None => None
    Some(boundary) =>
      match parity(boundary) {
        None => None
        Some(binary) => Some(@matrix.transpose(binary))
      }
  }
}

///|
fn rank_witness(input : @matrix.Matrix[Bool]) -> @csscode.RankWitness? {
  match @matrix.matrix(@matrix.width(input), Nil) {
    None => None
    Some(empty) =>
      match @csscode.validate(input, empty) {
        None => None
        Some(code) => Some(@csscode.certificate(code).x_rank)
      }
  }
}

///|
fn dot(left : @core.Chain[Bool], right : @core.Chain[Bool]) -> Bool {
  match (left, right) {
    (Cons(a, rest), Cons(b, tail)) => @csscode.xor(a && b, dot(rest, tail))
    _ => false
  }
}

///|
fn apply_matrix(
  matrix : @matrix.Matrix[Bool],
  vector : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  match @matrix.width(matrix).equal(@core.length(vector)) {
    false => None
    true => Some(@core.map(@matrix.rows(matrix), fn(row) { dot(row, vector) }))
  }
}

///|
fn columns(input : @matrix.Matrix[Bool]) -> @core.Chain[@core.Chain[Bool]] {
  @matrix.rows(@matrix.transpose(input))
}

///|
fn select_columns(
  input : @matrix.Matrix[Bool],
  indices : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Chain[Bool]]? {
  match indices {
    Nil => Some(Nil)
    Cons(index, rest) =>
      match (@matrix.column(input, index), select_columns(input, rest)) {
        (Some(column), Some(tail)) => Some(Cons(column, tail))
        _ => None
      }
  }
}

///|
/// Verify the actual group, source, degree, matrix identities, and dimensions.
/// This checker invokes no solver, inverse search, or row reduction.
pub fn check_result(
  source : @homology.Complex,
  degree : @core.Nat,
  actual : Group,
  witness : Certificate,
) -> Bool {
  match (coboundary(source, degree), incoming(source, degree)) {
    (Some(delta), Some(previous)) => {
      let n = @matrix.width(delta)
      let b = @core.length(witness.incoming_rank.pivots)
      let h = @core.length(actual.representatives)
      let cycle_count = @core.add(b, h)
      let identity = @matrix.identity(n, @csscode.scalars())
      let basis_columns = columns(witness.basis)
      let cycles = @core.take(cycle_count, basis_columns)
      witness.source.equal(source) &&
      witness.degree.equal(degree) &&
      witness.result.equal(actual) &&
      actual.rank.equal(h) &&
      @csscode.check_rank(delta, witness.outgoing_rank) &&
      @csscode.check_rank(previous, witness.incoming_rank) &&
      @core.add(cycle_count, @core.length(witness.outgoing_rank.pivots)).equal(
        n,
      ) &&
      @matrix.height(witness.basis).equal(n) &&
      @matrix.width(witness.basis).equal(n) &&
      @matrix.height(witness.inverse_basis).equal(n) &&
      @matrix.width(witness.inverse_basis).equal(n) &&
      @matrix.multiply(witness.basis, witness.inverse_basis, @csscode.scalars()).equal(
        Some(identity),
      ) &&
      @matrix.multiply(witness.inverse_basis, witness.basis, @csscode.scalars()).equal(
        Some(identity),
      ) &&
      actual.coboundaries.equal(@core.take(b, basis_columns)) &&
      actual.representatives.equal(@core.take(h, @core.drop(b, basis_columns))) &&
      @core.all(cycles, fn(vector) {
        match apply_matrix(delta, vector) {
          Some(value) => zero_vector(value)
          None => false
        }
      }) &&
      @matrix.multiply(delta, previous, @csscode.scalars())
      .map(zero_matrix)
      .equal(Some(true)) &&
      @matrix.height(witness.incoming_coordinates).equal(n) &&
      @matrix.width(witness.incoming_coordinates).equal(@matrix.width(previous)) &&
      @core.all(
        @core.drop(b, @matrix.rows(witness.incoming_coordinates)),
        zero_vector,
      ) &&
      @matrix.multiply(
        witness.basis,
        witness.incoming_coordinates,
        @csscode.scalars(),
      ).equal(Some(previous))
    }
    _ => false
  }
}

///|
/// Import an untrusted certificate only after checking its entire basis.
pub fn validate_certificate(
  source : @homology.Complex,
  degree : @core.Nat,
  actual : Group,
  witness : Certificate,
) -> Cohomology? {
  match check_result(source, degree, actual, witness) {
    false => None
    true => Some({ witness, })
  }
}

///|
/// Compute ker(delta_k)/im(delta_(k-1)), preserving explicit representatives.
pub fn compute(source : @homology.Complex, degree : @core.Nat) -> Cohomology? {
  match (coboundary(source, degree), incoming(source, degree)) {
    (Some(delta), Some(previous)) =>
      match (rank_witness(delta), rank_witness(previous)) {
        (Some(outgoing_rank), Some(incoming_rank)) => {
          let n = @matrix.width(delta)
          let zero = @core.replicate(@matrix.height(delta), false)
          let kernel = match @rowreduce.solve(@csscode.field(), delta, zero) {
            Some(Affine(_, basis)) => Some(basis)
            Some(Unique(_)) => Some(Nil)
            _ => None
          }
          match (kernel, select_columns(previous, incoming_rank.pivots)) {
            (Some(kernel), Some(boundaries)) =>
              match @matrix.matrix(n, @core.append(boundaries, kernel)) {
                None => None
                Some(candidates) =>
                  match rank_witness(@matrix.transpose(candidates)) {
                    None => None
                    Some(cycle_rank) =>
                      match
                        select_columns(
                          @matrix.transpose(candidates),
                          cycle_rank.pivots,
                        ) {
                        None => None
                        Some(cycles) => {
                          let unit = @matrix.identity(n, @csscode.scalars())
                          match select_columns(unit, outgoing_rank.pivots) {
                            None => None
                            Some(complement) =>
                              match
                                @matrix.matrix(
                                  n,
                                  @core.append(cycles, complement),
                                ) {
                                None => None
                                Some(rows) => {
                                  let basis = @matrix.transpose(rows)
                                  match
                                    @rowreduce.inverse(@csscode.field(), basis) {
                                    None => None
                                    Some(inverse_basis) =>
                                      match
                                        @matrix.multiply(
                                          inverse_basis,
                                          previous,
                                          @csscode.scalars(),
                                        ) {
                                        None => None
                                        Some(incoming_coordinates) => {
                                          let representatives = @core.drop(
                                            @core.length(boundaries),
                                            cycles,
                                          )
                                          let result = Group::{
                                            rank: @core.length(representatives),
                                            coboundaries: boundaries,
                                            representatives,
                                          }
                                          let witness = Certificate::{
                                            source,
                                            degree,
                                            result,
                                            outgoing_rank,
                                            incoming_rank,
                                            basis,
                                            inverse_basis,
                                            incoming_coordinates,
                                          }
                                          validate_certificate(
                                            source, degree, result, witness,
                                          )
                                        }
                                      }
                                  }
                                }
                              }
                          }
                        }
                      }
                  }
              }
            _ => None
          }
        }
        _ => None
      }
    _ => None
  }
}

///|
/// Return quotient coordinates only for a correctly sized cocycle.
pub fn coordinates(
  space : Cohomology,
  cocycle : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  let witness = space.witness
  match apply_matrix(witness.inverse_basis, cocycle) {
    None => None
    Some(all) => {
      let b = @core.length(witness.result.coboundaries)
      let h = witness.result.rank
      match zero_vector(@core.drop(@core.add(b, h), all)) {
        false => None
        true => Some(@core.take(h, @core.drop(b, all)))
      }
    }
  }
}

///|
/// Choose the stored cocycle representative of a quotient coordinate vector.
pub fn representative(
  space : Cohomology,
  value : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  let witness = space.witness
  match @core.length(value).equal(witness.result.rank) {
    false => None
    true => {
      let b = @core.length(witness.result.coboundaries)
      let tail = @core.subtract(
        @matrix.width(witness.basis),
        @core.add(b, witness.result.rank),
      )
      apply_matrix(
        witness.basis,
        @core.append(
          @core.replicate(b, false),
          @core.append(value, @core.replicate(tail, false)),
        ),
      )
    }
  }
}

///|
/// Compare cocycles modulo coboundaries; malformed/noncocycle input is None.
pub fn equivalent(
  space : Cohomology,
  left : @core.Chain[Bool],
  right : @core.Chain[Bool],
) -> Bool? {
  match (coordinates(space, left), coordinates(space, right)) {
    (Some(a), Some(b)) => Some(a.equal(b))
    _ => None
  }
}
