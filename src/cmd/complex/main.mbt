///|
/// Machine numbers appear only in this input/output adapter. The arithmetic,
/// enumeration and certificate checks use the pure symbolic kernel.
fn polynomial(coefficients : Array[Int32]) -> @poly.Polynomial {
  fn terms(index : Int32) -> @core.Chain[@poly.Term] {
    if index == coefficients.length() {
      Nil
    } else {
      Cons(
        {
          coefficient: @oracle.rational(coefficients[index], 1),
          exponents: @oracle.chain([@oracle.nat(index)]),
        },
        terms(index + 1),
      )
    }
  }
  @poly.polynomial(@oracle.nat(1), terms(0)).unwrap()
}

///|
fn gaussian(real : Int32, imaginary : Int32) -> @cx.Number {
  @cx.rational(@oracle.rational(real, 1), @oracle.rational(imaginary, 1)).unwrap()
}

///|
fn numeric_equal(left : @cx.Number, right : @cx.Number) -> Bool {
  match @cx.equal(left, right, @oracle.nat(100)).unwrap() {
    EqualityReady(equal, proof) => {
      if !@cx.check_equality_for(left, right, equal, proof) {
        abort("invalid equality certificate")
      }
      equal
    }
    EqualityPaused(_) => abort("demo equality needs more fuel")
  }
}

///|
fn solve(coefficients : Array[Int32]) -> @roots.RootSet {
  let source = polynomial(coefficients)
  match
    @roots.run(
      @roots.start(@roots.prepare(source).unwrap()),
      @oracle.nat(12),
      @oracle.nat(3000),
    ).unwrap() {
    Complete(value) => {
      if !@roots.check_result(source, value, @roots.certificate(value)) {
        abort("invalid exhaustive root certificate")
      }
      value
    }
    Paused(_, _) => abort("demo root search needs more fuel")
  }
}

///|
fn fixed_field(degree : Int32) -> @cf.Field {
  let coefficients = Array::make(degree + 1, 0)
  coefficients[0] = -2
  coefficients[degree] = 1
  let input : @real.RootCertificate = {
    polynomial: polynomial(coefficients),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }
  let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
  match
    @minimal.normalize_root(
      input,
      primes,
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("real coefficient field needs a verified minimum")
  }
}

///|
fn fixed_field_tour() -> Unit {
  let context = fixed_field(2)
  let base = @cf.real_field(context)
  let value = @cf.element(context, @nf.generator(base).unwrap(), @nf.one(base)).unwrap()
  let minimum = @cf.minimal_polynomial(value).unwrap()
  let checked = minimum == polynomial([9, 0, -2, 0, 1]) &&
    @cf.check_minimal_polynomial(value, minimum) &&
    @cf.check_trace(value, @oracle.rational(0, 1)) &&
    @cf.check_norm(value, @oracle.rational(9, 1))
  if !checked {
    abort("quartic basis invariants failed")
  }
  println(
    "K=Q(sqrt(2)): K(i) degree=\{@oracle.int_of_nat(@cf.degree(context))}; min(sqrt(2)+i)=t^4-2t^2+9; trace=0; norm=9 [checked]",
  )

  let context = fixed_field(4)
  let base = @cf.real_field(context)
  let a = @cf.element(context, @nf.generator(base).unwrap(), @nf.zero(base)).unwrap()
  let i = @cf.imaginary_unit(context)
  let ia = @cf.multiply(i, a).unwrap()
  let roots = [a, @cf.negate(a), ia, @cf.negate(ia)]
  for index in 0..<roots.length() {
    let squared = @cf.multiply(roots[index], roots[index]).unwrap()
    if !@cf.equal(
        @cf.multiply(squared, squared).unwrap(),
        @cf.rational(context, @oracle.rational(2, 1)),
      ) {
      abort("quartic splitting root failed")
    }
    for other in (index + 1)..<roots.length() {
      if @cf.equal(roots[index], roots[other]) {
        abort("duplicate quartic root")
      }
    }
  }
  if !@cf.equal(@cf.divide(ia, a).unwrap().unwrap(), i) {
    abort("root ratio did not recover i")
  }
  println(
    "a^4=2: Q(a,i) degree=\{@oracle.int_of_nat(@cf.degree(context))}; all four distinct roots +a,-a,+ia,-ia [checked]",
  )
  let unit = @cf.add(a, i).unwrap()
  let inverted = @cf.inverse_with_certificate(unit).unwrap().unwrap()
  let expected = @cf.element(
    context,
    @nf.element(base, polynomial([0, -1, 0, 1])).unwrap(),
    @nf.element(base, polynomial([1, 0, -1])).unwrap(),
  ).unwrap()
  let minimum = @cf.minimal_polynomial(unit).unwrap()
  if !@cf.equal(inverted.value, expected) ||
    !@cf.check_inverse_result(unit, inverted.value, inverted.certificate) ||
    minimum != polynomial([1, 0, 28, 0, 2, 0, 4, 0, 1]) ||
    !@cf.check_norm(unit, @oracle.rational(1, 1)) {
    abort("eighth-degree unit proof failed")
  }
  println(
    "a+i: inverse=a^3-a+i(1-a^2); minimum degree=8; ambient norm=1 [checked]",
  )
}

