///|
/// Exact binary addition, expressed without a numeric representation.
pub fn xor(a : Bool, b : Bool) -> Bool {
  match a {
    true => !b
    false => b
  }
}

///|
pub fn scalars() -> @algebra.Semiring[Bool] {
  { zero: false, one: true, plus: xor, times: fn(a, b) { a && b }, }
}

///|
pub fn field() -> @rowreduce.Field[Bool] {
  {
    zero: false,
    one: true,
    add: xor,
    subtract: xor,
    negate: fn(a) { a },
    multiply: fn(a, b) { a && b },
    inverse: fn(a) { if a { Some(true) } else { None } },
  }
}

///|
/// Each elementary operation is its own inverse over GF(2).
#derive(Eq, Debug)
pub enum Operation {
  Swap(@core.Nat, @core.Nat)
  Add(@core.Nat, @core.Nat)
}

///|
pub extend Operation with Eq::{equal, not_equal}

///|
pub extend Operation with Debug::{to_repr}

///|
/// A source-bound decomposition. The operation log is in reverse execution order;
/// inverse_transform replays it without a second Gaussian elimination.
#derive(Eq, Debug)
pub struct Factorization {
  source : @matrix.Matrix[Bool]
  reduction : @rowreduce.Reduction[Bool]
  transform : @matrix.Matrix[Bool]
  reverse_operations : @core.Chain[Operation]
}

///|
pub extend Factorization with Eq::{equal, not_equal}

///|
pub extend Factorization with Debug::{to_repr}

///|
fn xor_rows(
  row : @core.Chain[Bool],
  basis : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match (row, basis) {
    (Cons(x, xs), Cons(y, ys)) => Cons(xor(x, y), xor_rows(xs, ys))
    _ => row
  }
}

///|
/// Earlier columns are already zero in the basis, so only XOR the active suffix.
fn xor_suffix(
  row : @core.Chain[Bool],
  basis : @core.Chain[Bool],
  column : @core.Nat,
) -> @core.Chain[Bool] {
  match (column, row, basis) {
    (Zero, _, _) => xor_rows(row, basis)
    (Succ(rest), Cons(x, xs), Cons(_, ys)) => Cons(x, xor_suffix(xs, ys, rest))
    _ => row
  }
}

///|
fn eliminate(
  row : @core.Chain[Bool],
  basis : @core.Chain[Bool],
  column : @core.Nat,
) -> @core.Chain[Bool] {
  match @core.nth(row, column) {
    Some(true) => xor_suffix(row, basis, column)
    _ => row
  }
}

///|
/// Extract the first pivot, keeping all other rows in their original order.
fn select(
  rows : @core.Chain[@core.Chain[Bool]],
  column : @core.Nat,
) -> (@core.Chain[Bool], @core.Chain[@core.Chain[Bool]], @core.Nat)? {
  match rows {
    Nil => None
    Cons(row, rest) =>
      match @core.nth(row, column) {
        Some(true) => Some((row, rest, Zero))
        _ =>
          match select(rest, column) {
            None => None
            Some((chosen, others, index)) =>
              Some((chosen, Cons(row, others), Succ(index)))
          }
      }
  }
}

///|
/// Extracting row k is the sequence of adjacent swaps k/k-1,...,1/0.
fn log_selection(
  index : @core.Nat,
  base : @core.Nat,
  operations : @core.Chain[Operation],
) -> @core.Chain[Operation] {
  match index {
    Zero => operations
    Succ(previous) =>
      log_selection(
        previous,
        base,
        Cons(
          Swap(@core.add(base, index), @core.add(base, previous)),
          operations,
        ),
      )
  }
}

