///|
/// Only input/output and fixed scheduling use machine values; all field,
/// algebraic-number operations and validation use the symbolic libraries.
fn polynomial(coefficients : Array[Int32]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(coefficients[index], 1),
          exponents: Cons(@oracle.nat(index), Nil),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(Succ(Zero), terms(0)).unwrap()
}

///|
fn input() -> (@nf.Field, @real.Number) {
  let root : @real.RootCertificate = {
    polynomial: polynomial([-2, 0, 1]),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }
  let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
  match
    @minimal.normalize_root(
      root,
      primes,
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Normalized(value, proof) =>
      (@nf.field_result(value, proof, @oracle.nat(500)).unwrap(), value)
    _ => abort("shared exact input preparation failed")
  }
}

///|
fn realize(value : @nf.Element) -> @real.Number {
  match @nf.realize(value, @oracle.nat(2000)).unwrap() {
    RealReady(number, proof) => {
      if !@nf.check_realization_result(value, number, proof) {
        abort("invalid selected-embedding realization")
      }
      number
    }
    RealPaused(_) => abort("realization needs more fuel")
  }
}

///|
fn main {
  let arguments = @env.args()
  if arguments.length() == 0 {
    abort("mode must be coordinate or field")
  }
  let mode = arguments[arguments.length() - 1]
  let square = mode == "coordinate-square" || mode == "field-square"
  let repetitions = if square { 1 } else { 3 }
  let source = if square { "(sqrt(2)+i)^2" } else { "(sqrt(2)+i)^8" }
  let (base, selected) = input()
  let context = @cf.field(base)
  let expected = @cx.number(
    @real.rational(@oracle.rational(if square { 1 } else { 17 }, 1)).unwrap(),
    @real.number({
      polynomial: polynomial([if square { -8 } else { -6272 }, 0, 1]),
      interval: {
        lower: @oracle.rational(if square { 2 } else { -80 }, 1),
        upper: @oracle.rational(if square { 3 } else { -79 }, 1),
      },
    }).unwrap(),
  )
  let fuel = @oracle.nat(2000)
  let result = if mode == "coordinate" || mode == "coordinate-square" {
    let mut value = @cx.number(
      selected,
      @real.rational(@oracle.rational(1, 1)).unwrap(),
    )
    for _ in 0..<repetitions {
      let previous = value
      match @cx.multiply(previous, previous, fuel).unwrap() {
        ArithmeticReady(result, proof) => {
          if !@cx.check_arithmetic_for(
              previous,
              previous,
              @cx.Multiplication,
              result,
              proof,
            ) {
            abort("coordinate arithmetic certificate failed")
          }
          value = result
        }
        ArithmeticPaused(_) => abort("coordinate arithmetic needs more fuel")
      }
    }
    value
  } else if mode == "field" || mode == "field-square" {
    let mut value = @cf.element(
      context,
      @nf.generator(base).unwrap(),
      @nf.one(base),
    ).unwrap()
    for _ in 0..<repetitions {
      value = @cf.multiply(value, value).unwrap()
    }
    let expected_in_field = @cf.element(
      context,
      @nf.rational(base, @oracle.rational(if square { 1 } else { 17 }, 1)),
      @nf.element(base, polynomial([0, if square { 2 } else { -56 }])).unwrap(),
    ).unwrap()
    if !@cf.equal(value, expected_in_field) {
      abort("field result differs from the independent exact power")
    }
    @cx.number(
      realize(@cf.real_part(value)),
      realize(@cf.imaginary_part(value)),
    )
  } else {
    abort("mode must be coordinate, field, coordinate-square or field-square")
  }
  let equal = match @cx.equal(result, expected, fuel).unwrap() {
    EqualityReady(equal, proof) => {
      if !@cx.check_equality_for(result, expected, equal, proof) {
        abort("numeric result equality certificate failed")
      }
      equal
    }
    EqualityPaused(_) => abort("result comparison needs more fuel")
  }
  if !equal {
    abort("wrong exact power")
  }
  let degree = @oracle.int_of_nat(@cf.degree(context))
  println(
    "{\"source\":\"\{source}\",\"field_degree\":\{degree},\"numeric_equal\":\{equal},\"checked\":true}",
  )
}
