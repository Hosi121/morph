///|
#derive(Eq, Debug)
pub(all) struct Point {
  x : @exact.Rational
  y : @exact.Rational
}

///|
pub extend Point with Eq::{equal, not_equal}

///|
pub extend Point with Debug::{to_repr}

///|
pub fn compare(a : Point, b : Point) -> @core.Ordering {
  match @exact.rational_compare(a.x, b.x) {
    Equal => @exact.rational_compare(a.y, b.y)
    order => order
  }
}

///|
fn difference(a : Point, b : Point) -> Point {
  {
    x: @exact.rational_subtract(a.x, b.x),
    y: @exact.rational_subtract(a.y, b.y),
  }
}

///|
fn determinant(a : Point, b : Point) -> @exact.Rational {
  @exact.rational_subtract(
    @exact.rational_multiply(a.x, b.y),
    @exact.rational_multiply(a.y, b.x),
  )
}

///|
/// Greater means a counterclockwise turn, Less clockwise, Equal collinear.
pub fn orientation(a : Point, b : Point, c : Point) -> @core.Ordering {
  @exact.rational_compare(
    determinant(difference(b, a), difference(c, a)),
    @exact.rational_zero(),
  )
}

///|
fn deduplicate(points : @core.Chain[Point]) -> @core.Chain[Point] {
  match points {
    Cons(a, Cons(b, rest)) =>
      match compare(a, b) {
        Equal => deduplicate(Cons(b, rest))
        _ => Cons(a, deduplicate(Cons(b, rest)))
      }
    _ => points
  }
}

///|
fn without_last(points : @core.Chain[Point]) -> @core.Chain[Point] {
  match points {
    Nil | Cons(_, Nil) => Nil
    Cons(p, rest) => Cons(p, without_last(rest))
  }
}

///|
/// Andrew's monotone chain. Counterclockwise hull starts at lexicographic minimum;
/// interior collinear points and duplicates are removed. Degenerate hulls retain endpoints.
pub fn convex_hull(points : @core.Chain[Point]) -> @core.Chain[Point] {
  fn push(stack : @core.Chain[Point], point : Point) -> @core.Chain[Point] {
    match stack {
      Cons(b, Cons(a, _) as rest) =>
        match orientation(a, b, point) {
          Greater => Cons(point, stack)
          _ => push(rest, point)
        }
      _ => Cons(point, stack)
    }
  }
  fn half(points : @core.Chain[Point]) -> @core.Chain[Point] {
    @core.reverse(@core.fold_left(points, @core.Nil, push))
  }
  let sorted = deduplicate(@sorting.merge_sort(points, compare))
  match sorted {
    Nil | Cons(_, Nil) => sorted
    _ =>
      @core.append(
        without_last(half(sorted)),
        without_last(half(@core.reverse(sorted))),
      )
  }
}

///|
pub fn twice_signed_area(polygon : @core.Chain[Point]) -> @exact.Rational {
  match polygon {
    Nil => @exact.rational_zero()
    Cons(first, rest) => {
      fn walk(
        previous : Point,
        rest : @core.Chain[Point],
        sum : @exact.Rational,
      ) -> @exact.Rational {
        match rest {
          Nil => @exact.rational_add(sum, determinant(previous, first))
          Cons(next, rest) =>
            walk(
              next,
              rest,
              @exact.rational_add(sum, determinant(previous, next)),
            )
        }
      }
      walk(first, rest, @exact.rational_zero())
    }
  }
}

///|
/// Absolute shoelace area; for a simple polygon this is ordinary geometric area.
pub fn area(polygon : @core.Chain[Point]) -> @exact.Rational {
  let twice = twice_signed_area(polygon)
  let positive = match @exact.rational_compare(twice, @exact.rational_zero()) {
    Less => @exact.rational_negate(twice)
    _ => twice
  }
  @exact.rational_half(positive)
}

///|
pub fn on_segment(point : Point, a : Point, b : Point) -> Bool {
  let (low, high) = match compare(a, b) {
    Greater => (b, a)
    _ => (a, b)
  }
  match (orientation(a, b, point), compare(point, low), compare(point, high)) {
    (Equal, Equal, _) | (Equal, Greater, Less) | (Equal, _, Equal) => true
    _ => false
  }
}

///|
#derive(Eq, Debug)
pub(all) enum Intersection {
  NoIntersection
  PointIntersection(Point)
  SegmentIntersection(Point, Point)
}

///|
pub extend Intersection with Eq::{equal, not_equal}

///|
pub extend Intersection with Debug::{to_repr}

///|
fn unit_interval(value : @exact.Rational) -> Bool {
  match
    (
      @exact.rational_compare(value, @exact.rational_zero()),
      @exact.rational_compare(value, @exact.rational_one()),
    ) {
    (Less, _) | (_, Greater) => false
    _ => true
  }
}

///|
/// Exact segment intersection, including point segments and collinear overlap.
pub fn intersection(a : Point, b : Point, c : Point, d : Point) -> Intersection {
  match (compare(a, b), compare(c, d)) {
    (Equal, _) =>
      match on_segment(a, c, d) {
        true => PointIntersection(a)
        false => NoIntersection
      }
    (_, Equal) =>
      match on_segment(c, a, b) {
        true => PointIntersection(c)
        false => NoIntersection
      }
    _ => {
      let r = difference(b, a)
      let s = difference(d, c)
      match @exact.nonzero(determinant(r, s)) {
        Some(denominator) => {
          let inverse = @exact.reciprocal(denominator)
          let offset = difference(c, a)
          let t = @exact.rational_multiply(determinant(offset, s), inverse)
          let u = @exact.rational_multiply(determinant(offset, r), inverse)
          match (unit_interval(t), unit_interval(u)) {
            (true, true) =>
              PointIntersection({
                x: @exact.rational_add(a.x, @exact.rational_multiply(t, r.x)),
                y: @exact.rational_add(a.y, @exact.rational_multiply(t, r.y)),
              })
            _ => NoIntersection
          }
        }
        None =>
          match orientation(a, b, c) {
            Equal => {
              let (al, ah) = match compare(a, b) {
                Greater => (b, a)
                _ => (a, b)
              }
              let (cl, ch) = match compare(c, d) {
                Greater => (d, c)
                _ => (c, d)
              }
              let low = match compare(al, cl) {
                Greater => al
                _ => cl
              }
              let high = match compare(ah, ch) {
                Less => ah
                _ => ch
              }
              match compare(low, high) {
                Less => SegmentIntersection(low, high)
                Equal => PointIntersection(low)
                Greater => NoIntersection
              }
            }
            _ => NoIntersection
          }
      }
    }
  }
}

///|
/// de Casteljau evaluation. Rational t may lie outside the unit interval.
pub fn bezier(control : @core.Chain[Point], t : @exact.Rational) -> Point? {
  let complement = @exact.rational_subtract(@exact.rational_one(), t)
  fn level(points : @core.Chain[Point]) -> @core.Chain[Point] {
    match points {
      Cons(a, Cons(b, _) as rest) =>
        Cons(
          {
            x: @exact.rational_add(
              @exact.rational_multiply(complement, a.x),
              @exact.rational_multiply(t, b.x),
            ),
            y: @exact.rational_add(
              @exact.rational_multiply(complement, a.y),
              @exact.rational_multiply(t, b.y),
            ),
          },
          level(rest),
        )
      _ => Nil
    }
  }
  match control {
    Nil => None
    Cons(point, Nil) => Some(point)
    _ => bezier(level(control), t)
  }
}
