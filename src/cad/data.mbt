///|
#derive(Eq, Debug)
pub(all) enum CadError {
  WrongArity
  PrefixFailure(@prefix.PrefixError)
  InvalidCertificate
  ProjectionFailure(@projection.ProjectionError)
  TowerFailure(@tower.TowerError)
  EncodingFailure(@signs.EncodingError)
  InternalInvariant
}

///|
pub extend CadError with Eq::{equal, not_equal}

///|
pub extend CadError with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Sample {
  RationalPoint(@exact.Rational)
  RootPoint(@tower.RootCertificate)
}

///|
pub extend Sample with Eq::{equal, not_equal}

///|
pub extend Sample with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum TreeCertificate {
  Leaf(Bool)
  Stack(@tower.SolutionCertificate, @core.Chain[CellCertificate])
}

///|
pub extend TreeCertificate with Eq::{equal, not_equal}

///|
pub extend TreeCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct CellCertificate {
  sample : Sample
  signs : @core.Chain[@core.Ordering]
  subtree : TreeCertificate
}

///|
pub extend CellCertificate with Eq::{equal, not_equal}

///|
pub extend CellCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  arity : @core.Nat
  formula : @qf.Formula
  projection : @projection.Certificate
  tree : TreeCertificate
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Debug)
pub struct Problem {
  arity : @core.Nat
  formula : @qf.Formula
  atoms : @core.Chain[@poly.Polynomial]
  projection : @projection.Certificate
  prefix : @prefix.Plan
}

///|
pub extend Problem with Debug::{to_repr}

///|
#derive(Debug)
pub struct Decomposition {
  problem : Problem
  proof : Certificate
}

///|
pub extend Decomposition with Debug::{to_repr}

///|
/// All coordinates live in this single checked descendant field.
#derive(Debug)
pub struct Point {
  field : @tower.Field
  coordinates : @core.Chain[@tower.Scalar]
}

///|
pub extend Point with Debug::{to_repr}

///|
#derive(Debug)
struct Fibre {
  polynomials : @core.Chain[@tower.Polynomial]
  systems : @core.Chain[@tower.System?]
  root_polynomial : @tower.Polynomial
  system : @tower.System
}

///|
pub extend Fibre with Debug::{to_repr}

///|
#derive(Debug)
enum Node {
  Pending(Point, @core.Chain[@projection.Level], @core.Chain[@core.Ordering])
  Isolating(Point, @core.Chain[@projection.Level], Fibre, @tower.State)
  Separating(
    Point,
    @core.Chain[@projection.Level],
    Fibre,
    @tower.SolutionCertificate,
    @core.Chain[@tower.Root]
  )
  Sampling(
    Point,
    @core.Chain[@projection.Level],
    Fibre,
    @tower.SolutionCertificate,
    @core.Chain[Sample],
    @core.Chain[CellCertificate]
  )
  Descending(
    Point,
    @core.Chain[@projection.Level],
    Fibre,
    @tower.SolutionCertificate,
    @core.Chain[Sample],
    @core.Chain[CellCertificate],
    Sample,
    @core.Chain[@core.Ordering],
    Node
  )
}

///|
pub extend Node with Debug::{to_repr}

///|
#derive(Debug)
pub struct Machine {
  problem : Problem
  node : Node
}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Complete(Decomposition)
  Paused(Machine)
}

///|
pub extend Progress with Debug::{to_repr}

///|
#derive(Debug)
enum NodeProgress {
  Found(Point)
  Finished(TreeCertificate)
  Working(Node)
}

///|
pub extend NodeProgress with Debug::{to_repr}

///|
/// Resumable satisfiability search. Unlike Machine it may stop before complete
/// decomposition once an exact checked point has been found.
#derive(Debug)
pub struct Search {
  problem : Problem
  node : Node
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum SearchProgress {
  Satisfiable(Point)
  Unsatisfiable(Decomposition)
  Paused(Search)
}

///|
pub extend SearchProgress with Debug::{to_repr}
