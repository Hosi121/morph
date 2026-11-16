///|
fn binding_sign(
  binding : Binding,
  signs : @core.Chain[@core.Ordering],
) -> @core.Ordering? {
  match binding {
    Fixed(sign) => Some(sign)
    Observed(index) => @core.nth(signs, index)
    Unavailable => None
  }
}

///|
fn evaluate_conditional(
  conditional : Conditional,
  signs : @core.Chain[@core.Ordering],
) -> Truth {
  match conditional {
    Constant(value) => Known(value)
    Atom(constant, future, relation) =>
      if @core.all(future, fn(binding) {
          binding_sign(binding, signs) is Some(Equal)
        }) {
        match binding_sign(constant, signs) {
          Some(sign) => Known(@logic.relation_holds(relation, sign))
          None => Undetermined
        }
      } else {
        Undetermined
      }
    Not(body) =>
      match evaluate_conditional(body, signs) {
        Known(value) => Known(!value)
        Undetermined => Undetermined
      }
    And(left, right) =>
      match
        (evaluate_conditional(left, signs), evaluate_conditional(right, signs)) {
        (Known(false), _) | (_, Known(false)) => Known(false)
        (Known(true), Known(true)) => Known(true)
        _ => Undetermined
      }
    Or(left, right) =>
      match
        (evaluate_conditional(left, signs), evaluate_conditional(right, signs)) {
        (Known(true), _) | (_, Known(true)) => Known(true)
        (Known(false), Known(false)) => Known(false)
        _ => Undetermined
      }
  }
}

///|
/// Observations must be signs of the entire supplied family, in exactly its
/// original order, and must hold over the whole parent cell, not just one point.
pub fn evaluate(
  plan : Plan,
  depth : @core.Nat,
  signs : @core.Chain[@core.Ordering],
) -> Result[Truth, PrefixError] {
  match @core.nth(plan.stages, depth) {
    None => Err(InvalidObservation)
    Some(stage) =>
      if !@core.length(signs).equal(stage.observation_count) {
        Err(InvalidObservation)
      } else {
        Ok(evaluate_conditional(stage.conditional, signs))
      }
  }
}