///|
fn reduce(
  rows : @core.Chain[@core.Chain[Bool]],
  todo : @core.Nat,
  column : @core.Nat,
  base : @core.Nat,
  tracked : Bool,
  operations : @core.Chain[Operation],
) -> (
  @core.Chain[@core.Chain[Bool]],
  @core.Chain[@core.Nat],
  @core.Chain[Operation],
) {
  match todo {
    Zero => (rows, Nil, operations)
    Succ(rest) =>
      match select(rows, column) {
        None => reduce(rows, rest, Succ(column), base, tracked, operations)
        Some((chosen, others, index)) => {
          let selected = if tracked {
            log_selection(index, base, operations)
          } else {
            operations
          }
          fn below(
            rows : @core.Chain[@core.Chain[Bool]],
            target : @core.Nat,
            log : @core.Chain[Operation],
          ) -> (@core.Chain[@core.Chain[Bool]], @core.Chain[Operation]) {
            match rows {
              Nil => (Nil, log)
              Cons(row, tail) => {
                let nonzero = @core.nth(row, column) is Some(true)
                let next : @core.Chain[Operation] = if tracked && nonzero {
                  Cons(Add(target, base), log)
                } else {
                  log
                }
                let (lower, finished) = below(tail, Succ(target), next)
                (
                  Cons(
                    if nonzero {
                      xor_suffix(row, chosen, column)
                    } else {
                      row
                    },
                    lower,
                  ),
                  finished,
                )
              }
            }
          }
          let (lower, below_log) = below(others, Succ(base), selected)
          let (reduced, pivots, lower_log) = reduce(
            lower,
            rest,
            Succ(column),
            Succ(base),
            tracked,
            below_log,
          )
          fn above(
            row : @core.Chain[Bool],
            bases : @core.Chain[@core.Chain[Bool]],
            pivots : @core.Chain[@core.Nat],
            source : @core.Nat,
            log : @core.Chain[Operation],
          ) -> (@core.Chain[Bool], @core.Chain[Operation]) {
            match (bases, pivots) {
              (Cons(basis, bt), Cons(pivot, pt)) => {
                let nonzero = @core.nth(row, pivot) is Some(true)
                let next : @core.Chain[Operation] = if tracked && nonzero {
                  Cons(Add(base, source), log)
                } else {
                  log
                }
                above(eliminate(row, basis, pivot), bt, pt, Succ(source), next)
              }
              _ => (row, log)
            }
          }
          let (top, finished) = above(
            chosen,
            reduced,
            pivots,
            Succ(base),
            lower_log,
          )
          (Cons(top, reduced), Cons(column, pivots), finished)
        }
      }
  }
}

///|
/// No normalization, field dictionary, operation log, or transform is needed.
pub fn rref(input : @matrix.Matrix[Bool]) -> @rowreduce.Reduction[Bool]? {
  let (rows, pivots, _) = reduce(
    @matrix.rows(input),
    @matrix.width(input),
    Zero,
    Zero,
    false,
    Nil,
  )
  match @matrix.matrix(@matrix.width(input), rows) {
    None => None
    Some(matrix) => Some({ matrix, pivots, factor: true, })
  }
}

///|
pub fn factor(input : @matrix.Matrix[Bool]) -> Factorization? {
  let width = @matrix.width(input)
  let height = @matrix.height(input)
  let identity = @matrix.identity(height, scalars())
  match @core.zip(@matrix.rows(input), @matrix.rows(identity)) {
    None => None
    Some(pairs) => {
      let augmented = @core.map(pairs, fn(pair) {
        let (row, unit) = pair
        @core.append(row, unit)
      })
      let (rows, pivots, reverse_operations) = reduce(
        augmented,
        width,
        Zero,
        Zero,
        true,
        Nil,
      )
      match
        (
          @matrix.matrix(
            width,
            @core.map(rows, fn(row) { @core.take(width, row) }),
          ),
          @matrix.matrix(
            height,
            @core.map(rows, fn(row) { @core.drop(width, row) }),
          ),
        ) {
        (Some(matrix), Some(transform)) =>
          Some({
            source: input,
            reduction: { matrix, pivots, factor: true, },
            transform,
            reverse_operations,
          })
        _ => None
      }
    }
  }
}

///|
pub fn source(value : Factorization) -> @matrix.Matrix[Bool] {
  value.source
}

///|
pub fn reduction(value : Factorization) -> @rowreduce.Reduction[Bool] {
  value.reduction
}

///|
pub fn transform(value : Factorization) -> @matrix.Matrix[Bool] {
  value.transform
}

