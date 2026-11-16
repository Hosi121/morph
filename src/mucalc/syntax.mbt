///|
fn binder_count(formula : Formula) -> @core.Nat {
  match formula {
    Truth(_) | Proposition(_, _) | Bound(_) => Zero
    And(a, b) | Or(a, b) => @core.add(binder_count(a), binder_count(b))
    Diamond(body) | Box(body) => binder_count(body)
    Mu(body) | Nu(body) => Succ(binder_count(body))
  }
}

///|
/// Flatten occurrences in preorder. Bound(0) names the nearest binder. Binder
/// priority is 2*(total_binders-depth), plus one for Mu. Outermost recurring
/// binders therefore dominate for the MAX infinitely-often convention.
fn flatten(
  formula : Formula,
  next : @core.Nat,
  environment : @core.Chain[@core.Nat],
  depth : @core.Nat,
  binders : @core.Nat,
) -> Result[(@core.Chain[Node], @core.Nat), CompileError] {
  let id = next
  let child : @core.Nat = Succ(id)
  match formula {
    Truth(value) =>
      Ok((Cons({ id, priority: Zero, kind: Constant(value), }, Nil), child))
    Proposition(proposition, positive) =>
      Ok(
        (
          Cons(
            { id, priority: Zero, kind: Literal(proposition, positive), },
            Nil,
          ),
          child,
        ),
      )
    Bound(index) =>
      match @core.nth(environment, index) {
        None => Err(UnboundVariable(index))
        Some(target) =>
          Ok((Cons({ id, priority: Zero, kind: Jump(target), }, Nil), child))
      }
    And(left, right) | Or(left, right) =>
      match flatten(left, child, environment, depth, binders) {
        Err(error) => Err(error)
        Ok((left_nodes, right_id)) =>
          match flatten(right, right_id, environment, depth, binders) {
            Err(error) => Err(error)
            Ok((right_nodes, next)) => {
              let kind = match formula {
                And(_, _) => Conjunction(child, right_id)
                _ => Disjunction(child, right_id)
              }
              Ok(
                (
                  Cons(
                    { id, priority: Zero, kind, },
                    @core.append(left_nodes, right_nodes),
                  ),
                  next,
                ),
              )
            }
          }
      }
    Diamond(body) | Box(body) =>
      match flatten(body, child, environment, depth, binders) {
        Err(error) => Err(error)
        Ok((nodes, next)) => {
          let kind = match formula {
            Diamond(_) => SomeNext(child)
            _ => EveryNext(child)
          }
          Ok((Cons({ id, priority: Zero, kind, }, nodes), next))
        }
      }
    Mu(body) | Nu(body) => {
      let base = @core.add(
        @core.subtract(binders, depth),
        @core.subtract(binders, depth),
      )
      let priority : @core.Nat = match formula {
        Mu(_) => Succ(base)
        _ => base
      }
      match flatten(body, child, Cons(id, environment), Succ(depth), binders) {
        Err(error) => Err(error)
        Ok((nodes, next)) =>
          Ok((Cons({ id, priority, kind: Unfold(child), }, nodes), next))
      }
    }
  }
}
