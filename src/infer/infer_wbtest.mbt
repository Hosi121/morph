///|
fn name(n : Int32) -> @core.Nat {
  @oracle.nat(n)
}

///|
fn v(n : Int32) -> Expr {
  Reference(name(n))
}

///|
fn tv(n : Int32) -> Type {
  Variable(name(n))
}

///|
fn inferred(expression : Expr) -> Type {
  match infer(expression) {
    Ok(scheme) => canonical(body(scheme))
    Err(_) => abort("unexpected inference failure")
  }
}

///|
test "principal types for identity, constant, composition, products and projections" {
  let id = Lambda(name(0), v(0))
  assert_eq(inferred(id), arrow(tv(0), tv(0)))
  let constant = Lambda(name(0), Lambda(name(1), v(0)))
  assert_eq(inferred(constant), arrow(tv(0), arrow(tv(1), tv(0))))
  let compose = Lambda(
    name(0),
    Lambda(name(1), Lambda(name(2), Apply(v(0), Apply(v(1), v(2))))),
  )
  let expected = arrow(
    arrow(tv(0), tv(1)),
    arrow(arrow(tv(2), tv(0)), arrow(tv(2), tv(1))),
  )
  assert_eq(inferred(compose), expected)
  assert_eq(inferred(First(Tuple(Boolean(true), id))), boolean_type())
  assert_eq(inferred(Second(Tuple(Boolean(true), id))), arrow(tv(0), tv(0)))
  match infer(id) {
    Err(_) => fail("identity rejected")
    Ok(scheme) =>
      assert_eq(@oracle.int_of_nat(@core.length(quantified(scheme))), 1)
  }
}

///|
test "let generalizes and each use instantiates independently" {
  let id = Lambda(name(0), v(0))
  let expression = Let(
    name(1),
    id,
    Tuple(Apply(v(1), Boolean(true)), Apply(v(1), Lambda(name(2), v(2)))),
  )
  assert_eq(inferred(expression), product(boolean_type(), arrow(tv(0), tv(0))))
  let shadowed = Let(
    name(0),
    Boolean(true),
    Let(name(0), Lambda(name(1), v(1)), Apply(v(0), Boolean(false))),
  )
  assert_eq(inferred(shadowed), boolean_type())
}

///|
test "lambda arguments and variables free in the environment stay monomorphic" {
  let polymorphic_use = Tuple(
    Apply(v(0), Boolean(true)),
    Apply(v(0), Lambda(name(1), v(1))),
  )
  assert_true(infer(Lambda(name(0), polymorphic_use)) is Err(_))
  let bad_generalization = Lambda(
    name(0),
    Let(
      name(2),
      v(0),
      Tuple(Apply(v(2), Boolean(true)), Apply(v(2), Lambda(name(1), v(1)))),
    ),
  )
  assert_true(infer(bad_generalization) is Err(_))
  let dependent = Lambda(
    name(0),
    Let(
      name(2),
      Lambda(name(1), Apply(v(0), v(1))),
      Tuple(Apply(v(2), Boolean(true)), Apply(v(2), Lambda(name(3), v(3)))),
    ),
  )
  assert_true(infer(dependent) is Err(_))
}

///|
test "occurs check, free names and branch constraints report errors" {
  match infer(Lambda(name(0), Apply(v(0), v(0)))) {
    Err(Unification(OccursCheck(_, _))) => ()
    _ => fail("self application must fail the occurs check")
  }
  assert_eq(infer(v(4)), Err(UnboundVariable(name(4))))
  assert_true(
    infer(Conditional(Boolean(true), Boolean(false), Lambda(name(0), v(0))))
    is Err(_),
  )
  assert_true(
    infer(Conditional(Lambda(name(0), v(0)), Boolean(false), Boolean(true)))
    is Err(_),
  )
  assert_true(infer(First(Boolean(true))) is Err(_))
  assert_eq(
    inferred(Conditional(Boolean(true), Boolean(false), Boolean(true))),
    boolean_type(),
  )
}
