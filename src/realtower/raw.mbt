///|
fn[A, B] next(
  value : Result[A, TowerError],
  f : (A) -> Result[B, TowerError],
) -> Result[B, TowerError] {
  match value {
    Ok(a) => f(a)
    Err(e) => Err(e)
  }
}

///|
fn[A, B, C] both(
  left : Result[A, TowerError],
  right : Result[B, TowerError],
  f : (A, B) -> Result[C, TowerError],
) -> Result[C, TowerError] {
  match (left, right) {
    (Ok(a), Ok(b)) => f(a, b)
    (Err(e), _) | (_, Err(e)) => Err(e)
  }
}

///|
fn raw_one(field : Field) -> Representation {
  raw_rational(field, @exact.rational_one())
}

///|
fn raw_zero(field : Field) -> Representation {
  raw_rational(field, @exact.rational_zero())
}

///|
fn sign_product(a : @core.Ordering, b : @core.Ordering) -> @core.Ordering {
  match (a, b) {
    (Equal, _) | (_, Equal) => Equal
    (Less, Less) | (Greater, Greater) => Greater
    _ => Less
  }
}

///|
fn rp_degree(values : @core.Chain[Representation]) -> @core.Nat? {
  match @core.length(values) {
    Zero => None
    Succ(n) => Some(n)
  }
}

///|
fn rp_empty(values : @core.Chain[Representation]) -> Bool {
  match values {
    Nil => true
    _ => false
  }
}

///|
/// Only trailing semantic zeros are removed; a nonminimal residue can be zero.
fn rp_trim(
  field : Field,
  values : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  match values {
    Nil => Ok(Nil)
    Cons(head, rest) =>
      next(rp_trim(field, rest), fn(tail) {
        match tail {
          Nil =>
            next(raw_sign(field, head), fn(s) {
              Ok(if s.equal(Equal) { Nil } else { Cons(head, Nil) })
            })
          _ => Ok(Cons(head, tail))
        }
      })
  }
}

///|
fn rp_add(
  field : Field,
  left : @core.Chain[Representation],
  right : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  fn walk(
    a : @core.Chain[Representation],
    b : @core.Chain[Representation],
  ) -> Result[@core.Chain[Representation], TowerError] {
    match (a, b) {
      (Nil, _) => Ok(b)
      (_, Nil) => Ok(a)
      (Cons(a, as_), Cons(b, bs)) =>
        both(raw_add(field, a, b), walk(as_, bs), fn(c, cs) { Ok(Cons(c, cs)) })
    }
  }
  next(walk(left, right), fn(cs) { rp_trim(field, cs) })
}

///|
fn rp_negate(
  values : @core.Chain[Representation],
) -> @core.Chain[Representation] {
  @core.map(values, raw_negate)
}

///|
fn rp_subtract(
  field : Field,
  left : @core.Chain[Representation],
  right : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  rp_add(field, left, rp_negate(right))
}

///|
fn rp_scale(
  field : Field,
  values : @core.Chain[Representation],
  scalar : Representation,
) -> Result[@core.Chain[Representation], TowerError] {
  fn walk(
    values : @core.Chain[Representation],
  ) -> Result[@core.Chain[Representation], TowerError] {
    match values {
      Nil => Ok(Nil)
      Cons(c, cs) =>
        both(raw_multiply(field, c, scalar), walk(cs), fn(v, vs) {
          Ok(Cons(v, vs))
        })
    }
  }
  next(walk(values), fn(cs) { rp_trim(field, cs) })
}

///|
fn rp_shift(
  field : Field,
  values : @core.Chain[Representation],
  amount : @core.Nat,
) -> @core.Chain[Representation] {
  if rp_empty(values) {
    Nil
  } else {
    @core.replicate_onto(amount, raw_zero(field), values)
  }
}

///|
fn rp_multiply(
  field : Field,
  left : @core.Chain[Representation],
  right : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  match left {
    Nil => Ok(Nil)
    Cons(c, cs) =>
      both(rp_scale(field, right, c), rp_multiply(field, cs, right), fn(a, b) {
        rp_add(field, a, rp_shift(field, b, Succ(Zero)))
      })
  }
}

