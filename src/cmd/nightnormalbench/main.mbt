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
    "univariate-dense" => {
      let p = polynomial(1, [
        (-2, 1, [0]),
        (-1, 1, [1]),
        (0, 1, [2]),
        (1, 1, [3]),
        (2, 1, [4]),
        (-2, 1, [5]),
        (-1, 1, [6]),
        (0, 1, [7]),
        (1, 1, [8]),
        (2, 1, [9]),
        (-2, 1, [10]),
        (-1, 1, [11]),
        (0, 1, [12]),
      ])
      let gs = @oracle.chain([
        polynomial(1, [(1, 1, [4]), (-10, 1, [2]), (1, 1, [0])]),
      ])
      let expected = polynomial(1, [
        (-7760, 1, [3]),
        (-18501, 1, [2]),
        (783, 1, [1]),
        (1867, 1, [0]),
      ])
      if @poly.divide(p, gs).unwrap().remainder != expected {
        abort("frozen generic division oracle mismatch")
      }
      (
        12000,
        fn() {
          let result = @poly.normal_form(p, gs).unwrap()
          if result != expected {
            abort("full Fraction remainder differs")
          }
          polynomial_json(result)
        },
      )
    }
    "rational-nonmonic" => {
      let p = polynomial(1, [
        (1, 2, [9]),
        (-2, 3, [5]),
        (1, 3, [1]),
        (2, 5, [0]),
      ])
      let gs = @oracle.chain([polynomial(1, [(2, 3, [2]), (-3, 2, [0])])])
      let expected = polynomial(1, [(15011, 1536, [1]), (2, 5, [0])])
      if @poly.divide(p, gs).unwrap().remainder != expected {
        abort("frozen generic division oracle mismatch")
      }
      (
        12000,
        fn() {
          let result = @poly.normal_form(p, gs).unwrap()
          if result != expected {
            abort("full Fraction remainder differs")
          }
          polynomial_json(result)
        },
      )
    }
    "multivariate-order" => {
      let p = polynomial(2, [
        (1, 1, [4, 0]),
        (2, 1, [2, 3]),
        (-1, 1, [0, 5]),
        (3, 1, [0, 0]),
      ])
      let gs = @oracle.chain([
        polynomial(2, [(2, 1, [1, 0]), (-1, 1, [0, 1])]),
        polynomial(2, [(3, 1, [0, 2]), (-2, 1, [0, 0])]),
      ])
      let expected = polynomial(2, [(-2, 9, [0, 1]), (109, 36, [0, 0])])
      if @poly.divide(p, gs).unwrap().remainder != expected {
        abort("frozen generic division oracle mismatch")
      }
      (
        20000,
        fn() {
          let result = @poly.normal_form(p, gs).unwrap()
          if result != expected {
            abort("full Fraction remainder differs")
          }
          polynomial_json(result)
        },
      )
    }
    "no-reduction" => {
      let p = polynomial(3, [
        (1, 1, [1, 0, 0]),
        (1, 1, [0, 1, 0]),
        (1, 1, [0, 0, 1]),
        (1, 1, [0, 0, 0]),
      ])
      let gs = @oracle.chain([
        polynomial(3, [(1, 1, [2, 0, 0]), (1, 1, [0, 2, 0]), (1, 1, [0, 0, 2])]),
      ])
      let expected = polynomial(3, [
        (1, 1, [1, 0, 0]),
        (1, 1, [0, 1, 0]),
        (1, 1, [0, 0, 1]),
        (1, 1, [0, 0, 0]),
      ])
      if @poly.divide(p, gs).unwrap().remainder != expected {
        abort("frozen generic division oracle mismatch")
      }
      (
        150000,
        fn() {
          let result = @poly.normal_form(p, gs).unwrap()
          if result != expected {
            abort("full Fraction remainder differs")
          }
          polynomial_json(result)
        },
      )
    }
    "edge-errors" => {
      let constant = polynomial(0, [(5, 7, [])])
      let zero = @poly.zero(@oracle.nat(2))
      let wrong = @poly.zero(@oracle.nat(1))
      (
        100000,
        fn() {
          if @poly.normal_form(constant, Nil) != Ok(constant) ||
            @poly.normal_form(zero, Nil) != Ok(zero) ||
            @poly.normal_form(zero, Cons(zero, Nil)) != Err(@poly.ZeroDivisor) ||
            @poly.normal_form(zero, Cons(wrong, Cons(zero, Nil))) !=
            Err(@poly.DimensionMismatch) {
            abort("error precedence or empty case changed")
          }
          "[\"constant 5/7\",\"zero\",\"ZeroDivisor\",\"DimensionMismatch\"]"
        },
      )
    }
    "buchberger" => {
      let gs = @oracle.chain([
        polynomial(2, [(1, 1, [2, 0]), (-1, 1, [0, 1])]),
        polynomial(2, [(1, 1, [1, 1]), (-1, 1, [0, 0])]),
      ])
      // Existing independently generated SymPy 1.14 QQ reduced-lex fixture.
      let expected = @oracle.chain([
        polynomial(2, [(1, 1, [1, 0]), (-1, 1, [0, 2])]),
        polynomial(2, [(1, 1, [0, 3]), (-1, 1, [0, 0])]),
      ])
      for p in @oracle.array(gs) {
        if !@poly.is_zero(@poly.divide(p, expected).unwrap().remainder) {
          abort("unchanged divide rejected ideal membership")
        }
      }
      (
        4000,
        fn() {
          let b = match
            @gb.buchberger(@oracle.nat(2), gs, @oracle.nat(1000)).unwrap() {
            Complete(b) => b
            _ => abort("Buchberger incomplete")
          }
          if @gb.polynomials(b) != expected || @gb.verify(b) != Ok(true) {
            abort("full independent basis/check mismatch")
          }
          "[" +
          @oracle.array(@gb.polynomials(b)).map(polynomial_json).join(",") +
          "]"
        },
      )
    }
    _ => abort("unknown normal form benchmark case")
  }
  // Setup, unchanged divide warmup oracle, expected construction and one checked
  // warmup are included in process timing. Repeats include full comparisons,
  // JSON conversion and the public producer verifier where applicable.
  let expected = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("unstable full checked output")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
