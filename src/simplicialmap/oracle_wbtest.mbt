///|
fn verify_fixture(
  source : @homology.Complex,
  target : @homology.Complex,
  domain : Array[Int32],
  images : Array[Int32],
  widths : Array[Int32],
  expected : Array[Array[Array[Int32]]]?,
) -> Unit raise {
  let pairs : Array[(Int32, Int32)] = []
  for i in 0..<domain.length() {
    pairs.push((domain[i], images[i]))
  }
  let candidate = check(source, target, assignments(pairs))
  match expected {
    None => assert_eq(candidate, None)
    Some(matrices) => {
      let map = candidate.unwrap()
      for k in 0..<matrices.length() {
        let degree = @oracle.nat(k)
        let actual = chain_map(map, degree).unwrap()
        assert_eq(int_rows(actual), matrices[k])
        assert_eq(@matrix.width(actual), @oracle.nat(widths[k]))
        assert_true(check_chain_map(map, degree, actual))
      }
    }
  }
}

///|
fn three_vertex_functions() -> Array[Array[Int32]] {
  let result : Array[Array[Int32]] = []
  for a in 0..<3 {
    for b in 0..<3 {
      for c in 0..<3 {
        result.push([a, b, c])
      }
    }
  }
  result
}

///|
fn endomap(complex : @homology.Complex, images : Array[Int32]) -> SimplicialMap {
  check(
    complex,
    complex,
    assignments([(0, images[0]), (1, images[1]), (2, images[2])]),
  ).unwrap()
}

///|
test "all 729 triangle endomap compositions including degeneracies are functorial" {
  let triangle = generated([[0, 1, 2]])
  let maps = three_vertex_functions().map(fn(images) {
    endomap(triangle, images)
  })
  for before in maps {
    for after in maps {
      let composite = compose(after, before).unwrap()
      for k in 0..<4 {
        let degree = @oracle.nat(k)
        assert_eq(
          @matrix.multiply(
            chain_map(after, degree).unwrap(),
            chain_map(before, degree).unwrap(),
            @chainhomology.integers(),
          ),
          chain_map(composite, degree),
        )
      }
    }
  }
}

///|
test "all 729 circle endomap compositions induce multiplicative H1 degrees" {
  let c = circle()
  let h = completed(c, 1)
  let k = @oracle.nat(1)
  let functions = three_vertex_functions()
  let induced = functions.map(fn(images) {
    induce(endomap(c, images), k, h, h).unwrap()
  })
  for i in 0..<functions.length() {
    for j in 0..<functions.length() {
      let composite = compose(induced[j].map, induced[i].map).unwrap()
      let expected_images = functions[i].map(fn(image) { functions[j][image] })
      assert_eq(composite, endomap(c, expected_images))
      let actual = induce(composite, k, h, h).unwrap()
      let product = @matrix.multiply(
        induced[j].classes,
        induced[i].classes,
        @chainhomology.integers(),
      ).unwrap()
      assert_eq(actual.classes, product)
    }
  }
}