///|
fn rp_divide(
  field : Field,
  value : @core.Chain[Representation],
  divisor : @core.Chain[Representation],
) -> Result[
  (@core.Chain[Representation], @core.Chain[Representation]),
  TowerError,
] {
  fn walk(
    remainder : @core.Chain[Representation],
    quotient : @core.Chain[Representation],
    inverse : Representation,
    d : @core.Nat,
  ) -> Result[
    (@core.Chain[Representation], @core.Chain[Representation]),
    TowerError,
  ] {
    match (rp_degree(remainder), @core.last(remainder)) {
      (None, _) => Ok((quotient, remainder))
      (Some(n), Some(lc)) =>
        if @core.compare(n, d).equal(Less) {
          Ok((quotient, remainder))
        } else {
          next(raw_multiply(field, lc, inverse), fn(c) {
            let term = rp_shift(field, Cons(c, Nil), @core.subtract(n, d))
            next(rp_multiply(field, term, divisor), fn(product) {
              both(
                rp_subtract(field, remainder, product),
                rp_add(field, quotient, term),
                fn(r, q) {
                  if (match rp_degree(r) {
                      None => true
                      Some(m) => @core.compare(m, n).equal(Less)
                    }) {
                    walk(r, q, inverse, d)
                  } else {
                    Err(InternalInvariant)
                  }
                },
              )
            })
          })
        }
      _ => Err(InternalInvariant)
    }
  }
  match (rp_degree(divisor), @core.last(divisor)) {
    (Some(n), Some(lc)) =>
      next(raw_inverse(field, lc), fn(inv) { walk(value, Nil, inv, n) })
    _ => Err(ZeroDivisor)
  }
}

///|
fn rp_remainder(
  field : Field,
  value : @core.Chain[Representation],
  divisor : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  match (rp_degree(value), rp_degree(divisor)) {
    (None, _) => Ok(Nil)
    (Some(a), Some(b)) =>
      if @core.compare(a, b).equal(Less) {
        Ok(value)
      } else {
        next(rp_divide(field, value, divisor), fn(pair) {
          let (_, remainder) = pair
          Ok(remainder)
        })
      }
    _ => Err(ZeroDivisor)
  }
}

///|
fn rp_monic(
  field : Field,
  values : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  match @core.last(values) {
    None => Ok(Nil)
    Some(lc) =>
      if lc.equal(raw_one(field)) {
        Ok(values)
      } else {
        next(raw_inverse(field, lc), fn(inv) { rp_scale(field, values, inv) })
      }
  }
}

///|
fn rp_derivative(
  field : Field,
  values : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  fn walk(
    values : @core.Chain[Representation],
    n : @core.Nat,
  ) -> Result[@core.Chain[Representation], TowerError] {
    match values {
      Nil => Ok(Nil)
      Cons(c, cs) =>
        both(
          raw_multiply(
            field,
            c,
            raw_rational(
              field,
              @exact.whole(@exact.positive(@binary.from_nat(n))),
            ),
          ),
          walk(cs, Succ(n)),
          fn(v, vs) { Ok(Cons(v, vs)) },
        )
    }
  }
  match values {
    Nil => Ok(Nil)
    Cons(_, cs) => next(walk(cs, Succ(Zero)), fn(ds) { rp_trim(field, ds) })
  }
}

///|
fn rp_evaluate(
  field : Field,
  values : @core.Chain[Representation],
  point : Representation,
) -> Result[Representation, TowerError] {
  match values {
    Nil => Ok(raw_zero(field))
    Cons(c, cs) =>
      next(rp_evaluate(field, cs, point), fn(tail) {
        next(raw_multiply(field, point, tail), fn(product) {
          raw_add(field, c, product)
        })
      })
  }
}

///|
fn rp_sequence(
  field : Field,
  a : @core.Chain[Representation],
  b : @core.Chain[Representation],
) -> Result[@core.Chain[@core.Chain[Representation]], TowerError] {
  if rp_empty(b) {
    Ok(Cons(a, Nil))
  } else {
    next(rp_remainder(field, a, b), fn(r) {
      next(rp_sequence(field, b, rp_negate(r)), fn(tail) { Ok(Cons(a, tail)) })
    })
  }
}

