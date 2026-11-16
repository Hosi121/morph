// Independent Fraction permutation/Gaussian determinant oracle.

///|
test "Bareiss independent Fraction determinant 0" {
  bareiss_fixture(bareiss_matrix([]), bareiss_rat(false, "1", "1"), true)
}

///|
test "Bareiss independent Fraction determinant 1" {
  bareiss_fixture(
    bareiss_matrix([[bareiss_rat(false, "0", "1")]]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 2" {
  bareiss_fixture(
    bareiss_matrix([[bareiss_rat(true, "7", "d")]]),
    bareiss_rat(true, "7", "d"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 3" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 4" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 5" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 6" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 7" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 8" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 9" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 10" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 11" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 12" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 13" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 14" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 15" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 16" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 17" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 18" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 19" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 20" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 21" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 22" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 23" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 24" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 25" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 26" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 27" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 28" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 29" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 30" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 31" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 32" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 33" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 34" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 35" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 36" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 37" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 38" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 39" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 40" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 41" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 42" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 43" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 44" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 45" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 46" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 47" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 48" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 49" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 50" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 51" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 52" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 53" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 54" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 55" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 56" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 57" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 58" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 59" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 60" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 61" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 62" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 63" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 64" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 65" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 66" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 67" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 68" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 69" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 70" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 71" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 72" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 73" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 74" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 75" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 76" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 77" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(true, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 78" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 79" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 80" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "0", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 81" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(true, "1", "1")],
    ]),
    bareiss_rat(true, "2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 82" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "0", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 83" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
      [bareiss_rat(false, "1", "1"), bareiss_rat(false, "1", "1")],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 84" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "1", "3"),
      ],
    ]),
    bareiss_rat(false, "145", "bd"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 85" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "4", "7"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "1", "7"),
      ],
    ]),
    bareiss_rat(true, "74", "157"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 86" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "2", "1"),
      ],
    ]),
    bareiss_rat(true, "38c", "93"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 87" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "1"),
      ],
      [
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "1", "7"),
      ],
    ]),
    bareiss_rat(false, "12fe", "1b9"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 88" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "2", "3"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "1", "1"),
      ],
    ]),
    bareiss_rat(false, "190", "3f"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 89" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "7"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "5", "7"),
      ],
      [
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "1", "3"),
      ],
    ]),
    bareiss_rat(false, "aa", "c0f"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 90" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "2", "7"),
      ],
    ]),
    bareiss_rat(false, "193", "31"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 91" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "5", "3"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "4", "1"),
      ],
    ]),
    bareiss_rat(false, "4c1", "15"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 92" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "7"),
      ],
      [
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "2", "3"),
      ],
    ]),
    bareiss_rat(false, "10a6", "1c23"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 93" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "5", "7"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "1", "7"),
      ],
      [
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "4", "7"),
      ],
    ]),
    bareiss_rat(true, "bcf8", "1c23"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 94" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "5", "7"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "2", "3"),
      ],
    ]),
    bareiss_rat(true, "121a8", "c0f"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 95" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "7"),
      ],
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "3"),
      ],
      [
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "1", "1"),
      ],
    ]),
    bareiss_rat(true, "401", "52b"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 96" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "3"),
      ],
      [
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "3", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "1", "3"),
      ],
    ]),
    bareiss_rat(true, "3cd10", "52b"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 97" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "4", "7"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(true, "4", "7"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "5", "3"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "1"),
      ],
    ]),
    bareiss_rat(true, "99a", "157"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 98" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(true, "182", "1"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 99" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "4", "1"),
      ],
    ]),
    bareiss_rat(true, "3b44", "242d"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 100" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "7"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "1", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "7"),
      ],
    ]),
    bareiss_rat(true, "a2f34", "961"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 101" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "4", "3"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "1", "3"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "3"),
      ],
    ]),
    bareiss_rat(false, "1d10fb", "6c87"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 102" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "2", "1"),
      ],
    ]),
    bareiss_rat(true, "c508fa", "2f7b1"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 103" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "3", "7"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "7"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "3"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "4", "7"),
      ],
      [
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(false, "4b650", "5469"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 104" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "3"),
      ],
      [
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "2", "3"),
      ],
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "4", "1"),
      ],
    ]),
    bareiss_rat(false, "4a5fa", "6c87"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 105" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "3", "7"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "7"),
      ],
      [
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "5", "7"),
      ],
      [
        bareiss_rat(false, "2", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "2", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "2", "1"),
      ],
    ]),
    bareiss_rat(true, "50dee", "6c87"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 106" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "3", "7"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "7"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "4", "7"),
      ],
    ]),
    bareiss_rat(false, "30c0d", "1c23"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 107" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "7"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "4", "7"),
      ],
      [
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
      ],
    ]),
    bareiss_rat(true, "29aac5fd", "6ec9d"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 108" {
  bareiss_fixture(
    bareiss_matrix([
      [bareiss_rat(false, "2", "1"), bareiss_rat(false, "3", "1")],
      [bareiss_rat(false, "5", "1"), bareiss_rat(false, "7", "1")],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 109" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
      ],
    ]),
    bareiss_rat(true, "1", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 110" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
      ],
    ]),
    bareiss_rat(false, "d92", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 111" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "6", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "6", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "2", "1"),
      ],
    ]),
    bareiss_rat(true, "102cf", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 112" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "6", "1"),
      ],
    ]),
    bareiss_rat(false, "1b4b8", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 113" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "4", "1"),
      ],
    ]),
    bareiss_rat(false, "140a45", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 114" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(true, "e78e40", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 115" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(false, "8bc3f2", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 116" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "7", "2"),
        bareiss_rat(true, "6", "5"),
      ],
      [
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "1", "5"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(true, "6", "5"),
      ],
      [
        bareiss_rat(false, "1", "2"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "1", "5"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "2"),
        bareiss_rat(true, "1", "3"),
      ],
      [
        bareiss_rat(true, "1", "2"),
        bareiss_rat(true, "6", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "2"),
      ],
      [
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(true, "3", "5"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "4", "5"),
      ],
    ]),
    bareiss_rat(true, "19bdf2d", "c9dfb0"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 117" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "5", "7"),
      ],
      [
        bareiss_rat(false, "4", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "2"),
        bareiss_rat(false, "7", "5"),
        bareiss_rat(true, "1", "2"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "2", "3"),
      ],
      [
        bareiss_rat(true, "3", "2"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "7", "2"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "7", "3"),
      ],
      [
        bareiss_rat(false, "3", "5"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "3"),
      ],
    ]),
    bareiss_rat(true, "79fde", "278d"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 118" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "3"),
      ],
      [
        bareiss_rat(true, "5", "2"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "2"),
      ],
      [
        bareiss_rat(false, "3", "2"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(true, "6", "7"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "5"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "3", "2"),
      ],
      [
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "2", "7"),
      ],
    ]),
    bareiss_rat(true, "19ede07", "6de8b8"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 119" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(false, "2", "5"),
        bareiss_rat(true, "3", "5"),
      ],
      [
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "4", "7"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "3", "5"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "2"),
      ],
      [
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "7", "5"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "1", "3"),
      ],
      [
        bareiss_rat(false, "1", "2"),
        bareiss_rat(false, "2", "5"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "7", "5"),
      ],
      [
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(false, "7", "3"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "3", "2"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(false, "1", "2"),
      ],
    ]),
    bareiss_rat(false, "217739c43b09", "d0029dcd76"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 120" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(false, "3", "2"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "6", "5"),
      ],
      [
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "4", "5"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "4", "5"),
      ],
      [
        bareiss_rat(true, "3", "2"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "1", "2"),
      ],
      [
        bareiss_rat(true, "3", "5"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "3", "2"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "5"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
    ]),
    bareiss_rat(false, "616b359b15bd", "edb9d8ead0"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 121" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "6", "7"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "6", "7"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "7", "2"),
      ],
      [
        bareiss_rat(false, "1", "3"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "1", "5"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "7", "5"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "1", "2"),
      ],
      [
        bareiss_rat(true, "3", "5"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "7", "5"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(true, "1", "5"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(true, "1", "1"),
      ],
    ]),
    bareiss_rat(false, "87e6abbc51ed0", "191299e0c3f"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 122" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "5", "1"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 123" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 124" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 125" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "5", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "5", "1"),
      ],
      [
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "4", "1"),
      ],
    ]),
    bareiss_rat(false, "fe811", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 126" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "2", "1"),
      ],
      [
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(true, "82a780", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 127" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(true, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "1"),
      ],
      [
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "4", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
      ],
      [
        bareiss_rat(true, "2", "1"),
        bareiss_rat(true, "7", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "3", "1"),
      ],
      [
        bareiss_rat(true, "4", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "6", "1"),
      ],
      [
        bareiss_rat(false, "3", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
      ],
      [
        bareiss_rat(false, "6", "1"),
        bareiss_rat(false, "5", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "7", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "6", "1"),
        bareiss_rat(false, "3", "1"),
      ],
    ]),
    bareiss_rat(false, "84e51a", "1"),
    true,
  )
}

