///|
/// Truncated shifted-row Sylvester matrix of order n+m-2k. Coefficients of
/// y^(n+m-k-1) down to y^k are retained. k=0 is the usual resultant matrix;
/// for k=min(n,m), equal degrees give the empty matrix and determinant one.
pub fn[A] principal_matrix(
  f : Fixed[A],
  g : Fixed[A],
  k : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> @matrix.Matrix[A]? {
  match @core.compare(k, @core.minimum(f.degree, g.degree)) {
    Greater => None
    _ => {
      let left_count = @core.subtract(g.degree, k)
      let right_count = @core.subtract(f.degree, k)
      let dimension = @core.add(left_count, right_count)
      let rectangular_width = @core.add(dimension, k)
      let rows = @core.append(
        sylvester_block(f, left_count, rectangular_width, ring),
        sylvester_block(g, right_count, rectangular_width, ring),
      )
      @matrix.matrix(
        dimension,
        @core.map(rows, fn(row) { @core.take(dimension, row) }),
      )
    }
  }
}

///|
/// Fixed-nominal-degree principal subresultant coefficient. Specialization
/// preserves this determinant, including when leading coefficients vanish.
pub fn[A] principal_subresultant(
  f : Fixed[A],
  g : Fixed[A],
  k : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> A? {
  match principal_matrix(f, g, k, ring) {
    None => None
    Some(matrix) => @berkowitz.determinant(matrix, ring)
  }
}

///|
/// PSC_0,...,PSC_min in ascending index order. The top determinant is one for
/// equal degrees, or lc(smaller)^abs(n-m) otherwise. No degree is trimmed.
pub fn[A] principal_coefficients(
  f : Fixed[A],
  g : Fixed[A],
  ring : @berkowitz.Ring[A],
) -> @core.Chain[A]? {
  fn go(indices : @core.Chain[@core.Nat]) -> @core.Chain[A]? {
    match indices {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match (principal_subresultant(f, g, index, ring), go(rest)) {
          (Some(value), Some(tail)) => Some(Cons(value, tail))
          _ => None
        }
    }
  }
  go(@core.indices(Succ(@core.minimum(f.degree, g.degree))))
}

///|
/// An index helper only. Interpreting the result as a gcd degree additionally
/// requires a field, nonzero input polynomials and preserved actual degrees.
pub fn[A] first_nonzero(
  values : @core.Chain[A],
  zero : A,
  equal : (A, A) -> Bool,
) -> @core.Nat? {
  fn go(values : @core.Chain[A], index : @core.Nat) -> @core.Nat? {
    match values {
      Nil => None
      Cons(value, rest) =>
        if equal(value, zero) {
          go(rest, Succ(index))
        } else {
          Some(index)
        }
    }
  }
  go(values, Zero)
}

///|
pub(all) struct PrincipalCertificate[A] {
  left : Fixed[A]
  right : Fixed[A]
  index : @core.Nat
  value : A
}

///|
pub fn[A] principal_certificate(
  f : Fixed[A],
  g : Fixed[A],
  k : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> PrincipalCertificate[A]? {
  match principal_subresultant(f, g, k, ring) {
    None => None
    Some(value) => Some({ left: f, right: g, index: k, value, })
  }
}

///|
/// Bind both nominal inputs, the index and the separately supplied result;
/// recompute the truncated determinant rather than infer a gcd theorem.
pub fn[A] check_principal(
  f : Fixed[A],
  g : Fixed[A],
  k : @core.Nat,
  value : A,
  proof : PrincipalCertificate[A],
  ring : @berkowitz.Ring[A],
  equal : (A, A) -> Bool,
) -> Bool {
  same_fixed(f, proof.left, equal) &&
  same_fixed(g, proof.right, equal) &&
  @core.compare(k, proof.index) is Equal &&
  equal(value, proof.value) &&
  (match principal_subresultant(f, g, k, ring) {
    Some(expected) => equal(value, expected)
    None => false
  })
}
