// Independent full Collins and product projection, direct permutation determinants.

///|
test "projection independent CollinsProjection family 0" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([]),
    1,
    @oracle.chain([]),
    @oracle.chain([]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 0" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    Some(elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])])),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 1" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([elimination_poly(2, [])]),
    1,
    @oracle.chain([elimination_poly(1, [])]),
    @oracle.chain([]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 1" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([elimination_poly(2, [])]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    Some(elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])])),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 2" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 2" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [1, 0]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([elimination_rat(true, "2", "1")]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([elimination_rat(true, "1", "1")]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([elimination_rat(false, "0", "1")]),
        None,
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([elimination_rat(false, "2", "1")]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 3" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 3" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "4", "1"), [3]),
        (elimination_rat(false, "8", "1"), [2]),
        (elimination_rat(true, "4", "1"), [1]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "6", "1"), [1]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "3", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 3]),
        (elimination_rat(true, "1", "1"), [0, 2]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "48", "1"),
          elimination_rat(false, "a", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "10", "1"),
          elimination_rat(false, "4", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "2", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "8", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "8", "1"),
          elimination_rat(true, "e", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 4" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(true, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "2", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 4" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(true, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "3", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "3", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [3])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "3", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [3, 0]),
        (elimination_rat(false, "3", "1"), [2, 1]),
        (elimination_rat(true, "3", "1"), [1, 2]),
        (elimination_rat(false, "1", "1"), [0, 3]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 5" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 2]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "1", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(true, "2", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, []),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "1"), [1]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "4", "1"), [3]),
        (elimination_rat(true, "c", "1"), [2]),
        (elimination_rat(false, "c", "1"), [1]),
        (elimination_rat(true, "4", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(false, "5", "1"), [3]),
        (elimination_rat(false, "5", "1"), [2]),
        (elimination_rat(true, "5", "1"), [1]),
        (elimination_rat(true, "5", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 5" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 2]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "1", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(true, "2", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "1"), [2]),
        (elimination_rat(false, "2", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "1"), [2]),
        (elimination_rat(false, "2", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "64", "1"), [10]),
        (elimination_rat(true, "1f4", "1"), [8]),
        (elimination_rat(false, "3e8", "1"), [6]),
        (elimination_rat(true, "3e8", "1"), [4]),
        (elimination_rat(false, "1f4", "1"), [2]),
        (elimination_rat(true, "64", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "2", "1"), [6]),
        (elimination_rat(false, "6", "1"), [4]),
        (elimination_rat(true, "6", "1"), [2]),
        (elimination_rat(false, "2", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "3", "1"), [2]),
        (elimination_rat(true, "3", "1"), [0]),
      ]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 3]),
        (elimination_rat(true, "2", "1"), [2, 2]),
        (elimination_rat(false, "1", "1"), [2, 1]),
        (elimination_rat(true, "2", "1"), [2, 0]),
        (elimination_rat(true, "1", "1"), [0, 3]),
        (elimination_rat(false, "2", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 1]),
        (elimination_rat(false, "2", "1"), [0, 0]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "5eec", "1"),
          elimination_rat(true, "36", "1"),
          elimination_rat(false, "9", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
        ]),
        None,
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(true, "64", "1"),
          elimination_rat(false, "2", "1"),
          elimination_rat(true, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
        ]),
        None,
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "5eec", "1"),
          elimination_rat(true, "36", "1"),
          elimination_rat(false, "9", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 6" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "2", "3"), [0, 0])]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "5"), [1, 0]),
        (elimination_rat(false, "1", "5"), [0, 2]),
      ]),
      elimination_poly(2, []),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "2", "3"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "5"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "5"), [1])]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "4", "7d"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 6" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [(elimination_rat(false, "2", "3"), [0, 0])]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "5"), [1, 0]),
        (elimination_rat(false, "1", "5"), [0, 2]),
      ]),
      elimination_poly(2, []),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "2", "f"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "2", "f"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "20", "d2f"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "4", "f"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "2", "f"), [1, 0]),
        (elimination_rat(false, "2", "f"), [0, 2]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "40", "d2f"),
          elimination_rat(false, "4", "f"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "20", "d2f"),
          elimination_rat(false, "4", "f"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "4", "f"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "20", "d2f"),
          elimination_rat(false, "4", "f"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "40", "d2f"),
          elimination_rat(false, "4", "f"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 7" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 7" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, []),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "4", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "1", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "1", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "4", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 8" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 1]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [4]),
        (elimination_rat(true, "3", "1"), [2]),
        (elimination_rat(false, "4", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "4", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 8" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 1]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "4", "1"), [10]),
        (elimination_rat(true, "20", "1"), [8]),
        (elimination_rat(false, "74", "1"), [6]),
        (elimination_rat(true, "e8", "1"), [4]),
        (elimination_rat(false, "100", "1"), [2]),
        (elimination_rat(true, "80", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "6", "1"), [6]),
        (elimination_rat(true, "26", "1"), [4]),
        (elimination_rat(false, "4c", "1"), [2]),
        (elimination_rat(true, "30", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "3", "1"), [2]),
        (elimination_rat(true, "6", "1"), [0]),
      ]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 3]),
        (elimination_rat(false, "1", "1"), [2, 1]),
        (elimination_rat(false, "1", "1"), [1, 2]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 3]),
        (elimination_rat(true, "2", "1"), [0, 1]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "200", "1"),
          elimination_rat(false, "20", "1"),
          elimination_rat(false, "6", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "10", "1"),
          elimination_rat(true, "4", "1"),
          elimination_rat(true, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(true, "80", "1"),
          elimination_rat(true, "30", "1"),
          elimination_rat(true, "6", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "10", "1"),
          elimination_rat(true, "4", "1"),
          elimination_rat(true, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "200", "1"),
          elimination_rat(false, "20", "1"),
          elimination_rat(false, "6", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 9" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(true, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
    ]),
    0,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 9" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(true, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
    ]),
    0,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "4", "1"), [3]),
        (elimination_rat(false, "8", "1"), [2]),
        (elimination_rat(true, "4", "1"), [1]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "6", "1"), [1]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "3", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [3, 0]),
        (elimination_rat(true, "1", "1"), [2, 0]),
        (elimination_rat(true, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "48", "1"),
          elimination_rat(false, "a", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "10", "1"),
          elimination_rat(false, "4", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "2", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "8", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "8", "1"),
          elimination_rat(true, "e", "1"),
          elimination_rat(false, "3", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 10" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [2, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "2", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [2])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "2", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "3", "1"), [4])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "4", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 10" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [2, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "2", "1"), [1])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "2", "1"), [3])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [4])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "c", "1"), [2])]),
      elimination_poly(1, [(elimination_rat(false, "4", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [4, 0]),
        (elimination_rat(true, "2", "1"), [3, 1]),
        (elimination_rat(false, "2", "1"), [1, 3]),
        (elimination_rat(false, "1", "1"), [0, 4]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "30", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "c", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(3)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "c", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(true, "30", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(2)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 11" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 11" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "2", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [2])]),
    ]),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "2", "1"),
        ]),
        Some(@oracle.nat(1)),
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 12" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 12" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [2, 0]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [3]),
        (elimination_rat(true, "2", "1"), [2]),
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "2", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [3, 0]),
        (elimination_rat(true, "2", "1"), [2, 0]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([elimination_rat(false, "1", "1")]),
        None,
      ),
    ],
  )
}