///|
test "Bareiss independent Fraction determinant 128" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(false, "1", "3"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(false, "2", "5"),
        bareiss_rat(true, "3", "5"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "4", "7"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "5"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "5"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "2"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "7", "5"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "1", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "5"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "7", "5"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(false, "3", "2"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(false, "1", "7"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(false, "1", "2"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 129" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(false, "3", "2"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(true, "6", "5"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "2"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "4", "5"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "4", "5"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "7"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "5"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "1", "2"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "3", "2"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "2", "3"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "4", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "6", "5"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "6", "7"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "6", "5"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 130" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(true, "4", "5"),
        bareiss_rat(true, "4", "7"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(true, "6", "7"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "3", "2"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(false, "3", "7"),
        bareiss_rat(true, "2", "7"),
        bareiss_rat(false, "7", "2"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(true, "3", "7"),
        bareiss_rat(true, "1", "5"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(true, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "3", "1"),
        bareiss_rat(true, "1", "7"),
        bareiss_rat(false, "5", "7"),
        bareiss_rat(true, "2", "3"),
        bareiss_rat(false, "2", "7"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "5", "2"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "2", "5"),
        bareiss_rat(false, "1", "2"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "4", "3"),
        bareiss_rat(false, "2", "1"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "5"),
        bareiss_rat(false, "5", "2"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "7", "3"),
        bareiss_rat(false, "4", "7"),
        bareiss_rat(true, "1", "3"),
        bareiss_rat(false, "7", "5"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "2", "1"),
        bareiss_rat(false, "4", "3"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(true, "3", "1"),
        bareiss_rat(false, "5", "3"),
        bareiss_rat(true, "5", "3"),
        bareiss_rat(true, "1", "1"),
        bareiss_rat(false, "3", "5"),
        bareiss_rat(true, "7", "3"),
        bareiss_rat(true, "1", "1"),
      ],
    ]),
    bareiss_rat(false, "0", "1"),
    false,
  )
}

///|
test "Bareiss independent Fraction determinant 131" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
      ],
      [
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "1", "1"),
      ],
      [
        bareiss_rat(false, "1", "1"),
        bareiss_rat(false, "0", "1"),
        bareiss_rat(false, "0", "1"),
      ],
    ]),
    bareiss_rat(false, "1", "1"),
    true,
  )
}

