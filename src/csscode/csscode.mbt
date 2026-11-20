///|
/// Binary field addition, shared with the GF2 kernel (not Boolean OR).
pub fn xor(a : Bool, b : Bool) -> Bool {
  @gf2.xor(a, b)
}

///|
pub fn field() -> @rowreduce.Field[Bool] {
  @gf2.field()
}

///|
pub fn scalars() -> @algebra.Semiring[Bool] {
  @gf2.scalars()
}

///|
#derive(Eq, Debug)
pub(all) enum Axis {
  X
  Z
}

///|
pub extend Axis with Eq::{equal, not_equal}

///|
pub extend Axis with Debug::{to_repr}

///|
/// R = U A, with an explicit inverse of U and a structurally checked RREF.
/// Checking this witness does not invoke row reduction or inverse search.
#derive(Eq, Debug)
pub(all) struct RankWitness {
  source : @matrix.Matrix[Bool]
  reduced : @matrix.Matrix[Bool]
  transform : @matrix.Matrix[Bool]
  inverse_transform : @matrix.Matrix[Bool]
  pivots : @core.Chain[@core.Nat]
}

///|
pub extend RankWitness with Eq::{equal, not_equal}

///|
pub extend RankWitness with Debug::{to_repr}

///|
fn first_true(row : @core.Chain[Bool], column : @core.Nat) -> @core.Nat? {
  match row {
    Nil => None
    Cons(true, _) => Some(column)
    Cons(false, rest) => first_true(rest, Succ(column))
  }
}

///|
fn canonical_pivots(input : @matrix.Matrix[Bool]) -> @core.Chain[@core.Nat]? {
  fn unit_column(
    rows : @core.Chain[@core.Chain[Bool]],
    column : @core.Nat,
    target : @core.Nat,
    index : @core.Nat,
  ) -> Bool {
    match rows {
      Nil => true
      Cons(row, rest) =>
        @core.nth(row, column).equal(Some(index.equal(target))) &&
        unit_column(rest, column, target, Succ(index))
    }
  }
  fn walk(
    rows : @core.Chain[@core.Chain[Bool]],
    previous : @core.Nat?,
    index : @core.Nat,
  ) -> @core.Chain[@core.Nat]? {
    match rows {
      Nil => Some(Nil)
      Cons(row, rest) =>
        match first_true(row, Zero) {
          None =>
            match @core.all(rest, fn(r) { @core.all(r, fn(x) { !x }) }) {
              true => Some(Nil)
              false => None
            }
          Some(pivot) => {
            let increasing = match previous {
              None => true
              Some(old) => @core.compare(old, pivot) is Less
            }
            match
              increasing && unit_column(@matrix.rows(input), pivot, index, Zero) {
              false => None
              true =>
                match walk(rest, Some(pivot), Succ(index)) {
                  None => None
                  Some(tail) => Some(Cons(pivot, tail))
                }
            }
          }
        }
    }
  }
  walk(@matrix.rows(input), None, Zero)
}

///|
/// Polynomial-size algebraic verification of the claimed rank and rowspace.
pub fn check_rank(input : @matrix.Matrix[Bool], witness : RankWitness) -> Bool {
  let height = @matrix.height(input)
  let identity = @matrix.identity(height, scalars())
  witness.source.equal(input) &&
  @matrix.width(witness.reduced).equal(@matrix.width(input)) &&
  @matrix.height(witness.reduced).equal(height) &&
  @matrix.height(witness.transform).equal(height) &&
  @matrix.width(witness.transform).equal(height) &&
  @matrix.height(witness.inverse_transform).equal(height) &&
  @matrix.width(witness.inverse_transform).equal(height) &&
  @matrix.multiply(witness.transform, input, scalars()).equal(
    Some(witness.reduced),
  ) &&
  @matrix.multiply(witness.transform, witness.inverse_transform, scalars()).equal(
    Some(identity),
  ) &&
  @matrix.multiply(witness.inverse_transform, witness.transform, scalars()).equal(
    Some(identity),
  ) &&
  canonical_pivots(witness.reduced).equal(Some(witness.pivots))
}