///|
fn main {
  let i = gaussian(0, 1)
  match @cx.multiply(i, i, @oracle.nat(100)).unwrap() {
    ArithmeticReady(value, proof) => {
      let checked = @cx.check_arithmetic_for(
        i,
        i,
        @cx.Multiplication,
        value,
        proof,
      )
      println(
        "i*i=-1: \{numeric_equal(value, gaussian(-1, 0))}; arithmetic checked: \{checked}",
      )
    }
    ArithmeticPaused(_) => abort("Gaussian multiplication did not finish")
  }
  let left = gaussian(3, -4)
  let right = gaussian(3, 4)
  let expected = @cx.rational(
    @oracle.rational(-7, 25),
    @oracle.rational(-24, 25),
  ).unwrap()
  match @cx.divide(left, right, @oracle.nat(100)).unwrap() {
    ArithmeticReady(value, proof) => {
      let checked = @cx.check_arithmetic_for(
        left,
        right,
        @cx.Division,
        value,
        proof,
      )
      println(
        "(3-4i)/(3+4i)=-7/25-24i/25: \{numeric_equal(value, expected)}; arithmetic checked: \{checked}",
      )
    }
    ArithmeticPaused(_) => abort("Gaussian division did not finish")
  }
  let imaginary = solve([1, 0, 1])
  let points = @oracle.array(@roots.roots(imaginary))
  let numbers : Array[@cx.Number] = []
  for point in points {
    match @roots.materialize(point, @oracle.nat(100)).unwrap() {
      Materialized(value, proof) => {
        if !@roots.check_materialization(point, value, proof) {
          abort("invalid complex coordinate certificate")
        }
        numbers.push(value)
      }
      MaterializationPaused(_) => abort("demo coordinate needs more fuel")
    }
  }
  let selected = numbers.filter(fn(value) { numeric_equal(value, i) }).length()
  let other = numbers
    .filter(fn(value) { numeric_equal(value, gaussian(0, -1)) })
    .length()
  println(
    "z^2+1: exactly \{points.length()} roots; i and -i verified: \{selected == 1 && other == 1}",
  )
  match @cx.conjugate(numbers[0], @oracle.nat(100)).unwrap() {
    ArithmeticReady(value, proof) => {
      let checked = @cx.check_arithmetic_for(
        numbers[0],
        numbers[0],
        @cx.Conjugation,
        value,
        proof,
      )
      println(
        "isolated root -> exact conjugate -> other root: \{numeric_equal(value, numbers[1])}; checked: \{checked}",
      )
    }
    ArithmeticPaused(_) => abort("conjugate needs more fuel")
  }
  let cubic = solve([-1, 0, 0, 1])
  let cubic_count = @oracle.int_of_nat(@core.length(@roots.roots(cubic)))
  println(
    "z^3-1: exactly \{cubic_count} roots; full source-bound cover and multiplicities checked",
  )
  let repeated = solve([1, 0, 2, 0, 1])
  let orders = @oracle.array(@roots.roots(repeated)).map(fn(root) {
    @oracle.int_of_nat(@roots.multiplicity(root))
  })
  println(
    "(z^2+1)^2: distinct roots=\{orders.length()}; multiplicities=[\{orders[0]}, \{orders[1]}]",
  )
  let mixed = polynomial([-1, 1, -2, 2, -1, 1])
  let primes = @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary))
  let problem = match
    @factor.prepare(
      mixed,
      primes,
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Prepared(problem) => problem
    _ => abort("mixed polynomial factorization did not complete")
  }
  match
    @factor.run(@factor.start(problem), @oracle.nat(12), @oracle.nat(3000)).unwrap() {
    Complete(family) => {
      let checked = @factor.check_result(
          mixed,
          family,
          @factor.certificate(family),
          @oracle.nat(500),
        ) ==
        @zassenhaus.Proven
      let orders = @oracle.array(@factor.roots(family)).map(fn(root) {
        @oracle.int_of_nat(@factor.multiplicity(root))
      })
      let simple = orders.filter(fn(order) { order == 1 }).length()
      let doubled = orders.filter(fn(order) { order == 2 }).length()
      println(
        "(z^2+1)^2(z-1): \{orders.length()} roots; simple=\{simple}, double=\{doubled}; factor and root covers checked: \{checked}",
      )
    }
    Paused(_, _) => abort("factored mixed roots need more fuel")
  }
  fixed_field_tour()
}
