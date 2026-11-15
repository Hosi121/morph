///|
#derive(Eq, Debug)
pub(all) enum AdderStyle {
  Minterms
  Propagate
  Multiplexer
}

///|
pub extend AdderStyle with Eq::{equal, not_equal}

///|
pub extend AdderStyle with Debug::{to_repr}

///|
/// Inputs are a[width], then b[width], then one carry bit. Outputs retain carry.
pub fn adder_outputs(
  width : @core.Nat,
  style : AdderStyle,
) -> @core.Chain[Expr] {
  fn inputs(
    count : @core.Nat,
    next : @core.Nat,
  ) -> (@core.Chain[Expr], @core.Nat) {
    match count {
      Zero => (Nil, next)
      Succ(rest) => {
        let (tail, end) = inputs(rest, Succ(next))
        (Cons(Variable(next), tail), end)
      }
    }
  }
  let (a, next) = inputs(width, Zero)
  let (b, next) = inputs(width, next)
  let ops = algebra()
  let adder = fn(a, b, c) {
    match style {
      Minterms => @boolean.full_adder_minterms(ops, a, b, c)
      Propagate => @boolean.full_adder_propagate(ops, a, b, c)
      Multiplexer => @boolean.full_adder_mux(ops, a, b, c)
    }
  }
  match @boolean.add_words(adder, a, b, Variable(next)) {
    None => Nil
    Some((sum, carry)) => @core.append(sum, Cons(carry, Nil))
  }
}

///|
pub fn adder_miter(
  width : @core.Nat,
  left : AdderStyle,
  right : AdderStyle,
) -> Encoding? {
  miter(adder_outputs(width, left), adder_outputs(width, right))
}
