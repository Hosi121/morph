///|
/// A checked radix-two transform over a prime field, with a primitive root.
#derive(Eq, Debug)
pub struct Plan {
  modulus : @modular.Modulus
  size : @core.Nat
  root : @binary.Binary
  inverse_root : @binary.Binary
  inverse_size : @binary.Binary
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
/// For power-of-two N, root^N=1 and root^(N/2)!=1 ensure exact order N.
/// Primality is checked to exclude non-principal roots in composite rings.
pub fn plan(
  modulus : @modular.Modulus,
  root : @binary.Binary,
  size : @core.Nat,
) -> Plan? {
  match
    (
      @fft.valid_length(@core.replicate(size, ())),
      @modular.is_prime(@modular.value(modulus)),
    ) {
    (true, true) => {
      let n = @binary.from_nat(size)
      let root = @modular.reduce(modulus, root)
      let complete = @modular.power(modulus, root, n)
      let primitive = match @binary.compare(n, @binary.one()) {
        Equal => true
        _ =>
          match
            @binary.compare(
              @modular.power(modulus, root, @binary.half(n)),
              @binary.one(),
            ) {
            Equal => false
            _ => true
          }
      }
      match
        (
          @binary.compare(complete, @binary.one()),
          primitive,
          @modular.inverse(modulus, root),
          @modular.inverse(modulus, n),
        ) {
        (Equal, true, Some(inverse_root), Some(inverse_size)) =>
          Some({ modulus, size, root, inverse_root, inverse_size, })
        _ => None
      }
    }
    _ => None
  }
}

///|
fn transform_raw(
  modulus : @modular.Modulus,
  root : @binary.Binary,
  xs : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  fn combine(
    es : @core.Chain[@binary.Binary],
    os : @core.Chain[@binary.Binary],
    phase : @binary.Binary,
  ) -> (@core.Chain[@binary.Binary], @core.Chain[@binary.Binary]) {
    match (es, os) {
      (Cons(e, et), Cons(o, ot)) => {
        let rotated = @modular.multiply(modulus, phase, o)
        let (low, high) = combine(
          et,
          ot,
          @modular.multiply(modulus, phase, root),
        )
        (
          Cons(@modular.add(modulus, e, rotated), low),
          Cons(@modular.subtract(modulus, e, rotated), high),
        )
      }
      _ => (Nil, Nil)
    }
  }
  match xs {
    Nil | Cons(_, Nil) => xs
    _ => {
      let (evens, odds) = @core.alternating(xs)
      let square = @modular.multiply(modulus, root, root)
      let (low, high) = combine(
        transform_raw(modulus, square, evens),
        transform_raw(modulus, square, odds),
        @binary.one(),
      )
      @core.append(low, high)
    }
  }
}

///|
pub fn transform(
  plan : Plan,
  xs : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary]? {
  match @core.compare(@core.length(xs), plan.size) {
    Equal =>
      Some(
        transform_raw(
          plan.modulus,
          plan.root,
          @core.map(xs, fn(x) { @modular.reduce(plan.modulus, x) }),
        ),
      )
    _ => None
  }
}

///|
fn inverse_raw(
  plan : Plan,
  xs : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary] {
  @core.map(transform_raw(plan.modulus, plan.inverse_root, xs), fn(x) {
    @modular.multiply(plan.modulus, x, plan.inverse_size)
  })
}

///|
pub fn inverse(
  plan : Plan,
  xs : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary]? {
  match @core.compare(@core.length(xs), plan.size) {
    Equal =>
      Some(
        inverse_raw(
          plan,
          @core.map(xs, fn(x) { @modular.reduce(plan.modulus, x) }),
        ),
      )
    _ => None
  }
}

///|
/// Zero-padded linear convolution in the chosen prime field.
/// The plan size must cover length(xs)+length(ys)-1. Empty products are empty.
pub fn convolve(
  plan : Plan,
  xs : @core.Chain[@binary.Binary],
  ys : @core.Chain[@binary.Binary],
) -> @core.Chain[@binary.Binary]? {
  match (xs, ys) {
    (Nil, _) | (_, Nil) => Some(Nil)
    _ => {
      let needed = @core.subtract(
        @core.add(@core.length(xs), @core.length(ys)),
        Succ(Zero),
      )
      match @core.compare(needed, plan.size) {
        Greater => None
        _ => {
          let xpad = @core.append(
            xs,
            @core.replicate(
              @core.subtract(plan.size, @core.length(xs)),
              @binary.zero(),
            ),
          )
          let ypad = @core.append(
            ys,
            @core.replicate(
              @core.subtract(plan.size, @core.length(ys)),
              @binary.zero(),
            ),
          )
          match
            @core.zip(
              transform_raw(plan.modulus, plan.root, xpad),
              transform_raw(plan.modulus, plan.root, ypad),
            ) {
            None => None
            Some(pairs) => {
              let product = @core.map(pairs, fn(pair) {
                let (a, b) = pair
                @modular.multiply(plan.modulus, a, b)
              })
              Some(@core.take(needed, inverse_raw(plan, product)))
            }
          }
        }
      }
    }
  }
}
