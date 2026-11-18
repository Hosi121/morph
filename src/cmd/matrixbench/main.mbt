///|
type Block = (Int32, Int32, Int32, Int32)

///|
fn block_plus(a : Block, b : Block) -> Block {
  let (a0, a1, a2, a3) = a
  let (b0, b1, b2, b3) = b
  ((a0 + b0) % 7, (a1 + b1) % 7, (a2 + b2) % 7, (a3 + b3) % 7)
}

///|
fn block_times(a : Block, b : Block) -> Block {
  let (a0, a1, a2, a3) = a
  let (b0, b1, b2, b3) = b
  (
    (a0 * b0 + a1 * b2) % 7,
    (a0 * b1 + a1 * b3) % 7,
    (a2 * b0 + a3 * b2) % 7,
    (a2 * b1 + a3 * b3) % 7,
  )
}

///|
fn[A] matrix(values : Array[Array[A]], n : Int32) -> @matrix.Matrix[A] {
  @matrix.matrix(@oracle.nat(n), @oracle.chain(values.map(@oracle.chain))).unwrap()
}

///|
fn[A : Eq] run(
  input : @matrix.Matrix[A],
  expected : @matrix.Matrix[A],
  ops : @algebra.Semiring[A],
  iterations : Int32,
  multiply : Bool,
) -> @matrix.Matrix[A] {
  let mut last_result = input
  for _ in 0..<iterations {
    let actual = if multiply {
      @matrix.multiply(input, input, ops).unwrap()
    } else {
      @matrix.warshall(input, ops).unwrap()
    }
    if actual != expected {
      abort("complete matrix differs from independent reference")
    }
    last_result = actual
  }
  last_result
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  let (n, iterations) = match mode {
    "zero" => (0, 20000)
    "tiny" => (1, 20000)
    "bool24" => (24, 300)
    "bool64" => (64, 40)
    "multiply24" => (24, 300)
    "tropical12" => (12, 80)
    "block12" => (12, 80)
    _ => abort("expected frozen matrix benchmark case")
  }
  let text = if mode == "block12" {
    let values = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) {
        (
          (i + j * 2) % 7,
          (i * 3 + j + 1) % 7,
          (i + j + 2) % 7,
          (i * 2 + j * 3) % 7,
        )
      })
    })
    let expected = values.map(fn(row) { row.copy() })
    // Each stage reads a snapshot. Updating in place would change this recurrence.
    for k in 0..<n {
      let previous = expected.map(fn(row) { row.copy() })
      for i in 0..<n {
        for j in 0..<n {
          expected[i][j] = block_plus(
            previous[i][j],
            block_times(previous[i][k], previous[k][j]),
          )
        }
      }
    }
    let ops : @algebra.Semiring[Block] = {
      zero: (0, 0, 0, 0),
      one: (1, 0, 0, 1),
      plus: block_plus,
      times: block_times,
    }
    let result = run(
      matrix(values, n),
      matrix(expected, n),
      ops,
      iterations,
      false,
    )
    @oracle.array(@matrix.rows(result))
    .map(fn(row) {
      "[" +
      @oracle.array(row)
      .map(fn(value) {
        let (a, b, c, d) = value
        "[\{a},\{b},\{c},\{d}]"
      })
      .join(",") +
      "]"
    })
    .join(",")
  } else if mode == "tropical12" {
    let infinity_marker = 1000000
    let values = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) {
        if i == j {
          0
        } else if (i * 13 + j * 7) % 5 < 2 {
          (i * 17 + j * 11) % 23 + 1
        } else {
          infinity_marker
        }
      })
    })
    let expected = values.map(fn(row) { row.copy() })
    for k in 0..<n {
      for i in 0..<n {
        for j in 0..<n {
          expected[i][j] = expected[i][j].min(expected[i][k] + expected[k][j])
        }
      }
    }
    fn distances(row : Array[Int32]) -> Array[@algebra.Distance] {
      row.map(fn(value) {
        if value == 1000000 {
          @algebra.Infinity
        } else {
          @algebra.Finite(@binary.from_nat(@oracle.nat(value)))
        }
      })
    }
    let result = run(
      matrix(values.map(distances), n),
      matrix(expected.map(distances), n),
      @algebra.tropical(),
      iterations,
      false,
    )
    @oracle.array(@matrix.rows(result))
    .map(fn(row) {
      "[" +
      @oracle.array(row)
      .map(fn(value) {
        match value {
          Infinity => "null"
          Finite(value) => @oracle.int_of_binary(value).to_string()
        }
      })
      .join(",") +
      "]"
    })
    .join(",")
  } else {
    let values = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) { i == j || (i * 17 + j * 7) % 11 < 2 })
    })
    let expected = values.map(fn(row) { row.copy() })
    let multiply = mode == "multiply24"
    if multiply {
      for i in 0..<n {
        for j in 0..<n {
          expected[i][j] = false
          for k in 0..<n {
            expected[i][j] = expected[i][j] || (values[i][k] && values[k][j])
          }
        }
      }
    } else {
      for k in 0..<n {
        for i in 0..<n {
          for j in 0..<n {
            expected[i][j] = expected[i][j] ||
              (expected[i][k] && expected[k][j])
          }
        }
      }
    }
    let result = run(
      matrix(values, n),
      matrix(expected, n),
      @algebra.booleans(),
      iterations,
      multiply,
    )
    @oracle.array(@matrix.rows(result))
    .map(fn(row) {
      "[" +
      @oracle.array(row).map(fn(value) { value.to_string() }).join(",") +
      "]"
    })
    .join(",")
  }
  println(
    "{\"case\":\"\{mode}\",\"dimension\":\{n},\"iterations\":\{iterations},\"result\":[\{text}],\"checked\":true}",
  )
}
