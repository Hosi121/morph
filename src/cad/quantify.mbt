///|
#derive(Eq, Debug)
pub(all) struct EliminationCertificate {
  decomposition : Certificate
  encoding : @signs.Certificate
}

///|
pub extend EliminationCertificate with Eq::{equal, not_equal}

///|
pub extend EliminationCertificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Elimination {
  decomposition : Decomposition
  encoding : @signs.Encoding
}

///|
pub extend Elimination with Debug::{to_repr}

///|
fn sign_tree(tree : TreeCertificate) -> @signs.Tree {
  match tree {
    Leaf(value) => Leaf(value)
    Stack(_, children) =>
      Branch(
        @core.map(children, fn(child) {
          @signs.Child::{
            signs: child.signs,
            subtree: sign_tree(child.subtree),
          }
        }),
      )
  }
}

///|
pub fn eliminate(
  value : Decomposition,
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
) -> Result[Elimination, CadError] {
  match
    @signs.encode(
      free_variables,
      quantifiers,
      @core.map(
        @core.drop(Succ(Zero), value.problem.projection.levels),
        @projection.family,
      ),
      sign_tree(value.proof.tree),
    ) {
    Ok(encoding) => Ok({ decomposition: value, encoding, })
    Err(error) => Err(EncodingFailure(error))
  }
}

///|
pub fn quantifier_free(value : Elimination) -> @qf.Formula {
  @signs.formula(value.encoding)
}

///|
pub fn elimination_certificate(value : Elimination) -> EliminationCertificate {
  {
    decomposition: certificate(value.decomposition),
    encoding: @signs.certificate(value.encoding),
  }
}

///|
pub fn check_elimination(
  problem : Problem,
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  proof : EliminationCertificate,
) -> Elimination? {
  match check(problem, proof.decomposition) {
    None => None
    Some(value) =>
      match eliminate(value, free_variables, quantifiers) {
        Ok(expected) =>
          if elimination_certificate(expected).equal(proof) {
            Some(expected)
          } else {
            None
          }
        Err(_) => None
      }
  }
}

///|
pub fn check_elimination_result(
  problem : Problem,
  free_variables : @core.Nat,
  quantifiers : @core.Chain[@logic.Quantifier],
  value : Elimination,
  proof : EliminationCertificate,
) -> Bool {
  same_problem(value.decomposition.problem, problem) &&
  elimination_certificate(value).equal(proof) &&
  check_elimination(problem, free_variables, quantifiers, proof) is Some(_)
}

///|
pub fn sentence(
  value : Decomposition,
  quantifiers : @core.Chain[@logic.Quantifier],
) -> Result[Bool, CadError] {
  match eliminate(value, Zero, quantifiers) {
    Ok(result) =>
      match quantifier_free(result) {
        Truth(answer) => Ok(answer)
        _ => Err(InternalInvariant)
      }
    Err(error) => Err(error)
  }
}
