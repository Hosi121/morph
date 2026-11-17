///|
/// Fixed public-API fixtures. Input construction, algorithm and witness checks
/// occur together inside each timed iteration on both source revisions.
fn rational_matrix(
  values : Array[Array[(Int32, Int32)]],
) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(values[0].length()),
    @oracle.chain(
      values.map(fn(row) {
        @oracle.chain(row.map(fn(value) { @oracle.rational(value.0, value.1) }))
      }),
    ),
  ).unwrap()
}

///|
fn cells(mode : String) -> Array[Array[(Int32, Int32)]] {
  match mode {
    "identity-rref" =>
      [
        for i in 0..<10 => {
          [
            for j in 0..<10 => (if i == j { 1 } else { 0 }, 1)
          ]
        }
      ]
    "sparse-inverse" =>
      [
        for i in 0..<8 => {
          [
            for j in 0..<8 => (if i == j || j == i + 1 { 1 } else { 0 }, 1)
          ]
        }
      ]
    "dense-rref" | "dense-inverse" =>
      [
        for i in 0..<5 => {
          [
            for j in 0..<5 => {
              (if i == j { 11 + i } else { 1 + (i * 3 + j * 2) % 5 }, 1)
            }
          ]
        }
      ]
    "fractional-solve" =>
      [
        for i in 0..<4 => {
          [
            for j in 0..<5 => ((i * 7 + j * 3 + i * j) % 9 - 4, 2 + (i + j) % 3)
          ]
        }
      ]
    "singular-rectangular" =>
      [
        for i in 0..<4 => {
          [
            for j in 0..<6 => ((i % 2 + 1) * (j % 3 - 1), 2 + j % 2)
          ]
        }
      ]
    _ => abort("unknown matrix fixture")
  }
}

///|
fn apply(
  a : @matrix.Matrix[@exact.Rational],
  x : @core.Chain[@exact.Rational],
) -> @core.Chain[@exact.Rational] {
  @core.map(@matrix.rows(a), fn(row) {
    @core.fold_left(@core.zip(row, x).unwrap(), @exact.rational_zero(), fn(
      sum,
      pair,
    ) {
      @exact.rational_add(sum, @exact.rational_multiply(pair.0, pair.1))
    })
  })
}

///|
fn polynomial(values : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for i in 0..<values.length() => {
          @poly.Term::{
            coefficient: @oracle.rational(values[i], 1),
            exponents: @oracle.chain([@oracle.nat(i)]),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn iteration(mode : String) -> Int32 {
  if mode == "homology-inverse" {
    let input = @matrix.matrix(
      @oracle.nat(8),
      @oracle.chain(
        [
          for i in 0..<8 => {
            @oracle.chain(
              [
                for j in 0..<8 => {
                  @oracle.integer(if i == j || j == i + 1 { 1 } else { 0 })
                }
              ],
            )
          }
        ],
      ),
    ).unwrap()
    let result = @hom.integer_inverse(input).unwrap()
    if !@hom.inverse_pair(input, result) {
      abort("invalid integral inverse witness")
    }
    return @oracle.int_of_nat(@matrix.width(result))
  }
  if mode == "numberfield-minpoly" {
    let root : @real.RootCertificate = {
      polynomial: polynomial([-2, 0, 1]),
      interval: {
        lower: @oracle.rational(1, 1),
        upper: @oracle.rational(2, 1),
      },
    }
    let (selected, proof) = match
      @minimal.normalize_root(
        root,
        @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
        @oracle.nat(40),
        @oracle.nat(256),
        @oracle.nat(256),
      ).unwrap() {
      Normalized(value, proof) => (value, proof)
      _ => abort("unresolved numberfield fixture")
    }
    let field = @nf.field_result(selected, proof, @oracle.nat(256)).unwrap()
    let value = @nf.add(@nf.generator(field).unwrap(), @nf.one(field)).unwrap()
    let result = @nf.minimal_polynomial(value).unwrap()
    if !result.equal(polynomial([-1, -2, 1])) ||
      !@nf.check_minimal_polynomial(value, result) {
      abort("invalid minimal polynomial witness")
    }
    return @oracle.int_of_nat(@nf.degree(field))
  }
  let input = rational_matrix(cells(mode))
  if mode == "sparse-inverse" || mode == "dense-inverse" {
    let result = @linear.inverse(input).unwrap()
    if !@matrix.multiply(input, result, @algebra.rationals()).equal(
        Some(@matrix.identity(@matrix.width(input), @algebra.rationals())),
      ) {
      abort("invalid rational inverse witness")
    }
    return @oracle.int_of_nat(@matrix.width(result))
  }
  if mode == "fractional-solve" {
    let known = @core.map(@core.indices(@matrix.width(input)), fn(i) {
      @oracle.rational(@oracle.int_of_nat(i) - 2, 3)
    })
    let rhs = apply(input, known)
    let solution = match @linear.solve(input, rhs).unwrap() {
      Unique(x) => x
      Affine(x, basis) => {
        if !@core.all(basis, fn(v) {
            @core.all(apply(input, v), fn(x) { @exact.nonzero(x) is None })
          }) {
          abort("invalid nullspace witness")
        }
        x
      }
      Inconsistent => abort("consistent solve rejected")
    }
    if !apply(input, solution).equal(rhs) {
      abort("invalid solution witness")
    }
    return @oracle.int_of_nat(@core.length(solution))
  }
  let reduced = @linear.rref(input).unwrap()
  let expected = if mode == "singular-rectangular" {
    1
  } else {
    @oracle.int_of_nat(@matrix.width(input))
  }
  if @oracle.int_of_nat(@core.length(reduced.pivots)) != expected {
    abort("wrong exact rank")
  }
  if mode != "singular-rectangular" &&
    !reduced.matrix.equal(
      @matrix.identity(@matrix.width(input), @algebra.rationals()),
    ) {
    abort("wrong canonical rref")
  }
  @oracle.int_of_nat(@core.length(reduced.pivots))
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 1]
  let count = match mode {
    "numberfield-minpoly" => 600
    "singular-rectangular" => 10000
    "identity-rref" => 4000
    "sparse-inverse" | "homology-inverse" => 2000
    _ => 400
  }
  // Warm-up is outside the interval and validates the fixed fixture once.
  let expected = iteration(mode)
  let start = @bench.monotonic_clock_start()
  let mut checksum = 0
  for _ in 0..<count {
    checksum += iteration(mode)
  }
  let microseconds = @bench.monotonic_clock_end(start)
  if checksum != expected * count {
    abort("unstable benchmark result")
  }
  println(
    "{\"fixture\":\"\{mode}\",\"iterations\":\{count},\"elapsed_us\":\{microseconds},\"checksum\":\{checksum},\"checked\":true}",
  )
}
