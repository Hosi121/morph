///|
/// Maximize c*x subject to A*x <= b and x >= 0, with arbitrary rational b.
/// Two-phase simplex constructs a feasible basis or a Farkas certificate.
#derive(Eq, Debug)
pub struct Problem {
  a : @matrix.Matrix[@exact.Rational]
  b : @core.Chain[@exact.Rational]
  c : @core.Chain[@exact.Rational]
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
fn nonnegative(x : @exact.Rational) -> Bool {
  match @exact.rational_compare(x, @exact.rational_zero()) {
    Less => false
    _ => true
  }
}

///|
fn positive(x : @exact.Rational) -> Bool {
  match @exact.rational_compare(x, @exact.rational_zero()) {
    Greater => true
    _ => false
  }
}

///|
fn[A, B] same_length(a : @core.Chain[A], b : @core.Chain[B]) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(_, a), Cons(_, b)) => same_length(a, b)
    _ => false
  }
}

///|
pub fn problem(
  a : @matrix.Matrix[@exact.Rational],
  b : @core.Chain[@exact.Rational],
  c : @core.Chain[@exact.Rational],
) -> Problem? {
  match
    (
      same_length(@matrix.rows(a), b),
      @core.compare(@matrix.width(a), @core.length(c)),
    ) {
    (true, Equal) => Some({ a, b, c, })
    _ => None
  }
}

///|
#derive(Eq, Debug)
struct Row {
  basic : @core.Nat
  coefficients : @core.Chain[@exact.Rational]
  value : @exact.Rational
}

///|
pub extend Row with Eq::{equal, not_equal}

///|
pub extend Row with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Phase {
  PhaseOne
  Cleanup
  PhaseTwo
}

///|
pub extend Phase with Eq::{equal, not_equal}

///|
pub extend Phase with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct State {
  phase : Phase
  problem : Problem
  rows : @core.Chain[Row]
  objective : @core.Chain[@exact.Rational]
  value : @exact.Rational
}

///|
pub extend State with Eq::{equal, not_equal}

///|
pub extend State with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Optimum {
  primal : @core.Chain[@exact.Rational]
  dual : @core.Chain[@exact.Rational]
  value : @exact.Rational
}

///|
pub extend Optimum with Eq::{equal, not_equal}

///|
pub extend Optimum with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Ray {
  point : @core.Chain[@exact.Rational]
  direction : @core.Chain[@exact.Rational]
}

///|
pub extend Ray with Eq::{equal, not_equal}

///|
pub extend Ray with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Optimal(Optimum)
  Unbounded(Ray)
  Infeasible(@core.Chain[@exact.Rational])
  Paused(State)
  InvariantViolation
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(p : Problem) -> State {
  let n = @matrix.width(p.a)
  let m = @matrix.height(p.a)
  let first_phase = !@core.all(p.b, nonnegative)
  fn build(
    a : @core.Chain[@core.Chain[@exact.Rational]],
    b : @core.Chain[@exact.Rational],
    row : @core.Nat,
  ) -> @core.Chain[Row] {
    match (a, b) {
      (Cons(coefficients, a), Cons(value, b)) => {
        let reversed = !nonnegative(value)
        let unit = @core.map(@core.indices(m), fn(i) {
          match @core.compare(i, row) {
            Equal => @exact.rational_one()
            _ => @exact.rational_zero()
          }
        })
        let coefficients = @core.append(coefficients, unit)
        let coefficients = match reversed {
          true => @core.map(coefficients, @exact.rational_negate)
          false => coefficients
        }
        let coefficients = match first_phase {
          false => coefficients
          true =>
            @core.append(
              coefficients,
              match reversed {
                true => unit
                false => @core.replicate(m, @exact.rational_zero())
              },
            )
        }
        let value = match reversed {
          true => @exact.rational_negate(value)
          false => value
        }
        let offset = match reversed {
          true => @core.add(n, m)
          false => n
        }
        Cons(
          { basic: @core.add(offset, row), coefficients, value, },
          build(a, b, Succ(row)),
        )
      }
      _ => Nil
    }
  }
  let rows = build(@matrix.rows(p.a), p.b, Zero)
  let objective = match first_phase {
    false =>
      @core.append(
        @core.map(p.c, @exact.rational_negate),
        @core.replicate(m, @exact.rational_zero()),
      )
    true =>
      @core.append(
        @core.replicate(@core.add(n, m), @exact.rational_zero()),
        @core.replicate(m, @exact.rational_one()),
      )
  }
  let state = State::{
    phase: match first_phase {
      true => PhaseOne
      false => PhaseTwo
    },
    problem: p,
    rows,
    objective,
    value: @exact.rational_zero(),
  }
  canonical_objective(state)
}