///|
test "Bareiss wide 4x4 128bit integer" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(true, "a17297bf0f5039279e4fef6fe87ab388", "1"),
        bareiss_rat(true, "929dd9b27e40621439dbd3da349a68ca", "1"),
        bareiss_rat(true, "fdc6192712873f7d9198e3fea2c9f15d", "1"),
        bareiss_rat(true, "d92a1a5b39434c54bac72a039a5eaecf", "1"),
      ],
      [
        bareiss_rat(false, "e45953907279ad2c8bd571245c21b477", "1"),
        bareiss_rat(true, "cc91dad9d1efe4bbfd34eafa8428efaf", "1"),
        bareiss_rat(false, "c31c4a620c7187ca4feaa45acf5ca1a5", "1"),
        bareiss_rat(true, "e17af6175e0c6bbdddfc013aa245e9ab", "1"),
      ],
      [
        bareiss_rat(true, "a4890b2a2689f6cd9ca5cfccdbb10938", "1"),
        bareiss_rat(true, "ae846b5b2be5a2e11bee155387ae993e", "1"),
        bareiss_rat(false, "e854dfa6120a7b96cb6350d40f168f61", "1"),
        bareiss_rat(false, "ab2059c4ed92afde2db372275494327f", "1"),
      ],
      [
        bareiss_rat(false, "dfe60f94f40ae0abf8555c27bdfb1149", "1"),
        bareiss_rat(false, "a5e379f4ca4cfcd0db8b30f6ebd325d0", "1"),
        bareiss_rat(false, "91203dc50b3b35f59e9b0fc204e95376", "1"),
        bareiss_rat(true, "b84fcd242b1f08d357cb2a697bae2812", "1"),
      ],
    ]),
    bareiss_rat(
      true, "220a98f7ee6c3478ec9a14682eaeb6399c74d623c8df9a168b81f00ea80db2f9852eba621bd3d474811fbbf1fb263a24656df0943ef41800e622c0971739ea5bc",
      "1",
    ),
    true,
  )
}

