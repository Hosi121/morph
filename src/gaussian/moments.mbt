///|
type Cache = @avl.OrderedMap[@core.Chain[@core.Nat], @exact.Rational]

///|
/// Persistent memoization bound to one Gaussian's checked parameters.
#derive(Eq, Debug)
pub struct Moments {
  source : Gaussian
  cache : Cache
}

///|
pub extend Moments with Eq::{equal, not_equal}

///|
pub extend Moments with Debug::{to_repr}

///|
pub fn moments(source : Gaussian) -> Moments {
  { source, cache: @avl.empty(), }
}

///|
pub fn moments_source(value : Moments) -> Gaussian {
  value.source
}

///|
pub fn cached_moments(value : Moments) -> @binary.Binary {
  @avl.size(value.cache)
}

///|
fn compare_exponents(
  a : @core.Chain[@core.Nat],
  b : @core.Chain[@core.Nat],
) -> @core.Ordering {
  match (a, b) {
    (Nil, Nil) => Equal
    (Nil, _) => Less
    (_, Nil) => Greater
    (Cons(a, aa), Cons(b, bb)) =>
      match @core.compare(a, b) {
        Equal => compare_exponents(aa, bb)
        other => other
      }
  }
}

///|
fn first_positive(
  exponents : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> (@core.Nat, @core.Chain[@core.Nat])? {
  match exponents {
    Nil => None
    Cons(Succ(exponent), rest) => Some((index, Cons(exponent, rest)))
    Cons(Zero, rest) =>
      match first_positive(rest, Succ(index)) {
        None => None
        Some((index, rest)) => Some((index, Cons(Zero, rest)))
      }
  }
}

///|
fn decrement(
  values : @core.Chain[@core.Nat],
  index : @core.Nat,
) -> @core.Chain[@core.Nat]? {
  match (values, index) {
    (Cons(Succ(value), rest), Zero) => Some(Cons(value, rest))
    (Cons(value, rest), Succ(index)) =>
      match decrement(rest, index) {
        None => None
        Some(rest) => Some(Cons(value, rest))
      }
    _ => None
  }
}

///|
fn weighted_children(
  source : Gaussian,
  exponents : @core.Chain[@core.Nat],
  counts : @core.Chain[@core.Nat],
  i : @core.Nat,
  j : @core.Nat,
  cache : Cache,
  accumulated : @exact.Rational,
) -> (@exact.Rational, Cache) {
  match counts {
    Nil => (accumulated, cache)
    Cons(Zero, rest) =>
      weighted_children(source, exponents, rest, i, Succ(j), cache, accumulated)
    Cons(count, rest) => {
      let coefficient = @exact.rational_multiply(
        @exact.whole(@exact.positive(@binary.from_nat(count))),
        entry(source.covariance, i, j),
      )
      match @exact.nonzero(coefficient) {
        None =>
          weighted_children(
            source,
            exponents,
            rest,
            i,
            Succ(j),
            cache,
            accumulated,
          )
        Some(_) =>
          match decrement(exponents, j) {
            None => (accumulated, cache)
            Some(child) => {
              let (value, cache) = raw_moment(source, child, cache)
              weighted_children(
                source,
                exponents,
                rest,
                i,
                Succ(j),
                cache,
                @exact.rational_add(
                  accumulated,
                  @exact.rational_multiply(coefficient, value),
                ),
              )
            }
          }
      }
    }
  }
}

///|
// Stein recursion strictly lowers total degree. All exponent dimensions and
// parameter shapes are checked by public constructors before this recursion.
fn raw_moment(
  source : Gaussian,
  exponents : @core.Chain[@core.Nat],
  cache : Cache,
) -> (@exact.Rational, Cache) {
  match @avl.lookup(cache, exponents, compare_exponents) {
    Some(value) => (value, cache)
    None => {
      let (value, cache) = match first_positive(exponents, Zero) {
        None => (@exact.rational_one(), cache)
        Some((i, rest)) => {
          let mean = component(source.mean, i)
          let (first, cache) = match @exact.nonzero(mean) {
            None => (@exact.rational_zero(), cache)
            Some(_) => {
              let (value, cache) = raw_moment(source, rest, cache)
              (@exact.rational_multiply(mean, value), cache)
            }
          }
          weighted_children(source, rest, rest, i, Zero, cache, first)
        }
      }
      (value, @avl.put(cache, exponents, value, compare_exponents))
    }
  }
}

///|
pub fn moment_with(
  plan : Moments,
  exponents : @core.Chain[@core.Nat],
) -> Result[(@exact.Rational, Moments), GaussianError] {
  match @core.length(exponents).equal(dimension(plan.source)) {
    false => Err(DimensionMismatch)
    true => {
      let (value, cache) = raw_moment(plan.source, exponents, plan.cache)
      Ok((value, { source: plan.source, cache, }))
    }
  }
}

///|
pub fn moment(
  source : Gaussian,
  exponents : @core.Chain[@core.Nat],
) -> Result[@exact.Rational, GaussianError] {
  match moment_with(moments(source), exponents) {
    Err(error) => Err(error)
    Ok((value, _)) => Ok(value)
  }
}

///|
fn evaluate_terms(
  plan : Moments,
  terms : @core.Chain[@polynomial.Term],
  accumulated : @exact.Rational,
) -> (@exact.Rational, Moments) {
  match terms {
    Nil => (accumulated, plan)
    Cons(term, rest) => {
      let (value, cache) = raw_moment(plan.source, term.exponents, plan.cache)
      let plan = Moments::{ source: plan.source, cache, }
      evaluate_terms(
        plan,
        rest,
        @exact.rational_add(
          accumulated,
          @exact.rational_multiply(term.coefficient, value),
        ),
      )
    }
  }
}

///|
pub fn expectation_with(
  plan : Moments,
  polynomial : @polynomial.Polynomial,
) -> Result[(@exact.Rational, Moments), GaussianError] {
  match @polynomial.variables(polynomial).equal(dimension(plan.source)) {
    false => Err(DimensionMismatch)
    true =>
      Ok(
        evaluate_terms(
          plan,
          @polynomial.terms(polynomial),
          @exact.rational_zero(),
        ),
      )
  }
}

///|
pub fn expectation(
  source : Gaussian,
  polynomial : @polynomial.Polynomial,
) -> Result[@exact.Rational, GaussianError] {
  match expectation_with(moments(source), polynomial) {
    Err(error) => Err(error)
    Ok((value, _)) => Ok(value)
  }
}
