///|
#derive(Eq, Debug)
pub(all) enum Operation {
  Addition
  Subtraction
  Multiplication
  Division
  Negation
  Conjugation
}

///|
pub extend Operation with Eq::{equal, not_equal}

///|
pub extend Operation with Debug::{to_repr}

///|
#derive(Debug)
priv enum Slot {
  LeftReal
  LeftImaginary
  RightReal
  RightImaginary
  Temporary(@core.Nat)
}

///|
#derive(Debug)
priv enum Instruction {
  Sum(Slot, Slot)
  Product(Slot, Slot)
  Negative(Slot)
  Quotient(Slot, Slot)
}

///|
priv struct Recipe {
  instructions : @core.Chain[Instruction]
  real : Slot
  imaginary : Slot
}

///|
/// Fixed straight-line formulas; every temporary is an earlier result.
/// Division shares the real, nonnegative denominator c*c+d*d.
fn recipe(operation : Operation) -> Recipe {
  let z : @core.Nat = Zero
  let o = @core.Succ(z)
  let t = @core.Succ(o)
  let h = @core.Succ(t)
  let f = @core.Succ(h)
  let v = @core.Succ(f)
  let s = @core.Succ(v)
  let e = @core.Succ(s)
  let n = @core.Succ(e)
  let q = @core.Succ(n)
  let x = @core.Succ(q)
  let y = @core.Succ(x)
  let a = LeftReal
  let b = LeftImaginary
  let c = RightReal
  let d = RightImaginary
  match operation {
    Addition =>
      {
        instructions: Cons(Sum(a, c), Cons(Sum(b, d), Nil)),
        real: Temporary(z),
        imaginary: Temporary(o),
      }
    Subtraction =>
      {
        instructions: Cons(
          Negative(c),
          Cons(
            Sum(a, Temporary(z)),
            Cons(Negative(d), Cons(Sum(b, Temporary(t)), Nil)),
          ),
        ),
        real: Temporary(o),
        imaginary: Temporary(h),
      }
    Multiplication =>
      {
        instructions: Cons(
          Product(a, c),
          Cons(
            Product(b, d),
            Cons(
              Negative(Temporary(o)),
              Cons(
                Sum(Temporary(z), Temporary(t)),
                Cons(
                  Product(a, d),
                  Cons(
                    Product(b, c),
                    Cons(Sum(Temporary(f), Temporary(v)), Nil),
                  ),
                ),
              ),
            ),
          ),
        ),
        real: Temporary(h),
        imaginary: Temporary(s),
      }
    Division =>
      {
        instructions: Cons(
          Product(c, c),
          Cons(
            Product(d, d),
            Cons(
              Sum(Temporary(z), Temporary(o)),
              Cons(
                Product(a, c),
                Cons(
                  Product(b, d),
                  Cons(
                    Sum(Temporary(h), Temporary(f)),
                    Cons(
                      Product(b, c),
                      Cons(
                        Product(a, d),
                        Cons(
                          Negative(Temporary(e)),
                          Cons(
                            Sum(Temporary(s), Temporary(n)),
                            Cons(
                              Quotient(Temporary(v), Temporary(t)),
                              Cons(Quotient(Temporary(q), Temporary(t)), Nil),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        real: Temporary(x),
        imaginary: Temporary(y),
      }
    Negation =>
      {
        instructions: Cons(Negative(a), Cons(Negative(b), Nil)),
        real: Temporary(z),
        imaginary: Temporary(o),
      }
    Conjugation =>
      {
        instructions: Cons(Negative(b), Nil),
        real: a,
        imaginary: Temporary(z),
      }
  }
}

///|
fn read_slot(
  slot : Slot,
  left : Number,
  right : Number,
  values : @core.Chain[@realalgebraic.Number],
) -> @realalgebraic.Number? {
  match slot {
    LeftReal => Some(left.real)
    LeftImaginary => Some(left.imaginary)
    RightReal => Some(right.real)
    RightImaginary => Some(right.imaginary)
    Temporary(index) => @core.nth(values, index)
  }
}

///|
fn instruction_inputs(
  instruction : Instruction,
  left : Number,
  right : Number,
  values : @core.Chain[@realalgebraic.Number],
) -> (@realalgebraic.Number, @realalgebraic.Number)? {
  let (a, b) = match instruction {
    Sum(a, b) | Product(a, b) | Quotient(a, b) => (a, b)
    Negative(a) => (a, a)
  }
  match (read_slot(a, left, right, values), read_slot(b, left, right, values)) {
    (Some(a), Some(b)) => Some((a, b))
    _ => None
  }
}

///|
fn recipe_result(
  operation : Operation,
  left : Number,
  right : Number,
  values : @core.Chain[@realalgebraic.Number],
) -> Number? {
  let plan = recipe(operation)
  match
    (
      read_slot(plan.real, left, right, values),
      read_slot(plan.imaginary, left, right, values),
    ) {
    (Some(real), Some(imaginary)) => Some(number(real, imaginary))
    _ => None
  }
}