///|
test "Bareiss wide 4x4 256bit integer" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(
          false, "f75a0e2e93483162a170f8d876ec8de70a52ae7b8ce9cb4b6b835ab316aab0b2",
          "1",
        ),
        bareiss_rat(
          false, "e4efdccd13b459ad96eedcf198521f8832510afa9c36b4e50f90d5255d1e4a0f",
          "1",
        ),
        bareiss_rat(
          false, "b28141eb2dd2f6a9d00ee2175a762026cd6f191a90f0efd9873c26f73bc08d2d",
          "1",
        ),
        bareiss_rat(
          true, "da9169a73e6cc53317f177f6886124a79ad170638e777309ce288c72acd5ba40",
          "1",
        ),
      ],
      [
        bareiss_rat(
          false, "83458c0c9709a6868b99d850559ba53ba1976e71693be3eee935c4c971f2e411",
          "1",
        ),
        bareiss_rat(
          true, "bc1f315f9ffe09361fd54a7874f31053c02c39557ecf2fa265cde9d69c89696c",
          "1",
        ),
        bareiss_rat(
          false, "d5524b30ad5c7177d91e7fabaddac609b0a242382ef8b5cb5c6e9b7070893c47",
          "1",
        ),
        bareiss_rat(
          true, "e259ee2115e0cbb39e00d8ff0d7c7b527bf91980f493a825d0509254ddd6512d",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "c7c1d9ccce3bd759b2798accd189774c26bf7de977b4b14757a986f7644e2eed",
          "1",
        ),
        bareiss_rat(
          true, "96de756fada2ed4f8f704c2ef1bd4a9a66fc8cc06209f6c8f028c690f5c7fa19",
          "1",
        ),
        bareiss_rat(
          false, "aabd73c0c65d60dd31d081b10388d2c34e3c4c74a21e6977eab93441a4650c54",
          "1",
        ),
        bareiss_rat(
          true, "d25a90ee657a2586688aee96d6487a26a7560ad1539e15edd738e6340e9a0e39",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "df5b021ede491a080970302bbbb61d924207bf6e12232dfda1c4a579f51641d7",
          "1",
        ),
        bareiss_rat(
          true, "d2b8bb064d174a2c925d6f6ccc95f4839fcfe05d8f16317bc891198cfb412822",
          "1",
        ),
        bareiss_rat(
          false, "a586819950eefd875bc07c1df8ff1dbbf2315c8a4762a7f791f6fa2e170827b8",
          "1",
        ),
        bareiss_rat(
          false, "a00300e798be42432c355c4bff48a9a6f3edb099b88ec1ace42d18ab34ecf5da",
          "1",
        ),
      ],
    ]),
    bareiss_rat(
      true, "21a7b1eb6d7766e1c3499057f481f0b3d72f63a2a9d6262f37ccb3fdf01f17f7f198f5abf1ea5fb85f063e8cb1b5162ee7484315f798a54ce6e5bb84d6c28a26825ff7f1f5073ca60bdb42d9b368c898ad726492faee3e01baf13c98b41e44e2c841d3a4336201a49482616a7c5ef85db4d4eb96e2eaabbddf1cd2c56742dc730",
      "1",
    ),
    true,
  )
}

