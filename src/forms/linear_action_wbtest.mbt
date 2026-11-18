///|
test "all elementary exterior shears through dimension five match linear pullback minors" {
  for n in 1..<6 {
    for i in 0..<n {
      for j in 0..<n {
        if i == j {
          continue
        }
        let coordinates = Array::makei(n, fn(r) {
          let coordinate = fixture_polynomial(n, [
            (1, 1, Array::makei(n, fn(k) { if k == r { 1 } else { 0 } })),
          ])
          if r == j {
            @poly.add(
              coordinate,
              fixture_polynomial(n, [
                (2, 3, Array::makei(n, fn(k) { if k == i { 1 } else { 0 } })),
              ]),
            ).unwrap()
          } else {
            coordinate
          }
        })
        let mapping = polynomial_map(@oracle.nat(n), @oracle.chain(coordinates)).unwrap()
        for mask in 0..<(1 << n) {
          let basis = []
          for index in 0..<n {
            if (mask & (1 << index)) != 0 {
              basis.push(index)
            }
          }
          let value = fixture_form(n, basis.length(), [
            ([(1, 1, Array::make(n, 0))], basis),
          ])
          let actual = shear(
            value,
            @oracle.nat(i),
            @oracle.nat(j),
            @oracle.rational(2, 3),
          ).unwrap()
          assert_eq(actual, pullback(mapping, value).unwrap())
          assert_eq(
            shear(
              actual,
              @oracle.nat(i),
              @oracle.nat(j),
              @oracle.rational(-2, 3),
            ),
            Ok(value),
          )
        }
      }
    }
  }
}

///|
test "diagonal exterior maps and complements retain canonical terms and grading" {
  for n in 0..<6 {
    let factors = Array::makei(n, fn(i) { @oracle.rational(i, 2) })
    for mask in 0..<(1 << n) {
      let basis = []
      let complement = []
      for index in 0..<n {
        if (mask & (1 << index)) != 0 {
          basis.push(index)
        } else {
          complement.push(index)
        }
      }
      let value = fixture_form(n, basis.length(), [
        ([(1, 1, Array::make(n, 0))], basis),
      ])
      let mut scalar = @exact.rational_one()
      for index in basis {
        scalar = @exact.rational_multiply(scalar, factors[index])
      }
      let expected = form(
        @oracle.nat(n),
        @oracle.nat(basis.length()),
        Cons(
          {
            coefficient: @poly.constant(@oracle.nat(n), scalar),
            indices: @oracle.chain(basis.map(@oracle.nat)),
          },
          Nil,
        ),
      ).unwrap()
      assert_eq(scale_axes(value, @oracle.chain(factors)), Ok(expected))
      let star = euclidean_star(value).unwrap()
      let sign = if basis.length() * (n - basis.length()) % 2 == 0 {
        value
      } else {
        negate(value)
      }
      assert_eq(euclidean_star(star), Ok(sign))
      assert_eq(degree(star), @oracle.nat(complement.length()))
    }
  }
  let empty = zero(@oracle.nat(2), Zero)
  assert_eq(shear(empty, Zero, Zero, @exact.rational_zero()), Err(InvalidShear))
  assert_eq(
    shear(empty, @oracle.nat(2), Zero, @exact.rational_zero()),
    Err(IndexOutOfRange),
  )
  assert_eq(scale_axes(empty, Nil), Err(DimensionMismatch))
  assert_eq(
    euclidean_star(zero(@oracle.nat(2), @oracle.nat(3))),
    Err(DegreeOutOfRange),
  )
}
