///|
/// One entry for every ordered pair of homogeneous basis classes, including
/// products landing above the dimension, whose coordinate vector is empty.
#derive(Eq, Debug)
pub(all) struct TableEntry {
  left_degree : @core.Nat
  left_index : @core.Nat
  right_degree : @core.Nat
  right_index : @core.Nat
  value : @core.Chain[Bool]
}

///|
pub extend TableEntry with Eq::{equal, not_equal}

///|
pub extend TableEntry with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct RingResult {
  groups : @core.Chain[Group]
  table : @core.Chain[TableEntry]
  unit : @core.Chain[Bool]
}

///|
pub extend RingResult with Eq::{equal, not_equal}

///|
pub extend RingResult with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct RingCertificate {
  source : @homology.Complex
  result : RingResult
  degrees : @core.Chain[Certificate]
}

///|
pub extend RingCertificate with Eq::{equal, not_equal}

///|
pub extend RingCertificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Ring {
  source : @homology.Complex
  spaces : @core.Chain[Cohomology]
  result : RingResult
}

///|
pub extend Ring with Eq::{equal, not_equal}

///|
pub extend Ring with Debug::{to_repr}

///|
pub fn ring_result(ring : Ring) -> RingResult {
  ring.result
}

///|
pub fn ring_certificate(ring : Ring) -> RingCertificate {
  {
    source: ring.source,
    result: ring.result,
    degrees: @core.map(ring.spaces, certificate),
  }
}

///|
pub fn degree_space(ring : Ring, degree : @core.Nat) -> Cohomology? {
  @core.nth(ring.spaces, degree)
}

///|
fn dimension(source : @homology.Complex) -> @core.Nat {
  @core.fold_left(@homology.all_simplices(source), Zero, fn(old, face) {
    let degree = @core.subtract(@core.length(face), Succ(Zero))
    match @core.compare(old, degree) {
      Less => degree
      _ => old
    }
  })
}

///|
fn xor_vectors(
  left : @core.Chain[Bool],
  right : @core.Chain[Bool],
) -> @core.Chain[Bool] {
  match (left, right) {
    (Cons(a, rest), Cons(b, tail)) =>
      Cons(@csscode.xor(a, b), xor_vectors(rest, tail))
    _ => Nil
  }
}

///|
fn class_rank(groups : @core.Chain[Group], degree : @core.Nat) -> @core.Nat {
  match @core.nth(groups, degree) {
    Some(group) => group.rank
    None => Zero
  }
}

///|
fn lookup(
  table : @core.Chain[TableEntry],
  p : @core.Nat,
  i : @core.Nat,
  q : @core.Nat,
  j : @core.Nat,
) -> @core.Chain[Bool]? {
  match table {
    Nil => None
    Cons(entry, rest) =>
      match
        entry.left_degree.equal(p) &&
        entry.left_index.equal(i) &&
        entry.right_degree.equal(q) &&
        entry.right_index.equal(j) {
        true => Some(entry.value)
        false => lookup(rest, p, i, q, j)
      }
  }
}

///|
fn multiply_table(
  actual : RingResult,
  p : @core.Nat,
  left : @core.Chain[Bool],
  q : @core.Nat,
  right : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  fn right_products(
    table : @core.Chain[TableEntry],
    p : @core.Nat,
    i : @core.Nat,
    q : @core.Nat,
    j : @core.Nat,
    right : @core.Chain[Bool],
    sum : @core.Chain[Bool],
  ) -> @core.Chain[Bool]? {
    match right {
      Nil => Some(sum)
      Cons(bit, rest) =>
        match bit {
          false => right_products(table, p, i, q, Succ(j), rest, sum)
          true =>
            match lookup(table, p, i, q, j) {
              None => None
              Some(value) =>
                right_products(
                  table,
                  p,
                  i,
                  q,
                  Succ(j),
                  rest,
                  xor_vectors(sum, value),
                )
            }
        }
    }
  }
  fn walk(
    table : @core.Chain[TableEntry],
    p : @core.Nat,
    i : @core.Nat,
    left : @core.Chain[Bool],
    q : @core.Nat,
    right : @core.Chain[Bool],
    sum : @core.Chain[Bool],
  ) -> @core.Chain[Bool]? {
    match left {
      Nil => Some(sum)
      Cons(bit, rest) => {
        let next = match bit {
          false => Some(sum)
          true => right_products(table, p, i, q, Zero, right, sum)
        }
        match next {
          None => None
          Some(next) => walk(table, p, Succ(i), rest, q, right, next)
        }
      }
    }
  }
  match
    @core.length(left).equal(class_rank(actual.groups, p)) &&
    @core.length(right).equal(class_rank(actual.groups, q)) {
    false => None
    true =>
      walk(
        actual.table,
        p,
        Zero,
        left,
        q,
        right,
        @core.replicate(class_rank(actual.groups, @core.add(p, q)), false),
      )
  }
}

