///|
fn complex(facets : Array[Array[Int32]]) -> @hom.Complex {
  @hom.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn torus() -> @hom.Complex {
  complex([
    [0, 1, 2],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 6],
    [0, 1, 5],
    [1, 5, 6],
    [2, 3, 5],
    [2, 4, 5],
    [2, 3, 6],
    [0, 2, 6],
    [0, 3, 4],
    [0, 3, 5],
    [4, 5, 6],
    [0, 4, 6],
  ])
}

///|
fn wedge() -> @hom.Complex {
  complex([
    [0, 1],
    [1, 2],
    [0, 2],
    [0, 3],
    [3, 4],
    [0, 4],
    [0, 5, 6],
    [0, 5, 7],
    [0, 6, 7],
    [5, 6, 7],
  ])
}

///|
fn projective() -> @hom.Complex {
  complex([
    [0, 1, 2],
    [0, 2, 3],
    [0, 1, 5],
    [0, 4, 5],
    [0, 3, 4],
    [1, 2, 4],
    [1, 3, 4],
    [1, 3, 5],
    [2, 3, 5],
    [2, 4, 5],
  ])
}

///|
fn homology(source : @hom.Complex, degree : Int32) -> @hom.Certificate {
  match @hom.compute(source, @oracle.nat(degree), @oracle.nat(3000)) {
    @hom.Computed(witness) => {
      if !@hom.check_result(
          source,
          @oracle.nat(degree),
          witness.result,
          witness,
        ) {
        abort("integer homology certificate failed")
      }
      witness
    }
    _ => abort("small integer homology must finish")
  }
}

///|
fn ring(source : @hom.Complex, ranks : Array[Int32]) -> @co.Ring {
  let value = @co.compute_ring(source).unwrap()
  let result = @co.ring_result(value)
  if !@co.check_ring(source, result, @co.ring_certificate(value)) ||
    @oracle.array(result.groups).map(fn(group) {
      @oracle.int_of_nat(group.rank)
    }) !=
    ranks {
    abort("cohomology ring certificate or ranks failed")
  }
  value
}

///|
fn rings_demo() -> Unit {
  let torus = torus()
  let wedge = wedge()
  for source in [torus, wedge] {
    for degree in 0..<3 {
      let result = homology(source, degree).result
      if result.free_rank != @oracle.nat([1, 2, 1][degree]) ||
        result.torsion != @core.Nil {
        abort("torus and wedge must have identical additive integer homology")
      }
    }
  }
  let t = ring(torus, [1, 2, 1])
  let w = ring(wedge, [1, 2, 1])
  let a = @oracle.chain([true, false])
  let b = @oracle.chain([false, true])
  for value in [t, w] {
    for x in [a, b] {
      if @co.multiply(value, @oracle.nat(1), x, @oracle.nat(1), x) !=
        Some(@oracle.chain([false])) {
        abort("squares of degree-one classes must vanish in torus and wedge")
      }
    }
  }
  if @co.multiply(t, @oracle.nat(1), a, @oracle.nat(1), b) !=
    Some(@oracle.chain([true])) ||
    @co.multiply(w, @oracle.nat(1), a, @oracle.nat(1), b) !=
    Some(@oracle.chain([false])) {
    abort("cup product must distinguish torus from the wedge")
  }
  println("torus and S1 v S1 v S2: same integer H0=Z, H1=Z^2, H2=Z [checked]")
  println(
    "GF(2) cup product: torus a*b is nonzero; wedge a*b is zero [checked]",
  )
  let rp = ring(projective(), [1, 1, 1])
  let a = @oracle.chain([true])
  if @co.multiply(rp, @oracle.nat(1), a, @oracle.nat(1), a) !=
    Some(@oracle.chain([true])) {
    abort("RP2 generator must have nonzero square")
  }
  if @co.multiply(rp, @oracle.nat(1), a, @oracle.nat(2), a) != Some(@core.Nil) {
    abort("RP2 product above dimension must be zero")
  }
  println("RP2: GF(2) cohomology ring has a^2 nonzero and a^3=0 [checked]")
}

///|
fn relative(pair : @rel.Pair, degree : Int32) -> @rel.Certificate {
  match @rel.compute(pair, @oracle.nat(degree), @oracle.nat(3000)) {
    @rel.Computed(witness) => {
      if !@rel.check_result(pair, @oracle.nat(degree), witness.result, witness) {
        abort("relative homology certificate failed")
      }
      witness
    }
    _ => abort("small relative homology must finish")
  }
}

