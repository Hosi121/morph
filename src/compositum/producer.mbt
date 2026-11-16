///|
fn compare_complete(
  left : @real.Number,
  right : @real.Number,
  fuel : @core.Nat,
) -> Result[@real.ComparisonCertificate?, CompositumError] {
  match @real.compare(left, right, fuel) {
    Err(error) => Err(AlgebraFailure(error))
    Ok(@real.ComparisonPaused(_)) => Ok(None)
    Ok(@real.Compared(_, proof)) => Ok(Some(proof))
  }
}

///|
fn select_all(
  points : @core.Chain[@variety.ProjectedPoint],
  left : @real.Number,
  right : @real.Number,
  budget : Budget,
) -> Result[(@core.Chain[SelectionRow], StopReason?), CompositumError] {
  match points {
    Nil => Ok((Nil, None))
    Cons(point, rest) => {
      let (x, xproof) = match
        @variety.evaluate_projected_coordinate(point, Zero, budget.coordinate) {
        Err(error) => return Err(VarietyFailure(error))
        Ok(@variety.CoordinatePaused(_)) =>
          return Ok((Nil, Some(CoordinateBudget)))
        Ok(@variety.CoordinateReady(value, proof)) => (value, proof)
      }
      let (y, yproof) = match
        @variety.evaluate_projected_coordinate(
          point,
          Succ(Zero),
          budget.coordinate,
        ) {
        Err(error) => return Err(VarietyFailure(error))
        Ok(@variety.CoordinatePaused(_)) =>
          return Ok((Nil, Some(CoordinateBudget)))
        Ok(@variety.CoordinateReady(value, proof)) => (value, proof)
      }
      let xcomparison = match compare_complete(x, left, budget.comparison) {
        Err(error) => return Err(error)
        Ok(None) => return Ok((Nil, Some(ComparisonBudget)))
        Ok(Some(proof)) => proof
      }
      let ycomparison = match compare_complete(y, right, budget.comparison) {
        Err(error) => return Err(error)
        Ok(None) => return Ok((Nil, Some(ComparisonBudget)))
        Ok(Some(proof)) => proof
      }
      match select_all(rest, left, right, budget) {
        Err(error) => Err(error)
        Ok((tail, stopped)) =>
          Ok(
            (
              Cons(
                {
                  left: xproof,
                  right: yproof,
                  left_comparison: xcomparison,
                  right_comparison: ycomparison,
                },
                tail,
              ),
              stopped,
            ),
          )
      }
    }
  }
}

///|
/// One-shot, explicitly budgeted construction. Unresolved retains no resumable
/// state; callers may retry with larger stage budgets. All points are compared,
/// including nonmatching conjugates, before claiming unique input selection.
pub fn compose(
  left : @real.Number,
  right : @real.Number,
  budget : Budget,
) -> Result[Progress, CompositumError] {
  let problem = match source_problem(left, right) {
    Ok(problem) => problem
    Err(error) => return Err(error)
  }
  let separated = match
    @variety.separation_advance(
      @variety.separation_start(problem),
      budget.attempts,
      budget.work,
    ) {
    Err(error) => return Err(VarietyFailure(error))
    Ok(@variety.SeparationPaused(_, reason)) =>
      return Ok(Unresolved(SeparationBudget(reason)))
    Ok(@variety.SeparationNoSolutions(_)) => return Err(InternalInvariant)
    Ok(@variety.Separated(value)) => value
  }
  let points = match @variety.projected_points(separated) {
    Ok(points) => points
    Err(error) => return Err(VarietyFailure(error))
  }
  let selection = match select_all(points, left, right, budget) {
    Err(error) => return Err(error)
    Ok((_, Some(reason))) => return Ok(Unresolved(reason))
    Ok((rows, None)) => rows
  }
  let selected = match unique_index(selection) {
    Some(index) => index
    None => return Err(InternalInvariant)
  }
  let point = match @core.nth(points, selected) {
    Some(point) => point
    None => return Err(InternalInvariant)
  }
  let (parameter, minimal) = match
    @minimal.normalize(
      @variety.projected_parameter(point),
      budget.primes,
      budget.lift,
      budget.subset,
      budget.verification,
    ) {
    Err(error) => return Err(MinimalFailure(error))
    Ok(@minimal.Unresolved(reason)) =>
      return Ok(Unresolved(MinimalBudget(reason)))
    Ok(@minimal.Normalized(parameter, proof)) => (parameter, proof)
  }
  let field = match @nf.field_result(parameter, minimal, budget.verification) {
    Ok(field) => field
    Err(@nf.VerificationBudget) =>
      return Ok(Unresolved(MinimalBudget(@minimal.VerificationBudget)))
    Err(error) => return Err(FieldFailure(error))
  }
  let (x, y) = match @variety.projected_coordinate_expressions(point) {
    Cons(x, Cons(y, Nil)) =>
      match (@nf.element(field, x), @nf.element(field, y)) {
        (Ok(x), Ok(y)) => (x, y)
        _ => return Err(InternalInvariant)
      }
    _ => return Err(InternalInvariant)
  }
  let (xvalue, xembedding) = match @nf.realize(x, budget.realization) {
    Err(error) => return Err(FieldFailure(error))
    Ok(@nf.RealPaused(_)) => return Ok(Unresolved(RealizationBudget))
    Ok(@nf.RealReady(value, proof)) => (value, proof)
  }
  let (yvalue, yembedding) = match @nf.realize(y, budget.realization) {
    Err(error) => return Err(FieldFailure(error))
    Ok(@nf.RealPaused(_)) => return Ok(Unresolved(RealizationBudget))
    Ok(@nf.RealReady(value, proof)) => (value, proof)
  }
  let xequality = match compare_complete(xvalue, left, budget.comparison) {
    Err(error) => return Err(error)
    Ok(None) => return Ok(Unresolved(ComparisonBudget))
    Ok(Some(proof)) => proof
  }
  let yequality = match compare_complete(yvalue, right, budget.comparison) {
    Err(error) => return Err(error)
    Ok(None) => return Ok(Unresolved(ComparisonBudget))
    Ok(Some(proof)) => proof
  }
  if !xequality.order.equal(Equal) || !yequality.order.equal(Equal) {
    return Err(InternalInvariant)
  }
  Ok(
    Composed({ field, left: x, right: y, }, {
      left: @real.root_certificate(left),
      right: @real.root_certificate(right),
      separation: @variety.separation_certificate(separated),
      selection,
      selected,
      minimal,
      left_embedding: xembedding,
      right_embedding: yembedding,
      left_equality: xequality,
      right_equality: yequality,
    }),
  )
}