///|
/// Bilinearly multiply arbitrary homogeneous class coordinates in the full ring.
pub fn multiply(
  ring : Ring,
  left_degree : @core.Nat,
  left : @core.Chain[Bool],
  right_degree : @core.Nat,
  right : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  multiply_table(ring.result, left_degree, left, right_degree, right)
}

///|
fn quotient(
  spaces : @core.Chain[Cohomology],
  degree : @core.Nat,
  cochain : @core.Chain[Bool],
) -> @core.Chain[Bool]? {
  match @core.nth(spaces, degree) {
    Some(space) => coordinates(space, cochain)
    None =>
      match cochain {
        Nil => Some(Nil)
        _ => None
      }
  }
}

///|
fn table_for(
  source : @homology.Complex,
  spaces : @core.Chain[Cohomology],
) -> @core.Chain[TableEntry]? {
  fn rights(
    p : @core.Nat,
    i : @core.Nat,
    left : @core.Chain[Bool],
    q : @core.Nat,
    j : @core.Nat,
    right : @core.Chain[@core.Chain[Bool]],
    source : @homology.Complex,
    spaces : @core.Chain[Cohomology],
  ) -> @core.Chain[TableEntry]? {
    match right {
      Nil => Some(Nil)
      Cons(value, rest) =>
        match
          (
            cup(source, p, left, q, value),
            rights(p, i, left, q, Succ(j), rest, source, spaces),
          ) {
          (Some(cochain), Some(tail)) =>
            match quotient(spaces, @core.add(p, q), cochain) {
              Some(value) =>
                Some(
                  Cons(
                    {
                      left_degree: p,
                      left_index: i,
                      right_degree: q,
                      right_index: j,
                      value,
                    },
                    tail,
                  ),
                )
              None => None
            }
          _ => None
        }
    }
  }
  fn right_degrees(
    p : @core.Nat,
    i : @core.Nat,
    left : @core.Chain[Bool],
    q : @core.Nat,
    todo : @core.Chain[Cohomology],
    source : @homology.Complex,
    spaces : @core.Chain[Cohomology],
  ) -> @core.Chain[TableEntry]? {
    match todo {
      Nil => Some(Nil)
      Cons(space, rest) =>
        match
          (
            rights(
              p,
              i,
              left,
              q,
              Zero,
              space.witness.result.representatives,
              source,
              spaces,
            ),
            right_degrees(p, i, left, Succ(q), rest, source, spaces),
          ) {
          (Some(entries), Some(tail)) => Some(@core.append(entries, tail))
          _ => None
        }
    }
  }
  fn lefts(
    p : @core.Nat,
    i : @core.Nat,
    todo : @core.Chain[@core.Chain[Bool]],
    source : @homology.Complex,
    spaces : @core.Chain[Cohomology],
  ) -> @core.Chain[TableEntry]? {
    match todo {
      Nil => Some(Nil)
      Cons(left, rest) =>
        match
          (
            right_degrees(p, i, left, Zero, spaces, source, spaces),
            lefts(p, Succ(i), rest, source, spaces),
          ) {
          (Some(entries), Some(tail)) => Some(@core.append(entries, tail))
          _ => None
        }
    }
  }
  fn degrees(
    p : @core.Nat,
    todo : @core.Chain[Cohomology],
    source : @homology.Complex,
    spaces : @core.Chain[Cohomology],
  ) -> @core.Chain[TableEntry]? {
    match todo {
      Nil => Some(Nil)
      Cons(space, rest) =>
        match
          (
            lefts(p, Zero, space.witness.result.representatives, source, spaces),
            degrees(Succ(p), rest, source, spaces),
          ) {
          (Some(entries), Some(tail)) => Some(@core.append(entries, tail))
          _ => None
        }
    }
  }
  degrees(Zero, spaces, source, spaces)
}

///|
fn basis_classes(
  groups : @core.Chain[Group],
) -> @core.Chain[(@core.Nat, @core.Chain[Bool])] {
  fn walk(
    groups : @core.Chain[Group],
    degree : @core.Nat,
  ) -> @core.Chain[(@core.Nat, @core.Chain[Bool])] {
    match groups {
      Nil => Nil
      Cons(group, rest) =>
        @core.append(
          @core.map(
            @matrix.rows(@matrix.identity(group.rank, @csscode.scalars())),
            fn(unit) { (degree, unit) },
          ),
          walk(rest, Succ(degree)),
        )
    }
  }
  walk(groups, Zero)
}