///|
fn rank_witness(input : @matrix.Matrix[Bool]) -> RankWitness? {
  match @gf2.factor(input) {
    None => None
    Some(factor) =>
      match @gf2.certificate(factor) {
        None => None
        Some(proof) => {
          let witness = RankWitness::{
            source: proof.source,
            reduced: proof.reduced,
            transform: proof.transform,
            inverse_transform: proof.inverse_transform,
            pivots: proof.pivots,
          }
          match check_rank(input, witness) {
            true => Some(witness)
            false => None
          }
        }
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Parameters {
  physical : @core.Nat
  rank_x : @core.Nat
  rank_z : @core.Nat
  logical : @core.Nat
}

///|
pub extend Parameters with Eq::{equal, not_equal}

///|
pub extend Parameters with Debug::{to_repr}

///|
/// A checked commuting pair of binary stabilizer matrices, with exact widths.
/// Redundant rows and empty matrices are allowed. This describes stabilizer
/// algebra; it does not represent or simulate quantum state amplitudes.
#derive(Eq, Debug)
pub struct Code {
  hx : @matrix.Matrix[Bool]
  hz : @matrix.Matrix[Bool]
  x_rank : RankWitness
  z_rank : RankWitness
}

///|
pub extend Code with Eq::{equal, not_equal}

///|
pub extend Code with Debug::{to_repr}

///|
pub fn checks(code : Code, axis : Axis) -> @matrix.Matrix[Bool] {
  match axis {
    X => code.hx
    Z => code.hz
  }
}

///|
pub fn parameters(code : Code) -> Parameters {
  let physical = @matrix.width(code.hx)
  let rank_x = @core.length(code.x_rank.pivots)
  let rank_z = @core.length(code.z_rank.pivots)
  {
    physical,
    rank_x,
    rank_z,
    logical: @core.subtract(physical, @core.add(rank_x, rank_z)),
  }
}

///|
pub fn commute(hx : @matrix.Matrix[Bool], hz : @matrix.Matrix[Bool]) -> Bool {
  let product_zero = match
    @matrix.multiply(hx, @matrix.transpose(hz), scalars()) {
    None => false
    Some(product) =>
      @core.all(@matrix.rows(product), fn(row) { @core.all(row, fn(x) { !x }) })
  }
  @matrix.width(hx).equal(@matrix.width(hz)) && product_zero
}

///|
/// Validate equal physical widths and Hx Hz^T = 0 over GF(2).
pub fn validate(hx : @matrix.Matrix[Bool], hz : @matrix.Matrix[Bool]) -> Code? {
  match commute(hx, hz) {
    false => None
    true =>
      match (rank_witness(hx), rank_witness(hz)) {
        (Some(x_rank), Some(z_rank)) => {
          let code = Code::{ hx, hz, x_rank, z_rank, }
          match
            @core.compare(
              @core.add(
                @core.length(x_rank.pivots),
                @core.length(z_rank.pivots),
              ),
              @matrix.width(hx),
            ) {
            Greater => None
            _ => Some(code)
          }
        }
        _ => None
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : Code
  result : Parameters
  x_rank : RankWitness
  z_rank : RankWitness
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
pub fn certificate(code : Code) -> Certificate {
  {
    source: code,
    result: parameters(code),
    x_rank: code.x_rank,
    z_rank: code.z_rank,
  }
}

///|
/// Bind both independently checked rank witnesses to the requested code/result.
pub fn check_parameters(
  code : Code,
  actual : Parameters,
  witness : Certificate,
) -> Bool {
  witness.source.equal(code) &&
  witness.result.equal(actual) &&
  commute(code.hx, code.hz) &&
  check_rank(code.hx, witness.x_rank) &&
  check_rank(code.hz, witness.z_rank) &&
  actual.physical.equal(@matrix.width(code.hx)) &&
  actual.rank_x.equal(@core.length(witness.x_rank.pivots)) &&
  actual.rank_z.equal(@core.length(witness.z_rank.pivots)) &&
  @core.add(actual.logical, @core.add(actual.rank_x, actual.rank_z)).equal(
    actual.physical,
  )
}

///|
fn dot(a : @core.Chain[Bool], b : @core.Chain[Bool]) -> Bool {
  match (a, b) {
    (Cons(x, xs), Cons(y, ys)) => xor(x && y, dot(xs, ys))
    _ => false
  }
}

///|
/// Syndrome of an X error uses Hz; syndrome of a Z error uses Hx.
/// None means the supplied error has the wrong physical width.
pub fn syndrome(
  code : Code,
  axis : Axis,
  error : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  match @core.length(error).equal(@matrix.width(code.hx)) {
    false => None
    true => {
      let opposite = match axis {
        X => code.hz
        Z => code.hx
      }
      Some(@core.map(@matrix.rows(opposite), fn(row) { dot(row, error) }))
    }
  }
}

///|
fn row_member(vector : @core.Chain[Bool], witness : RankWitness) -> Bool {
  fn reduce(
    vector : @core.Chain[Bool],
    rows : @core.Chain[@core.Chain[Bool]],
    pivots : @core.Chain[@core.Nat],
  ) -> Bool {
    match (rows, pivots) {
      (Cons(row, rest), Cons(pivot, tail)) => {
        let next = match @core.nth(vector, pivot) {
          Some(true) =>
            match @core.zip(vector, row) {
              Some(pairs) =>
                @core.map(pairs, fn(pair) {
                  let (x, y) = pair
                  xor(x, y)
                })
              None => vector
            }
          _ => vector
        }
        reduce(next, rest, tail)
      }
      _ => @core.all(vector, fn(x) { !x })
    }
  }
  reduce(vector, @matrix.rows(witness.reduced), witness.pivots)
}

///|
pub fn in_stabilizer(
  code : Code,
  axis : Axis,
  vector : @core.Chain[Bool],
) -> Bool? {
  match @core.length(vector).equal(@matrix.width(code.hx)) {
    false => None
    true =>
      Some(
        row_member(
          vector,
          match axis {
            X => code.x_rank
            Z => code.z_rank
          },
        ),
      )
  }
}

///|
/// X: ker(Hz) minus rowspace(Hx); Z: ker(Hx) minus rowspace(Hz).
pub fn is_logical(
  code : Code,
  axis : Axis,
  vector : @core.Chain[Bool],
) -> Bool? {
  match (syndrome(code, axis, vector), in_stabilizer(code, axis, vector)) {
    (Some(checks), Some(stabilizer)) =>
      Some(@core.all(checks, fn(x) { !x }) && !stabilizer)
    _ => None
  }
}

///|
pub fn weight(vector : @core.Chain[Bool]) -> @core.Nat {
  @core.fold_left(vector, Zero, fn(sum, bit) {
    match bit {
      true => Succ(sum)
      false => sum
    }
  })
}

///|
/// C_degree coordinates are physical qubits; Hx=d_degree mod 2 and
/// Hz=(d_(degree+1) mod 2)^T. Signed integer incidence reduces by parity,
/// preserving the exact matrix shapes including degree zero/empty complexes.
pub fn from_complex(complex : @homology.Complex, degree : @core.Nat) -> Code? {
  fn mod_two(input : @matrix.Matrix[@exact.Integer]) -> @matrix.Matrix[Bool]? {
    @matrix.matrix(
      @matrix.width(input),
      @core.map(@matrix.rows(input), fn(row) {
        @core.map(row, fn(value) { @binary.odd(@exact.magnitude(value)) })
      }),
    )
  }
  match
    (
      @homology.boundary(complex, degree),
      @homology.boundary(complex, Succ(degree)),
    ) {
    (Some(a), Some(b)) =>
      match (mod_two(a), mod_two(b)) {
        (Some(hx), Some(next)) => validate(hx, @matrix.transpose(next))
        _ => None
      }
    _ => None
  }
}
