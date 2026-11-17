///|
fn fraction_stationary_fixture(
  rows : Array[Array[(Int32, Int32)]],
  origin : Array[(Int32, Int32)],
  basis : Array[Array[(Int32, Int32)]],
  parameters : Array[Array[(Int32, Int32)]],
  members : Array[Array[(Int32, Int32)]?],
) -> Unit raise {
  let value = kernel(fraction_rows(rows)).unwrap()
  let family = stationary_affine(value).unwrap()
  assert_eq(stationary_kernel(family), value)
  assert_eq(stationary_origin(family), fraction_vector(origin))
  assert_eq(stationary_directions(family), fraction_rows(basis))
  assert_true(check_stationary_family(value, family))
  if basis.is_empty() {
    assert_eq(unique_stationary(value), Ok(fraction_vector(origin)))
  } else {
    assert_eq(unique_stationary(value), Err(NonUniqueStationary))
  }
  for i in 0..<parameters.length() {
    match members[i] {
      None =>
        assert_eq(
          stationary_member(family, fraction_vector(parameters[i])),
          Err(NegativeProbability),
        )
      Some(expected) => {
        let distribution = stationary_member(
          family,
          fraction_vector(parameters[i]),
        ).unwrap()
        assert_eq(distribution, fraction_vector(expected))
        assert_true(check_stationary(value, distribution))
        assert_eq(evolve(value, distribution), Ok(distribution))
      }
    }
  }
}

///|
test "reducible stationary family retains its nonnegative parameter constraints" {
  let value = identity(@oracle.nat(2)).unwrap()
  let family = stationary_affine(value).unwrap()
  assert_eq(stationary_origin(family), fraction_vector([(1, 1), (0, 1)]))
  assert_eq(stationary_directions(family), fraction_rows([[(-1, 1), (1, 1)]]))
  assert_eq(unique_stationary(value), Err(NonUniqueStationary))
  assert_eq(stationary_member(family, Nil), Err(DimensionMismatch))
  assert_eq(
    stationary_member(family, fraction_vector([(-1, 1)])),
    Err(NegativeProbability),
  )
  assert_eq(
    stationary_member(family, fraction_vector([(2, 1)])),
    Err(NegativeProbability),
  )
  assert_eq(
    stationary_member(family, fraction_vector([(1, 3)])),
    Ok(fraction_vector([(2, 3), (1, 3)])),
  )
  let triple = stationary_affine(identity(@oracle.nat(3)).unwrap()).unwrap()
  assert_eq(
    stationary_member(triple, fraction_vector([(1, 4), (1, 4)])),
    Ok(fraction_vector([(1, 2), (1, 4), (1, 4)])),
  )
}

///|
test "stationary check rejects incomplete dependent wrongly normalized or foreign families" {
  let value = identity(@oracle.nat(2)).unwrap()
  let family = stationary_affine(value).unwrap()
  assert_true(!check_stationary_family(value, { ..family, directions: Nil, }))
  assert_true(
    !check_stationary_family(value, {
      ..family,
      origin: fraction_vector([(0, 1), (0, 1)]),
    }),
  )
  assert_true(
    !check_stationary_family(value, {
      ..family,
      directions: fraction_rows([[(-1, 1), (1, 1)], [(-1, 1), (1, 1)]]),
    }),
  )
  assert_true(
    !check_stationary_family(value, {
      ..family,
      directions: fraction_rows([[(1, 1), (0, 1)]]),
    }),
  )
  assert_true(
    !check_stationary_family(identity(@oracle.nat(1)).unwrap(), family),
  )
  assert_true(!check_stationary(value, fraction_vector([(-1, 1), (2, 1)])))
}

///|
test "uniqueness requires neither irreducibility nor aperiodicity" {
  let reducible = kernel(fraction_rows([[(1, 1), (0, 1)], [(1, 3), (2, 3)]])).unwrap()
  assert_eq(unique_stationary(reducible), Ok(fraction_vector([(1, 1), (0, 1)])))
  let periodic = kernel(fraction_rows([[(0, 1), (1, 1)], [(1, 1), (0, 1)]])).unwrap()
  assert_eq(unique_stationary(periodic), Ok(fraction_vector([(1, 2), (1, 2)])))
  assert_eq(
    evolve(periodic, fraction_vector([(1, 1), (0, 1)])),
    Ok(fraction_vector([(0, 1), (1, 1)])),
  )
}
