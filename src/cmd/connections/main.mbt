///|
/// Ordinary machine values construct and display examples only. Every group,
/// polynomial bound, boundary matrix and certificate uses the symbolic packages.
fn polynomial(coefficients : Array[(Int32, Int32)]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, fraction in coefficients => {
          let (numerator, denominator) = fraction
          @poly.Term::{
            coefficient: @oracle.rational(numerator, denominator),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn fraction_text(value : @exact.Rational) -> String {
  let numerator = @oracle.int_of_integer(@exact.numerator(value))
  let denominator = @oracle.int_of_binary(@exact.denominator(value))
  if denominator == 1 {
    numerator.to_string()
  } else {
    "\{numerator}/\{denominator}"
  }
}

///|
fn permutations(values : Array[Array[Int32]]) -> @core.Chain[@pg.Permutation] {
  @oracle.chain(
    values.map(fn(images) {
      @pg.checked_permutation(
        @oracle.nat(images.length()),
        @oracle.chain(images.map(@oracle.nat)),
      ).unwrap()
    }),
  )
}

///|
fn show_group(
  label : String,
  degree : Int32,
  generators : Array[Array[Int32]],
  expected_orders : Array[Int32],
  solvable : Bool,
) -> Unit {
  let degree = @oracle.nat(degree)
  let generators = permutations(generators)
  let group = match @pg.generate(degree, generators, @oracle.nat(200)) {
    @pg.Complete(group) => group
    _ => abort("small generated group must complete")
  }
  let proof = @pg.analyze(group)
  let orders = @oracle.array(@pg.series_orders(proof)).map(@oracle.int_of_nat)
  if orders != expected_orders ||
    @pg.is_solvable(proof) != solvable ||
    !@pg.check_result(group, proof) {
    abort("generated group or derived-series verification failed")
  }
  let orders = orders.map(fn(value) { value.to_string() }).join(" -> ")
  println("\{label}: derived orders \{orders}; solvable=\{solvable} [checked]")
}

///|
fn group_demo() -> Unit {
  show_group("S4", 4, [[1, 0, 2, 3], [1, 2, 3, 0]], [24, 12, 4, 1], true)
  show_group("A5", 5, [[1, 2, 0, 3, 4], [1, 2, 3, 4, 0]], [60], false)
  show_group("S5", 5, [[1, 0, 2, 3, 4], [1, 2, 3, 4, 0]], [120, 60], false)
}

///|
fn bernstein_demo() -> Unit {
  let p = polynomial([(3, 8), (-1, 1), (1, 1)])
  let box : @core.Chain[@bern.Axis] = Cons(
    @bern.Axis::{
      lower: @oracle.rational(0, 1),
      upper: @oracle.rational(1, 1),
    },
    Nil,
  )
  let degrees : @core.Chain[@core.Nat] = Cons(@oracle.nat(2), Nil)
  let enclosure = @bern.bound(p, box, degrees).unwrap()
  if !@bern.check_bound(p, box, enclosure) ||
    enclosure.lower != @oracle.rational(-1, 8) ||
    enclosure.upper != @oracle.rational(3, 8) {
    abort("initial Bernstein enclosure failed")
  }
  println(
    "x^2-x+3/8 on [0,1]: initial Bernstein enclosure [\{fraction_text(enclosure.lower)},\{fraction_text(enclosure.upper)}] [checked]",
  )
  let paused = match
    @bern.certify(p, box, degrees, @bern.Positive, Zero).unwrap() {
    @bern.Paused(state) => state
    _ => abort("initial coefficients do not yet prove strict positivity")
  }
  let outcome = @bern.resume_search(paused, @oracle.nat(1)).unwrap()
  if !@bern.check_outcome(p, box, @bern.Positive, outcome) {
    abort("subdivision certificate failed")
  }
  match outcome {
    @bern.Certified(state) => {
      let (leaves, splits, open) = @bern.tree_counts(state.tree)
      if @oracle.int_of_nat(leaves) != 2 ||
        @oracle.int_of_nat(splits) != 1 ||
        !@core.is_zero(open) {
        abort("unexpected positivity proof shape")
      }
      println("  one midpoint split: p>0; 2 certified leaves [checked]")
    }
    _ => abort("one subdivision must prove this quadratic positive")
  }
  let problem = @rcad.prepare(@rcad.Atom(p, @rcad.GreaterZero)).unwrap()
  match @rcad.run(@rcad.start(problem), @oracle.nat(1000)) {
    @rcad.Complete(result) => {
      if !@rcad.universally_true(result) ||
        @rcad.check(problem, @rcad.certificate(result)) is None {
        abort("independent CAD positivity route failed")
      }
      println("  same polynomial: p>0 on all real x by CAD [checked]")
    }
    _ => abort("small CAD example must finish")
  }
  let x = polynomial([(0, 1), (1, 1)])
  let outcome = @bern.certify(
    x,
    box,
    Cons(@oracle.nat(1), Nil),
    @bern.Positive,
    Zero,
  ).unwrap()
  if !@bern.check_outcome(x, box, @bern.Positive, outcome) {
    abort("closed-box boundary counterexample failed")
  }
  match outcome {
    @bern.Counterexample(_, witness) => {
      if witness.point != Cons(@oracle.rational(0, 1), Nil) {
        abort("expected boundary counterexample zero")
      }
      println("x on [0,1]: x>0 refuted at x=0; x>=0 certified [checked]")
    }
    _ => abort("strict positivity must fail at closed-box boundary")
  }
  let nonnegative = @bern.certify(
    x,
    box,
    Cons(@oracle.nat(1), Nil),
    @bern.Nonnegative,
    Zero,
  ).unwrap()
  match nonnegative {
    @bern.Certified(_) =>
      if !@bern.check_outcome(x, box, @bern.Nonnegative, nonnegative) {
        abort("nonnegative boundary proof failed")
      }
    _ => abort("x must be nonnegative on the closed box")
  }
}

///|
fn complex(facets : Array[Array[Int32]]) -> @hom.Complex {
  @hom.closure(
    @oracle.chain(facets.map(fn(face) { @oracle.chain(face.map(@oracle.nat)) })),
  ).unwrap()
}

///|
fn show_homology(
  label : String,
  source : @hom.Complex,
  expected : Array[(Int32, Array[Int32])],
) -> Unit {
  let descriptions = [
    for index, item in expected => {
      let (free, torsion) = item
      let degree = @oracle.nat(index)
      let proof = match @hom.compute(source, degree, @oracle.nat(3000)) {
        @hom.Computed(proof) => proof
        _ => abort("small integer homology computation must finish")
      }
      let actual = @hom.result(proof)
      if actual.free_rank != @oracle.nat(free) ||
        actual.torsion != @oracle.chain(torsion.map(@oracle.binary)) ||
        !@hom.check_result(source, degree, actual, proof) ||
        !@hom.boundary_squared_zero(source, degree) {
        abort("integer homology certificate failed")
      }
      let parts = []
      if free == 1 {
        parts.push("Z")
      } else if free > 1 {
        parts.push("Z^\{free}")
      }
      for factor in torsion {
        parts.push("Z/\{factor}")
      }
      let text = if parts.is_empty() { "0" } else { parts.join(" + ") }
      "H\{index}=\{text}"
    }
  ]
  let euler = @oracle.int_of_integer(@hom.euler_characteristic(source))
  println("\{label}: \{descriptions.join("; ")}; Euler=\{euler} [checked]")
}

///|
fn homology_demo() -> Unit {
  show_homology("circle", complex([[0, 1], [0, 2], [1, 2]]), [
    (1, []),
    (1, []),
    (0, []),
  ])
  show_homology("filled triangle", complex([[0, 1, 2]]), [
    (1, []),
    (0, []),
    (0, []),
  ])
  show_homology(
    "sphere",
    complex([[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]),
    [(1, []), (0, []), (1, [])],
  )
  show_homology("real projective plane", projective_plane(), [
    (1, []),
    (0, [2]),
    (0, []),
  ])
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
fn presented_group(
  generators : Int32,
  relators : Array[Array[Int32]],
  free : Int32,
  torsion : Array[Int32],
) -> @pre.Abelianization {
  let source = @pre.checked_presentation(
    @oracle.nat(generators),
    @oracle.chain(
      relators.map(fn(word) {
        @oracle.chain(
          word.map(fn(letter) {
            if letter == 0 {
              abort("signed words use one-based generator indices")
            }
            @pre.Letter::{
              generator: @oracle.nat(letter.abs() - 1),
              inverse: letter < 0,
            }
          }),
        )
      }),
    ),
  ).unwrap()
  match @pre.run(@pre.start(source), @oracle.nat(1000)) {
    @pre.Done(value, proof) => {
      if !@pre.check_result(source, value, proof) ||
        @pre.free_rank(value) != @oracle.nat(free) ||
        @pre.torsion_factors(value) !=
        @oracle.chain(torsion.map(@oracle.binary)) {
        abort("presentation abelianization failed")
      }
      value
    }
    _ => abort("small presentation must finish")
  }
}

///|
fn compare_homology(
  source : @hom.Complex,
  abelian : @pre.Abelianization,
) -> Unit {
  match @hom.compute(source, @oracle.nat(1), @oracle.nat(3000)) {
    @hom.Computed(proof) => {
      let h = @hom.result(proof)
      if !@hom.check_result(source, @oracle.nat(1), h, proof) ||
        h.free_rank != @pre.free_rank(abelian) ||
        h.torsion != @pre.torsion_factors(abelian) {
        abort("independent boundary and presentation routes disagree")
      }
    }
    _ => abort("small first homology must finish")
  }
}

///|
fn presentation_demo() -> Unit {
  let projective = presented_group(1, [[1, 1]], 0, [2])
  compare_homology(projective_plane(), projective)
  println(
    "RP2: <a | a^2> abelianization = H1 from simplicial boundaries = Z/2 [checked]",
  )
  let torus_group = presented_group(2, [[1, 2, -1, -2]], 2, [])
  compare_homology(torus(), torus_group)
  println(
    "torus: <a,b | [a,b]> abelianization = H1 from simplicial boundaries = Z^2 [checked]",
  )
  ignore(presented_group(2, [[1, 2, -1, 2]], 1, [2]))
  println("Klein bottle presentation: abelianization Z + Z/2 [checked]")
  ignore(presented_group(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2]], 0, [2]))
  println("<a,b | a^2,b^3,(ab)^2>: abelianization Z/2 [checked]")
  ignore(
    presented_group(2, [[1, 1], [2, 2, 2], [1, 2, 1, 2, 1, 2, 1, 2, 1, 2]], 0, []),
  )
  println(
    "triangle (2,3,5) presentation: abelianization 0; this alone does not imply a trivial group [checked]",
  )
}

///|
fn galois_demo() -> Unit {
  let input = polynomial([(-2, 1), (0, 1), (0, 1), (1, 1)])
  let budget : @split.Budget = {
    algebra: {
      attempts: @oracle.nat(12),
      work: @oracle.nat(3000),
      coordinate: @oracle.nat(1000),
      comparison: @oracle.nat(1000),
      primes: @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      lift: @oracle.nat(100),
      subset: @oracle.nat(500),
      verification: @oracle.nat(500),
      realization: @oracle.nat(1000),
    },
    primitive: @oracle.nat(12),
  }
  let field = match @split.solve(input, budget).unwrap() {
    @split.Ready(value, _) => value
    _ => abort("small cubic splitting field must finish")
  }
  let group = match
    @gal.advance(@gal.start(field).unwrap(), @oracle.nat(100)).unwrap() {
    @gal.Ready(value, _) => value
    _ => abort("small full Galois group must finish")
  }
  match @rad.advance(@rad.start(group).unwrap(), @oracle.nat(100)).unwrap() {
    @rad.Ready(value, proof) => {
      if !@rad.is_solvable_by_radicals(value) ||
        !@rad.check_result(group, value, proof) ||
        @rad.derived_orders(value) != @oracle.chain([6, 3, 1].map(@oracle.nat)) {
        abort("Galois-to-derived-series connection failed")
      }
      println(
        "z^3-2: full Galois action -> derived orders 6 -> 3 -> 1; solvable by radicals [checked]",
      )
    }
    _ => abort("small Galois-derived analysis must finish")
  }
}

///|
/// Node supplies both its executable and script path; native and moonrun
/// supply one program prefix. Keep this host detail outside symbolic kernels.
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
    "groups" => group_demo()
    "bernstein" => bernstein_demo()
    "homology" => homology_demo()
    "presentation" => presentation_demo()
    "galois" => galois_demo()
    "all" => {
      group_demo()
      bernstein_demo()
      homology_demo()
      presentation_demo()
      galois_demo()
    }
    _ =>
      abort("expected all, groups, bernstein, homology, presentation or galois")
  }
}