///|
fn rp_squarefree(
  field : Field,
  value : @core.Chain[Representation],
) -> Result[@core.Chain[Representation], TowerError] {
  next(rp_monic(field, value), fn(m) {
    next(rp_derivative(field, m), fn(d) {
      next(rp_sequence(field, m, d), fn(sequence) {
        match @core.last(sequence) {
          None => Err(InternalInvariant)
          Some(last) =>
            next(rp_monic(field, last), fn(gcd) {
              next(rp_divide(field, m, gcd), fn(pair) {
                let (quotient, remainder) = pair
                if rp_empty(remainder) {
                  Ok(quotient)
                } else {
                  Err(InternalInvariant)
                }
              })
            })
        }
      })
    })
  })
}

///|
/// Remainders keep the raw degree bounded without quotient-ring inversion.
fn raw_fraction(
  field : Field,
  numerator : @core.Chain[Representation],
  denominator : @core.Chain[Representation],
) -> Result[Representation, TowerError] {
  match field.context {
    Rationals => Err(InternalInvariant)
    Extension(parent, modulus, _) =>
      both(
        rp_remainder(parent, numerator, modulus),
        rp_remainder(parent, denominator, modulus),
        fn(n, d) {
          match (n, d) {
            (_, Nil) => Err(InternalInvariant)
            (Nil, _) => Ok(raw_zero(field))
            (_, Cons(c, Nil)) =>
              if c.equal(raw_one(parent)) {
                Ok(Fraction(n, d))
              } else {
                next(raw_inverse(parent, c), fn(inv) {
                  next(rp_scale(parent, n, inv), fn(n) {
                    Ok(Fraction(n, Cons(raw_one(parent), Nil)))
                  })
                })
              }
            _ =>
              if n.equal(d) {
                Ok(raw_one(field))
              } else {
                Ok(Fraction(n, d))
              }
          }
        },
      )
  }
}

///|
fn raw_add(
  field : Field,
  a : Representation,
  b : Representation,
) -> Result[Representation, TowerError] {
  match (field.context, a, b) {
    (Rationals, Base(a), Base(b)) => Ok(Base(@exact.rational_add(a, b)))
    (Extension(parent, _, _), Fraction(an, ad), Fraction(bn, bd)) =>
      if ad.equal(bd) {
        next(rp_add(parent, an, bn), fn(n) { raw_fraction(field, n, ad) })
      } else {
        both(rp_multiply(parent, an, bd), rp_multiply(parent, bn, ad), fn(
          a,
          b,
        ) {
          both(rp_add(parent, a, b), rp_multiply(parent, ad, bd), fn(n, d) {
            raw_fraction(field, n, d)
          })
        })
      }
    _ => Err(InternalInvariant)
  }
}

///|
fn raw_multiply(
  field : Field,
  a : Representation,
  b : Representation,
) -> Result[Representation, TowerError] {
  if a.equal(raw_one(field)) {
    Ok(b)
  } else if b.equal(raw_one(field)) {
    Ok(a)
  } else {
    match (field.context, a, b) {
      (Rationals, Base(a), Base(b)) => Ok(Base(@exact.rational_multiply(a, b)))
      (Extension(parent, _, _), Fraction(an, ad), Fraction(bn, bd)) =>
        both(rp_multiply(parent, an, bn), rp_multiply(parent, ad, bd), fn(
          n,
          d,
        ) {
          raw_fraction(field, n, d)
        })
      _ => Err(InternalInvariant)
    }
  }
}

///|
fn raw_inverse(
  field : Field,
  value : Representation,
) -> Result[Representation, TowerError] {
  if value.equal(raw_one(field)) {
    Ok(value)
  } else {
    next(raw_sign(field, value), fn(s) {
      if s.equal(Equal) {
        Err(ZeroDivisor)
      } else {
        match (field.context, value) {
          (Rationals, Base(q)) =>
            match @exact.nonzero(q) {
              Some(n) => Ok(Base(@exact.reciprocal(n)))
              None => Err(InternalInvariant)
            }
          (Extension(_, _, _), Fraction(n, d)) => raw_fraction(field, d, n)
          _ => Err(InternalInvariant)
        }
      }
    })
  }
}

///|
fn root_value_sign(
  field : Field,
  modulus : @core.Chain[Representation],
  value : @core.Chain[Representation],
  interval : @sturm.Interval,
) -> Result[@core.Ordering, TowerError] {
  match (modulus, value) {
    (_, Nil) => Ok(Equal)
    (_, Cons(c, Nil)) => raw_sign(field, c)
    (Cons(c, Cons(b, Cons(lc, Nil))), Cons(d, Cons(a, Nil))) =>
      if lc.equal(raw_one(field)) {
        quadratic_linear_sign(field, c, b, d, a, interval)
      } else {
        generic_root_value_sign(field, modulus, value, interval)
      }
    _ => generic_root_value_sign(field, modulus, value, interval)
  }
}

