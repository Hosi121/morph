// Generated from frozen independent semantics, not implementation results.

///|
test "independent algebraic fibre 0 linear over Qsqrt2" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent algebraic fibre 1 quadratic extension fibre" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, false, true, false],
  )
}

///|
test "independent algebraic fibre 2 negative conjugate has no quadratic roots" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1]],
    [false],
  )
}

///|
test "independent algebraic fibre 3 repeated field root" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent algebraic fibre 4 shared field roots" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[-1, 1], [-1, 0], [-1, -1], [0, 0], [1, 1]],
    [false, false, false, true, false],
  )
}

///|
test "independent algebraic fibre 5 residue nullification" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 1), (1, 1, 2, 0), (-2, 1, 0, 1), (-2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent algebraic fibre 6 residue nullification strict" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[0]],
    [false],
  )
}

///|
test "independent algebraic fibre 7 vanishing leading coefficient degree drop" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 2), (-2, 1, 0, 2), (1, 1, 0, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent algebraic fibre 8 negative algebraic constant" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[-1]],
    [true],
  )
}

///|
test "independent algebraic fibre 9 positive conjugate constant" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(-1, 1, 1, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1]],
    [true],
  )
}

///|
test "independent algebraic fibre 10 empty atom truth" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [],
    fn(_) { Truth(true) },
    [[]],
    [true],
  )
}

///|
test "independent algebraic fibre 11 cubic proper extension fibre" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0), (1, 1, 0, 3)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent algebraic fibre 12 quartic proper extension fibre" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 0, 4), (-2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [-1], [0], [1]],
    [false, false, true, false, false],
  )
}

///|
test "independent algebraic fibre 13 odd even repeated root signs" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [
      [
        (1, 1, 5, 0),
        (1, 1, 4, 1),
        (-2, 1, 3, 2),
        (-2, 1, 2, 3),
        (1, 1, 1, 4),
        (1, 1, 0, 5),
      ],
    ],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1], [0], [1]],
    [false, false, true, false, true],
  )
}

///|
test "independent algebraic fibre 14 shared factors distinct intervals" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [
      [(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[1, 1], [1, 0], [1, -1], [0, 0], [1, 1]],
    [false, false, true, false, false],
  )
}

///|
test "independent algebraic fibre 15 shared factors negative conjugate" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [
      [(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[1, 1], [0, 0], [1, -1], [1, 0], [1, 1]],
    [false, false, true, false, false],
  )
}

///|
test "independent algebraic fibre 16 positive leading algebraic sign" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 1, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent algebraic fibre 17 negative leading algebraic sign" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(1, 1, 1, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [-1]],
    [true, false, false],
  )
}

///|
test "independent algebraic fibre 18 negated strict field inequality" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Negation(Atom(ps[0], LessZero)) },
    [[-1], [0], [1]],
    [false, true, true],
  )
}

///|
test "independent plane fibre 0 0 circle equality" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 0 1 circle equality" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 0 2 circle equality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, false, true, false],
  )
}

///|
test "independent plane fibre 0 3 circle equality" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 0 4 circle equality" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 1 0 closed disk" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 1 1 closed disk" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 1 2 closed disk" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, true, true, false],
  )
}

///|
test "independent plane fibre 1 3 closed disk" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 1 4 closed disk" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 2 0 open disk strict endpoints" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 2 1 open disk strict endpoints" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 2 2 open disk strict endpoints" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [-1], [0], [1]],
    [false, false, true, false, false],
  )
}

///|
test "independent plane fibre 2 3 open disk strict endpoints" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 2 4 open disk strict endpoints" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 3 0 strict circle exterior" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1]],
    [true],
  )
}

///|
test "independent plane fibre 3 1 strict circle exterior" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 3 2 strict circle exterior" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [-1], [0], [1]],
    [true, false, false, false, true],
  )
}

///|
test "independent plane fibre 3 3 strict circle exterior" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 3 4 strict circle exterior" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1]],
    [true],
  )
}

///|
test "independent plane fibre 4 0 parabola equality" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 4 1 parabola equality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 4 2 parabola equality" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 5 0 strict parabola epigraph" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 5 1 strict parabola epigraph" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 5 2 strict parabola epigraph" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(-1, 1, 2, 0), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 6 0 quadratic degree birth" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 6 1 quadratic degree birth" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 6 2 quadratic degree birth" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, false, true, false],
  )
}

///|
test "independent plane fibre 7 0 nullified xy equality" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 7 1 nullified xy equality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 7 2 nullified xy equality" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 8 0 nullified xy strict" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [-1]],
    [true, false, false],
  )
}

///|
test "independent plane fibre 8 1 nullified xy strict" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[0]],
    [false],
  )
}

