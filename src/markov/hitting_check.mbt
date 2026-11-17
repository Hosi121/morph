///|
fn valid_path(
  value : Kernel,
  targets : @core.Chain[Bool],
  start : @core.Nat,
  path : @core.Chain[@core.Nat],
) -> Bool {
  match path {
    Nil => false
    Cons(head, Nil) =>
      head.equal(start) && @core.nth(targets, head) is Some(true)
    Cons(head, Cons(next, _) as rest) =>
      if !head.equal(start) {
        false
      } else {
        match @core.nth(@matrix.rows(value.transition), head) {
          None => false
          Some(row) =>
            match @core.nth(row, next) {
              None => false
              Some(weight) =>
                positive_probability(weight) &&
                valid_path(value, targets, next, rest)
            }
        }
      }
  }
}

///|
fn closed_unreachable(
  row : @core.Chain[@exact.Rational],
  paths : @core.Chain[@core.Chain[@core.Nat]?],
) -> Bool {
  match @core.zip(row, paths) {
    None => false
    Some(pairs) =>
      @core.all(pairs, fn(pair) {
        let (weight, destination) = pair
        !positive_probability(weight) || destination is None
      })
  }
}

///|
fn scalar_product(
  a : @core.Chain[@exact.Rational],
  b : @core.Chain[@exact.Rational],
) -> @exact.Rational? {
  match (a, b) {
    (Nil, Nil) => Some(@exact.rational_zero())
    (Cons(x, xs), Cons(y, ys)) =>
      match scalar_product(xs, ys) {
        None => None
        Some(rest) =>
          Some(@exact.rational_add(@exact.rational_multiply(x, y), rest))
      }
    _ => None
  }
}

///|
/// No arithmetic 0*infinity convention is needed: zero-weight edges are skipped,
/// while a positive edge to Infinite rules out a finite current expectation.
fn weighted_time(
  row : @core.Chain[@exact.Rational],
  times : @core.Chain[HittingTime],
) -> @exact.Rational? {
  match (row, times) {
    (Nil, Nil) => Some(@exact.rational_zero())
    (Cons(weight, rest), Cons(duration, tail)) =>
      if !positive_probability(weight) {
        weighted_time(rest, tail)
      } else {
        match (duration, weighted_time(rest, tail)) {
          (Finite(value), Some(previous)) =>
            Some(
              @exact.rational_add(
                @exact.rational_multiply(weight, value),
                previous,
              ),
            )
          _ => None
        }
      }
    _ => None
  }
}

///|
/// Verifies local paths, the target-disjoint closed unreachable set, and the
/// original first-step equations. It does not call reach_paths, hitting, solve,
/// RREF, or the producer's Dirichlet matrix builder. These graph certificates
/// select the minimal hitting solution rather than any harmonic fixed point.
pub fn check_hitting(
  value : Kernel,
  target_indices : @core.Chain[@core.Nat],
  result : Hitting,
) -> Bool {
  match target_mask(value, target_indices) {
    Err(_) => false
    Ok(targets) => {
      let count = states(value)
      if !value.equal(result.context) ||
        !targets.equal(result.targets) ||
        !@core.length(result.chances).equal(count) ||
        !@core.length(result.times).equal(count) ||
        !@core.length(result.paths).equal(count) ||
        !@core.all(result.chances, fn(chance) {
          nonnegative(chance) &&
          !(@exact.rational_compare(chance, @exact.rational_one()) is Greater)
        }) {
        return false
      }
      fn rows(
        matrix_rows : @core.Chain[@core.Chain[@exact.Rational]],
        flags : @core.Chain[Bool],
        chances : @core.Chain[@exact.Rational],
        paths : @core.Chain[@core.Chain[@core.Nat]?],
        times : @core.Chain[HittingTime],
        index : @core.Nat,
      ) -> Bool {
        match (matrix_rows, flags, chances, paths, times) {
          (Nil, Nil, Nil, Nil, Nil) => true
          (
            Cons(row, rest),
            Cons(target, targets),
            Cons(chance, probabilities),
            Cons(path, witnesses),
            Cons(duration, durations),
          ) => {
            let reachable = match path {
              Some(path) => valid_path(value, result.targets, index, path)
              None => !target && closed_unreachable(row, result.paths)
            }
            let harmonic = if target {
              chance.equal(@exact.rational_one())
            } else if path is None {
              chance.equal(@exact.rational_zero())
            } else {
              match scalar_product(row, result.chances) {
                Some(actual) => actual.equal(chance)
                None => false
              }
            }
            let expectation = if target {
              duration.equal(Finite(@exact.rational_zero()))
            } else if !chance.equal(@exact.rational_one()) {
              duration is Infinite
            } else {
              match (duration, weighted_time(row, result.times)) {
                (Finite(time), Some(next)) =>
                  nonnegative(time) &&
                  time.equal(@exact.rational_add(@exact.rational_one(), next))
                _ => false
              }
            }
            reachable &&
            harmonic &&
            expectation &&
            rows(
              rest,
              targets,
              probabilities,
              witnesses,
              durations,
              Succ(index),
            )
          }
          _ => false
        }
      }
      rows(
        @matrix.rows(value.transition),
        targets,
        result.chances,
        result.paths,
        result.times,
        Zero,
      )
    }
  }
}