///|
fn canonical_objective(state : State) -> State {
  let (objective, value) = @core.fold_left(
    state.rows,
    (state.objective, state.value),
    fn(acc, row) {
      let (objective, value) = acc
      let factor = entry(objective, row.basic)
      (
        eliminate(objective, row.coefficients, factor),
        @exact.rational_subtract(
          value,
          @exact.rational_multiply(factor, row.value),
        ),
      )
    },
  )
  { ..state, objective, value, }
}

///|
fn entry(
  xs : @core.Chain[@exact.Rational],
  index : @core.Nat,
) -> @exact.Rational {
  match @core.nth(xs, index) {
    Some(x) => x
    None => @exact.rational_zero()
  }
}

///|
fn entering(xs : @core.Chain[@exact.Rational], index : @core.Nat) -> @core.Nat? {
  match xs {
    Nil => None
    Cons(x, rest) =>
      match nonnegative(x) {
        false => Some(index)
        true => entering(rest, Succ(index))
      }
  }
}

///|
priv struct Pivot {
  row : Row
  reciprocal : @exact.Rational
  ratio : @exact.Rational
}

///|
fn leaving(rows : @core.Chain[Row], column : @core.Nat) -> Pivot? {
  @core.fold_left(rows, None, fn(best, row) {
    let coefficient = entry(row.coefficients, column)
    match (positive(coefficient), @exact.nonzero(coefficient)) {
      (true, Some(proof)) => {
        let reciprocal = @exact.reciprocal(proof)
        let ratio = @exact.rational_multiply(row.value, reciprocal)
        let candidate = Pivot::{ row, reciprocal, ratio, }
        match best {
          None => Some(candidate)
          Some(previous) =>
            match @exact.rational_compare(ratio, previous.ratio) {
              Less => Some(candidate)
              Equal =>
                match @core.compare(row.basic, previous.row.basic) {
                  Less => Some(candidate)
                  _ => best
                }
              Greater => best
            }
        }
      }
      _ => best
    }
  })
}

///|
/// Internal vectors retain the checked common tableau width after every pivot.
fn eliminate(
  xs : @core.Chain[@exact.Rational],
  ys : @core.Chain[@exact.Rational],
  factor : @exact.Rational,
) -> @core.Chain[@exact.Rational] {
  match (xs, ys) {
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(
        @exact.rational_subtract(x, @exact.rational_multiply(factor, y)),
        eliminate(xs, ys, factor),
      )
    _ => Nil
  }
}

///|
fn pivot(state : State, column : @core.Nat, selected : Pivot) -> State {
  let normalized : Row = {
    basic: column,
    coefficients: @core.map(selected.row.coefficients, fn(x) {
      @exact.rational_multiply(x, selected.reciprocal)
    }),
    value: selected.ratio,
  }
  let rows = @core.map(state.rows, fn(row) {
    match @core.compare(row.basic, selected.row.basic) {
      Equal => normalized
      _ => {
        let factor = entry(row.coefficients, column)
        Row::{
          basic: row.basic,
          coefficients: eliminate(
            row.coefficients,
            normalized.coefficients,
            factor,
          ),
          value: @exact.rational_subtract(
            row.value,
            @exact.rational_multiply(factor, normalized.value),
          ),
        }
      }
    }
  })
  let factor = entry(state.objective, column)
  {
    phase: state.phase,
    problem: state.problem,
    rows,
    objective: eliminate(state.objective, normalized.coefficients, factor),
    value: @exact.rational_subtract(
      state.value,
      @exact.rational_multiply(factor, normalized.value),
    ),
  }
}

