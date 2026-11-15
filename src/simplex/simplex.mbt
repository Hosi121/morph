///|
/// Maximize c*x subject to A*x <= b and x >= 0. Requires b >= 0.
/// This checked domain starts feasible at the origin; no Phase I is needed.
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
      @core.all(b, nonnegative),
    ) {
    (true, Equal, true) => Some({ a, b, c, })
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
pub struct State {
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
  Paused(State)
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(p : Problem) -> State {
  let n = @matrix.width(p.a)
  let m = @matrix.height(p.a)
  fn build(
    a : @core.Chain[@core.Chain[@exact.Rational]],
    b : @core.Chain[@exact.Rational],
    row : @core.Nat,
  ) -> @core.Chain[Row] {
    match (a, b) {
      (Cons(coefficients, a), Cons(value, b)) => {
        let unit = @core.map(@core.indices(m), fn(i) {
          match @core.compare(i, row) {
            Equal => @exact.rational_one()
            _ => @exact.rational_zero()
          }
        })
        Cons(
          {
            basic: @core.add(n, row),
            coefficients: @core.append(coefficients, unit),
            value,
          },
          build(a, b, Succ(row)),
        )
      }
      _ => Nil
    }
  }
  {
    problem: p,
    rows: build(@matrix.rows(p.a), p.b, Zero),
    objective: @core.append(
      @core.map(p.c, @exact.rational_negate),
      @core.replicate(m, @exact.rational_zero()),
    ),
    value: @exact.rational_zero(),
  }
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
/// Fuel counts pivots, and a paused tableau can be resumed exactly.
pub fn run(state : State, fuel : @core.Nat) -> Progress {
  match entering(state.objective, Zero) {
    None =>
      Optimal({
        primal: primal(state),
        dual: @core.drop(@matrix.width(state.problem.a), state.objective),
        value: state.value,
      })
    Some(column) =>
      match leaving(state.rows, column) {
        None => Unbounded(unbounded_ray(state, column))
        Some(selected) =>
          match fuel {
            Zero => Paused(state)
            Succ(rest) => run(pivot(state, column, selected), rest)
          }
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
