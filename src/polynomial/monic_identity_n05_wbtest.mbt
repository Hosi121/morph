///|
fn n05_polynomial(
  variables : Int32,
  entries : Array[(Int32, Int32, Array[Int32])],
) -> Polynomial {
  polynomial(
    @oracle.nat(variables),
    @oracle.chain(
      entries.map(fn(entry) {
        let (n, d, e) = entry
        Term::{
          coefficient: @oracle.rational(n, d),
          exponents: @oracle.chain(e.map(@oracle.nat)),
        }
      }),
    ),
  ).unwrap()
}

///|
fn monic_before_n05(p : Polynomial) -> Polynomial {
  match p.terms {
    Nil => p
    Cons(leading, _) =>
      match @exact.nonzero(leading.coefficient) {
        None => p
        Some(coefficient) => {
          let factor = @exact.reciprocal(coefficient)
          {
            variables: p.variables,
            terms: @core.map(p.terms, fn(term) {
              {
                coefficient: @exact.rational_multiply(factor, term.coefficient),
                exponents: term.exponents,
              }
            }),
          }
        }
      }
  }
}

///|
test "N05 complete Fraction monic fixtures and unchanged legacy oracle" {
  {
    let input = n05_polynomial(1, [
      (-3, 1, [0]),
      (-1, 1, [1]),
      (-1, 3, [2]),
      (2, 1, [3]),
      (1, 2, [4]),
      (2, 3, [5]),
      (3, 1, [6]),
      (-3, 2, [7]),
      (-2, 3, [8]),
      (-1, 1, [9]),
      (1, 1, [10]),
      (1, 3, [11]),
      (2, 1, [12]),
      (3, 2, [13]),
      (-1, 1, [14]),
      (-2, 1, [15]),
      (-1, 2, [16]),
      (2, 3, [17]),
      (1, 1, [18]),
      (1, 1, [19]),
      (1, 1, [20]),
      (-3, 1, [21]),
      (-1, 1, [22]),
      (-1, 3, [23]),
      (2, 1, [24]),
      (1, 2, [25]),
      (2, 3, [26]),
      (3, 1, [27]),
      (-3, 2, [28]),
      (-2, 3, [29]),
      (-1, 1, [30]),
      (1, 1, [31]),
      (1, 3, [32]),
      (2, 1, [33]),
      (3, 2, [34]),
      (-1, 1, [35]),
      (-2, 1, [36]),
      (-1, 2, [37]),
      (2, 3, [38]),
      (1, 1, [39]),
      (1, 1, [40]),
      (1, 1, [41]),
      (-3, 1, [42]),
      (-1, 1, [43]),
      (-1, 3, [44]),
      (2, 1, [45]),
      (1, 2, [46]),
      (2, 3, [47]),
      (1, 1, [48]),
    ])
    let wanted = n05_polynomial(1, [
      (1, 1, [48]),
      (2, 3, [47]),
      (1, 2, [46]),
      (2, 1, [45]),
      (-1, 3, [44]),
      (-1, 1, [43]),
      (-3, 1, [42]),
      (1, 1, [41]),
      (1, 1, [40]),
      (1, 1, [39]),
      (2, 3, [38]),
      (-1, 2, [37]),
      (-2, 1, [36]),
      (-1, 1, [35]),
      (3, 2, [34]),
      (2, 1, [33]),
      (1, 3, [32]),
      (1, 1, [31]),
      (-1, 1, [30]),
      (-2, 3, [29]),
      (-3, 2, [28]),
      (3, 1, [27]),
      (2, 3, [26]),
      (1, 2, [25]),
      (2, 1, [24]),
      (-1, 3, [23]),
      (-1, 1, [22]),
      (-3, 1, [21]),
      (1, 1, [20]),
      (1, 1, [19]),
      (1, 1, [18]),
      (2, 3, [17]),
      (-1, 2, [16]),
      (-2, 1, [15]),
      (-1, 1, [14]),
      (3, 2, [13]),
      (2, 1, [12]),
      (1, 3, [11]),
      (1, 1, [10]),
      (-1, 1, [9]),
      (-2, 3, [8]),
      (-3, 2, [7]),
      (3, 1, [6]),
      (2, 3, [5]),
      (1, 2, [4]),
      (2, 1, [3]),
      (-1, 3, [2]),
      (-1, 1, [1]),
      (-3, 1, [0]),
    ])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(1, [
      (1, 1, [240]),
      (-2, 3, [83]),
      (7, 5, [32]),
      (-1, 1, [7]),
      (2, 1, [1]),
      (3, 7, [0]),
    ])
    let wanted = n05_polynomial(1, [
      (1, 1, [240]),
      (-2, 3, [83]),
      (7, 5, [32]),
      (-1, 1, [7]),
      (2, 1, [1]),
      (3, 7, [0]),
    ])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(3, [
      (-2, 1, [0, 0, 0]),
      (-1, 2, [0, 1, 3]),
      (1, 1, [0, 2, 6]),
      (1, 4, [0, 3, 2]),
      (2, 1, [0, 4, 5]),
      (-1, 1, [0, 5, 1]),
      (-1, 3, [1, 0, 4]),
      (3, 4, [1, 1, 0]),
      (1, 1, [1, 2, 3]),
      (1, 1, [1, 3, 6]),
      (-2, 3, [1, 4, 2]),
      (-1, 4, [1, 5, 5]),
      (3, 1, [2, 0, 1]),
      (1, 2, [2, 1, 4]),
      (2, 3, [2, 2, 0]),
      (-1, 2, [2, 3, 3]),
      (-1, 1, [2, 4, 6]),
      (3, 2, [2, 5, 2]),
      (1, 3, [3, 0, 5]),
      (1, 2, [3, 1, 1]),
      (-2, 1, [3, 2, 4]),
      (-1, 2, [3, 3, 0]),
      (1, 1, [3, 4, 3]),
      (1, 4, [3, 5, 6]),
      (2, 1, [4, 0, 2]),
      (-1, 1, [4, 1, 5]),
      (-1, 3, [4, 2, 1]),
      (3, 4, [4, 3, 4]),
      (1, 1, [4, 4, 0]),
      (1, 1, [4, 5, 3]),
      (-2, 3, [5, 0, 6]),
      (-1, 4, [5, 1, 2]),
      (3, 1, [5, 2, 5]),
      (1, 2, [5, 3, 1]),
      (2, 3, [5, 4, 4]),
      (-1, 2, [5, 5, 0]),
      (1, 1, [7, 2, 4]),
    ])
    let wanted = n05_polynomial(3, [
      (1, 1, [7, 2, 4]),
      (-1, 2, [5, 5, 0]),
      (2, 3, [5, 4, 4]),
      (1, 2, [5, 3, 1]),
      (3, 1, [5, 2, 5]),
      (-1, 4, [5, 1, 2]),
      (-2, 3, [5, 0, 6]),
      (1, 1, [4, 5, 3]),
      (1, 1, [4, 4, 0]),
      (3, 4, [4, 3, 4]),
      (-1, 3, [4, 2, 1]),
      (-1, 1, [4, 1, 5]),
      (2, 1, [4, 0, 2]),
      (1, 4, [3, 5, 6]),
      (1, 1, [3, 4, 3]),
      (-1, 2, [3, 3, 0]),
      (-2, 1, [3, 2, 4]),
      (1, 2, [3, 1, 1]),
      (1, 3, [3, 0, 5]),
      (3, 2, [2, 5, 2]),
      (-1, 1, [2, 4, 6]),
      (-1, 2, [2, 3, 3]),
      (2, 3, [2, 2, 0]),
      (1, 2, [2, 1, 4]),
      (3, 1, [2, 0, 1]),
      (-1, 4, [1, 5, 5]),
      (-2, 3, [1, 4, 2]),
      (1, 1, [1, 3, 6]),
      (1, 1, [1, 2, 3]),
      (3, 4, [1, 1, 0]),
      (-1, 3, [1, 0, 4]),
      (-1, 1, [0, 5, 1]),
      (2, 1, [0, 4, 5]),
      (1, 4, [0, 3, 2]),
      (1, 1, [0, 2, 6]),
      (-1, 2, [0, 1, 3]),
      (-2, 1, [0, 0, 0]),
    ])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(2, [
      (-3, 1, [0, 0]),
      (-1, 1, [0, 1]),
      (-1, 3, [0, 2]),
      (2, 1, [0, 3]),
      (1, 2, [1, 0]),
      (2, 3, [1, 1]),
      (3, 1, [1, 2]),
      (-3, 2, [1, 3]),
      (-2, 3, [2, 0]),
      (-1, 1, [2, 1]),
      (1, 1, [2, 2]),
      (1, 3, [2, 3]),
      (2, 1, [3, 0]),
      (3, 2, [3, 1]),
      (-1, 1, [3, 2]),
      (-2, 1, [3, 3]),
      (-1, 2, [4, 0]),
      (2, 3, [4, 1]),
      (1, 1, [4, 2]),
      (1, 1, [4, 3]),
      (1, 1, [5, 0]),
      (-3, 1, [5, 1]),
      (-1, 1, [5, 2]),
      (-1, 3, [5, 3]),
      (-1, 1, [7, 0]),
      (2, 3, [8, 0]),
    ])
    let wanted = n05_polynomial(2, [
      (1, 1, [8, 0]),
      (-3, 2, [7, 0]),
      (-1, 2, [5, 3]),
      (-3, 2, [5, 2]),
      (-9, 2, [5, 1]),
      (3, 2, [5, 0]),
      (3, 2, [4, 3]),
      (3, 2, [4, 2]),
      (1, 1, [4, 1]),
      (-3, 4, [4, 0]),
      (-3, 1, [3, 3]),
      (-3, 2, [3, 2]),
      (9, 4, [3, 1]),
      (3, 1, [3, 0]),
      (1, 2, [2, 3]),
      (3, 2, [2, 2]),
      (-3, 2, [2, 1]),
      (-1, 1, [2, 0]),
      (-9, 4, [1, 3]),
      (9, 2, [1, 2]),
      (1, 1, [1, 1]),
      (3, 4, [1, 0]),
      (3, 1, [0, 3]),
      (-1, 2, [0, 2]),
      (-3, 2, [0, 1]),
      (-9, 2, [0, 0]),
    ])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(0, [])
    let wanted = n05_polynomial(0, [])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(0, [(1, 1, [])])
    let wanted = n05_polynomial(0, [(1, 1, [])])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(0, [(-1, 1, [])])
    let wanted = n05_polynomial(0, [(1, 1, [])])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(0, [(2, 3, [])])
    let wanted = n05_polynomial(0, [(1, 1, [])])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  {
    let input = n05_polynomial(1, [(1, 1, [7])])
    let wanted = n05_polynomial(1, [(1, 1, [7])])
    assert_eq(monic(input), wanted)
    assert_eq(monic(input), monic_before_n05(input))
  }
  let input = n05_polynomial(3, [(1, 1, [2, 4, 7]), (-5, 7, [1, 8, 0])])
  let wanted = n05_polynomial(3, [(1, 1, [2, 4, 7]), (-5, 7, [1, 8, 0])])
  assert_eq(monic(input), wanted)
  assert_eq(monic(input), monic_before_n05(input))
}

///|
test "N05 canonical QQ +1 recognition exhausts small numerator denominator pairs" {
  for n in -8..<9 {
    for d in 1..<10 {
      let q = @oracle.rational(n, d)
      assert_eq(monic_positive_one(q), n == d)
      let p = n05_polynomial(2, [(n, d, [3, 7]), (2, 3, [1, 1])])
      assert_eq(monic(p), monic_before_n05(p))
    }
  }
}
