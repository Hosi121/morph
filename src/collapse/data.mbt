///|
/// An oriented codimension-one free face and its unique maximal coface.
/// Both use the increasing vertex order of homology.Complex.
#derive(Eq, Debug)
pub(all) struct Pair {
  lower : @core.Chain[@core.Nat]
  upper : @core.Chain[@core.Nat]
}

///|
pub extend Pair with Eq::{equal, not_equal}

///|
pub extend Pair with Debug::{to_repr}

///|
/// Column-vector conventions: inclusion C_k(target)->C_k(source), projection
/// C_k(source)->C_k(target), homotopy C_k(source)->C_(k+1)(source).
#derive(Eq, Debug)
pub(all) struct DegreeMaps {
  inclusion : @matrix.Matrix[@exact.Integer]
  projection : @matrix.Matrix[@exact.Integer]
  homotopy : @matrix.Matrix[@exact.Integer]
}

///|
pub extend DegreeMaps with Eq::{equal, not_equal}

///|
pub extend DegreeMaps with Debug::{to_repr}

///|
/// Public fields are untrusted. Accept through check with actual endpoints.
/// maps contains degrees zero through one beyond the source dimension; higher
/// groups and maps are the unique zero maps and have no stored coordinates.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @homology.Complex
  target : @homology.Complex
  pair : Pair
  orientation : @exact.Integer
  maps : @core.Chain[DegreeMaps]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
fn integers() -> @algebra.Semiring[@exact.Integer] {
  {
    zero: @exact.positive(@binary.zero()),
    one: @exact.positive(@binary.one()),
    plus: @exact.add,
    times: @exact.multiply,
  }
}

///|
fn same_simplex(a : @core.Chain[@core.Nat], b : @core.Chain[@core.Nat]) -> Bool {
  a.equal(b)
}

///|
fn has_simplex(
  simplex : @core.Chain[@core.Nat],
  faces : @core.Chain[@core.Chain[@core.Nat]],
) -> Bool {
  @core.any(faces, fn(face) { same_simplex(simplex, face) })
}

///|
fn top_size(source : @homology.Complex) -> @core.Nat {
  @core.fold_left(@homology.all_simplices(source), Zero, fn(size, simplex) {
    let candidate = @core.length(simplex)
    match @core.compare(size, candidate) {
      Less => candidate
      _ => size
    }
  })
}

///|
fn incidence(pair : Pair) -> @exact.Integer {
  fn walk(
    faces : @core.Chain[@core.Chain[@core.Nat]],
    positive : Bool,
  ) -> @exact.Integer {
    match faces {
      Nil => integers().zero
      Cons(face, rest) =>
        match same_simplex(face, pair.lower) {
          false => walk(rest, !positive)
          true => {
            let one = integers().one
            if positive {
              one
            } else {
              @exact.negate(one)
            }
          }
        }
    }
  }
  walk(@homology.faces(pair.upper), true)
}

///|
/// This is a direct check of the supplied pair, never a free-face search.
/// Requiring the exact deletion to remain a complex proves there are no other
/// cofaces of lower and no cofaces of upper, since their required faces vanish.
fn deletion(source : @homology.Complex, pair : Pair) -> @homology.Complex? {
  let faces = @homology.all_simplices(source)
  let lower_nonempty = match pair.lower {
    Nil => false
    _ => true
  }
  let valid = lower_nonempty &&
    @homology.validate(faces).equal(Some(source)) &&
    has_simplex(pair.lower, faces) &&
    has_simplex(pair.upper, faces) &&
    has_simplex(pair.lower, @homology.faces(pair.upper))
  if valid {
    @homology.validate(
      @core.filter(faces, fn(simplex) {
        !same_simplex(simplex, pair.lower) && !same_simplex(simplex, pair.upper)
      }),
    )
  } else {
    None
  }
}

///|
fn map_matrix(
  rows : @core.Chain[@core.Chain[@core.Nat]],
  columns : @core.Chain[@core.Chain[@core.Nat]],
  entry : (@core.Chain[@core.Nat], @core.Chain[@core.Nat]) -> @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(
    @core.length(columns),
    @core.map(rows, fn(row) {
      @core.map(columns, fn(column) { entry(row, column) })
    }),
  )
}

///|
fn delta(
  row : @core.Chain[@core.Nat],
  column : @core.Chain[@core.Nat],
) -> @exact.Integer {
  if same_simplex(row, column) {
    integers().one
  } else {
    integers().zero
  }
}

///|
fn inclusion(
  source : @homology.Complex,
  target : @homology.Complex,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  map_matrix(
    @homology.simplices(source, degree),
    @homology.simplices(target, degree),
    delta,
  )
}

///|
fn homotopy(
  source : @homology.Complex,
  pair : Pair,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  map_matrix(
    @homology.simplices(source, Succ(degree)),
    @homology.simplices(source, degree),
    fn(row, column) {
      if same_simplex(row, pair.upper) && same_simplex(column, pair.lower) {
        incidence(pair)
      } else {
        integers().zero
      }
    },
  )
}

///|
fn zero_map(
  height : @core.Nat,
  width : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(
    width,
    @core.replicate(height, @core.replicate(width, integers().zero)),
  )
}

///|
fn combine(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
  operation : (@exact.Integer, @exact.Integer) -> @exact.Integer,
) -> @matrix.Matrix[@exact.Integer]? {
  fn rows(
    todo : @core.Chain[
      (@core.Chain[@exact.Integer], @core.Chain[@exact.Integer]),
    ],
  ) -> @core.Chain[@core.Chain[@exact.Integer]]? {
    match todo {
      Nil => Some(Nil)
      Cons((a, b), tail) =>
        match (@core.zip(a, b), rows(tail)) {
          (Some(entries), Some(rest)) =>
            Some(
              Cons(
                @core.map(entries, fn(entry) {
                  let (x, y) = entry
                  operation(x, y)
                }),
                rest,
              ),
            )
          _ => None
        }
    }
  }
  if !@matrix.width(a).equal(@matrix.width(b)) {
    None
  } else {
    match @core.zip(@matrix.rows(a), @matrix.rows(b)) {
      None => None
      Some(pairs) =>
        match rows(pairs) {
          None => None
          Some(result) => @matrix.matrix(@matrix.width(a), result)
        }
    }
  }
}

///|
fn product_equal(
  a : @matrix.Matrix[@exact.Integer],
  b : @matrix.Matrix[@exact.Integer],
  c : @matrix.Matrix[@exact.Integer],
  d : @matrix.Matrix[@exact.Integer],
) -> Bool {
  match
    (@matrix.multiply(a, b, integers()), @matrix.multiply(c, d, integers())) {
    (Some(left), Some(right)) => left.equal(right)
    _ => false
  }
}