///|
/// Bilinearity reduces the unit/commutation checks to basis pairs and
/// associativity to basis triples. In GF(2) the graded sign is one.
fn ring_laws(actual : RingResult) -> Bool {
  let basis = basis_classes(actual.groups)
  @core.all(basis, fn(a) {
    let (p, x) = a
    multiply_table(actual, Zero, actual.unit, p, x).equal(Some(x)) &&
    multiply_table(actual, p, x, Zero, actual.unit).equal(Some(x)) &&
    @core.all(basis, fn(b) {
      let (q, y) = b
      let xy = multiply_table(actual, p, x, q, y)
      xy.equal(multiply_table(actual, q, y, p, x)) &&
      @core.all(basis, fn(c) {
        let (r, z) = c
        match (xy, multiply_table(actual, q, y, r, z)) {
          (Some(xy), Some(yz)) =>
            multiply_table(actual, @core.add(p, q), xy, r, z).equal(
              multiply_table(actual, p, x, @core.add(q, r), yz),
            )
          _ => false
        }
      })
    })
  })
}

///|
/// Check B*Z and Z*B vanish in the quotient on complete bases. Together with
/// bilinearity this verifies representative independence for every class.
fn descends(
  source : @homology.Complex,
  spaces : @core.Chain[Cohomology],
) -> Bool {
  @core.all(spaces, fn(left) {
    @core.all(spaces, fn(right) {
      let p = left.witness.degree
      let q = right.witness.degree
      let a = left.witness.result
      let b = right.witness.result
      fn vanishes(x : @core.Chain[Bool], y : @core.Chain[Bool]) -> Bool {
        match cup(source, p, x, q, y) {
          None => false
          Some(product) =>
            match quotient(spaces, @core.add(p, q), product) {
              Some(value) => zero_vector(value)
              None => false
            }
        }
      }
      @core.all(a.coboundaries, fn(x) {
        @core.all(@core.append(b.coboundaries, b.representatives), fn(y) {
          vanishes(x, y)
        })
      }) &&
      @core.all(@core.append(a.coboundaries, a.representatives), fn(x) {
        @core.all(b.coboundaries, fn(y) { vanishes(x, y) })
      })
    })
  })
}

///|
fn import_degrees(
  source : @homology.Complex,
  todo : @core.Chain[Certificate],
  degree : @core.Nat,
  count : @core.Nat,
) -> @core.Chain[Cohomology]? {
  match (todo, count) {
    (Nil, Zero) => Some(Nil)
    (Cons(witness, rest), Succ(remaining)) =>
      match
        (
          validate_certificate(source, degree, witness.result, witness),
          import_degrees(source, rest, Succ(degree), remaining),
        ) {
        (Some(space), Some(tail)) => Some(Cons(space, tail))
        _ => None
      }
    _ => None
  }
}

///|
/// Check a complete table and all basis identities, without elimination search.
pub fn check_ring(
  source : @homology.Complex,
  actual : RingResult,
  witness : RingCertificate,
) -> Bool {
  witness.source.equal(source) &&
  witness.result.equal(actual) &&
  (match
    import_degrees(source, witness.degrees, Zero, Succ(dimension(source))) {
    None => false
    Some(spaces) => {
      let unit = @core.replicate(
        @core.length(@homology.simplices(source, Zero)),
        true,
      )
      actual.groups.equal(@core.map(spaces, result)) &&
      table_for(source, spaces).equal(Some(actual.table)) &&
      quotient(spaces, Zero, unit).equal(Some(actual.unit)) &&
      descends(source, spaces) &&
      ring_laws(actual)
    }
  })
}

///|
/// Full finite ring through the source dimension, including H^0 and all zero
/// groups. Empty complexes have the zero ring (empty unit coordinates).
pub fn compute_ring(source : @homology.Complex) -> Ring? {
  fn degrees(
    source : @homology.Complex,
    degree : @core.Nat,
    count : @core.Nat,
  ) -> @core.Chain[Cohomology]? {
    match count {
      Zero => Some(Nil)
      Succ(rest) =>
        match (compute(source, degree), degrees(source, Succ(degree), rest)) {
          (Some(space), Some(tail)) => Some(Cons(space, tail))
          _ => None
        }
    }
  }
  match degrees(source, Zero, Succ(dimension(source))) {
    None => None
    Some(spaces) =>
      match table_for(source, spaces) {
        None => None
        Some(table) => {
          let unit = @core.replicate(
            @core.length(@homology.simplices(source, Zero)),
            true,
          )
          match quotient(spaces, Zero, unit) {
            None => None
            Some(unit) => {
              let result = RingResult::{
                groups: @core.map(spaces, result),
                table,
                unit,
              }
              match descends(source, spaces) && ring_laws(result) {
                false => None
                true => Some({ source, spaces, result, })
              }
            }
          }
        }
      }
  }
}
