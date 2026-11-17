///|
// Independent test-only integer matrix engine. Width survives zero-row shapes.
#derive(Eq, Debug)
struct OracleMatrix {
  rows : Array[Array[Int32]]
  width : Int32
}

///|
pub extend OracleMatrix with Eq::{equal, not_equal}

///|
pub extend OracleMatrix with Debug::{to_repr}

///|
fn oracle_matrix(
  height : Int32,
  width : Int32,
  entry : (Int32, Int32) -> Int32,
) -> OracleMatrix {
  {
    rows: Array::makei(height, fn(i) {
      Array::makei(width, fn(j) { entry(i, j) })
    }),
    width,
  }
}

///|
fn oracle_zero(height : Int32, width : Int32) -> OracleMatrix {
  oracle_matrix(height, width, fn(_, _) { 0 })
}

///|
fn oracle_identity(size : Int32) -> OracleMatrix {
  oracle_matrix(size, size, fn(i, j) { if i == j { 1 } else { 0 } })
}

///|
fn oracle_product(a : OracleMatrix, b : OracleMatrix) -> OracleMatrix {
  if a.width != b.rows.length() {
    abort("oracle matrix shape mismatch")
  }
  oracle_matrix(a.rows.length(), b.width, fn(i, j) {
    let mut sum = 0
    for k in 0..<a.width {
      sum += a.rows[i][k] * b.rows[k][j]
    }
    sum
  })
}

///|
fn oracle_sum(a : OracleMatrix, b : OracleMatrix, sign : Int32) -> OracleMatrix {
  if a.width != b.width || a.rows.length() != b.rows.length() {
    abort("oracle matrix sum mismatch")
  }
  oracle_matrix(a.rows.length(), a.width, fn(i, j) {
    a.rows[i][j] + sign * b.rows[i][j]
  })
}

///|
fn numeric_faces(source : @homology.Complex) -> Array[Array[Int32]] {
  @oracle.array(@homology.all_simplices(source)).map(fn(face) {
    @oracle.array(face).map(@oracle.int_of_nat)
  })
}

///|
fn oracle_basis(
  faces : Array[Array[Int32]],
  degree : Int32,
) -> Array[Array[Int32]] {
  faces.filter(fn(face) { face.length() == degree + 1 })
}

///|
fn oracle_boundary(faces : Array[Array[Int32]], degree : Int32) -> OracleMatrix {
  let rows = if degree == 0 { [] } else { oracle_basis(faces, degree - 1) }
  let columns = oracle_basis(faces, degree)
  let result = oracle_zero(rows.length(), columns.length())
  if degree > 0 {
    for j, simplex in columns {
      for deleted in 0..<simplex.length() {
        let face = Array::makei(simplex.length() - 1, fn(i) {
          simplex[if i < deleted { i } else { i + 1 }]
        })
        for i, row in rows {
          if row == face {
            result.rows[i][j] = if deleted % 2 == 0 { 1 } else { -1 }
          }
        }
      }
    }
  }
  result
}

///|
fn numeric_matrix(input : @matrix.Matrix[@exact.Integer]) -> OracleMatrix {
  {
    rows: @oracle.array(@matrix.rows(input)).map(fn(row) {
      @oracle.array(row).map(@oracle.int_of_integer)
    }),
    width: @oracle.int_of_nat(@matrix.width(input)),
  }
}

///|
fn oracle_check_step(witness : Certificate) -> Unit raise {
  let source = numeric_faces(witness.source)
  let target = numeric_faces(witness.target)
  let lower = @oracle.array(witness.pair.lower).map(@oracle.int_of_nat)
  let upper = @oracle.array(witness.pair.upper).map(@oracle.int_of_nat)
  let mut epsilon = 0
  for deleted in 0..<upper.length() {
    let face = Array::makei(upper.length() - 1, fn(i) {
      upper[if i < deleted { i } else { i + 1 }]
    })
    if face == lower {
      epsilon = if deleted % 2 == 0 { 1 } else { -1 }
    }
  }
  assert_eq(@oracle.int_of_integer(witness.orientation), epsilon)
  let mut previous_i = oracle_zero(0, 0)
  let mut previous_p = oracle_zero(0, 0)
  let mut previous_h = oracle_zero(oracle_basis(source, 0).length(), 0)
  for k, maps in @oracle.array(witness.maps) {
    let sbasis = oracle_basis(source, k)
    let tbasis = oracle_basis(target, k)
    let next = oracle_basis(source, k + 1)
    let i = oracle_matrix(sbasis.length(), tbasis.length(), fn(r, c) {
      if sbasis[r] == tbasis[c] {
        1
      } else {
        0
      }
    })
    let h = oracle_matrix(next.length(), sbasis.length(), fn(r, c) {
      if next[r] == upper && sbasis[c] == lower {
        epsilon
      } else {
        0
      }
    })
    let ds = oracle_boundary(source, k)
    let ds_next = oracle_boundary(source, k + 1)
    let dt = oracle_boundary(target, k)
    assert_eq(
      numeric_matrix(
        @homology.boundary(witness.source, @oracle.nat(k)).unwrap(),
      ),
      ds,
    )
    assert_eq(
      numeric_matrix(
        @homology.boundary(witness.target, @oracle.nat(k)).unwrap(),
      ),
      dt,
    )
    let q = oracle_sum(
      oracle_sum(
        oracle_identity(sbasis.length()),
        oracle_product(ds_next, h),
        -1,
      ),
      oracle_product(previous_h, ds),
      -1,
    )
    let p = oracle_matrix(tbasis.length(), sbasis.length(), fn(r, c) {
      let mut value = 0
      for index, face in sbasis {
        if face == tbasis[r] {
          value = q.rows[index][c]
        }
      }
      value
    })
    assert_eq(numeric_matrix(maps.inclusion), i)
    assert_eq(numeric_matrix(maps.projection), p)
    assert_eq(numeric_matrix(maps.homotopy), h)
    assert_eq(oracle_product(dt, p), oracle_product(previous_p, ds))
    assert_eq(oracle_product(ds, i), oracle_product(previous_i, dt))
    assert_eq(oracle_product(p, i), oracle_identity(tbasis.length()))
    assert_eq(
      oracle_sum(oracle_identity(sbasis.length()), oracle_product(i, p), -1),
      oracle_sum(oracle_product(ds_next, h), oracle_product(previous_h, ds), 1),
    )
    previous_i = i
    previous_p = p
    previous_h = h
  }
}
