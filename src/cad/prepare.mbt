///|
pub fn prepare(
  arity : @core.Nat,
  formula : @qf.Formula,
) -> Result[Problem, CadError] {
  let atoms = @logic.qf_atoms(formula)
  if !@core.all(atoms, fn(p) { @poly.variables(p).equal(arity) }) {
    Err(WrongArity)
  } else {
    match @projection.prepare(arity, atoms) {
      Err(error) => Err(ProjectionFailure(error))
      Ok(plan) => {
        let projection = @projection.certificate(plan)
        match
          @prefix.prepare(
            arity,
            formula,
            @core.map(projection.levels, @projection.family),
          ) {
          Err(error) => Err(PrefixFailure(error))
          Ok(prefix) => Ok({ arity, formula, atoms, projection, prefix, })
        }
      }
    }
  }
}

///|
pub fn arity(problem : Problem) -> @core.Nat {
  problem.arity
}

///|
pub fn formula(problem : Problem) -> @qf.Formula {
  problem.formula
}

///|
pub fn polynomials(problem : Problem) -> @core.Chain[@poly.Polynomial] {
  problem.atoms
}

///|
pub fn projection(problem : Problem) -> @projection.Certificate {
  problem.projection
}

///|
pub fn point_field(point : Point) -> @tower.Field {
  point.field
}

///|
pub fn coordinates(point : Point) -> @core.Chain[@tower.Scalar] {
  point.coordinates
}

///|
pub fn rational_point(values : @core.Chain[@exact.Rational]) -> Point {
  let field = @tower.rational_field()
  {
    field,
    coordinates: @core.map(values, fn(q) { @tower.rational(field, q) }),
  }
}

///|
pub fn point(
  field : @tower.Field,
  coordinates : @core.Chain[@tower.Scalar],
) -> Result[Point, CadError] {
  match
    map_result(coordinates, fn(value) {
      match @tower.embed(field, value) {
        Ok(embedded) => Ok(embedded)
        Err(error) => Err(TowerFailure(error))
      }
    }) {
    Ok(coordinates) => Ok({ field, coordinates, })
    Err(error) => Err(error)
  }
}
