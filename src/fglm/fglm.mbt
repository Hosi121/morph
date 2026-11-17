///|
#derive(Eq, Debug)
pub(all) enum StopReason {
  DimensionLimit
}

///|
pub extend StopReason with Eq::{equal, not_equal}

///|
pub extend StopReason with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Statistics {
  processed : @core.Nat
  independent : @core.Nat
  dependent : @core.Nat
  skipped : @core.Nat
}

///|
pub extend Statistics with Eq::{equal, not_equal}

///|
pub extend Statistics with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct State {
  source : @f4.Basis
  order : Order
  source_standard : @core.Chain[@core.Chain[@core.Nat]]
  queue : @heap.Heap[@core.Chain[@core.Nat]]
  seen : @core.Chain[@core.Chain[@core.Nat]]
  standards : @core.Chain[@core.Chain[@core.Nat]]
  vectors : @core.Chain[@core.Chain[@exact.Rational]]
  span_state : @linearspan.State
  polynomials : @core.Chain[@poly.Polynomial]
  relations : @core.Chain[Relation]
  processed : @core.Nat
  skipped : @core.Nat
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Basis {
  source : @f4.Basis
  certificate : Certificate
  source_standard : @core.Chain[@core.Chain[@core.Nat]]
  standard_monomials : @core.Chain[@core.Chain[@core.Nat]]
  statistics : Statistics
}

///|
pub extend Basis with Eq::{equal, not_equal}

///|
pub extend Basis with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Basis)
  Paused(State)
  Undecided(StopReason)
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn variables(value : Basis) -> @core.Nat {
  @f4.variables(value.source)
}

///|
pub fn order(value : Basis) -> Order {
  value.certificate.order
}

///|
pub fn polynomials(value : Basis) -> @core.Chain[@poly.Polynomial] {
  value.certificate.polynomials
}

///|
pub fn certificate(value : Basis) -> Certificate {
  value.certificate
}

///|
pub fn dimension(value : Basis) -> @core.Nat {
  @core.length(value.source_standard)
}

///|
pub fn standard_monomials(value : Basis) -> @core.Chain[@core.Chain[@core.Nat]] {
  value.standard_monomials
}

///|
pub fn source_standard_monomials(
  value : Basis,
) -> @core.Chain[@core.Chain[@core.Nat]] {
  value.source_standard
}

///|
pub fn statistics(value : Basis) -> Statistics {
  value.statistics
}

///|
pub fn state_statistics(value : State) -> Statistics {
  {
    processed: value.processed,
    independent: @core.length(value.standards),
    dependent: @core.length(value.relations),
    skipped: value.skipped,
  }
}

///|
pub fn verify(value : Basis) -> Result[Bool, FglmError] {
  check(value.source, value.certificate)
}

///|
pub fn pending(value : State) -> @core.Nat {
  @core.length(
    @heap.drain(value.queue, fn(a, b) { compare_monomial(value.order, a, b) }),
  )
}

///|
priv enum Span {
  Dependent(@core.Chain[@exact.Rational])
  Independent
}

///|
fn combine_vectors(
  vectors : @core.Chain[@core.Chain[@exact.Rational]],
  coefficients : @core.Chain[@exact.Rational],
  dimension : @core.Nat,
) -> @core.Chain[@exact.Rational]? {
  match (vectors, coefficients) {
    (Nil, Nil) => Some(@core.replicate(dimension, @exact.rational_zero()))
    (Cons(vector, rest), Cons(coefficient, tail)) =>
      match combine_vectors(rest, tail, dimension) {
        None => None
        Some(other) =>
          match @core.zip(vector, other) {
            None => None
            Some(pairs) =>
              Some(
                @core.map(pairs, fn(pair) {
                  let (x, y) = pair
                  @exact.rational_add(
                    @exact.rational_multiply(coefficient, x),
                    y,
                  )
                }),
              )
          }
      }
    _ => None
  }
}

///|
fn cached_span(
  state : State,
  vector : @core.Chain[@exact.Rational],
) -> Result[(Span, @linearspan.State), FglmError] {
  match @linearspan.insert(state.span_state, vector) {
    Err(_) => Err(InternalInvariant)
    Ok(@linearspan.Independent(next)) => Ok((Independent, next))
    Ok(@linearspan.Dependent(coefficients)) =>
      match combine_vectors(state.vectors, coefficients, @core.length(vector)) {
        Some(actual) =>
          if actual.equal(vector) {
            Ok((Dependent(coefficients), state.span_state))
          } else {
            Err(InternalInvariant)
          }
        None => Err(InternalInvariant)
      }
  }
}

