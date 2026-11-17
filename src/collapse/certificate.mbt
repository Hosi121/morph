///|
/// Structural check of one supplied elementary pair. No matrices or pair
/// enumeration are used. The exact deletion must still be a valid complex.
pub fn is_free(source : @homology.Complex, pair : Pair) -> Bool {
  deletion(source, pair) is Some(_)
}

///|
/// Read a stored degree. A valid witness stores degrees zero through one past
/// the source dimension. Above that, all chain groups are zero.
pub fn degree_maps(witness : Certificate, degree : @core.Nat) -> DegreeMaps? {
  @core.nth(witness.maps, degree)
}

///|
fn shaped(
  input : @matrix.Matrix[@exact.Integer],
  height : @core.Nat,
  width : @core.Nat,
) -> Bool {
  @matrix.height(input).equal(height) && @matrix.width(input).equal(width)
}

///|
fn check_degree(
  source : @homology.Complex,
  target : @homology.Complex,
  pair : Pair,
  degree : @core.Nat,
  current : DegreeMaps,
  previous_inclusion : @matrix.Matrix[@exact.Integer],
  previous_projection : @matrix.Matrix[@exact.Integer],
  previous_homotopy : @matrix.Matrix[@exact.Integer],
) -> Bool {
  let source_size = @core.length(@homology.simplices(source, degree))
  let target_size = @core.length(@homology.simplices(target, degree))
  let source_next_size = @core.length(@homology.simplices(source, Succ(degree)))
  let shapes = shaped(current.inclusion, source_size, target_size) &&
    shaped(current.projection, target_size, source_size) &&
    shaped(current.homotopy, source_next_size, source_size)
  let canonical = inclusion(source, target, degree).equal(
      Some(current.inclusion),
    ) &&
    homotopy(source, pair, degree).equal(Some(current.homotopy))
  match
    (
      shapes && canonical,
      @homology.boundary(source, degree),
      @homology.boundary(source, Succ(degree)),
      @homology.boundary(target, degree),
    ) {
    (true, Some(ds), Some(ds_next), Some(dt)) => {
      let chain_maps = product_equal(
          dt,
          current.projection,
          previous_projection,
          ds,
        ) &&
        product_equal(ds, current.inclusion, previous_inclusion, dt)
      let retraction = @matrix.multiply(
        current.projection,
        current.inclusion,
        integers(),
      ).equal(Some(@matrix.identity(target_size, integers())))
      match
        (
          @matrix.multiply(current.inclusion, current.projection, integers()),
          @matrix.multiply(ds_next, current.homotopy, integers()),
          @matrix.multiply(previous_homotopy, ds, integers()),
        ) {
        (Some(ip), Some(dh), Some(hd)) =>
          match
            (
              combine(
                @matrix.identity(source_size, integers()),
                ip,
                @exact.subtract,
              ),
              combine(dh, hd, @exact.add),
            ) {
            (Some(left), Some(right)) =>
              chain_maps && retraction && left.equal(right)
            _ => false
          }
        _ => false
      }
    }
    _ => false
  }
}

///|
/// Bind an untrusted witness to actual source and target. Checks the exact
/// elementary deletion, orientation, every matrix shape and all four chain
/// identities dP=Pd, dI=Id, PI=id and id-IP=dH+Hd. Degree zero is unreduced.
/// The last stored degree is above the source dimension; all later groups
/// vanish, so there are no unverified higher coordinates. No pair search or
/// homology computation is performed.
pub fn check(
  source : @homology.Complex,
  actual_target : @homology.Complex,
  witness : Certificate,
) -> Bool {
  fn walk(
    degree : @core.Nat,
    todo : @core.Chain[DegreeMaps],
    previous_i : @matrix.Matrix[@exact.Integer],
    previous_p : @matrix.Matrix[@exact.Integer],
    previous_h : @matrix.Matrix[@exact.Integer],
  ) -> Bool {
    match todo {
      Nil => true
      Cons(current, rest) =>
        check_degree(
          source,
          actual_target,
          witness.pair,
          degree,
          current,
          previous_i,
          previous_p,
          previous_h,
        ) &&
        walk(
          Succ(degree),
          rest,
          current.inclusion,
          current.projection,
          current.homotopy,
        )
    }
  }
  let bound = witness.source.equal(source) &&
    witness.target.equal(actual_target) &&
    deletion(source, witness.pair).equal(Some(actual_target)) &&
    witness.orientation.equal(incidence(witness.pair)) &&
    @core.length(witness.maps).equal(Succ(top_size(source)))
  if !bound {
    false
  } else {
    match
      (
        zero_map(Zero, Zero),
        zero_map(@core.length(@homology.simplices(source, Zero)), Zero),
      ) {
      (Some(empty), Some(h)) => walk(Zero, witness.maps, empty, empty, h)
      _ => false
    }
  }
}

///|
fn build_degree(
  source : @homology.Complex,
  target : @homology.Complex,
  pair : Pair,
  degree : @core.Nat,
) -> DegreeMaps? {
  let projection = map_matrix(
    @homology.simplices(target, degree),
    @homology.simplices(source, degree),
    fn(row, column) {
      let identity = delta(row, column)
      if same_simplex(column, pair.lower) {
        @exact.subtract(
          identity,
          @exact.multiply(
            incidence(pair),
            incidence({ lower: row, upper: pair.upper, }),
          ),
        )
      } else {
        identity
      }
    },
  )
  match
    (
      inclusion(source, target, degree),
      projection,
      homotopy(source, pair, degree),
    ) {
    (Some(inclusion), Some(projection), Some(homotopy)) =>
      Some({ inclusion, projection, homotopy, })
    _ => None
  }
}

///|
/// Construct and check one exact elementary contraction. H(lower) is
/// [lower:boundary(upper)]*upper; H is zero on every other simplex.
/// Projection is id-dH-Hd with the deleted coordinates removed.
pub fn elementary(source : @homology.Complex, pair : Pair) -> Certificate? {
  fn build(
    target : @homology.Complex,
    degrees : @core.Chain[@core.Nat],
  ) -> @core.Chain[DegreeMaps]? {
    match degrees {
      Nil => Some(Nil)
      Cons(degree, rest) =>
        match
          (build_degree(source, target, pair, degree), build(target, rest)) {
          (Some(maps), Some(tail)) => Some(Cons(maps, tail))
          _ => None
        }
    }
  }
  match deletion(source, pair) {
    None => None
    Some(target) =>
      match build(target, @core.indices(Succ(top_size(source)))) {
        None => None
        Some(maps) => {
          let witness = {
            source,
            target,
            pair,
            orientation: incidence(pair),
            maps,
          }
          if check(source, target, witness) {
            Some(witness)
          } else {
            None
          }
        }
      }
  }
}
