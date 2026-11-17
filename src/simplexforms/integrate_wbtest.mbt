///|
fn fraction_value(value : (Int32, Int32)) -> @exact.Rational {
  let (n, d) = value
  @oracle.rational(n, d)
}

///|
fn fraction_vertex(
  value : Array[(Int32, Int32)],
) -> @core.Chain[@exact.Rational] {
  @oracle.chain(value.map(fraction_value))
}

///|
fn fraction_simplex(
  count : Int32,
  input : Array[Array[(Int32, Int32)]],
) -> Simplex {
  simplex(@oracle.nat(count), @oracle.chain(input.map(fraction_vertex))).unwrap()
}

///|
fn fraction_polynomial(
  count : Int32,
  input : Array[(Int32, Int32, Array[Int32])],
) -> @poly.Polynomial {
  @poly.polynomial(
    @oracle.nat(count),
    @oracle.chain(
      input.map(fn(entry) {
        let (n, d, exponents) = entry
        @poly.Term::{
          coefficient: @oracle.rational(n, d),
          exponents: @oracle.chain(exponents.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn fraction_terms(
  count : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> @core.Chain[@forms.Term] {
  @oracle.chain(
    input.map(fn(entry) {
      let (coefficient, indices) = entry
      @forms.Term::{
        coefficient: fraction_polynomial(count, coefficient),
        indices: @oracle.chain(indices.map(@oracle.nat)),
      }
    }),
  )
}

///|
fn fraction_form(
  count : Int32,
  grade : Int32,
  input : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
) -> @forms.Form {
  @forms.form(
    @oracle.nat(count),
    @oracle.nat(grade),
    fraction_terms(count, input),
  ).unwrap()
}

///|
fn fraction_integral_fixture(
  count : Int32,
  input : Array[Array[(Int32, Int32)]],
  coefficients : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  expected : (Int32, Int32),
) -> Unit raise {
  let value = fraction_simplex(count, input)
  let integrand = fraction_form(count, input.length() - 1, coefficients)
  assert_eq(ambient(value), @oracle.nat(count))
  assert_eq(dimension(value), @oracle.nat(input.length() - 1))
  assert_eq(vertices(value), @oracle.chain(input.map(fraction_vertex)))
  assert_true(check_parameterization(value, parameterization(value).unwrap()))
  assert_eq(integrate(value, integrand), Ok(fraction_value(expected)))
  assert_true(check_integral(value, integrand, fraction_value(expected)))
  assert_true(
    !check_integral(
      value,
      integrand,
      @exact.rational_add(fraction_value(expected), @oracle.rational(1, 1)),
    ),
  )
  if input.length() > 1 {
    let reversed = input.copy()
    let previous = reversed[0]
    reversed[0] = reversed[1]
    reversed[1] = previous
    assert_eq(
      integrate(fraction_simplex(count, reversed), integrand),
      Ok(@exact.rational_negate(fraction_value(expected))),
    )
  }
}

///|
fn fraction_stokes_fixture(
  count : Int32,
  input : Array[Array[(Int32, Int32)]],
  coefficients : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  differential : Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])],
  face_values : Array[(Int32, Int32)],
  expected : (Int32, Int32),
) -> Unit raise {
  let value = fraction_simplex(count, input)
  let integrand = fraction_form(count, input.length() - 2, coefficients)
  let certificate = stokes(value, integrand).unwrap()
  assert_eq(certificate.simplex, value)
  assert_eq(certificate.integrand, integrand)
  assert_eq(
    @forms.terms(certificate.differential),
    fraction_terms(count, differential),
  )
  assert_eq(certificate.interior, fraction_value(expected))
  assert_eq(certificate.boundary, fraction_value(expected))
  assert_eq(boundary_integral(value, integrand), Ok(fraction_value(expected)))
  let faces = @oracle.array(certificate.faces)
  assert_eq(faces.length(), input.length())
  for i in 0..<faces.length() {
    let expected_vertices = [
      for j in 0..<input.length() if i != j => fraction_vertex(input[j])
    ]
    assert_eq(faces[i].oriented.omitted, @oracle.nat(i))
    assert_eq(faces[i].oriented.negative, i % 2 == 1)
    assert_eq(
      vertices(faces[i].oriented.simplex),
      @oracle.chain(expected_vertices),
    )
    assert_eq(faces[i].integral, fraction_value(face_values[i]))
  }
  assert_true(check_boundary(value, boundary(value)))
  assert_true(check_stokes(certificate))
}

///|
test "simplex validates shape and face indices before degeneration" {
  assert_eq(simplex(Zero, Nil), Err(EmptySimplex))
  assert_eq(simplex(Succ(Zero), Cons(Nil, Nil)), Err(VertexDimension))
  let triangle = standard(@oracle.nat(2))
  assert_eq(face(triangle, Nil), Err(EmptyFace))
  assert_eq(
    face(
      triangle,
      @oracle.chain([@oracle.nat(0), @oracle.nat(0), @oracle.nat(3)]),
    ),
    Err(InvalidVertex),
  )
  assert_eq(
    integrate(triangle, @forms.zero(@oracle.nat(3), @oracle.nat(2))),
    Err(DimensionMismatch),
  )
  assert_eq(
    integrate(triangle, @forms.zero(@oracle.nat(2), Succ(Zero))),
    Err(DegreeMismatch),
  )
  let point = standard(Zero)
  assert_eq(boundary(point), Nil)
  assert_true(check_boundary(point, Nil))
  assert_eq(
    integrate(point, @forms.scalar(fraction_polynomial(0, [(7, 3, [])]))),
    Ok(@oracle.rational(7, 3)),
  )
  assert_eq(stokes(point, @forms.zero(Zero, Zero)), Err(DegreeMismatch))
  assert_eq(
    boundary_integral(point, @forms.zero(Zero, Zero)),
    Err(DegreeMismatch),
  )
}

///|
test "parameterization check rejects nonlinear maps with the right endpoint values" {
  let segment = standard(Succ(Zero))
  let nonlinear = @forms.polynomial_map(
    Succ(Zero),
    Cons(fraction_polynomial(1, [(1, 1, [2])]), Nil),
  ).unwrap()
  assert_true(!check_parameterization(segment, nonlinear))
  let wrong = @forms.polynomial_map(
    Succ(Zero),
    Cons(fraction_polynomial(1, [(1, 1, [0]), (1, 1, [1])]), Nil),
  ).unwrap()
  assert_true(!check_parameterization(segment, wrong))
}

///|
test "Stokes checks every face omission sign value and the exact differential" {
  let value = standard(@oracle.nat(2))
  let integrand = fraction_form(2, 1, [([(1, 1, [1, 0])], [1])])
  let proof = stokes(value, integrand).unwrap()
  assert_eq(proof.interior, @oracle.rational(1, 2))
  assert_true(
    !check_stokes({
      ..proof,
      differential: @forms.zero(@oracle.nat(2), @oracle.nat(2)),
    }),
  )
  assert_true(!check_stokes({ ..proof, interior: @oracle.rational(2, 3), }))
  assert_true(!check_stokes({ ..proof, boundary: @oracle.rational(2, 3), }))
  assert_true(
    !check_stokes({ ..proof, faces: @core.drop(Succ(Zero), proof.faces), }),
  )
  let first = @core.nth(proof.faces, Zero).unwrap()
  let tail = @core.drop(Succ(Zero), proof.faces)
  let wrong_sign = {
    ..first,
    oriented: { ..first.oriented, negative: !first.oriented.negative, },
  }
  assert_true(!check_stokes({ ..proof, faces: Cons(wrong_sign, tail), }))
  let wrong_value = { ..first, integral: @oracle.rational(9, 1), }
  assert_true(!check_stokes({ ..proof, faces: Cons(wrong_value, tail), }))
  let wrong_face = {
    ..first,
    oriented: {
      ..first.oriented,
      simplex: face(value, @oracle.chain([@oracle.nat(2), @oracle.nat(1)])).unwrap(),
    },
  }
  assert_true(!check_stokes({ ..proof, faces: Cons(wrong_face, tail), }))
  assert_true(!check_boundary(value, @core.reverse(boundary(value))))
}
