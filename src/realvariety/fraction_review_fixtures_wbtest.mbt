// Independent Fraction-only shape/norm oracle from tools/generate_realvariety_review.py.

///|
test "independent realvariety review fixture 0 three_fractions" {
  rv_review_fixture(
    2,
    [
      rv_review_p(2, [
        (rv_review_rat(true, "2", "7"), [1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 4]),
        (rv_review_rat(false, "3b", "64"), [0, 3]),
        (rv_review_rat(true, "95", "c4e"), [0, 2]),
        (rv_review_rat(true, "463", "834"), [0, 1]),
        (rv_review_rat(false, "20b", "113a"), [0, 0]),
      ]),
      rv_review_p(2, [
        (rv_review_rat(true, "3", "b"), [0, 3]),
        (rv_review_rat(false, "7", "14"), [0, 2]),
        (rv_review_rat(false, "39", "dc"), [0, 1]),
        (rv_review_rat(true, "7", "6e"), [0, 0]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "7", "1e"),
      rv_review_rat(true, "13", "14"),
      rv_review_rat(true, "4d", "3c"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "1", "7"),
        rv_review_rat(true, "3", "5"),
        rv_review_rat(false, "2", "3"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      rv_review_rat(true, "2", "3"),
      rv_review_rat(false, "1", "5"),
      rv_review_rat(false, "7", "4"),
    ],
    [
      rv_review_u([
        rv_review_rat(true, "95e8dd", "c6b8314"),
        rv_review_rat(false, "3f93bf", "3c8fe8"),
        rv_review_rat(true, "12abd", "93a8"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "7", "1e"),
        rv_review_rat(true, "13", "14"),
        rv_review_rat(true, "4d", "3c"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [rv_review_rat(false, "319", "3b1"), rv_review_rat(true, "2", "3")],
      [rv_review_rat(false, "1a", "20d"), rv_review_rat(false, "1", "5")],
      [rv_review_rat(false, "3b9", "348"), rv_review_rat(false, "7", "4")],
    ],
  )
}

///|
test "independent realvariety review fixture 1 close_repeated_zero" {
  rv_review_fixture(
    2,
    [
      rv_review_p(2, [
        (rv_review_rat(true, "2", "7"), [1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 5]),
        (rv_review_rat(false, "a4", "1d1"), [0, 4]),
        (rv_review_rat(true, "9d", "12c5"), [0, 3]),
        (rv_review_rat(false, "1694", "4ed5"), [0, 2]),
      ]),
      rv_review_p(2, [
        (rv_review_rat(true, "3", "b"), [0, 4]),
        (rv_review_rat(false, "9", "155"), [0, 3]),
        (rv_review_rat(true, "6", "294b"), [0, 2]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "2", "3c1"),
      rv_review_rat(true, "3", "1f"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "1", "1f"),
      rv_review_rat(false, "2", "1f"),
    ],
    [
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "4", "e1781"),
        rv_review_rat(true, "5", "3c1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "2", "3c1"),
        rv_review_rat(true, "3", "1f"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [rv_review_rat(false, "0", "1"), rv_review_rat(false, "0", "1")],
      [rv_review_rat(false, "1", "3c1"), rv_review_rat(false, "1", "1f")],
      [rv_review_rat(false, "4", "3c1"), rv_review_rat(false, "2", "1f")],
    ],
  )
}

///|
test "independent realvariety review fixture 2 collision_and_reverse" {
  rv_review_fixture(
    3,
    [
      rv_review_p(3, [
        (rv_review_rat(true, "2", "7"), [1, 0, 0]),
        (rv_review_rat(false, "1", "1"), [0, 1, 1]),
        (rv_review_rat(false, "1", "2"), [0, 1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 0, 5]),
        (rv_review_rat(false, "2", "f"), [0, 0, 4]),
        (rv_review_rat(false, "8", "f"), [0, 0, 3]),
        (rv_review_rat(false, "79", "69"), [0, 0, 2]),
        (rv_review_rat(true, "b", "6"), [0, 0, 1]),
        (rv_review_rat(true, "1", "1"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "8"), [0, 1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 0, 5]),
        (rv_review_rat(false, "2", "f"), [0, 0, 4]),
        (rv_review_rat(false, "8", "f"), [0, 0, 3]),
        (rv_review_rat(true, "2", "f"), [0, 0, 2]),
        (rv_review_rat(true, "11", "18"), [0, 0, 1]),
        (rv_review_rat(false, "3", "4"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "b"), [0, 0, 4]),
        (rv_review_rat(true, "3", "b"), [0, 0, 3]),
        (rv_review_rat(false, "3", "b"), [0, 0, 2]),
        (rv_review_rat(false, "3", "b"), [0, 0, 1]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "0", "1"),
      rv_review_rat(true, "1", "1"),
      rv_review_rat(true, "1", "1"),
      rv_review_rat(false, "1", "1"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "2", "1"),
        rv_review_rat(true, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      rv_review_rat(true, "1", "1"),
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "1", "1"),
    ],
    [
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(true, "1", "1"),
        rv_review_rat(false, "3", "1"),
        rv_review_rat(true, "3", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "12", "1"),
        rv_review_rat(true, "27", "1"),
        rv_review_rat(false, "1d", "1"),
        rv_review_rat(true, "9", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(true, "1", "1"),
        rv_review_rat(true, "1", "1"),
        rv_review_rat(false, "1", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [
        rv_review_rat(false, "1", "1"),
        rv_review_rat(false, "3", "1"),
        rv_review_rat(true, "1", "1"),
      ],
      [
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "2", "1"),
        rv_review_rat(false, "0", "1"),
      ],
      [
        rv_review_rat(false, "1", "1"),
        rv_review_rat(false, "1", "1"),
        rv_review_rat(false, "1", "1"),
      ],
    ],
  )
}

///|
test "independent realvariety review fixture 3 constant_and_zero" {
  rv_review_fixture(
    3,
    [
      rv_review_p(3, [
        (rv_review_rat(true, "2", "7"), [1, 0, 0]),
        (rv_review_rat(false, "1", "1"), [0, 1, 1]),
        (rv_review_rat(false, "1", "2"), [0, 1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 0, 3]),
        (rv_review_rat(false, "1", "3"), [0, 0, 2]),
        (rv_review_rat(false, "9", "f5"), [0, 0, 1]),
        (rv_review_rat(true, "6d", "27d"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "8"), [0, 1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 0, 3]),
        (rv_review_rat(false, "1", "3"), [0, 0, 2]),
        (rv_review_rat(false, "9", "f5"), [0, 0, 1]),
        (rv_review_rat(true, "3", "31"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "b"), [0, 0, 2]),
        (rv_review_rat(false, "1b", "21b"), [0, 0, 0]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(true, "9", "31"),
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([rv_review_rat(true, "5", "d")]),
      rv_review_u([]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [rv_review_rat(true, "3", "7"), rv_review_rat(false, "3", "7")],
    [
      rv_review_u([
        rv_review_rat(false, "19", "a9"),
        rv_review_rat(false, "a", "d"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(true, "9", "31"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [
        rv_review_rat(true, "5", "d"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(true, "3", "7"),
      ],
      [
        rv_review_rat(true, "5", "d"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "3", "7"),
      ],
    ],
  )
}

///|
test "independent realvariety review fixture 4 single_repeated_parameter" {
  rv_review_fixture(
    2,
    [
      rv_review_p(2, [
        (rv_review_rat(true, "2", "7"), [1, 0]),
        (rv_review_rat(false, "3", "23"), [0, 5]),
        (rv_review_rat(false, "6d", "ff"), [0, 4]),
        (rv_review_rat(true, "2f0", "10ef"), [0, 3]),
        (rv_review_rat(false, "2c8", "5ff5"), [0, 2]),
        (rv_review_rat(true, "ad0", "131dcf"), [0, 1]),
        (rv_review_rat(false, "7aa56", "12664a7"), [0, 0]),
      ]),
      rv_review_p(2, [
        (rv_review_rat(true, "3", "b"), [0, 4]),
        (rv_review_rat(false, "18", "bb"), [0, 3]),
        (rv_review_rat(true, "48", "c6b"), [0, 2]),
        (rv_review_rat(false, "60", "d31b"), [0, 1]),
        (rv_review_rat(true, "30", "e04cb"), [0, 0]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "10", "14641"),
      rv_review_rat(true, "20", "1331"),
      rv_review_rat(false, "18", "121"),
      rv_review_rat(true, "8", "11"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "15a4d1", "ee517b"),
        rv_review_rat(false, "f0", "14641"),
        rv_review_rat(true, "a0", "1331"),
        rv_review_rat(false, "28", "121"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [rv_review_rat(false, "2", "11")],
    [
      rv_review_u([
        rv_review_rat(
          false, "35d7cfd65f91be15404c1", "c044e55f7bed0336dafa5471",
        ),
        rv_review_rat(true, "9f03bd2c72abf844", "ce88c6d80aca002003"),
        rv_review_rat(false, "b01b51fa246", "dddb9aa31119"),
        rv_review_rat(true, "56aec4", "ee517b"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "10", "14641"),
        rv_review_rat(true, "20", "1331"),
        rv_review_rat(false, "18", "121"),
        rv_review_rat(true, "8", "11"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [
        rv_review_rat(false, "15abb1", "ee517b"),
        rv_review_rat(false, "2", "11"),
      ],
    ],
  )
}

///|
test "independent realvariety review fixture 5 high_odd_power" {
  rv_review_fixture(
    2,
    [
      rv_review_p(2, [
        (rv_review_rat(true, "2", "7"), [1, 0]),
        (rv_review_rat(false, "2", "7"), [0, 9]),
        (rv_review_rat(true, "1", "5"), [0, 5]),
        (rv_review_rat(false, "1", "3"), [0, 4]),
        (rv_review_rat(true, "13", "d2"), [0, 3]),
        (rv_review_rat(true, "1", "6"), [0, 2]),
        (rv_review_rat(true, "1", "50"), [0, 1]),
        (rv_review_rat(false, "83", "690"), [0, 0]),
      ]),
      rv_review_p(2, [
        (rv_review_rat(true, "3", "b"), [0, 4]),
        (rv_review_rat(false, "3", "16"), [0, 2]),
        (rv_review_rat(true, "3", "b0"), [0, 0]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "1", "10"),
      rv_review_rat(false, "0", "1"),
      rv_review_rat(true, "1", "2"),
      rv_review_rat(false, "0", "1"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "1", "5"),
        rv_review_rat(true, "3", "100"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(true, "1d", "30"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [rv_review_rat(true, "1", "2"), rv_review_rat(false, "1", "2")],
    [
      rv_review_u([
        rv_review_rat(false, "3865faa6fc1", "c5c1000000000"),
        rv_review_rat(true, "1e0a1f", "4650000"),
        rv_review_rat(false, "660a1f", "1c20000"),
        rv_review_rat(true, "4", "5"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "1", "10"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(true, "1", "2"),
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [rv_review_rat(false, "871", "1e00"), rv_review_rat(true, "1", "2")],
      [rv_review_rat(false, "38f", "1e00"), rv_review_rat(false, "1", "2")],
    ],
  )
}

///|
test "independent realvariety review fixture 6 three_variable_mixed_rows" {
  rv_review_fixture(
    3,
    [
      rv_review_p(3, [
        (rv_review_rat(true, "2", "7"), [1, 0, 0]),
        (rv_review_rat(false, "1", "1"), [0, 1, 1]),
        (rv_review_rat(false, "1", "2"), [0, 1, 0]),
        (rv_review_rat(true, "6", "5"), [0, 0, 4]),
        (rv_review_rat(true, "7", "b4"), [0, 0, 3]),
        (rv_review_rat(false, "20", "1b"), [0, 0, 2]),
        (rv_review_rat(false, "43", "8dc"), [0, 0, 1]),
        (rv_review_rat(false, "151", "46e"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "8"), [0, 1, 0]),
        (rv_review_rat(true, "1", "5"), [0, 0, 4]),
        (rv_review_rat(false, "12d", "168"), [0, 0, 3]),
        (rv_review_rat(false, "5", "1b"), [0, 0, 2]),
        (rv_review_rat(true, "2dd", "288"), [0, 0, 1]),
        (rv_review_rat(false, "19", "a2"), [0, 0, 0]),
      ]),
      rv_review_p(3, [
        (rv_review_rat(true, "3", "b"), [0, 0, 3]),
        (rv_review_rat(false, "17", "84"), [0, 0, 2]),
        (rv_review_rat(false, "d7", "18c"), [0, 0, 1]),
        (rv_review_rat(true, "19", "c6"), [0, 0, 0]),
      ]),
    ],
    rv_review_u([
      rv_review_rat(false, "19", "36"),
      rv_review_rat(true, "d7", "6c"),
      rv_review_rat(true, "17", "24"),
      rv_review_rat(false, "1", "1"),
    ]),
    [
      rv_review_u([
        rv_review_rat(false, "1", "2"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(true, "19", "36"),
        rv_review_rat(false, "6b", "6c"),
        rv_review_rat(false, "17", "24"),
      ]),
      rv_review_u([
        rv_review_rat(false, "0", "1"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      rv_review_rat(true, "5", "4"),
      rv_review_rat(false, "2", "9"),
      rv_review_rat(false, "5", "3"),
    ],
    [
      rv_review_u([
        rv_review_rat(false, "a9", "90"),
        rv_review_rat(true, "41", "6c"),
        rv_review_rat(true, "4d", "24"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(true, "785", "1116"),
        rv_review_rat(true, "189c55", "99c60"),
        rv_review_rat(true, "1755b", "b640"),
        rv_review_rat(false, "1", "1"),
      ]),
      rv_review_u([
        rv_review_rat(false, "19", "36"),
        rv_review_rat(true, "d7", "6c"),
        rv_review_rat(true, "17", "24"),
        rv_review_rat(false, "1", "1"),
      ]),
    ],
    [
      [
        rv_review_rat(true, "3", "4"),
        rv_review_rat(true, "2d", "40"),
        rv_review_rat(true, "5", "4"),
      ],
      [
        rv_review_rat(false, "d", "12"),
        rv_review_rat(true, "9a", "2d9"),
        rv_review_rat(false, "2", "9"),
      ],
      [
        rv_review_rat(false, "d", "6"),
        rv_review_rat(false, "50", "1b"),
        rv_review_rat(false, "5", "3"),
      ],
    ],
  )
}
