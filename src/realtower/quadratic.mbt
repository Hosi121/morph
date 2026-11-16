///|
/// A monic squarefree quadratic has two distinct real roots whenever this
/// checked interval contains one. At its upper endpoint u, derivative <= zero
/// places u left of the vertex. Right of the vertex, f(u) >= zero means the
/// included root is the right one; otherwise only the left root is included.
fn quadratic_branch(
  field : Field,
  constant : Representation,
  linear : Representation,
  interval : @sturm.Interval,
) -> Result[@core.Ordering, TowerError] {
  let upper = raw_rational(field, interval.upper)
  next(raw_add(field, upper, upper), fn(twice) {
    next(raw_add(field, twice, linear), fn(derivative) {
      next(raw_sign(field, derivative), fn(sign) {
        if !sign.equal(Greater) {
          Ok(Less)
        } else {
          next(raw_add(field, upper, linear), fn(sum) {
            next(raw_multiply(field, upper, sum), fn(product) {
              next(raw_add(field, product, constant), fn(value) {
                next(raw_sign(field, value), fn(sign) {
                  Ok(if sign.equal(Less) { Less } else { Greater })
                })
              })
            })
          })
        }
      })
    })
  })
}

///|
/// For f=x*x+b*x+c and q=a*x+d, put z=two*beta+b and w=two*d-a*b.
/// Then z*z=b*b-four*c=Delta and two*q(beta)=a*z+w. If the two summands
/// have opposite signs, compare their squared magnitudes in the parent field.
/// This uses neither irreducibility nor independence from the parent field.
fn quadratic_linear_sign(
  field : Field,
  constant : Representation,
  linear : Representation,
  d : Representation,
  a : Representation,
  interval : @sturm.Interval,
) -> Result[@core.Ordering, TowerError] {
  both(raw_sign(field, a), raw_add(field, d, d), fn(sa, twice_d) {
    if sa.equal(Equal) {
      raw_sign(field, d)
    } else {
      next(raw_multiply(field, a, linear), fn(ab) {
        next(raw_add(field, twice_d, raw_negate(ab)), fn(w) {
          both(
            raw_sign(field, w),
            quadratic_branch(field, constant, linear, interval),
            fn(sw, branch) {
              let az = sign_product(sa, branch)
              if sw.equal(Equal) || sw.equal(az) {
                Ok(az)
              } else {
                next(raw_add(field, constant, constant), fn(twice_c) {
                  next(raw_add(field, twice_c, twice_c), fn(four_c) {
                    next(raw_multiply(field, linear, linear), fn(bb) {
                      next(raw_add(field, bb, raw_negate(four_c)), fn(delta) {
                        both(
                          raw_multiply(field, a, a),
                          raw_multiply(field, w, w),
                          fn(aa, ww) {
                            next(raw_multiply(field, aa, delta), fn(square) {
                              next(raw_add(field, ww, raw_negate(square)), fn(
                                difference,
                              ) {
                                next(raw_sign(field, difference), fn(
                                  comparison,
                                ) {
                                  Ok(
                                    match comparison {
                                      Equal => Equal
                                      Greater => sw
                                      Less => az
                                    },
                                  )
                                })
                              })
                            })
                          },
                        )
                      })
                    })
                  })
                })
              }
            },
          )
        })
      })
    }
  })
}
