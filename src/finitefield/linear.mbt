///|
/// Field dictionary for shared Gauss-Jordan elimination. Every result is reduced.
pub fn arithmetic(field : Field) -> @rowreduce.Field[@binary.Binary] {
  let m = field.modulus
  {
    zero: @binary.zero(),
    one: @binary.one(),
    add: fn(a, b) { @modular.add(m, a, b) },
    subtract: fn(a, b) { @modular.subtract(m, a, b) },
    negate: fn(a) { @modular.subtract(m, @binary.zero(), a) },
    multiply: fn(a, b) { @modular.multiply(m, a, b) },
    inverse: fn(a) { @modular.inverse(m, a) },
  }
}
