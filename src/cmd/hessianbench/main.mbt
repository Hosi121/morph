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
fn vector_json(value : @core.Chain[@exact.Rational]) -> String {
  "[" + @oracle.array(value).map(rational_json).join(",") + "]"
}

///|
fn matrix_json(value : @matrix.Matrix[@exact.Rational]) -> String {
  "[" + @oracle.array(@matrix.rows(value)).map(vector_json).join(",") + "]"
}

///|
fn standard(n : Int32) -> @gaussian.Gaussian {
  let mean = @oracle.chain(Array::make(n, @oracle.rational(0, 1)))
  let rows = @oracle.chain(
    Array::makei(n, fn(i) {
      @oracle.chain(
        Array::makei(n, fn(j) {
          @oracle.rational(if i == j { 1 } else { 0 }, 1)
        }),
      )
    }),
  )
  @gaussian.gaussian(mean, @matrix.matrix(@oracle.nat(n), rows).unwrap()).unwrap()
}

///|
fn flatten(value : @riemann.Tensor4) -> @core.Chain[@exact.Rational] {
  @core.fold_left(value, @core.Nil, fn(result, tensor) {
    @core.fold_left(tensor, result, fn(result, matrix) {
      @core.fold_left(matrix, result, @core.append)
    })
  })
}

///|
fn general(source : @gaussian.Gaussian, kind : String) -> String {
  let jet = @gaussian.fisher_jet(source).unwrap()
  let value = @riemann.curvature(@riemann.connection(jet))
  let metric = matrix_json(@riemann.metric(jet))
  if kind == "scalar" {
    return "{\"metric\":" +
      metric +
      ",\"scalar\":" +
      rational_json(@riemann.scalar_curvature(value)) +
      "}"
  }
  if kind == "action" {
    let result = @core.map(@core.indices(@riemann.dimension(jet)), fn(r) {
      @riemann.component4(
        @riemann.riemann(value),
        r,
        @core.Zero,
        @core.Zero,
        @core.Succ(@core.Succ(@core.Zero)),
      ).unwrap()
    })
    return "{\"metric\":" + metric + ",\"action\":" + vector_json(result) + "}"
  }
  let ricci = @matrix.matrix(@riemann.dimension(jet), @riemann.ricci(value)).unwrap()
  "{\"metric\":" +
  metric +
  ",\"riemann\":" +
  vector_json(flatten(@riemann.riemann(value))) +
  ",\"ricci\":" +
  matrix_json(ricci) +
  ",\"scalar\":" +
  rational_json(@riemann.scalar_curvature(value)) +
  "}"
}

///|
fn structured(source : @gaussian.Gaussian, kind : String) -> String {
  let point = @statgeometry.gaussian_hessian(
    @gaussian.information(source).unwrap(),
  ).unwrap()
  let value = point.curvature(@oracle.rational(0, 1))
  let metric = matrix_json(point.metric())
  if kind == "scalar" {
    return "{\"metric\":" +
      metric +
      ",\"scalar\":" +
      rational_json(value.scalar()) +
      "}"
  }
  if kind == "action" {
    let d = @oracle.int_of_nat(point.dimension())
    let u = point
      .tangent(
        @oracle.chain(
          Array::makei(d, fn(i) {
            @oracle.rational(if i == 0 { 1 } else { 0 }, 1)
          }),
        ),
      )
      .unwrap()
    let v = point
      .tangent(
        @oracle.chain(
          Array::makei(d, fn(i) {
            @oracle.rational(if i == 2 { 1 } else { 0 }, 1)
          }),
        ),
      )
      .unwrap()
    return "{\"metric\":" +
      metric +
      ",\"action\":" +
      vector_json(value.apply(u, v, u).unwrap().components()) +
      "}"
  }
  "{\"metric\":" +
  metric +
  ",\"riemann\":" +
  vector_json(@tensor.entries(value.riemann())) +
  ",\"ricci\":" +
  matrix_json(value.ricci().unwrap()) +
  ",\"scalar\":" +
  rational_json(value.scalar()) +
  "}"
}

///|
fn main {
  let args = @env.args()
  let route = args[args.length() - 2]
  let name = args[args.length() - 1]
  let (n, kind, iterations) = match name {
    "scalar1" => (1, "scalar", 20)
    "scalar2" => (2, "scalar", 2)
    "full2" => (2, "full", 1)
    "action2" => (2, "action", 2)
    _ => abort("unknown case")
  }
  let source = standard(n)
  let answers = []
  for _ in 0..<iterations {
    answers.push(
      match route {
        "general" => general(source, kind)
        "structured" => structured(source, kind)
        _ => abort("unknown route")
      },
    )
  }
  println(
    "{\"case\":\"\{name}\",\"iterations\":\{iterations},\"results\":[" +
    answers.join(",") +
    "]}",
  )
}
