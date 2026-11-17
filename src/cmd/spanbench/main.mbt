///|
/// Public-API benchmark host. Setup is outside elapsed_us; every timed iteration
/// computes and checks the complete canonical result. No incremental API here.
fn polynomial(
  n : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(n),
    @oracle.chain(
      terms.map(fn(t) {
        @poly.Term::{
          coefficient: @oracle.rational(t.0, 1),
          exponents: @oracle.chain(t.1.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn univariate(cs : Array[Int32]) -> @poly.Polynomial {
  polynomial(1, [ for i, c in cs => (c, [i]) ])
}

///|
fn real_field(d : Int32) -> @nf.Field {
  let cs = Array::make(d + 1, 0)
  cs[0] = if d == 1 { 0 } else { -2 }
  cs[d] = 1
  let root : @real.RootCertificate = {
    polynomial: univariate(cs),
    interval: {
      lower: @oracle.rational(if d == 1 { -1 } else { 1 }, 1),
      upper: @oracle.rational(if d == 1 { 1 } else { 2 }, 1),
    },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(100),
      @oracle.nat(1000),
      @oracle.nat(1000),
    ).unwrap() {
    Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(1000)).unwrap()
    _ => abort("field setup unresolved")
  }
}

///|
fn vector_json(v : @core.Chain[@core.Nat]) -> String {
  "[" +
  @oracle.array(v).map(fn(n) { @oracle.int_of_nat(n).to_string() }).join(",") +
  "]"
}

///|
fn rational_json(q : @exact.Rational) -> String {
  "[\{@oracle.int_of_integer(@exact.numerator(q))},\{@oracle.int_of_binary(@exact.denominator(q))}]"
}

///|
fn polynomial_json(p : @poly.Polynomial) -> String {
  "[" +
  @oracle.array(@poly.terms(p))
  .map(fn(t) { "[\{rational_json(t.coefficient)},\{vector_json(t.exponents)}]" })
  .join(",") +
  "]"
}

///|
fn source(n : Int32, inputs : Array[@poly.Polynomial]) -> @f4.Basis {
  match
    @f4.f4(@oracle.nat(n), @oracle.chain(inputs), @oracle.nat(1000)).unwrap() {
    Complete(b) => b
    _ => abort("source F4 incomplete")
  }
}

///|
fn fglm_json(b : @fglm.Basis) -> String {
  let c = @fglm.certificate(b)
  let stats = @fglm.statistics(b)
  let ps = "[" +
    @oracle.array(@fglm.polynomials(b)).map(polynomial_json).join(",") +
    "]"
  let standards = "[" +
    @oracle.array(@fglm.standard_monomials(b)).map(vector_json).join(",") +
    "]"
  let source_standards = "[" +
    @oracle.array(@fglm.source_standard_monomials(b)).map(vector_json).join(",") +
    "]"
  let relations = "[" +
    @oracle.array(c.relations)
    .map(fn(r) {
      let monomials = "[" +
        @oracle.array(r.standard_monomials).map(vector_json).join(",") +
        "]"
      let cs = "[" +
        @oracle.array(r.coefficients).map(rational_json).join(",") +
        "]"
      "[\{vector_json(r.monomial)},\{monomials},\{cs}]"
    })
    .join(",") +
    "]"
  "{\"polynomials\":\{ps},\"standards\":\{standards},\"source_standards\":\{source_standards},\"relations\":\{relations},\"statistics\":[\{@oracle.int_of_nat(stats.processed)},\{@oracle.int_of_nat(stats.independent)},\{@oracle.int_of_nat(stats.dependent)},\{@oracle.int_of_nat(stats.skipped)}]}"
}

///|
fn main {
  let args = @env.args()
  let name = args[args.length() - 1]
  let (iterations, operation) : (Int32, () -> String) = match name {
    "nf2" | "nf6" | "nf6-subfield" => {
      let f = real_field(if name == "nf2" { 2 } else { 6 })
      let g = @nf.generator(f).unwrap()
      let value = if name == "nf6-subfield" {
        @nf.multiply(g, g).unwrap()
      } else {
        @nf.add(g, @nf.one(f)).unwrap()
      }
      let expected = univariate(
        match name {
          "nf2" => [-1, -2, 1]
          "nf6" => [-1, -6, 15, -20, 15, -6, 1]
          _ => [-2, 0, 0, 1]
        },
      )
      (
        if name == "nf2" {
          100
        } else {
          30
        },
        fn() {
          let p = @nf.minimal_polynomial(value).unwrap()
          if !p.equal(expected) || !@nf.check_minimal_polynomial(value, p) {
            abort("NF canonical result/check failed")
          }
          polynomial_json(p)
        },
      )
    }
    "cf2-tiny" | "cf4" | "cf8" => {
      let k = real_field(
        if name == "cf2-tiny" {
          1
        } else if name == "cf4" {
          2
        } else {
          4
        },
      )
      let f = @cf.field(k)
      let value = @cf.element(f, @nf.generator(k).unwrap(), @nf.one(k)).unwrap()
      let expected = univariate(
        match name {
          "cf2-tiny" => [1, 0, 1]
          "cf4" => [9, 0, -2, 0, 1]
          _ => [1, 0, 28, 0, 2, 0, 4, 0, 1]
        },
      )
      (
        if name == "cf2-tiny" {
          100
        } else if name == "cf4" {
          50
        } else {
          10
        },
        fn() {
          let p = @cf.minimal_polynomial(value).unwrap()
          if !p.equal(expected) || !@cf.check_minimal_polynomial(value, p) {
            abort("CF canonical result/check failed")
          }
          polynomial_json(p)
        },
      )
    }
    "fglm3" | "fglm8" => {
      let higher = name == "fglm8"
      let n = if higher { 3 } else { 2 }
      let s = if higher {
        source(n, [
          polynomial(n, [(1, [1, 0, 0]), (-1, [0, 0, 4])]),
          polynomial(n, [(1, [0, 1, 0]), (-1, [0, 0, 3])]),
          polynomial(n, [(1, [0, 0, 8]), (-1, [0, 0, 0])]),
        ])
      } else {
        source(n, [
          polynomial(n, [(1, [2, 0]), (-1, [0, 1])]),
          polynomial(n, [(1, [1, 1]), (-1, [0, 0])]),
        ])
      }
      let expected = if higher {
        @oracle.chain([
          polynomial(n, [(1, [1, 2, 0]), (-1, [0, 0, 2])]),
          polynomial(n, [(1, [0, 3, 0]), (-1, [0, 0, 1])]),
          polynomial(n, [(1, [1, 0, 2]), (-1, [0, 2, 0])]),
          polynomial(n, [(1, [0, 0, 3]), (-1, [0, 1, 0])]),
          polynomial(n, [(1, [2, 0, 0]), (-1, [0, 0, 0])]),
          polynomial(n, [(1, [0, 1, 1]), (-1, [1, 0, 0])]),
        ])
      } else {
        @oracle.chain([
          polynomial(n, [(1, [2, 0]), (-1, [0, 1])]),
          polynomial(n, [(1, [1, 1]), (-1, [0, 0])]),
          polynomial(n, [(1, [0, 2]), (-1, [1, 0])]),
        ])
      }
      (
        if higher {
          3
        } else {
          15
        },
        fn() {
          let b = match
            @fglm.convert(s, @fglm.GrevLex, @oracle.nat(8), @oracle.nat(1000)).unwrap() {
            Complete(b) => b
            _ => abort("FGLM incomplete")
          }
          if !@fglm.polynomials(b).equal(expected) ||
            @fglm.verify(b) != Ok(true) ||
            @oracle.int_of_nat(@fglm.dimension(b)) !=
            (if higher { 8 } else { 3 }) {
            abort("FGLM canonical result/check failed")
          }
          fglm_json(b)
        },
      )
    }
    _ => abort("unknown span benchmark case")
  }
  let expected = operation()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<iterations {
    if operation() != expected {
      abort("unstable full result")
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":\{expected},\"elapsed_us\":\{elapsed_us},\"checked\":true}",
  )
}