///|
test "independent plane fibre 8 2 nullified xy strict" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 9 0 nullified xy disequality" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], NotZero) },
    [[1], [0], [-1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 9 1 nullified xy disequality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], NotZero) },
    [[0]],
    [false],
  )
}

///|
test "independent plane fibre 9 2 nullified xy disequality" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 1)]],
    fn(ps) { Atom(ps[0], NotZero) },
    [[-1], [0], [1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 10 0 guarded nullification" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 1, 0)], [(1, 1, 1, 1)]],
    fn(ps) { Disjunction(Atom(ps[0], EqualZero), Atom(ps[1], GreaterZero)) },
    [[-1, 1], [-1, 0], [-1, -1]],
    [true, false, false],
  )
}

///|
test "independent plane fibre 10 1 guarded nullification" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 0)], [(1, 1, 1, 1)]],
    fn(ps) { Disjunction(Atom(ps[0], EqualZero), Atom(ps[1], GreaterZero)) },
    [[0, 0]],
    [true],
  )
}

///|
test "independent plane fibre 10 2 guarded nullification" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 0)], [(1, 1, 1, 1)]],
    fn(ps) { Disjunction(Atom(ps[0], EqualZero), Atom(ps[1], GreaterZero)) },
    [[1, -1], [1, 0], [1, 1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 11 0 shared line equality" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[-1, 1], [0, 0], [1, -1], [1, 0], [1, 1]],
    [false, true, false, false, false],
  )
}

///|
test "independent plane fibre 11 1 shared line equality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[-1, 1], [0, 0], [1, 1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 11 2 shared line equality" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[-1, 1], [-1, 0], [-1, -1], [0, 0], [1, 1]],
    [false, false, false, true, false],
  )
}

///|
test "independent plane fibre 12 0 shared root collision strict" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], EqualZero)) },
    [[1, 1], [0, 0], [1, -1], [1, 0], [1, 1]],
    [false, false, false, true, false],
  )
}

///|
test "independent plane fibre 12 1 shared root collision strict" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], EqualZero)) },
    [[1, 1], [0, 0], [1, 1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 12 2 shared root collision strict" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)], [(-1, 1, 2, 0), (1, 1, 0, 2)]],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], EqualZero)) },
    [[1, 1], [1, 0], [1, -1], [0, 0], [1, 1]],
    [false, true, false, false, false],
  )
}

///|
test "independent plane fibre 13 0 repeated square impossible" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 13 1 repeated square impossible" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 13 2 repeated square impossible" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 14 0 repeated square nonnegative" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[1], [0], [1]],
    [true, true, true],
  )
}

///|
test "independent plane fibre 14 1 repeated square nonnegative" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[1], [0], [1]],
    [true, true, true],
  )
}

///|
test "independent plane fibre 14 2 repeated square nonnegative" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 0, 2)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[1], [0], [1]],
    [true, true, true],
  )
}

///|
test "independent plane fibre 15 0 shared factors mixed strict" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [0, 0], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 15 1 shared factors mixed strict" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [0, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 15 2 shared factors mixed strict" {
  review_relative_fixture(
    [(1, 2), (1, 1)],
    (-3, 2),
    (-1, 2),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [-1, 0], [-1, -1], [0, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 15 3 shared factors mixed strict" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [-1, 0], [-1, -1], [0, 0], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 15 4 shared factors mixed strict" {
  review_relative_fixture(
    [(-1, 2), (1, 1)],
    (-1, 2),
    (1, 2),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1], [0, 0], [1, 1]],
    [false, false, false, false, true, false, false],
  )
}

///|
test "independent plane fibre 15 5 shared factors mixed strict" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [0, 0], [1, -1], [0, 0], [1, 1]],
    [false, false, true, false, false],
  )
}

///|
test "independent plane fibre 15 6 shared factors mixed strict" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [
      [(1, 1, 3, 0), (-1, 1, 2, 1), (-1, 1, 1, 2), (1, 1, 0, 3)],
      [(-1, 1, 1, 1), (-1, 1, 1, 0), (1, 1, 0, 2), (1, 1, 0, 1)],
    ],
    fn(ps) { Conjunction(Atom(ps[0], GreaterZero), Atom(ps[1], LessZero)) },
    [[-1, 1], [0, 1], [1, 1], [1, 0], [1, -1], [0, 0], [1, 1]],
    [false, false, false, false, true, false, false],
  )
}

///|
test "independent plane fibre 16 0 vertical leading coefficient" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 16 1 vertical leading coefficient" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1]],
    [false],
  )
}

///|
test "independent plane fibre 16 2 vertical leading coefficient" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 17 0 quadratic to linear degree drop" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 2), (-1, 1, 0, 2), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1], [0], [-1]],
    [false, true, false, true, false],
  )
}

///|
test "independent plane fibre 17 1 quadratic to linear degree drop" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 2), (-1, 1, 0, 2), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 17 2 quadratic to linear degree drop" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 1, 2), (-1, 1, 0, 2), (1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, false, true, false],
  )
}

