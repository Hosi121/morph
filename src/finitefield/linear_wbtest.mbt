///|
test "shared field Gaussian solver versus all assignments over the field of three" {
  let field = field(@oracle.binary(3)).unwrap()
  for matrix in 0..<81 {
    let entries = [ for i in 0..<4 => matrix / [1, 3, 9, 27][i] % 3 ]
    let a = @matrix.matrix(
      @oracle.nat(2),
      @oracle.chain([
        @oracle.chain(entries[:2].to_owned().map(@oracle.binary)),
        @oracle.chain(entries[2:].to_owned().map(@oracle.binary)),
      ]),
    ).unwrap()
    for rhs in 0..<9 {
      let b = [rhs % 3, rhs / 3]
      let solutions = []
      for x in 0..<3 {
        for y in 0..<3 {
          if (entries[0] * x + entries[1] * y) % 3 == b[0] &&
            (entries[2] * x + entries[3] * y) % 3 == b[1] {
            solutions.push([x, y])
          }
        }
      }
      match
        @rowreduce.solve(
          arithmetic(field),
          a,
          @oracle.chain(b.map(@oracle.binary)),
        ).unwrap() {
        Inconsistent => assert_true(solutions.is_empty())
        Unique(values) => {
          assert_eq(solutions.length(), 1)
          assert_eq(
            @oracle.array(values).map(@oracle.int_of_binary),
            solutions[0],
          )
        }
        Affine(particular, basis) => {
          assert_true(solutions.length() > 1)
          let p = @oracle.array(particular).map(@oracle.int_of_binary)
          assert_true(solutions.contains(p))
          for direction in @oracle.array(basis) {
            let d = @oracle.array(direction).map(@oracle.int_of_binary)
            for scale in 0..<3 {
              assert_true(
                solutions.contains([
                  (p[0] + scale * d[0]) % 3,
                  (p[1] + scale * d[1]) % 3,
                ]),
              )
            }
          }
        }
      }
    }
  }
}

///|
test "finite-field determinant and inverse versus two-by-two integer formulas" {
  for p in [3, 5] {
    let context = field(@oracle.binary(p)).unwrap()
    for code in 0..<(p * p * p * p) {
      let values = [
        code % p,
        code / p % p,
        code / (p * p) % p,
        code / (p * p * p),
      ]
      let matrix = @matrix.matrix(
        @oracle.nat(2),
        @oracle.chain([
          @oracle.chain(values[:2].to_owned().map(@oracle.binary)),
          @oracle.chain(values[2:].to_owned().map(@oracle.binary)),
        ]),
      ).unwrap()
      let determinant = (
          (values[0] * values[3] - values[1] * values[2]) % p + p
        ) %
        p
      assert_eq(
        @rowreduce.determinant(arithmetic(context), matrix),
        Some(@oracle.binary(determinant)),
      )
      match @rowreduce.inverse(arithmetic(context), matrix) {
        None => assert_eq(determinant, 0)
        Some(inverse) => {
          assert_true(determinant != 0)
          let mut reciprocal = 0
          for candidate in 1..<p {
            if candidate * determinant % p == 1 {
              reciprocal = candidate
            }
          }
          let expected = [[values[3], -values[1]], [-values[2], values[0]]].map(fn(
              row,
            ) {
              row.map(fn(x) { (x * reciprocal % p + p) % p })
            },
          )
          let actual = @oracle.array(@matrix.rows(inverse)).map(fn(row) {
            @oracle.array(row).map(@oracle.int_of_binary)
          })
          assert_eq(actual, expected)
        }
      }
    }
  }
}
