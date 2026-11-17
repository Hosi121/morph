///|
/// An ordered affine simplex. Degeneracy is permitted; order is orientation.
/// All vertices have ambient coordinates and there is at least one vertex.
#derive(Eq, Debug)
pub struct Simplex {
  ambient : @core.Nat
  dimension : @core.Nat
  vertices : @core.Chain[@core.Chain[@exact.Rational]]
}

///|
pub extend Simplex with Eq::{equal, not_equal}

///|
pub extend Simplex with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum IntegrationError {
  EmptySimplex
  VertexDimension
  DimensionMismatch
  DegreeMismatch
  InvalidVertex
  EmptyFace
  FormFailure(@forms.FormError)
  InternalInvariant
}

///|
pub extend IntegrationError with Eq::{equal, not_equal}

///|
pub extend IntegrationError with Debug::{to_repr}

///|
pub fn simplex(
  ambient : @core.Nat,
  vertices : @core.Chain[@core.Chain[@exact.Rational]],
) -> Result[Simplex, IntegrationError] {
  match vertices {
    Nil => Err(EmptySimplex)
    Cons(_, rest) =>
      if !@core.all(vertices, fn(vertex) { @core.length(vertex).equal(ambient) }) {
        Err(VertexDimension)
      } else {
        Ok({ ambient, dimension: @core.length(rest), vertices, })
      }
  }
}

///|
pub fn ambient(value : Simplex) -> @core.Nat {
  value.ambient
}

///|
pub fn dimension(value : Simplex) -> @core.Nat {
  value.dimension
}

///|
pub fn vertices(value : Simplex) -> @core.Chain[@core.Chain[@exact.Rational]] {
  value.vertices
}

///|
pub fn standard(dimension : @core.Nat) -> Simplex {
  let axes = @core.indices(dimension)
  let origin = @core.replicate(dimension, @exact.rational_zero())
  let unit_vertices = @core.map(axes, fn(index) {
    @core.map(axes, fn(coordinate) {
      if coordinate.equal(index) {
        @exact.rational_one()
      } else {
        @exact.rational_zero()
      }
    })
  })
  { ambient: dimension, dimension, vertices: Cons(origin, unit_vertices), }
}

///|
/// Ordered vertex selection; repeats preserve a degenerate parameterization.
pub fn face(
  value : Simplex,
  indices : @core.Chain[@core.Nat],
) -> Result[Simplex, IntegrationError] {
  fn select(
    indices : @core.Chain[@core.Nat],
  ) -> @core.Chain[@core.Chain[@exact.Rational]]? {
    match indices {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match (@core.nth(value.vertices, index), select(rest)) {
          (Some(vertex), Some(tail)) => Some(Cons(vertex, tail))
          _ => None
        }
    }
  }
  match indices {
    Nil => Err(EmptyFace)
    Cons(_, _) =>
      if !@core.all(indices, fn(index) {
          @core.compare(index, Succ(value.dimension)) is Less
        }) {
        Err(InvalidVertex)
      } else {
        match select(indices) {
          None => Err(InternalInvariant)
          Some(selected) => simplex(value.ambient, selected)
        }
      }
  }
}

///|
/// The image is affine and sends every standard vertex to its declared vertex.
/// This checks the geometric tie without trusting the coefficient builder.
pub fn check_parameterization(
  value : Simplex,
  mapping : @forms.PolynomialMap,
) -> Bool {
  if !@forms.map_source(mapping).equal(value.dimension) ||
    !@forms.map_target(mapping).equal(value.ambient) ||
    !@core.all(@forms.map_coordinates(mapping), fn(coordinate) {
      @core.all(@poly.terms(coordinate), fn(term) {
        match @core.fold_left(term.exponents, @core.Zero, @core.add) {
          Zero | Succ(Zero) => true
          _ => false
        }
      })
    }) {
    return false
  }
  match @core.zip(vertices(standard(value.dimension)), value.vertices) {
    None => false
    Some(pairs) =>
      @core.all(pairs, fn(pair) {
        let (parameter, vertex) = pair
        match @core.zip(@forms.map_coordinates(mapping), vertex) {
          None => false
          Some(coordinates) =>
            @core.all(coordinates, fn(coordinate) {
              let (polynomial, expected) = coordinate
              match @poly.evaluate(polynomial, parameter) {
                None => false
                Some(actual) => actual.equal(expected)
              }
            })
        }
      })
  }
}

///|
pub fn parameterization(
  value : Simplex,
) -> Result[@forms.PolynomialMap, IntegrationError] {
  fn slopes(
    origin : @core.Chain[@exact.Rational],
    remaining : @core.Chain[@core.Chain[@exact.Rational]],
    coordinate : @core.Nat,
    index : @core.Nat,
  ) -> @core.Chain[@poly.Term]? {
    match remaining {
      Nil =>
        match @core.nth(origin, coordinate) {
          None => None
          Some(coefficient) =>
            Some(
              Cons(
                {
                  coefficient,
                  exponents: @core.replicate(value.dimension, Zero),
                },
                Nil,
              ),
            )
        }
      Cons(vertex, rest) =>
        match
          (
            @core.nth(origin, coordinate),
            @core.nth(vertex, coordinate),
            slopes(origin, rest, coordinate, Succ(index)),
          ) {
          (Some(base), Some(current), Some(tail)) => {
            let exponents : @core.Chain[@core.Nat] = @core.map(
              @core.indices(value.dimension),
              fn(variable) {
                if variable.equal(index) {
                  Succ(Zero)
                } else {
                  Zero
                }
              },
            )
            Some(
              Cons(
                {
                  coefficient: @exact.rational_subtract(current, base),
                  exponents,
                },
                tail,
              ),
            )
          }
          _ => None
        }
    }
  }
  fn coordinates(
    indices : @core.Chain[@core.Nat],
  ) -> @core.Chain[@poly.Polynomial]? {
    match (indices, value.vertices) {
      (Nil, _) => Some(Nil)
      (Cons(index, rest), Cons(origin, tail)) =>
        match (slopes(origin, tail, index, Zero), coordinates(rest)) {
          (Some(input), Some(coordinates)) =>
            match @poly.polynomial(value.dimension, input) {
              Err(_) => None
              Ok(coordinate) => Some(Cons(coordinate, coordinates))
            }
          _ => None
        }
      _ => None
    }
  }
  match coordinates(@core.indices(value.ambient)) {
    None => Err(InternalInvariant)
    Some(coordinates) =>
      match @forms.polynomial_map(value.dimension, coordinates) {
        Err(error) => Err(FormFailure(error))
        Ok(mapping) =>
          if check_parameterization(value, mapping) {
            Ok(mapping)
          } else {
            Err(InternalInvariant)
          }
      }
  }
}
