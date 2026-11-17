///|
fn complex(facets : Array[Array[Int32]]) -> @hom.Complex {
  @hom.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
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
        abort("integer homology witness failed")
      }
      witness
    }
    _ => abort("small integer homology must finish")
  }
}

///|
fn persistence(source : @ph.Filtration) -> @ph.Certificate {
  match @ph.run(@ph.start(source), @oracle.nat(2000), @oracle.nat(100)) {
    @ph.Done(witness) => {
      if !@ph.check_result(source, @ph.barcode(witness), witness) {
        abort("persistence reduction witness failed")
      }
      witness
    }
    _ => abort("small filtration must finish")
  }
}

///|
fn square() -> @rips.Cloud {
  @rips.cloud(
    @oracle.nat(2),
    @oracle.chain(
      [[0, 0], [1, 0], [1, 1], [0, 1]].map(fn(point) {
        @oracle.chain(point.map(fn(x) { @oracle.rational(x, 1) }))
      }),
    ),
  ).unwrap()
}

///|
fn at_grade(source : @ph.Filtration, grade : Int32) -> @hom.Complex {
  let entries = @core.filter(@ph.entries(source), fn(entry) {
    !(@exact.rational_compare(entry.grade, @oracle.rational(grade, 1))
    is Greater)
  })
  @hom.validate(@core.map(entries, fn(entry) { entry.simplex })).unwrap()
}

///|
fn rips_demo() -> Unit {
  let cloud = square()
  let source = @rips.build(cloud, @oracle.nat(3)).unwrap()
  if !@rips.check_filtration(cloud, @oracle.nat(3), source) {
    abort("exact point cloud filtration failed")
  }
  let witness = persistence(source)
  let bars = @oracle.array(@ph.barcode(witness))
  let h1 = bars.filter(fn(bar) { bar.dimension == @oracle.nat(1) })
  if bars.length() != 5 ||
    h1.length() != 1 ||
    h1[0].birth != @oracle.rational(1, 1) ||
    h1[0].death != Some(@oracle.rational(2, 1)) {
    abort("square barcode has incorrect endpoints")
  }
  println(
    "square: exact squared distances; H1 barcode [1,2) over GF(2) [checked]",
  )
  let before = homology(at_grade(source, 1), 1)
  let after = homology(at_grade(source, 2), 1)
  if before.result.free_rank != @oracle.nat(1) ||
    after.result.free_rank != @oracle.nat(0) {
    abort("square integer homology disagrees with persistence")
  }
  println("square: H1 over Z is Z at grade 1, zero at grade 2 [checked]")
  let skeleton = @rips.build(cloud, @oracle.nat(2)).unwrap()
  let truncated = @oracle.array(@ph.barcode(persistence(skeleton)))
  if truncated
    .filter(fn(bar) { bar.dimension == @oracle.nat(2) && bar.death is None })
    .length() !=
    1 ||
    bars.filter(fn(bar) { bar.dimension == @oracle.nat(2) }).length() != 0 {
    abort("dimension truncation example failed")
  }
  println(
    "square: stopping at triangles leaves H2; adding the tetrahedron kills it [checked]",
  )
}

///|
fn maps_demo() -> Unit {
  let circle = complex([[0, 1], [0, 2], [1, 2]])
  let disk = complex([[0, 1, 2]])
  let h1 = homology(circle, 1)
  let reflection = @sm.check(
    circle,
    circle,
    @oracle.chain(
      [(0, 0), (1, 2), (2, 1)].map(fn(pair) {
        (@oracle.nat(pair.0), @oracle.nat(pair.1))
      }),
    ),
  ).unwrap()
  let induced = @sm.induce(reflection, @oracle.nat(1), h1, h1).unwrap()
  if !@sm.check_induced(reflection, @oracle.nat(1), induced.classes, induced) ||
    @sm.apply(induced, @oracle.chain([@oracle.integer(3)])) !=
    Some(@oracle.chain([@oracle.integer(-3)])) {
    abort("circle reflection must have degree minus one")
  }
  let inclusion = @sm.check(
    circle,
    disk,
    @oracle.chain(
      [(0, 0), (1, 1), (2, 2)].map(fn(pair) {
        (@oracle.nat(pair.0), @oracle.nat(pair.1))
      }),
    ),
  ).unwrap()
  let killed = @sm.induce(inclusion, @oracle.nat(1), h1, homology(disk, 1)).unwrap()
  if !@sm.check_induced(inclusion, @oracle.nat(1), killed.classes, killed) ||
    !@core.all(
      @sm.apply(killed, @oracle.chain([@oracle.integer(3)])).unwrap(),
      fn(x) { x == @oracle.integer(0) },
    ) {
    abort("circle inclusion into disk must kill H1")
  }
  println("circle reflection: induced H1 map over Z sends 3 to -3 [checked]")
  println("circle -> filled triangle: induced H1 map is zero [checked]")
}

