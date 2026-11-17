///|
fn polynomial(
  n : Int32,
  data : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(n),
    @oracle.chain(
      data.map(fn(t) {
        @poly.Term::{
          coefficient: @oracle.rational(t.0, t.1),
          exponents: @oracle.chain(t.2.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn polynomial_json(p : @poly.Polynomial) -> String {
  "[" +
  @oracle.array(@poly.terms(p))
  .map(fn(t) {
    let e = "[" +
      @oracle.array(t.exponents)
      .map(fn(n) { @oracle.int_of_nat(n).to_string() })
      .join(",") +
      "]"
    "[[\{@oracle.int_of_integer(@exact.numerator(t.coefficient))},\{@oracle.int_of_binary(@exact.denominator(t.coefficient))}],\{e}]"
  })
  .join(",") +
  "]"
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (iterations, operation) : (Int32, () -> String) = match name {
    "unit-plus" => {
      let a = polynomial(3, [(1, 1, [0, 0, 0])])
      let b = polynomial(3, [
        (-2, 1, [0, 0, 0]),
        (-1, 2, [1, 1, 3]),
        (0, 3, [2, 2, 1]),
        (1, 1, [3, 3, 4]),
        (2, 2, [4, 0, 2]),
        (-2, 3, [5, 1, 0]),
        (-1, 1, [6, 2, 3]),
        (0, 2, [7, 3, 1]),
        (1, 3, [8, 0, 4]),
        (2, 1, [9, 1, 2]),
        (-2, 2, [10, 2, 0]),
        (-1, 3, [11, 3, 3]),
        (0, 1, [12, 0, 1]),
        (1, 2, [13, 1, 4]),
        (2, 3, [14, 2, 2]),
        (-2, 1, [15, 3, 0]),
        (-1, 2, [16, 0, 3]),
        (0, 3, [17, 1, 1]),
        (1, 1, [18, 2, 4]),
        (2, 2, [19, 3, 2]),
        (-2, 3, [20, 0, 0]),
        (-1, 1, [21, 1, 3]),
        (0, 2, [22, 2, 1]),
        (1, 3, [23, 3, 4]),
        (2, 1, [24, 0, 2]),
        (-2, 2, [25, 1, 0]),
        (-1, 3, [26, 2, 3]),
        (0, 1, [27, 3, 1]),
      ])
      let expected = polynomial(3, [
        (-1, 3, [26, 2, 3]),
        (-1, 1, [25, 1, 0]),
        (2, 1, [24, 0, 2]),
        (1, 3, [23, 3, 4]),
        (-1, 1, [21, 1, 3]),
        (-2, 3, [20, 0, 0]),
        (1, 1, [19, 3, 2]),
        (1, 1, [18, 2, 4]),
        (-1, 2, [16, 0, 3]),
        (-2, 1, [15, 3, 0]),
        (2, 3, [14, 2, 2]),
        (1, 2, [13, 1, 4]),
        (-1, 3, [11, 3, 3]),
        (-1, 1, [10, 2, 0]),
        (2, 1, [9, 1, 2]),
        (1, 3, [8, 0, 4]),
        (-1, 1, [6, 2, 3]),
        (-2, 3, [5, 1, 0]),
        (1, 1, [4, 0, 2]),
        (1, 1, [3, 3, 4]),
        (-1, 2, [1, 1, 3]),
        (-2, 1, [0, 0, 0]),
      ])
      (
        15000,
        fn() {
          let left = @poly.multiply(a, b).unwrap()
          let right = @poly.multiply(b, a).unwrap()
          if left != expected || right != expected {
            abort("full independent unit/control product mismatch")
          }
          "[" + polynomial_json(left) + "," + polynomial_json(right) + "]"
        },
      )
    }
    "unit-minus" => {
      let a = polynomial(3, [(-1, 1, [0, 0, 0])])
      let b = polynomial(3, [
        (-2, 1, [0, 0, 0]),
        (-1, 2, [1, 1, 3]),
        (0, 3, [2, 2, 1]),
        (1, 1, [3, 3, 4]),
        (2, 2, [4, 0, 2]),
        (-2, 3, [5, 1, 0]),
        (-1, 1, [6, 2, 3]),
        (0, 2, [7, 3, 1]),
        (1, 3, [8, 0, 4]),
        (2, 1, [9, 1, 2]),
        (-2, 2, [10, 2, 0]),
        (-1, 3, [11, 3, 3]),
        (0, 1, [12, 0, 1]),
        (1, 2, [13, 1, 4]),
        (2, 3, [14, 2, 2]),
        (-2, 1, [15, 3, 0]),
        (-1, 2, [16, 0, 3]),
        (0, 3, [17, 1, 1]),
        (1, 1, [18, 2, 4]),
        (2, 2, [19, 3, 2]),
        (-2, 3, [20, 0, 0]),
        (-1, 1, [21, 1, 3]),
        (0, 2, [22, 2, 1]),
        (1, 3, [23, 3, 4]),
        (2, 1, [24, 0, 2]),
        (-2, 2, [25, 1, 0]),
        (-1, 3, [26, 2, 3]),
        (0, 1, [27, 3, 1]),
      ])
      let expected = polynomial(3, [
        (1, 3, [26, 2, 3]),
        (1, 1, [25, 1, 0]),
        (-2, 1, [24, 0, 2]),
        (-1, 3, [23, 3, 4]),
        (1, 1, [21, 1, 3]),
        (2, 3, [20, 0, 0]),
        (-1, 1, [19, 3, 2]),
        (-1, 1, [18, 2, 4]),
        (1, 2, [16, 0, 3]),
        (2, 1, [15, 3, 0]),
        (-2, 3, [14, 2, 2]),
        (-1, 2, [13, 1, 4]),
        (1, 3, [11, 3, 3]),
        (1, 1, [10, 2, 0]),
        (-2, 1, [9, 1, 2]),
        (-1, 3, [8, 0, 4]),
        (1, 1, [6, 2, 3]),
        (2, 3, [5, 1, 0]),
        (-1, 1, [4, 0, 2]),
        (-1, 1, [3, 3, 4]),
        (1, 2, [1, 1, 3]),
        (2, 1, [0, 0, 0]),
      ])
      (
        15000,
        fn() {
          let left = @poly.multiply(a, b).unwrap()
          let right = @poly.multiply(b, a).unwrap()
          if left != expected || right != expected {
            abort("full independent unit/control product mismatch")
          }
          "[" + polynomial_json(left) + "," + polynomial_json(right) + "]"
        },
      )
    }
    "nonunit-controls" => {
      let a = polynomial(3, [(2, 3, [0, 0, 0])])
      let b = polynomial(3, [
        (-2, 1, [0, 0, 0]),
        (-1, 2, [1, 1, 3]),
        (0, 3, [2, 2, 1]),
        (1, 1, [3, 3, 4]),
        (2, 2, [4, 0, 2]),
        (-2, 3, [5, 1, 0]),
        (-1, 1, [6, 2, 3]),
        (0, 2, [7, 3, 1]),
        (1, 3, [8, 0, 4]),
        (2, 1, [9, 1, 2]),
        (-2, 2, [10, 2, 0]),
        (-1, 3, [11, 3, 3]),
        (0, 1, [12, 0, 1]),
        (1, 2, [13, 1, 4]),
        (2, 3, [14, 2, 2]),
        (-2, 1, [15, 3, 0]),
        (-1, 2, [16, 0, 3]),
        (0, 3, [17, 1, 1]),
        (1, 1, [18, 2, 4]),
        (2, 2, [19, 3, 2]),
        (-2, 3, [20, 0, 0]),
        (-1, 1, [21, 1, 3]),
        (0, 2, [22, 2, 1]),
        (1, 3, [23, 3, 4]),
        (2, 1, [24, 0, 2]),
        (-2, 2, [25, 1, 0]),
        (-1, 3, [26, 2, 3]),
        (0, 1, [27, 3, 1]),
      ])
      let expected = polynomial(3, [
        (-2, 9, [26, 2, 3]),
        (-2, 3, [25, 1, 0]),
        (4, 3, [24, 0, 2]),
        (2, 9, [23, 3, 4]),
        (-2, 3, [21, 1, 3]),
        (-4, 9, [20, 0, 0]),
        (2, 3, [19, 3, 2]),
        (2, 3, [18, 2, 4]),
        (-1, 3, [16, 0, 3]),
        (-4, 3, [15, 3, 0]),
        (4, 9, [14, 2, 2]),
        (1, 3, [13, 1, 4]),
        (-2, 9, [11, 3, 3]),
        (-2, 3, [10, 2, 0]),
        (4, 3, [9, 1, 2]),
        (2, 9, [8, 0, 4]),
        (-2, 3, [6, 2, 3]),
        (-4, 9, [5, 1, 0]),
        (2, 3, [4, 0, 2]),
        (2, 3, [3, 3, 4]),
        (-1, 3, [1, 1, 3]),
        (-4, 3, [0, 0, 0]),
      ])
      (
        5000,
        fn() {
          let left = @poly.multiply(a, b).unwrap()
          let right = @poly.multiply(b, a).unwrap()
          if left != expected || right != expected {
            abort("full independent unit/control product mismatch")
          }
          "[" + polynomial_json(left) + "," + polynomial_json(right) + "]"
        },
      )
    }
    "dense-control" => {
      let a = polynomial(2, [
        (-2, 1, [0, 0]),
        (-1, 1, [1, 0]),
        (0, 1, [2, 0]),
        (1, 1, [3, 0]),
        (2, 1, [4, 0]),
        (-2, 1, [5, 0]),
        (-1, 1, [0, 1]),
        (0, 1, [1, 1]),
        (1, 1, [2, 1]),
        (2, 1, [3, 1]),
        (-2, 1, [4, 1]),
        (-1, 1, [5, 1]),
        (0, 1, [0, 2]),
        (1, 1, [1, 2]),
        (2, 1, [2, 2]),
        (-2, 1, [3, 2]),
        (-1, 1, [4, 2]),
        (0, 1, [5, 2]),
        (1, 1, [0, 3]),
        (2, 1, [1, 3]),
        (-2, 1, [2, 3]),
        (-1, 1, [3, 3]),
        (0, 1, [4, 3]),
        (1, 1, [5, 3]),
      ])
      let b = polynomial(2, [
        (-3, 1, [0, 0]),
        (-2, 1, [1, 0]),
        (-1, 1, [2, 0]),
        (0, 1, [3, 0]),
        (1, 1, [4, 0]),
        (2, 1, [5, 0]),
        (3, 1, [0, 1]),
        (-3, 1, [1, 1]),
        (-2, 1, [2, 1]),
        (-1, 1, [3, 1]),
        (0, 1, [4, 1]),
        (1, 1, [5, 1]),
        (2, 1, [0, 2]),
        (3, 1, [1, 2]),
        (-3, 1, [2, 2]),
        (-2, 1, [3, 2]),
        (-1, 1, [4, 2]),
        (0, 1, [5, 2]),
      ])
      let expected = polynomial(2, [
        (1, 1, [10, 4]),
        (2, 1, [10, 3]),
        (-1, 1, [10, 2]),
        (-4, 1, [10, 1]),
        (-4, 1, [10, 0]),
        (-1, 1, [9, 5]),
        (1, 1, [9, 3]),
        (-2, 1, [9, 2]),
        (-3, 1, [9, 1]),
        (2, 1, [9, 0]),
        (-2, 1, [8, 5]),
        (-1, 1, [8, 4]),
        (5, 1, [8, 1]),
        (4, 1, [8, 0]),
        (-2, 1, [7, 5]),
        (2, 1, [7, 3]),
        (8, 1, [7, 2]),
        (7, 1, [7, 1]),
        (3, 1, [7, 0]),
        (7, 1, [6, 5]),
        (5, 1, [6, 4]),
        (3, 1, [6, 3]),
        (-4, 1, [6, 2]),
        (5, 1, [6, 1]),
        (7, 1, [5, 5]),
        (6, 1, [5, 4]),
        (-9, 1, [5, 3]),
        (2, 1, [5, 2]),
        (-13, 1, [5, 1]),
        (-4, 1, [5, 0]),
        (-2, 1, [4, 5]),
        (-11, 1, [4, 4]),
        (3, 1, [4, 3]),
        (2, 1, [4, 2]),
        (4, 1, [4, 1]),
        (-10, 1, [4, 0]),
        (-16, 1, [3, 5]),
        (-3, 1, [3, 4]),
        (14, 1, [3, 2]),
        (-1, 1, [3, 1]),
        (-2, 1, [3, 0]),
        (-1, 1, [2, 5]),
        (-7, 1, [2, 4]),
        (9, 1, [2, 3]),
        (5, 1, [2, 1]),
        (4, 1, [2, 0]),
        (7, 1, [1, 5]),
        (5, 1, [1, 4]),
        (-8, 1, [1, 3]),
        (-8, 1, [1, 2]),
        (5, 1, [1, 1]),
        (7, 1, [1, 0]),
        (2, 1, [0, 5]),
        (3, 1, [0, 4]),
        (-5, 1, [0, 3]),
        (-7, 1, [0, 2]),
        (-3, 1, [0, 1]),
        (6, 1, [0, 0]),
      ])
      (
        500,
        fn() {
          let left = @poly.multiply(a, b).unwrap()
          let right = @poly.multiply(b, a).unwrap()
          if left != expected || right != expected {
            abort("full independent unit/control product mismatch")
          }
          "[" + polynomial_json(left) + "," + polynomial_json(right) + "]"
        },
      )
    }
    "tiny-zero-errors" => {
      let one = polynomial(0, [(1, 1, [])])
      let minus = polynomial(0, [(-1, 1, [])])
      let third = polynomial(0, [(2, 3, [])])
      let wanted = polynomial(0, [(-2, 3, [])])
      let z = @poly.zero(@oracle.nat(2))
      let unit = polynomial(2, [(1, 1, [0, 0])])
      let monomial = polynomial(2, [(1, 1, [0, 1])])
      let shifted = polynomial(2, [(1, 1, [0, 2])])
      (
        50000,
        fn() {
          if @poly.multiply(one, minus) != Ok(minus) ||
            @poly.multiply(minus, third) != Ok(wanted) ||
            @poly.multiply(z, unit) != Ok(z) ||
            @poly.multiply(unit, z) != Ok(z) ||
            @poly.multiply(one, z) != Err(@poly.DimensionMismatch) ||
            @poly.multiply(z, one) != Err(@poly.DimensionMismatch) ||
            @poly.multiply(monomial, monomial) != Ok(shifted) {
            abort("tiny/zero/0var/nonconstant/dimension result mismatch")
          }
          polynomial_json(wanted)
        },
      )
    }
    "nf-upper" => {
      let root : @real.RootCertificate = {
        polynomial: polynomial(1, [(1, 1, [4]), (-10, 1, [2]), (1, 1, [0])]),
        interval: {
          lower: @oracle.rational(3, 1),
          upper: @oracle.rational(4, 1),
        },
      }
      let f = match
        @minimal.normalize_root(
          root,
          @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
          @oracle.nat(40),
          @oracle.nat(256),
          @oracle.nat(256),
        ).unwrap() {
        Normalized(value, proof) =>
          @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
        _ => abort("field setup unresolved")
      }
      let p = polynomial(1, [
        (1, 1, [0]),
        (-2, 1, [1]),
        (1, 1, [2]),
        (1, 1, [3]),
      ])
      let value = @nf.element(f, p).unwrap()
      let unit = @nf.one(f)
      let minus = @nf.negate(unit)
      let wanted = @poly.negate(p)
      (
        10000,
        fn() {
          let a = @nf.multiply(unit, value).unwrap()
          let b = @nf.multiply(value, unit).unwrap()
          let c = @nf.multiply(minus, value).unwrap()
          let d = @nf.multiply(value, minus).unwrap()
          if @nf.representative(a) != p ||
            @nf.representative(b) != p ||
            @nf.representative(c) != wanted ||
            @nf.representative(d) != wanted ||
            !@nf.same_field(@nf.parent(a), f) ||
            !@nf.same_field(@nf.parent(d), f) {
            abort("full NF unit product/context mismatch")
          }
          "[" +
          polynomial_json(@nf.representative(a)) +
          "," +
          polynomial_json(@nf.representative(b)) +
          "," +
          polynomial_json(@nf.representative(c)) +
          "," +
          polynomial_json(@nf.representative(d)) +
          "]"
        },
      )
    }
    _ => abort("unknown unit case")
  }
  let expected = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("unstable full output")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
