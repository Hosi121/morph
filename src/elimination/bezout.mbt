///|
/// U and V are descending coefficient lists of exactly n and m cells. Inputs
/// and nominal degrees are embedded, and check_bezout_identity binds them to
/// separately supplied inputs and value.
pub(all) struct Bezout[A] {
  left : Fixed[A]
  right : Fixed[A]
  value : A
  u : @core.Chain[A]
  v : @core.Chain[A]
}

///|
/// Adjugate constant-coordinate column. None for two nominal constants: their
/// empty determinant is one and has no universal Bezout representation.
pub fn[A] bezout(
  f : Fixed[A],
  g : Fixed[A],
  ring : @berkowitz.Ring[A],
) -> Bezout[A]? {
  match @core.add(f.degree, g.degree) {
    Zero => None
    Succ(last) =>
      match sylvester(f, g, ring) {
        None => None
        Some(matrix) =>
          match
            (
              @berkowitz.determinant(matrix, ring),
              @berkowitz.adjugate(matrix, ring),
            ) {
            (Some(value), Some(adjugate)) =>
              match @matrix.column(adjugate, last) {
                None => None
                Some(column) =>
                  match @core.split_exact(g.degree, column) {
                    None => None
                    Some((u, v)) => Some({ left: f, right: g, value, u, v, })
                  }
              }
            _ => None
          }
      }
  }
}

///|
fn[A] add_ascending(
  a : @core.Chain[A],
  b : @core.Chain[A],
  ring : @berkowitz.Ring[A],
) -> @core.Chain[A] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) =>
      Cons((ring.semiring.plus)(x, y), add_ascending(xs, ys, ring))
  }
}

///|
fn[A] multiply_ascending(
  a : @core.Chain[A],
  b : @core.Chain[A],
  ring : @berkowitz.Ring[A],
) -> @core.Chain[A] {
  match (a, b) {
    (Nil, _) | (_, Nil) => Nil
    (Cons(x, Nil), _) => @core.map(b, fn(y) { (ring.semiring.times)(x, y) })
    (Cons(x, xs), _) =>
      add_ascending(
        @core.map(b, fn(y) { (ring.semiring.times)(x, y) }),
        Cons(ring.semiring.zero, multiply_ascending(xs, b, ring)),
        ring,
      )
  }
}

///|
/// Only the bounded polynomial identity Uf+Vg=value is checked. This proves
/// ideal membership; it does NOT by itself prove value equals the determinant.
/// In particular an all-zero identity certifies zero for any input pair.
pub fn[A] check_bezout_identity(
  f : Fixed[A],
  g : Fixed[A],
  value : A,
  proof : Bezout[A],
  ring : @berkowitz.Ring[A],
  equal : (A, A) -> Bool,
) -> Bool {
  let bound = same_fixed(f, proof.left, equal) &&
    same_fixed(g, proof.right, equal) &&
    equal(value, proof.value) &&
    @core.compare(@core.length(proof.u), g.degree) is Equal &&
    @core.compare(@core.length(proof.v), f.degree) is Equal
  if !bound {
    false
  } else {
    let sum = add_ascending(
      multiply_ascending(
        @core.reverse(proof.u),
        @core.reverse(f.coefficients),
        ring,
      ),
      multiply_ascending(
        @core.reverse(proof.v),
        @core.reverse(g.coefficients),
        ring,
      ),
      ring,
    )
    match sum {
      Nil => equal(value, ring.semiring.zero)
      Cons(constant, rest) =>
        equal(constant, value) &&
        @core.all(rest, fn(x) { equal(x, ring.semiring.zero) })
    }
  }
}
