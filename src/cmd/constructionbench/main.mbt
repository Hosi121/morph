///|
fn bits(n : Int32, d : Int32) -> @core.Chain[Bool] {
  @oracle.chain(Array::makei(d, fn(i) { (n & (1 << i)) != 0 }))
}

///|
fn encoded(values : @core.Chain[Bool]) -> Int32 {
  let mut n = 0
  for i, bit in @oracle.array(values) {
    if bit {
      n = n | (1 << i)
    }
  }
  n
}

///|
fn finite(p : Int32, coefficients : Array[Int32]) -> @galois.Field {
  let base = @primefield.field(@oracle.binary(p)).unwrap()
  let f = @fppoly.polynomial(
    base,
    @oracle.chain(coefficients.map(@oracle.binary)),
  )
  @galois.extension(f, @fppoly.irreducibility(f).unwrap().unwrap()).unwrap()
}

///|
fn real_field(d : Int32) -> @nf.Field {
  let values = if d == 2 { [-2, 0, 1] } else { [1, 0, -10, 0, 1] }
  let f = @bridge.rational_polynomial(
    @oracle.chain(values.map(fn(x) { @oracle.rational(x, 1) })),
  ).unwrap()
  let root : @real.RootCertificate = {
    polynomial: f,
    interval: {
      lower: @oracle.rational(if d == 2 { 1 } else { 3 }, 1),
      upper: @oracle.rational(if d == 2 { 2 } else { 4 }, 1),
    },
  }
  match
    @minimal.normalize_root(
      root,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @nf.field_result(value, proof, @oracle.nat(256)).unwrap()
    _ => abort("fixture unresolved")
  }
}

///|
fn main {
  let args = @env.args()
  let mode = args[args.length() - 2]
  let route = args[args.length() - 1]
  let mut elapsed = 0.0
  let output : Array[Array[Int32]] = if mode == "gf2-d4" || mode == "gf2-d8" {
    let d = if mode == "gf2-d4" { 4 } else { 8 }
    let source = finite(
      2,
      if d == 4 {
        [1, 1, 0, 0, 1]
      } else {
        [1, 1, 0, 1, 1, 0, 0, 0, 1]
      },
    )
    let generic = @bridge.bit_extension(source, @q.Generic).unwrap()
    let fused = @bridge.bit_extension(source, @q.Carryless).unwrap()
    let inputs = Array::makei(64, fn(i) {
      let a = (i * 17 + 3) % (1 << d)
      let b = (i * 29 + 5) % (1 << d)
      let aa = @q.normalize(@bridge.bit_context(generic), bits(a, d)).unwrap()
      let bb = @q.normalize(@bridge.bit_context(generic), bits(b, d)).unwrap()
      let af = @q.normalize(@bridge.bit_context(fused), bits(a, d)).unwrap()
      let bf = @q.normalize(@bridge.bit_context(fused), bits(b, d)).unwrap()
      (
        aa,
        bb,
        af,
        bf,
        @bridge.leave_bits(generic, aa).unwrap(),
        @bridge.leave_bits(generic, bb).unwrap(),
      )
    })
    if route == "old" {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(32768, fn(i) {
        let (_, _, _, _, a, b) = inputs[i % 64]
        @galois.multiply(a, b).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) {
        [encoded(@q.coefficients(@bridge.enter_bits(fused, x).unwrap()))]
      })
    } else {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(32768, fn(i) {
        let (a, b, af, bf, _, _) = inputs[i % 64]
        @q.multiply(
          if route == "generic" {
            a
          } else {
            af
          },
          if route == "generic" {
            b
          } else {
            bf
          },
        ).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) { [encoded(@q.coefficients(x))] })
    }
  } else if mode == "fp5-d2" {
    let source = finite(5, [2, 0, 1])
    let extension = @bridge.prime_extension(source).unwrap()
    let inputs = Array::makei(25, fn(i) {
      let a = @galois.element(
        source,
        @fppoly.polynomial(
          @galois.prime_field(source),
          @oracle.chain([i % 5, i / 5].map(@oracle.binary)),
        ),
      ).unwrap()
      let b = @galois.element(
        source,
        @fppoly.polynomial(
          @galois.prime_field(source),
          @oracle.chain([(i * 3 + 1) % 5, (i * 2 + 4) % 5].map(@oracle.binary)),
        ),
      ).unwrap()
      (
        a,
        b,
        @bridge.enter_prime(extension, a).unwrap(),
        @bridge.enter_prime(extension, b).unwrap(),
      )
    })
    if route == "old" {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(16384, fn(i) {
        let (a, b, _, _) = inputs[i % 25]
        @galois.multiply(a, b).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) {
        @oracle.array(@fppoly.coefficients(@galois.representative(x))).map(
          @oracle.int_of_binary,
        )
      })
    } else {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(16384, fn(i) {
        let (_, _, a, b) = inputs[i % 25]
        @q.multiply(a, b).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) {
        @oracle.array(@q.coefficients(x)).map(@oracle.int_of_binary)
      })
    }
  } else {
    let d = if mode == "qq-d2" {
      2
    } else if mode == "qq-d4" {
      4
    } else {
      abort("unknown cohort")
    }
    let source = real_field(d)
    let extension = @bridge.real_extension(source).unwrap()
    let inputs = Array::makei(16, fn(i) {
      let aa = Array::makei(d, fn(j) {
        @oracle.rational((i * 3 + j * 2) % 5 - 2, 1)
      })
      let bb = Array::makei(d, fn(j) {
        @oracle.rational((i * 2 + j * 3 + 1) % 5 - 2, 1)
      })
      let a = @nf.element(
        source,
        @bridge.rational_polynomial(@oracle.chain(aa)).unwrap(),
      ).unwrap()
      let b = @nf.element(
        source,
        @bridge.rational_polynomial(@oracle.chain(bb)).unwrap(),
      ).unwrap()
      (
        a,
        b,
        @bridge.enter_real(extension, a).unwrap(),
        @bridge.enter_real(extension, b).unwrap(),
      )
    })
    if route == "old" {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(8192, fn(i) {
        let (a, b, _, _) = inputs[i % 16]
        @nf.multiply(a, b).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) {
        @oracle.array(@nf.coordinates(x)).map(fn(r) {
          @oracle.int_of_integer(@exact.numerator(r))
        })
      })
    } else {
      let started = @bench.monotonic_clock_start()
      let retained = Array::makei(8192, fn(i) {
        let (_, _, a, b) = inputs[i % 16]
        @q.multiply(a, b).unwrap()
      })
      elapsed = @bench.monotonic_clock_end(started)
      retained.map(fn(x) {
        let coefficients = @oracle.array(@q.coefficients(x))
        Array::makei(d, fn(j) {
          if j < coefficients.length() {
            @oracle.int_of_integer(@exact.numerator(coefficients[j]))
          } else {
            0
          }
        })
      })
    }
  }
  let json = "[" +
    output
    .map(fn(row) { "[" + row.map(fn(x) { x.to_string() }).join(",") + "]" })
    .join(",") +
    "]"
  println(
    "{\"case\":\"\{mode}\",\"route\":\"\{route}\",\"elapsed_us\":\{elapsed},\"outputs\":\{json}}",
  )
}
