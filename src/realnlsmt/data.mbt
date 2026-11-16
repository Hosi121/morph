///|
#derive(Eq, Debug)
pub(all) struct Context {
  arity : @core.Nat
  source : @qf.Formula
}

///|
pub extend Context with Eq::{equal, not_equal}

///|
pub extend Context with Debug::{to_repr}

///|
/// A Boolean source variable identifies this pair, not just its polynomial.
#derive(Eq, Debug)
pub(all) struct Atom {
  polynomial : @polynomial.Polynomial
  relation : @qf.Relation
}

///|
pub extend Atom with Eq::{equal, not_equal}

///|
pub extend Atom with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum SmtError {
  WrongArity
  CadFailure(@cad.CadError)
  InternalInvariant
}

///|
pub extend SmtError with Eq::{equal, not_equal}

///|
pub extend SmtError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Problem {
  context : Context
  atoms : @core.Chain[Atom]
  encoding : @circuit.Encoding
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
/// Untrusted model data. The checker binds context, CNF, source assertion,
/// every signed arithmetic source variable, and the original real formula.
#derive(Debug)
pub(all) struct Model {
  context : Context
  booleans : @sat.Model
  point : @cad.Point
}

///|
pub extend Model with Debug::{to_repr}

///|
/// Signed source-atom IDs whose conjunction has no point. Auxiliary Tseitin
/// variables are excluded. The blocking clause is reconstructed by the checker.
#derive(Eq, Debug)
pub(all) struct Lemma {
  context : Context
  assignment : @sat.Model
  decomposition : @cad.Certificate
}

///|
pub extend Lemma with Eq::{equal, not_equal}

///|
pub extend Lemma with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Refutation {
  context : Context
  lemmas : @core.Chain[Lemma]
  propositional : @cdcl.Proof
}

///|
pub extend Refutation with Eq::{equal, not_equal}

///|
pub extend Refutation with Debug::{to_repr}

///|
#derive(Debug)
enum TheoryMode {
  FullCad
  PrunedCad
}

///|
pub extend TheoryMode with Debug::{to_repr}

///|
#derive(Debug)
enum TheorySolver {
  FullSolver(@cad.Machine)
  PrunedSolver(@cad.Search)
}

///|
pub extend TheorySolver with Debug::{to_repr}

///|
#derive(Debug)
enum TheoryProgress {
  Found(@cad.Point)
  Rejected(@cad.Decomposition)
  Working(TheorySolver)
}

///|
pub extend TheoryProgress with Debug::{to_repr}

///|
#derive(Debug)
enum Phase {
  Boolean(@cdcl.Search)
  Theory(@sat.Model, @sat.Model, @cdcl.Search, TheorySolver)
}

///|
#derive(Debug)
enum BooleanMode {
  Restarting
  Retained
}

///|
pub extend BooleanMode with Debug::{to_repr}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  problem : Problem
  mode : TheoryMode
  boolean_mode : BooleanMode
  restarts : @core.Nat
  formula : @sat.Cnf
  lemmas_rev : @core.Chain[Lemma]
  phase : Phase
  transitions : @core.Nat
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Outcome {
  Satisfiable(Model)
  Unsatisfiable(Refutation)
  Paused(Search)
}

///|
pub extend Outcome with Debug::{to_repr}
