///|
/// Find the least exponent x with zero <= x < limit and base^x = target in a
/// checked prime field's multiplicative group. The base need not be a generator.
#derive(Eq, Debug)
pub struct Problem {
  field : @primefield.Field
  base : @binary.Binary
  target : @binary.Binary
  limit : @binary.Binary
}

///|
pub extend Problem with Eq::{equal, not_equal}

///|
pub extend Problem with Debug::{to_repr}

///|
pub fn problem(
  field : @primefield.Field,
  base : @binary.Binary,
  target : @binary.Binary,
  limit : @binary.Binary,
) -> Problem? {
  let modulus = @primefield.modulus(field)
  let base = @modular.reduce(modulus, base)
  let target = @modular.reduce(modulus, target)
  match (@binary.is_zero(base), @binary.is_zero(target)) {
    (false, false) => Some({ field, base, target, limit, })
    _ => None
  }
}

///|
pub fn field(problem : Problem) -> @primefield.Field {
  problem.field
}

///|
pub fn base(problem : Problem) -> @binary.Binary {
  problem.base
}

///|
pub fn target(problem : Problem) -> @binary.Binary {
  problem.target
}

///|
pub fn limit(problem : Problem) -> @binary.Binary {
  problem.limit
}

///|
/// A candidate checked by a fresh modular exponentiation. This establishes a
/// bounded solution, while minimality is supplied by the search order.
#derive(Eq, Debug)
pub struct Logarithm {
  problem : Problem
  exponent : @binary.Binary
}

///|
pub extend Logarithm with Eq::{equal, not_equal}

///|
pub extend Logarithm with Debug::{to_repr}

///|
pub fn instance(logarithm : Logarithm) -> Problem {
  logarithm.problem
}

///|
pub fn exponent(logarithm : Logarithm) -> @binary.Binary {
  logarithm.exponent
}

///|
/// Search-free solution checker. The upper bound is exclusive, even if a larger
/// exponent also satisfies the same group equation.
pub fn check(problem : Problem, exponent : @binary.Binary) -> Logarithm? {
  match @binary.compare(exponent, problem.limit) {
    Less =>
      match
        @binary.compare(
          @modular.power(
            @primefield.modulus(problem.field),
            problem.base,
            exponent,
          ),
          problem.target,
        ) {
        Equal => Some({ problem, exponent, })
        _ => None
      }
    _ => None
  }
}

///|
/// Complete enumeration of the stated finite interval, used as a simple
/// reference. None refers only to that interval.
pub fn naive(problem : Problem) -> Logarithm? {
  let modulus = @primefield.modulus(problem.field)
  fn walk(exponent : @binary.Binary, power : @binary.Binary) -> Logarithm? {
    match @binary.compare(exponent, problem.limit) {
      Less =>
        match @binary.compare(power, problem.target) {
          Equal => check(problem, exponent)
          _ =>
            walk(
              @binary.successor(exponent),
              @modular.multiply(modulus, power, problem.base),
            )
        }
      _ => None
    }
  }
  walk(@binary.zero(), @binary.one())
}

///|
/// Baby-step giant-step with width ceil(sqrt(limit)). Persistent Bool trie keys
/// are canonical residue bits; repeated baby residues retain the least index.
/// None is a bounded-search result, not a general nonexistence certificate.
pub fn baby_step_giant_step(problem : Problem) -> Logarithm? {
  let modulus = @primefield.modulus(problem.field)
  match check(problem, @binary.zero()) {
    Some(logarithm) => Some(logarithm)
    None =>
      match @binary.is_zero(problem.limit) {
        true => None
        false => {
          let (root, remainder) = @binary.sqrt_rem(problem.limit)
          let width = match @binary.is_zero(remainder) {
            true => root
            false => @binary.successor(root)
          }
          fn babies(
            index : @binary.Binary,
            power : @binary.Binary,
            table : @trie.Trie[@binary.Binary],
          ) -> @trie.Trie[@binary.Binary] {
            match @binary.compare(index, width) {
              Less => {
                let key = @binary.bits(power)
                let table = match @trie.lookup(table, key) {
                  Some(_) => table
                  None => @trie.put(table, key, index)
                }
                babies(
                  @binary.successor(index),
                  @modular.multiply(modulus, power, problem.base),
                  table,
                )
              }
              _ => table
            }
          }
          let table = babies(@binary.zero(), @binary.one(), @trie.empty())
          match
            @modular.inverse(
              modulus,
              @modular.power(modulus, problem.base, width),
            ) {
            None => None
            Some(stride) => {
              fn giants(
                offset : @binary.Binary,
                power : @binary.Binary,
              ) -> Logarithm? {
                match @binary.compare(offset, problem.limit) {
                  Less => {
                    let found = match @trie.lookup(table, @binary.bits(power)) {
                      None => None
                      Some(index) => check(problem, @binary.add(offset, index))
                    }
                    match found {
                      Some(logarithm) => Some(logarithm)
                      None =>
                        giants(
                          @binary.add(offset, width),
                          @modular.multiply(modulus, power, stride),
                        )
                    }
                  }
                  _ => None
                }
              }
              giants(@binary.zero(), problem.target)
            }
          }
        }
      }
  }
}
