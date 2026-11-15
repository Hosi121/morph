///|
fn point(x : Int32, y : Int32) -> Point {
  { x: @oracle.rational(x, 1), y: @oracle.rational(y, 1), }
}

///|
fn cross(a : (Int32, Int32), b : (Int32, Int32), c : (Int32, Int32)) -> Int32 {
  (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0)
}

///|
/// Independent gift-wrapping hull using integer orientation and distance.
fn jarvis(points : Array[(Int32, Int32)]) -> Array[(Int32, Int32)] {
  if points.length() <= 1 {
    return points
  }
  let first = points[0]
  let result = []
  let mut current = first
  for _ in 0..<=points.length() {
    result.push(current)
    let mut candidate = if points[0] == current { points[1] } else { points[0] }
    fn distance(a : (Int32, Int32), b : (Int32, Int32)) -> Int32 {
      (a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1)
    }
    for p in points {
      let turn = cross(current, candidate, p)
      if turn < 0 ||
        (turn == 0 && distance(current, p) > distance(current, candidate)) {
        candidate = p
      }
    }
    current = candidate
    if current == first {
      return result
    }
  }
  abort("gift wrapping oracle did not close")
}

///|
test "exact monotone hull matches gift wrapping for every subset of a three by three grid" {
  let grid = []
  for x in -1..<=1 {
    for y in -1..<=1 {
      grid.push((x, y))
    }
  }
  for mask in 0..<512 {
    let selected = [ for i in 0..<9 if (mask & (1 << i)) != 0 => grid[i] ]
    let input = selected.rev()
    if !input.is_empty() {
      input.push(input[0])
      input.push(input[0])
    }
    let hull = convex_hull(@oracle.chain(input.map(fn(p) { point(p.0, p.1) })))
    let actual = @oracle.array(hull).map(fn(p) {
      (
        @oracle.int_of_integer(@exact.numerator(p.x)),
        @oracle.int_of_integer(@exact.numerator(p.y)),
      )
    })
    let expected = jarvis(selected)
    assert_eq(actual, expected)
    let mut twice_area = 0
    for i in 0..<expected.length() {
      let a = expected[i]
      let b = expected[(i + 1) % expected.length()]
      twice_area += a.0 * b.1 - a.1 * b.0
    }
    assert_eq(area(hull), @oracle.rational(twice_area.abs(), 2))
  }
}

///|
test "all grid segment pairs agree with an integer intersection predicate" {
  let grid = []
  for x in -1..<=1 {
    for y in -1..<=1 {
      grid.push((x, y))
    }
  }
  fn on(p : (Int32, Int32), a : (Int32, Int32), b : (Int32, Int32)) -> Bool {
    cross(a, b, p) == 0 &&
    p.0 >= Int32::min(a.0, b.0) &&
    p.0 <= Int32::max(a.0, b.0) &&
    p.1 >= Int32::min(a.1, b.1) &&
    p.1 <= Int32::max(a.1, b.1)
  }
  for a in grid {
    for b in grid {
      for c in grid {
        for d in grid {
          let o1 = cross(a, b, c)
          let o2 = cross(a, b, d)
          let o3 = cross(c, d, a)
          let o4 = cross(c, d, b)
          let expected = on(a, c, d) ||
            on(b, c, d) ||
            on(c, a, b) ||
            on(d, a, b) ||
            (o1 * o2 < 0 && o3 * o4 < 0)
          let pa = point(a.0, a.1)
          let pb = point(b.0, b.1)
          let pc = point(c.0, c.1)
          let pd = point(d.0, d.1)
          match intersection(pa, pb, pc, pd) {
            NoIntersection => assert_false(expected)
            PointIntersection(p) => {
              assert_true(expected)
              assert_true(on_segment(p, pa, pb) && on_segment(p, pc, pd))
            }
            SegmentIntersection(x, y) => {
              assert_true(expected)
              assert_true(
                on_segment(x, pa, pb) &&
                on_segment(x, pc, pd) &&
                on_segment(y, pa, pb) &&
                on_segment(y, pc, pd),
              )
            }
          }
        }
      }
    }
  }
}

///|
test "rational intersections, huge translated orientation and exact Bezier evaluation" {
  let expected : Point = {
    x: @oracle.rational(6, 5),
    y: @oracle.rational(6, 5),
  }
  assert_eq(
    intersection(point(0, 0), point(3, 3), point(0, 2), point(3, 0)),
    PointIntersection(expected),
  )
  assert_eq(
    intersection(point(3, 0), point(0, 0), point(1, 0), point(5, 0)),
    SegmentIntersection(point(1, 0), point(3, 0)),
  )
  let big = @exact.whole(
    @exact.positive(@oracle.binary_from_hex("10000000000000000000000000")),
  )
  let next = @exact.rational_add(big, @exact.rational_one())
  assert_eq(
    orientation({ x: big, y: big, }, { x: next, y: big, }, { x: big, y: next, }),
    @core.Greater,
  )
  let control = @oracle.chain([
    point(0, 0),
    point(1, 2),
    point(3, 2),
    point(4, 0),
  ])
  assert_eq(
    bezier(control, @oracle.rational(1, 2)),
    Some(Point::{ x: @oracle.rational(2, 1), y: @oracle.rational(3, 2), }),
  )
  assert_eq(bezier(control, @exact.rational_zero()), Some(point(0, 0)))
  assert_eq(bezier(control, @exact.rational_one()), Some(point(4, 0)))
  assert_eq(bezier(Nil, @exact.rational_zero()), None)
  for k in -2..<=8 {
    let expected : Point = {
      x: @oracle.rational(108 * k + 18 * k * k - 2 * k * k * k, 216),
      y: @oracle.rational(36 * k - 6 * k * k, 36),
    }
    assert_eq(bezier(control, @oracle.rational(k, 6)), Some(expected))
  }
}
