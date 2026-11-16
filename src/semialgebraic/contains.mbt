///|
fn compare_bound(
  point : @real.Number,
  bound : @real.RootCertificate,
  fuel : @core.Nat,
) -> Result[@core.Ordering?, SetError] {
  match @real.number(bound) {
    Err(_) => Err(InvalidEndpoint)
    Ok(endpoint) =>
      match @real.compare(point, endpoint, fuel) {
        Err(e) => Err(AlgebraFailure(e))
        Ok(@real.ComparisonPaused(_)) => Ok(None)
        Ok(@real.Compared(order, _)) => Ok(Some(order))
      }
  }
}

///|
fn lower_test(
  interval : Interval,
  point : @real.Number,
  fuel : @core.Nat,
) -> Result[Bool?, SetError] {
  match interval.lower {
    NegativeInfinity => Ok(Some(true))
    PositiveInfinity => Ok(Some(false))
    Finite(bound) =>
      match compare_bound(point, bound, fuel) {
        Err(e) => Err(e)
        Ok(None) => Ok(None)
        Ok(Some(order)) =>
          Ok(
            Some(
              order.equal(Greater) ||
              (order.equal(Equal) && interval.lower_closed),
            ),
          )
      }
  }
}

///|
fn upper_test(
  interval : Interval,
  point : @real.Number,
  fuel : @core.Nat,
) -> Result[Bool?, SetError] {
  match interval.upper {
    PositiveInfinity => Ok(Some(true))
    NegativeInfinity => Ok(Some(false))
    Finite(bound) =>
      match compare_bound(point, bound, fuel) {
        Err(e) => Err(e)
        Ok(None) => Ok(None)
        Ok(Some(order)) =>
          Ok(
            Some(
              order.equal(Less) || (order.equal(Equal) && interval.upper_closed),
            ),
          )
      }
  }
}

///|
fn membership(
  values : @core.Chain[Interval],
  point : @real.Number,
  fuel : @core.Nat,
) -> Result[Bool?, SetError] {
  fn walk(
    values : @core.Chain[Interval],
    uncertain : Bool,
  ) -> Result[Bool?, SetError] {
    match values {
      Nil => Ok(if uncertain { None } else { Some(false) })
      Cons(interval, rest) =>
        match lower_test(interval, point, fuel) {
          Err(e) => Err(e)
          Ok(Some(false)) => walk(rest, uncertain)
          Ok(None) => walk(rest, true)
          Ok(Some(true)) =>
            match upper_test(interval, point, fuel) {
              Err(e) => Err(e)
              Ok(Some(true)) => Ok(Some(true))
              Ok(Some(false)) => walk(rest, uncertain)
              Ok(None) => walk(rest, true)
            }
        }
    }
  }
  walk(values, false)
}

///|
/// Exact membership. None is an unresolved comparison budget, never false.
/// Fuel is per endpoint comparison, not a global time or bit-operation bound.
pub fn contains(
  value : RealSet,
  point : @real.Number,
  fuel : @core.Nat,
) -> Result[Bool?, SetError] {
  membership(value.certificate.intervals, point, fuel)
}
