///|
#derive(Eq, Debug)
pub struct Pair {
  left : Annotated
  right : Annotated
  degree : @core.Nat
}

///|
pub extend Pair with Eq::{equal, not_equal}

///|
pub extend Pair with Debug::{to_repr}

///|
/// Structural statistics for a completed Macaulay batch. Counts are not timing
/// claims; reducer_rows excludes the two seed multiples per selected S-pair.
#derive(Eq, Debug)
pub(all) struct Batch {
  degree : @core.Nat
  selected_pairs : @core.Nat
  seed_rows : @core.Nat
  reducer_rows : @core.Nat
  columns : @core.Nat
  new_rows : @core.Nat
}

///|
pub extend Batch with Eq::{equal, not_equal}

///|
pub extend Batch with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct State {
  variables : @core.Nat
  inputs : @core.Chain[@poly.Polynomial]
  candidates : @core.Chain[Annotated]
  pairs : @core.Chain[Pair]
  batches : @core.Chain[Batch]
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Basis {
  variables : @core.Nat
  inputs : @core.Chain[@poly.Polynomial]
  certificate : Certificate
  batches : @core.Chain[Batch]
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
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn variables(value : Basis) -> @core.Nat {
  value.variables
}

///|
pub fn certificate(value : Basis) -> Certificate {
  value.certificate
}

///|
pub fn polynomials(value : Basis) -> @core.Chain[@poly.Polynomial] {
  value.certificate.polynomials
}

///|
pub fn history(value : Basis) -> @core.Chain[Batch] {
  value.batches
}

///|
pub fn state_history(value : State) -> @core.Chain[Batch] {
  @core.reverse(value.batches)
}

///|
pub fn pending(value : State) -> @core.Nat {
  @core.length(value.pairs)
}

///|
pub fn verify(value : Basis) -> Result[Bool, F4Error] {
  check(value.variables, value.inputs, value.certificate)
}

///|
fn pair(a : Annotated, b : Annotated) -> Result[Pair, F4Error] {
  match (@poly.terms(a.value), @poly.terms(b.value)) {
    (Cons(x, _), Cons(y, _)) =>
      match @poly.monomial_lcm(x.exponents, y.exponents) {
        None => Err(InternalInvariant)
        Some(lcm) =>
          Ok({
            left: a,
            right: b,
            degree: @core.fold_left(lcm, Zero, @core.add),
          })
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn all_pairs(
  rows : @core.Chain[Annotated],
) -> Result[@core.Chain[Pair], F4Error] {
  match rows {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      match (traverse(rest, fn(row) { pair(head, row) }), all_pairs(rest)) {
        (Ok(first), Ok(tail)) => Ok(@core.append(first, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
pub fn start(
  variables : @core.Nat,
  inputs : @core.Chain[@poly.Polynomial],
) -> Result[State, F4Error] {
  if !@core.all(inputs, fn(p) {
      @core.compare(@poly.variables(p), variables).equal(Equal)
    }) {
    return Err(DimensionMismatch)
  }
  let input_count = @core.length(inputs)
  fn annotate(
    todo : @core.Chain[@poly.Polynomial],
    index : @core.Nat,
    seen : @core.Chain[@poly.Polynomial],
  ) -> Result[@core.Chain[Annotated], F4Error] {
    match todo {
      Nil => Ok(Nil)
      Cons(value, rest) =>
        if @poly.is_zero(value) {
          annotate(rest, Succ(index), seen)
        } else {
          let row : Annotated = {
            value,
            combination: @core.map(@core.indices(input_count), fn(j) {
              @poly.constant(
                variables,
                if @core.compare(index, j).equal(Equal) {
                  @exact.rational_one()
                } else {
                  @exact.rational_zero()
                },
              )
            }),
          }
          match annotated_monic(row) {
            Err(error) => Err(error)
            Ok(row) =>
              if @core.any(seen, fn(p) { p.equal(row.value) }) {
                annotate(rest, Succ(index), seen)
              } else {
                match annotate(rest, Succ(index), Cons(row.value, seen)) {
                  Err(error) => Err(error)
                  Ok(tail) => Ok(Cons(row, tail))
                }
              }
          }
        }
    }
  }
  match annotate(inputs, Zero, Nil) {
    Err(error) => Err(error)
    Ok(candidates) =>
      match all_pairs(candidates) {
        Err(error) => Err(error)
        Ok(pairs) => Ok({ variables, inputs, candidates, pairs, batches: Nil, })
      }
  }
}

///|
fn pair_rows(value : Pair) -> Result[@core.Chain[Annotated], F4Error] {
  match (@poly.terms(value.left.value), @poly.terms(value.right.value)) {
    (Cons(a, _), Cons(b, _)) =>
      match @poly.monomial_lcm(a.exponents, b.exponents) {
        None => Err(InternalInvariant)
        Some(lcm) =>
          match
            (
              @poly.monomial_quotient(lcm, a.exponents),
              @poly.monomial_quotient(lcm, b.exponents),
              @exact.nonzero(a.coefficient),
              @exact.nonzero(b.coefficient),
            ) {
            (Some(x), Some(y), Some(c), Some(d)) =>
              match
                (
                  annotated_scale(value.left, {
                    coefficient: @exact.reciprocal(c),
                    exponents: x,
                  }),
                  annotated_scale(value.right, {
                    coefficient: @exact.reciprocal(d),
                    exponents: y,
                  }),
                ) {
                (Ok(left), Ok(right)) => Ok(Cons(left, Cons(right, Nil)))
                (Err(error), _) | (_, Err(error)) => Err(error)
              }
            _ => Err(InternalInvariant)
          }
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn seed_rows(
  pairs : @core.Chain[Pair],
) -> Result[@core.Chain[Annotated], F4Error] {
  match pairs {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      match (pair_rows(head), seed_rows(rest)) {
        (Ok(first), Ok(tail)) => Ok(@core.append(first, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
fn minimum_degree(pairs : @core.Chain[Pair], current : @core.Nat) -> @core.Nat {
  @core.fold_left(pairs, current, fn(best, p) { @core.minimum(best, p.degree) })
}

///|
fn add_new(
  rows : @core.Chain[Annotated],
  basis : @core.Chain[Annotated],
  pending : @core.Chain[Pair],
) -> Result[(@core.Chain[Annotated], @core.Chain[Pair], @core.Nat), F4Error] {
  match rows {
    Nil => Ok((basis, pending, Zero))
    Cons(row, rest) =>
      match traverse(basis, fn(g) { pair(row, g) }) {
        Err(error) => Err(error)
        Ok(extra) =>
          match add_new(rest, Cons(row, basis), @core.append(extra, pending)) {
            Err(error) => Err(error)
            Ok((basis, pending, count)) => Ok((basis, pending, Succ(count)))
          }
      }
  }
}

///|
/// Keep one representative per minimal leading monomial, including when distinct
/// initial polynomials have equal leading monomials.
fn minimal(rows : @core.Chain[Annotated]) -> @core.Chain[Annotated] {
  fn strict_divides(a : Annotated, b : Annotated) -> Bool {
    leading_divides(a.value, b.value) && !leading_divides(b.value, a.value)
  }
  fn walk(
    todo : @core.Chain[Annotated],
    kept : @core.Chain[Annotated],
  ) -> @core.Chain[Annotated] {
    match todo {
      Nil => @core.reverse(kept)
      Cons(head, rest) =>
        if @core.any(kept, fn(g) { leading_divides(g.value, head.value) }) ||
          @core.any(rest, fn(g) { strict_divides(g, head) }) {
          walk(rest, kept)
        } else {
          walk(rest, Cons(head, kept))
        }
    }
  }
  walk(rows, Nil)
}

///|
fn interreduce(
  rows : @core.Chain[Annotated],
) -> Result[@core.Chain[Annotated], F4Error] {
  fn reduce_row(
    row : Annotated,
    others : @core.Chain[Annotated],
  ) -> Result[Annotated, F4Error] {
    match @poly.divide(row.value, @core.map(others, fn(g) { g.value })) {
      Err(_) => Err(InternalInvariant)
      Ok(division) => {
        fn subtract_quotients(
          todo : @core.Chain[Annotated],
          quotients : @core.Chain[@poly.Polynomial],
          current : Annotated,
        ) -> Result[Annotated, F4Error] {
          match (todo, quotients) {
            (Nil, Nil) => annotated_monic(current)
            (Cons(g, rest), Cons(q, tail)) =>
              match annotated_multiply(g, @poly.negate(q)) {
                Err(error) => Err(error)
                Ok(scaled) =>
                  match annotated_add(current, scaled) {
                    Err(error) => Err(error)
                    Ok(next) => subtract_quotients(rest, tail, next)
                  }
              }
            _ => Err(InternalInvariant)
          }
        }
        match subtract_quotients(others, division.quotients, row) {
          Err(error) => Err(error)
          Ok(result) =>
            if result.value.equal(@poly.monic(division.remainder)) {
              Ok(result)
            } else {
              Err(InternalInvariant)
            }
        }
      }
    }
  }
  fn walk(
    todo : @core.Chain[Annotated],
    prefix : @core.Chain[Annotated],
  ) -> Result[@core.Chain[Annotated], F4Error] {
    match todo {
      Nil => Ok(Nil)
      Cons(head, rest) =>
        match
          (
            reduce_row(head, @core.reverse_onto(prefix, rest)),
            walk(rest, Cons(head, prefix)),
          ) {
          (Ok(row), Ok(tail)) => Ok(Cons(row, tail))
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  match walk(minimal(rows), Nil) {
    Err(error) => Err(error)
    Ok(rows) =>
      Ok(
        @sorting.merge_sort(rows, fn(a, b) {
          match (@poly.terms(a.value), @poly.terms(b.value)) {
            (Cons(a, _), Cons(b, _)) =>
              match @poly.compare_monomial(a.exponents, b.exponents) {
                Less => Greater
                Greater => Less
                Equal => Equal
              }
            _ => Equal
          }
        }),
      )
  }
}

///|
/// One full minimum-LCM-degree F4 batch, or final interreduction. Core S-pair
/// reduction is solely symbolic preprocessing followed by a Macaulay RREF.
pub fn step(state : State) -> Result[Progress, F4Error] {
  match state.pairs {
    Nil =>
      match interreduce(state.candidates) {
        Err(error) => Err(error)
        Ok(rows) =>
          Ok(
            Complete({
              variables: state.variables,
              inputs: state.inputs,
              certificate: {
                polynomials: @core.map(rows, fn(row) { row.value }),
                combinations: @core.map(rows, fn(row) { row.combination }),
              },
              batches: @core.reverse(state.batches),
            }),
          )
      }
    Cons(first, _) => {
      let degree = minimum_degree(state.pairs, first.degree)
      let selected = @core.filter(state.pairs, fn(p) {
        @core.compare(p.degree, degree).equal(Equal)
      })
      let rest = @core.filter(state.pairs, fn(p) {
        !@core.compare(p.degree, degree).equal(Equal)
      })
      match seed_rows(selected) {
        Err(error) => Err(error)
        Ok(seeds) =>
          match symbolic_preprocessing(seeds, state.candidates) {
            Err(error) => Err(error)
            Ok(rows) =>
              match
                macaulay_reduce(
                  state.variables,
                  @core.length(state.inputs),
                  rows,
                ) {
                Err(error) => Err(error)
                Ok((echelon, columns)) =>
                  match
                    add_new(
                      @core.filter(echelon, fn(row) {
                        !@core.any(state.candidates, fn(g) {
                          leading_divides(g.value, row.value)
                        })
                      }),
                      state.candidates,
                      rest,
                    ) {
                    Err(error) => Err(error)
                    Ok((candidates, pairs, new_rows)) =>
                      Ok(
                        Paused({
                          variables: state.variables,
                          inputs: state.inputs,
                          candidates,
                          pairs,
                          batches: Cons(
                            {
                              degree,
                              selected_pairs: @core.length(selected),
                              seed_rows: @core.length(seeds),
                              reducer_rows: @core.subtract(
                                @core.length(rows),
                                @core.length(seeds),
                              ),
                              columns,
                              new_rows,
                            },
                            state.batches,
                          ),
                        }),
                      )
                  }
              }
          }
      }
    }
  }
}

///|
/// Fuel counts whole Macaulay batches plus finalization, not individual matrix
/// operations, preprocessing steps, allocations or elapsed time.
pub fn run(state : State, fuel : @core.Nat) -> Result[Progress, F4Error] {
  match fuel {
    Zero => Ok(Paused(state))
    Succ(rest) =>
      match step(state) {
        Err(error) => Err(error)
        Ok(Paused(next)) => run(next, rest)
        Ok(Complete(basis)) => Ok(Complete(basis))
      }
  }
}

///|
pub fn f4(
  variables : @core.Nat,
  inputs : @core.Chain[@poly.Polynomial],
  fuel : @core.Nat,
) -> Result[Progress, F4Error] {
  match start(variables, inputs) {
    Err(error) => Err(error)
    Ok(state) => run(state, fuel)
  }
}