///|
test "projection independent CollinsProjection family 13" {
  projection_fixture(
    CollinsProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 3]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "4", "1"), [3]),
        (elimination_rat(false, "1b", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "6", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [3]),
        (elimination_rat(true, "1", "1"), [2]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [2]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
    ]),
    None,
    [],
  )
}

///|
test "projection independent ProductProjection family 13" {
  projection_fixture(
    ProductProjection,
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 3]),
        (elimination_rat(false, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    1,
    @oracle.chain([
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
      elimination_poly(1, [
        (elimination_rat(true, "1", "1"), [2]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
    ]),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(true, "4", "1"), [9]),
        (elimination_rat(true, "8", "1"), [8]),
        (elimination_rat(true, "4", "1"), [7]),
        (elimination_rat(true, "23", "1"), [6]),
        (elimination_rat(true, "3e", "1"), [5]),
        (elimination_rat(true, "1b", "1"), [4]),
        (elimination_rat(true, "3a", "1"), [3]),
        (elimination_rat(true, "36", "1"), [2]),
        (elimination_rat(true, "1b", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "6", "1"), [5]),
        (elimination_rat(false, "6", "1"), [4]),
        (elimination_rat(true, "a", "1"), [3]),
        (elimination_rat(true, "c", "1"), [2]),
        (elimination_rat(false, "24", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(true, "3", "1"), [2]),
        (elimination_rat(false, "8", "1"), [1]),
      ]),
      elimination_poly(1, [(elimination_rat(false, "4", "1"), [0])]),
    ]),
    Some(
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [2, 1]),
        (elimination_rat(true, "1", "1"), [1, 3]),
        (elimination_rat(false, "1", "1"), [1, 2]),
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 4]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ),
    [
      (
        elimination_rat(true, "2", "1"),
        @oracle.chain([
          elimination_rat(false, "2d", "1"),
          elimination_rat(true, "1c", "1"),
          elimination_rat(true, "1c", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(true, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "17", "1"),
          elimination_rat(false, "22", "1"),
          elimination_rat(true, "b", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "0", "1"),
        @oracle.chain([
          elimination_rat(true, "1b", "1"),
          elimination_rat(false, "24", "1"),
          elimination_rat(false, "0", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "1", "1"),
        @oracle.chain([
          elimination_rat(true, "117", "1"),
          elimination_rat(false, "1a", "1"),
          elimination_rat(false, "5", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
      (
        elimination_rat(false, "2", "1"),
        @oracle.chain([
          elimination_rat(true, "26f3", "1"),
          elimination_rat(false, "c4", "1"),
          elimination_rat(false, "4", "1"),
          elimination_rat(false, "4", "1"),
        ]),
        Some(@oracle.nat(0)),
      ),
    ],
  )
}
