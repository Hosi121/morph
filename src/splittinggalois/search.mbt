///|
/// A DFS frame retains only one prefix and its remaining choices. Children are
/// expanded one at a time, never constructing the factorial permutation list.
#derive(Debug)
struct Frame {
  prefix : @core.Chain[@core.Nat]
  remaining : @core.Chain[@core.Nat]
  choices : @core.Chain[@core.Nat]
}

///|
pub extend Frame with Debug::{to_repr}

///|
#derive(Debug)
pub struct Search {
  priv source : @split.Splitting
  priv stack : @core.Chain[Frame]
  priv maps : @core.Chain[MapCertificate]
}

///|
pub extend Search with Debug::{to_repr}

///|
#derive(Debug)
pub(all) enum Progress {
  Ready(Group, Certificate)
  Paused(Search)
}

///|
pub extend Progress with Debug::{to_repr}

///|
pub fn start(source : @split.Splitting) -> Result[Search, GaloisError] {
  if !@split.check_result(
      @split.source(source),
      @split.ambient(source),
      source,
      @split.certificate(source),
    ) {
    return Err(InvalidSource)
  }
  let indices = @core.indices(@core.length(@split.roots(source)))
  Ok({
    source,
    stack: Cons({ prefix: Nil, remaining: indices, choices: indices, }, Nil),
    maps: Nil,
  })
}

///|
fn remove(
  value : @core.Nat,
  values : @core.Chain[@core.Nat],
) -> @core.Chain[@core.Nat] {
  @core.filter(values, fn(other) { !value.equal(other) })
}

///|
fn next_permutation(
  stack : @core.Chain[Frame],
) -> (@core.Chain[@core.Nat], @core.Chain[Frame])? {
  match stack {
    Nil => None
    Cons(frame, rest) =>
      match frame.remaining {
        Nil => Some((@core.reverse(frame.prefix), rest))
        Cons(_, _) =>
          match frame.choices {
            Nil => next_permutation(rest)
            Cons(choice, choices) => {
              let remaining = remove(choice, frame.remaining)
              next_permutation(
                Cons(
                  {
                    prefix: Cons(choice, frame.prefix),
                    remaining,
                    choices: remaining,
                  },
                  Cons({ ..frame, choices, }, rest),
                ),
              )
            }
          }
      }
  }
}

///|
fn rational_nat(value : @core.Nat) -> @exact.Rational {
  match value {
    Zero => @exact.rational_zero()
    Succ(rest) => @exact.rational_add(@exact.rational_one(), rational_nat(rest))
  }
}

///|
fn power(value : @cf.Element, exponent : @core.Nat) -> @cf.Element? {
  match exponent {
    Zero => Some(@cf.one(@cf.parent(value)))
    Succ(rest) =>
      match power(value, rest) {
        Some(previous) =>
          match @cf.multiply(value, previous) {
            Ok(result) => Some(result)
            Err(_) => None
          }
        None => None
      }
  }
}

///|
fn monomial(
  source : @cf.Field,
  roots : @core.Chain[@cf.Element],
  exponents : @core.Chain[@core.Nat],
) -> @cf.Element? {
  match (roots, exponents) {
    (Nil, Nil) => Some(@cf.one(source))
    (Cons(root, rest), Cons(exponent, tail)) =>
      match (power(root, exponent), monomial(source, rest, tail)) {
        (Some(a), Some(b)) =>
          match @cf.multiply(a, b) {
            Ok(value) => Some(value)
            Err(_) => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// Substitute the proposed root permutation into the certified monomial basis
/// and into theta = sum_j c^j*basis_j. No ambient i action is assumed.
fn proposed_image(
  source : @split.Splitting,
  permutation : @core.Chain[@core.Nat],
) -> @cf.Element? {
  fn roots(todo : @core.Chain[@core.Nat]) -> @core.Chain[@cf.Element]? {
    match todo {
      Nil => Some(Nil)
      Cons(index, rest) =>
        match (@core.nth(@split.roots(source), index), roots(rest)) {
          (Some(root), Some(tail)) => Some(Cons(root.value, tail))
          _ => None
        }
    }
  }
  let images = match roots(permutation) {
    Some(value) => value
    None => return None
  }
  let candidate = rational_nat(@split.certificate(source).primitive.candidate)
  let ambient = @split.ambient(source)
  fn sum(
    todo : @core.Chain[@core.Chain[@core.Nat]],
    coefficient : @exact.Rational,
  ) -> @cf.Element? {
    match todo {
      Nil => Some(@cf.zero(ambient))
      Cons(exponents, rest) =>
        match
          (
            monomial(ambient, images, exponents),
            sum(rest, @exact.rational_multiply(coefficient, candidate)),
          ) {
          (Some(value), Some(tail)) =>
            match @cf.multiply(@cf.rational(ambient, coefficient), value) {
              Ok(weighted) =>
                match @cf.add(weighted, tail) {
                  Ok(result) => Some(result)
                  Err(_) => None
                }
              Err(_) => None
            }
          _ => None
        }
    }
  }
  sum(@split.certificate(source).generated.monomials, @exact.rational_one())
}

///|
/// Budget counts complete permutation trials. DFS traversal and a trial's exact
/// arithmetic finish atomically. A pause retains the next untried permutation.
pub fn advance(
  search : Search,
  budget : @core.Nat,
) -> Result[Progress, GaloisError] {
  if @core.length(search.maps).equal(@split.degree(search.source)) {
    return finish(search.source, @core.reverse(search.maps))
  }
  match budget {
    Zero => Ok(Paused(search))
    Succ(rest) =>
      match next_permutation(search.stack) {
        None => Err(InternalInvariant)
        Some((permutation, stack)) => {
          let image = match proposed_image(search.source, permutation) {
            Some(value) => value
            None => return Err(InternalInvariant)
          }
          let map : MapCertificate = { permutation, image, }
          let maps : @core.Chain[MapCertificate] = if valid_map(
              search.source,
              map,
            ) &&
            !@core.any(search.maps, fn(other) { @cf.equal(image, other.image) }) {
            Cons(map, search.maps)
          } else {
            search.maps
          }
          advance({ ..search, stack, maps, }, rest)
        }
      }
  }
}
