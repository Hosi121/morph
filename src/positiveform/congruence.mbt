///|
/// An elementary map e_source -> e_source + coefficient e_target.
/// Produced by a checked congruence; inverse and transpose retain invertibility.
#derive(Eq, Debug)
pub struct Shear {
  target : @core.Nat
  source : @core.Nat
  coefficient : @exact.Rational
}

///|
pub extend Shear with Eq::{equal, not_equal}

///|
pub extend Shear with Debug::{to_repr}

///|
pub fn Shear::target(self : Shear) -> @core.Nat {
  self.target
}

///|
pub fn Shear::source(self : Shear) -> @core.Nat {
  self.source
}

///|
pub fn Shear::coefficient(self : Shear) -> @exact.Rational {
  self.coefficient
}

///|
pub fn Shear::inverse(self : Shear) -> Shear {
  { ..self, coefficient: @exact.rational_negate(self.coefficient), }
}

///|
pub fn Shear::transpose(self : Shear) -> Shear {
  { ..self, target: self.source, source: self.target, }
}

///|
/// A=F D F^T. Shears are in MATRIX PRODUCT order F=S_first ... S_last,
/// so applying F to a vector applies the last shear first.
/// Dense input inherits LDL; inverse views use F^(-T), without another LDL.
#derive(Eq, Debug)
pub struct Congruence {
  dimension : @core.Nat
  diagonal : @core.Chain[PositiveScalar]
  shears : @core.Chain[Shear]
}

///|
pub extend Congruence with Eq::{equal, not_equal}

///|
pub extend Congruence with Debug::{to_repr}

///|
pub fn Congruence::dimension(self : Congruence) -> @core.Nat {
  self.dimension
}

///|
pub fn Congruence::diagonal(self : Congruence) -> @core.Chain[PositiveScalar] {
  self.diagonal
}

///|
pub fn Congruence::shears(self : Congruence) -> @core.Chain[Shear] {
  self.shears
}

///|
fn pivot_shears(
  values : @core.Chain[@exact.Rational],
  column : @core.Nat,
  row : @core.Nat,
) -> @core.Chain[Shear] {
  match values {
    Nil => Nil
    Cons(value, tail) => {
      let rest = pivot_shears(tail, column, Succ(row))
      if value.equal(@exact.rational_zero()) {
        rest
      } else {
        Cons({ target: row, source: column, coefficient: value, }, rest)
      }
    }
  }
}

///|
fn factor_word(
  factors : Factors,
  index : @core.Nat,
) -> (@core.Chain[PositiveScalar], @core.Chain[Shear]) {
  match factors {
    Empty => (Nil, Nil)
    Pivot(value, below, tail) => {
      let (diagonal, word) = factor_word(tail, Succ(index))
      (
        Cons(value, diagonal),
        @core.append(pivot_shears(below, index, Succ(index)), word),
      )
    }
  }
}

///|
fn block_words(
  blocks : @core.Chain[PositiveDefinite],
  offset : @core.Nat,
) -> (@core.Chain[PositiveScalar], @core.Chain[Shear]) {
  match blocks {
    Nil => (Nil, Nil)
    Cons(block, tail) => {
      let current = block.congruence()
      let (diagonal, word) = block_words(
        tail,
        @core.add(offset, block.dimension),
      )
      let shifted = @core.map(current.shears, fn(shear) {
        {
          ..shear,
          target: @core.add(offset, shear.target),
          source: @core.add(offset, shear.source),
        }
      })
      (@core.append(current.diagonal, diagonal), @core.append(shifted, word))
    }
  }
}

///|
/// Preserves cached decomposition, scaling, inverse and direct-sum laws.
pub fn PositiveDefinite::congruence(self : PositiveDefinite) -> Congruence {
  let (diagonal, shears) = match self.structure {
    Dense(_, factors) => factor_word(factors, Zero)
    Inverse(source) => {
      let previous = source.congruence()
      (
        @core.map(previous.diagonal, PositiveScalar::inverse),
        @core.map(previous.shears, fn(shear) { shear.transpose().inverse() }),
      )
    }
    Scaled(factor, source) => {
      let previous = source.congruence()
      (
        @core.map(previous.diagonal, fn(value) { factor.multiply(value) }),
        previous.shears,
      )
    }
    Blocks(values) => block_words(values, Zero)
  }
  { dimension: self.dimension, diagonal, shears, }
}
