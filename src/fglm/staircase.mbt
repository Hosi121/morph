///|
fn same(a : @core.Chain[@core.Nat], b : @core.Chain[@core.Nat]) -> Bool {
  @poly.compare_monomial(a, b).equal(Equal)
}

///|
fn contains(
  values : @core.Chain[@core.Chain[@core.Nat]],
  value : @core.Chain[@core.Nat],
) -> Bool {
  @core.any(values, fn(m) { same(m, value) })
}

///|
fn unique(values : @core.Chain[@core.Chain[@core.Nat]]) -> Bool {
  match values {
    Nil => true
    Cons(head, rest) => !contains(rest, head) && unique(rest)
  }
}

///|
fn variable_multiple(
  m : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> @core.Chain[@core.Nat] {
  match (m, index) {
    (Cons(head, rest), Zero) => Cons(Succ(head), rest)
    (Cons(head, rest), Succ(index)) =>
      Cons(head, variable_multiple(rest, index))
    _ => m
  }
}

///|
fn multiples(m : @core.Chain[@core.Nat]) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.map(@core.indices(@core.length(m)), fn(i) { variable_multiple(m, i) })
}

///|
fn enqueue(
  order : Order,
  heap : @heap.Heap[@core.Chain[@core.Nat]],
  seen : @core.Chain[@core.Chain[@core.Nat]],
  values : @core.Chain[@core.Chain[@core.Nat]],
) -> (@heap.Heap[@core.Chain[@core.Nat]], @core.Chain[@core.Chain[@core.Nat]]) {
  match values {
    Nil => (heap, seen)
    Cons(value, rest) =>
      if contains(seen, value) {
        enqueue(order, heap, seen, rest)
      } else {
        enqueue(
          order,
          @heap.insert(heap, value, fn(a, b) { compare_monomial(order, a, b) }),
          Cons(value, seen),
          rest,
        )
      }
  }
}

///|
fn lex_leads(
  polynomials : @core.Chain[@poly.Polynomial],
) -> @core.Chain[@core.Chain[@core.Nat]] {
  @core.fold_left(polynomials, Nil, fn(found, p) {
    match @poly.terms(p) {
      Nil => found
      Cons(head, _) => Cons(head.exponents, found)
    }
  })
}

///|
fn is_unit(leads : @core.Chain[@core.Chain[@core.Nat]]) -> Bool {
  @core.any(leads, fn(m) { @core.all(m, @core.is_zero) })
}

///|
fn pure_power(value : @core.Chain[@core.Nat], index : @core.Nat) -> Bool {
  match (value, index) {
    (Cons(Succ(_), rest), Zero) => @core.all(rest, @core.is_zero)
    (Cons(Zero, rest), Succ(index)) => pure_power(rest, index)
    _ => false
  }
}

///|
fn finite_staircase(
  variables : @core.Nat,
  leads : @core.Chain[@core.Chain[@core.Nat]],
) -> Bool {
  @core.all(@core.indices(variables), fn(i) {
    @core.any(leads, fn(m) { pure_power(m, i) })
  })
}

///|
/// Standard-monomial heap traversal, after checking a pure power for each variable.
/// Only standard monomials enqueue children. Exceeding cap stops after cap+one
/// standard monomials; no huge Cartesian bounding box is built.
fn staircase(
  variables : @core.Nat,
  leads : @core.Chain[@core.Chain[@core.Nat]],
  cap : @core.Nat,
) -> @core.Chain[@core.Chain[@core.Nat]]? {
  let one = @core.replicate(variables, @core.Zero)
  fn walk(
    heap : @heap.Heap[@core.Chain[@core.Nat]],
    seen : @core.Chain[@core.Chain[@core.Nat]],
    found : @core.Chain[@core.Chain[@core.Nat]],
    remaining : @core.Nat,
  ) -> @core.Chain[@core.Chain[@core.Nat]]? {
    match @heap.pop(heap, fn(a, b) { compare_monomial(Lex, a, b) }) {
      None => Some(@core.reverse(found))
      Some((m, rest)) =>
        if @core.any(leads, fn(lead) { @poly.divides(lead, m) }) {
          walk(rest, seen, found, remaining)
        } else {
          match remaining {
            Zero => None
            Succ(remaining) => {
              let (heap, seen) = enqueue(Lex, rest, seen, multiples(m))
              walk(heap, seen, Cons(m, found), remaining)
            }
          }
        }
    }
  }
  walk(@heap.singleton(one), Cons(one, Nil), Nil, cap)
}

///|
fn coefficient(
  p : @poly.Polynomial,
  m : @core.Chain[@core.Nat],
) -> @exact.Rational {
  fn find(terms : @core.Chain[@poly.Term]) -> @exact.Rational {
    match terms {
      Nil => @exact.rational_zero()
      Cons(t, rest) =>
        if same(t.exponents, m) {
          t.coefficient
        } else {
          find(rest)
        }
    }
  }
  find(@poly.terms(p))
}

///|
fn coordinates(
  p : @poly.Polynomial,
  standard : @core.Chain[@core.Chain[@core.Nat]],
) -> @core.Chain[@exact.Rational]? {
  if @core.all(@poly.terms(p), fn(term) { contains(standard, term.exponents) }) {
    Some(@core.map(standard, fn(m) { coefficient(p, m) }))
  } else {
    None
  }
}
