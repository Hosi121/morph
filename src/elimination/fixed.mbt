///|
/// Dense descending coefficients with a retained nominal degree. Leading zero
/// coefficients are significant. Constructed only after checking degree+1 cells.
#derive(Eq, Debug)
pub struct Fixed[A] {
  degree : @core.Nat
  coefficients : @core.Chain[A]
}

///|
pub extend Fixed with Eq::{equal, not_equal}

///|
pub extend Fixed with Debug::{to_repr}

///|
pub fn[A] fixed(degree : @core.Nat, coefficients : @core.Chain[A]) -> Fixed[A]? {
  match @core.compare(@core.length(coefficients), Succ(degree)) {
    Equal => Some({ degree, coefficients, })
    _ => None
  }
}

///|
/// Nil denotes the nominal constant zero. Otherwise length-1 is the nominal
/// degree, even when the first coefficient is zero.
pub fn[A] dense(
  coefficients : @core.Chain[A],
  ring : @berkowitz.Ring[A],
) -> Fixed[A] {
  match coefficients {
    Nil => { degree: Zero, coefficients: Cons(ring.semiring.zero, Nil), }
    Cons(_, rest) => { degree: @core.length(rest), coefficients, }
  }
}

///|
pub fn[A] nominal_degree(p : Fixed[A]) -> @core.Nat {
  p.degree
}

///|
pub fn[A] coefficients(p : Fixed[A]) -> @core.Chain[A] {
  p.coefficients
}

///|
/// Mapping never trims leading zeros: specialization retains nominal degree.
/// Resultant commutation additionally requires map to be a unital ring map.
pub fn[A, B] map_coefficients(p : Fixed[A], map : (A) -> B) -> Fixed[B] {
  { degree: p.degree, coefficients: @core.map(p.coefficients, map), }
}

///|
fn[A] coefficient_equal(
  a : @core.Chain[A],
  b : @core.Chain[A],
  equal : (A, A) -> Bool,
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) =>
      equal(x, y) && coefficient_equal(xs, ys, equal)
    _ => false
  }
}

///|
pub fn[A, B] check_specialization(
  source : Fixed[A],
  target : Fixed[B],
  map : (A) -> B,
  equal : (B, B) -> Bool,
) -> Bool {
  @core.compare(source.degree, target.degree) is Equal &&
  coefficient_equal(
    @core.map(source.coefficients, map),
    target.coefficients,
    equal,
  )
}

///|
fn[A] same_fixed(a : Fixed[A], b : Fixed[A], equal : (A, A) -> Bool) -> Bool {
  @core.compare(a.degree, b.degree) is Equal &&
  coefficient_equal(a.coefficients, b.coefficients, equal)
}

///|
fn[A] signed(value : A, parity : @core.Nat, ring : @berkowitz.Ring[A]) -> A {
  match parity {
    Zero => value
    Succ(Zero) => (ring.negate)(value)
    Succ(Succ(rest)) => signed(value, rest, ring)
  }
}

///|
fn[A] sylvester_block(
  p : Fixed[A],
  count : @core.Nat,
  total : @core.Nat,
  ring : @berkowitz.Ring[A],
) -> @core.Chain[@core.Chain[A]] {
  @core.map(@core.indices(count), fn(shift) {
    @core.append(
      @core.replicate(shift, ring.semiring.zero),
      @core.append(
        p.coefficients,
        @core.replicate(
          @core.subtract(total, @core.add(shift, Succ(p.degree))),
          ring.semiring.zero,
        ),
      ),
    )
  })
}

///|
/// Coefficient map (U,V) -> Uf+Vg, descending bases, deg U<n and deg V<m.
/// This is the transpose of the conventional shifted-row Sylvester matrix;
/// its determinant has the same standard resultant sign.
pub fn[A] sylvester(
  f : Fixed[A],
  g : Fixed[A],
  ring : @berkowitz.Ring[A],
) -> @matrix.Matrix[A]? {
  let total = @core.add(f.degree, g.degree)
  let rows = @core.append(
    sylvester_block(f, g.degree, total, ring),
    sylvester_block(g, f.degree, total, ring),
  )
  match @matrix.matrix(total, rows) {
    None => None
    Some(matrix) => Some(@matrix.transpose(matrix))
  }
}

///|
/// Fixed-degree Sylvester determinant over a commutative ring. The nominal
/// degree-zero/degree-zero case is the empty determinant one, even for zeros.
pub fn[A] resultant(
  f : Fixed[A],
  g : Fixed[A],
  ring : @berkowitz.Ring[A],
) -> A? {
  match sylvester(f, g, ring) {
    None => None
    Some(matrix) => @berkowitz.determinant(matrix, ring)
  }
}

///|
/// Recompute the determinant. Unlike check_bezout_identity this checks that the
/// claimed scalar is exactly the fixed-degree resultant.
pub fn[A] check_resultant(
  f : Fixed[A],
  g : Fixed[A],
  value : A,
  ring : @berkowitz.Ring[A],
  equal : (A, A) -> Bool,
) -> Bool {
  match resultant(f, g, ring) {
    None => false
    Some(expected) => equal(value, expected)
  }
}
