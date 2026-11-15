///|
#derive(Eq, Debug)
pub(all) enum AesError {
  InvalidKeyLength
  Algebra(@galois.FieldError)
  Polynomial(@fppoly.PolyError)
  InternalInvariant
}

///|
pub extend AesError with Eq::{equal, not_equal}

///|
pub extend AesError with Debug::{to_repr}

///|
/// Generated immutable lookup tries, together with their checked AES field.
#derive(Eq, Debug)
pub struct Tables {
  field : @galois.Field
  forward : @trie.Trie[Octet]
  inverse : @trie.Trie[Octet]
}

///|
pub extend Tables with Eq::{equal, not_equal}

///|
pub extend Tables with Debug::{to_repr}

///|
pub fn byte_field(tables : Tables) -> @galois.Field {
  tables.field
}

///|
pub fn to_galois(
  tables : Tables,
  value : Octet,
) -> Result[@galois.Element, AesError] {
  let coefficients = @core.map(bits(value), fn(bit) {
    match bit {
      true => @binary.one()
      false => @binary.zero()
    }
  })
  match
    @galois.element(
      tables.field,
      @fppoly.polynomial(@galois.prime_field(tables.field), coefficients),
    ) {
    Ok(value) => Ok(value)
    Err(error) => Err(Algebra(error))
  }
}

///|
pub fn from_galois(
  tables : Tables,
  value : @galois.Element,
) -> Result[Octet, AesError] {
  match @galois.field_of(value).equal(tables.field) {
    false => Err(Algebra(@galois.FieldMismatch))
    true => {
      let coefficients = @core.map(
        @fppoly.coefficients(@galois.representative(value)),
        fn(coefficient) { !@binary.is_zero(coefficient) },
      )
      let width = @core.length(bits(zero()))
      match octet(@core.take(width, @core.append(coefficients, bits(zero())))) {
        None => Err(InternalInvariant)
        Some(value) => Ok(value)
      }
    }
  }
}

///|
/// Generate one S-box value from field inversion and the FIPS affine map.
pub fn calculate_sbox(
  tables : Tables,
  input : Octet,
) -> Result[Octet, AesError] {
  match to_galois(tables, input) {
    Err(error) => Err(error)
    Ok(input) => {
      let inverse = match @galois.inverse(input) {
        Ok(value) => Ok(value)
        Err(@galois.ZeroDivisor) => Ok(@galois.zero(tables.field))
        Err(error) => Err(Algebra(error))
      }
      match inverse {
        Err(error) => Err(error)
        Ok(value) =>
          match from_galois(tables, value) {
            Err(error) => Err(error)
            Ok(value) => Ok(affine(value))
          }
      }
    }
  }
}

///|
fn bit_words(shape : @core.Chain[Bool]) -> @core.Chain[@core.Chain[Bool]] {
  match shape {
    Nil => Cons(Nil, Nil)
    Cons(_, rest) => {
      let tails = bit_words(rest)
      @core.append(
        @core.map(tails, fn(tail) { Cons(false, tail) }),
        @core.map(tails, fn(tail) { Cons(true, tail) }),
      )
    }
  }
}

///|
/// Build the field and both caches at runtime; no precomputed S-box literals.
pub fn tables() -> Result[Tables, AesError] {
  fn fill(
    context : Tables,
    inputs : @core.Chain[@core.Chain[Bool]],
  ) -> Result[Tables, AesError] {
    match inputs {
      Nil => Ok(context)
      Cons(input, rest) =>
        match octet(input) {
          None => Err(InternalInvariant)
          Some(input) =>
            match calculate_sbox(context, input) {
              Err(error) => Err(error)
              Ok(output) =>
                match @trie.lookup(context.inverse, bits(output)) {
                  Some(_) => Err(InternalInvariant)
                  None =>
                    fill(
                      {
                        ..context,
                        forward: @trie.put(context.forward, bits(input), output),
                        inverse: @trie.put(context.inverse, bits(output), input),
                      },
                      rest,
                    )
                }
            }
        }
    }
  }
  match @primefield.field(@binary.double(@binary.one())) {
    None => Err(InternalInvariant)
    Some(prime) => {
      let reduction : Octet = {
        a: true,
        b: true,
        c: false,
        d: true,
        e: true,
        f: false,
        g: false,
        h: false,
      }
      let polynomial = @fppoly.polynomial(
        prime,
        @core.map(@core.append(bits(reduction), Cons(true, Nil)), fn(bit) {
          match bit {
            true => @binary.one()
            false => @binary.zero()
          }
        }),
      )
      match @fppoly.irreducibility(polynomial) {
        Err(error) => Err(Polynomial(error))
        Ok(None) => Err(InternalInvariant)
        Ok(Some(certificate)) =>
          match @galois.extension(polynomial, certificate) {
            None => Err(InternalInvariant)
            Some(field) =>
              fill(
                { field, forward: @trie.empty(), inverse: @trie.empty(), },
                bit_words(bits(zero())),
              )
          }
      }
    }
  }
}

///|
pub fn sbox(tables : Tables, value : Octet) -> Result[Octet, AesError] {
  match @trie.lookup(tables.forward, bits(value)) {
    None => Err(InternalInvariant)
    Some(value) => Ok(value)
  }
}

///|
pub fn inverse_sbox(tables : Tables, value : Octet) -> Result[Octet, AesError] {
  match @trie.lookup(tables.inverse, bits(value)) {
    None => Err(InternalInvariant)
    Some(value) => Ok(value)
  }
}

///|
fn[A, B] checked_map_four(
  value : Four[A],
  f : (A) -> Result[B, AesError],
) -> Result[Four[B], AesError] {
  match (f(value.a), f(value.b), f(value.c), f(value.d)) {
    (Ok(a), Ok(b), Ok(c), Ok(d)) => Ok({ a, b, c, d, })
    (Err(error), _, _, _)
    | (_, Err(error), _, _)
    | (_, _, Err(error), _)
    | (_, _, _, Err(error)) => Err(error)
  }
}

///|
pub fn sub_bytes(tables : Tables, state : Block) -> Result[Block, AesError] {
  match
    checked_map_four(state.columns, fn(word) {
      checked_map_four(word, fn(value) { sbox(tables, value) })
    }) {
    Err(error) => Err(error)
    Ok(columns) => Ok({ columns, })
  }
}

///|
pub fn inverse_sub_bytes(
  tables : Tables,
  state : Block,
) -> Result[Block, AesError] {
  match
    checked_map_four(state.columns, fn(word) {
      checked_map_four(word, fn(value) { inverse_sbox(tables, value) })
    }) {
    Err(error) => Err(error)
    Ok(columns) => Ok({ columns, })
  }
}