///|
fn[A] replace(
  rows : @core.Chain[A],
  index : @core.Nat,
  value : A,
) -> @core.Chain[A] {
  match (rows, index) {
    (Nil, _) => Nil
    (Cons(_, rest), Zero) => Cons(value, rest)
    (Cons(row, rest), Succ(previous)) =>
      Cons(row, replace(rest, previous, value))
  }
}

///|
fn apply_operation(
  rows : @core.Chain[@core.Chain[Bool]],
  operation : Operation,
) -> @core.Chain[@core.Chain[Bool]] {
  match operation {
    Swap(a, b) =>
      match (@core.nth(rows, a), @core.nth(rows, b)) {
        (Some(x), Some(y)) => replace(replace(rows, a, y), b, x)
        _ => rows
      }
    Add(target, source) =>
      match (@core.nth(rows, target), @core.nth(rows, source)) {
        (Some(row), Some(basis)) => replace(rows, target, xor_rows(row, basis))
        _ => rows
      }
  }
}

///|
pub fn inverse_transform(value : Factorization) -> @matrix.Matrix[Bool]? {
  let height = @matrix.height(value.source)
  let rows = @core.fold_left(
    value.reverse_operations,
    @matrix.rows(@matrix.identity(height, scalars())),
    apply_operation,
  )
  @matrix.matrix(height, rows)
}

///|
/// Initially retain the independent generic matrix checker as the trust boundary.
pub fn multiply(
  a : @matrix.Matrix[Bool],
  b : @matrix.Matrix[Bool],
) -> @matrix.Matrix[Bool]? {
  @matrix.multiply(a, b, scalars())
}

///|
/// A concrete algebraic witness, compatible with CSS rank witnesses.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @matrix.Matrix[Bool]
  reduced : @matrix.Matrix[Bool]
  transform : @matrix.Matrix[Bool]
  inverse_transform : @matrix.Matrix[Bool]
  pivots : @core.Chain[@core.Nat]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
pub fn certificate(value : Factorization) -> Certificate? {
  match inverse_transform(value) {
    None => None
    Some(inverse_transform) =>
      Some({
        source: value.source,
        reduced: value.reduction.matrix,
        transform: value.transform,
        inverse_transform,
        pivots: value.reduction.pivots,
      })
  }
}

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
            if @core.all(rest, fn(row) { @core.all(row, fn(x) { !x }) }) {
              Some(Nil)
            } else {
              None
            }
          Some(pivot) => {
            let increasing = match previous {
              None => true
              Some(old) => @core.compare(old, pivot) is Less
            }
            if increasing &&
              unit_column(@matrix.rows(input), pivot, index, Zero) {
              match walk(rest, Some(pivot), Succ(index)) {
                None => None
                Some(tail) => Some(Cons(pivot, tail))
              }
            } else {
              None
            }
          }
        }
    }
  }
  walk(@matrix.rows(input), None, Zero)
}

///|
/// Verify the supplied source AND supplied reduction; do not trust embedded claims.
/// This checker performs multiplication and structural RREF checks, no elimination.
pub fn check_certificate(
  input : @matrix.Matrix[Bool],
  result : @rowreduce.Reduction[Bool],
  witness : Certificate,
) -> Bool {
  let height = @matrix.height(input)
  let identity = @matrix.identity(height, scalars())
  witness.source.equal(input) &&
  witness.reduced.equal(result.matrix) &&
  witness.pivots.equal(result.pivots) &&
  result.factor &&
  @matrix.width(witness.reduced).equal(@matrix.width(input)) &&
  @matrix.height(witness.reduced).equal(height) &&
  @matrix.height(witness.transform).equal(height) &&
  @matrix.width(witness.transform).equal(height) &&
  @matrix.height(witness.inverse_transform).equal(height) &&
  @matrix.width(witness.inverse_transform).equal(height) &&
  multiply(witness.transform, input).equal(Some(witness.reduced)) &&
  multiply(witness.transform, witness.inverse_transform).equal(Some(identity)) &&
  multiply(witness.inverse_transform, witness.transform).equal(Some(identity)) &&
  canonical_pivots(witness.reduced).equal(Some(witness.pivots))
}
