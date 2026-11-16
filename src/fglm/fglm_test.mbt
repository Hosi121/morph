///|
test "public FGLM conversion certificate and target normal form API" {
  let n = @oracle.nat(2)
  let inputs = @oracle.chain([
    @poly.polynomial(
      n,
      @oracle.chain([
        @poly.Term::{
          coefficient: @oracle.rational(1, 1),
          exponents: @oracle.chain([@oracle.nat(1), @oracle.nat(0)]),
        },
        @poly.Term::{
          coefficient: @oracle.rational(-1, 1),
          exponents: @oracle.chain([@oracle.nat(0), @oracle.nat(2)]),
        },
      ]),
    ).unwrap(),
    @poly.polynomial(
      n,
      @oracle.chain([
        @poly.Term::{
          coefficient: @oracle.rational(1, 1),
          exponents: @oracle.chain([@oracle.nat(0), @oracle.nat(3)]),
        },
        @poly.Term::{
          coefficient: @oracle.rational(-1, 1),
          exponents: @oracle.chain([@oracle.nat(0), @oracle.nat(0)]),
        },
      ]),
    ).unwrap(),
  ])
  let source = match @f4.f4(n, inputs, @oracle.nat(50)).unwrap() {
    @f4.Complete(source) => source
    _ => abort("F4 source")
  }
  let basis = match
    @fglm.convert(source, @fglm.GrevLex, @oracle.nat(3), @oracle.nat(100)).unwrap() {
    @fglm.Complete(basis) => basis
    _ => abort("FGLM conversion")
  }
  assert_eq(@fglm.variables(basis), n)
  assert_eq(@fglm.order(basis), @fglm.GrevLex)
  assert_eq(@oracle.int_of_nat(@fglm.dimension(basis)), 3)
  assert_eq(
    @core.length(@fglm.standard_monomials(basis)),
    @fglm.dimension(basis),
  )
  assert_eq(@fglm.check(source, @fglm.certificate(basis)), Ok(true))
  assert_eq(@fglm.verify(basis), Ok(true))
  for input in @oracle.array(inputs) {
    assert_true(
      @poly.is_zero(
        @fglm.normal_form(@fglm.GrevLex, input, @fglm.polynomials(basis)).unwrap(),
      ),
    )
  }
}
