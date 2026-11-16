// Independent Fraction/Q(sqrt(d)) oracle from tools/generate_realcad_review.py.

///|
test "independent realcad review fixture 0 rational_denominators" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(true, "2", "37"),
              review_ratio(true, "3", "37"),
              review_ratio(false, "7", "b"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "19ff", "1c0"),
              review_ratio(true, "717", "70"),
              review_ratio(false, "a5", "1c"),
              review_ratio(true, "5", "7"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "0", "1"),
                  review_ratio(true, "31", "f"),
                  review_ratio(true, "e", "5"),
                  review_ratio(true, "3", "5"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "7", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(true, "1", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "b", "4"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, false, true, false, true, false, true, true, true],
  )
}

///|
test "independent realcad review fixture 1 rational_denominators" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "0", "1"),
                review_ratio(true, "2", "37"),
                review_ratio(true, "3", "37"),
                review_ratio(false, "7", "b"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "19ff", "1c0"),
                  review_ratio(true, "717", "70"),
                  review_ratio(false, "a5", "1c"),
                  review_ratio(true, "5", "7"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "7", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(true, "1", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "b", "4"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 2 rational_denominators" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(true, "2", "37"),
              review_ratio(true, "3", "37"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(true, "2", "37"),
              review_ratio(true, "3", "37"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "19ff", "1c0"),
              review_ratio(true, "717", "70"),
              review_ratio(false, "a5", "1c"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "19ff", "1c0"),
              review_ratio(true, "717", "70"),
              review_ratio(false, "a5", "1c"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "7", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(true, "1", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "b", "4"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 3 rational_denominators" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "31", "f"),
              review_ratio(true, "e", "5"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(true, "2", "37"),
              review_ratio(true, "3", "37"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(true, "2", "37"),
              review_ratio(true, "3", "37"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "19ff", "1c0"),
              review_ratio(true, "717", "70"),
              review_ratio(false, "a5", "1c"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "19ff", "1c0"),
              review_ratio(true, "717", "70"),
              review_ratio(false, "a5", "1c"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "7", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(true, "1", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "b", "4"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
    ],
  )
}

///|
test "independent realcad review fixture 4 near_zero_31" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "294b"),
              review_ratio(true, "15", "155"),
              review_ratio(false, "7", "b"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "87", "32e99"),
              review_ratio(true, "87", "1a47"),
              review_ratio(false, "2d", "d9"),
              review_ratio(true, "5", "7"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "3", "12c5"),
                  review_ratio(false, "24", "3c1"),
                  review_ratio(true, "9d2", "12c5"),
                  review_ratio(true, "24", "1f"),
                  review_ratio(true, "3", "5"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "1", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "1f"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, false, true, false, true, false, true, true, true],
  )
}

///|
test "independent realcad review fixture 5 near_zero_31" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "0", "1"),
                review_ratio(false, "e", "294b"),
                review_ratio(true, "15", "155"),
                review_ratio(false, "7", "b"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "87", "32e99"),
                  review_ratio(true, "87", "1a47"),
                  review_ratio(false, "2d", "d9"),
                  review_ratio(true, "5", "7"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "1", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "1f"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 6 near_zero_31" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "294b"),
              review_ratio(true, "15", "155"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "294b"),
              review_ratio(true, "15", "155"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "87", "32e99"),
              review_ratio(true, "87", "1a47"),
              review_ratio(false, "2d", "d9"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "87", "32e99"),
              review_ratio(true, "87", "1a47"),
              review_ratio(false, "2d", "d9"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "1f"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 7 near_zero_31" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "3", "12c5"),
              review_ratio(false, "24", "3c1"),
              review_ratio(true, "9d2", "12c5"),
              review_ratio(true, "24", "1f"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "294b"),
              review_ratio(true, "15", "155"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "294b"),
              review_ratio(true, "15", "155"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "87", "32e99"),
              review_ratio(true, "87", "1a47"),
              review_ratio(false, "2d", "d9"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "87", "32e99"),
              review_ratio(true, "87", "1a47"),
              review_ratio(false, "2d", "d9"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1f"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "1f"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
    ],
  )
}

///|
test "independent realcad review fixture 8 close_257" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "b160b"),
              review_ratio(true, "15", "b0b"),
              review_ratio(false, "7", "b"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "5", "38"),
              review_ratio(true, "f", "1c"),
              review_ratio(false, "f", "e"),
              review_ratio(true, "5", "7"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "1", "f1e0f"),
                  review_ratio(false, "1fc", "f1e0f"),
                  review_ratio(true, "f5fe", "f1e0f"),
                  review_ratio(true, "1fc", "505"),
                  review_ratio(true, "3", "5"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "2"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, false, true, false, true, false, true, true, true],
  )
}

