///|
fn[A] required(result : Result[A, @poly.PolyError]) -> A {
  match result {
    Ok(value) => value
    Err(_) => abort("test polynomial operation")
  }
}

///|
/// Independent sparse-polynomial interpretation for differentiation oracles.
fn expand(expression : Expr) -> @poly.Polynomial {
  match expression {
    Constant(value) => @poly.constant(@oracle.nat(3), value)
    Variable(name) => {
      let powers = @oracle.chain(
        [
          for i in 0..<3 => {
            @oracle.nat(if i == @oracle.int_of_nat(name) { 1 } else { 0 })
          }
        ],
      )
      required(
        @poly.polynomial(
          @oracle.nat(3),
          @core.Cons(
            @poly.Term::{
              coefficient: @exact.rational_one(),
              exponents: powers,
            },
            Nil,
          ),
        ),
      )
    }
    Sum(a, b) => required(@poly.add(expand(a), expand(b)))
    Product(a, b) => required(@poly.multiply(expand(a), expand(b)))
    Negative(a) => @poly.negate(expand(a))
    Power(a, n) => {
      let base = expand(a)
      for i = 0, result = @poly.constant(@oracle.nat(3), @exact.rational_one()); i <
         @oracle.int_of_nat(n); {
        continue i + 1, required(@poly.multiply(result, base))
      } nobreak {
        result
      }
    }
  }
}

///|
test "symbolic, forward and reverse derivatives agree with sparse polynomial derivatives" {
  let x = Variable(@oracle.nat(0))
  let y = Variable(@oracle.nat(1))
  let z = Variable(@oracle.nat(2))
  for family in 0..<12 {
    let a = Sum(
      Power(x, @oracle.nat(family % 3 + 1)),
      Product(Constant(@oracle.rational(family % 5 - 2, 1)), y),
    )
    let b = Sum(z, Constant(@oracle.rational(1, 2)))
    let expression = Power(
      Sum(Product(a, b), Negative(y)),
      @oracle.nat(family % 3),
    )
    let polynomial = expand(expression)
    for px in -1..<=2 {
      for py in [-1, 1] {
        let values = @oracle.chain([
          @oracle.rational(px, 1),
          @oracle.rational(py, 2),
          @oracle.rational(2, 3),
        ])
        let environment = @oracle.chain(
          @oracle.array(values).mapi(fn(i, value) { (@oracle.nat(i), value) }),
        )
        let expected_value = @poly.evaluate(polynomial, values).unwrap()
        assert_eq(evaluate(expression, environment), Some(expected_value))
        let gradient = reverse(expression, environment).unwrap()
        assert_eq(gradient.value, expected_value)
        for variable in 0..<3 {
          let derivative = @poly.derivative(polynomial, @oracle.nat(variable)).unwrap()
          let expected = @poly.evaluate(derivative, values).unwrap()
          assert_eq(
            evaluate(
              differentiate(expression, @oracle.nat(variable)),
              environment,
            ),
            Some(expected),
          )
          assert_eq(
            forward(expression, environment, @oracle.nat(variable)),
            Some(Dual::{ value: expected_value, tangent: expected, }),
          )
          assert_eq(partial(gradient, @oracle.nat(variable)), expected)
        }
      }
    }
  }
}

///|
test "zero powers, cancellation, rational constants and missing variables" {
  let x = Variable(@oracle.nat(0))
  let expression = Sum(Product(x, x), Negative(Product(x, x)))
  let environment = @oracle.chain([(@oracle.nat(0), @oracle.rational(7, 3))])
  let gradient = reverse(expression, environment).unwrap()
  assert_eq(gradient.value, @exact.rational_zero())
  assert_eq(gradient.partials, Nil)
  assert_eq(evaluate(x, Nil), None)
  assert_eq(forward(x, Nil, @oracle.nat(0)), None)
  assert_eq(reverse(x, Nil), None)
  assert_eq(
    evaluate(Power(x, @oracle.nat(0)), Nil),
    Some(@exact.rational_one()),
  )
  assert_eq(power(x, @oracle.nat(0)), Constant(@exact.rational_one()))
}