///|
test "independent plane fibre 18 0 vertical nullification" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 18 1 vertical nullification" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 18 2 vertical nullification" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 1, 1), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 19 0 irrational vertical nullification" {
  review_relative_fixture(
    [(-1, 1), (2, 1), (1, 1)],
    (-17, 7),
    (-12, 5),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 19 1 irrational vertical nullification" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 19 2 irrational vertical nullification" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1], [0], [-1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 19 3 irrational vertical nullification" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 19 4 irrational vertical nullification" {
  review_relative_fixture(
    [(-1, 1), (-2, 1), (1, 1)],
    (12, 5),
    (17, 7),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1], [0], [1]],
    [false, true, false],
  )
}

///|
test "independent plane fibre 20 0 irrational nullification strict" {
  review_relative_fixture(
    [(-1, 1), (2, 1), (1, 1)],
    (-17, 7),
    (-12, 5),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 20 1 irrational nullification strict" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[0]],
    [false],
  )
}

///|
test "independent plane fibre 20 2 irrational nullification strict" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1], [0], [-1]],
    [true, false, false],
  )
}

///|
test "independent plane fibre 20 3 irrational nullification strict" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[0]],
    [false],
  )
}

///|
test "independent plane fibre 20 4 irrational nullification strict" {
  review_relative_fixture(
    [(-1, 1), (-2, 1), (1, 1)],
    (12, 5),
    (17, 7),
    [[(1, 1, 2, 1), (-2, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[-1], [0], [1]],
    [false, false, true],
  )
}

///|
test "independent plane fibre 21 0 vertical factor times horizontal square" {
  review_relative_fixture(
    [(-1, 1), (2, 1), (1, 1)],
    (-17, 7),
    (-12, 5),
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[1], [0], [-1], [0], [1]],
    [true, true, false, true, true],
  )
}

///|
test "independent plane fibre 21 1 vertical factor times horizontal square" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (-10, 7),
    (-7, 5),
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 21 2 vertical factor times horizontal square" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[-1], [0], [1], [0], [-1]],
    [false, true, true, true, false],
  )
}

///|
test "independent plane fibre 21 3 vertical factor times horizontal square" {
  review_relative_fixture(
    [(-2, 1), (0, 1), (1, 1)],
    (7, 5),
    (10, 7),
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 21 4 vertical factor times horizontal square" {
  review_relative_fixture(
    [(-1, 1), (-2, 1), (1, 1)],
    (12, 5),
    (17, 7),
    [[(1, 1, 2, 2), (-1, 1, 2, 0), (-2, 1, 0, 2), (2, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], AtLeastZero) },
    [[1], [0], [-1], [0], [1]],
    [true, true, false, true, true],
  )
}

///|
test "independent plane fibre 22 0 pure base atom" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 1, 0), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[-1]],
    [false],
  )
}

///|
test "independent plane fibre 22 1 pure base atom" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 1, 0), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 22 2 pure base atom" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 1, 0), (-1, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[1]],
    [false],
  )
}

///|
test "independent plane fibre 23 0 identically zero equality" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[]],
    fn(ps) { Atom(ps[0], EqualZero) },
    [[0]],
    [true],
  )
}

///|
test "independent plane fibre 24 0 identically zero strict" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[0]],
    [false],
  )
}

///|
test "independent plane fibre 25 0 nonzero constant" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(3, 1, 0, 0)]],
    fn(ps) { Atom(ps[0], GreaterZero) },
    [[1]],
    [true],
  )
}

///|
test "independent plane fibre 26 0 circle shared line endpoints" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 26 1 circle shared line endpoints" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 2 circle shared line endpoints" {
  review_relative_fixture(
    [(1, 8), (1, 1), (1, 1)],
    (-6, 7),
    (-5, 6),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 3 circle shared line endpoints" {
  review_relative_fixture(
    [(-1, 2), (0, 1), (1, 1)],
    (-5, 7),
    (-7, 10),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, 0], [-1, 1], [0, 1], [1, 1]],
    [false, true, false, false, false],
  )
}

