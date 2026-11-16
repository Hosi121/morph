///|
/// One exhaustive real-variety cover for the exact Cartesian equations,
/// followed by a multiplicity proof for every covered parameter, in order.
#derive(Eq, Debug)
pub(all) struct Certificate {
  source : @poly.Polynomial
  separation : @variety.SeparationCertificate?
  multiplicities : @core.Chain[MultiplicityCertificate]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
pub fn check(source : @poly.Polynomial, proof : Certificate) -> Bool {
  if !source.equal(proof.source) {
    false
  } else {
    match prepare(source) {
      Err(_) => false
      Ok(problem) =>
        match proof.separation {
          None =>
            degree(problem.squarefree).equal(Zero) &&
            proof.multiplicities is Nil
          Some(separation) => {
            let solution = separation.solutions
            if degree(problem.squarefree).equal(Zero) ||
              !@variety.check_separation(problem.variety, separation) ||
              !@core.length(solution.intervals).equal(
                degree(problem.squarefree),
              ) {
              false
            } else {
              match @sturm.system(solution.shape.eliminant) {
                Err(_) => false
                Ok(system) => {
                  let coordinates = @core.take(
                    two(),
                    solution.shape.coordinates,
                  )
                  fn walk(
                    intervals : @core.Chain[@sturm.Interval],
                    values : @core.Chain[MultiplicityCertificate],
                    total : @core.Nat,
                  ) -> Bool {
                    match (intervals, values) {
                      (Nil, Nil) => total.equal(degree(source))
                      (Cons(interval, rest), Cons(head, tail)) =>
                        check_multiplicity(
                          source,
                          coordinates,
                          { polynomial: @sturm.squarefree(system), interval, },
                          head,
                        ) &&
                        walk(rest, tail, @core.add(total, head.order))
                      _ => false
                    }
                  }
                  walk(solution.intervals, proof.multiplicities, Zero)
                }
              }
            }
          }
        }
    }
  }
}

///|
#derive(Debug)
pub struct Root {
  source : @poly.Polynomial
  point : @variety.ProjectedPoint
  multiplicity : MultiplicityCertificate
}

///|
pub extend Root with Debug::{to_repr}

///|
pub fn parameter(root : Root) -> @real.Number {
  @variety.projected_parameter(root.point)
}

///|
pub fn coordinate_expressions(root : Root) -> @core.Chain[@poly.Polynomial] {
  @variety.projected_coordinate_expressions(root.point)
}

///|
pub fn multiplicity(root : Root) -> @core.Nat {
  root.multiplicity.order
}

///|
#derive(Debug)
pub struct RootSet {
  problem : Problem
  proof : Certificate
  roots : @core.Chain[Root]
}

///|
pub extend RootSet with Debug::{to_repr}

///|
pub fn roots(value : RootSet) -> @core.Chain[Root] {
  value.roots
}

///|
pub fn certificate(value : RootSet) -> Certificate {
  value.proof
}

///|
pub fn from_certificate(
  source : @poly.Polynomial,
  proof : Certificate,
) -> Result[RootSet, RootError] {
  if !check(source, proof) {
    Err(InvalidCertificate)
  } else {
    match prepare(source) {
      Err(error) => Err(error)
      Ok(problem) =>
        match proof.separation {
          None => Ok({ problem, proof, roots: Nil, })
          Some(separation) =>
            match
              @variety.separation_from_certificate(problem.variety, separation) {
              Err(error) => Err(VarietyFailure(error))
              Ok(value) =>
                match @variety.projected_points(value) {
                  Err(error) => Err(VarietyFailure(error))
                  Ok(points) =>
                    match @core.zip(points, proof.multiplicities) {
                      None => Err(InternalInvariant)
                      Some(pairs) =>
                        Ok({
                          problem,
                          proof,
                          roots: @core.map(pairs, fn(pair) {
                            let (point, multiplicity) = pair
                            { source, point, multiplicity, }
                          }),
                        })
                    }
                }
            }
        }
    }
  }
}

///|
/// Also bind the actual returned list, order and coordinate representation.
pub fn check_result(
  source : @poly.Polynomial,
  value : RootSet,
  proof : Certificate,
) -> Bool {
  fn bindings(
    roots : @core.Chain[Root],
    values : @core.Chain[MultiplicityCertificate],
  ) -> Bool {
    match (roots, values) {
      (Nil, Nil) => true
      (Cons(root, rest), Cons(head, tail)) =>
        root.source.equal(source) &&
        root.multiplicity.equal(head) &&
        @real.root_certificate(parameter(root)).equal(head.parameter) &&
        (match proof.separation {
          None => false
          Some(separation) =>
            @variety.projected_point_certificate(root.point).separation.equal(
              separation,
            ) &&
            coordinate_expressions(root).equal(
              @core.take(two(), separation.solutions.shape.coordinates),
            ) &&
            bindings(rest, tail)
        })
      _ => false
    }
  }
  value.problem.source.equal(source) &&
  value.proof.equal(proof) &&
  bindings(value.roots, proof.multiplicities) &&
  check(source, proof)
}
