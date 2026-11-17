///|
/// A normalized residual column, with zeros in all preceding pivot rows.
/// Its witness expresses that column in the ORIGINAL independent-column order.
/// Witnesses omit trailing zeros belonging to columns inserted later.
#derive(Eq, Debug)
struct Column {
  pivot : @core.Nat
  vector : @core.Chain[@exact.Rational]
  witness : @core.Chain[@exact.Rational]
}

///|
pub extend Column with Eq::{equal, not_equal}

///|
pub extend Column with Debug::{to_repr}

///|
/// Immutable exact rational span. Constructors and fields are package private:
/// dimension is fixed and columns are independent, with one distinct pivot each.
#derive(Eq, Debug)
pub struct State {
  dimension : @core.Nat
  rank : @core.Nat
  columns : @core.Chain[Column]
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SpanError {
  DimensionMismatch
}

///|
pub extend SpanError with Eq::{equal, not_equal}

///|
pub extend SpanError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Insertion {
  /// The unique coefficients in the ORIGINAL independent-column order.
  /// The supplied state remains unchanged; no column is added.
  Dependent(@core.Chain[@exact.Rational])
  /// A new state with this independent vector appended to the original basis.
  Independent(State)
}

///|
pub extend Insertion with Eq::{equal, not_equal}

///|
pub extend Insertion with Debug::{to_repr}

///|
pub fn empty(dimension : @core.Nat) -> State {
  { dimension, rank: Zero, columns: Nil, }
}

///|
pub fn dimension(state : State) -> @core.Nat {
  state.dimension
}

///|
pub fn rank(state : State) -> @core.Nat {
  state.rank
}

///|
fn subtract_scaled(
  vector : @core.Chain[@exact.Rational],
  column : @core.Chain[@exact.Rational],
  factor : @exact.Rational,
) -> @core.Chain[@exact.Rational] {
  match (vector, column) {
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(
        @exact.rational_subtract(x, @exact.rational_multiply(factor, y)),
        subtract_scaled(xs, ys, factor),
      )
    _ => Nil
  }
}

///|
fn add_witness(
  accumulated : @core.Chain[@exact.Rational],
  witness : @core.Chain[@exact.Rational],
  factor : @exact.Rational,
) -> @core.Chain[@exact.Rational] {
  match (accumulated, witness) {
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(
        @exact.rational_add(x, @exact.rational_multiply(factor, y)),
        add_witness(xs, ys, factor),
      )
    (_, Nil) => accumulated
    _ => Nil
  }
}

///|
fn reduce(
  columns : @core.Chain[Column],
  vector : @core.Chain[@exact.Rational],
  coefficients : @core.Chain[@exact.Rational],
) -> (@core.Chain[@exact.Rational], @core.Chain[@exact.Rational]) {
  match columns {
    Nil => (vector, coefficients)
    Cons(column, rest) =>
      match @core.nth(vector, column.pivot) {
        Some(factor) =>
          if @exact.nonzero(factor) is None {
            reduce(rest, vector, coefficients)
          } else {
            reduce(
              rest,
              subtract_scaled(vector, column.vector, factor),
              add_witness(coefficients, column.witness, factor),
            )
          }
        // Unreachable for the opaque state and checked vector dimension.
        None => (vector, coefficients)
      }
  }
}

///|
fn first_nonzero(
  vector : @core.Chain[@exact.Rational],
  index : @core.Nat,
) -> (@core.Nat, @exact.Nonzero)? {
  match vector {
    Nil => None
    Cons(x, rest) =>
      match @exact.nonzero(x) {
        Some(proof) => Some((index, proof))
        None => first_nonzero(rest, Succ(index))
      }
  }
}

///|
/// Reduce only the incoming vector against cached exact columns. This is a
/// persistent operation: both the input state and every returned state can be
/// reused or branched independently. Zero vectors (also in dimension zero)
/// are dependent. Rank cannot exceed dimension because every insertion creates
/// a distinct pivot; at full rank all further vectors are dependent.
pub fn insert(
  state : State,
  vector : @core.Chain[@exact.Rational],
) -> Result[Insertion, SpanError] {
  if !@core.length(vector).equal(state.dimension) {
    return Err(DimensionMismatch)
  }
  let (residual, coefficients) = reduce(
    state.columns,
    vector,
    @core.replicate(state.rank, @exact.rational_zero()),
  )
  match first_nonzero(residual, Zero) {
    None => Ok(Dependent(coefficients))
    Some((pivot, proof)) => {
      let inverse = @exact.reciprocal(proof)
      let column : Column = {
        pivot,
        vector: @core.map(residual, fn(x) {
          @exact.rational_multiply(inverse, x)
        }),
        witness: @core.append(
          @core.map(coefficients, fn(x) {
            @exact.rational_negate(@exact.rational_multiply(inverse, x))
          }),
          Cons(inverse, Nil),
        ),
      }
      Ok(
        Independent({
          ..state,
          rank: Succ(state.rank),
          columns: @core.append(state.columns, Cons(column, Nil)),
        }),
      )
    }
  }
}
