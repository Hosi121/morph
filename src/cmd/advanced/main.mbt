///|
/// Ordinary numbers and strings here only adapt a few fixed demo inputs and
/// outputs. All the algorithms called below use the symbolic packages.
fn q(value : Int32) -> @exact.Rational {
  @oracle.rational(value, 1)
}

///|
fn poly(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for degree in 0..<coefficients.length() => {
          @poly.Term::{
            coefficient: q(coefficients[degree]),
            exponents: @core.Cons(@oracle.nat(degree), @core.Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn multivariate(
  variables : Int32,
  terms : Array[(Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      terms.map(fn(term) {
        let (coefficient, exponents) = term
        @poly.Term::{
          coefficient: q(coefficient),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn fraction_text(value : @exact.Rational) -> String {
  // These fixed examples have small displayable numerators and denominators.
  let numerator = @oracle.int_of_integer(@exact.numerator(value))
  let denominator = @oracle.int_of_binary(@exact.denominator(value))
  if denominator == 1 {
    numerator.to_string()
  } else {
    "\{numerator}/\{denominator}"
  }
}

///|
fn polynomial_text(value : @poly.Polynomial, names : Array[String]) -> String {
  let out = StringBuilder()
  let mut first = true
  for term in @oracle.array(@poly.terms(value)) {
    let negative = @exact.negative(@exact.numerator(term.coefficient))
    if first {
      if negative {
        out.write_string("-")
      }
    } else {
      out.write_string(if negative { " - " } else { " + " })
    }
    first = false
    let magnitude = if negative {
      @exact.rational_negate(term.coefficient)
    } else {
      term.coefficient
    }
    let factors : Array[String] = []
    let exponents = @oracle.array(term.exponents)
    for i in 0..<exponents.length() {
      let exponent = @oracle.int_of_nat(exponents[i])
      if exponent == 1 {
        factors.push(names[i])
      }
      if exponent > 1 {
        factors.push("\{names[i]}^\{exponent}")
      }
    }
    if factors.is_empty() || !magnitude.equal(q(1)) {
      factors.insert(0, fraction_text(magnitude))
    }
    out.write_string(factors.join("*"))
  }
  if first {
    "0"
  } else {
    out.to_string()
  }
}

///|
fn root(
  coefficients : Array[Int32],
  lower : Int32,
  upper : Int32,
) -> @real.Number {
  @real.number({
    polynomial: poly(coefficients),
    interval: { lower: q(lower), upper: q(upper), },
  }).unwrap()
}

///|
fn normalize(value : @real.Number) -> (@real.Number, @minimal.Certificate) {
  match
    @minimal.normalize(
      value,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(40),
      @oracle.nat(256),
      @oracle.nat(256),
    ).unwrap() {
    Normalized(number, proof) => {
      guard @minimal.check_normalization(value, number, proof, @oracle.nat(256))
        is Proven else {
        abort("minimal polynomial proof failed")
      }
      (number, proof)
    }
    Unresolved(_) => abort("demo factorization budget exhausted")
  }
}

///|
fn algebraic_numbers() -> Unit {
  let a = root([-2, 0, 1], 1, 2)
  let b = root([-3, 0, 1], 1, 2)
  let threshold = poly([-3, 2])
  let sign = @tarski.sign_at(a, threshold).unwrap()
  guard @tarski.check_sign_at(a, threshold, sign.sign, sign.certificate) else {
    abort("Tarski sign proof failed")
  }
  println(
    "sign(2*sqrt(2)-3): \{match sign.sign { Less => "negative"; Equal => "zero"; Greater => "positive" }}, proof=true",
  )
  match @real.add(a, b, @oracle.nat(256)).unwrap() {
    ArithmeticReady(sum, proof) => {
      guard @real.check_arithmetic_result(sum, proof) else {
        abort("sum proof failed")
      }
      println(
        "sqrt(2)+sqrt(3): \{polynomial_text(@real.definition(sum), ["z"])} = 0, proof=true",
      )
    }
    _ => abort("demo addition budget exhausted")
  }
  match @real.multiply(a, a, @oracle.nat(256)).unwrap() {
    ArithmeticReady(square, proof) => {
      guard @real.check_arithmetic_result(square, proof) else {
        abort("product proof failed")
      }
      let (small, _) = normalize(square)
      println(
        "sqrt(2)^2: \{polynomial_text(@real.definition(square), ["z"])} -> \{polynomial_text(@real.definition(small), ["z"])}",
      )
    }
    _ => abort("demo multiplication budget exhausted")
  }
  let (minimal_a, proof) = normalize(a)
  let field = @numberfield.field_result(minimal_a, proof, @oracle.nat(256)).unwrap()
  let alpha = @numberfield.generator(field).unwrap()
  let plus_one = @numberfield.add(alpha, @numberfield.one(field)).unwrap()
  let square = @numberfield.multiply(plus_one, plus_one).unwrap()
  let fourth = @numberfield.multiply(square, square).unwrap()
  println(
    "Q(sqrt(2)): (1+alpha)^4 = \{polynomial_text(@numberfield.representative(fourth), ["alpha"])}",
  )
  let inverse = @numberfield.inverse_with_certificate(plus_one)
    .unwrap()
    .unwrap()
  guard @numberfield.check_inverse_result(
    plus_one,
    inverse.value,
    inverse.certificate,
  ) else {
    abort("Bezout inverse proof failed")
  }
  println(
    "(1+alpha)^(-1) = \{polynomial_text(@numberfield.representative(inverse.value), ["alpha"])}, Bezout=true",
  )
  println(
    "trace((1+alpha)^4)=\{fraction_text(@numberfield.trace(fourth).unwrap())}, norm=\{fraction_text(@numberfield.norm(fourth).unwrap())}",
  )
  let minimum = @numberfield.minimal_polynomial(fourth).unwrap()
  guard @numberfield.check_minimal_polynomial(fourth, minimum) else {
    abort("field element minimal polynomial proof failed")
  }
  println(
    "minimal polynomial of (1+alpha)^4: \{polynomial_text(minimum, ["z"])}",
  )
  let matrix = @numberfield.multiplication_matrix(alpha).unwrap()
  let characteristic = @berkowitz.characteristic(matrix, @berkowitz.rationals()).unwrap()
  println(
    "alpha multiplication matrix characteristic (descending): [\{@oracle.array(characteristic).map(fraction_text).join(", ")}]",
  )
}

///|
fn real_points() -> Unit {
  let equations = @oracle.chain([
    multivariate(2, [(1, [2, 0]), (-2, [0, 0])]),
    multivariate(2, [(1, [0, 2]), (-3, [0, 0])]),
  ])
  let problem = @variety.problem(@oracle.nat(2), equations).unwrap()
  match
    @variety.separation_advance(
      @variety.separation_start(problem),
      @oracle.nat(4),
      @oracle.nat(512),
    ).unwrap() {
    Separated(solutions) => {
      let proof = @variety.separation_certificate(solutions)
      guard @variety.check_separation_result(problem, solutions, proof) else {
        abort("projected solution proof failed")
      }
      let points = @oracle.array(@variety.projected_points(solutions).unwrap())
      println(
        "x^2=2, y^2=3: separating seed=\{@oracle.int_of_binary(proof.augmentation.seed)}, real points=\{points.length()}, proof=true",
      )
      println(
        "parameter equation: \{polynomial_text(proof.solutions.shape.eliminant, ["t"])} = 0",
      )
      let coordinates = @oracle.array(
        @variety.projected_coordinate_expressions(points[0]),
      )
      println(
        "x=\{polynomial_text(coordinates[0], ["t"])}, y=\{polynomial_text(coordinates[1], ["t"])}",
      )
      for point in points {
        let interval = @real.interval(@variety.projected_parameter(point))
        println(
          "  one t root in (\{fraction_text(interval.lower)}, \{fraction_text(interval.upper)}]",
        )
      }
    }
    _ => abort("demo separation budget exhausted")
  }
}

///|
fn order_conversion() -> Unit {
  let inputs = @oracle.chain([
    multivariate(2, [(1, [2, 0]), (-1, [0, 1])]),
    multivariate(2, [(1, [1, 1]), (-1, [0, 0])]),
  ])
  let source = match @f4.f4(@oracle.nat(2), inputs, @oracle.nat(128)).unwrap() {
    Complete(basis) => basis
    _ => abort("demo F4 budget exhausted")
  }
  match
    @fglm.convert(source, GrevLex, @oracle.nat(16), @oracle.nat(128)).unwrap() {
    Complete(basis) => {
      guard @fglm.check(source, @fglm.certificate(basis)).unwrap() else {
        abort("FGLM proof failed")
      }
      println(
        "F4 -> FGLM GrevLex: quotient dimension=\{@oracle.int_of_nat(@fglm.dimension(basis))}, proof=true",
      )
      for p in @oracle.array(@fglm.polynomials(basis)) {
        println("  \{polynomial_text(p, ["x", "y"])}")
      }
    }
    _ => abort("demo FGLM budget exhausted")
  }
}

///|
fn model_checking() -> Unit {
  let proposition = @oracle.nat(0)
  let model = @mucalc.model(
    @oracle.chain([
      @mucalc.State::{
        id: @oracle.nat(0),
        propositions: @core.Nil,
        successors: @oracle.chain([@oracle.nat(1)]),
      },
      @mucalc.State::{
        id: @oracle.nat(1),
        propositions: @oracle.chain([proposition]),
        successors: @oracle.chain([@oracle.nat(1)]),
      },
      @mucalc.State::{
        id: @oracle.nat(2),
        propositions: @core.Nil,
        successors: @oracle.chain([@oracle.nat(2)]),
      },
      @mucalc.State::{
        id: @oracle.nat(3),
        propositions: @core.Nil,
        successors: @core.Nil,
      },
    ]),
  ).unwrap()
  let formula = @mucalc.Mu(
    @mucalc.Or(
      @mucalc.Proposition(proposition, true),
      @mucalc.Diamond(@mucalc.Bound(@oracle.nat(0))),
    ),
  )
  let compilation = @mucalc.compile(model, formula).unwrap()
  match @mucalc.run(@mucalc.start(compilation), @oracle.nat(1024)) {
    Complete(solution) => {
      guard @mucalc.checked(compilation, @mucalc.certificate(solution))
        is Some(_) else {
        abort("model-checking game proof failed")
      }
      let states = @oracle.array(@mucalc.satisfying_states(solution)).map(fn(
        state,
      ) {
        @oracle.int_of_nat(state).to_string()
      })
      println(
        "mu X.(p OR Diamond X): satisfying states=[\{states.join(", ")}], parity proof=true",
      )
    }
    _ => abort("demo model-checking budget exhausted")
  }
}

///|
fn main {
  println("morph: exact algebra and fixed-point model checking")
  algebraic_numbers()
  real_points()
  order_conversion()
  model_checking()
}
