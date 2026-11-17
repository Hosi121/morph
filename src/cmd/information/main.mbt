///|
fn q(n : Int32, d : Int32) -> @exact.Rational {
  @oracle.rational(n, d)
}

///|
fn rational_text(value : @exact.Rational) -> String {
  let n = @oracle.int_of_integer(@exact.numerator(value))
  let d = @oracle.int_of_binary(@exact.denominator(value))
  if d == 1 {
    n.to_string()
  } else {
    "\{n}/\{d}"
  }
}

///|
fn vector_text(values : @core.Chain[@exact.Rational]) -> String {
  "[" + @oracle.array(values).map(rational_text).join(", ") + "]"
}

///|
fn matrix_text(value : @matrix.Matrix[@exact.Rational]) -> String {
  "[" + @oracle.array(@matrix.rows(value)).map(vector_text).join(", ") + "]"
}

///|
fn binary_hex(value : @binary.Binary) -> String {
  let bits = @oracle.array(@core.reverse(@binary.bits(value)))
  if bits.is_empty() {
    return "0"
  }
  let padded = Array::make((4 - bits.length() % 4) % 4, false)
  for bit in bits {
    padded.push(bit)
  }
  @oracle.hex_bits(@oracle.chain(padded))
}

///|
fn rational_json(value : @exact.Rational) -> String {
  let n = @exact.numerator(value)
  "[\{@exact.negative(n)},\"\{binary_hex(@exact.magnitude(n))}\",\"\{binary_hex(@exact.denominator(value))}\"]"
}

///|
fn vector_json(values : @core.Chain[@exact.Rational]) -> String {
  "[" + @oracle.array(values).map(rational_json).join(",") + "]"
}

///|
fn matrix_json(value : @matrix.Matrix[@exact.Rational]) -> String {
  "[" + @oracle.array(@matrix.rows(value)).map(vector_json).join(",") + "]"
}

///|
fn simplex(parameters : Array[@exact.Rational]) -> @infogeom.ModelPoint {
  let d = parameters.length()
  let vars = @oracle.nat(d)
  let zero = Array::make(d, 0)
  let outcomes = [
    for i in 0..<d => {
      let powers = zero.copy()
      powers[i] = 1
      @polynomial.polynomial(
        vars,
        @oracle.chain([
          {
            coefficient: q(1, 1),
            exponents: @oracle.chain(powers.map(@oracle.nat)),
          },
        ]),
      ).unwrap()
    }
  ]
  let rest : Array[@polynomial.Term] = [
    { coefficient: q(1, 1), exponents: @oracle.chain(zero.map(@oracle.nat)), },
  ]
  for i in 0..<d {
    let powers = zero.copy()
    powers[i] = 1
    rest.push({
      coefficient: q(-1, 1),
      exponents: @oracle.chain(powers.map(@oracle.nat)),
    })
  }
  outcomes.push(@polynomial.polynomial(vars, @oracle.chain(rest)).unwrap())
  @infogeom.at(
    @infogeom.family(vars, @oracle.chain(outcomes)).unwrap(),
    @oracle.chain(parameters),
  ).unwrap()
}

///|
fn standard_gaussian(d : Int32) -> @gaussian.Gaussian {
  let rows = [
    for i in 0..<d => {
      @oracle.chain(
        [
          for j in 0..<d => if i == j { q(1, 1) } else { q(0, 1) }
        ],
      )
    }
  ]
  @gaussian.gaussian(
    @oracle.chain(Array::make(d, q(0, 1))),
    @matrix.matrix(@oracle.nat(d), @oracle.chain(rows)).unwrap(),
  ).unwrap()
}

///|
fn geometry_json(value : @riemann.Curvature) -> String {
  let metric = @riemann.metric(
    @riemann.connection_jet(@riemann.curvature_connection(value)),
  )
  let flat : Array[@exact.Rational] = []
  for t in @oracle.array(@riemann.lowered_riemann(value)) {
    for m in @oracle.array(t) {
      for row in @oracle.array(m) {
        for value in @oracle.array(row) {
          flat.push(value)
        }
      }
    }
  }
  "{\"metric\":" +
  matrix_json(metric) +
  ",\"lower_riemann\":" +
  vector_json(@oracle.chain(flat)) +
  ",\"ricci\":[" +
  @oracle.array(@riemann.ricci(value)).map(vector_json).join(",") +
  "],\"scalar\":" +
  rational_json(@riemann.scalar_curvature(value)) +
  ",\"contracted\":" +
  rational_json(@statgeometry.scalar_by_contraction(value).unwrap()) +
  "}"
}

