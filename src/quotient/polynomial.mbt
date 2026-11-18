///|
fn[A] trim(
  is_zero : (A) -> Bool,
  coefficients : @core.Chain[A],
) -> @core.Chain[A] {
  match coefficients {
    Nil => Nil
    Cons(head, rest) => {
      let tail = trim(is_zero, rest)
      match (is_zero(head), tail) {
        (true, Nil) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
fn[A] coefficient_lists_equal(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> Bool {
  match (a, b) {
    (Nil, Nil) => true
    (Cons(x, xs), Cons(y, ys)) =>
      is_zero((arithmetic.subtract)(x, y)) &&
      coefficient_lists_equal(arithmetic, is_zero, xs, ys)
    _ => false
  }
}

///|
fn[A] add_coefficients(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> @core.Chain[A] {
  match (a, b) {
    (Nil, _) => b
    (_, Nil) => a
    (Cons(x, xs), Cons(y, ys)) => {
      let head = (arithmetic.add)(x, y)
      let tail = add_coefficients(arithmetic, is_zero, xs, ys)
      match (is_zero(head), tail) {
        (true, Nil) => Nil
        _ => Cons(head, tail)
      }
    }
  }
}

///|
fn[A] negate_coefficients(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  coefficients : @core.Chain[A],
) -> @core.Chain[A] {
  trim(is_zero, @core.map(coefficients, arithmetic.negate))
}

///|
fn[A] subtract_coefficients(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> @core.Chain[A] {
  add_coefficients(
    arithmetic,
    is_zero,
    a,
    negate_coefficients(arithmetic, is_zero, b),
  )
}

///|
fn[A] scale_coefficients(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  scalar : A,
  coefficients : @core.Chain[A],
) -> @core.Chain[A] {
  if is_zero(scalar) {
    Nil
  } else {
    trim(
      is_zero,
      @core.map(coefficients, fn(coefficient) {
        (arithmetic.multiply)(scalar, coefficient)
      }),
    )
  }
}

///|
fn[A] convolution(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  a : @core.Chain[A],
  b : @core.Chain[A],
) -> @core.Chain[A] {
  match (a, b) {
    (Nil, _) | (_, Nil) => Nil
    (Cons(head, rest), _) => {
      let shifted : @core.Chain[A] = match
        convolution(arithmetic, is_zero, rest, b) {
        Nil => Nil
        tail => Cons(arithmetic.zero, tail)
      }
      add_coefficients(
        arithmetic,
        is_zero,
        scale_coefficients(arithmetic, is_zero, head, b),
        shifted,
      )
    }
  }
}

///|
/// Since the modulus is monic, cancelling the leading term needs no inverse.
/// Over the trusted coefficient field each cancellation lowers the degree.
fn[A] monic_remainder(
  arithmetic : @rowreduce.Field[A],
  is_zero : (A) -> Bool,
  modulus : @core.Chain[A],
  degree : @core.Nat,
  coefficients : @core.Chain[A],
) -> @core.Chain[A] {
  match @core.length(coefficients) {
    Zero => Nil
    Succ(exponent) =>
      match @core.compare(exponent, degree) {
        Less => coefficients
        _ =>
          match @core.last(coefficients) {
            None => Nil
            Some(leading) => {
              let cancellation = @core.replicate_onto(
                @core.subtract(exponent, degree),
                arithmetic.zero,
                scale_coefficients(arithmetic, is_zero, leading, modulus),
              )
              monic_remainder(
                arithmetic,
                is_zero,
                modulus,
                degree,
                subtract_coefficients(
                  arithmetic, is_zero, coefficients, cancellation,
                ),
              )
            }
          }
      }
  }
}
