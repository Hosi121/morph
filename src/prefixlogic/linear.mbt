///|
/// Only positive equality conjuncts hold whenever the whole source holds.
/// A constant nonzero remainder modulo coordinate equations proves a conflict;
/// reconstruct the exact polynomial identity before accepting it.
fn linear_conflict(formula : @qf.Formula) -> Bool {
  fn collect(
    source : @qf.Formula,
    tail : @core.Chain[@poly.Polynomial],
  ) -> @core.Chain[@poly.Polynomial] {
    match source {
      Atom(p, EqualZero) => Cons(p, tail)
      Conjunction(left, right) => collect(left, collect(right, tail))
      _ => tail
    }
  }
  // ax_i+b=0 permits substitution without introducing other variables or
  // expanding one monomial into many. Coupled affine rows use ordinary CAD.
  fn coordinate(p : @poly.Polynomial) -> Bool {
    match
      @core.filter(@poly.terms(p), fn(term) {
        !@core.all(term.exponents, @core.is_zero)
      }) {
      Cons(term, Nil) =>
        @core.fold_left(term.exponents, @core.Zero, @core.add).equal(Succ(Zero))
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
  let equalities = collect(formula, Nil)
  let divisors = @core.filter(equalities, coordinate)
  match divisors {
    Nil => false
    _ =>
      @core.any(equalities, fn(p) {
        if coordinate(p) {
          false
        } else {
          match @poly.divide(p, divisors) {
            Err(_) => false
            Ok(division) =>
              match constant_sign(division.remainder) {
                Some(Less) | Some(Greater) =>
                  match
                    reconstruct(
                      divisors,
                      division.quotients,
                      division.remainder,
                    ) {
                    Some(original) => original.equal(p)
                    None => false
                  }
                _ => false
              }
          }
        }
      })
  }
}
