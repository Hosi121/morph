///|
fn variable(n : Int32) -> Term[Bool] {
  Variable(@oracle.nat(n))
}

///|
fn node(symbol : Bool, children : Array[Term[Bool]]) -> Term[Bool] {
  Node(symbol, @oracle.chain(children))
}

///|
test "unifier composes substitutions and checks occurs, symbols and arity" {
  let a = node(false, [])
  let x = variable(0)
  let y = variable(1)
  let eq = fn(a : Bool, b : Bool) { a == b }
  let equations = @oracle.chain([(x, node(true, [y])), (y, a)])
  match unify(equations, eq) {
    Err(_) => fail("unifiable terms rejected")
    Ok(substitution) => {
      assert_eq(apply(substitution, x), node(true, [a]))
      assert_eq(apply(substitution, y), a)
      for binding in @oracle.array(bindings(substitution)) {
        assert_eq(apply(substitution, binding.1), binding.1)
        assert_false(occurs(binding.0, binding.1))
      }
    }
  }
  match unify(@oracle.chain([(x, node(true, [x]))]), eq) {
    Err(OccursCheck(_, _)) => ()
    _ => fail("occurs check missing")
  }
  match unify(@oracle.chain([(a, node(true, []))]), eq) {
    Err(SymbolMismatch(_, _)) => ()
    _ => fail("head mismatch missing")
  }
  match unify(@oracle.chain([(a, node(false, [x]))]), eq) {
    Err(ArityMismatch) => ()
    _ => fail("arity mismatch missing")
  }
  match unify(@oracle.chain([(x, node(true, [y])), (y, node(true, [x]))]), eq) {
    Err(OccursCheck(_, _)) => ()
    _ => fail("indirect occurs check missing")
  }
  assert_true(unify(@oracle.chain([(x, x)]), eq) is Ok(_))
}

///|
test "finite term pairs preserve equations and substitutions are idempotent" {
  let atoms = [variable(0), variable(1), node(false, []), node(true, [])]
  let terms = atoms.copy()
  for symbol in [false, true] {
    for child in atoms {
      terms.push(node(symbol, [child]))
    }
    for a in atoms {
      for b in atoms {
        terms.push(node(symbol, [a, b]))
      }
    }
  }
  let eq = fn(a : Bool, b : Bool) { a == b }
  for a in terms {
    for b in terms {
      match unify(@oracle.chain([(a, b)]), eq) {
        Err(_) => ()
        Ok(s) => {
          assert_eq(apply(s, a), apply(s, b))
          let entries = @oracle.array(bindings(s))
          for domain in entries {
            for range in entries {
              assert_false(occurs(domain.0, range.1))
            }
          }
          for term in atoms {
            assert_eq(apply(s, apply(s, term)), apply(s, term))
          }
        }
      }
    }
  }
  assert_eq(
    @oracle.array(
      free_variables(node(true, [variable(2), variable(0), variable(2)])),
    ).map(@oracle.int_of_nat),
    [2, 0],
  )
}
