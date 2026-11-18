///|
type HFRat = (Int32, Int32)

///|
type HFForm = Array[(Array[(Int32, Int32, Array[Int32])], Array[Int32])]

///|
fn hf_q(q : HFRat) -> @exact.Rational {
  let (n, d) = q
  @oracle.rational(n, d)
}

///|
fn hf_matrix(rows : Array[Array[HFRat]]) -> @matrix.Matrix[@exact.Rational] {
  @matrix.matrix(
    @oracle.nat(rows.length()),
    @oracle.chain(rows.map(fn(row) { @oracle.chain(row.map(hf_q)) })),
  ).unwrap()
}

///|
fn hf_terms(n : Int32, input : HFForm) -> @core.Chain[@forms.Term] {
  @oracle.chain(
    input.map(fn(entry) {
      let (polynomial, indices) = entry
      @forms.Term::{
        coefficient: @poly.polynomial(
          @oracle.nat(n),
          @oracle.chain(
            polynomial.map(fn(term) {
              let (numerator, denominator, exponents) = term
              @poly.Term::{
                coefficient: @oracle.rational(numerator, denominator),
                exponents: @oracle.chain(exponents.map(@oracle.nat)),
              }
            }),
          ),
        ).unwrap(),
        indices: @oracle.chain(indices.map(@oracle.nat)),
      }
    }),
  )
}

///|
fn hf_form(n : Int32, k : Int32, input : HFForm) -> @forms.Form {
  @forms.form(@oracle.nat(n), @oracle.nat(k), hf_terms(n, input)).unwrap()
}

///|
fn hf_assert_parts(
  value : Parts,
  n : Int32,
  k : Int32,
  a : HFForm,
  b : HFForm,
) -> Unit raise {
  assert_eq(@forms.variables(value.rational), @oracle.nat(n))
  assert_eq(@forms.variables(value.radical), @oracle.nat(n))
  assert_eq(@forms.degree(value.rational), @oracle.nat(k))
  assert_eq(@forms.degree(value.radical), @oracle.nat(k))
  // Expected canonical Terms bypass both Space.from_parts and Form normalization.
  assert_eq(@forms.terms(value.rational), hf_terms(n, a))
  assert_eq(@forms.terms(value.radical), hf_terms(n, b))
}

///|
fn hf_fixture(
  n : Int32,
  k : Int32,
  g : Array[Array[HFRat]],
  negative : Bool,
  determinant : HFRat,
  root : HFRat?,
  gram : Array[Array[HFRat]],
  a0 : HFForm,
  a1 : HFForm,
  b0 : HFForm,
  b1 : HFForm,
  star0 : HFForm,
  star1 : HFForm,
  inner0 : HFForm,
  inner1 : HFForm,
) -> Unit raise {
  let s = space(
    @positiveform.positive_definite(hf_matrix(g)).unwrap(),
    if negative {
      Negative
    } else {
      Positive
    },
  ).unwrap()
  assert_eq(s.volume_squared().value(), hf_q(determinant))
  assert_eq(s.rational_volume(), root.map(hf_q))
  let rule = s.prepare(@oracle.nat(k)).unwrap()
  assert_eq(hf_gram(rule, n, k), hf_matrix(gram))
  let a = s
    .from_parts({ rational: hf_form(n, k, a0), radical: hf_form(n, k, a1), })
    .unwrap()
  let b = s
    .from_parts({ rational: hf_form(n, k, b0), radical: hf_form(n, k, b1), })
    .unwrap()
  let star = a.star()
  hf_assert_parts(star.parts().unwrap(), n, n - k, star0, star1)
  hf_assert_parts(
    rule.apply(a).unwrap().parts().unwrap(),
    n,
    n - k,
    star0,
    star1,
  )
  hf_assert_parts(a.inner(b).unwrap().parts().unwrap(), n, 0, inner0, inner1)
  hf_assert_parts(
    rule.inner(a, b).unwrap().parts().unwrap(),
    n,
    0,
    inner0,
    inner1,
  )
  let sign = if k * (n - k) % 2 == 0 { a } else { a.negate() }
  // Check the ADT simplification and separately force two full component maps.
  assert_eq(a.star().star(), sign)
  let materialized = s.from_parts(star.parts().unwrap()).unwrap()
  assert_true(materialized.star().equivalent(sign).unwrap())
  assert_true(
    a
    .wedge(b.star())
    .unwrap()
    .equivalent(a.inner(b).unwrap().wedge(s.volume()).unwrap())
    .unwrap(),
  )
  let expanded_b = s.from_parts(b.star().parts().unwrap()).unwrap()
  hf_assert_parts(
    materialized.inner(expanded_b).unwrap().parts().unwrap(),
    n,
    0,
    inner0,
    inner1,
  )
  hf_assert_parts(
    a.star().inner(b.star()).unwrap().parts().unwrap(),
    n,
    0,
    inner0,
    inner1,
  )
  assert_eq(star.is_zero().unwrap(), a.is_zero().unwrap())
}

///|
// Dense exterior matrices exist only in this small reference harness.
fn hf_bases(n : Int32, k : Int32) -> Array[Array[Int32]] {
  fn walk(
    start : Int32,
    remaining : Int32,
    prefix : Array[Int32],
  ) -> Array[Array[Int32]] {
    if remaining == 0 {
      return [prefix]
    }
    let result = []
    for i in start..<n {
      let next = prefix.copy()
      next.push(i)
      for basis in walk(i + 1, remaining - 1, next) {
        result.push(basis)
      }
    }
    result
  }
  walk(0, k, [])
}

///|
fn hf_gram(
  rule : PreparedHodge,
  n : Int32,
  k : Int32,
) -> @matrix.Matrix[@exact.Rational] {
  let bases = hf_bases(n, k)
  let columns = bases.map(fn(basis) {
    rule
    .covector_action(hf_form(n, k, [([(1, 1, Array::make(n, 0))], basis)]))
    .unwrap()
  })
  let rows = bases.map(fn(basis) {
    @oracle.chain(
      columns.map(fn(column) {
        @poly.evaluate(
          coefficient(
            @forms.terms(column),
            @oracle.chain(basis.map(@oracle.nat)),
            @oracle.nat(n),
          ),
          @core.replicate(@oracle.nat(n), @exact.rational_zero()),
        ).unwrap()
      }),
    )
  })
  @matrix.matrix(@oracle.nat(bases.length()), @oracle.chain(rows)).unwrap()
}
