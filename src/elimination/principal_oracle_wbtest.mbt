// Independent Fraction permutations and Euclidean/SymPy gcd oracles.

///|
test "principal independent Fraction matrix and gcd 0" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "0", "1")]),
    @oracle.chain([elimination_rat(false, "0", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 1" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "2", "3")]),
    @oracle.chain([elimination_rat(true, "7", "b")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 2" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "0", "1")]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "3", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "0", "1")]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 3" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "3", "1")]),
    @oracle.chain([elimination_rat(false, "3", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 4" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(1)),
  )
}

///|
test "principal independent Fraction matrix and gcd 5" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "3", "1"),
      elimination_rat(false, "4", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 6" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "3", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 7" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "3", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 8" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "5", "7")]),
    @oracle.chain([elimination_rat(true, "5", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 9" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "5", "3")]),
    @oracle.chain([elimination_rat(true, "4", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 10" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "5", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 11" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "4", "3")]),
    @oracle.chain([elimination_rat(true, "3", "b")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 12" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "2", "7")]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "4", "1"),
    ]),
    @oracle.chain([elimination_rat(true, "2", "7")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 13" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "2", "7")]),
    @oracle.chain([
      elimination_rat(false, "2", "5"),
      elimination_rat(false, "5", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "2", "7")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 14" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "4", "3")]),
    @oracle.chain([
      elimination_rat(true, "4", "1"),
      elimination_rat(true, "3", "1"),
    ]),
    @oracle.chain([elimination_rat(true, "4", "3")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 15" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "5", "1")]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "5", "1")]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 16" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "1", "1")]),
    @oracle.chain([
      elimination_rat(true, "4", "5"),
      elimination_rat(true, "5", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 17" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "4", "1")]),
    @oracle.chain([
      elimination_rat(true, "4", "5"),
      elimination_rat(true, "5", "b"),
      elimination_rat(true, "3", "5"),
    ]),
    @oracle.chain([elimination_rat(false, "10", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 18" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "2", "7")]),
    @oracle.chain([
      elimination_rat(false, "4", "b"),
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "4", "31")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 19" {
  principal_fixture(
    @oracle.chain([elimination_rat(false, "1", "1")]),
    @oracle.chain([
      elimination_rat(true, "4", "b"),
      elimination_rat(true, "5", "b"),
      elimination_rat(true, "1", "5"),
    ]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 20" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "5", "1")]),
    @oracle.chain([
      elimination_rat(true, "4", "5"),
      elimination_rat(true, "4", "5"),
      elimination_rat(false, "1", "b"),
      elimination_rat(false, "1", "b"),
    ]),
    @oracle.chain([elimination_rat(true, "7d", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 21" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "5", "3")]),
    @oracle.chain([
      elimination_rat(true, "5", "1"),
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "3", "1"),
      elimination_rat(true, "4", "b"),
    ]),
    @oracle.chain([elimination_rat(true, "7d", "1b")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 22" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "2", "7")]),
    @oracle.chain([
      elimination_rat(true, "3", "b"),
      elimination_rat(false, "4", "5"),
      elimination_rat(true, "3", "5"),
      elimination_rat(true, "4", "1"),
    ]),
    @oracle.chain([elimination_rat(true, "8", "157")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 23" {
  principal_fixture(
    @oracle.chain([elimination_rat(true, "5", "3")]),
    @oracle.chain([
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "3", "1"),
      elimination_rat(true, "5", "b"),
    ]),
    @oracle.chain([elimination_rat(true, "7d", "1b")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 24" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "3", "7"),
      elimination_rat(false, "5", "7"),
    ]),
    @oracle.chain([elimination_rat(true, "2", "1")]),
    @oracle.chain([elimination_rat(true, "2", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 25" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "4", "3"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "2", "1")]),
    @oracle.chain([elimination_rat(false, "2", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 26" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "5", "1"),
      elimination_rat(false, "3", "7"),
    ]),
    @oracle.chain([elimination_rat(false, "3", "5")]),
    @oracle.chain([elimination_rat(false, "3", "5")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 27" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "3"),
      elimination_rat(true, "2", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 28" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "1"),
      elimination_rat(true, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3", "5"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "9", "23"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 29" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "2", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "a", "b"),
      elimination_rat(false, "1", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 30" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "4", "7"),
      elimination_rat(false, "5", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "f", "7"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 31" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "4", "5"),
      elimination_rat(true, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1c", "5"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 32" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "3", "1"),
      elimination_rat(true, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "1", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "357", "21b"),
      elimination_rat(true, "3", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 33" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3", "5"),
      elimination_rat(true, "5", "1"),
      elimination_rat(false, "2", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3f0", "37"),
      elimination_rat(false, "2", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 34" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "1", "3"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "5"),
      elimination_rat(false, "2", "b"),
      elimination_rat(true, "4", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "d5", "37"),
      elimination_rat(true, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 35" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "7"),
      elimination_rat(false, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(true, "2", "5"),
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "5", "b"),
    ]),
    @oracle.chain([
      elimination_rat(true, "12a", "a87"),
      elimination_rat(false, "2", "7"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 36" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "4", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "5"),
      elimination_rat(true, "4", "b"),
      elimination_rat(true, "5", "b"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "21ab8", "49b1"),
      elimination_rat(false, "4", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 37" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "4", "7"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1", "5"),
      elimination_rat(true, "3", "1"),
      elimination_rat(false, "1", "b"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "16c48", "49b1"),
      elimination_rat(false, "10", "31"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 38" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "7"),
      elimination_rat(false, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3", "1"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "5", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1c9", "ebd"),
      elimination_rat(false, "1", "31"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 39" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "1", "b"),
      elimination_rat(false, "4", "5"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3617", "49b1"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 40" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "4", "1"),
      elimination_rat(true, "2", "3"),
      elimination_rat(false, "2", "3"),
    ]),
    @oracle.chain([elimination_rat(false, "3", "b")]),
    @oracle.chain([elimination_rat(false, "9", "79")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 41" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "3"),
      elimination_rat(true, "2", "7"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([elimination_rat(true, "3", "b")]),
    @oracle.chain([elimination_rat(false, "9", "79")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 42" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "1"),
      elimination_rat(false, "1", "7"),
      elimination_rat(false, "1", "7"),
    ]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    @oracle.chain([elimination_rat(false, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 43" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "7"),
      elimination_rat(false, "5", "3"),
      elimination_rat(true, "3", "1"),
    ]),
    @oracle.chain([elimination_rat(false, "0", "1")]),
    @oracle.chain([elimination_rat(false, "0", "1")]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 44" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "5", "3"),
      elimination_rat(false, "4", "3"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3", "b"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "16a", "79"),
      elimination_rat(true, "3", "b"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 45" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "7"),
      elimination_rat(false, "1", "3"),
      elimination_rat(true, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "4", "5"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "20", "19"),
      elimination_rat(true, "4", "5"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 46" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "5", "3"),
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "5", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "5"),
      elimination_rat(true, "1", "5"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2b", "69"),
      elimination_rat(false, "3", "5"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 47" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "4", "3"),
      elimination_rat(false, "4", "1"),
      elimination_rat(true, "5", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "3", "b"),
    ]),
    @oracle.chain([
      elimination_rat(true, "33ec", "34f"),
      elimination_rat(false, "4", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 48" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "4", "3"),
      elimination_rat(false, "3", "1"),
      elimination_rat(true, "2", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "5", "b"),
      elimination_rat(true, "2", "1"),
      elimination_rat(false, "2", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "712", "d071"),
      elimination_rat(true, "85", "21"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 49" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "3", "7"),
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "3", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "1"),
      elimination_rat(false, "2", "5"),
      elimination_rat(false, "1", "5"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2271f", "4c9"),
      elimination_rat(true, "207", "23"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 50" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "7"),
      elimination_rat(false, "1", "7"),
      elimination_rat(true, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(true, "2", "b"),
      elimination_rat(true, "1", "5"),
      elimination_rat(true, "3", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "4d1", "24301"),
      elimination_rat(false, "3", "37"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 51" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "4", "1"),
      elimination_rat(false, "2", "3"),
      elimination_rat(false, "4", "3"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "b"),
      elimination_rat(false, "4", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "27a4", "79"),
      elimination_rat(true, "b2", "b"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 52" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "3", "7"),
      elimination_rat(false, "4", "3"),
      elimination_rat(false, "4", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "4", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "ccac0", "1e65d"),
      elimination_rat(true, "14", "4d"),
      elimination_rat(true, "3", "7"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 53" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "2", "3"),
    ]),
    @oracle.chain([
      elimination_rat(false, "5", "1"),
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "1", "b"),
      elimination_rat(true, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "465da", "cc3"),
      elimination_rat(false, "d9", "21"),
      elimination_rat(true, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 54" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "5", "7"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "5", "1"),
      elimination_rat(false, "5", "b"),
      elimination_rat(true, "1", "1"),
      elimination_rat(true, "2", "5"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1a33d", "ebd"),
      elimination_rat(true, "7d", "31"),
      elimination_rat(false, "0", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 55" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "5", "7"),
      elimination_rat(false, "4", "3"),
      elimination_rat(true, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(true, "5", "1"),
      elimination_rat(false, "1", "b"),
      elimination_rat(true, "4", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "315fce", "1e65d"),
      elimination_rat(true, "21f7", "2b5"),
      elimination_rat(false, "5", "7"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 56" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "5", "3"),
      elimination_rat(true, "2", "7"),
      elimination_rat(false, "2", "3"),
      elimination_rat(false, "1", "7"),
    ]),
    @oracle.chain([elimination_rat(true, "1", "1")]),
    @oracle.chain([elimination_rat(true, "1", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 57" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "1", "7"),
      elimination_rat(false, "3", "7"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "5", "3"),
    ]),
    @oracle.chain([elimination_rat(true, "5", "1")]),
    @oracle.chain([elimination_rat(true, "7d", "1")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 58" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "5", "1"),
      elimination_rat(false, "2", "3"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "5", "7"),
    ]),
    @oracle.chain([elimination_rat(false, "2", "b")]),
    @oracle.chain([elimination_rat(false, "8", "533")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 59" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "3", "7"),
      elimination_rat(false, "2", "7"),
      elimination_rat(true, "4", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([elimination_rat(true, "3", "5")]),
    @oracle.chain([elimination_rat(true, "1b", "7d")]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 60" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "7"),
      elimination_rat(false, "5", "7"),
      elimination_rat(true, "2", "3"),
      elimination_rat(true, "4", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "2", "5"),
    ]),
    @oracle.chain([
      elimination_rat(false, "10", "36b"),
      elimination_rat(false, "0", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 61" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "b"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "5", "533"),
      elimination_rat(false, "1", "79"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 62" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "1", "7"),
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "5", "b"),
    ]),
    @oracle.chain([
      elimination_rat(true, "e33", "2465"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 63" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "2", "1"),
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "2", "1"),
      elimination_rat(false, "4", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "3", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "49", "7"),
      elimination_rat(false, "9", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 64" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(true, "5", "7"),
      elimination_rat(true, "2", "1"),
      elimination_rat(false, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2", "5"),
      elimination_rat(true, "2", "5"),
      elimination_rat(true, "2", "b"),
    ]),
    @oracle.chain([
      elimination_rat(false, "a45a8", "4f9cf"),
      elimination_rat(false, "c", "181"),
      elimination_rat(false, "2", "5"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 65" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "4", "1"),
      elimination_rat(true, "1", "3"),
      elimination_rat(true, "3", "7"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "5", "1"),
      elimination_rat(true, "3", "5"),
    ]),
    @oracle.chain([
      elimination_rat(false, "27413", "17ed"),
      elimination_rat(false, "2a82", "69"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 66" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "3"),
      elimination_rat(true, "1", "3"),
      elimination_rat(true, "1", "1"),
      elimination_rat(true, "3", "7"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(true, "5", "b"),
      elimination_rat(false, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "536d74", "8f4db"),
      elimination_rat(true, "7cc", "16b"),
      elimination_rat(false, "2", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 67" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "1", "1"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "2", "b"),
      elimination_rat(false, "4", "b"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "38", "533"),
      elimination_rat(false, "c", "79"),
      elimination_rat(false, "2", "b"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 68" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "5", "3"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "3", "5"),
      elimination_rat(false, "4", "5"),
      elimination_rat(false, "5", "1"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3fa21", "1b"),
      elimination_rat(false, "1e4d", "2d"),
      elimination_rat(true, "11", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 69" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "4", "7"),
      elimination_rat(false, "2", "7"),
      elimination_rat(true, "1", "1"),
      elimination_rat(false, "5", "3"),
    ]),
    @oracle.chain([
      elimination_rat(true, "1", "b"),
      elimination_rat(false, "2", "1"),
      elimination_rat(true, "2", "5"),
      elimination_rat(true, "1", "5"),
    ]),
    @oracle.chain([
      elimination_rat(true, "3b59821e0", "5bd6b99b"),
      elimination_rat(false, "17e73", "9de9"),
      elimination_rat(true, "56", "4d"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 70" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "4", "7"),
      elimination_rat(true, "2", "7"),
      elimination_rat(true, "5", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "4", "b"),
      elimination_rat(true, "3", "b"),
      elimination_rat(false, "3", "b"),
      elimination_rat(true, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "11734", "ebd"),
      elimination_rat(false, "124", "4d"),
      elimination_rat(true, "4", "4d"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 71" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(true, "3", "1"),
      elimination_rat(true, "4", "1"),
      elimination_rat(false, "4", "3"),
      elimination_rat(false, "5", "3"),
    ]),
    @oracle.chain([
      elimination_rat(false, "5", "b"),
      elimination_rat(true, "4", "b"),
      elimination_rat(true, "2", "5"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "80ff", "db579"),
      elimination_rat(true, "1751c", "6a59"),
      elimination_rat(false, "20", "b"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 72" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "40000000000000000000003", "11"),
      elimination_rat(true, "7", "d"),
      elimination_rat(false, "1", "5"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "7"),
      elimination_rat(true, "100000000000000000009", "13"),
    ]),
    @oracle.chain([
      elimination_rat(
        false, "31c400000000000000037fed530000000000000fc06eb7000000000000000228d1",
        "12a40e9",
      ),
      elimination_rat(false, "1", "7"),
    ]),
    Some(@oracle.nat(0)),
  )
}

///|
test "principal independent Fraction matrix and gcd 73" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(true, "3", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "2", "1"),
      elimination_rat(true, "3", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(1)),
  )
}

///|
test "principal independent Fraction matrix and gcd 74" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "2", "1"),
      elimination_rat(false, "4", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "6", "1"),
      elimination_rat(false, "c", "1"),
      elimination_rat(false, "6", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    Some(@oracle.nat(2)),
  )
}

///|
test "principal independent Fraction matrix and gcd 75" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "2", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "3", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    None,
  )
}

///|
test "principal independent Fraction matrix and gcd 76" {
  principal_fixture(
    @oracle.chain([
      elimination_rat(false, "1", "1"),
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "1", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    @oracle.chain([
      elimination_rat(false, "0", "1"),
      elimination_rat(false, "0", "1"),
    ]),
    None,
  )
}

///|
test "principal independent QQ coefficient and PSC query 0" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(false, "1", "1"), [1]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 1" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(false, "1", "1"), [1]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 2" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
    ]),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [3, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 3" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
      elimination_poly(2, []),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 1])]),
    ]),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "3", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 4" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
      elimination_poly(2, []),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(true, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 5" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
      elimination_poly(0, []),
      elimination_poly(0, [(elimination_rat(false, "2", "3"), [])]),
    ]),
    @oracle.chain([
      elimination_poly(0, [(elimination_rat(false, "13f", "31"), [])]),
      elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 6" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 7" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 8" {
  principal_variable_fixture(
    elimination_poly(2, []),
    elimination_poly(2, []),
    1,
    0,
    0,
    @oracle.chain([elimination_poly(1, [])]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 9" {
  principal_variable_fixture(
    elimination_poly(2, [(elimination_rat(false, "2", "7"), [0, 0])]),
    elimination_poly(2, [(elimination_rat(true, "3", "b"), [0, 0])]),
    1,
    0,
    0,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "2", "7"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 10" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "2", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [2])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 11" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 12" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "2", "7"), [1]),
        (elimination_rat(true, "2", "7"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 13" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "3"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "7"), [1]),
        (elimination_rat(true, "2", "7"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "b"), [2]),
        (elimination_rat(false, "1", "b"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "21"), [6]),
        (elimination_rat(false, "7d", "651"), [4]),
        (elimination_rat(true, "4", "93"), [3]),
        (elimination_rat(false, "140", "12f3"), [2]),
        (elimination_rat(true, "a", "1b9"), [1]),
        (elimination_rat(false, "5c", "12f3"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "3"), [2]),
        (elimination_rat(true, "1", "3"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 14" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "2", "3"), [1]),
        (elimination_rat(true, "2", "3"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "3", "b"), [1])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "b"), [1]),
        (elimination_rat(false, "1", "b"), [0]),
      ]),
    ]),
    @oracle.chain([
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
        (elimination_rat(false, "1", "1"), [4]),
        (elimination_rat(false, "2", "1"), [2]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 15" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "3"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "3e", "3f"), [1]),
        (elimination_rat(true, "53", "3f"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 16" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "b"), [0])]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "2", "7"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "12", "34f"), [4]),
        (elimination_rat(true, "1", "b"), [3]),
        (elimination_rat(true, "29", "34f"), [2]),
        (elimination_rat(true, "1", "b"), [1]),
        (elimination_rat(true, "1c6", "1dc7"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "3", "b"), [2]),
        (elimination_rat(true, "3", "b"), [0]),
      ]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 17" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "b"), [1]),
        (elimination_rat(true, "2", "b"), [0]),
      ]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
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
        (elimination_rat(true, "34", "63"), [3]),
        (elimination_rat(true, "8", "63"), [2]),
        (elimination_rat(true, "3e", "63"), [1]),
        (elimination_rat(true, "9", "79"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "2", "3"), [1])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 18" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
      elimination_poly(1, [
        (elimination_rat(false, "3", "b"), [1]),
        (elimination_rat(false, "3", "b"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "3", "4d"), [2]),
        (elimination_rat(true, "6", "4d"), [1]),
        (elimination_rat(false, "1", "7"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 19" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "2", "7"), [1])]),
      elimination_poly(1, [(elimination_rat(true, "1", "b"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "8", "93"), [5]),
        (elimination_rat(false, "dc", "1b9"), [4]),
        (elimination_rat(false, "14", "21b"), [3]),
        (elimination_rat(false, "b5c0", "d071"), [2]),
        (elimination_rat(true, "20", "1dc7"), [1]),
        (elimination_rat(false, "4c6", "cc3"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "4", "15"), [2]),
        (elimination_rat(true, "4", "15"), [1]),
        (elimination_rat(true, "2", "9"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 20" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "2", "7"), [1]),
        (elimination_rat(true, "2", "7"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "3", "b"), [1]),
        (elimination_rat(false, "3", "b"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "3", "b"), [2]),
        (elimination_rat(false, "3", "b"), [0]),
      ]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [
        (elimination_rat(false, "4", "79"), [2]),
        (elimination_rat(false, "8", "79"), [1]),
        (elimination_rat(false, "4", "79"), [0]),
      ]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 21" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "7"), [1])]),
      elimination_poly(1, [
        (elimination_rat(true, "3", "7"), [2]),
        (elimination_rat(true, "3", "7"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "3", "31"), [5]),
        (elimination_rat(true, "9", "31"), [4]),
        (elimination_rat(true, "6", "31"), [3]),
        (elimination_rat(true, "12", "31"), [2]),
        (elimination_rat(true, "3", "31"), [1]),
        (elimination_rat(true, "9", "31"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "7"), [1])]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 22" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "b"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "7"), [2]),
        (elimination_rat(true, "1", "7"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "1", "3f"), [4]),
        (elimination_rat(true, "2", "3f"), [3]),
        (elimination_rat(true, "b", "3f"), [2]),
        (elimination_rat(true, "3a0", "12f3"), [1]),
        (elimination_rat(true, "1", "3f"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "3"), [1]),
        (elimination_rat(true, "1", "3"), [0]),
      ]),
    ]),
  )
}

///|
test "principal independent QQ coefficient and PSC query 23" {
  principal_variable_fixture(
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
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "3"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "2", "3"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "b"), [1])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [1]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "96cc", "6f755"), [5]),
        (elimination_rat(true, "5dc3d1", "23441e5"), [4]),
        (elimination_rat(true, "29e54", "334bcf"), [3]),
        (elimination_rat(false, "14984", "1ade91"), [2]),
        (elimination_rat(false, "2da", "1a523"), [1]),
        (elimination_rat(true, "473", "1a523"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "9", "21b"), [3]),
        (elimination_rat(false, "19", "129"), [2]),
        (elimination_rat(false, "e", "129"), [1]),
        (elimination_rat(true, "1", "1b"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(true, "3", "7"), [1])]),
    ]),
  )
}