///|
fn relative_demo() -> Unit {
  let disk = complex([[0, 1, 2]])
  let boundary = complex([[0, 1], [0, 2], [1, 2]])
  let pair = @rel.pair(disk, boundary).unwrap()
  let h = relative(pair, 2)
  let connecting = @rel.connect(pair, @oracle.nat(2), h, homology(boundary, 1)).unwrap()
  let rows = @oracle.array(@matrix.rows(connecting.classes))
  if h.result.free_rank != @oracle.nat(1) ||
    !@rel.check_connecting(pair, @oracle.nat(2), connecting.classes, connecting) ||
    rows.length() != 1 ||
    @oracle.int_of_integer(@core.nth(rows[0], @core.Zero).unwrap()).abs() != 1 {
    abort("disk boundary connecting map must be an integer isomorphism")
  }
  println(
    "(disk,boundary): H2=Z; connecting map to H1(boundary)=Z is an isomorphism [checked]",
  )
  let endpoints = complex([[0], [1]])
  let pair = @rel.pair(complex([[0, 1]]), endpoints).unwrap()
  let h = relative(pair, 1)
  let connecting = @rel.connect(pair, @oracle.nat(1), h, homology(endpoints, 0)).unwrap()
  let image = @oracle.array(
    @rel.apply_connecting(connecting, @oracle.chain([@oracle.integer(1)])).unwrap(),
  ).map(@oracle.int_of_integer)
  if !@rel.check_connecting(
      pair,
      @oracle.nat(1),
      connecting.classes,
      connecting,
    ) ||
    image != [-1, 1] {
    abort("interval relative cycle must map to endpoint difference")
  }
  println(
    "(interval,endpoints): connecting map sends 1 to (-1,1) in Z^2 [checked]",
  )
}

///|
fn bars(source : @ph.Filtration) -> Array[@ph.Bar] {
  match @ph.run(@ph.start(source), @oracle.nat(3000), @oracle.nat(100)) {
    @ph.Done(witness) => {
      if !@ph.check_result(source, witness.bars, witness) {
        abort("persistence check failed")
      }
      @oracle.array(witness.bars)
    }
    _ => abort("small persistence must finish")
  }
}

///|
fn collapse_demo() -> Unit {
  let disk = complex([[0, 1, 2]])
  let sequence = match @collapse.run(@collapse.start(disk), @oracle.nat(1000)) {
    @collapse.Stalled(value) => value
    _ => abort("small disk collapse must finish")
  }
  if !@collapse.check_sequence(disk, sequence.target, sequence) ||
    @core.length(@hom.all_simplices(sequence.target)) != @oracle.nat(1) {
    abort("disk contraction must reach one vertex")
  }
  println(
    "filled triangle: 7 simplices -> 1, with exact integer I/P/H identities [checked]",
  )
  let cloud = @rips.cloud(
    @oracle.nat(2),
    @oracle.chain(
      [[0, 0], [1, 0], [1, 1], [0, 1]].map(fn(row) {
        @oracle.chain(row.map(fn(x) { @oracle.rational(x, 1) }))
      }),
    ),
  ).unwrap()
  let source = @rips.build(cloud, @oracle.nat(3)).unwrap()
  let proof = match @fc.run(@fc.start(source), @oracle.nat(1000)) {
    @fc.Stalled(value) => value
    _ => abort("filtered square collapse must finish")
  }
  let before = bars(source)
  let after = bars(proof.target)
  if !@fc.check_stalled(source, proof.target, proof) ||
    before.length() != after.length() {
    abort("filtered contraction or barcode check failed")
  }
  for bar in before {
    let same = fn(x : @ph.Bar) {
      x.dimension == bar.dimension &&
      x.birth == bar.birth &&
      x.death == bar.death
    }
    if before.filter(same).length() != after.filter(same).length() {
      abort("grade barcode changed")
    }
  }
  let n = @oracle.int_of_nat(@core.length(@ph.entries(source)))
  let m = @oracle.int_of_nat(@core.length(@ph.entries(proof.target)))
  if m >= n {
    abort("square should admit equal-grade contractions")
  }
  println(
    "square Rips: \{n} simplices -> \{m}; grade barcode including H1=[1,2) preserved [checked]",
  )
}

///|
#cfg(target="js")
fn argument_prefix() -> Int32 {
  2
}

///|
#cfg(not(target="js"))
fn argument_prefix() -> Int32 {
  1
}

///|
fn main {
  let args = @env.args()
  let prefix = argument_prefix()
  let mode = if args.length() <= prefix {
    "all"
  } else if args.length() == prefix + 1 {
    args[prefix]
  } else {
    abort("expected at most one mode argument")
  }
  match mode {
    "rings" => rings_demo()
    "relative" => relative_demo()
    "collapse" => collapse_demo()
    "all" => {
      rings_demo()
      relative_demo()
      collapse_demo()
    }
    _ => abort("expected all, rings, relative or collapse")
  }
}
