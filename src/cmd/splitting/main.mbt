///|
/// Machine numbers only construct/print fixed examples; the exact fields,
/// polynomial roots, group search and proof checkers use symbolic libraries.
fn polynomial(coefficients : Array[Int32]) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(1),
    @oracle.chain(
      [
        for index, coefficient in coefficients => {
          @poly.Term::{
            coefficient: @oracle.rational(coefficient, 1),
            exponents: Cons(@oracle.nat(index), Nil),
          }
        }
      ],
    ),
  ).unwrap()
}

///|
fn budget() -> @split.Budget {
  {
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
}

///|
fn finish_field(search : @split.Search) -> @split.Splitting {
  match @split.advance(search, budget()).unwrap() {
    @split.Ready(value, proof) => {
      if !@split.check_result(
          @split.source(value),
          @split.ambient(value),
          value,
          proof,
        ) {
        abort("splitting field proof failed")
      }
      value
    }
    @split.Paused(next, _) => finish_field(next)
  }
}

///|
fn finish_group(search : @gal.Search) -> @gal.Group {
  match @gal.advance(search, @oracle.nat(100)).unwrap() {
    @gal.Ready(value, proof) => {
      if !@gal.check_result(@gal.source(value), value, proof) {
        abort("full Galois group proof failed")
      }
      value
    }
    @gal.Paused(next) => finish_group(next)
  }
}

///|
fn solve(
  coefficients : Array[Int32],
  expected_degree : Int32,
  label : String,
) -> @gal.Group {
  let field = finish_field(@split.start(polynomial(coefficients)).unwrap())
  let group = finish_group(@gal.start(field).unwrap())
  let degree = @oracle.int_of_nat(@split.degree(field))
  let order = @oracle.int_of_nat(@gal.order(group))
  if degree != expected_degree || order != degree {
    abort("wrong minimal degree or full group order")
  }
  println(
    "\{label}: minimal degree=\{degree}; group order=\{order}; all roots and full group [checked]",
  )
  group
}

///|
fn map_by_permutation(
  group : @gal.Group,
  expected : Array[Int32],
) -> @gal.Automorphism {
  let permutations = @oracle.chain(expected.map(@oracle.nat))
  for value in @oracle.array(@gal.automorphisms(group)) {
    if @gal.permutation(value) == permutations {
      return value
    }
  }
  abort("expected group action absent")
}

///|
fn verify_dihedral(
  group : @gal.Group,
  rotation : Array[Int32],
  reflection : Array[Int32],
  order : Int32,
) -> Unit {
  let r = map_by_permutation(group, rotation)
  let t = map_by_permutation(group, reflection)
  let mut power = @gal.identity(group)
  for _ in 0..<order {
    power = @gal.compose(group, r, power).unwrap()
  }
  let t2 = @gal.compose(group, t, t).unwrap()
  let conjugated = @gal.compose(group, t, @gal.compose(group, r, t).unwrap()).unwrap()
  if !@gal.equal(power, @gal.identity(group)) ||
    !@gal.equal(t2, @gal.identity(group)) ||
    !@gal.equal(conjugated, @gal.inverse(group, r).unwrap()) {
    abort("semidirect product relations failed")
  }
}

///|
fn quartic() -> @gal.Group {
  let work = budget().algebra
  let input : @real.RootCertificate = {
    polynomial: polynomial([-2, 0, 0, 0, 1]),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }
  let field = match
    @minimal.normalize_root(
      input,
      work.primes,
      work.lift,
      work.subset,
      work.verification,
    ).unwrap() {
    @minimal.Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, work.verification).unwrap())
    _ => abort("quartic real generator needs more budget")
  }
  let real = @cf.real_field(field)
  let a = @cf.element(field, @nf.generator(real).unwrap(), @nf.zero(real)).unwrap()
  let ia = @cf.multiply(@cf.imaginary_unit(field), a).unwrap()
  let roots = @oracle.chain(
    [a, @cf.negate(a), ia, @cf.negate(ia)].map(fn(value) {
      @split.Root::{ value, multiplicity: @oracle.nat(1), }
    }),
  )
  let splitting = finish_field(
    @split.start_from_roots(polynomial([-2, 0, 0, 0, 1]), field, roots).unwrap(),
  )
  let group = finish_group(@gal.start(splitting).unwrap())
  if @oracle.int_of_nat(@gal.order(group)) != 8 ||
    @oracle.int_of_nat(@split.degree(splitting)) != 8 {
    abort("quartic minimal splitting field must have degree8")
  }
  verify_dihedral(group, [2, 3, 1, 0], [0, 1, 3, 2], 4)
  println(
    "z^4-2 (supplied exact roots): minimal degree=8; Gal=D4; faithful root action and relations [checked]",
  )
  group
}

///|
fn main {
  let _ = solve([-1, 0, 1], 1, "z^2-1")
  let _ = solve([1, 0, 1], 2, "z^2+1")
  let _ = solve([-1, 0, 0, 1], 2, "z^3-1")
  let cubic = solve([-2, 0, 0, 1], 6, "z^3-2")
  verify_dihedral(cubic, [1, 2, 0], [0, 2, 1], 3)
  println(
    "z^3-2: Gal=S3; all six permutations, r^3=t^2=1 and t*r*t=r^-1 [checked]",
  )
  let field = @gal.source(cubic)
  let i = @cf.imaginary_unit(@split.ambient(field))
  if @oracle.int_of_nat(@cf.degree(@split.ambient(field))) != 12 ||
    @sub.contains(@split.generated_field(field), i) {
    abort("ambient quadratic extension was not removed")
  }
  let values = @oracle.array(@split.roots(field))
  let imaginary_sqrt3 = @cf.divide(
      @cf.subtract(values[1].value, values[2].value).unwrap(),
      values[0].value,
    )
    .unwrap()
    .unwrap()
  let sqrt3 = @cf.multiply(@cf.negate(i), imaginary_sqrt3).unwrap()
  if @sub.contains(@split.generated_field(field), sqrt3) ||
    !@sub.contains(@split.generated_field(field), imaginary_sqrt3) {
    abort("minimal cubic field membership failed")
  }
  println(
    "cubic ambient degree12 -> splitting degree6: i and sqrt3 excluded, i*sqrt3 included [checked]",
  )
  let _ = quartic()
}