///|
test "Bareiss wide 6x6 128bit integer" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(false, "897ed8e5e347b5d032d372efca0d3f7b", "1"),
        bareiss_rat(true, "e1b184e592754e08f829b6e0f1d484aa", "1"),
        bareiss_rat(false, "863dc89a1b041730de977c0829d2ca28", "1"),
        bareiss_rat(true, "95210245d91d16504a08c5c00d29bf57", "1"),
        bareiss_rat(true, "93edfbb02ffa1689cabf5755d1b255af", "1"),
        bareiss_rat(false, "81ba515ddcb1bad61d342a3a8551882c", "1"),
      ],
      [
        bareiss_rat(false, "b868943f61afbb97c8ae7f941d4f6058", "1"),
        bareiss_rat(false, "e1d40574adf14297b22c38a2a31cfed1", "1"),
        bareiss_rat(true, "8ca120c0911c04fe57431cbee43a64cb", "1"),
        bareiss_rat(false, "e572979d7fa8d28ac38e4d34f3442ab7", "1"),
        bareiss_rat(false, "bb5345030e27d2ada6ac8f0ae63f1fd7", "1"),
        bareiss_rat(true, "cec932fabedc952bfda16f1048287540", "1"),
      ],
      [
        bareiss_rat(true, "c4715e190e90be5c9dea04c95792d05b", "1"),
        bareiss_rat(false, "b670dc93f255a5d82252928438425603", "1"),
        bareiss_rat(false, "91c133196c48bace146b096fa6466517", "1"),
        bareiss_rat(true, "96b4d94ac71e6587f217e404691fed89", "1"),
        bareiss_rat(true, "ac399917d9bf727e1ee617d5b37bd797", "1"),
        bareiss_rat(true, "e2d9672f280263d2f916a3213070f0fe", "1"),
      ],
      [
        bareiss_rat(false, "f1f90bc11e395afdc2f2e9be68078af4", "1"),
        bareiss_rat(true, "f5debed1dc39e44f194599a4b57704f2", "1"),
        bareiss_rat(true, "b901924ea772ad3e589774188596fc24", "1"),
        bareiss_rat(false, "cd249cbe1b7db65d896976e85ecf55d6", "1"),
        bareiss_rat(true, "ca8df3c26c24d86a665639a065c1dfb8", "1"),
        bareiss_rat(true, "93a5d99207c44c816d9283ca55a3682f", "1"),
      ],
      [
        bareiss_rat(true, "eb39a68bcd0409dc4959820b64a23a30", "1"),
        bareiss_rat(false, "aaa3e814e4cc84418dbf0c7c01928b48", "1"),
        bareiss_rat(true, "ae890b2e1f7e47790dd1af6e650f75bb", "1"),
        bareiss_rat(true, "8f95fc888d168076aa45db07cb8159a2", "1"),
        bareiss_rat(true, "d5338dd81b9f635df942df9af92ea2e0", "1"),
        bareiss_rat(true, "94549ab3aa2ca15ef2cba09a71e50d6d", "1"),
      ],
      [
        bareiss_rat(true, "8c93144bab952f9fd877a538c2128ca9", "1"),
        bareiss_rat(false, "e97da1720cf0f243f8591a7da47dcb17", "1"),
        bareiss_rat(false, "d3959a0a18d336b11d9c92651e29c013", "1"),
        bareiss_rat(false, "fe4e986fd3ff6139357a7b93b938fd32", "1"),
        bareiss_rat(true, "e23e5a65e2aa43929c51c569de4c2679", "1"),
        bareiss_rat(true, "cbe2ba1a4754594775cb1094ec7674bc", "1"),
      ],
    ]),
    bareiss_rat(
      true, "4ace643b7805d16be33dbc19a48ea5f3250df4a23bb41e3d8cd532fd104b160d1ff2fb7fa35ca450f3030ffb16cf1f24079f8732b8a6e03140738aa8085c40325e33b0d71398d8a572c9305774b8bc2d6e32ba3dbe74cc06038fc06ec2b8f0205",
      "1",
    ),
    true,
  )
}

