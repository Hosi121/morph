// Independent symbolic permutation determinant; discriminants specialize universal coefficient formulas.

///|
test "elimination independent polynomial coefficient projection 0" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 1]),
    ]),
    1,
    2,
    1,
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [2]),
      (elimination_rat(false, "1", "1"), [1]),
    ]),
    elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 1" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [2, 0]),
      (elimination_rat(false, "1", "1"), [0, 1]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 1]),
    ]),
    0,
    2,
    1,
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [2]),
      (elimination_rat(false, "1", "1"), [1]),
    ]),
    elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 2" {
  elimination_projection_fixture(
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [1, 1, 0]),
      (elimination_rat(false, "1", "1"), [0, 0, 1]),
    ]),
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [1, 0, 1]),
      (elimination_rat(false, "1", "1"), [0, 2, 0]),
    ]),
    1,
    1,
    2,
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [3, 1]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 3" {
  elimination_projection_fixture(
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [2, 0, 0]),
      (elimination_rat(false, "1", "1"), [0, 1, 1]),
    ]),
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [1, 0, 0]),
      (elimination_rat(false, "1", "1"), [0, 1, 0]),
      (elimination_rat(false, "1", "1"), [0, 0, 1]),
    ]),
    0,
    2,
    1,
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [2, 0]),
      (elimination_rat(false, "3", "1"), [1, 1]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    elimination_poly(2, [(elimination_rat(true, "4", "1"), [1, 1])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 4" {
  elimination_projection_fixture(
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [1, 1, 0]),
      (elimination_rat(false, "1", "1"), [0, 0, 2]),
      (elimination_rat(false, "1", "1"), [0, 0, 0]),
    ]),
    elimination_poly(3, [
      (elimination_rat(false, "1", "1"), [1, 0, 0]),
      (elimination_rat(true, "1", "1"), [0, 1, 0]),
      (elimination_rat(false, "1", "1"), [0, 0, 1]),
    ]),
    2,
    2,
    1,
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [2, 0]),
      (elimination_rat(true, "1", "1"), [1, 1]),
      (elimination_rat(false, "1", "1"), [0, 2]),
      (elimination_rat(false, "1", "1"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "4", "1"), [1, 1]),
      (elimination_rat(true, "4", "1"), [0, 0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 5" {
  elimination_projection_fixture(
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [2]),
      (elimination_rat(false, "2", "3"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(false, "3", "1"), [1]),
      (elimination_rat(true, "5", "7"), [0]),
    ]),
    0,
    2,
    1,
    elimination_poly(0, [(elimination_rat(false, "13f", "31"), [])]),
    elimination_poly(0, [(elimination_rat(true, "8", "3"), [])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 6" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 1]),
      (elimination_rat(false, "1", "1"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [0, 1]),
      (elimination_rat(false, "1", "1"), [0, 0]),
    ]),
    1,
    1,
    1,
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [1]),
      (elimination_rat(true, "1", "1"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 7" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [0, 1]),
      (elimination_rat(false, "1", "1"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    1,
    2,
    2,
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [1]),
      (elimination_rat(false, "1", "1"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 8" {
  elimination_projection_fixture(
    elimination_poly(2, []),
    elimination_poly(2, []),
    1,
    0,
    0,
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 9" {
  elimination_projection_fixture(
    elimination_poly(2, [(elimination_rat(false, "2", "7"), [0, 0])]),
    elimination_poly(2, [(elimination_rat(true, "3", "b"), [0, 0])]),
    1,
    0,
    0,
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 10" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [2, 0]),
      (elimination_rat(true, "2", "1"), [1, 1]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "1", "1"), [1, 1]),
      (elimination_rat(true, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 2]),
      (elimination_rat(false, "1", "1"), [0, 1]),
    ]),
    1,
    2,
    2,
    elimination_poly(1, []),
    elimination_poly(1, []),
  )
}

///|
test "elimination independent polynomial coefficient projection 11" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 1]),
      (elimination_rat(false, "1", "1"), [0, 3]),
      (elimination_rat(false, "1", "1"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 2]),
    ]),
    1,
    3,
    2,
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    elimination_poly(1, [
      (elimination_rat(true, "4", "1"), [3]),
      (elimination_rat(true, "1b", "1"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 12" {
  elimination_projection_fixture(
    elimination_poly(2, [(elimination_rat(true, "1", "1"), [0, 1])]),
    elimination_poly(2, [
      (elimination_rat(true, "2", "b"), [2, 1]),
      (elimination_rat(false, "2", "7"), [1, 0]),
      (elimination_rat(true, "2", "b"), [0, 1]),
      (elimination_rat(false, "2", "7"), [0, 0]),
    ]),
    1,
    1,
    1,
    elimination_poly(1, [
      (elimination_rat(true, "2", "7"), [1]),
      (elimination_rat(true, "2", "7"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 13" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "b"), [2, 0]),
      (elimination_rat(true, "2", "7"), [1, 1]),
      (elimination_rat(false, "1", "3"), [0, 2]),
      (elimination_rat(true, "2", "7"), [0, 1]),
      (elimination_rat(false, "1", "b"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "1", "1"), [2, 1]),
      (elimination_rat(false, "1", "7"), [1, 0]),
      (elimination_rat(true, "1", "1"), [0, 1]),
      (elimination_rat(false, "1", "7"), [0, 0]),
    ]),
    1,
    2,
    2,
    elimination_poly(1, [
      (elimination_rat(false, "1", "21"), [6]),
      (elimination_rat(false, "7d", "651"), [4]),
      (elimination_rat(true, "4", "93"), [3]),
      (elimination_rat(false, "140", "12f3"), [2]),
      (elimination_rat(true, "a", "1b9"), [1]),
      (elimination_rat(false, "5c", "12f3"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(true, "40", "651"), [2]),
      (elimination_rat(false, "8", "31"), [1]),
      (elimination_rat(true, "40", "651"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 14" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "2", "3"), [1, 3]),
      (elimination_rat(false, "3", "b"), [1, 2]),
      (elimination_rat(true, "1", "1"), [1, 1]),
      (elimination_rat(false, "1", "b"), [1, 0]),
      (elimination_rat(true, "2", "3"), [0, 3]),
      (elimination_rat(false, "1", "b"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [2, 1]),
      (elimination_rat(true, "2", "3"), [1, 0]),
      (elimination_rat(false, "1", "1"), [0, 1]),
      (elimination_rat(true, "2", "3"), [0, 0]),
    ]),
    1,
    3,
    1,
    elimination_poly(1, [
      (elimination_rat(true, "1", "b"), [7]),
      (elimination_rat(false, "13", "21"), [6]),
      (elimination_rat(false, "3", "b"), [5]),
      (elimination_rat(false, "389", "37b"), [4]),
      (elimination_rat(false, "599", "37b"), [3]),
      (elimination_rat(false, "18d", "129"), [2]),
      (elimination_rat(false, "455", "37b"), [1]),
      (elimination_rat(false, "5f", "37b"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(true, "19c01", "ab93"), [4]),
      (elimination_rat(true, "1a8c4", "ab93"), [3]),
      (elimination_rat(true, "24", "79"), [2]),
      (elimination_rat(true, "30", "79"), [1]),
      (elimination_rat(true, "c", "79"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 15" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [0, 1]),
      (elimination_rat(true, "1", "3"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "7"), [1, 2]),
      (elimination_rat(true, "1", "1"), [1, 0]),
      (elimination_rat(false, "1", "7"), [0, 2]),
      (elimination_rat(true, "1", "1"), [0, 1]),
      (elimination_rat(true, "1", "1"), [0, 0]),
    ]),
    1,
    1,
    2,
    elimination_poly(1, [
      (elimination_rat(true, "3e", "3f"), [1]),
      (elimination_rat(true, "53", "3f"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 16" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "1", "1"), [1, 1]),
      (elimination_rat(false, "1", "b"), [0, 2]),
      (elimination_rat(false, "1", "1"), [0, 1]),
      (elimination_rat(false, "2", "7"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "3", "b"), [2, 1]),
      (elimination_rat(true, "3", "b"), [0, 1]),
      (elimination_rat(true, "1", "3"), [0, 0]),
    ]),
    1,
    2,
    1,
    elimination_poly(1, [
      (elimination_rat(false, "12", "34f"), [4]),
      (elimination_rat(true, "1", "b"), [3]),
      (elimination_rat(true, "29", "34f"), [2]),
      (elimination_rat(true, "1", "b"), [1]),
      (elimination_rat(true, "1c6", "1dc7"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(false, "1", "1"), [2]),
      (elimination_rat(false, "2", "1"), [1]),
      (elimination_rat(false, "45", "4d"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 17" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "2", "b"), [1, 1]),
      (elimination_rat(true, "1", "1"), [0, 3]),
      (elimination_rat(true, "1", "1"), [0, 2]),
      (elimination_rat(true, "2", "b"), [0, 1]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "2", "3"), [2, 0]),
      (elimination_rat(false, "2", "3"), [1, 2]),
      (elimination_rat(true, "3", "b"), [0, 1]),
      (elimination_rat(true, "2", "3"), [0, 0]),
    ]),
    1,
    3,
    2,
    elimination_poly(1, [
      (elimination_rat(true, "548", "cc3"), [6]),
      (elimination_rat(false, "b8", "441"), [5]),
      (elimination_rat(true, "7c", "79"), [4]),
      (elimination_rat(false, "2dd4", "8c61"), [3]),
      (elimination_rat(true, "2534", "2ecb"), [2]),
      (elimination_rat(false, "161c", "8c61"), [1]),
      (elimination_rat(true, "19d8", "8c61"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(true, "20", "533"), [3]),
      (elimination_rat(true, "34", "533"), [2]),
      (elimination_rat(true, "8", "533"), [1]),
      (elimination_rat(false, "c", "533"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 18" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "3", "b"), [1, 0]),
      (elimination_rat(true, "2", "3"), [0, 1]),
      (elimination_rat(false, "3", "b"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "1", "7"), [1, 1]),
      (elimination_rat(false, "1", "7"), [0, 1]),
      (elimination_rat(true, "3", "b"), [0, 0]),
    ]),
    1,
    1,
    1,
    elimination_poly(1, [
      (elimination_rat(true, "3", "4d"), [2]),
      (elimination_rat(true, "6", "4d"), [1]),
      (elimination_rat(false, "1", "7"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 19" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "2", "7"), [1, 1]),
      (elimination_rat(true, "2", "3"), [0, 2]),
      (elimination_rat(true, "1", "b"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "1", "1"), [2, 0]),
      (elimination_rat(true, "2", "3"), [1, 2]),
      (elimination_rat(true, "2", "3"), [0, 2]),
      (elimination_rat(false, "1", "3"), [0, 1]),
      (elimination_rat(true, "1", "1"), [0, 0]),
    ]),
    1,
    2,
    2,
    elimination_poly(1, [
      (elimination_rat(false, "8", "93"), [5]),
      (elimination_rat(false, "dc", "1b9"), [4]),
      (elimination_rat(false, "14", "21b"), [3]),
      (elimination_rat(false, "b5c0", "d071"), [2]),
      (elimination_rat(true, "20", "1dc7"), [1]),
      (elimination_rat(false, "4c6", "cc3"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(false, "4", "31"), [2]),
      (elimination_rat(true, "8", "21"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 20" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(false, "3", "b"), [2, 1]),
      (elimination_rat(true, "2", "7"), [1, 3]),
      (elimination_rat(false, "3", "b"), [1, 2]),
      (elimination_rat(true, "2", "7"), [0, 3]),
      (elimination_rat(false, "3", "b"), [0, 2]),
      (elimination_rat(false, "3", "b"), [0, 1]),
    ]),
    elimination_poly(2, [
      (elimination_rat(false, "2", "b"), [1, 1]),
      (elimination_rat(false, "2", "b"), [0, 1]),
    ]),
    1,
    3,
    1,
    elimination_poly(1, []),
    elimination_poly(1, [
      (elimination_rat(false, "d8", "2465"), [7]),
      (elimination_rat(false, "b7f", "19057"), [6]),
      (elimination_rat(false, "2046", "19057"), [5]),
      (elimination_rat(false, "227d", "19057"), [4]),
      (elimination_rat(false, "24b4", "19057"), [3]),
      (elimination_rat(false, "227d", "19057"), [2]),
      (elimination_rat(false, "db6", "19057"), [1]),
      (elimination_rat(false, "b7f", "19057"), [0]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 21" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "3", "7"), [2, 0]),
      (elimination_rat(false, "1", "7"), [1, 1]),
      (elimination_rat(true, "3", "7"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "1", "1"), [2, 1]),
      (elimination_rat(true, "1", "1"), [0, 2]),
      (elimination_rat(true, "1", "1"), [0, 1]),
    ]),
    1,
    1,
    2,
    elimination_poly(1, [
      (elimination_rat(true, "3", "31"), [5]),
      (elimination_rat(true, "9", "31"), [4]),
      (elimination_rat(true, "6", "31"), [3]),
      (elimination_rat(true, "12", "31"), [2]),
      (elimination_rat(true, "3", "31"), [1]),
      (elimination_rat(true, "9", "31"), [0]),
    ]),
    elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
  )
}

///|
test "elimination independent polynomial coefficient projection 22" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "1", "7"), [2, 0]),
      (elimination_rat(true, "1", "b"), [1, 2]),
      (elimination_rat(false, "1", "1"), [1, 1]),
      (elimination_rat(true, "1", "7"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "1", "3"), [1, 1]),
      (elimination_rat(true, "1", "3"), [0, 1]),
      (elimination_rat(true, "3", "7"), [0, 0]),
    ]),
    1,
    2,
    1,
    elimination_poly(1, [
      (elimination_rat(true, "1", "3f"), [4]),
      (elimination_rat(true, "2", "3f"), [3]),
      (elimination_rat(true, "b", "3f"), [2]),
      (elimination_rat(true, "3a0", "12f3"), [1]),
      (elimination_rat(true, "1", "3f"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(true, "4", "4d"), [3]),
      (elimination_rat(false, "1", "1"), [2]),
      (elimination_rat(true, "4", "4d"), [1]),
    ]),
  )
}

///|
test "elimination independent polynomial coefficient projection 23" {
  elimination_projection_fixture(
    elimination_poly(2, [
      (elimination_rat(true, "1", "b"), [1, 1]),
      (elimination_rat(true, "1", "1"), [1, 0]),
      (elimination_rat(true, "1", "3"), [0, 3]),
      (elimination_rat(false, "2", "3"), [0, 2]),
      (elimination_rat(true, "1", "1"), [0, 0]),
    ]),
    elimination_poly(2, [
      (elimination_rat(true, "3", "7"), [1, 2]),
      (elimination_rat(false, "1", "3"), [1, 1]),
      (elimination_rat(true, "2", "b"), [1, 0]),
      (elimination_rat(false, "1", "3"), [0, 1]),
      (elimination_rat(true, "2", "b"), [0, 0]),
    ]),
    1,
    3,
    2,
    elimination_poly(1, [
      (elimination_rat(true, "96cc", "6f755"), [5]),
      (elimination_rat(true, "5dc3d1", "23441e5"), [4]),
      (elimination_rat(true, "29e54", "334bcf"), [3]),
      (elimination_rat(false, "14984", "1ade91"), [2]),
      (elimination_rat(false, "2da", "1a523"), [1]),
      (elimination_rat(true, "473", "1a523"), [0]),
    ]),
    elimination_poly(1, [
      (elimination_rat(true, "4", "f99"), [3]),
      (elimination_rat(true, "e4b", "441"), [2]),
      (elimination_rat(true, "602", "129"), [1]),
      (elimination_rat(true, "31", "1b"), [0]),
    ]),
  )
}
