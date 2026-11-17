///|
fn polynomial(
  variables : Int32,
  entries : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      entries.map(fn(entry) {
        let (n, d, e) = entry
        @poly.Term::{
          coefficient: @oracle.rational(n, d),
          exponents: @oracle.chain(e.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn polynomial_json(value : @poly.Polynomial) -> String {
  let ts = @oracle.array(@poly.terms(value))
    .map(fn(term) {
      let n = @oracle.int_of_integer(@exact.numerator(term.coefficient))
      let d = @oracle.int_of_binary(@exact.denominator(term.coefficient))
      let es = @oracle.array(term.exponents)
        .map(fn(x) { @oracle.int_of_nat(x).to_string() })
        .join(",")
      "[\{n},\{d},[" + es + "]]"
    })
    .join(",")
  "{\"variables\":\{@oracle.int_of_nat(@poly.variables(value))},\"terms\":[" +
  ts +
  "]}"
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (iterations, operation) : (Int32, () -> String) = match name {
    "dense-monic" => {
      let input = polynomial(1, [
        (-3, 1, [0]),
        (-1, 1, [1]),
        (-1, 3, [2]),
        (2, 1, [3]),
        (1, 2, [4]),
        (2, 3, [5]),
        (3, 1, [6]),
        (-3, 2, [7]),
        (-2, 3, [8]),
        (-1, 1, [9]),
        (1, 1, [10]),
        (1, 3, [11]),
        (2, 1, [12]),
        (3, 2, [13]),
        (-1, 1, [14]),
        (-2, 1, [15]),
        (-1, 2, [16]),
        (2, 3, [17]),
        (1, 1, [18]),
        (1, 1, [19]),
        (1, 1, [20]),
        (-3, 1, [21]),
        (-1, 1, [22]),
        (-1, 3, [23]),
        (2, 1, [24]),
        (1, 2, [25]),
        (2, 3, [26]),
        (3, 1, [27]),
        (-3, 2, [28]),
        (-2, 3, [29]),
        (-1, 1, [30]),
        (1, 1, [31]),
        (1, 3, [32]),
        (2, 1, [33]),
        (3, 2, [34]),
        (-1, 1, [35]),
        (-2, 1, [36]),
        (-1, 2, [37]),
        (2, 3, [38]),
        (1, 1, [39]),
        (1, 1, [40]),
        (1, 1, [41]),
        (-3, 1, [42]),
        (-1, 1, [43]),
        (-1, 3, [44]),
        (2, 1, [45]),
        (1, 2, [46]),
        (2, 3, [47]),
        (1, 1, [48]),
      ])
      let wanted = polynomial(1, [
        (1, 1, [48]),
        (2, 3, [47]),
        (1, 2, [46]),
        (2, 1, [45]),
        (-1, 3, [44]),
        (-1, 1, [43]),
        (-3, 1, [42]),
        (1, 1, [41]),
        (1, 1, [40]),
        (1, 1, [39]),
        (2, 3, [38]),
        (-1, 2, [37]),
        (-2, 1, [36]),
        (-1, 1, [35]),
        (3, 2, [34]),
        (2, 1, [33]),
        (1, 3, [32]),
        (1, 1, [31]),
        (-1, 1, [30]),
        (-2, 3, [29]),
        (-3, 2, [28]),
        (3, 1, [27]),
        (2, 3, [26]),
        (1, 2, [25]),
        (2, 1, [24]),
        (-1, 3, [23]),
        (-1, 1, [22]),
        (-3, 1, [21]),
        (1, 1, [20]),
        (1, 1, [19]),
        (1, 1, [18]),
        (2, 3, [17]),
        (-1, 2, [16]),
        (-2, 1, [15]),
        (-1, 1, [14]),
        (3, 2, [13]),
        (2, 1, [12]),
        (1, 3, [11]),
        (1, 1, [10]),
        (-1, 1, [9]),
        (-2, 3, [8]),
        (-3, 2, [7]),
        (3, 1, [6]),
        (2, 3, [5]),
        (1, 2, [4]),
        (2, 1, [3]),
        (-1, 3, [2]),
        (-1, 1, [1]),
        (-3, 1, [0]),
      ])
      (
        3000,
        fn() {
          let actual = @poly.monic(input)
          if actual != wanted {
            abort("Fraction full monic result mismatch")
          }
          polynomial_json(actual)
        },
      )
    }
    "sparse-monic" => {
      let input = polynomial(1, [
        (1, 1, [240]),
        (-2, 3, [83]),
        (7, 5, [32]),
        (-1, 1, [7]),
        (2, 1, [1]),
        (3, 7, [0]),
      ])
      let wanted = polynomial(1, [
        (1, 1, [240]),
        (-2, 3, [83]),
        (7, 5, [32]),
        (-1, 1, [7]),
        (2, 1, [1]),
        (3, 7, [0]),
      ])
      (
        4000,
        fn() {
          let actual = @poly.monic(input)
          if actual != wanted {
            abort("Fraction full monic result mismatch")
          }
          polynomial_json(actual)
        },
      )
    }
    "rational-multivar" => {
      let input = polynomial(3, [
        (-2, 1, [0, 0, 0]),
        (-1, 2, [0, 1, 3]),
        (1, 1, [0, 2, 6]),
        (1, 4, [0, 3, 2]),
        (2, 1, [0, 4, 5]),
        (-1, 1, [0, 5, 1]),
        (-1, 3, [1, 0, 4]),
        (3, 4, [1, 1, 0]),
        (1, 1, [1, 2, 3]),
        (1, 1, [1, 3, 6]),
        (-2, 3, [1, 4, 2]),
        (-1, 4, [1, 5, 5]),
        (3, 1, [2, 0, 1]),
        (1, 2, [2, 1, 4]),
        (2, 3, [2, 2, 0]),
        (-1, 2, [2, 3, 3]),
        (-1, 1, [2, 4, 6]),
        (3, 2, [2, 5, 2]),
        (1, 3, [3, 0, 5]),
        (1, 2, [3, 1, 1]),
        (-2, 1, [3, 2, 4]),
        (-1, 2, [3, 3, 0]),
        (1, 1, [3, 4, 3]),
        (1, 4, [3, 5, 6]),
        (2, 1, [4, 0, 2]),
        (-1, 1, [4, 1, 5]),
        (-1, 3, [4, 2, 1]),
        (3, 4, [4, 3, 4]),
        (1, 1, [4, 4, 0]),
        (1, 1, [4, 5, 3]),
        (-2, 3, [5, 0, 6]),
        (-1, 4, [5, 1, 2]),
        (3, 1, [5, 2, 5]),
        (1, 2, [5, 3, 1]),
        (2, 3, [5, 4, 4]),
        (-1, 2, [5, 5, 0]),
        (1, 1, [7, 2, 4]),
      ])
      let wanted = polynomial(3, [
        (1, 1, [7, 2, 4]),
        (-1, 2, [5, 5, 0]),
        (2, 3, [5, 4, 4]),
        (1, 2, [5, 3, 1]),
        (3, 1, [5, 2, 5]),
        (-1, 4, [5, 1, 2]),
        (-2, 3, [5, 0, 6]),
        (1, 1, [4, 5, 3]),
        (1, 1, [4, 4, 0]),
        (3, 4, [4, 3, 4]),
        (-1, 3, [4, 2, 1]),
        (-1, 1, [4, 1, 5]),
        (2, 1, [4, 0, 2]),
        (1, 4, [3, 5, 6]),
        (1, 1, [3, 4, 3]),
        (-1, 2, [3, 3, 0]),
        (-2, 1, [3, 2, 4]),
        (1, 2, [3, 1, 1]),
        (1, 3, [3, 0, 5]),
        (3, 2, [2, 5, 2]),
        (-1, 1, [2, 4, 6]),
        (-1, 2, [2, 3, 3]),
        (2, 3, [2, 2, 0]),
        (1, 2, [2, 1, 4]),
        (3, 1, [2, 0, 1]),
        (-1, 4, [1, 5, 5]),
        (-2, 3, [1, 4, 2]),
        (1, 1, [1, 3, 6]),
        (1, 1, [1, 2, 3]),
        (3, 4, [1, 1, 0]),
        (-1, 3, [1, 0, 4]),
        (-1, 1, [0, 5, 1]),
        (2, 1, [0, 4, 5]),
        (1, 4, [0, 3, 2]),
        (1, 1, [0, 2, 6]),
        (-1, 2, [0, 1, 3]),
        (-2, 1, [0, 0, 0]),
      ])
      (
        3000,
        fn() {
          let actual = @poly.monic(input)
          if actual != wanted {
            abort("Fraction full monic result mismatch")
          }
          polynomial_json(actual)
        },
      )
    }
    "fallback-dense" => {
      let input = polynomial(2, [
        (-3, 1, [0, 0]),
        (-1, 1, [0, 1]),
        (-1, 3, [0, 2]),
        (2, 1, [0, 3]),
        (1, 2, [1, 0]),
        (2, 3, [1, 1]),
        (3, 1, [1, 2]),
        (-3, 2, [1, 3]),
        (-2, 3, [2, 0]),
        (-1, 1, [2, 1]),
        (1, 1, [2, 2]),
        (1, 3, [2, 3]),
        (2, 1, [3, 0]),
        (3, 2, [3, 1]),
        (-1, 1, [3, 2]),
        (-2, 1, [3, 3]),
        (-1, 2, [4, 0]),
        (2, 3, [4, 1]),
        (1, 1, [4, 2]),
        (1, 1, [4, 3]),
        (1, 1, [5, 0]),
        (-3, 1, [5, 1]),
        (-1, 1, [5, 2]),
        (-1, 3, [5, 3]),
        (-1, 1, [7, 0]),
        (2, 3, [8, 0]),
      ])
      let wanted = polynomial(2, [
        (1, 1, [8, 0]),
        (-3, 2, [7, 0]),
        (-1, 2, [5, 3]),
        (-3, 2, [5, 2]),
        (-9, 2, [5, 1]),
        (3, 2, [5, 0]),
        (3, 2, [4, 3]),
        (3, 2, [4, 2]),
        (1, 1, [4, 1]),
        (-3, 4, [4, 0]),
        (-3, 1, [3, 3]),
        (-3, 2, [3, 2]),
        (9, 4, [3, 1]),
        (3, 1, [3, 0]),
        (1, 2, [2, 3]),
        (3, 2, [2, 2]),
        (-3, 2, [2, 1]),
        (-1, 1, [2, 0]),
        (-9, 4, [1, 3]),
        (9, 2, [1, 2]),
        (1, 1, [1, 1]),
        (3, 4, [1, 0]),
        (3, 1, [0, 3]),
        (-1, 2, [0, 2]),
        (-3, 2, [0, 1]),
        (-9, 2, [0, 0]),
      ])
      (
        1500,
        fn() {
          let actual = @poly.monic(input)
          if actual != wanted {
            abort("Fraction full monic result mismatch")
          }
          polynomial_json(actual)
        },
      )
    }
    "zero-tiny-controls" => {
      let input0 = polynomial(0, [])
      let wanted0 = polynomial(0, [])
      let input1 = polynomial(0, [(1, 1, [])])
      let wanted1 = polynomial(0, [(1, 1, [])])
      let input2 = polynomial(0, [(-1, 1, [])])
      let wanted2 = polynomial(0, [(1, 1, [])])
      let input3 = polynomial(0, [(2, 3, [])])
      let wanted3 = polynomial(0, [(1, 1, [])])
      let input4 = polynomial(1, [(1, 1, [7])])
      let wanted4 = polynomial(1, [(1, 1, [7])])
      let input5 = polynomial(3, [(1, 1, [2, 4, 7]), (-5, 7, [1, 8, 0])])
      let wanted5 = polynomial(3, [(1, 1, [2, 4, 7]), (-5, 7, [1, 8, 0])])
      (
        5000,
        fn() {
          let actual0 = @poly.monic(input0)
          if actual0 != wanted0 {
            abort("zero/tiny/negative monic mismatch")
          }
          let actual1 = @poly.monic(input1)
          if actual1 != wanted1 {
            abort("zero/tiny/negative monic mismatch")
          }
          let actual2 = @poly.monic(input2)
          if actual2 != wanted2 {
            abort("zero/tiny/negative monic mismatch")
          }
          let actual3 = @poly.monic(input3)
          if actual3 != wanted3 {
            abort("zero/tiny/negative monic mismatch")
          }
          let actual4 = @poly.monic(input4)
          if actual4 != wanted4 {
            abort("zero/tiny/negative monic mismatch")
          }
          let actual5 = @poly.monic(input5)
          if actual5 != wanted5 {
            abort("zero/tiny/negative monic mismatch")
          }
          "[" +
          polynomial_json(actual0) +
          "," +
          polynomial_json(actual1) +
          "," +
          polynomial_json(actual2) +
          "," +
          polynomial_json(actual3) +
          "," +
          polynomial_json(actual4) +
          "," +
          polynomial_json(actual5) +
          "]"
        },
      )
    }
    "resultant-caller" => {
      let left = polynomial(1, [(1, 1, [2]), (-2, 1, [0])])
      let right = polynomial(1, [(1, 1, [1]), (-1, 1, [0])])
      let wanted = polynomial(1, [(1, 1, [2]), (-2, 1, [1]), (-1, 1, [0])])
      let samples = @oracle.chain([
        @oracle.rational(-1, 1),
        @oracle.rational(-2, 1),
        @oracle.rational(-1, 1),
      ])
      (
        500,
        fn() {
          let state = @real.resultant_start(left, right, @real.Sum).unwrap()
          match @real.resultant_advance(state, @oracle.nat(8)).unwrap() {
            ResultantReady(proof) => {
              if proof.left != left ||
                proof.right != right ||
                proof.polynomial != wanted ||
                proof.samples != samples ||
                proof.operation != @real.Sum ||
                !@real.check_resultant(proof) {
                abort("independent full resultant certificate mismatch")
              }
              "[" +
              polynomial_json(proof.left) +
              "," +
              polynomial_json(proof.right) +
              "," +
              polynomial_json(proof.polynomial) +
              ",[-1,-2,-1]]"
            }
            _ => abort("resultant fuel unexpectedly paused")
          }
        },
      )
    }
    _ => abort("unknown monic case")
  }
  let expected = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("unstable complete monic output")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