///|
fn benchmark_case(name : String) -> (Int32, () -> String) {
  match name {
    "lc-simplex2" =>
      (
        200,
        fn() {
          geometry_json(
            @statgeometry.curvature(simplex([q(1, 4), q(1, 4)])).unwrap(),
          )
        },
      )
    "alpha-simplex2" =>
      (
        200,
        fn() {
          let point = simplex([q(1, 4), q(1, 4)])
          let value = @statgeometry.alpha_geometry(point, q(2, 1)).unwrap()
          "{\"metric\":" +
          matrix_json(@infogeom.fisher(@statgeometry.alpha_model(value))) +
          ",\"coefficients\":" +
          vector_json(@tensor.entries(@statgeometry.alpha_coefficients(value))) +
          ",\"lower_riemann\":" +
          vector_json(
            @tensor.entries(@statgeometry.alpha_lowered_riemann(value)),
          ) +
          ",\"ricci\":" +
          matrix_json(@statgeometry.alpha_ricci(value)) +
          ",\"scalar\":" +
          rational_json(@statgeometry.alpha_scalar(value)) +
          "}"
        },
      )
    "cubic-pullback3" =>
      (
        150,
        fn() {
          let model = @infogeom.local_model(
            simplex([q(1, 5), q(1, 5), q(1, 5)]),
          )
          let jacobian = @matrix.matrix(
            @oracle.nat(3),
            @oracle.chain([
              @oracle.chain([q(1, 1), q(1, 3), q(0, 1)]),
              @oracle.chain([q(0, 1), q(1, 1), q(1, 2)]),
              @oracle.chain([q(1, 4), q(0, 1), q(1, 1)]),
            ]),
          ).unwrap()
          vector_json(
            @tensor.entries(
              @statgeometry.pullback_cubic(model, jacobian).unwrap(),
            ),
          )
        },
      )
    "gaussian2" =>
      (
        10,
        fn() {
          let jet = @gaussian.fisher_jet(standard_gaussian(2)).unwrap()
          let first = @oracle.array(@riemann.first_derivatives(jet))
            .map(matrix_json)
            .join(",")
          let second = @oracle.array(@riemann.second_derivatives(jet))
            .map(fn(row) {
              "[" + @oracle.array(row).map(matrix_json).join(",") + "]"
            })
            .join(",")
          "{\"metric\":" +
          matrix_json(@riemann.metric(jet)) +
          ",\"first\":[" +
          first +
          "],\"second\":[" +
          second +
          "]}"
        },
      )
    "scalar0" =>
      (
        1000,
        fn() { geometry_json(@statgeometry.curvature(simplex([])).unwrap()) },
      )
    _ => abort("unknown information benchmark case")
  }
}

///|
fn demo() -> Unit {
  let prior = @probability.distribution(@oracle.chain([q(1, 3), q(2, 3)])).unwrap()
  let posterior = @probability.bayes(prior, @oracle.chain([q(1, 4), q(3, 4)])).unwrap()
  println("Bayes posterior = " + vector_text(@probability.masses(posterior)))
  let point = simplex([q(1, 6), q(1, 3)])
  println(
    "Simplex Fisher (mixture coordinates) = " +
    matrix_text(@infogeom.fisher(@infogeom.local_model(point))),
  )
  let cubic = @statgeometry.amari_chentsov(@infogeom.local_model(point)).unwrap()
  println(
    "Simplex Amari-Chentsov squared norm = " +
    rational_text(cubic.norm_squared()),
  )
  println("Simplex Amari-Chentsov trace = " + vector_text(cubic.trace()))
  for alpha in [-1, 0, 1, 2] {
    let value = @statgeometry.alpha_geometry(point, q(alpha, 1)).unwrap()
    println(
      "Simplex alpha=\{alpha}, scalar curvature = " +
      rational_text(@statgeometry.alpha_scalar(value)),
    )
  }
  let normal = @gaussian.fisher_jet(standard_gaussian(1)).unwrap()
  println(
    "Gaussian Amari-Chentsov squared norm = " +
    rational_text(
      @statgeometry.gaussian_amari_chentsov(standard_gaussian(1))
      .unwrap()
      .norm_squared(),
    ),
  )
  println(
    "Gaussian Fisher (natural coordinates) = " +
    matrix_text(@riemann.metric(normal)),
  )
  println(
    "Gaussian scalar curvature = " +
    rational_text(
      @riemann.scalar_curvature(@riemann.curvature(@riemann.connection(normal))),
    ),
  )
  let kernel = @markov.kernel(
    @oracle.chain([
      @oracle.chain([q(3, 4), q(1, 4)]),
      @oracle.chain([q(1, 2), q(1, 2)]),
    ]),
  ).unwrap()
  let stationary = @markov.unique_stationary(kernel).unwrap()
  if !@markov.check_stationary(kernel, stationary) {
    abort("stationary checker")
  }
  println("Markov stationary = " + vector_text(stationary))
  let hitting = @markov.hitting(kernel, @oracle.chain([@oracle.nat(1)])).unwrap()
  if !@markov.check_hitting(kernel, @oracle.chain([@oracle.nat(1)]), hitting) {
    abort("hitting checker")
  }
  println(
    "Target hitting probabilities = " +
    vector_text(@markov.hitting_probabilities(hitting)),
  )
  let times = @oracle.array(@markov.expected_hitting_times(hitting)).map(fn(
    time,
  ) {
    match time {
      @markov.Finite(value) => rational_text(value)
      @markov.Infinite => "infinity"
    }
  })
  println("Expected hitting times = [" + times.join(", ") + "]")
}

///|
fn main {
  let args = @env.args()
  if args.length() >= 3 && args[args.length() - 2] == "--benchmark" {
    let name = args[args.length() - 1]
    let (iterations, operation) = benchmark_case(name)
    let wanted = operation()
    for _ in 0..<iterations {
      if operation() != wanted {
        abort("information result changed during repetition")
      }
    }
    println(
      "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"result\":" +
      wanted +
      "}",
    )
  } else {
    demo()
  }
}
