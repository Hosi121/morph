///|
/// A signed occurrence of a zero-based generator in a finite relator word.
#derive(Eq, Debug)
pub(all) struct Letter {
  generator : @core.Nat
  inverse : Bool
}

///|
pub extend Letter with Eq::{equal, not_equal}

///|
pub extend Letter with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Presentation {
  priv generators : @core.Nat
  priv relators : @core.Chain[@core.Chain[Letter]]
  priv relations : @matrix.Matrix[@exact.Integer]
}

///|
pub extend Presentation with Eq::{equal, not_equal}

///|
pub extend Presentation with Debug::{to_repr}

///|
pub fn inverse_word(word : @core.Chain[Letter]) -> @core.Chain[Letter] {
  @core.reverse(
    @core.map(word, fn(letter) { { ..letter, inverse: !letter.inverse, } }),
  )
}

///|
/// Free cancellation only; this does not use the relators of a presentation.
pub fn reduce_word(word : @core.Chain[Letter]) -> @core.Chain[Letter] {
  @core.reverse(
    @core.fold_left(word, Nil, fn(stack, letter) {
      match stack {
        Cons(head, rest) =>
          if head.generator.equal(letter.generator) &&
            !head.inverse.equal(letter.inverse) {
            rest
          } else {
            Cons(letter, stack)
          }
        Nil => Cons(letter, Nil)
      }
    }),
  )
}

///|
fn valid_word(generators : @core.Nat, word : @core.Chain[Letter]) -> Bool {
  @core.all(word, fn(letter) {
    @core.compare(letter.generator, generators).equal(Less)
  })
}

///|
fn exponent_sum(
  generator : @core.Nat,
  word : @core.Chain[Letter],
) -> @exact.Integer {
  let unit = @exact.positive(@binary.one())
  @core.fold_left(word, @exact.positive(@binary.zero()), fn(sum, letter) {
    if letter.generator.equal(generator) {
      @exact.add(sum, if letter.inverse { @exact.negate(unit) } else { unit })
    } else {
      sum
    }
  })
}

///|
/// The finite presentation is retained literally; words are not normalized.
/// Empty words and empty generator/relator collections are supported.
pub fn checked_presentation(
  generators : @core.Nat,
  relators : @core.Chain[@core.Chain[Letter]],
) -> Presentation? {
  if !@core.all(relators, fn(word) { valid_word(generators, word) }) {
    return None
  }
  let rows = @core.map(@core.indices(generators), fn(generator) {
    @core.map(relators, fn(word) { exponent_sum(generator, word) })
  })
  match @matrix.matrix(@core.length(relators), rows) {
    Some(relations) => Some({ generators, relators, relations, })
    None => None
  }
}

///|
pub fn generator_count(source : Presentation) -> @core.Nat {
  source.generators
}

///|
pub fn relators(source : Presentation) -> @core.Chain[@core.Chain[Letter]] {
  source.relators
}

///|
/// Generators index rows; relators index columns.
pub fn relation_matrix(source : Presentation) -> @matrix.Matrix[@exact.Integer] {
  source.relations
}

///|
pub fn exponent_sums(
  source : Presentation,
  word : @core.Chain[Letter],
) -> @core.Chain[@exact.Integer]? {
  if valid_word(source.generators, word) {
    Some(
      @core.map(@core.indices(source.generators), fn(generator) {
        exponent_sum(generator, word)
      }),
    )
  } else {
    None
  }
}
