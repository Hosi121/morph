///|
fn atoms(
  polynomial : @poly.Polynomial,
  roots : @core.Chain[@sturm.Interval],
  truth : @core.Chain[Bool],
) -> Result[@core.Chain[Interval], SetError] {
  fn walk(
    lower : Bound,
    roots : @core.Chain[@sturm.Interval],
    truth : @core.Chain[Bool],
  ) -> Result[@core.Chain[Interval], SetError] {
    match (roots, truth) {
      (Nil, Cons(holds, Nil)) =>
        if holds {
          Ok(
            Cons(
              {
                lower,
                upper: PositiveInfinity,
                lower_closed: false,
                upper_closed: false,
              },
              Nil,
            ),
          )
        } else {
          Ok(Nil)
        }
      (Cons(root, rest), Cons(open, Cons(point, tail))) => {
        let endpoint : @real.RootCertificate = { polynomial, interval: root, }
        if !@real.check_root(endpoint) {
          return Err(InvalidEndpoint)
        }
        let upper = Finite(endpoint)
        match walk(upper, rest, tail) {
          Err(e) => Err(e)
          Ok(after) => {
            let with_point : @core.Chain[Interval] = if point {
              Cons(
                Interval::{
                  lower: upper,
                  upper,
                  lower_closed: true,
                  upper_closed: true,
                },
                after,
              )
            } else {
              after
            }
            if open {
              Ok(
                Cons(
                  { lower, upper, lower_closed: false, upper_closed: false, },
                  with_point,
                ),
              )
            } else {
              Ok(with_point)
            }
          }
        }
      }
      _ => Err(MalformedCells)
    }
  }
  walk(NegativeInfinity, roots, truth)
}

///|
fn coalesce(values : @core.Chain[Interval]) -> @core.Chain[Interval] {
  fn collect(
    current : Interval,
    rest : @core.Chain[Interval],
  ) -> @core.Chain[Interval] {
    match rest {
      Nil => Cons(current, Nil)
      Cons(next, tail) =>
        if current.upper.equal(next.lower) &&
          (current.upper_closed || next.lower_closed) {
          collect(
            { ..current, upper: next.upper, upper_closed: next.upper_closed, },
            tail,
          )
        } else {
          Cons(current, collect(next, tail))
        }
    }
  }
  match values {
    Nil => Nil
    Cons(head, tail) => collect(head, tail)
  }
}

///|
fn assemble(
  polynomial : @poly.Polynomial,
  roots : @core.Chain[@sturm.Interval],
  truth : @core.Chain[Bool],
) -> Result[@core.Chain[Interval], SetError] {
  match atoms(polynomial, roots, truth) {
    Ok(values) => Ok(coalesce(values))
    Err(e) => Err(e)
  }
}

///|
/// Reify the complete CAD's y-quantified truth cells into maximal connected
/// components. False point cells prevent merging two touching open intervals.
pub fn from_cad2(
  value : @cad2.Decomposition,
  quantifier : @cad2.Quantifier,
) -> Result[RealSet, SetError] {
  let problem = @cad2.problem_of(value)
  let cad = @cad2.certificate(value)
  let truth = @cad2.eliminate_y(value, quantifier)
  match
    assemble(
      @base.root_polynomial(@cad2.base_problem(problem)),
      cad.base.roots,
      truth,
    ) {
    Err(e) => Err(e)
    Ok(intervals) =>
      Ok({
        certificate: {
          formula: @cad2.formula(problem),
          quantifier,
          cad,
          truth,
          intervals,
        },
      })
  }
}

///|
/// None means not verified: an invalid certificate OR insufficient CAD
/// verification fuel. It is never a proof that the represented set is empty.
pub fn check(
  problem : @cad2.Problem,
  quantifier : @cad2.Quantifier,
  proof : Certificate,
  verification : @core.Nat,
) -> RealSet? {
  if !@cad2.formula(problem).equal(proof.formula) ||
    !quantifier.equal(proof.quantifier) {
    return None
  }
  match @cad2.check(problem, proof.cad, verification) {
    None => None
    Some(value) =>
      if !@cad2.eliminate_y(value, quantifier).equal(proof.truth) {
        None
      } else {
        match from_cad2(value, quantifier) {
          Ok(expected) =>
            if expected.certificate.equal(proof) {
              Some(expected)
            } else {
              None
            }
          Err(_) => None
        }
      }
  }
}

///|
/// Exact representation binding of the separately returned interval-set payload.
pub fn check_result(
  problem : @cad2.Problem,
  quantifier : @cad2.Quantifier,
  value : RealSet,
  proof : Certificate,
  verification : @core.Nat,
) -> Bool {
  value.certificate.equal(proof) &&
  check(problem, quantifier, proof, verification) is Some(_)
}
