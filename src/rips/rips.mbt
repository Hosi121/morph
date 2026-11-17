///|
/// A finite exact Euclidean point cloud. Positions may coincide, but vertices
/// remain distinct. Pairwise squared distances are computed once on entry.
#derive(Eq, Debug)
pub struct Cloud {
  dimension : @core.Nat
  points : @core.Chain[@core.Chain[@exact.Rational]]
  distances : @core.Chain[@core.Chain[@exact.Rational]]
}

///|
pub extend Cloud with Eq::{equal, not_equal}

///|
pub extend Cloud with Debug::{to_repr}

///|
fn distance_equal(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @exact.Rational {
  match (a, b) {
    (Cons(x, xs), Cons(y, ys)) => {
      let delta = @exact.rational_subtract(x, y)
      @exact.rational_add(
        @exact.rational_multiply(delta, delta),
        distance_equal(xs, ys),
      )
    }
    _ => @exact.rational_zero()
  }
}

///|
/// Exact squared Euclidean distance; rejects vectors of different dimensions.
pub fn squared_distance(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match @core.length(a).equal(@core.length(b)) {
    true => Some(distance_equal(a, b))
    false => None
  }
}

///|
pub fn cloud(
  dimension : @core.Nat,
  points : @core.Chain[@core.Chain[@exact.Rational]],
) -> Cloud? {
  match @core.all(points, fn(point) { @core.length(point).equal(dimension) }) {
    false => None
    true =>
      Some({
        dimension,
        points,
        distances: @core.map(points, fn(a) {
          @core.map(points, fn(b) { distance_equal(a, b) })
        }),
      })
  }
}

///|
pub fn dimension(source : Cloud) -> @core.Nat {
  source.dimension
}

///|
pub fn points(source : Cloud) -> @core.Chain[@core.Chain[@exact.Rational]] {
  source.points
}

///|
fn maximum(a : @exact.Rational, b : @exact.Rational) -> @exact.Rational {
  match @exact.rational_compare(a, b) {
    Less => b
    _ => a
  }
}

///|
fn distances_to(
  row : @core.Chain[@exact.Rational],
  vertices : @core.Chain[@core.Nat],
  bound : @exact.Rational,
) -> @exact.Rational? {
  match vertices {
    Nil => Some(bound)
    Cons(vertex, rest) =>
      match @core.nth(row, vertex) {
        None => None
        Some(value) => distances_to(row, rest, maximum(bound, value))
      }
  }
}

///|
/// Birth grade of a nonempty vertex set, in squared-distance units.
/// Filtration validation separately enforces sorted, distinct vertices.
pub fn grade(
  source : Cloud,
  simplex : @core.Chain[@core.Nat],
) -> @exact.Rational? {
  fn walk(
    rest : @core.Chain[@core.Nat],
    bound : @exact.Rational,
  ) -> @exact.Rational? {
    match rest {
      Nil => Some(bound)
      Cons(vertex, tail) =>
        match @core.nth(source.distances, vertex) {
          None => None
          Some(row) =>
            match distances_to(row, tail, bound) {
              None => None
              Some(next) => walk(tail, next)
            }
        }
    }
  }
  match simplex {
    Nil => None
    _ => walk(simplex, @exact.rational_zero())
  }
}

///|
fn lexical(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(x, xs), Cons(y, ys)) =>
      match @core.compare(x, y) {
        Equal => lexical(xs, ys)
        order => order
      }
  }
}

///|
fn entry_order(
  a : @persistence.Entry,
  b : @persistence.Entry,
) -> @core.Ordering {
  match @exact.rational_compare(a.grade, b.grade) {
    Equal =>
      match @core.compare(@core.length(a.simplex), @core.length(b.simplex)) {
        Equal => lexical(a.simplex, b.simplex)
        order => order
      }
    order => order
  }
}

///|
fn enumerate(
  source : Cloud,
  todo : @core.Chain[@core.Nat],
  reversed : @core.Chain[@core.Nat],
  slots : @core.Nat,
  bound : @exact.Rational,
  onto : @core.Chain[@persistence.Entry],
) -> @core.Chain[@persistence.Entry]? {
  match (slots, todo) {
    (Zero, _) | (_, Nil) => Some(onto)
    (Succ(rest_slots), Cons(vertex, rest)) =>
      match @core.nth(source.distances, vertex) {
        None => None
        Some(row) =>
          match distances_to(row, reversed, bound) {
            None => None
            Some(next_grade) => {
              let next : @core.Chain[@core.Nat] = Cons(vertex, reversed)
              let entry : @persistence.Entry = {
                simplex: @core.reverse(next),
                grade: next_grade,
              }
              match
                enumerate(
                  source,
                  rest,
                  next,
                  rest_slots,
                  next_grade,
                  Cons(entry, onto),
                ) {
                None => None
                Some(with_vertex) =>
                  enumerate(source, rest, reversed, slots, bound, with_vertex)
              }
            }
          }
      }
  }
}

///|
/// All Vietoris–Rips simplices through max_dimension, ordered by squared
/// diameter, then dimension, then vertices. No square root or float occurs.
/// This eagerly constructs a finite filtration; it has no execution fuel.
pub fn build(
  source : Cloud,
  max_dimension : @core.Nat,
) -> @persistence.Filtration? {
  match
    enumerate(
      source,
      @core.indices(@core.length(source.points)),
      Nil,
      Succ(max_dimension),
      @exact.rational_zero(),
      Nil,
    ) {
    None => None
    Some(entries) =>
      @persistence.validate(@sorting.merge_sort(entries, entry_order))
  }
}

///|
// Pascal's triangle truncated to the number of allowed simplex vertices.
// Counting all possible subsets independently proves completeness without
// invoking the filtration producer or enumerating subsets a second time.
fn subset_count(vertices : @core.Nat, limit : @core.Nat) -> @core.Nat {
  fn next(
    row : @core.Chain[@core.Nat],
    previous : @core.Nat,
  ) -> @core.Chain[@core.Nat] {
    match row {
      Nil => Cons(previous, Nil)
      Cons(value, rest) => Cons(@core.add(previous, value), next(rest, value))
    }
  }
  fn pascal(
    n : @core.Nat,
    row : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Nat] {
    match n {
      Zero => row
      Succ(rest) => pascal(rest, @core.take(Succ(limit), next(row, Zero)))
    }
  }
  @core.fold_left(
    @core.drop(Succ(Zero), pascal(vertices, Cons(Succ(Zero), Nil))),
    Zero,
    @core.add,
  )
}

///|
/// Bind an actual filtration to the point cloud and dimension cap. Checks
/// grades directly from the exact metric, validity/uniqueness, allowed vertex
/// sets, dimension and binomial completeness; never calls build or persistence.
/// Any valid ordering of equal-grade simplices is accepted.
pub fn check_filtration(
  source : Cloud,
  max_dimension : @core.Nat,
  actual : @persistence.Filtration,
) -> Bool {
  let entries = @persistence.entries(actual)
  @persistence.validate(entries).equal(Some(actual)) &&
  @core.length(entries).equal(
    subset_count(@core.length(source.points), Succ(max_dimension)),
  ) &&
  @core.all(entries, fn(entry) {
    !(@core.compare(@core.length(entry.simplex), Succ(max_dimension)) is Greater) &&
    grade(source, entry.simplex).equal(Some(entry.grade))
  })
}
