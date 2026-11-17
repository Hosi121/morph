///|
/// A total vertex function preserving every simplex after duplicate collapse.
/// Construct with check; vertices are stored in increasing source order.
#derive(Eq, Debug)
pub struct SimplicialMap {
  source_complex : @homology.Complex
  target_complex : @homology.Complex
  assignments : @core.Chain[(@core.Nat, @core.Nat)]
}

///|
pub extend SimplicialMap with Eq::{equal, not_equal}

///|
pub extend SimplicialMap with Debug::{to_repr}

///|
fn labels(complex : @homology.Complex) -> @core.Chain[@core.Nat] {
  fn collect(
    simplices : @core.Chain[@core.Chain[@core.Nat]],
  ) -> @core.Chain[@core.Nat] {
    match simplices {
      Nil => Nil
      Cons(Cons(vertex, Nil), rest) => Cons(vertex, collect(rest))
      Cons(_, rest) => collect(rest)
    }
  }
  collect(@homology.simplices(complex, Zero))
}

///|
fn lookup(
  assignments : @core.Chain[(@core.Nat, @core.Nat)],
  vertex : @core.Nat,
) -> @core.Nat? {
  match assignments {
    Nil => None
    Cons((from, to), rest) =>
      match from.equal(vertex) {
        true => Some(to)
        false => lookup(rest, vertex)
      }
  }
}

///|
fn mapped_vertices(
  assignments : @core.Chain[(@core.Nat, @core.Nat)],
  simplex : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat]? {
  match simplex {
    Nil => Some(Nil)
    Cons(vertex, rest) =>
      match (lookup(assignments, vertex), mapped_vertices(assignments, rest)) {
        (Some(image), Some(rest)) => Some(Cons(image, rest))
        _ => None
      }
  }
}

///|
// Insert at the increasing position, counting swaps. Equality collapses a
// repeated image vertex and marks the simplex degenerate in its old degree.
fn insert_image(
  vertex : @core.Nat,
  sorted : @core.Chain[@core.Nat],
) -> (@core.Chain[@core.Nat], Bool, Bool) {
  match sorted {
    Nil => (Cons(vertex, Nil), false, false)
    Cons(head, rest) =>
      match @core.compare(vertex, head) {
        Less => (Cons(vertex, sorted), false, false)
        Equal => (sorted, false, true)
        Greater => {
          let (tail, negative, degenerate) = insert_image(vertex, rest)
          (Cons(head, tail), !negative, degenerate)
        }
      }
  }
}

///|
fn oriented_image(
  vertices : @core.Chain[@core.Nat],
) -> (@core.Chain[@core.Nat], Bool, Bool) {
  match vertices {
    Nil => (Nil, false, false)
    Cons(vertex, rest) => {
      let (tail, tail_negative, tail_degenerate) = oriented_image(rest)
      let (sorted, negative, degenerate) = insert_image(vertex, tail)
      (
        sorted,
        match tail_negative {
          true => !negative
          false => negative
        },
        tail_degenerate || degenerate,
      )
    }
  }
}

///|
/// Rejects missing or repeated source keys, extra keys, unknown target
/// vertices, and images whose distinct vertex set is not a target simplex.
/// Equal target images are allowed: simplicial maps may collapse simplices.
pub fn check(
  source : @homology.Complex,
  target : @homology.Complex,
  assignments : @core.Chain[(@core.Nat, @core.Nat)],
) -> SimplicialMap? {
  fn unique(todo : @core.Chain[(@core.Nat, @core.Nat)]) -> Bool {
    match todo {
      Nil => true
      Cons((vertex, _), rest) => lookup(rest, vertex) is None && unique(rest)
    }
  }
  fn ordered(
    todo : @core.Chain[@core.Nat],
  ) -> @core.Chain[(@core.Nat, @core.Nat)]? {
    match todo {
      Nil => Some(Nil)
      Cons(vertex, rest) =>
        match (lookup(assignments, vertex), ordered(rest)) {
          (Some(image), Some(rest)) => Some(Cons((vertex, image), rest))
          _ => None
        }
    }
  }
  let domain = labels(source)
  let codomain = labels(target)
  let valid = @homology.validate(@homology.all_simplices(source)).equal(
      Some(source),
    ) &&
    @homology.validate(@homology.all_simplices(target)).equal(Some(target)) &&
    unique(assignments) &&
    @core.length(assignments).equal(@core.length(domain)) &&
    @core.all(assignments, fn(pair) {
      let (from, to) = pair
      @core.any(domain, fn(vertex) { vertex.equal(from) }) &&
      @core.any(codomain, fn(vertex) { vertex.equal(to) })
    }) &&
    @core.all(@homology.all_simplices(source), fn(simplex) {
      match mapped_vertices(assignments, simplex) {
        None => false
        Some(images) => {
          let (sorted, _, _) = oriented_image(images)
          @core.any(@homology.all_simplices(target), fn(face) {
            face.equal(sorted)
          })
        }
      }
    })
  match (valid, ordered(domain)) {
    (true, Some(assignments)) =>
      Some({ source_complex: source, target_complex: target, assignments, })
    _ => None
  }
}