///|
test "independent realcad review fixture 9 close_257" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "0", "1"),
                review_ratio(false, "e", "b160b"),
                review_ratio(true, "15", "b0b"),
                review_ratio(false, "7", "b"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "5", "38"),
                  review_ratio(true, "f", "1c"),
                  review_ratio(false, "f", "e"),
                  review_ratio(true, "5", "7"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "2"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 10 close_257" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "b160b"),
              review_ratio(true, "15", "b0b"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "b160b"),
              review_ratio(true, "15", "b0b"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "5", "38"),
              review_ratio(true, "f", "1c"),
              review_ratio(false, "f", "e"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "5", "38"),
              review_ratio(true, "f", "1c"),
              review_ratio(false, "f", "e"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "2"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 11 close_257" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "1", "f1e0f"),
              review_ratio(false, "1fc", "f1e0f"),
              review_ratio(true, "f5fe", "f1e0f"),
              review_ratio(true, "1fc", "505"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "b160b"),
              review_ratio(true, "15", "b0b"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "0", "1"),
              review_ratio(false, "e", "b160b"),
              review_ratio(true, "15", "b0b"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "5", "38"),
              review_ratio(true, "f", "1c"),
              review_ratio(false, "f", "e"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "5", "38"),
              review_ratio(true, "f", "1c"),
              review_ratio(false, "f", "e"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "101"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "2"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
    ],
  )
}

///|
test "independent realcad review fixture 12 close_translated" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "70404", "84a71b"),
              review_ratio(false, "a05d", "1b907"),
              review_ratio(true, "48c", "575"),
              review_ratio(false, "7", "b"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "28", "7"),
              review_ratio(true, "3c", "7"),
              review_ratio(false, "1e", "7"),
              review_ratio(true, "5", "7"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "3e05b0", "b8a89e5"),
                  review_ratio(true, "1b48", "3c4bf5"),
                  review_ratio(false, "d8825", "3c4bf5"),
                  review_ratio(false, "6", "27b"),
                  review_ratio(true, "3", "5"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "184", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "18b", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, false, true, false, true, false, true, true, true],
  )
}

///|
test "independent realcad review fixture 13 close_translated" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(true, "70404", "84a71b"),
                review_ratio(false, "a05d", "1b907"),
                review_ratio(true, "48c", "575"),
                review_ratio(false, "7", "b"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "28", "7"),
                  review_ratio(true, "3c", "7"),
                  review_ratio(false, "1e", "7"),
                  review_ratio(true, "5", "7"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "184", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "18b", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 14 close_translated" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "70404", "84a71b"),
              review_ratio(false, "a05d", "1b907"),
              review_ratio(true, "48c", "575"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "70404", "84a71b"),
              review_ratio(false, "a05d", "1b907"),
              review_ratio(true, "48c", "575"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "28", "7"),
              review_ratio(true, "3c", "7"),
              review_ratio(false, "1e", "7"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "28", "7"),
              review_ratio(true, "3c", "7"),
              review_ratio(false, "1e", "7"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "184", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "18b", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [true, true, true, true, true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 15 close_translated" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "3e05b0", "b8a89e5"),
              review_ratio(true, "1b48", "3c4bf5"),
              review_ratio(false, "d8825", "3c4bf5"),
              review_ratio(false, "6", "27b"),
              review_ratio(true, "3", "5"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "70404", "84a71b"),
              review_ratio(false, "a05d", "1b907"),
              review_ratio(true, "48c", "575"),
              review_ratio(false, "7", "b"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "70404", "84a71b"),
              review_ratio(false, "a05d", "1b907"),
              review_ratio(true, "48c", "575"),
              review_ratio(false, "7", "b"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "28", "7"),
              review_ratio(true, "3c", "7"),
              review_ratio(false, "1e", "7"),
              review_ratio(true, "5", "7"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "28", "7"),
              review_ratio(true, "3c", "7"),
              review_ratio(false, "1e", "7"),
              review_ratio(true, "5", "7"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "3", "7"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "184", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "18b", "379"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "2", "1"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
    ],
  )
}

///|
test "independent realcad review fixture 16 sqrt2_close_shift" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "3a9a", "1331"),
              review_ratio(false, "34", "121"),
              review_ratio(true, "3aa7", "1331"),
              review_ratio(true, "1a", "121"),
              review_ratio(false, "d", "11"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "31", "1ef"),
              review_ratio(true, "149", "1ef"),
              review_ratio(false, "d9", "a5"),
              review_ratio(true, "7", "b"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "14", "9"),
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "14", "9"),
                  review_ratio(false, "0", "1"),
                  review_ratio(true, "5", "9"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "7", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(false, "1", "1"), 2),
    ],
    [
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, false, true, false, true, true, true, true, true, false, true, false,
      true,
    ],
  )
}

