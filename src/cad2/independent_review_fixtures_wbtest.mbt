// Generated from frozen hand-derived quantified semantics.

///|
test "independent plane quantifier family 0 circle equality" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 1 closed disk" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 2 open disk strict endpoints" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 3 strict circle exterior" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [true, true, true, false],
  )
}

///|
test "independent plane quantifier family 4 parabola equality" {
  review_plane_fixture(
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 5 strict parabola epigraph" {
  review_plane_fixture(
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 6 quadratic degree birth" {
  review_plane_fixture(
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 7 nullified xy equality" {
  review_plane_fixture([[(1, 1, 1, 1)]], fn(ps) { Atom(ps[0], EqualZero) }, [
    true, true, true, false,
  ])
}

///|
test "independent plane quantifier family 8 nullified xy strict" {
  review_plane_fixture([[(1, 1, 1, 1)]], fn(ps) { Atom(ps[0], GreaterZero) }, [
    true, false, false, false,
  ])
}

///|
test "independent plane quantifier family 9 nullified xy disequality" {
  review_plane_fixture([[(1, 1, 1, 1)]], fn(ps) { Atom(ps[0], NotZero) }, [
    true, false, false, false,
  ])
}

///|
test "independent plane quantifier family 10 guarded nullification" {
  review_plane_fixture(
    [[(1, 1, 1, 0)], [(1, 1, 1, 1)]],
    fn(ps) { Disjunction(Atom(ps[0], EqualZero), Atom(ps[1], GreaterZero)) },
    [true, true, true, false],
  )
}

///|
test "independent plane quantifier family 11 shared line equality" {
  review_plane_fixture(
    [[(-1, 1, 1, 0), (1, 1, 0, 1)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 12 shared root collision strict" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], EqualZero)) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 13 repeated square impossible" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [false, false, false, false],
  )
}

///|
test "independent plane quantifier family 14 repeated square nonnegative" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [true, true, true, true],
  )
}

///|
test "independent plane quantifier family 15 shared factors mixed strict" {
  review_plane_fixture(
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 16 vertical leading coefficient" {
  review_plane_fixture(
    [[(1, 1, 1, 1), (-1, 1, 0, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 17 quadratic to linear degree drop" {
  review_plane_fixture(
    [[(1, 1, 1, 2), (-1, 1, 0, 2), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 18 vertical nullification" {
  review_plane_fixture(
    [[(1, 1, 1, 1), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, true, true, false],
  )
}

///|
test "independent plane quantifier family 19 irrational vertical nullification" {
  review_plane_fixture(
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, true, true, false],
  )
}

///|
test "independent plane quantifier family 20 irrational nullification strict" {
  review_plane_fixture(
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 21 vertical factor times horizontal square" {
  review_plane_fixture(
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [true, true, true, false],
  )
}

///|
test "independent plane quantifier family 22 pure base atom" {
  review_plane_fixture(
    [[(1, 1, 1, 0), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [true, true, false, false],
  )
}

///|
test "independent plane quantifier family 23 identically zero equality" {
  review_plane_fixture([[]], fn(ps) { Atom(ps[0], EqualZero) }, [
    true, true, true, true,
  ])
}

///|
test "independent plane quantifier family 24 identically zero strict" {
  review_plane_fixture([[]], fn(ps) { Atom(ps[0], GreaterZero) }, [
    false, false, false, false,
  ])
}

///|
test "independent plane quantifier family 25 nonzero constant" {
  review_plane_fixture([[(3, 1, 0, 0)]], fn(ps) { Atom(ps[0], GreaterZero) }, [
    true, true, true, true,
  ])
}

///|
test "independent plane quantifier family 26 circle shared line endpoints" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 27 circle line strict interior" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [true, false, false, false],
  )
}

///|
test "independent plane quantifier family 28 open interval between moving roots" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 1, 0), (1, 1, 0, 2), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 29 closed interval between moving roots" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 1, 0), (1, 1, 0, 2), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [true, false, true, false],
  )
}

///|
test "independent plane quantifier family 30 contradictory strict and weak" {
  review_plane_fixture(
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[0], AtLeastZero)) },
    [false, false, false, false],
  )
}

///|
test "independent plane quantifier family 31 trichotomy tautology" {
  review_plane_fixture(
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) {
      Disjunction(
        Atom(ps[0], LessZero),
        Disjunction(Atom(ps[0], EqualZero), Atom(ps[0], GreaterZero)),
      )
    },
    [true, true, true, true],
  )
}

///|
test "independent plane quantifier family 32 empty true formula" {
  review_plane_fixture([], fn(_) { Truth(true) }, [true, true, true, true])
}

///|
test "independent plane quantifier family 33 empty false formula" {
  review_plane_fixture([], fn(_) { Truth(false) }, [false, false, false, false])
}

///|
test "independent plane quantifier family 34 negated closed disk" {
  review_plane_fixture(
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [true, true, true, false],
  )
}
