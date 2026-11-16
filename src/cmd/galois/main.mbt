///|
/// Machine values schedule and print this finite tour. All field/group/linear
/// computations and certificate checks are in the pure symbolic libraries.
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
fn splitting_field() -> @cf.Field {
  let input : @real.RootCertificate = {
    polynomial: polynomial([-2, 0, 0, 0, 1]),
    interval: { lower: @oracle.rational(1, 1), upper: @oracle.rational(2, 1), },
  }
  match
    @minimal.normalize_root(
      input,
      @oracle.chain([2, 3, 5, 7, 11, 13].map(@oracle.binary)),
      @oracle.nat(100),
      @oracle.nat(500),
      @oracle.nat(500),
    ).unwrap() {
    Normalized(value, proof) =>
      @cf.field(@nf.field_result(value, proof, @oracle.nat(500)).unwrap())
    _ => abort("splitting-field input needs a verified real minimum")
  }
}

///|
fn fixed_case(
  group : @aut.Group,
  name : String,
  members : Array[Int32],
  expected_degree : Int32,
  generator : @cf.Element,
  expected_minimum : Array[Int32],
) -> Unit {
  let value = @fixed.prepare(group, @oracle.chain(members.map(@oracle.nat))).unwrap()
  let minimum = @cf.minimal_polynomial(generator).unwrap()
  let coefficients = @fixed.coordinates(value, generator).unwrap()
  if @oracle.int_of_nat(@fixed.degree(value)) != expected_degree ||
    !@fixed.check_result(group, value, @fixed.certificate(value)) ||
    !@fixed.contains(value, generator) ||
    !@cf.equal(@fixed.from_coordinates(value, coefficients).unwrap(), generator) ||
    minimum != polynomial(expected_minimum) ||
    !@cf.check_minimal_polynomial(generator, minimum) {
    abort("fixed-field identity, completeness or generator minimum failed")
  }
  println(
    "\{name}: subgroup order=\{members.length()}; fixed degree=\{expected_degree}; generator and full invariant basis [checked]",
  )
}

///|
fn main {
  let field = splitting_field()
  let base = @cf.real_field(field)
  let a = @cf.element(field, @nf.generator(base).unwrap(), @nf.zero(base)).unwrap()
  let i = @cf.imaginary_unit(field)
  let ia = @cf.multiply(i, a).unwrap()
  let group = @aut.prepare(
    field,
    @oracle.chain([a, @cf.negate(a), ia, @cf.negate(ia)]),
  ).unwrap()
  if !@aut.check_result(field, group, @aut.certificate(group)) {
    abort("invalid automorphism source/result certificate")
  }
  let maps = @oracle.array(@aut.automorphisms(group))
  let r = maps[4]
  let tau = @aut.conjugation(group)
  let r2 = @aut.compose(group, r, r).unwrap()
  let r4 = @aut.compose(group, r2, r2).unwrap()
  let tau2 = @aut.compose(group, tau, tau).unwrap()
  let conjugated = @aut.compose(
    group,
    tau,
    @aut.compose(group, r, tau).unwrap(),
  ).unwrap()
  if !@aut.equal(r4, @aut.identity(group)) ||
    !@aut.equal(tau2, @aut.identity(group)) ||
    !@aut.equal(conjugated, @aut.inverse(group, r).unwrap()) ||
    !@cf.equal(@cf.divide(ia, a).unwrap().unwrap(), i) {
    abort("quartic D4 splitting-field relations failed")
  }
  println(
    "a^4=2: Gal(Q(a,i)/Q)=D4, order=\{@oracle.int_of_nat(@aut.order(group))}; full composition table [checked]",
  )
  println(
    "r(a)=ia, r(i)=i; tau=conjugation; r^4=tau^2=1 and tau*r*tau=r^-1 [checked]",
  )
  let a2 = @cf.multiply(a, a).unwrap()
  fixed_case(group, "Q(a,i)", [0], 8, @cf.add(a, i).unwrap(), [
    1, 0, 28, 0, 2, 0, 4, 0, 1,
  ])
  fixed_case(group, "Q(sqrt(2),i)", [0, 2], 4, @cf.add(a2, i).unwrap(), [
    9, 0, -2, 0, 1,
  ])
  fixed_case(group, "Q(a)", [0, 1], 4, a, [-2, 0, 0, 0, 1])
  fixed_case(group, "Q((1+i)a)", [0, 5], 4, @cf.add(a, ia).unwrap(), [
    8, 0, 0, 0, 1,
  ])
  fixed_case(group, "Q(ia)", [0, 3], 4, ia, [-2, 0, 0, 0, 1])
  fixed_case(group, "Q((1-i)a)", [0, 7], 4, @cf.subtract(a, ia).unwrap(), [
    8, 0, 0, 0, 1,
  ])
  fixed_case(group, "Q(i)", [0, 2, 4, 6], 2, i, [1, 0, 1])
  fixed_case(group, "Q(sqrt(2))", [0, 1, 2, 3], 2, a2, [-2, 0, 1])
  fixed_case(
    group,
    "Q(i*sqrt(2))",
    [0, 2, 5, 7],
    2,
    @cf.multiply(i, a2).unwrap(),
    [2, 0, 1],
  )
  fixed_case(group, "Q", [0, 1, 2, 3, 4, 5, 6, 7], 1, @cf.one(field), [-1, 1])
}
