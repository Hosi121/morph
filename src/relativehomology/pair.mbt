///|
/// A finite simplicial pair (K,A), with the checked inclusion A subset K.
/// No quotient-space collapse is used: chain groups have basis K minus A.
#derive(Eq, Debug)
pub struct Pair {
  ambient : @homology.Complex
  subcomplex : @homology.Complex
}

///|
pub extend Pair with Eq::{equal, not_equal}

///|
pub extend Pair with Debug::{to_repr}

///|
pub fn pair(
  ambient : @homology.Complex,
  subcomplex : @homology.Complex,
) -> Pair? {
  let k = @homology.all_simplices(ambient)
  let a = @homology.all_simplices(subcomplex)
  let checked = @homology.validate(k).equal(Some(ambient)) &&
    @homology.validate(a).equal(Some(subcomplex)) &&
    @core.all(a, fn(face) { @core.any(k, fn(simplex) { simplex.equal(face) }) })
  match checked {
    true => Some({ ambient, subcomplex, })
    false => None
  }
}

///|
pub fn ambient(source : Pair) -> @homology.Complex {
  source.ambient
}

///|
pub fn subcomplex(source : Pair) -> @homology.Complex {
  source.subcomplex
}

///|
pub fn simplices(
  source : Pair,
  degree : @core.Nat,
) -> @core.Chain[@core.Chain[@core.Nat]] {
  let a = @homology.simplices(source.subcomplex, degree)
  @core.filter(@homology.simplices(source.ambient, degree), fn(simplex) {
    !@core.any(a, fn(face) { face.equal(simplex) })
  })
}

///|
fn embedding(
  whole : @core.Chain[@core.Chain[@core.Nat]],
  part : @core.Chain[@core.Chain[@core.Nat]],
) -> @matrix.Matrix[@exact.Integer]? {
  @matrix.matrix(
    @core.length(part),
    @core.map(whole, fn(row) {
      @core.map(part, fn(column) {
        match row.equal(column) {
          true => @exact.positive(@binary.one())
          false => @exact.positive(@binary.zero())
        }
      })
    }),
  )
}

///|
/// Canonical lift C_k(K,A) to C_k(K), setting A coordinates to zero.
pub fn lift(
  source : Pair,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  embedding(
    @homology.simplices(source.ambient, degree),
    simplices(source, degree),
  )
}

///|
/// Inclusion of A chains into K chains in their actual simplex bases.
pub fn inclusion(
  source : Pair,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  embedding(
    @homology.simplices(source.ambient, degree),
    @homology.simplices(source.subcomplex, degree),
  )
}

///|
/// Quotient boundary obtained from d_K by deleting A columns and A face rows.
/// Degree zero is the unreduced zero boundary with precise empty shape.
pub fn boundary(
  source : Pair,
  degree : @core.Nat,
) -> @matrix.Matrix[@exact.Integer]? {
  match (@homology.boundary(source.ambient, degree), lift(source, degree)) {
    (Some(d), Some(l)) =>
      match @matrix.multiply(d, l, @chainhomology.integers()) {
        None => None
        Some(columns) =>
          match degree {
            Zero => Some(columns)
            Succ(previous) =>
              match lift(source, previous) {
                None => None
                Some(p) =>
                  @matrix.multiply(
                    @matrix.transpose(p),
                    columns,
                    @chainhomology.integers(),
                  )
              }
          }
      }
    _ => None
  }
}

///|
pub fn boundary_squared_zero(source : Pair, degree : @core.Nat) -> Bool {
  match (boundary(source, degree), boundary(source, Succ(degree))) {
    (Some(a), Some(b)) => @chainhomology.chain_identity(a, b)
    _ => false
  }
}
