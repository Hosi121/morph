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