///|
fn basic_value(rows : @core.Chain[Row], index : @core.Nat) -> @exact.Rational {
  match rows {
    Nil => @exact.rational_zero()
    Cons(row, rest) =>
      match @core.compare(row.basic, index) {
        Equal => row.value
        _ => basic_value(rest, index)
      }
  }
}

///|
fn primal(state : State) -> @core.Chain[@exact.Rational] {
  @core.map(@core.indices(@matrix.width(state.problem.a)), fn(index) {
    basic_value(state.rows, index)
  })
}

///|
fn unbounded_ray(state : State, column : @core.Nat) -> Ray {
  fn direction(rows : @core.Chain[Row], index : @core.Nat) -> @exact.Rational {
    match @core.compare(column, index) {
      Equal => @exact.rational_one()
      _ =>
        match rows {
          Nil => @exact.rational_zero()
          Cons(row, rest) =>
            match @core.compare(row.basic, index) {
              Equal => @exact.rational_negate(entry(row.coefficients, column))
              _ => direction(rest, index)
            }
        }
    }
  }
  {
    point: primal(state),
    direction: @core.map(@core.indices(@matrix.width(state.problem.a)), fn(
      index,
    ) {
      direction(state.rows, index)
    }),
  }
}

///|
/// Bland's least-index entering rule and least-basic-index minimum-ratio tie break.
/// Fuel counts pivots and artificial-basic cleanup steps, not elapsed time.
pub fn run(state : State, fuel : @core.Nat) -> Progress {
  match state.phase {
    Cleanup => cleanup(state, fuel)
    PhaseOne | PhaseTwo =>
      match entering(state.objective, Zero) {
        None =>
          match state.phase {
            PhaseOne =>
              match
                @exact.rational_compare(state.value, @exact.rational_zero()) {
                Less =>
                  Infeasible(
                    @core.take(
                      @matrix.height(state.problem.a),
                      @core.drop(
                        @matrix.width(state.problem.a),
                        state.objective,
                      ),
                    ),
                  )
                Equal => run({ ..state, phase: Cleanup, }, fuel)
                Greater => InvariantViolation
              }
            PhaseTwo =>
              Optimal({
                primal: primal(state),
                dual: @core.drop(
                  @matrix.width(state.problem.a),
                  state.objective,
                ),
                value: state.value,
              })
            Cleanup => InvariantViolation
          }
        Some(column) =>
          match leaving(state.rows, column) {
            None =>
              match state.phase {
                PhaseTwo => Unbounded(unbounded_ray(state, column))
                _ => InvariantViolation
              }
            Some(selected) =>
              match fuel {
                Zero => Paused(state)
                Succ(rest) => run(pivot(state, column, selected), rest)
              }
          }
      }
  }
}