///|
test "independent realcad review fixture 17 sqrt2_close_shift" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "3a9a", "1331"),
                review_ratio(false, "34", "121"),
                review_ratio(true, "3aa7", "1331"),
                review_ratio(true, "1a", "121"),
                review_ratio(false, "d", "11"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "31", "1ef"),
                  review_ratio(true, "149", "1ef"),
                  review_ratio(false, "d9", "a5"),
                  review_ratio(true, "7", "b"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "7", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(false, "1", "1"), 2),
    ],
    [
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 18 sqrt2_close_shift" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "3a9a", "1331"),
              review_ratio(false, "34", "121"),
              review_ratio(true, "3aa7", "1331"),
              review_ratio(true, "1a", "121"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "3a9a", "1331"),
              review_ratio(false, "34", "121"),
              review_ratio(true, "3aa7", "1331"),
              review_ratio(true, "1a", "121"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "31", "1ef"),
              review_ratio(true, "149", "1ef"),
              review_ratio(false, "d9", "a5"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "31", "1ef"),
              review_ratio(true, "149", "1ef"),
              review_ratio(false, "d9", "a5"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "7", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(false, "1", "1"), 2),
    ],
    [
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 19 sqrt2_close_shift" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "14", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "3a9a", "1331"),
              review_ratio(false, "34", "121"),
              review_ratio(true, "3aa7", "1331"),
              review_ratio(true, "1a", "121"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "3a9a", "1331"),
              review_ratio(false, "34", "121"),
              review_ratio(true, "3aa7", "1331"),
              review_ratio(true, "1a", "121"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "31", "1ef"),
              review_ratio(true, "149", "1ef"),
              review_ratio(false, "d9", "a5"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "31", "1ef"),
              review_ratio(true, "149", "1ef"),
              review_ratio(false, "d9", "a5"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(true, "1", "1"), 2),
      (review_ratio(false, "1", "3"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "7", "5"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 2),
      (review_ratio(false, "1", "11"), review_ratio(false, "1", "1"), 2),
    ],
    [
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
      false, false,
    ],
  )
}

///|
test "independent realcad review fixture 20 sqrt3_shared_even" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "5ee", "dd"),
              review_ratio(true, "6", "11"),
              review_ratio(true, "3f5", "dd"),
              review_ratio(false, "2", "11"),
              review_ratio(false, "d", "11"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "10", "21"),
              review_ratio(false, "74", "63"),
              review_ratio(false, "8", "21"),
              review_ratio(true, "7", "b"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "5", "1"),
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "a", "3"),
                  review_ratio(false, "0", "1"),
                  review_ratio(true, "5", "9"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "1", "d"), review_ratio(true, "1", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 3),
      (review_ratio(true, "2", "3"), review_ratio(false, "0", "1"), 3),
      (review_ratio(true, "1", "d"), review_ratio(false, "1", "1"), 3),
      (review_ratio(false, "c", "7"), review_ratio(false, "0", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 3),
    ],
    [
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, -1, 0, -1, 0],
      [-1, -1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, false, true, false, true, true, true, false, true, true, true, false,
      true,
    ],
  )
}

