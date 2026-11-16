///|
fn check_node(
  problem : Problem,
  point : Point,
  levels : @core.Chain[@projection.Level],
  parent_signs : @core.Chain[@core.Ordering],
  proof : TreeCertificate,
) -> Bool {
  match (levels, proof) {
    (Nil, Leaf(holds)) =>
      match evaluate_formula(point, problem.formula) {
        Ok(expected) => holds.equal(expected)
        Err(_) => false
      }
    (Cons(_, _), Leaf(holds)) =>
      match
        @prefix.evaluate(
          problem.prefix,
          @core.length(point.coordinates),
          parent_signs,
        ) {
        Ok(Known(expected)) => holds.equal(expected)
        _ => false
      }
    (Cons(level, rest), Stack(isolation, cells)) =>
      match prepare_fibre(point, level.family) {
        Err(_) => false
        Ok(fibre) =>
          if !@tower.check_isolation(fibre.root_polynomial, isolation) {
            false
          } else {
            fn walk(
              expected : @core.Chain[Sample],
              cells : @core.Chain[CellCertificate],
            ) -> Bool {
              match (expected, cells) {
                (Nil, Nil) => true
                (Cons(sample, pending), Cons(cell, tail)) =>
                  if !cell.sample.equal(sample) {
                    false
                  } else {
                    match
                      (
                        classify(fibre, sample),
                        extend_point(point, fibre, sample),
                      ) {
                      (Ok(signs), Ok(next)) =>
                        cell.signs.equal(signs) &&
                        check_node(problem, next, rest, signs, cell.subtree) &&
                        walk(pending, tail)
                      _ => false
                    }
                  }
                _ => false
              }
            }
            match samples(isolation.roots) {
              Some(expected) => walk(expected, cells)
              None => false
            }
          }
      }
    _ => false
  }
}

///|
pub fn certificate(value : Decomposition) -> Certificate {
  value.proof
}

///|
pub fn problem_of(value : Decomposition) -> Problem {
  value.problem
}

///|
/// Validates source-bound Collins projection, complete relative root covers,
/// canonical ordered samples, all specialised signs and all terminal truths.
/// Shortened leaves additionally require a source-bound coefficient plan proving
/// constant truth over the whole parent cell times every remaining coordinate.
/// A cover may be built from additional partition polynomials, provided every
/// target atom occurs in its checked source. Ordinary prepared Problems still
/// bind their exact projection through proof.projection equality.
/// Field and PRS computations are recomputed; this is not a Lean proof.
pub fn check(problem : Problem, proof : Certificate) -> Decomposition? {
  if !@logic.qf_atoms(problem.formula).equal(problem.atoms) ||
    !@prefix.check_plan(
      problem.arity,
      problem.formula,
      @core.map(problem.projection.levels, @projection.family),
      problem.prefix,
    ) ||
    !proof.arity.equal(problem.arity) ||
    !proof.formula.equal(problem.formula) ||
    !proof.projection.equal(problem.projection) ||
    !cover_contains(problem.atoms, proof.projection.atoms) ||
    !@projection.check(problem.arity, proof.projection.atoms, proof.projection) {
    None
  } else if check_node(
      problem,
      rational_point(Nil),
      @core.drop(Succ(Zero), problem.projection.levels),
      Nil,
      proof.tree,
    ) {
    Some({ problem, proof, })
  } else {
    None
  }
}

///|
fn same_problem(left : Problem, right : Problem) -> Bool {
  left.arity.equal(right.arity) &&
  left.formula.equal(right.formula) &&
  left.atoms.equal(right.atoms) &&
  left.projection.equal(right.projection) &&
  left.prefix.equal(right.prefix)
}

///|
pub fn check_result(
  problem : Problem,
  value : Decomposition,
  proof : Certificate,
) -> Bool {
  same_problem(value.problem, problem) &&
  value.proof.equal(proof) &&
  check(problem, proof) is Some(_)
}

///|
fn has_true_leaf(tree : TreeCertificate) -> Bool {
  match tree {
    Leaf(value) => value
    Stack(_, children) =>
      @core.any(children, fn(child) { has_true_leaf(child.subtree) })
  }
}

///|
fn find_witness(
  point : Point,
  levels : @core.Chain[@projection.Level],
  tree : TreeCertificate,
) -> Result[Point?, CadError] {
  if !has_true_leaf(tree) {
    Ok(None)
  } else {
    match (levels, tree) {
      (_, Leaf(true)) => Ok(Some(complete_point(point, @core.length(levels))))
      (Cons(level, rest), Stack(_, children)) =>
        match prepare_fibre(point, level.family) {
          Err(error) => Err(error)
          Ok(fibre) => {
            fn search(
              children : @core.Chain[CellCertificate],
            ) -> Result[Point?, CadError] {
              match children {
                Nil => Ok(None)
                Cons(child, tail) =>
                  if has_true_leaf(child.subtree) {
                    match extend_point(point, fibre, child.sample) {
                      Err(error) => Err(error)
                      Ok(next) => find_witness(next, rest, child.subtree)
                    }
                  } else {
                    search(tail)
                  }
              }
            }
            search(children)
          }
        }
      _ => Err(InternalInvariant)
    }
  }
}

///|
pub fn witness(value : Decomposition) -> Result[Point?, CadError] {
  find_witness(
    rational_point(Nil),
    @core.drop(Succ(Zero), value.problem.projection.levels),
    value.proof.tree,
  )
}

///|
pub fn check_witness(problem : Problem, point : Point) -> Bool {
  @core.length(point.coordinates).equal(problem.arity) &&
  @core.all(point.coordinates, fn(value) {
    @tower.same_field(point.field, @tower.scalar_field(value))
  }) &&
  evaluate_formula(point, problem.formula) is Ok(true)
}