///|
/// Validate a lex F4 source and build its bounded finite standard staircase.
/// The cap limits quotient dimension, not coefficient size or elapsed time.
pub fn start(
  source : @f4.Basis,
  target : Order,
  max_dimension : @core.Nat,
) -> Result[Progress, FglmError] {
  match @f4.verify(source) {
    Ok(true) => ()
    _ => return Err(InvalidSource)
  }
  let variables = @f4.variables(source)
  let leads = lex_leads(@f4.polynomials(source))
  let one = @core.replicate(variables, @core.Zero)
  if is_unit(leads) {
    let relation : Relation = {
      monomial: one,
      standard_monomials: Nil,
      coefficients: Nil,
    }
    return Ok(
      Complete({
        source,
        certificate: {
          order: target,
          polynomials: Cons(
            @poly.constant(variables, @exact.rational_one()),
            Nil,
          ),
          relations: Cons(relation, Nil),
        },
        source_standard: Nil,
        standard_monomials: Nil,
        statistics: {
          processed: Zero,
          independent: Zero,
          dependent: Succ(Zero),
          skipped: Zero,
        },
      }),
    )
  }
  if !finite_staircase(variables, leads) {
    return Err(PositiveDimension)
  }
  match staircase(variables, leads, max_dimension) {
    None => Ok(Undecided(DimensionLimit))
    Some(source_standard) =>
      Ok(
        Paused({
          source,
          order: target,
          source_standard,
          queue: @heap.singleton(one),
          seen: Cons(one, Nil),
          standards: Nil,
          vectors: Nil,
          span_state: @linearspan.empty(@core.length(source_standard)),
          polynomials: Nil,
          relations: Nil,
          processed: Zero,
          skipped: Zero,
        }),
      )
  }
}

///|
fn finish(state : State) -> Result[Progress, FglmError] {
  if !@core.compare(
      @core.length(state.standards),
      @core.length(state.source_standard),
    ).equal(Equal) {
    return Err(InternalInvariant)
  }
  match @core.zip(state.polynomials, state.relations) {
    None => Err(InternalInvariant)
    Some(pairs) => {
      let sorted = @sorting.merge_sort(pairs, fn(a, b) {
        let (left, _) = a
        let (right, _) = b
        match (leading(state.order, left), leading(state.order, right)) {
          (Some(a), Some(b)) =>
            reverse_order(
              compare_monomial(state.order, a.exponents, b.exponents),
            )
          _ => Equal
        }
      })
      Ok(
        Complete({
          source: state.source,
          certificate: {
            order: state.order,
            polynomials: @core.map(sorted, fn(pair) {
              let (p, _) = pair
              p
            }),
            relations: @core.map(sorted, fn(pair) {
              let (_, relation) = pair
              relation
            }),
          },
          source_standard: state.source_standard,
          standard_monomials: state.standards,
          statistics: state_statistics(state),
        }),
      )
    }
  }
}

///|
/// One priority-heap monomial pop. Independent source normal forms extend the
/// target standard basis and enqueue variable multiples. A dependence creates
/// one exact target-leading relation; its multiples are pruned thereafter.
pub fn step(state : State) -> Result[Progress, FglmError] {
  match
    @heap.pop(state.queue, fn(a, b) { compare_monomial(state.order, a, b) }) {
    None => finish(state)
    Some((m, queue)) => {
      let current : State = {
        ..state,
        queue,
        processed: Succ(state.processed),
      }
      let reducible = @core.any(state.polynomials, fn(p) {
        match leading(state.order, p) {
          Some(head) => @poly.divides(head.exponents, m)
          None => false
        }
      })
      if reducible {
        return Ok(Paused({ ..current, skipped: Succ(state.skipped), }))
      }
      let variables = @f4.variables(state.source)
      match monomial(variables, m) {
        Err(error) => Err(error)
        Ok(p) =>
          match @poly.normal_form(p, @f4.polynomials(state.source)) {
            Err(_) => Err(InternalInvariant)
            Ok(normal) =>
              match coordinates(normal, state.source_standard) {
                None => Err(InternalInvariant)
                Some(vector) =>
                  match cached_span(state, vector) {
                    Err(error) => Err(error)
                    Ok((Independent, next_span)) => {
                      if !@core.compare(
                          @core.length(state.standards),
                          @core.length(state.source_standard),
                        ).equal(Less) {
                        return Err(InternalInvariant)
                      }
                      let (queue, seen) = enqueue(
                        state.order,
                        queue,
                        state.seen,
                        multiples(m),
                      )
                      Ok(
                        Paused({
                          ..current,
                          span_state: next_span,
                          queue,
                          seen,
                          standards: @core.append(state.standards, Cons(m, Nil)),
                          vectors: @core.append(
                            state.vectors,
                            Cons(vector, Nil),
                          ),
                        }),
                      )
                    }
                    Ok((Dependent(coefficients), _)) => {
                      let relation : Relation = {
                        monomial: m,
                        standard_monomials: state.standards,
                        coefficients,
                      }
                      match relation_polynomial(variables, relation) {
                        Err(error) => Err(error)
                        Ok(polynomial) =>
                          Ok(
                            Paused({
                              ..current,
                              polynomials: Cons(polynomial, state.polynomials),
                              relations: Cons(relation, state.relations),
                            }),
                          )
                      }
                    }
                  }
              }
          }
      }
    }
  }
}

///|
/// Fuel counts heap pops (including pruned multiples) plus finalization. A pop
/// may perform a full source normal form and an exact incremental reduction.
pub fn run(state : State, fuel : @core.Nat) -> Result[Progress, FglmError] {
  match fuel {
    Zero => Ok(Paused(state))
    Succ(rest) =>
      match step(state) {
        Err(error) => Err(error)
        Ok(Paused(state)) => run(state, rest)
        other => other
      }
  }
}

///|
pub fn convert(
  source : @f4.Basis,
  target : Order,
  max_dimension : @core.Nat,
  fuel : @core.Nat,
) -> Result[Progress, FglmError] {
  match start(source, target, max_dimension) {
    Ok(Paused(state)) => run(state, fuel)
    other => other
  }
}