///|
test "independent realcad review fixture 21 sqrt3_shared_even" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "5ee", "dd"),
                review_ratio(true, "6", "11"),
                review_ratio(true, "3f5", "dd"),
                review_ratio(false, "2", "11"),
                review_ratio(false, "d", "11"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "10", "21"),
                  review_ratio(false, "74", "63"),
                  review_ratio(false, "8", "21"),
                  review_ratio(true, "7", "b"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "1", "d"), review_ratio(true, "1", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 3),
      (review_ratio(true, "2", "3"), review_ratio(false, "0", "1"), 3),
      (review_ratio(true, "1", "d"), review_ratio(false, "1", "1"), 3),
      (review_ratio(false, "c", "7"), review_ratio(false, "0", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 3),
    ],
    [
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, -1, 0, -1, 0],
      [-1, -1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 22 sqrt3_shared_even" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "5ee", "dd"),
              review_ratio(true, "6", "11"),
              review_ratio(true, "3f5", "dd"),
              review_ratio(false, "2", "11"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "5ee", "dd"),
              review_ratio(true, "6", "11"),
              review_ratio(true, "3f5", "dd"),
              review_ratio(false, "2", "11"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "10", "21"),
              review_ratio(false, "74", "63"),
              review_ratio(false, "8", "21"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "10", "21"),
              review_ratio(false, "74", "63"),
              review_ratio(false, "8", "21"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "d"), review_ratio(true, "1", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 3),
      (review_ratio(true, "2", "3"), review_ratio(false, "0", "1"), 3),
      (review_ratio(true, "1", "d"), review_ratio(false, "1", "1"), 3),
      (review_ratio(false, "c", "7"), review_ratio(false, "0", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 3),
    ],
    [
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, -1, 0, 0, -1],
      [-1, -1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 23 sqrt3_shared_even" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "5", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "a", "3"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "5ee", "dd"),
              review_ratio(true, "6", "11"),
              review_ratio(true, "3f5", "dd"),
              review_ratio(false, "2", "11"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "5ee", "dd"),
              review_ratio(true, "6", "11"),
              review_ratio(true, "3f5", "dd"),
              review_ratio(false, "2", "11"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "10", "21"),
              review_ratio(false, "74", "63"),
              review_ratio(false, "8", "21"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "10", "21"),
              review_ratio(false, "74", "63"),
              review_ratio(false, "8", "21"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "1", "d"), review_ratio(true, "1", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 3),
      (review_ratio(true, "2", "3"), review_ratio(false, "0", "1"), 3),
      (review_ratio(true, "1", "d"), review_ratio(false, "1", "1"), 3),
      (review_ratio(false, "c", "7"), review_ratio(false, "0", "1"), 3),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 3),
    ],
    [
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, -1, 0, 0, -1],
      [-1, -1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
      false, false,
    ],
  )
}

///|
test "independent realcad review fixture 24 sqrt5_close_shift" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "4c3c4", "3fd1"),
              review_ratio(false, "82", "20f"),
              review_ratio(true, "1e7f5", "3fd1"),
              review_ratio(true, "1a", "20f"),
              review_ratio(false, "d", "11"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "237", "50"),
              review_ratio(false, "a95", "370"),
              review_ratio(false, "a1", "6e"),
              review_ratio(true, "7", "b"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "7d", "9"),
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "32", "9"),
                  review_ratio(false, "0", "1"),
                  review_ratio(true, "5", "9"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(true, "1", "1"), 5),
      (review_ratio(true, "b", "5"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 5),
      (review_ratio(false, "9", "4"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(false, "1", "1"), 5),
    ],
    [
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, -1, 0, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, false, true, false, true, true, true, false, true, true, true, false,
      true,
    ],
  )
}