///|
test "independent plane fibre 26 4 circle shared line endpoints" {
  review_relative_fixture(
    [(-1, 8), (0, 1), (1, 1)],
    (-4, 11),
    (-1, 3),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 5 circle shared line endpoints" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 6 circle shared line endpoints" {
  review_relative_fixture(
    [(-1, 8), (0, 1), (1, 1)],
    (1, 3),
    (4, 11),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 7 circle shared line endpoints" {
  review_relative_fixture(
    [(-1, 2), (0, 1), (1, 1)],
    (7, 10),
    (5, 7),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [0, 0], [1, 1]],
    [false, false, false, true, false],
  )
}

///|
test "independent plane fibre 26 8 circle shared line endpoints" {
  review_relative_fixture(
    [(1, 8), (-1, 1), (1, 1)],
    (5, 6),
    (6, 7),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [0, -1], [1, -1], [1, 0], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 9 circle shared line endpoints" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [1, -1], [1, 0], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 26 10 circle shared line endpoints" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], EqualZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 27 0 circle line strict interior" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 27 1 circle line strict interior" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 2 circle line strict interior" {
  review_relative_fixture(
    [(1, 8), (1, 1), (1, 1)],
    (-6, 7),
    (-5, 6),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 3 circle line strict interior" {
  review_relative_fixture(
    [(-1, 2), (0, 1), (1, 1)],
    (-5, 7),
    (-7, 10),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 4 circle line strict interior" {
  review_relative_fixture(
    [(-1, 8), (0, 1), (1, 1)],
    (-4, 11),
    (-1, 3),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, true, false, false, false],
  )
}

///|
test "independent plane fibre 27 5 circle line strict interior" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, true, false, false, false],
  )
}

///|
test "independent plane fibre 27 6 circle line strict interior" {
  review_relative_fixture(
    [(-1, 8), (0, 1), (1, 1)],
    (1, 3),
    (4, 11),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1], [1, 1]],
    [false, false, false, true, false, false, false],
  )
}

///|
test "independent plane fibre 27 7 circle line strict interior" {
  review_relative_fixture(
    [(-1, 2), (0, 1), (1, 1)],
    (7, 10),
    (5, 7),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [0, 0], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 8 circle line strict interior" {
  review_relative_fixture(
    [(1, 8), (-1, 1), (1, 1)],
    (5, 6),
    (6, 7),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [-1, -1], [0, -1], [1, -1], [1, 0], [1, 1]],
    [false, false, false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 9 circle line strict interior" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [0, -1], [1, -1], [1, 0], [1, 1]],
    [false, false, false, false, false],
  )
}

///|
test "independent plane fibre 27 10 circle line strict interior" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)], [(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[1], EqualZero)) },
    [[1, -1], [1, 0], [1, 1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 28 0 open interval between moving roots" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 1, 0), (1, 1, 0, 2), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], LessZero) },
    [[1], [0], [-1], [0], [1]],
    [false, false, true, false, false],
  )
}

///|
test "independent plane fibre 29 0 closed interval between moving roots" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (-2, 1, 1, 1), (1, 1, 1, 0), (1, 1, 0, 2), (-1, 1, 0, 1)]],
    fn(ps) { Atom(ps[0], AtMostZero) },
    [[1], [0], [-1], [0], [1]],
    [false, true, true, true, false],
  )
}

///|
test "independent plane fibre 30 0 contradictory strict and weak" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) { Conjunction(Atom(ps[0], LessZero), Atom(ps[0], AtLeastZero)) },
    [[-1], [0], [1]],
    [false, false, false],
  )
}

///|
test "independent plane fibre 31 0 trichotomy tautology" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(-1, 1, 1, 0), (1, 1, 0, 1)]],
    fn(ps) {
      Disjunction(
        Atom(ps[0], LessZero),
        Disjunction(Atom(ps[0], EqualZero), Atom(ps[0], GreaterZero)),
      )
    },
    [[-1], [0], [1]],
    [true, true, true],
  )
}

///|
test "independent plane fibre 32 0 empty true formula" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [],
    fn(_) { Truth(true) },
    [[]],
    [true],
  )
}

///|
test "independent plane fibre 33 0 empty false formula" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [],
    fn(_) { Truth(false) },
    [[]],
    [false],
  )
}

///|
test "independent plane fibre 34 0 negated closed disk" {
  review_relative_fixture(
    [(2, 1), (1, 1)],
    (-3, 1),
    (-2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [[1]],
    [true],
  )
}

///|
test "independent plane fibre 34 1 negated closed disk" {
  review_relative_fixture(
    [(1, 1), (1, 1)],
    (-2, 1),
    (-1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [[1], [0], [1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 34 2 negated closed disk" {
  review_relative_fixture(
    [(0, 1), (1, 1)],
    (-1, 1),
    (0, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [[1], [0], [-1], [0], [1]],
    [true, false, false, false, true],
  )
}

///|
test "independent plane fibre 34 3 negated closed disk" {
  review_relative_fixture(
    [(-1, 1), (1, 1)],
    (0, 1),
    (1, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [[1], [0], [1]],
    [true, false, true],
  )
}

///|
test "independent plane fibre 34 4 negated closed disk" {
  review_relative_fixture(
    [(-2, 1), (1, 1)],
    (1, 1),
    (2, 1),
    [[(1, 1, 2, 0), (1, 1, 0, 2), (-1, 1, 0, 0)]],
    fn(ps) { Negation(Atom(ps[0], AtMostZero)) },
    [[1]],
    [true],
  )
}
