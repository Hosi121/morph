///|
fn rank(input : Array[Array[Bool]], width : Int32) -> Int32 {
  let rows = input.map(fn(row) { row.copy() })
  let mut pivot = 0
  for column in 0..<width {
    let mut selected = -1
    for row in pivot..<rows.length() {
      if selected < 0 && rows[row][column] {
        selected = row
      }
    }
    if selected >= 0 {
      let tmp = rows[pivot]
      rows[pivot] = rows[selected]
      rows[selected] = tmp
      for row in (pivot + 1)..<rows.length() {
        if rows[row][column] {
          for j in column..<width {
            rows[row][j] = rows[row][j] != rows[pivot][j]
          }
        }
      }
      pivot += 1
    }
  }
  pivot
}

///|
fn complex(facets : Array[Array[Int32]]) -> @hom.Complex {
  @hom.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn css_case(mode : String, count : Int32) -> Int32 {
  let width = if mode == "css-rectangular" { 24 } else { 16 }
  let rows = Array::makei(16, fn(i) {
    Array::makei(width, fn(j) {
      if mode == "css-sparse" {
        i == j
      } else if mode == "css-singular" {
        j % 3 == 0
      } else {
        (i * 17 + j * 13 + i * j * 7) % 11 < 6
      }
    })
  })
  let expected = rank(rows, width)
  let input = @matrix.matrix(
    @oracle.nat(width),
    @oracle.chain(rows.map(@oracle.chain)),
  ).unwrap()
  let empty = @matrix.matrix(@oracle.nat(width), @core.Nil).unwrap()
  let mut sum = 0
  for _ in 0..<count {
    let code = @css.validate(input, empty).unwrap()
    let p = @css.parameters(code)
    if !@css.check_parameters(code, p, @css.certificate(code)) ||
      p.rank_x != @oracle.nat(expected) ||
      p.logical != @oracle.nat(width - expected) {
      abort("CSS exact rank/quotient witness differs from machine oracle")
    }
    sum += @oracle.int_of_nat(p.logical)
  }
  sum
}

///|
fn cohomology_case(mode : String, count : Int32) -> Int32 {
  let source = if mode == "coho-circle" {
    complex([[0, 1], [0, 2], [1, 2]])
  } else {
    complex([
      [0, 1, 2],
      [1, 2, 4],
      [1, 3, 4],
      [1, 3, 6],
      [0, 1, 5],
      [1, 5, 6],
      [2, 3, 5],
      [2, 4, 5],
      [2, 3, 6],
      [0, 2, 6],
      [0, 3, 4],
      [0, 3, 5],
      [4, 5, 6],
      [0, 4, 6],
    ])
  }
  let expected = if mode == "coho-circle" { [1, 1, 0] } else { [1, 2, 1] }
  let mut sum = 0
  for _ in 0..<count {
    for degree in 0..<3 {
      let space = @co.compute(source, @oracle.nat(degree)).unwrap()
      let actual = @co.result(space)
      if !@co.check_result(
          source,
          @oracle.nat(degree),
          actual,
          @co.certificate(space),
        ) ||
        actual.rank != @oracle.nat(expected[degree]) {
        abort("cohomology exact basis witness or known ranks failed")
      }
      sum += @oracle.int_of_nat(actual.rank)
    }
  }
  sum
}

///|
fn iteration(mode : String, count : Int32) -> Int32 {
  if mode.has_prefix("css-") {
    css_case(mode, count)
  } else {
    cohomology_case(mode, count)
  }
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  if ![
      "css-sparse", "css-dense", "css-singular", "css-rectangular", "coho-circle",
      "coho-torus",
    ].contains(mode) {
    abort("unknown GF2 consumer benchmark case")
  }
  let count = if mode == "coho-torus" {
    10
  } else if mode == "coho-circle" {
    200
  } else {
    30
  }
  let warm = iteration(mode, 1)
  let timer = @bench.monotonic_clock_start()
  let checksum = iteration(mode, count)
  let elapsed_us = @bench.monotonic_clock_end(timer)
  if checksum != warm * count {
    abort("consumer benchmark result changed")
  }
  println(
    "{\"fixture\":\"\{mode}\",\"iterations\":\{count},\"elapsed_us\":\{elapsed_us},\"checksum\":\{checksum},\"checked\":true}",
  )
}
