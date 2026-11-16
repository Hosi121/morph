///|
fn middle(interval : @sturm.Interval) -> @exact.Rational {
  @exact.rational_half(@exact.rational_add(interval.lower, interval.upper))
}

///|
/// Canonical rational sector samples, with strict gaps between isolating
/// intervals. Root descriptors retain their full source/context certificate.
fn samples(roots : @core.Chain[@tower.RootCertificate]) -> @core.Chain[Sample]? {
  fn following(
    left : @tower.RootCertificate,
    rest : @core.Chain[@tower.RootCertificate],
  ) -> @core.Chain[Sample]? {
    let a = left.count.interval
    match rest {
      Nil =>
        Some(
          Cons(
            RationalPoint(@exact.rational_add(a.upper, @exact.rational_one())),
            Nil,
          ),
        )
      Cons(right, tail) => {
        let b = right.count.interval
        match @exact.rational_compare(a.upper, b.lower) {
          Less =>
            match following(right, tail) {
              None => None
              Some(after) =>
                Some(
                  Cons(
                    RationalPoint(
                      @exact.rational_half(
                        @exact.rational_add(a.upper, b.lower),
                      ),
                    ),
                    Cons(RootPoint(right), after),
                  ),
                )
            }
          _ => None
        }
      }
    }
  }
  match roots {
    Nil => Some(Cons(RationalPoint(@exact.rational_zero()), Nil))
    Cons(first, rest) =>
      match following(first, rest) {
        None => None
        Some(after) =>
          Some(
            Cons(
              RationalPoint(
                @exact.rational_subtract(
                  first.count.interval.lower,
                  @exact.rational_one(),
                ),
              ),
              Cons(RootPoint(first), after),
            ),
          )
      }
  }
}

///|
fn separate_once(
  roots : @core.Chain[@tower.Root],
) -> Result[@core.Chain[@tower.Root]?, CadError] {
  match roots {
    Nil | Cons(_, Nil) => Ok(None)
    Cons(left, Cons(right, rest)) => {
      let a = @tower.root_interval(left)
      let b = @tower.root_interval(right)
      match @exact.rational_compare(a.upper, b.lower) {
        Less =>
          match separate_once(Cons(right, rest)) {
            Ok(Some(tail)) => Ok(Some(Cons(left, tail)))
            Ok(None) => Ok(None)
            Err(error) => Err(error)
          }
        _ =>
          match @tower.refine(right, Succ(Zero)) {
            Ok(refined) => Ok(Some(Cons(left, Cons(refined, rest))))
            Err(error) => Err(TowerFailure(error))
          }
      }
    }
  }
}

///|
fn rational_sign(
  p : @tower.Polynomial,
  value : @exact.Rational,
) -> Result[@core.Ordering, CadError] {
  match @tower.evaluate_rational(p, value) {
    Err(error) => Err(TowerFailure(error))
    Ok(value) =>
      match @tower.scalar_sign(value) {
        Ok(sign) => Ok(sign.sign)
        Err(error) => Err(TowerFailure(error))
      }
  }
}

///|
/// At a root of the certified nonzero-atom union, each atom either has that root or has no
/// root in the one-root interval. In the latter case midpoint sign is exact.
fn classify(
  fibre : Fibre,
  sample : Sample,
) -> Result[@core.Chain[@core.Ordering], CadError] {
  fn walk(
    polynomials : @core.Chain[@tower.Polynomial],
    systems : @core.Chain[@tower.System?],
  ) -> Result[@core.Chain[@core.Ordering], CadError] {
    match (polynomials, systems) {
      (Nil, Nil) => Ok(Nil)
      (Cons(p, rest), Cons(system, tail)) => {
        let sign = match sample {
          RationalPoint(value) => rational_sign(p, value)
          RootPoint(root) =>
            match system {
              None => Ok(@core.Equal)
              Some(system) =>
                match @tower.count_between(system, root.count.interval) {
                  Err(error) => Err(TowerFailure(error))
                  Ok(count) =>
                    match count.count {
                      Succ(Zero) => Ok(@core.Equal)
                      Zero => rational_sign(p, middle(root.count.interval))
                      _ => Err(InternalInvariant)
                    }
                }
            }
        }
        match sign {
          Err(error) => Err(error)
          Ok(head) =>
            match walk(rest, tail) {
              Ok(tail) => Ok(Cons(head, tail))
              Err(error) => Err(error)
            }
        }
      }
      _ => Err(InternalInvariant)
    }
  }
  walk(fibre.polynomials, fibre.systems)
}

///|
fn append_rational(point : Point, value : @exact.Rational) -> Point {
  {
    field: point.field,
    coordinates: @core.append(
      point.coordinates,
      Cons(@tower.rational(point.field, value), Nil),
    ),
  }
}

///|
/// A root of an atom in a one-root union interval is the same selected real
/// value. Choose a smaller squarefree defining degree without factoring it.
fn defining_root(
  fibre : Fibre,
  proof : @tower.RootCertificate,
) -> Result[@tower.Root, CadError] {
  fn choose(
    systems : @core.Chain[@tower.System?],
    best : @tower.Root,
    degree : @core.Nat,
  ) -> Result[@tower.Root, CadError] {
    match systems {
      Nil => Ok(best)
      Cons(None, rest) => choose(rest, best, degree)
      Cons(Some(system), rest) =>
        match @tower.degree(@tower.squarefree(system)) {
          Some(Succ(_) as candidate) =>
            if @core.compare(candidate, degree) is Less {
              match @tower.count_between(system, proof.count.interval) {
                Err(error) => Err(TowerFailure(error))
                Ok(count) =>
                  if count.count.equal(Succ(Zero)) {
                    match
                      @tower.root_in_interval(system, proof.count.interval) {
                      Ok(root) => choose(rest, root, candidate)
                      Err(error) => Err(TowerFailure(error))
                    }
                  } else {
                    choose(rest, best, degree)
                  }
              }
            } else {
              choose(rest, best, degree)
            }
          _ => choose(rest, best, degree)
        }
    }
  }
  match @tower.root_from_certificate(fibre.root_polynomial, proof) {
    Err(error) => Err(TowerFailure(error))
    Ok(root) =>
      match @tower.degree(@tower.squarefree(fibre.system)) {
        Some(degree) => choose(fibre.systems, root, degree)
        None => Err(InternalInvariant)
      }
  }
}

///|
fn extend_point(
  point : Point,
  fibre : Fibre,
  sample : Sample,
) -> Result[Point, CadError] {
  match sample {
    RationalPoint(value) => Ok(append_rational(point, value))
    RootPoint(proof) =>
      match rational_sign(fibre.root_polynomial, proof.count.interval.upper) {
        Err(error) => Err(error)
        Ok(Equal) => Ok(append_rational(point, proof.count.interval.upper))
        Ok(_) =>
          match defining_root(fibre, proof) {
            Err(error) => Err(error)
            Ok(root) =>
              match @tower.adjoin(root) {
                Err(error) => Err(TowerFailure(error))
                Ok(extension) =>
                  match
                    map_result(point.coordinates, fn(value) {
                      match @tower.embed(extension.field, value) {
                        Ok(value) => Ok(value)
                        Err(error) => Err(TowerFailure(error))
                      }
                    }) {
                    Err(error) => Err(error)
                    Ok(prefix) =>
                      Ok({
                        field: extension.field,
                        coordinates: @core.append(
                          prefix,
                          Cons(extension.generator, Nil),
                        ),
                      })
                  }
              }
          }
      }
  }
}
