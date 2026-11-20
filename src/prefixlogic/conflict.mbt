///|
/// Mandatory binomial equations reduce monomials without increasing total degree.
/// Every new residue is tied to the source by an exact reconstructed identity.
fn conjunct_conflict(formula : @qf.Formula) -> Bool {
  fn collect(
    source : @qf.Formula,
    tail : @core.Chain[(@poly.Polynomial, @qf.Relation)],
  ) -> @core.Chain[(@poly.Polynomial, @qf.Relation)] {
    match source {
      Atom(p, relation) => Cons((p, relation), tail)
      Conjunction(left, right) => collect(left, collect(right, tail))
      _ => tail
    }
  }
  fn binomial(p : @poly.Polynomial) -> Bool {
    fn degree(term : @poly.Term) -> @core.Nat {
      @core.fold_left(term.exponents, @core.Zero, @core.add)
    }
    match @poly.terms(p) {
      Cons(head, Nil) =>
        @core.any(head.exponents, fn(power) { power is Succ(_) })
      Cons(head, Cons(tail, Nil)) =>
        match @core.compare(degree(head), degree(tail)) {
          Less => false
          _ => @core.any(head.exponents, fn(power) { power is Succ(_) })
        }
      _ => false
    }
  }
  fn unit(powers : @core.Chain[@core.Nat]) -> Bool {
    match powers {
      Nil => false
      Cons(Zero, rest) => unit(rest)
      Cons(Succ(Zero), rest) => @core.all(rest, @core.is_zero)
      _ => false
    }
  }
  fn coordinate(p : @poly.Polynomial) -> Bool {
    match @poly.terms(p) {
      Cons(head, Nil) => unit(head.exponents)
      Cons(head, Cons(tail, Nil)) =>
        unit(head.exponents) && @core.all(tail.exponents, @core.is_zero)
      _ => false
    }
  }
  fn reconstruct(
    divisors : @core.Chain[@poly.Polynomial],
    quotients : @core.Chain[@poly.Polynomial],
    sum : @poly.Polynomial,
  ) -> @poly.Polynomial? {
    match (divisors, quotients) {
      (Nil, Nil) => Some(sum)
      (Cons(d, ds), Cons(q, qs)) =>
        match @poly.multiply(d, q) {
          Err(_) => None
          Ok(product) =>
            match @poly.add(sum, product) {
              Err(_) => None
              Ok(next) => reconstruct(ds, qs, next)
            }
        }
      _ => None
    }
  }
  fn reduce(
    p : @poly.Polynomial,
    divisors : @core.Chain[@poly.Polynomial],
    needed : (@poly.Polynomial) -> Bool,
  ) -> @poly.Polynomial? {
    match @poly.divide(p, divisors) {
      Err(_) => None
      Ok(division) =>
        // A rejected candidate cannot affect the caller's result. Accepted
        // changes still require the same exact reconstructed identity.
        if !needed(division.remainder) {
          None
        } else if division.remainder.equal(p) {
          Some(p)
        } else {
          match reconstruct(divisors, division.quotients, division.remainder) {
            Some(original) =>
              if original.equal(p) {
                Some(division.remainder)
              } else {
                None
              }
            None => None
          }
        }
    }
  }
  fn constant_false(p : @poly.Polynomial, relation : @qf.Relation) -> Bool {
    match constant_sign(p) {
      Some(sign) => !@logic.relation_holds(relation, sign)
      None => false
    }
  }
  fn refutes(
    atoms : @core.Chain[(@poly.Polynomial, @qf.Relation)],
    basis : @core.Chain[@poly.Polynomial],
  ) -> Bool {
    @core.any(atoms, fn(atom) {
      let (p, relation) = atom
      reduce(p, basis, fn(r) { constant_false(r, relation) }) is Some(_)
    })
  }
  let atoms = collect(formula, Nil)
  match atoms {
    Nil | Cons(_, Nil) => return false
    _ => ()
  }
  let equalities = @core.map(
    @core.filter(atoms, fn(atom) {
      let (_, relation) = atom
      relation is EqualZero
    }),
    fn(atom) {
      let (p, _) = atom
      p
    },
  )
  // Keep the existing coordinate shortcut first. Extra equations must not
  // obscure a conflict that coordinate substitution already establishes.
  let coordinates = @core.filter(equalities, coordinate)
  match coordinates {
    Cons(_, _) => if refutes(atoms, coordinates) { return true }
    Nil => ()
  }
  let inputs = @core.filter(equalities, binomial)
  // The coordinate-only basis was already checked; do not repeat that work.
  if @core.all(inputs, coordinate) {
    false
  } else {
    // One pass against original equations only: each accepted residue
    // vanishes whenever the mandatory source equalities vanish.
    let residues = @core.fold_left(inputs, @core.Nil, fn(
      found : @core.Chain[@poly.Polynomial],
      p,
    ) {
      let others = @core.filter(inputs, fn(q) { !q.equal(p) })
      match
        reduce(p, others, fn(r) {
          (binomial(r) || constant_false(r, EqualZero)) &&
          !@core.any(inputs, fn(q) { q.equal(r) }) &&
          !@core.any(found, fn(q) { q.equal(r) })
        }) {
        Some(r) => Cons(r, found)
        None => found
      }
    })
    let basis = @core.append(inputs, residues)
    @core.any(residues, fn(r) { constant_false(r, EqualZero) }) ||
    refutes(atoms, basis)
  }
}
