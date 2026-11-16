///|
/// At lexical depth d every atom has free_count+d variables. Free variables
/// occupy the first slots, followed by surrounding binders outermost first.
/// Exists/Forall append one local slot to their body's environment.
#derive(Eq, Debug)
pub(all) enum Formula {
  Truth(Bool)
  Atom(@polynomial.Polynomial, @realcad.Relation)
  Negation(Formula)
  Conjunction(Formula, Formula)
  Disjunction(Formula, Formula)
  Exists(Formula)
  Forall(Formula)
}

///|
pub extend Formula with Eq::{equal, not_equal}

///|
pub extend Formula with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Quantifier {
  Exists
  Forall
}

///|
pub extend Quantifier with Eq::{equal, not_equal}

///|
pub extend Quantifier with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum BuildError {
  ArityMismatch
  InvalidRenaming
}

///|
pub extend BuildError with Eq::{equal, not_equal}

///|
pub extend BuildError with Debug::{to_repr}

///|
/// An untrusted finite normalization claim. check recomputes the syntactic
/// transformation and binds it to the requested source and free-variable arity.
#derive(Eq, Debug)
pub(all) struct Certificate {
  free_variables : @core.Nat
  source : Formula
  quantifiers : @core.Chain[Quantifier]
  matrix : @realcad.Formula
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
/// A checked prenex normalization over a nonempty domain. Matrix variable order
/// is free variables first, then one globally distinct slot per prefix binder.
/// The prefix is outermost first; sibling binders are never identified.
#derive(Eq, Debug)
pub struct Prenex {
  certificate : Certificate
}

///|
pub extend Prenex with Eq::{equal, not_equal}

///|
pub extend Prenex with Debug::{to_repr}
