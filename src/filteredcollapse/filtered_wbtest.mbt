///|
fn simplicial(facets : Array[Array[Int32]]) -> @homology.Complex {
  @homology.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
// Three independent monotone grade functions: constant, dimension, max label.
fn filtration(
  facets : Array[Array[Int32]],
  mode : Int32,
) -> @persistence.Filtration {
  let source = simplicial(facets)
  let entries : Array[@persistence.Entry] = []
  for degree in 0..<4 {
    for
      simplex in @oracle.array(@homology.simplices(source, @oracle.nat(degree))) {
      let vertices = @oracle.array(simplex).map(@oracle.int_of_nat)
      let grade = if mode == 0 {
        0
      } else if mode == 1 {
        degree
      } else {
        vertices[vertices.length() - 1]
      }
      entries.push({ simplex, grade: @oracle.rational(grade, 1), })
    }
  }
  entries.sort_by(fn(a, b) {
    match @exact.rational_compare(a.grade, b.grade) {
      Less => -1
      Greater => 1
      Equal =>
        @oracle.int_of_nat(@core.length(a.simplex)).compare(
          @oracle.int_of_nat(@core.length(b.simplex)),
        )
    }
  })
  @persistence.validate(@oracle.chain(entries)).unwrap()
}

///|
fn finish(source : @persistence.Filtration) -> Certificate {
  match run(start(source), @oracle.nat(1000)) {
    Stalled(witness) => witness
    _ => abort("small filtration must finish")
  }
}

///|
fn bars(source : @persistence.Filtration) -> Array[@persistence.Bar] {
  match
    @persistence.run(
      @persistence.start(source),
      @oracle.nat(3000),
      @oracle.nat(100),
    ) {
    Done(witness) => {
      if !@persistence.check_result(source, witness.bars, witness) {
        abort("persistence witness failed")
      }
      @oracle.array(witness.bars)
    }
    _ => abort("small persistence computation must finish")
  }
}

///|
fn same_profile(a : @persistence.Bar, b : @persistence.Bar) -> Bool {
  a.dimension == b.dimension && a.birth == b.birth && a.death == b.death
}

///|
fn verify_barcode(
  source : @persistence.Filtration,
  target : @persistence.Filtration,
) -> Unit raise {
  let a = bars(source)
  let b = bars(target)
  assert_eq(a.length(), b.length())
  for bar in a {
    assert_eq(
      a.filter(fn(x) { same_profile(bar, x) }).length(),
      b.filter(fn(x) { same_profile(bar, x) }).length(),
    )
  }
}

///|
test "empty singleton and constant-grade disk preserve grade barcodes" {
  for facets in [[], [[0]], [[0, 1, 2]], [[0, 1, 2, 3]]] {
    let source = filtration(facets, 0)
    let witness = finish(source)
    assert_true(check_stalled(source, witness.target, witness))
    assert_eq(
      @oracle.int_of_nat(@core.length(@persistence.entries(witness.target))),
      if facets.length() == 0 {
        0
      } else {
        1
      },
    )
    verify_barcode(source, witness.target)
  }
}

///|
test "ordinary collapsibility does not preserve positive-lifetime intervals" {
  let source = filtration([[0, 1, 2]], 1)
  let pair : @collapse.Pair = {
    lower: @oracle.chain([@oracle.nat(0), @oracle.nat(1)]),
    upper: @oracle.chain([@oracle.nat(0), @oracle.nat(1), @oracle.nat(2)]),
  }
  let ordinary = @collapse.elementary(complex(source).unwrap(), pair).unwrap()
  let target = remove(source, pair).unwrap()
  assert_eq(elementary(source, pair), None)
  assert_false(
    check_step(source, target, { source, target, contraction: ordinary, }),
  )
  let witness = finish(source)
  assert_eq(witness.target, source)
  assert_eq(witness.steps, @core.Nil)
  assert_true(check_stalled(source, source, witness))
  assert_eq(
    bars(source).filter(fn(bar) { bar.dimension == @oracle.nat(1) }).length(),
    1,
  )
  assert_eq(
    bars(target).filter(fn(bar) { bar.dimension == @oracle.nat(1) }).length(),
    0,
  )
}

///|
test "all nonzero contraction entries must respect filtration grades" {
  let matrix = @matrix.matrix(
    @oracle.nat(1),
    @oracle.chain([@oracle.chain([@oracle.integer(1)])]),
  ).unwrap()
  let zero = @matrix.matrix(
    @oracle.nat(1),
    @oracle.chain([@oracle.chain([@oracle.integer(0)])]),
  ).unwrap()
  let early = @oracle.chain([@oracle.rational(0, 1)])
  let late = @oracle.chain([@oracle.rational(1, 1)])
  assert_false(preserves(matrix, early, late))
  assert_true(preserves(matrix, late, early))
  assert_true(preserves(matrix, early, early))
  assert_true(preserves(zero, early, late))
  assert_false(preserves(matrix, @core.Nil, late))
}

///|
test "square Rips simplifies while retaining its nonzero H1 interval" {
  let cloud = @rips.cloud(
    @oracle.nat(2),
    @oracle.chain(
      [[0, 0], [1, 0], [1, 1], [0, 1]].map(fn(row) {
        @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
      }),
    ),
  ).unwrap()
  let source = @rips.build(cloud, @oracle.nat(3)).unwrap()
  let witness = finish(source)
  assert_true(check_stalled(source, witness.target, witness))
  assert_true(
    @core.compare(
      @core.length(@persistence.entries(witness.target)),
      @core.length(@persistence.entries(source)),
    )
    is Less,
  )
  verify_barcode(source, witness.target)
  let h1 = bars(witness.target).filter(fn(bar) {
    bar.dimension == @oracle.nat(1)
  })
  assert_eq(h1.length(), 1)
  assert_eq(
    (h1[0].birth, h1[0].death),
    (@oracle.rational(1, 1), Some(@oracle.rational(2, 1))),
  )
}

///|
test "finite complex families preserve all positive and essential intervals" {
  for
    facets in [
      [[0, 1]],
      [[0, 1], [1, 2], [0, 2]],
      [[0, 1, 2], [0, 2, 3]],
      [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]],
      [[0, 1], [1, 2], [0, 2], [2, 3]],
      [[0, 1, 2, 3]],
    ] {
    for mode in 0..<3 {
      let source = filtration(facets, mode)
      let witness = finish(source)
      assert_true(check_stalled(source, witness.target, witness))
      verify_barcode(source, witness.target)
    }
  }
}

///|
test "continuations and certificates bind sources results and all steps" {
  let source = filtration([[0, 1, 2, 3]], 0)
  let expected = finish(source)
  assert_true(run(start(source), @core.Zero) is Paused(_))
  let mut state = start(source)
  let mut found = None
  for _ in 0..<1000 {
    if found is None {
      match run(state, @oracle.nat(1)) {
        Paused(next) => state = next
        Stalled(value) => found = Some(value)
        InvalidWitness => abort("resumption must preserve witness")
      }
    }
  }
  assert_eq(found, Some(expected))
  let other = filtration([[0, 1, 2, 3]], 1)
  assert_false(check_result(other, expected.target, expected))
  assert_false(check_result(source, source, expected))
  assert_false(
    check_result(source, expected.target, { ..expected, steps: @core.Nil, }),
  )
  let steps = @oracle.array(expected.steps)
  let step = steps[0]
  assert_false(check_step(source, step.target, { ..step, target: source, }))
}
