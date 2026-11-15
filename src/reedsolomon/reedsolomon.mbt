///|
/// Evaluation-form Reed-Solomon over an odd prime field, coefficient message order.
#derive(Eq, Debug)
pub struct Plan {
  field : @finitefield.Field
  message_size : @core.Nat
  errors : @core.Nat
  points : @core.Chain[@binary.Binary]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
pub fn plan(
  field : @finitefield.Field,
  message_size : @core.Nat,
  errors : @core.Nat,
  points : @core.Chain[@binary.Binary],
) -> Plan? {
  fn unique(points : @core.Chain[@binary.Binary]) -> Bool {
    match points {
      Nil => true
      Cons(x, rest) =>
        !@core.any(rest, fn(y) {
          match @binary.compare(x, y) {
            Equal => true
            _ => false
          }
        }) &&
        unique(rest)
    }
  }
  let required = @core.add(message_size, @core.add(errors, errors))
  let prime = @modular.value(@finitefield.modulus(field))
  let canonical = @core.all(points, fn(x) {
    match @binary.compare(x, prime) {
      Less => true
      _ => false
    }
  })
  match
    (
      @core.is_zero(message_size),
      @core.compare(@core.length(points), required),
      unique(points) && canonical,
    ) {
    (false, Equal, true) | (false, Greater, true) =>
      Some({ field, message_size, errors, points, })
    _ => None
  }
}

///|
fn evaluate(
  m : @modular.Modulus,
  coefficients : @core.Chain[@binary.Binary],
  x : @binary.Binary,
) -> @binary.Binary {
  match coefficients {
    Nil => @binary.zero()
    Cons(a, rest) =>
      @modular.add(m, a, @modular.multiply(m, x, evaluate(m, rest, x)))
  }
}

///|
pub fn encode(
  plan : Plan,
  message : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary]? {
  match @core.compare(@core.length(message), plan.message_size) {
    Equal =>
      Some(
        @core.map(plan.points, fn(x) {
          evaluate(@finitefield.modulus(plan.field), message, x)
        }),
      )
    _ => None
  }
}

///|
fn trim(
  coefficients : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  fn leading(xs : @core.Chain[@binary.Binary]) -> @core.Chain[@binary.Binary] {
    match xs {
      Nil => Nil
      Cons(x, rest) =>
        match @binary.is_zero(x) {
          true => leading(rest)
          false => xs
        }
    }
  }
  @core.reverse(leading(@core.reverse(coefficients)))
}

///|
fn combine(
  m : @modular.Modulus,
  a : @core.Chain[@binary.Binary],
  b : @core.Chain[@binary.Binary],
  subtract : Bool,
) -> @core.Chain[@binary.Binary] {
  match (a, b) {
    (Nil, Nil) => Nil
    (Cons(x, rest), Nil) => Cons(x, combine(m, rest, Nil, subtract))
    (Nil, Cons(y, rest)) =>
      Cons(
        match subtract {
          true => @modular.subtract(m, @binary.zero(), y)
          false => y
        },
        combine(m, Nil, rest, subtract),
      )
    (Cons(x, xs), Cons(y, ys)) =>
      Cons(
        match subtract {
          true => @modular.subtract(m, x, y)
          false => @modular.add(m, x, y)
        },
        combine(m, xs, ys, subtract),
      )
  }
}

///|
/// Dense monic long division; each successful step strictly drops the numerator degree.
fn divide(
  m : @modular.Modulus,
  numerator : @core.Chain[@binary.Binary],
  denominator : @core.Chain[@binary.Binary],
) -> (@core.Chain[@binary.Binary], @core.Chain[@binary.Binary])? {
  let numerator = trim(numerator)
  match @core.compare(@core.length(numerator), @core.length(denominator)) {
    Less => Some((Nil, numerator))
    _ =>
      match @core.last(numerator) {
        None => None
        Some(coefficient) => {
          let shift = @core.subtract(
            @core.length(numerator),
            @core.length(denominator),
          )
          let zeros = @core.replicate(shift, @binary.zero())
          let product = @core.append(
            zeros,
            @core.map(denominator, fn(x) {
              @modular.multiply(m, coefficient, x)
            }),
          )
          let remainder = trim(combine(m, numerator, product, true))
          match
            @core.compare(@core.length(remainder), @core.length(numerator)) {
            Less =>
              match divide(m, remainder, denominator) {
                None => None
                Some((quotient, rest)) =>
                  Some(
                    (
                      combine(
                        m,
                        quotient,
                        @core.append(zeros, Cons(coefficient, Nil)),
                        false,
                      ),
                      rest,
                    ),
                  )
              }
            _ => None
          }
        }
      }
  }
}

///|
fn powers(
  m : @modular.Modulus,
  x : @binary.Binary,
  count : @core.Nat,
) -> @core.Chain[@binary.Binary] {
  fn build(
    count : @core.Nat,
    value : @binary.Binary,
    reversed : @core.Chain[@binary.Binary],
  ) -> @core.Chain[@binary.Binary] {
    match count {
      Zero => @core.reverse(reversed)
      Succ(rest) =>
        build(rest, @modular.multiply(m, value, x), Cons(value, reversed))
    }
  }
  build(count, @binary.one(), Nil)
}

///|
fn allowance(plan : Plan, retained : @core.Nat) -> @core.Nat? {
  match @core.compare(retained, plan.message_size) {
    Less => None
    _ =>
      match
        @core.divmod(
          @core.subtract(retained, plan.message_size),
          Succ(Succ(Zero)),
        ) {
        None => None
        Some((capacity, _)) => Some(@core.minimum(plan.errors, capacity))
      }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Decoded {
  message : @core.Chain[@binary.Binary]
  corrected : @core.Chain[@binary.Binary]
  error_positions : @core.Chain[@core.Nat]
  erasure_positions : @core.Chain[@core.Nat]
}

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with Debug::{to_repr}

///|
fn differences(
  m : @modular.Modulus,
  received : @core.Chain[@binary.Binary?],
  corrected : @core.Chain[@binary.Binary],
) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat])? {
  fn scan(
    received : @core.Chain[@binary.Binary?],
    corrected : @core.Chain[@binary.Binary],
    index : @core.Nat,
    errors : @core.Chain[@core.Nat],
    erasures : @core.Chain[@core.Nat],
  ) -> (@core.Chain[@core.Nat], @core.Chain[@core.Nat])? {
    match (received, corrected) {
      (Nil, Nil) => Some((@core.reverse(errors), @core.reverse(erasures)))
      (Cons(value, rx), Cons(expected, cx)) =>
        match value {
          None => scan(rx, cx, Succ(index), errors, Cons(index, erasures))
          Some(value) =>
            match @binary.compare(@modular.reduce(m, value), expected) {
              Equal => scan(rx, cx, Succ(index), errors, erasures)
              _ => scan(rx, cx, Succ(index), Cons(index, errors), erasures)
            }
        }
      _ => None
    }
  }
  scan(received, corrected, Zero, Nil, Nil)
}

///|
/// Berlekamp-Welch: solve Q(x_i)=y_i*E(x_i), E monic of the available error degree.
/// With erasures, use min(configured errors, floor((retained-k)/two)).
pub fn decode_erasures(
  plan : Plan,
  received : @core.Chain[@binary.Binary?],
) -> Decoded? {
  let m = @finitefield.modulus(plan.field)
  let observations = match @core.zip(plan.points, received) {
    None => return None
    Some(pairs) => pairs
  }
  let retained = @core.filter(observations, fn(pair) {
    let (_, y) = pair
    match y {
      None => false
      Some(_) => true
    }
  })
  let errors = match allowance(plan, @core.length(retained)) {
    None => return None
    Some(errors) => errors
  }
  let q_width = @core.add(plan.message_size, errors)
  let columns = @core.add(q_width, errors)
  let equations = @core.map(retained, fn(pair) {
    let (x, y) = pair
    let y = match y {
      None => @binary.zero()
      Some(y) => @modular.reduce(m, y)
    }
    let q = powers(m, x, q_width)
    let e = @core.map(powers(m, x, errors), fn(power) {
      @modular.subtract(m, @binary.zero(), @modular.multiply(m, y, power))
    })
    (
      @core.append(q, e),
      @modular.multiply(m, y, @modular.power(m, x, @binary.from_nat(errors))),
    )
  })
  let rows = @core.map(equations, fn(pair) {
    let (row, _) = pair
    row
  })
  let right = @core.map(equations, fn(pair) {
    let (_, rhs) = pair
    rhs
  })
  let matrix = match @matrix.matrix(columns, rows) {
    None => return None
    Some(matrix) => matrix
  }
  let solution = match
    @rowreduce.solve(@finitefield.arithmetic(plan.field), matrix, right) {
    Some(Unique(solution)) | Some(Affine(solution, _)) => solution
    _ => return None
  }
  let q = @core.take(q_width, solution)
  let e = @core.append(@core.drop(q_width, solution), Cons(@binary.one(), Nil))
  match divide(m, q, e) {
    None => None
    Some((quotient, remainder)) =>
      match
        (
          @core.compare(@core.length(quotient), plan.message_size),
          trim(remainder),
        ) {
        (Greater, _) | (_, Cons(_, _)) => None
        _ => {
          let message = @core.append(
            quotient,
            @core.replicate(
              @core.subtract(plan.message_size, @core.length(quotient)),
              @binary.zero(),
            ),
          )
          match encode(plan, message) {
            None => None
            Some(corrected) =>
              match differences(m, received, corrected) {
                None => None
                Some((error_positions, erasure_positions)) =>
                  match @core.compare(@core.length(error_positions), errors) {
                    Greater => None
                    _ =>
                      Some({
                        message,
                        corrected,
                        error_positions,
                        erasure_positions,
                      })
                  }
              }
          }
        }
      }
  }
}

///|
pub fn decode(plan : Plan, received : @core.Chain[@binary.Binary]) -> Decoded? {
  decode_erasures(plan, @core.map(received, fn(value) { Some(value) }))
}

///|
/// Verify message evaluation, reported locations and correction radius without solving equations.
pub fn check(
  plan : Plan,
  received : @core.Chain[@binary.Binary?],
  decoded : Decoded,
) -> Bool {
  match encode(plan, decoded.message) {
    None => false
    Some(corrected) =>
      match
        (
          @core.zip(corrected, decoded.corrected),
          differences(@finitefield.modulus(plan.field), received, corrected),
        ) {
        (Some(pairs), Some((errors, erasures))) => {
          let retained = @core.subtract(
            @core.length(corrected),
            @core.length(erasures),
          )
          let same_errors = match @core.zip(errors, decoded.error_positions) {
            None => false
            Some(pairs) =>
              @core.all(pairs, fn(pair) {
                let (a, b) = pair
                match @core.compare(a, b) {
                  Equal => true
                  _ => false
                }
              })
          }
          let same_erasures = match
            @core.zip(erasures, decoded.erasure_positions) {
            None => false
            Some(pairs) =>
              @core.all(pairs, fn(pair) {
                let (a, b) = pair
                match @core.compare(a, b) {
                  Equal => true
                  _ => false
                }
              })
          }
          let equal = @core.all(pairs, fn(pair) {
            let (a, b) = pair
            match @binary.compare(a, b) {
              Equal => true
              _ => false
            }
          })
          match allowance(plan, retained) {
            None => false
            Some(capacity) =>
              match @core.compare(@core.length(errors), capacity) {
                Greater => false
                _ => equal && same_errors && same_erasures
              }
          }
        }
        _ => false
      }
  }
}