///|
fn cleanup(state : State, fuel : @core.Nat) -> Progress {
  let n = @matrix.width(state.problem.a)
  let m = @matrix.height(state.problem.a)
  let ordinary = @core.add(n, m)
  fn artificial(rows : @core.Chain[Row]) -> Row? {
    match rows {
      Nil => None
      Cons(row, rest) =>
        match @core.compare(row.basic, ordinary) {
          Less => artificial(rest)
          _ => Some(row)
        }
    }
  }
  fn replacement(
    xs : @core.Chain[@exact.Rational],
    index : @core.Nat,
  ) -> (@core.Nat, @exact.Rational)? {
    match xs {
      Nil => None
      Cons(x, rest) =>
        match @exact.nonzero(x) {
          Some(proof) => Some((index, @exact.reciprocal(proof)))
          None => replacement(rest, Succ(index))
        }
    }
  }
  match artificial(state.rows) {
    None => {
      let rows = @core.map(state.rows, fn(row) {
        Row::{ ..row, coefficients: @core.take(ordinary, row.coefficients), }
      })
      let objective = @core.append(
        @core.map(state.problem.c, @exact.rational_negate),
        @core.replicate(m, @exact.rational_zero()),
      )
      run(
        canonical_objective({
          ..state,
          phase: PhaseTwo,
          rows,
          objective,
          value: @exact.rational_zero(),
        }),
        fuel,
      )
    }
    Some(row) =>
      match @exact.rational_compare(row.value, @exact.rational_zero()) {
        Equal =>
          match fuel {
            Zero => Paused(state)
            Succ(rest) =>
              match replacement(@core.take(ordinary, row.coefficients), Zero) {
                Some((column, reciprocal)) =>
                  run(
                    pivot(state, column, {
                      row,
                      reciprocal,
                      ratio: @exact.rational_zero(),
                    }),
                    rest,
                  )
                None => {
                  let rows = @core.filter(state.rows, fn(other) {
                    match @core.compare(row.basic, other.basic) {
                      Equal => false
                      _ => true
                    }
                  })
                  run({ ..state, rows, }, rest)
                }
              }
          }
        _ => InvariantViolation
      }
  }
}

///|
fn dot(
  xs : @core.Chain[@exact.Rational],
  ys : @core.Chain[@exact.Rational],
) -> @exact.Rational {
  match (xs, ys) {
    (Cons(x, xs), Cons(y, ys)) =>
      @exact.rational_add(@exact.rational_multiply(x, y), dot(xs, ys))
    _ => @exact.rational_zero()
  }
}

///|
fn feasible(p : Problem, x : @core.Chain[@exact.Rational]) -> Bool {
  match @core.compare(@core.length(x), @matrix.width(p.a)) {
    Equal =>
      match @core.zip(@matrix.rows(p.a), p.b) {
        None => false
        Some(pairs) =>
          @core.all(x, nonnegative) &&
          @core.all(pairs, fn(pair) {
            let (row, bound) = pair
            nonnegative(@exact.rational_subtract(bound, dot(row, x)))
          })
      }
    _ => false
  }
}

///|
/// Independent primal/dual feasibility and exact equality of objectives.
pub fn check_optimum(p : Problem, certificate : Optimum) -> Bool {
  let x = certificate.primal
  let y = certificate.dual
  match (feasible(p, x), same_length(y, p.b), @core.all(y, nonnegative)) {
    (true, true, true) =>
      match @core.zip(@matrix.rows(@matrix.transpose(p.a)), p.c) {
        None => false
        Some(pairs) => {
          let dual_feasible = @core.all(pairs, fn(pair) {
            let (column, cost) = pair
            nonnegative(@exact.rational_subtract(dot(column, y), cost))
          })
          match
            (
              @exact.rational_compare(dot(p.c, x), certificate.value),
              @exact.rational_compare(dot(p.b, y), certificate.value),
            ) {
            (Equal, Equal) => dual_feasible
            _ => false
          }
        }
      }
    _ => false
  }
}

///|
/// A feasible point and a nonnegative direction d with A*d <= 0 and c*d > 0.
pub fn check_ray(p : Problem, ray : Ray) -> Bool {
  feasible(p, ray.point) &&
  same_length(ray.direction, p.c) &&
  @core.all(ray.direction, nonnegative) &&
  @core.all(@matrix.rows(p.a), fn(row) {
    nonnegative(@exact.rational_negate(dot(row, ray.direction)))
  }) &&
  positive(dot(p.c, ray.direction))
}

///|
/// Farkas contradiction: y>=0, A^T*y>=0, b*y<0 rules out any feasible x>=0.
pub fn check_infeasible(p : Problem, y : @core.Chain[@exact.Rational]) -> Bool {
  same_length(y, p.b) &&
  @core.all(y, nonnegative) &&
  @core.all(@matrix.rows(@matrix.transpose(p.a)), fn(column) {
    nonnegative(dot(column, y))
  }) &&
  !nonnegative(dot(p.b, y))
}