///|
test "Bareiss wide 6x6 256bit integer" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(
          false, "92855e2ad23c2a33585caea644593fdf826ed08ee95a6e1276ab20ccc707c85d",
          "1",
        ),
        bareiss_rat(
          false, "dc861206b7c078ed3dc6112781e8ce7e82c11e54ccab4dc44b637894e51fd1a0",
          "1",
        ),
        bareiss_rat(
          false, "ec7d173f4df3bf8dd3241d3a1d26553a2790a6dd8e06855c3a96946eb1385dfb",
          "1",
        ),
        bareiss_rat(
          true, "fd58f9c7cd7135051eada4e877eac5dc2471c10b1ca77830333efaa1e5d70df8",
          "1",
        ),
        bareiss_rat(
          true, "b233d6e4f6a4ab8dc66300eb57d50f94e7ad6d2825c09c60ce514758c5a5b981",
          "1",
        ),
        bareiss_rat(
          false, "c91f3e5ad353148f0f3e1f82ecb4535a2e47556561c9ad3c05346eab2bfe5426",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "d30afe1fc6a1b2537ca029fff8cd4b34d6827a8020083b0bb770f58af0649479",
          "1",
        ),
        bareiss_rat(
          true, "b0da38a91e03b9cef1ac6d3e59e963cc86652c14b6d0a6a193fc1b639e392ce9",
          "1",
        ),
        bareiss_rat(
          false, "a1decadf0f918dbd4bb8505a07a225c14d381ebc775a1839937c1d909776afb3",
          "1",
        ),
        bareiss_rat(
          true, "d66c0ef27a116a6875c6aaa40bdfca7d496f429dec2de732dad36aa1bbea738c",
          "1",
        ),
        bareiss_rat(
          false, "90a6fc7b017598e778fea8ae90c3aaeedc8f3c4e81c568bb4ae25fd35bffa020",
          "1",
        ),
        bareiss_rat(
          true, "822546277ac791df73379e2d5e1deaf13f0ec94eafedf6b08ad30ce5d3a32cee",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "f8ee1e089d7af12d93a57e68bc3f0f76a29a5ef9202a9c77b81808406f2f1d4d",
          "1",
        ),
        bareiss_rat(
          true, "ac33c19eb6c6d041f20c42ddc00d59217083ae1f461520f4902ba7af3469b7b0",
          "1",
        ),
        bareiss_rat(
          false, "8ee2f40276de6eb10062cf42c987a4b383e0c374fb2e04446e8419bf0a9f2062",
          "1",
        ),
        bareiss_rat(
          true, "d3d876b5087c0ddf709b82c8f5fd50042b37fd013c42ae3790607865cbee03cf",
          "1",
        ),
        bareiss_rat(
          false, "c8f3ada43ee9ac857296b9ae1306e959d53ef10ba7c3eee4ccfabc83d599b5a9",
          "1",
        ),
        bareiss_rat(
          true, "e83e3b063957faab857375846328da8ccfdcd845350d805654c8741faa01b246",
          "1",
        ),
      ],
      [
        bareiss_rat(
          false, "cb2f54672cc8c69a5e7710ab36cb6c8dd7ac59a6814aa9a2cdaf8e1ae2a1ef57",
          "1",
        ),
        bareiss_rat(
          true, "e3f59479a12ac028864fcd4b2ea939ae18cfa4f676e9af062d0644ac80ebeb0c",
          "1",
        ),
        bareiss_rat(
          false, "98f6c34358165e6acfba31f34984e274113827e7402ddfbe4c0a0a6023769ff2",
          "1",
        ),
        bareiss_rat(
          true, "c81c73ea6c1fa3ab4f95fee0df1f2b6d04a11a3650d7879ae6d85209588ed5be",
          "1",
        ),
        bareiss_rat(
          false, "ec50078118904e3ee96ae7b1370163df37b904a6ec83c520d7afa2bccb37a852",
          "1",
        ),
        bareiss_rat(
          true, "8247cdbb80601c8a18fb2fa10c3b301c63415525cc7181375b10d1fce438dcf2",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "8838ce5a4dc9d87610ba4a0d7bb55de06c0cc6793e245e687a2dedbe53536b90",
          "1",
        ),
        bareiss_rat(
          true, "cb6fa38951d264205e2803df11c3e7dffa69631d8b523a7cca801ba1a0047fbe",
          "1",
        ),
        bareiss_rat(
          true, "d0d34ed82b348e442adf884180f31c3487be9f5175e307bedced7d07600ebb9a",
          "1",
        ),
        bareiss_rat(
          true, "cde0eafd07a08d2dff9a951cc53a9c4111baf150556a38093f0b0ce8943c2000",
          "1",
        ),
        bareiss_rat(
          true, "c2658c9cd1c10cb23650cea17ddeec4e4d65932b6880730a983d4fcf383aab29",
          "1",
        ),
        bareiss_rat(
          true, "d3a2820a566419daa4ce3df19820d98cb1672bc45c539d8befad6ab77c0233ce",
          "1",
        ),
      ],
      [
        bareiss_rat(
          true, "c3e41ed6965af20e1a31671e98e4a94626df00ca38f6f4d45b231f454947ece6",
          "1",
        ),
        bareiss_rat(
          true, "ceeefc633a87a53d67b44787cac8a7cb1499ece5e1dbc2af49060a71dd508785",
          "1",
        ),
        bareiss_rat(
          true, "de92b861c66a6f52292deb51d80019150eccd35f7a024e2d2660a1a39be0fb67",
          "1",
        ),
        bareiss_rat(
          true, "86cb7252ed04bcdde856fd89f091b55f51db0015bca4ed607727dcbed632ede0",
          "1",
        ),
        bareiss_rat(
          false, "b2b6eb7115c3bc6189f313984254820ada08788ec47635f12967cec915146443",
          "1",
        ),
        bareiss_rat(
          false, "901f1ffd09127330ec6c788ab95c02bbd6407f1e0e408b08e9d7eb49bd2d9017",
          "1",
        ),
      ],
    ]),
    bareiss_rat(
      true, "35f1f64468c3d66c2271a464e75911b553b0ea84c733980e4257b24af88dfa9a9129410696a4bc4e522349d9a7e801af69686fd464adde920da007ffbd3166bee40fdbe9b3a616bc5dcc88e4225fb5e9c8de52eba038ec2d68035d8ee5603ae5329d80fff6cd4cf14929f8335620cbadf5737ce43c3c3238133250031094e95f7d54c0075626559c0b3fbfb0f63956582726cd249c3508baaf98a21a85db36360a786f8967e83551fe40b753edf8b450ea880dde6e3093752fe45a8c7e1d1f5c7",
      "1",
    ),
    true,
  )
}