///|
pub fn source(map : SimplicialMap) -> @homology.Complex {
  map.source_complex
}

///|
pub fn target(map : SimplicialMap) -> @homology.Complex {
  map.target_complex
}

///|
pub fn vertices(map : SimplicialMap) -> @core.Chain[(@core.Nat, @core.Nat)] {
  map.assignments
}

///|
pub fn identity(complex : @homology.Complex) -> SimplicialMap {
  {
    source_complex: complex,
    target_complex: complex,
    assignments: @core.map(labels(complex), fn(vertex) { (vertex, vertex) }),
  }
}

///|
/// after composed with before; rejects unequal intermediate complexes.
pub fn compose(after : SimplicialMap, before : SimplicialMap) -> SimplicialMap? {
  fn compose_vertices(
    todo : @core.Chain[(@core.Nat, @core.Nat)],
  ) -> @core.Chain[(@core.Nat, @core.Nat)]? {
    match todo {
      Nil => Some(Nil)
      Cons((from, middle), rest) =>
        match (lookup(after.assignments, middle), compose_vertices(rest)) {
          (Some(to), Some(rest)) => Some(Cons((from, to), rest))
          _ => None
        }
    }
  }
  match before.target_complex.equal(after.source_complex) {
    false => None
    true =>
      match compose_vertices(before.assignments) {
        None => None
        Some(assignments) =>
          check(before.source_complex, after.target_complex, assignments)
      }
  }
}

///|
/// Integral chain map in the existing lexicographic simplex bases. Repeated
/// image vertices give a zero column in the original degree; otherwise the
/// column has the sign of the permutation sorting its mapped vertices.
pub fn chain_map(
  map : SimplicialMap,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  fn images(
    todo : @core.Chain[@core.Chain[@core.Nat]],
  ) -> @core.Chain[(@core.Chain[@core.Nat], Bool, Bool)]? {
    match todo {
      Nil => Some(Nil)
      Cons(simplex, rest) =>
        match (mapped_vertices(map.assignments, simplex), images(rest)) {
          (Some(image), Some(rest)) => Some(Cons(oriented_image(image), rest))
          _ => None
        }
    }
  }
  let columns = @homology.simplices(map.source_complex, degree)
  match images(columns) {
    None => None
    Some(images) =>
      @matrix.matrix(
        @core.length(columns),
        @core.map(@homology.simplices(map.target_complex, degree), fn(simplex) {
          @core.map(images, fn(image) {
            let (sorted, negative, degenerate) = image
            match !degenerate && simplex.equal(sorted) {
              false => integers().zero
              true =>
                match negative {
                  true => @exact.negate(integers().one)
                  false => integers().one
                }
            }
          })
        }),
      )
  }
}

///|
/// Checks d_target F_k = F_(k-1) d_source, with zero degree unreduced.
pub fn chain_identity(map : SimplicialMap, degree : @core.Nat) -> Bool {
  match
    (
      @homology.boundary(map.target_complex, degree),
      chain_map(map, degree),
      @homology.boundary(map.source_complex, degree),
    ) {
    (Some(dt), Some(f), Some(ds)) => {
      let right = match degree {
        Zero => Some(ds)
        Succ(previous) =>
          match chain_map(map, previous) {
            Some(previous) => @matrix.multiply(previous, ds, integers())
            None => None
          }
      }
      match (@matrix.multiply(dt, f, integers()), right) {
        (Some(left), Some(right)) => left.equal(right)
        _ => false
      }
    }
    _ => false
  }
}

///|
/// Binds an externally supplied matrix to the map and degree, and checks the
/// boundary identity independently of equality with the constructed matrix.
pub fn check_chain_map(
  map : SimplicialMap,
  degree : @core.Nat,
  actual : @matrix.Matrix[@exact.Integer],
) -> Bool {
  chain_map(map, degree).equal(Some(actual)) && chain_identity(map, degree)
}
