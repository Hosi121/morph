///|
fn name(n : Int32) -> @core.Nat {
  @oracle.nat(n)
}

///|
test "CEK lexical scope, call-by-value and resumable transitions" {
  let expression = @infer.Let(
    name(0),
    Boolean(true),
    Let(
      name(1),
      Lambda(name(2), Reference(name(0))),
      Let(name(0), Boolean(false), Apply(Reference(name(1)), Boolean(false))),
    ),
  )
  assert_eq(evaluate(expression, @oracle.nat(100)), Done(BoolValue(true)))
  let mut state = start(expression)
  let mut completed = false
  for _ in 0..<100 {
    match run(state, @oracle.nat(1)) {
      Suspended(next) => state = next
      Done(value) => {
        assert_eq(value, BoolValue(true))
        completed = true
        break
      }
      Fault(_) => fail("well-typed expression failed")
    }
  }
  assert_true(completed)
  assert_eq(evaluate(expression, @oracle.nat(0)), Suspended(start(expression)))
  assert_eq(
    evaluate(
      @infer.First(Tuple(Boolean(false), Boolean(true))),
      @oracle.nat(20),
    ),
    Done(BoolValue(false)),
  )
  assert_eq(
    evaluate(
      @infer.Second(Tuple(Boolean(false), Boolean(true))),
      @oracle.nat(20),
    ),
    Done(BoolValue(true)),
  )
  assert_eq(
    evaluate(
      @infer.Conditional(Boolean(false), Reference(name(99)), Boolean(true)),
      @oracle.nat(20),
    ),
    Done(BoolValue(true)),
  )
}

///|
test "runtime errors and divergence are distinct from fuel exhaustion" {
  assert_eq(
    evaluate(@infer.Apply(Boolean(true), Boolean(false)), @oracle.nat(20)),
    Fault(NotFunction),
  )
  assert_eq(
    evaluate(@infer.First(Boolean(true)), @oracle.nat(20)),
    Fault(NotPair),
  )
  assert_eq(
    evaluate(@infer.Reference(name(5)), @oracle.nat(20)),
    Fault(Unbound(name(5))),
  )
  assert_eq(
    evaluate(
      @infer.Conditional(
        Tuple(Boolean(true), Boolean(false)),
        Boolean(true),
        Boolean(false),
      ),
      @oracle.nat(20),
    ),
    Fault(NotBoolean),
  )
  let self = @infer.Lambda(
    name(0),
    Apply(Reference(name(0)), Reference(name(0))),
  )
  assert_true(
    evaluate(@infer.Apply(self, self), @oracle.nat(1000)) is Suspended(_),
  )
}

///|
test "generated inferred programs execute without type faults" {
  let base : Array[@infer.Expr] = [
    Boolean(false),
    Boolean(true),
    Lambda(name(0), Reference(name(0))),
    Lambda(name(0), Lambda(name(1), Reference(name(0)))),
  ]
  let terms = base.copy()
  for a in base {
    terms.push(First(a))
    terms.push(Second(a))
    for b in base {
      terms.push(Apply(a, b))
      terms.push(Tuple(a, b))
      for c in base {
        terms.push(Conditional(a, b, c))
      }
    }
  }
  let more = terms.copy()
  for a in terms {
    for b in base {
      more.push(Apply(a, b))
      more.push(Tuple(a, b))
    }
  }
  let mut accepted = 0
  for expression in more {
    match @infer.infer(expression) {
      Err(_) => ()
      Ok(scheme) => {
        accepted += 1
        match evaluate(expression, @oracle.nat(500)) {
          Fault(_) => fail("inferred program encountered a type fault")
          Suspended(_) => fail("small generated program exceeded generous fuel")
          Done(value) =>
            match @infer.canonical(@infer.body(scheme)) {
              Node(BoolType, _) => assert_true(value is BoolValue(_))
              Node(FunctionType, _) => assert_true(value is Closure(_, _, _))
              Node(ProductType, _) => assert_true(value is PairValue(_, _))
              Variable(_) => ()
            }
        }
      }
    }
  }
  assert_true(accepted > 100)
}