///|
test "Bareiss wide 4x4 128bit rational" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(
          false, "4e4d03913b3728a1bd65ee0f4d844b7d", "7fffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "e96da21f924e8316603cdec4df087c59", "37fffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "2e52ef0dafca86d6f847d821b3f95fc2", "7fffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          false, "4f34b6f2e59ab47d66e18de46257f9f0", "7fffffffffffffffffffffffffffffed",
        ),
      ],
      [
        bareiss_rat(
          true, "21420009e00d7aad74ee8acfca2fc090", "7fffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "8c6d93d7913696d8edcb9d513d8b946c", "37fffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "e3778d58dddd31004878854f30848710", "27fffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          false, "13b463321b38892b48ea1a35fabf6951", "7fffffffffffffffffffffffffffffed",
        ),
      ],
      [
        bareiss_rat(
          false, "b7486dbbd8abacb41d4cfac4197ee733", "37fffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "3f9a745d25901eecf600ece13c40d11d", "7fffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "323404373cbd51663310de384f14c13a", "7fffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "f556aa340e32578a78001edc5630d178", "17fffffffffffffffffffffffffffffc7",
        ),
      ],
      [
        bareiss_rat(
          true, "cd9c406131de003e456c11996bed6f17", "37fffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "d2fcfbd4220c33f1b31431bdaf58fb58", "27fffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "c2de67b1ba5ccdb35a71e1adbb40908f", "27fffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "cab5e72155bdd43b068a12418937f2b9", "17fffffffffffffffffffffffffffffc7",
        ),
      ],
    ]),
    bareiss_rat(
      false, "80d7cb59636b4e77608bd2873fd87d70c9cb18fff1c2bf07879b55b071dade97c30098a61c9f7a4484d1a657fca4dcba49ff3f68c74f570b7c9a90dab8119efee",
      "e5afffffffffffffffffffffffffff779f800000000000000000000000001e5d7c7ffffffffffffffffffffffffcfebfae0000000000000000000000001c8be30b",
    ),
    false,
  )
}