///|
test "independent realcad review fixture 25 sqrt5_close_shift" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(false, "4c3c4", "3fd1"),
                review_ratio(false, "82", "20f"),
                review_ratio(true, "1e7f5", "3fd1"),
                review_ratio(true, "1a", "20f"),
                review_ratio(false, "d", "11"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(true, "237", "50"),
                  review_ratio(false, "a95", "370"),
                  review_ratio(false, "a1", "6e"),
                  review_ratio(true, "7", "b"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(true, "1", "1"), 5),
      (review_ratio(true, "b", "5"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 5),
      (review_ratio(false, "9", "4"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(false, "1", "1"), 5),
    ],
    [
      [-1, 1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 1, 0, -1, 0],
      [-1, 1, -1, -1, 0],
      [0, 0, -1, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, -1, 0, -1, 0],
      [-1, -1, -1, -1, 0],
      [-1, 0, -1, -1, 0],
      [-1, 1, -1, -1, 0],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 26 sqrt5_close_shift" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "4c3c4", "3fd1"),
              review_ratio(false, "82", "20f"),
              review_ratio(true, "1e7f5", "3fd1"),
              review_ratio(true, "1a", "20f"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "4c3c4", "3fd1"),
              review_ratio(false, "82", "20f"),
              review_ratio(true, "1e7f5", "3fd1"),
              review_ratio(true, "1a", "20f"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "237", "50"),
              review_ratio(false, "a95", "370"),
              review_ratio(false, "a1", "6e"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "237", "50"),
              review_ratio(false, "a95", "370"),
              review_ratio(false, "a1", "6e"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(true, "1", "1"), 5),
      (review_ratio(true, "b", "5"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 5),
      (review_ratio(false, "9", "4"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(false, "1", "1"), 5),
    ],
    [
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, -1, 0, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      true, true, true, true, true, true, true, true, true, true, true, true, true,
    ],
  )
}

///|
test "independent realcad review fixture 27 sqrt5_close_shift" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "7d", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "32", "9"),
              review_ratio(false, "0", "1"),
              review_ratio(true, "5", "9"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "4c3c4", "3fd1"),
              review_ratio(false, "82", "20f"),
              review_ratio(true, "1e7f5", "3fd1"),
              review_ratio(true, "1a", "20f"),
              review_ratio(false, "d", "11"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "4c3c4", "3fd1"),
              review_ratio(false, "82", "20f"),
              review_ratio(true, "1e7f5", "3fd1"),
              review_ratio(true, "1a", "20f"),
              review_ratio(false, "d", "11"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "237", "50"),
              review_ratio(false, "a95", "370"),
              review_ratio(false, "a1", "6e"),
              review_ratio(true, "7", "b"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "237", "50"),
              review_ratio(false, "a95", "370"),
              review_ratio(false, "a1", "6e"),
              review_ratio(true, "7", "b"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(false, "0", "1"), review_ratio(true, "1", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(true, "1", "1"), 5),
      (review_ratio(true, "b", "5"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "0", "1"), review_ratio(false, "1", "1"), 5),
      (review_ratio(false, "9", "4"), review_ratio(false, "0", "1"), 5),
      (review_ratio(false, "1", "1f"), review_ratio(false, "1", "1"), 5),
    ],
    [
      [-1, 1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 1, 0, 0, -1],
      [-1, 1, -1, 0, -1],
      [0, 0, -1, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, -1, 0, 0, -1],
      [-1, -1, -1, 0, -1],
      [-1, 0, -1, 0, -1],
      [-1, 1, -1, 0, -1],
    ],
    [
      false, false, false, false, false, false, false, false, false, false, false,
      false, false,
    ],
  )
}

///|
test "independent realcad review fixture 28 degree10_even_shared_positive" {
  review_assert_fixture(
    Conjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "440", "1b50f7"),
              review_ratio(false, "51d0", "91afd"),
              review_ratio(true, "63b03", "91afd"),
              review_ratio(false, "6b5bb", "1700d"),
              review_ratio(true, "14c9", "675"),
              review_ratio(false, "11", "1d"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
            ]),
            EqualZero,
          ),
          Negation(
            Disjunction(
              Atom(
                review_polynomial([
                  review_ratio(true, "1adb", "a431f0"),
                  review_ratio(false, "1bdcd", "5218f8"),
                  review_ratio(true, "5929", "2e170"),
                  review_ratio(true, "234619", "290c7c"),
                  review_ratio(true, "25b1e1", "123e70"),
                  review_ratio(true, "111110b", "5218f8"),
                  review_ratio(true, "2b9e60b", "a431f0"),
                  review_ratio(true, "1b4b31", "6d76a"),
                  review_ratio(true, "b483", "40de"),
                  review_ratio(true, "58", "39"),
                  review_ratio(true, "b", "17"),
                ]),
                LessZero,
              ),
              Atom(
                review_polynomial([review_ratio(true, "2", "d")]),
                GreaterZero,
              ),
            ),
          ),
        ),
      ),
      Atom(review_polynomial([]), EqualZero),
    ),
    [
      (review_ratio(true, "5", "6"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "13"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "8", "3"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
    ],
    [true, true, true, false, true, false, true],
  )
}

