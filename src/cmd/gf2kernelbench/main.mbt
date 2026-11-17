///|
fn source(shape : String) -> @matrix.Matrix[Bool] {
  let (height, width) = match shape {
    "small" => (4, 5)
    "dense" | "sparse" | "dependent" => (24, 24)
    "wide" => (12, 36)
    "tall" => (36, 12)
    _ => abort("unknown shape")
  }
  let rows = Array::makei(height, fn(i) {
    Array::makei(width, fn(j) {
      let row = if shape == "dependent" && i >= height / 2 { i % 3 } else { i }
      let value = ((row + 1) * 197 + (j + 1) * 269 + row * j * 137 + 19) % 521
      if shape == "sparse" {
        i == j || value % 11 == 0
      } else {
        value % 2 == 0
      }
    })
  })
  @matrix.matrix(@oracle.nat(width), @oracle.chain(rows.map(@oracle.chain))).unwrap()
}

///|
fn baseline_factor(
  input : @matrix.Matrix[Bool],
) -> (@rowreduce.Reduction[Bool], @matrix.Matrix[Bool]) {
  let width = @matrix.width(input)
  let height = @matrix.height(input)
  let unit = @matrix.identity(height, @gf2.scalars())
  let pairs = @core.zip(@matrix.rows(input), @matrix.rows(unit)).unwrap()
  let augmented = @matrix.matrix(
    @core.add(width, height),
    @core.map(pairs, fn(pair) {
      let (row, identity) = pair
      @core.append(row, identity)
    }),
  ).unwrap()
  let old = @rowreduce.rref(@gf2.field(), augmented).unwrap()
  let reduced = @matrix.matrix(
    width,
    @core.map(@matrix.rows(old.matrix), fn(row) { @core.take(width, row) }),
  ).unwrap()
  let transform = @matrix.matrix(
    height,
    @core.map(@matrix.rows(old.matrix), fn(row) { @core.drop(width, row) }),
  ).unwrap()
  let pivots = @core.filter(old.pivots, fn(column) {
    @core.compare(column, width) is Less
  })
  ({ matrix: reduced, pivots, factor: true, }, transform)
}

///|
fn baseline_certificate(
  input : @matrix.Matrix[Bool],
) -> (@rowreduce.Reduction[Bool], @gf2.Certificate) {
  let (result, transform) = baseline_factor(input)
  let inverse_transform = @rowreduce.inverse(@gf2.field(), transform).unwrap()
  (
    result,
    {
      source: input,
      reduced: result.matrix,
      transform,
      inverse_transform,
      pivots: result.pivots,
    },
  )
}

///|
fn main {
  let args = @env.args()
  let variant = args[args.length() - 4]
  let workload = args[args.length() - 3]
  let shape = args[args.length() - 2]
  let reps = @string.parse_int(args[args.length() - 1][:]) catch {
    _ => abort("invalid repetition count")
  }
  let input = source(shape)
  let reference = @rowreduce.rref(@gf2.field(), input).unwrap()
  let rhs = @core.map(@core.indices(@matrix.height(input)), fn(i) {
    @oracle.int_of_nat(i) % 3 == 0
  })
  let expected_solution = @rowreduce.solve(@gf2.field(), input, rhs)
  let mut digest = 0
  for _ in 0..<reps {
    match workload {
      "rref" => {
        let result = if variant == "baseline" {
          @rowreduce.rref(@gf2.field(), input).unwrap()
        } else {
          @gf2.rref(input).unwrap()
        }
        if result != reference {
          abort("RREF output mismatch")
        }
        digest += @oracle.int_of_nat(@core.length(result.pivots))
      }
      "factor" => {
        let (result, transform) = if variant == "baseline" {
          baseline_factor(input)
        } else {
          let value = @gf2.factor(input).unwrap()
          (@gf2.reduction(value), @gf2.transform(value))
        }
        if result != reference ||
          @matrix.multiply(transform, input, @gf2.scalars()) !=
          Some(result.matrix) {
          abort("factor output mismatch")
        }
        digest += @oracle.int_of_nat(@core.length(result.pivots))
      }
      "certificate" => {
        let (result, certificate) = if variant == "baseline" {
          baseline_certificate(input)
        } else {
          let value = @gf2.factor(input).unwrap()
          (@gf2.reduction(value), @gf2.certificate(value).unwrap())
        }
        if result != reference ||
          !@gf2.check_certificate(input, result, certificate) {
          abort("certificate output mismatch")
        }
        digest += @oracle.int_of_nat(@core.length(result.pivots))
      }
      "solve" => {
        let result = if variant == "baseline" {
          @rowreduce.solve(@gf2.field(), input, rhs)
        } else {
          @gf2.solve(input, rhs)
        }
        if result != expected_solution {
          abort("solution mismatch")
        }
        digest += @oracle.int_of_nat(@core.length(reference.pivots))
      }
      "reuse" => {
        if variant == "baseline" {
          let (result, certificate) = baseline_certificate(input)
          if !@gf2.check_certificate(input, result, certificate) {
            abort("baseline certificate rejected")
          }
          for _ in 0..<4 {
            if @rowreduce.solve(@gf2.field(), input, rhs) != expected_solution {
              abort("baseline reuse solution mismatch")
            }
          }
        } else {
          let value = @gf2.factor(input).unwrap()
          if !@gf2.check_certificate(
              input,
              @gf2.reduction(value),
              @gf2.certificate(value).unwrap(),
            ) {
            abort("certificate rejected")
          }
          for _ in 0..<4 {
            if @gf2.solve_factor(value, rhs) != expected_solution {
              abort("reuse solution mismatch")
            }
          }
        }
        digest += @oracle.int_of_nat(@core.length(reference.pivots))
      }
      _ => abort("unknown workload")
    }
  }
  println(
    "{\"shape\":\"\{shape}\",\"workload\":\"\{workload}\",\"repetitions\":\{reps},\"rank\":\{@oracle.int_of_nat(@core.length(reference.pivots))},\"digest\":\{digest},\"checked\":true}",
  )
}