///|
test "Bareiss wide 6x6 256bit rational" {
  bareiss_fixture(
    bareiss_matrix([
      [
        bareiss_rat(
          false, "dbb781eba7cc30dc0bd46d270b3bcf64b08d0f3891faf1bb3bd2989fe95422ae",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "968e7c3923ec5790cce81e49c5335659577cd97648e6118264a895bb05eddadc",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "2b83da59310dbad0a5ff53cec1ebe4cd10191d2f54bfbd952e91c9098bfe2b5f",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          false, "9c0f96d3f987ded6cc5452ddedd58800d29cf21cdea3e42d9ae1f41ff715c63d",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "db8bad225aa40ee17e0b384e1ea961045c03898f265076e6bda118b157971b37",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "2c583a8d5f54886d74769047493cce67900b86f4f5aa8c6bf7f786c92bc845ff",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
      ],
      [
        bareiss_rat(
          false, "39c8800c90338334309d6775733416cd75a55b6936d2dd95f3572dc66f78febc",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          false, "d937ffeeaa731e1868fe70662296d826835661d32e8d7c5bbe2a07320dba020e",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "8b4df7afa1207a05da4af332c07c11f7e0998c6ea772a72cb4a7714cdae91eb7",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "3e8e84424cf23ee809f0b19145ab660dcb483e25df4de420a04b4c8c5e66405d",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          false, "4e654f89b8d9677568a2e154c366d143971d51f9d467c588ccde5403f8d89955",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "fac31d894044e1d468ccc1d27b1c90accde9c7a0ef8c79908d71f6cef64d3cc1",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
      ],
      [
        bareiss_rat(
          true, "fe40b0f04d9f58edd11b10d6b26298ce1654c25c906f8ee4dd592c203025c71d",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          true, "f46315cb95ae0a7c273900aee19ab96c5a732734e46e6ffe97d97d6155ea9107",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "ddc4a20a84693e40aab8c1d7f5bfcfc73115e96638a2f3ea9a0493ae588fb068",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "904604e051bf2592fca2714e251b017a08e3fa0b3ddabb16781d62cfcd5e0717",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          false, "bf69f197e98b6453dd7284e6b99075ef1c71bb2da12f9255c490f98b65864247",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "d302d590c6a11b544e1378a4282feccfebf4414210d3cd5bfc0c17ce8da7b780",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
      ],
      [
        bareiss_rat(
          false, "a6d3535960899bb86aaa900c6516eafd8e175eca139ab276c2e79cf63922020f",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "f585547229295f566df6b02b7d229bdeee9b0f76f6ae7ff14d29eb806735665f",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "9ea4658d46841e290a64d83e88d6216b02914db0eca92c29594f41af0b74e252",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "1defc9c8dbd6fc4d1a5995f6d68eac21d91ce6ceba2c8162deb7578cd97ca54d",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "507c1cc481fccd1326b5eada9dea87ab827b2c9476cec50082a3710307997f81",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
        bareiss_rat(
          true, "c33551156a09d4bb33f2bbfd638f71f0ed6392486bbdf6276f3d5f858d9e8fa7",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
      ],
      [
        bareiss_rat(
          true, "b73f835d8b35ccd0602b8c0140e5c95ac4937882df4585bef53c3f798306f1c7",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          false, "bcf66ce2f90000e2b2c0eabb6c5304d74e60d9c975793b90e9f484326fa3072f",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "fae27d83098cde321af94bb9c3ae6c483f37258336ff3548fc7e9b46bef0297b",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
        bareiss_rat(
          true, "898e192817d6ac05549b106d26fd6cc7596e54986b2808fcef36fc8dba80d4f3",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "b824ea764ca9f7c9d98a95868d44dbc5524fdd00e5fbb02bc90d8ea6a6307bb4",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "477d2d806d41049249bee68543c0cdff4f6cf20551842b9fdd6115c5737b2b19",
          "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed",
        ),
      ],
      [
        bareiss_rat(
          false, "f80476adfdf602a41c36e2ea235b7e392c02975a13a7948f6fb3fc75d2ad993d",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "d1af27159576b433df3b1bab7927e12a07c2db6f952745e75b30739bc17ee208",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "ef290974210e965ca8e186d39aa491906eb6f44b544178ec07fe3f911d102e2d",
          "37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7b",
        ),
        bareiss_rat(
          true, "b3e89dc010e0e2d8c5086147f6a2d10968f9b761e89193664d56b8b4b2253d28",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          false, "f88a5f2935740b488c0418a55666046779273f7efd75661d879b9b18ebc38934",
          "17fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7",
        ),
        bareiss_rat(
          true, "df22441b0ed5fe2b9e2547e8ab3966cd638b8e0904f15822394f0b07666a7131",
          "27fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1",
        ),
      ],
    ]),
    bareiss_rat(
      false, "1d03542b6d8f39b23760ba257019cdbbfcff433c268d5bd08c031951e91c15ade1b176dc86e643df16f9a2d6ad6dc2da33ba4632ea73dac0b56c3dd9bd4098c77698f2ca04a458693bc1445088bb79dba63e8ae161ce9bf224c5943e5d30719903d4fa2a8c459cb3fb1d97a8641eda2b510a2c79a4413bfecc13cf51934ad4ad674ec564cde4c90e188cc77ffaed43d534079818102f807fe34ceda8f39f9427d3f1739b0d746771be35f7956f4843a2a9efd2b28d4bde6bfdd24496be0223566c8c2",
      "cadc079bffffffffffffffffffffffffffffffffffffffffffffffffffffff4b540939100000000000000000000000000000000000000000000000000000430bd093d30ffffffffffffffffffffffffffffffffffffffffffffffffffff2bafeb8138f80000000000000000000000000000000000000000000000000017a2ea481d2863fffffffffffffffffffffffffffffffffffffffffffffffffe98ba16eb119a1000000000000000000000000000000000000000000000000008e3656ed9e5daf",
    ),
    false,
  )
}