///|
test "independent realcad review fixture 29 degree10_even_shared_positive" {
  review_assert_fixture(
    Conjunction(
      Negation(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            GreaterZero,
          ),
          Disjunction(
            Atom(
              review_polynomial([
                review_ratio(true, "440", "1b50f7"),
                review_ratio(false, "51d0", "91afd"),
                review_ratio(true, "63b03", "91afd"),
                review_ratio(false, "6b5bb", "1700d"),
                review_ratio(true, "14c9", "675"),
                review_ratio(false, "11", "1d"),
              ]),
              AtMostZero,
            ),
            Negation(
              Atom(
                review_polynomial([
                  review_ratio(false, "1", "1"),
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "1", "1"),
                  review_ratio(false, "0", "1"),
                  review_ratio(false, "1", "1"),
                ]),
                EqualZero,
              ),
            ),
          ),
        ),
      ),
      Disjunction(
        Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        Atom(review_polynomial([]), NotZero),
      ),
    ),
    [
      (review_ratio(true, "5", "6"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "13"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "8", "3"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, -1, 0],
      [0, -1, 1, -1, 0],
      [-1, -1, 1, -1, 0],
      [0, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
      [-1, 0, 1, -1, 0],
      [-1, 1, 1, -1, 0],
    ],
    [true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 30 degree10_even_shared_positive" {
  review_assert_fixture(
    Conjunction(
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            NotZero,
          ),
        ),
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "440", "1b50f7"),
              review_ratio(false, "51d0", "91afd"),
              review_ratio(true, "63b03", "91afd"),
              review_ratio(false, "6b5bb", "1700d"),
              review_ratio(true, "14c9", "675"),
              review_ratio(false, "11", "1d"),
            ]),
            AtMostZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "440", "1b50f7"),
              review_ratio(false, "51d0", "91afd"),
              review_ratio(true, "63b03", "91afd"),
              review_ratio(false, "6b5bb", "1700d"),
              review_ratio(true, "14c9", "675"),
              review_ratio(false, "11", "1d"),
            ]),
            GreaterZero,
          ),
        ),
      ),
      Conjunction(
        Disjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
            ]),
            AtLeastZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
            ]),
            LessZero,
          ),
        ),
        Disjunction(
          Atom(review_polynomial([]), EqualZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), GreaterZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "5", "6"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "13"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "8", "3"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
    ],
    [true, true, true, true, true, true, true],
  )
}

///|
test "independent realcad review fixture 31 degree10_even_shared_positive" {
  review_assert_fixture(
    Disjunction(
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            EqualZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "1adb", "a431f0"),
              review_ratio(false, "1bdcd", "5218f8"),
              review_ratio(true, "5929", "2e170"),
              review_ratio(true, "234619", "290c7c"),
              review_ratio(true, "25b1e1", "123e70"),
              review_ratio(true, "111110b", "5218f8"),
              review_ratio(true, "2b9e60b", "a431f0"),
              review_ratio(true, "1b4b31", "6d76a"),
              review_ratio(true, "b483", "40de"),
              review_ratio(true, "58", "39"),
              review_ratio(true, "b", "17"),
            ]),
            NotZero,
          ),
        ),
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(true, "440", "1b50f7"),
              review_ratio(false, "51d0", "91afd"),
              review_ratio(true, "63b03", "91afd"),
              review_ratio(false, "6b5bb", "1700d"),
              review_ratio(true, "14c9", "675"),
              review_ratio(false, "11", "1d"),
            ]),
            GreaterZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(true, "440", "1b50f7"),
              review_ratio(false, "51d0", "91afd"),
              review_ratio(true, "63b03", "91afd"),
              review_ratio(false, "6b5bb", "1700d"),
              review_ratio(true, "14c9", "675"),
              review_ratio(false, "11", "1d"),
            ]),
            AtMostZero,
          ),
        ),
      ),
      Disjunction(
        Conjunction(
          Atom(
            review_polynomial([
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
            ]),
            LessZero,
          ),
          Atom(
            review_polynomial([
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
              review_ratio(false, "0", "1"),
              review_ratio(false, "1", "1"),
            ]),
            AtLeastZero,
          ),
        ),
        Conjunction(
          Atom(review_polynomial([]), NotZero),
          Atom(review_polynomial([review_ratio(true, "2", "d")]), LessZero),
        ),
      ),
    ),
    [
      (review_ratio(true, "5", "6"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "1", "13"), review_ratio(false, "0", "1"), 2),
      (review_ratio(false, "8", "3"), review_ratio(false, "0", "1"), 2),
    ],
    [
      [-1, -1, 1, 0, -1],
      [0, -1, 1, 0, -1],
      [-1, -1, 1, 0, -1],
      [0, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
      [-1, 0, 1, 0, -1],
      [-1, 1, 1, 0, -1],
    ],
    [false, false, false, false, false, false, false],
  )
}
