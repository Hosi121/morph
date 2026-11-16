///|
fn separated(roots : @core.Chain[@sturm.Interval]) -> Bool {
  match roots {
    Cons(a, Cons(b, rest)) =>
      match @exact.rational_compare(a.upper, b.lower) {
        Less => separated(Cons(b, rest))
        _ => false
      }
    _ => true
  }
}

///|
fn samples(roots : @core.Chain[@sturm.Interval]) -> @core.Chain[Sample] {
  fn after(
    root : @sturm.Interval,
    rest : @core.Chain[@sturm.Interval],
  ) -> @core.Chain[Sample] {
    let following : @core.Chain[Sample] = match rest {
      Nil =>
        Cons(
          RationalPoint(@exact.rational_add(root.upper, @exact.rational_one())),
          Nil,
        )
      Cons(next, rest) =>
        Cons(RationalPoint(middle(root.upper, next.lower)), after(next, rest))
    }
    Cons(AlgebraicPoint(root), following)
  }
  match roots {
    Nil => Cons(RationalPoint(@exact.rational_zero()), Nil)
    Cons(first, rest) =>
      Cons(
        RationalPoint(
          @exact.rational_subtract(first.lower, @exact.rational_one()),
        ),
        after(first, rest),
      )
  }
}

///|
/// Recheck coverage and signs without rerunning root isolation or the solver.
/// The root-counting and sign helpers are shared with generation.
pub fn check(problem : Problem, certificate : Certificate) -> Decomposition? {
  fn check_cells(
    problem : Problem,
    pending : @core.Chain[Sample],
    cells : @core.Chain[Cell],
  ) -> Bool {
    match (pending, cells) {
      (Nil, Nil) => true
      (Cons(sample, rest), Cons(cell, tail)) =>
        match classify(problem, sample) {
          None => false
          Some(expected) =>
            expected.equal(cell) && check_cells(problem, rest, tail)
        }
      _ => false
    }
  }
  match
    @sturm.check_isolation(problem.system, certificate.roots) &&
    separated(certificate.roots) {
    false => None
    true =>
      match
        check_cells(problem, samples(certificate.roots), certificate.cells) {
        true => Some({ problem, certificate, })
        false => None
      }
  }
}

///|
pub fn certificate(decomposition : Decomposition) -> Certificate {
  decomposition.certificate
}

///|
pub fn problem_of(decomposition : Decomposition) -> Problem {
  decomposition.problem
}

///|
pub fn cells(decomposition : Decomposition) -> @core.Chain[Cell] {
  decomposition.certificate.cells
}

///|
pub fn roots(decomposition : Decomposition) -> @core.Chain[@sturm.Interval] {
  decomposition.certificate.roots
}

///|
fn first_sample(cells : @core.Chain[Cell], wanted : Bool) -> Sample? {
  match cells {
    Nil => None
    Cons(cell, rest) =>
      match (cell.holds, wanted) {
        (true, true) | (false, false) => Some(cell.sample)
        _ => first_sample(rest, wanted)
      }
  }
}

///|
/// An exact witness for exists x. formula(x), if any.
pub fn witness(decomposition : Decomposition) -> Sample? {
  first_sample(decomposition.certificate.cells, true)
}

///|
/// An exact counterexample to forall x. formula(x), if any.
pub fn counterexample(decomposition : Decomposition) -> Sample? {
  first_sample(decomposition.certificate.cells, false)
}

///|
pub fn universally_true(decomposition : Decomposition) -> Bool {
  @core.all(decomposition.certificate.cells, fn(cell) { cell.holds })
}

///|
pub fn satisfying_cells(decomposition : Decomposition) -> @core.Chain[Cell] {
  @core.filter(decomposition.certificate.cells, fn(cell) { cell.holds })
}