///|
fn generic_root_value_sign(
  field : Field,
  modulus : @core.Chain[Representation],
  value : @core.Chain[Representation],
  interval : @sturm.Interval,
) -> Result[@core.Ordering, TowerError] {
  next(rp_query(field, modulus, value, interval), fn(n) {
    let zero = @exact.positive(@binary.zero())
    let unit = @exact.positive(@binary.one())
    if n.equal(zero) {
      Ok(Equal)
    } else if n.equal(unit) {
      Ok(Greater)
    } else if n.equal(@exact.negate(unit)) {
      Ok(Less)
    } else {
      Err(InternalInvariant)
    }
  })
}

///|
/// Both query computations descend to the parent ordered field.
fn raw_sign(
  field : Field,
  value : Representation,
) -> Result[@core.Ordering, TowerError] {
  match (field.context, value) {
    (Rationals, Base(q)) =>
      Ok(@exact.rational_compare(q, @exact.rational_zero()))
    (Extension(parent, modulus, interval), Fraction(n, d)) =>
      next(root_value_sign(parent, modulus, n, interval), fn(sn) {
        if sn.equal(Equal) {
          Ok(Equal)
        } else {
          next(root_value_sign(parent, modulus, d, interval), fn(sd) {
            if sd.equal(Equal) {
              Err(InternalInvariant)
            } else {
              Ok(sign_product(sn, sd))
            }
          })
        }
      })
    _ => Err(InternalInvariant)
  }
}

///|
/// Right-hand Taylor sign, including a root exactly at the rational endpoint.
fn rp_right_sign(
  field : Field,
  values : @core.Chain[Representation],
  point : @exact.Rational,
) -> Result[@core.Ordering, TowerError] {
  if rp_empty(values) {
    Err(InternalInvariant)
  } else {
    next(rp_evaluate(field, values, raw_rational(field, point)), fn(value) {
      next(raw_sign(field, value), fn(sign) {
        if sign.equal(Equal) {
          next(rp_derivative(field, values), fn(d) {
            rp_right_sign(field, d, point)
          })
        } else {
          Ok(sign)
        }
      })
    })
  }
}

///|
fn rp_variations(
  field : Field,
  sequence : @core.Chain[@core.Chain[Representation]],
  point : @exact.Rational,
) -> Result[@core.Nat, TowerError] {
  fn walk(
    values : @core.Chain[@core.Chain[Representation]],
    previous : @core.Ordering,
    count : @core.Nat,
  ) -> Result[@core.Nat, TowerError] {
    match values {
      Nil => Ok(count)
      Cons(p, ps) =>
        next(rp_right_sign(field, p, point), fn(sign) {
          match (previous, sign) {
            (Less, Greater) | (Greater, Less) => walk(ps, sign, Succ(count))
            _ => walk(ps, sign, count)
          }
        })
    }
  }
  walk(sequence, Equal, Zero)
}

///|
fn rp_difference(
  field : Field,
  sequence : @core.Chain[@core.Chain[Representation]],
  interval : @sturm.Interval,
) -> Result[@exact.Integer, TowerError] {
  both(
    rp_variations(field, sequence, interval.lower),
    rp_variations(field, sequence, interval.upper),
    fn(a, b) {
      Ok(
        @exact.subtract(
          @exact.positive(@binary.from_nat(a)),
          @exact.positive(@binary.from_nat(b)),
        ),
      )
    },
  )
}

///|
/// Sturm-Tarski: sum sign(query(r)) over distinct roots in (lower, upper].
fn rp_query(
  field : Field,
  polynomial : @core.Chain[Representation],
  query : @core.Chain[Representation],
  interval : @sturm.Interval,
) -> Result[@exact.Integer, TowerError] {
  next(rp_monic(field, polynomial), fn(monic) {
    next(rp_derivative(field, monic), fn(d) {
      next(rp_multiply(field, d, query), fn(product) {
        next(rp_remainder(field, product, monic), fn(seed) {
          next(rp_sequence(field, monic, seed), fn(sequence) {
            rp_difference(field, sequence, interval)
          })
        })
      })
    })
  })
}
