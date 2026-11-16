///|
#derive(Eq, Debug)
pub(all) struct JetCertificate {
  real : @tarski.RootSignCertificate
  imaginary : @tarski.RootSignCertificate
}

///|
pub extend JetCertificate with Eq::{equal, not_equal}

///|
pub extend JetCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct MultiplicityCertificate {
  parameter : @real.RootCertificate
  order : @core.Nat
  jets : @core.Chain[JetCertificate]
}

///|
pub extend MultiplicityCertificate with Eq::{equal, not_equal}

///|
pub extend MultiplicityCertificate with Debug::{to_repr}

///|
fn parameter_queries(
  polynomial : @poly.Polynomial,
  coordinates : @core.Chain[@poly.Polynomial],
  eliminant : @poly.Polynomial,
) -> Cartesian? {
  match cartesian(polynomial) {
    Err(_) => None
    Ok(expansion) =>
      match
        (
          @variety.substitute_mod(expansion.real, coordinates, eliminant),
          @variety.substitute_mod(expansion.imaginary, coordinates, eliminant),
        ) {
        (Ok(real), Ok(imaginary)) => Some({ real, imaginary, })
        _ => None
      }
  }
}

///|
fn produce_multiplicity(
  source : @poly.Polynomial,
  point : @variety.ProjectedPoint,
) -> MultiplicityCertificate? {
  let parameter = @real.root_certificate(@variety.projected_parameter(point))
  let coordinates = @variety.projected_coordinate_expressions(point)
  fn jets(
    derivative : @poly.Polynomial,
    order : @core.Nat,
    previous : @core.Chain[JetCertificate],
  ) -> MultiplicityCertificate? {
    match parameter_queries(derivative, coordinates, parameter.polynomial) {
      None => None
      Some(queries) =>
        match
          (
            @tarski.root_sign(parameter, queries.real),
            @tarski.root_sign(parameter, queries.imaginary),
          ) {
          (Ok(real), Ok(imaginary)) => {
            let previous : @core.Chain[JetCertificate] = Cons(
              { real: real.certificate, imaginary: imaginary.certificate, },
              previous,
            )
            if real.sign.equal(Equal) && imaginary.sign.equal(Equal) {
              if @poly.is_zero(derivative) {
                None
              } else {
                match @poly.derivative(derivative, Zero) {
                  Some(next) => jets(next, Succ(order), previous)
                  None => None
                }
              }
            } else {
              Some({ parameter, order, jets: @core.reverse(previous), })
            }
          }
          _ => None
        }
    }
  }
  match @poly.derivative(source, Zero) {
    Some(derivative) => jets(derivative, Succ(Zero), Nil)
    None => None
  }
}

///|
/// The first nonzero complex derivative determines algebraic multiplicity.
/// Each earlier derivative must vanish in both coordinates. No sign or order
/// supplied by the producer is trusted without a source-bound Tarski check.
fn check_multiplicity(
  source : @poly.Polynomial,
  coordinates : @core.Chain[@poly.Polynomial],
  parameter : @real.RootCertificate,
  proof : MultiplicityCertificate,
) -> Bool {
  fn jets(
    derivative : @poly.Polynomial,
    order : @core.Nat,
    values : @core.Chain[JetCertificate],
  ) -> Bool {
    match values {
      Nil => false
      Cons(head, rest) =>
        match parameter_queries(derivative, coordinates, parameter.polynomial) {
          None => false
          Some(queries) =>
            if !@tarski.check_root_sign(
                parameter,
                queries.real,
                head.real.sign,
                head.real,
              ) ||
              !@tarski.check_root_sign(
                parameter,
                queries.imaginary,
                head.imaginary.sign,
                head.imaginary,
              ) {
              false
            } else if head.real.sign.equal(Equal) &&
              head.imaginary.sign.equal(Equal) {
              match @poly.derivative(derivative, Zero) {
                Some(next) => jets(next, Succ(order), rest)
                None => false
              }
            } else {
              rest is Nil && order.equal(proof.order)
            }
        }
    }
  }
  proof.parameter.equal(parameter) &&
  (match @poly.derivative(source, Zero) {
    Some(derivative) => jets(derivative, Succ(Zero), proof.jets)
    None => false
  })
}
