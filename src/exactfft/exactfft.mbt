///|
/// A radix-two DFT inside one checked cyclotomic field.
/// The transform size may be any positive power of two dividing the field order.
#derive(Eq, Debug)
pub struct Plan {
  field : @cyclotomic.Field
  size : @core.Nat
  root : @cyclotomic.Element
  inverse_root : @cyclotomic.Element
  inverse_size : @cyclotomic.Element
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum TransformError {
  LengthMismatch
  FieldMismatch
  Arithmetic(@cyclotomic.CyclotomicError)
}

///|
pub extend TransformError with Eq::{equal, not_equal}

///|
pub extend TransformError with Debug::{to_repr}

///|
/// Choose omega = zeta_M^(M/N), where M is the field order and N is the size.
/// This is the positive-exponent DFT convention; inverse uses omega^(-1)/N.
pub fn plan(field : @cyclotomic.Field, size : @core.Nat) -> Plan? {
  match
    (
      @fft.valid_length(@core.replicate(size, ())),
      @binary.divmod(
        @binary.from_nat(@cyclotomic.order(field)),
        @binary.from_nat(size),
      ),
    ) {
    (true, Some((step, remainder))) =>
      match @binary.is_zero(remainder) {
        false => None
        true =>
          match
            (
              @cyclotomic.power(@cyclotomic.generator(field), step),
              @exact.ratio(
                @exact.positive(@binary.one()),
                @binary.from_nat(size),
              ),
            ) {
            (Ok(root), Some(scale)) =>
              match @cyclotomic.conjugate(root) {
                Err(_) => None
                Ok(inverse_root) =>
                  Some({
                    field,
                    size,
                    root,
                    inverse_root,
                    inverse_size: @cyclotomic.rational(field, scale),
                  })
              }
            _ => None
          }
      }
    _ => None
  }
}

///|
pub fn size(plan : Plan) -> @core.Nat {
  plan.size
}

///|
pub fn field_of(plan : Plan) -> @cyclotomic.Field {
  plan.field
}

///|
pub fn root(plan : Plan) -> @cyclotomic.Element {
  plan.root
}

///|
fn combine(
  root : @cyclotomic.Element,
  phase : @cyclotomic.Element,
  evens : @core.Chain[@cyclotomic.Element],
  odds : @core.Chain[@cyclotomic.Element],
) -> Result[
  (@core.Chain[@cyclotomic.Element], @core.Chain[@cyclotomic.Element]),
  @cyclotomic.CyclotomicError,
] {
  match (evens, odds) {
    (Nil, Nil) => Ok((Nil, Nil))
    (Cons(e, et), Cons(o, ot)) =>
      match @cyclotomic.multiply(phase, o) {
        Err(error) => Err(error)
        Ok(rotated) =>
          match
            (
              @cyclotomic.add(e, rotated),
              @cyclotomic.subtract(e, rotated),
              @cyclotomic.multiply(phase, root),
            ) {
            (Ok(low), Ok(high), Ok(next)) =>
              match combine(root, next, et, ot) {
                Err(error) => Err(error)
                Ok((lt, ht)) => Ok((Cons(low, lt), Cons(high, ht)))
              }
            (Err(error), _, _) | (_, Err(error), _) | (_, _, Err(error)) =>
              Err(error)
          }
      }
    _ => Err(@cyclotomic.InternalInvariant)
  }
}

///|
fn transform_raw(
  root : @cyclotomic.Element,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@core.Chain[@cyclotomic.Element], @cyclotomic.CyclotomicError] {
  match xs {
    Nil | Cons(_, Nil) => Ok(xs)
    _ => {
      let (evens, odds) = @core.alternating(xs)
      match @cyclotomic.multiply(root, root) {
        Err(error) => Err(error)
        Ok(square) =>
          match (transform_raw(square, evens), transform_raw(square, odds)) {
            (Ok(es), Ok(os)) =>
              match
                combine(
                  root,
                  @cyclotomic.one(@cyclotomic.field_of(root)),
                  es,
                  os,
                ) {
                Err(error) => Err(error)
                Ok((low, high)) => Ok(@core.append(low, high))
              }
            (Err(error), _) | (_, Err(error)) => Err(error)
          }
      }
    }
  }
}

///|
fn check(plan : Plan, xs : @core.Chain[@cyclotomic.Element]) -> TransformError? {
  match @core.compare(@core.length(xs), plan.size) {
    Equal =>
      match
        @core.all(xs, fn(value) {
          @cyclotomic.field_of(value).equal(plan.field)
        }) {
        true => None
        false => Some(FieldMismatch)
      }
    _ => Some(LengthMismatch)
  }
}

///|
pub fn transform(
  plan : Plan,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@core.Chain[@cyclotomic.Element], TransformError] {
  match check(plan, xs) {
    Some(error) => Err(error)
    None =>
      match transform_raw(plan.root, xs) {
        Ok(values) => Ok(values)
        Err(error) => Err(Arithmetic(error))
      }
  }
}

///|
fn scale_all(
  scale : @cyclotomic.Element,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@core.Chain[@cyclotomic.Element], @cyclotomic.CyclotomicError] {
  match xs {
    Nil => Ok(Nil)
    Cons(value, rest) =>
      match (@cyclotomic.multiply(scale, value), scale_all(scale, rest)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
pub fn inverse(
  plan : Plan,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@core.Chain[@cyclotomic.Element], TransformError] {
  match check(plan, xs) {
    Some(error) => Err(error)
    None =>
      match transform_raw(plan.inverse_root, xs) {
        Err(error) => Err(Arithmetic(error))
        Ok(transformed) =>
          match scale_all(plan.inverse_size, transformed) {
            Err(error) => Err(Arithmetic(error))
            Ok(values) => Ok(values)
          }
      }
  }
}

///|
/// Direct bin: sum_j xs[j] * step^j, with no radix-two decomposition.
fn direct_bin(
  step : @cyclotomic.Element,
  phase : @cyclotomic.Element,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@cyclotomic.Element, @cyclotomic.CyclotomicError] {
  match xs {
    Nil => Ok(@cyclotomic.zero(@cyclotomic.field_of(step)))
    Cons(value, rest) =>
      match
        (@cyclotomic.multiply(value, phase), @cyclotomic.multiply(phase, step)) {
        (Ok(head), Ok(next)) =>
          match direct_bin(step, next, rest) {
            Err(error) => Err(error)
            Ok(tail) => @cyclotomic.add(head, tail)
          }
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
/// Quadratic specification using the signal spine as a bin counter.
pub fn dft(
  plan : Plan,
  xs : @core.Chain[@cyclotomic.Element],
) -> Result[@core.Chain[@cyclotomic.Element], TransformError] {
  fn bins(
    todo : @core.Chain[@cyclotomic.Element],
    step : @cyclotomic.Element,
  ) -> Result[@core.Chain[@cyclotomic.Element], @cyclotomic.CyclotomicError] {
    match todo {
      Nil => Ok(Nil)
      Cons(_, rest) =>
        match
          (
            direct_bin(step, @cyclotomic.one(plan.field), xs),
            @cyclotomic.multiply(step, plan.root),
          ) {
          (Ok(head), Ok(next)) =>
            match bins(rest, next) {
              Err(error) => Err(error)
              Ok(tail) => Ok(Cons(head, tail))
            }
          (Err(error), _) | (_, Err(error)) => Err(error)
        }
    }
  }
  match check(plan, xs) {
    Some(error) => Err(error)
    None =>
      match bins(xs, @cyclotomic.one(plan.field)) {
        Err(error) => Err(Arithmetic(error))
        Ok(values) => Ok(values)
      }
  }
}

///|
/// Interpret an original formal arrow of length k as zeta_M^k in this field.
pub fn interpret_arrow(
  field : @cyclotomic.Field,
  arrow : @fft.Arrow,
) -> Result[@cyclotomic.Element, @cyclotomic.CyclotomicError] {
  @cyclotomic.power(
    @cyclotomic.generator(field),
    @binary.from_nat(@core.length(arrow)),
  )
}

///|
pub fn interpret_number(
  field : @cyclotomic.Field,
  number : @fft.Number,
) -> Result[@cyclotomic.Element, @cyclotomic.CyclotomicError] {
  match number {
    Nil => Ok(@cyclotomic.zero(field))
    Cons(arrow, rest) =>
      match (interpret_arrow(field, arrow), interpret_number(field, rest)) {
        (Ok(head), Ok(tail)) => @cyclotomic.add(head, tail)
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}

///|
pub fn interpret_signal(
  field : @cyclotomic.Field,
  signal : @fft.Signal,
) -> Result[@core.Chain[@cyclotomic.Element], @cyclotomic.CyclotomicError] {
  match signal {
    Nil => Ok(Nil)
    Cons(number, rest) =>
      match (interpret_number(field, number), interpret_signal(field, rest)) {
        (Ok(head), Ok(tail)) => Ok(Cons(head, tail))
        (Err(error), _) | (_, Err(error)) => Err(error)
      }
  }
}
