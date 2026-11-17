///|
/// A finite abstract simplicial complex. Each nonempty simplex has distinct,
/// increasing Nat vertices. All nonempty faces are present exactly once.
/// The empty complex is valid; homology is unreduced in nonnegative degrees.
#derive(Eq, Debug)
pub struct Complex {
  faces : @core.Chain[@core.Chain[@core.Nat]]
}

///|
pub extend Complex with Eq::{equal, not_equal}

///|
pub extend Complex with Debug::{to_repr}

///|
fn simplex_order(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(x, xs), Cons(y, ys)) =>
      match @core.compare(x, y) {
        Equal => simplex_order(xs, ys)
        order => order
      }
  }
}

///|
fn canonical(simplex : @core.Chain[@core.Nat]) -> Bool {
  fn increasing(xs : @core.Chain[@core.Nat], previous : @core.Nat) -> Bool {
    match xs {
      Nil => true
      Cons(x, rest) => @core.compare(previous, x) is Less && increasing(rest, x)
    }
  }
  match simplex {
    Nil => false
    Cons(x, rest) => increasing(rest, x)
  }
}

///|
fn contains(
  faces : @core.Chain[@core.Chain[@core.Nat]],
  simplex : @core.Chain[@core.Nat],
) -> Bool {
  @core.any(faces, fn(face) { face.equal(simplex) })
}

///|
fn insert(
  faces : @core.Chain[@core.Chain[@core.Nat]],
  simplex : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  match faces {
    Nil => Cons(simplex, Nil)
    Cons(face, rest) =>
      match simplex_order(simplex, face) {
        Less => Cons(simplex, faces)
        Equal => faces
        Greater => Cons(face, insert(rest, simplex))
      }
  }
}

///|
/// Codimension-one faces in deletion order (including the empty face for a
/// vertex). A simplex's orientation is its increasing vertex order.
pub fn faces(
  simplex : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  fn walk(
    prefix : @core.Chain[@core.Nat],
    rest : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@core.Nat]] {
    match rest {
      Nil => Nil
      Cons(vertex, tail) =>
        Cons(@core.reverse_onto(prefix, tail), walk(Cons(vertex, prefix), tail))
    }
  }
  walk(Nil, simplex)
}

///|
/// Validate an explicitly complete face list. Rejects duplicate simplices,
/// missing faces, empty simplices, reversed vertices and repeated vertices.
/// The outer list may have any order and is stored in lexicographic order.
pub fn validate(input : @core.Chain[@core.Chain[@core.Nat]]) -> Complex? {
  fn distinct(todo : @core.Chain[@core.Chain[@core.Nat]]) -> Bool {
    match todo {
      Nil => true
      Cons(simplex, rest) =>
        canonical(simplex) && !contains(rest, simplex) && distinct(rest)
    }
  }
  let closed = @core.all(input, fn(simplex) {
    @core.all(faces(simplex), fn(face) {
      match face {
        Nil => true
        _ => contains(input, face)
      }
    })
  })
  match distinct(input) && closed {
    false => None
    true => Some({ faces: @core.fold_left(input, Nil, insert), })
  }
}

///|
/// Close canonical nonempty generators under nonempty faces. Repeated
/// generators and shared faces are intentionally merged. Vertex order is
/// validated, never silently reoriented. Nil generates the empty complex.
pub fn closure(input : @core.Chain[@core.Chain[@core.Nat]]) -> Complex? {
  fn add(
    accumulated : @core.Chain[@core.Chain[@core.Nat]],
    simplex : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@core.Nat]] {
    match simplex {
      Nil => accumulated
      _ =>
        match contains(accumulated, simplex) {
          true => accumulated
          false =>
            @core.fold_left(faces(simplex), insert(accumulated, simplex), add)
        }
    }
  }
  match @core.all(input, canonical) {
    false => None
    true => validate(@core.fold_left(input, Nil, add))
  }
}

///|
pub fn all_simplices(complex : Complex) -> @core.Chain[@core.Chain[@core.Nat]] {
  complex.faces
}

///|
pub fn simplices(
  complex : Complex,
  degree : @core.Nat,
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.filter(complex.faces, fn(simplex) {
    @core.compare(@core.length(simplex), Succ(degree)) is Equal
  })
}

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
fn zero(value : @exact.Integer) -> Bool {
  @binary.is_zero(@exact.magnitude(value))
}

///|
fn zero_matrix(input : @matrix.Matrix[@exact.Integer]) -> Bool {
  @core.all(@matrix.rows(input), fn(row) { @core.all(row, zero) })
}

///|
fn incidence(
  face : @core.Chain[@core.Nat],
  simplex : @core.Chain[@core.Nat],
) -> @exact.Integer {
  fn walk(
    todo : @core.Chain[@core.Chain[@core.Nat]],
    positive : Bool,
  ) -> @exact.Integer {
    match todo {
      Nil => @exact.positive(@binary.zero())
      Cons(candidate, rest) =>
        match candidate.equal(face) {
          false => walk(rest, !positive)
          true => {
            let one = @exact.positive(@binary.one())
            match positive {
              true => one
              false => @exact.negate(one)
            }
          }
        }
    }
  }
  walk(faces(simplex), true)
}

///|
/// Integral oriented boundary d_k: C_k -> C_(k-1). In degree zero the target
/// is the zero group, so the shape is zero rows by number-of-vertices columns.
/// Degrees beyond the complex dimension retain their precise zero shapes.
pub fn boundary(
  complex : Complex,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  let columns = simplices(complex, degree)
  let rows : @core.Chain[@core.Chain[@core.Nat]] = match degree {
    Zero => Nil
    Succ(previous) => simplices(complex, previous)
  }
  @matrix.matrix(
    @core.length(columns),
    @core.map(rows, fn(face) {
      @core.map(columns, fn(simplex) { incidence(face, simplex) })
    }),
  )
}

///|
/// Exact check d_k*d_(k+1)=0, including degree zero and empty shapes.
pub fn boundary_squared_zero(complex : Complex, degree : @core.Nat) -> Bool {
  match (boundary(complex, degree), boundary(complex, Succ(degree))) {
    (Some(a), Some(b)) =>
      match @matrix.multiply(a, b, integers()) {
        Some(product) => zero_matrix(product)
        None => false
      }
    _ => false
  }
}

///|
/// Alternating number of nonempty simplices; the empty complex has value zero.
pub fn euler_characteristic(complex : Complex) -> @exact.Integer {
  fn sign(rest : @core.Chain[@core.Nat], positive : Bool) -> @exact.Integer {
    match rest {
      Nil => {
        let one = @exact.positive(@binary.one())
        match positive {
          true => one
          false => @exact.negate(one)
        }
      }
      Cons(_, tail) => sign(tail, !positive)
    }
  }
  @core.fold_left(complex.faces, @exact.positive(@binary.zero()), fn(
    sum,
    simplex,
  ) {
    match simplex {
      Nil => sum
      Cons(_, rest) => @exact.add(sum, sign(rest, true))
    }
  })
}