///|
fn distance(code : @css.Code, axis : @css.Axis) -> Int32 {
  match @css.run_distance(@css.start_distance(code, axis), @oracle.nat(6000)) {
    @css.Found(witness) => {
      if @css.check_distance(code, axis, witness, @oracle.nat(6000)) !=
        @css.Verified {
        abort("minimum logical weight replay failed")
      }
      @oracle.int_of_nat(witness.distance)
    }
    _ => abort("small code must have an exact logical distance")
  }
}

///|
fn show_code(
  label : String,
  code : @css.Code,
  n : Int32,
  k : Int32,
  dx : Int32,
  dz : Int32,
) -> Unit {
  let p = @css.parameters(code)
  if !@css.check_parameters(code, p, @css.certificate(code)) ||
    p.physical != @oracle.nat(n) ||
    p.logical != @oracle.nat(k) ||
    distance(code, @css.X) != dx ||
    distance(code, @css.Z) != dz {
    abort("CSS parameters or distances disagree")
  }
  println("\{label}: n=\{n}, k=\{k}, dX=\{dx}, dZ=\{dz} [checked]")
}

///|
fn projective_plane() -> @hom.Complex {
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
fn codes_demo() -> Unit {
  let source = @rips.build(square(), @oracle.nat(3)).unwrap()
  show_code(
    "square cycle CSS",
    @css.from_complex(at_grade(source, 1), @oracle.nat(1)).unwrap(),
    4,
    1,
    1,
    4,
  )
  let filled = @css.from_complex(at_grade(source, 2), @oracle.nat(1)).unwrap()
  if @css.parameters(filled).logical != @core.Zero ||
    @css.run_distance(@css.start_distance(filled, @css.X), @core.Zero) !=
    @css.NoLogical {
    abort("filled square has no nontrivial logical classes")
  }
  println("filled square CSS: k=0; no logical distance [checked]")
  let hamming = @matrix.matrix(
    @oracle.nat(7),
    @oracle.chain(
      [
        [true, false, true, false, true, false, true],
        [false, true, true, false, false, true, true],
        [false, false, false, true, true, true, true],
      ].map(@oracle.chain),
    ),
  ).unwrap()
  show_code("Steane CSS", @css.validate(hamming, hamming).unwrap(), 7, 1, 3, 3)
  let rp = projective_plane()
  let integer = homology(rp, 1)
  if integer.result.free_rank != @core.Zero ||
    integer.result.torsion != @oracle.chain([@oracle.binary(2)]) {
    abort("RP2 must retain integer torsion")
  }
  // Coefficients change the result. This comparison is with the same actual
  // simplicial boundaries, reduced modulo two for the CSS adapter.
  let entries : Array[@ph.Entry] = []
  for degree in 0..<=2 {
    for simplex in @oracle.array(@hom.simplices(rp, @oracle.nat(degree))) {
      entries.push({ simplex, grade: @oracle.rational(degree, 1), })
    }
  }
  let bars = @oracle.array(
    @ph.barcode(persistence(@ph.validate(@oracle.chain(entries)).unwrap())),
  )
  for degree in [1, 2] {
    if bars
      .filter(fn(bar) {
        bar.dimension == @oracle.nat(degree) && bar.death is None
      })
      .length() !=
      1 {
      abort("RP2 must have GF2 Betti numbers one in degrees one and two")
    }
  }
  println("RP2: integer H1=Z/2; GF(2) Betti numbers (1,1,1) [checked]")
  show_code(
    "RP2 edge CSS",
    @css.from_complex(rp, @oracle.nat(1)).unwrap(),
    15,
    1,
    5,
    3,
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
    "rips" => rips_demo()
    "maps" => maps_demo()
    "codes" => codes_demo()
    "all" => {
      rips_demo()
      maps_demo()
      codes_demo()
    }
    _ => abort("expected all, rips, maps or codes")
  }
}
