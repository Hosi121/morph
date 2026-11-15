///|
test "Apply idempotent substitution to bound shared term" (b : @bench.T) {
  let mut tree : @unify.Term[Bool] = Node(false, Nil)
  for _ in 0..<6 {
    tree = Node(true, @core.Cons(tree, Cons(tree, Nil)))
  }
  let variable : @unify.Term[Bool] = Variable(@oracle.nat(0))
  let substitution = match
    @unify.unify(@core.Cons((variable, tree), Nil), fn(a : Bool, b : Bool) {
      a == b
    }) {
    Ok(s) => s
    Err(_) => abort("benchmark unification")
  }
  b.bench(fn() { b.keep(@unify.apply(substitution, variable)) })
}
