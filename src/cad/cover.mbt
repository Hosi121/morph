///|
fn cover_contains(
  atoms : @core.Chain[@poly.Polynomial],
  source : @core.Chain[@poly.Polynomial],
) -> Bool {
  @core.all(atoms, fn(atom) {
    @core.any(source, fn(polynomial) { atom.equal(polynomial) })
  })
}

///|
/// Internal construction only. The caller either starts from an opaque
/// generated cover or immediately runs the full untrusted certificate checker.
fn prepare_cover(
  arity : @core.Nat,
  formula : @qf.Formula,
  projection : @projection.Certificate,
) -> Result[Problem, CadError] {
  let atoms = @logic.qf_atoms(formula)
  if !@core.all(atoms, fn(p) { @poly.variables(p).equal(arity) }) {
    Err(WrongArity)
  } else if !projection.arity.equal(arity) ||
    !cover_contains(atoms, projection.atoms) {
    Err(InvalidCertificate)
  } else {
    match
      @prefix.prepare(
        arity,
        formula,
        @core.map(projection.levels, @projection.family),
      ) {
      Err(error) => Err(PrefixFailure(error))
      Ok(prefix) => Ok({ arity, formula, atoms, projection, prefix, })
    }
  }
}

///|
/// Check an exact requested formula on an explicitly supplied covering
/// projection. Extra source polynomials are partition helpers, not assumptions.
/// All target atoms, the full Collins hierarchy, root covers, sibling coverage,
/// signs and terminal truths are checked by the ordinary checker.
pub fn check_cover(
  arity : @core.Nat,
  formula : @qf.Formula,
  proof : Certificate,
) -> Decomposition? {
  if !proof.arity.equal(arity) || !proof.formula.equal(formula) {
    None
  } else {
    match prepare_cover(arity, formula, proof.projection) {
      Err(_) => None
      Ok(problem) => check(problem, proof)
    }
  }
}

///|
fn refute_tree(
  plan : @prefix.Plan,
  depth : @core.Nat,
  levels : @core.Chain[@projection.Level],
  signs : @core.Chain[@core.Ordering],
  tree : TreeCertificate,
) -> Result[TreeCertificate?, CadError] {
  match @prefix.evaluate(plan, depth, signs) {
    Err(error) => Err(PrefixFailure(error))
    Ok(Known(false)) => Ok(Some(Leaf(false)))
    Ok(Known(true)) => Ok(None)
    Ok(Undetermined) =>
      match (levels, tree) {
        (_, Leaf(_)) => Ok(None)
        (Cons(_, rest), Stack(isolation, Cons(_, _) as cells)) => {
          fn walk(
            cells : @core.Chain[CellCertificate],
          ) -> Result[@core.Chain[CellCertificate]?, CadError] {
            match cells {
              Nil => Ok(Some(Nil))
              Cons(cell, tail) =>
                match
                  refute_tree(plan, Succ(depth), rest, cell.signs, cell.subtree) {
                  Err(error) => Err(error)
                  Ok(None) => Ok(None)
                  Ok(Some(subtree)) =>
                    match walk(tail) {
                      Err(error) => Err(error)
                      Ok(None) => Ok(None)
                      Ok(Some(remaining)) =>
                        Ok(Some(Cons({ ..cell, subtree, }, remaining)))
                    }
                }
            }
          }
          match walk(cells) {
            Err(error) => Err(error)
            Ok(None) => Ok(None)
            Ok(Some(children)) => Ok(Some(Stack(isolation, children)))
          }
        }
        _ => Err(InvalidCertificate)
      }
  }
}

///|
/// Re-labels an existing opaque cover using exact conditional signs. No
/// projection, field arithmetic, root isolation, or extra CAD search is done.
/// Unknown shortened cells are refused rather than inferred from their sample.
/// This producer shares the trust boundary of start/run: an untrusted result
/// must be validated with check_cover or check_result before it is relied on.
pub fn refute_on_cover(
  value : Decomposition,
  formula : @qf.Formula,
) -> Result[Decomposition?, CadError] {
  let original = value.problem
  if !value.proof.arity.equal(original.arity) ||
    !value.proof.formula.equal(original.formula) ||
    !value.proof.projection.equal(original.projection) ||
    !@logic.qf_atoms(original.formula).equal(original.atoms) ||
    !cover_contains(original.atoms, original.projection.atoms) ||
    !@prefix.check_plan(
      original.arity,
      original.formula,
      @core.map(original.projection.levels, @projection.family),
      original.prefix,
    ) {
    Err(InvalidCertificate)
  } else {
    match prepare_cover(original.arity, formula, original.projection) {
      Err(error) => Err(error)
      Ok(problem) =>
        match
          refute_tree(
            problem.prefix,
            Zero,
            @core.drop(Succ(Zero), problem.projection.levels),
            Nil,
            value.proof.tree,
          ) {
          Err(error) => Err(error)
          Ok(None) => Ok(None)
          Ok(Some(tree)) =>
            Ok(
              Some({
                problem,
                proof: {
                  arity: problem.arity,
                  formula,
                  projection: problem.projection,
                  tree,
                },
              }),
            )
        }
    }
  }
}
